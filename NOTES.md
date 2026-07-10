# Bottleneck Analysis for `src/parser.zig`

This document details the performance analysis of the TextMate line-parsing implementation in [src/parser.zig](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig) and highlights the key bottlenecks that degrade performance—particularly when parsing complex, recursive grammars like [c.json](file:///home/iceman/Developer/zig/textmate.zig/src/resources/grammars/c.json) on large source files (e.g., `sqlite3.c`).

---

## Executive Summary

The TextMate parsing process runs in linear time $O(N)$ relative to the number of lines, but the constant factor per line is extremely high. When analyzing the parsing lifecycle via [Parser.parseLine](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L1156-L1411), we find that the parser spends the vast majority of its CPU cycles on:
1. **Redundant Injection and Scope Processing**: Resolving scope-based grammar injections on *every single pattern matching attempt*, even when the active scope stack remains unchanged.
2. **Sub-optimal Regex Match Caching** *(Optimized)*: Cache retrieval conditions in [Parser.findMatch](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L433-L584) were overly restrictive. We have implemented range-based validation and cached successful matches to drastically reduce redundant regex engine searches.
3. **Dynamic Selector Parsing**: Parsing complex scope selector expressions character-by-character at runtime for every rule evaluation.
4. **Frequent Heap Allocations** *(Optimized)*: We have eliminated heap allocations and deallocations per regex execution by reusing a persistent [oni.Region](file:///home/iceman/Developer/zig/textmate.zig/pkg/oniguruma/region.zig#L4-L51) buffer inside the parser.
5. **Over-evaluation of Child Patterns during End Matches** *(OPTIMIZED)*

---

## Detailed Bottleneck Breakdown

### 1. Dynamic Injection Processing & Lack of State Invalidation Caching
**Location**: [Parser.matchPatterns](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L864-L1001)

#### The Issue:
For every call to `matchPatterns`, if the rule has a scope name, the parser:
1. Traverses the entire active state stack ([ParseState.stack](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L193-L336)) to reconstruct the current scopes.
2. Splits and trims the scope names.
3. Loops through the injections of the active grammar AND **all loaded grammars** in the library cache (`gml.cache`).
4. Invokes the dynamic selector matching logic for each injection.

#### Why it is a bottleneck:
The scope stack only changes when a rule context is **pushed**, **popped**, or **deserialized**. However, the parser executes `matchPatterns` at every matching step along a line. Re-evaluating and reconstructing active injections when the scope stack is identical results in >95% redundant computation.

#### Architectural Reference: `syntect` (Rust)
In [syntect](file:///home/iceman/Developer/zig/textmate.zig/resources/syntect/src/highlighting/highlighter.rs), scope and style state evaluations are optimized using a parallel caching stack ([HighlightState](file:///home/iceman/Developer/zig/textmate.zig/resources/syntect/src/highlighting/highlighter.rs#L59) which contains `styles` and `single_caches` parallel vectors). 
* **Incremental Push**: When pushing a new scope, the style modifier is computed incrementally based on the previous stack's style.
* **$O(1)$ Pop**: When popping a scope, the top style is simply popped from the styles vector without re-evaluation.
By storing pre-evaluated styles per stack level, `syntect` completely avoids traversing the full scope stack or re-matching all scope selectors on most steps.

---

### 2. Ineffective Regex Match Caching **[OPTIMIZED]**
**Locations**: [Parser.findMatch](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L433-L584) & [Parser.matchBegin](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L595-L700)

#### The Issue (Now Optimized):
The parser maintains two caches: `match_cache` (keyed by rule ID) and `exec_cache` (keyed by regex ID).
* **Weak Cache Check**: Previously, the retrieval check for `exec_cache` required an exact match of the search start position (`mm.anchor_start == hard_start`).
* **Cache Exclusions**: Previously, successful matches were not stored in `match_cache` or `exec_cache` under many circumstances.

#### Optimization Applied:
We modified the caching system to support range-based validation for non-anchored patterns:
1. Mismatches (`count == 0`) are cached and validated for any search start position $P \ge \text{anchor\_start}$.
2. Matches (`count > 0`) are cached and validated for any search start position $P$ where $\text{anchor\_start} \le P \le \text{match.start}$.
3. Successful matches are now fully cached in both `match_cache` and `exec_cache`, avoiding redundant regex engine searches.

---

### 3. Runtime Scope Selector Parsing
**Location**: [matchesScopeSelector](file:///home/iceman/Developer/zig/textmate.zig/src/scopes.zig#L101-L116) and [SelectorEvaluator](file:///home/iceman/Developer/zig/textmate.zig/src/scopes.zig#L18-L99)

#### The Issue:
When checking if an injection rule applies to the current scope stack, the parser calls `matchesScopeSelector`, which:
1. Splits the selector string (e.g., `L:text.html.php - (meta.embedded | comment)`) by commas.
2. Instantiates a [SelectorEvaluator](file:///home/iceman/Developer/zig/textmate.zig/src/scopes.zig#L18-L99) parser.
3. Parses the selector string character-by-character on the fly (evaluating `|`, `&`, `-`, parentheses, and identifiers).

#### Why it is a bottleneck:
Grammars with numerous injections require evaluating scope selectors thousands of times. Parsing these strings dynamically at runtime creates massive overhead in string parsing, validation, and traversal.

---

### 4. Heap Allocations via Oniguruma Regions **[OPTIMIZED]**
**Location**: [Parser.findMatch](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L501-L518)

#### The Issue (Now Optimized):
Previously, an [oni.Region](file:///home/iceman/Developer/zig/textmate.zig/pkg/oniguruma/region.zig#L4-L51) struct was allocated on the stack and its internal memory arrays were allocated and freed via heap on every single regex search execution.

#### Optimization Applied:
We added a persistent `region: oni.Region` field directly to the `Parser` struct. It is initialized in `Parser.init` and deinitialized once in `Parser.deinit`. During matching inside `findMatch`, the parser passes `&self.region` to Oniguruma's search function. Oniguruma internally reuses the pre-allocated buffers of the region, completely eliminating heap allocations and deallocations on every regex matching step.

---

### 5. Over-evaluation of Child Patterns during End Matches **[OPTIMIZED]**
**Location**: [Parser.parseLine](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L1219-L1226)

#### The Issue:
Even if a valid `matchEnd` match is found at the current position, the parser will still evaluate all child patterns via `matchPatterns` unless:
```zig
if (!syn.apply_end_pattern_last and end_match.count > 0 and end_match.start == start and end_match.end + 1 >= end) {
    // end match is prioritized, remove?
}
```
The condition `end_match.end + 1 >= end` restricts this short-circuiting to end matches that reach the end of the line.

#### Why it is a bottleneck:
If the end match is found at the current `start` position but does not span to the end of the line, the parser still scans all child patterns via `matchPatterns` even though the end pattern is prioritized and will win anyway.

---

## Case Study: The [c.json](file:///home/iceman/Developer/zig/textmate.zig/src/resources/grammars/c.json) Grammar

The C grammar illustrates why these bottlenecks are so destructive:
* **Deep Include Hierarchies**: Rules like `#preprocessor-rule-enabled`, `#comments`, and `#block` include dozens of other rules. This causes the patterns array in [Parser.matchPatterns](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L864-L1001) to be very large (containing hundreds of patterns to test).
* **Recursive Scopes**: Parsing constructs like functions or nested blocks pushes many layers onto the state stack, increasing the overhead of scope list construction.
* **Frequent Injections**: Large grammars utilize injections (e.g. for comments, string interpolations, or embedded languages). Walking the entire grammar library cache (`gml.cache`) to evaluate these injections for every sub-pattern quickly dominates execution time.

---

## Actionable Recommendations

### Recommendation 1: Implement Stack-Based Injection Caching

Drawing inspiration from `syntect`'s parallel stack cache design, we can optimize grammar injection lookup by avoiding scope-selector parsing and stack traversal during normal pattern matching steps. We propose two design options:

#### Option A: Parser-Level Dirty Caching (Simplest)
Add cached injection fields and an invalidation flag to the `Parser` struct:
```zig
left_injections: std.ArrayList(*Syntax),
right_injections: std.ArrayList(*Syntax),
injections_dirty: bool = true,
```
1. In `push`, `pop`, and `deserialize`, set `injections_dirty = true`.
2. In `matchPatterns`, if `injections_dirty` is true, re-collect active injections (evaluating selectors) and set `injections_dirty = false`. Otherwise, immediately reuse `left_injections` and `right_injections`.

* **Pros**: Simple to implement, low memory footprint, and requires zero modifications to the serialized `StateContext` structures.

#### Option B: Parallel Injection Stack / Context-Level Caching (Most Performant)
Store the pre-computed active injections directly inside each [StateContext](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L158-L190) (or in a parallel stack owned by the parser):
```zig
const StateContext = struct {
    // ... existing fields ...
    left_injections: std.ArrayListUnmanaged(*Syntax) = .{},
    right_injections: std.ArrayListUnmanaged(*Syntax) = .{},
};
```
1. When a new context is **pushed** onto the stack, compute its active injections by merging the parent context's injections with any new injections matched by the new scope level.
2. When a context is **popped**, simply pop it off the stack. The new top context already contains its pre-computed injection lists.
3. During `matchPatterns`, fetch active injections directly from the top stack context in $O(1)$ time.

* **Pros**: Reaches $O(1)$ injection lookup per step, eliminates redundant injection scans even when backtracking or switching between deeply nested contexts, and follows the clean parallel-caching stack pattern used by `syntect`.

### Recommendation 2: Improve Regex Cache Matching Conditions **[RESOLVED & IMPLEMENTED]**
We implemented range-based validation for cached mismatches and matches, and enabled caching for successful matches:
1. A cached mismatch (`count == 0`) is valid for all starting positions $P \ge \text{anchor\_start}$.
2. A cached match (`count > 0`) is valid for all starting positions $P$ where $\text{anchor\_start} \le P \le \text{match.start}$.
This drastically increases the cache hit rate as the scanner advances.

### Recommendation 3: Pre-parse Scope Selectors
Parse selector strings once into an AST or token stream during grammar JSON loading, storing the structured representation inside `Syntax` injection nodes. This eliminates character-by-character string parsing at runtime.

### Recommendation 4: Reuse Oniguruma Region Buffers **[RESOLVED & IMPLEMENTED]**
Added a persistent `region` buffer to the `Parser` struct, avoiding heap allocation/deallocation on every single search step.

### Recommendation 5: Optimize End-Match Short-Circuiting **[RESOLVED & IMPLEMENTED]**
Relax the short-circuiting condition in `parseLine` so that if an end match is found at the current position, the parser can skip child pattern matching without requiring the match to extend to the end of the line.
