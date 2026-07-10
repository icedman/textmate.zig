# Bottleneck Analysis for `src/parser.zig`

This document details the performance analysis of the TextMate line-parsing implementation in [src/parser.zig](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig) and highlights the key bottlenecks that degrade performance—particularly when parsing complex, recursive grammars like [c.json](file:///home/iceman/Developer/zig/textmate.zig/src/resources/grammars/c.json) on large source files (e.g., `sqlite3.c`).

---

## Executive Summary

The TextMate parsing process runs in linear time $O(N)$ relative to the number of lines, but the constant factor per line is extremely high. When analyzing the parsing lifecycle via [Parser.parseLine](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L1156-L1411), we find that the parser spends the vast majority of its CPU cycles on:
1. **Redundant Injection and Scope Processing**: Resolving scope-based grammar injections on *every single pattern matching attempt*, even when the active scope stack remains unchanged.
2. **Sub-optimal Regex Match Caching**: Cache retrieval conditions in [Parser.findMatch](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L433-L584) are overly restrictive, causing cache misses when the parser's horizontal position advances across the line.
3. **Dynamic Selector Parsing**: Parsing complex scope selector expressions character-by-character at runtime for every rule evaluation.
4. **Frequent Heap Allocations**: Allocating and freeing Oniguruma search region memory buffers (`oni.Region`) on every single regex invocation.

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

---

### 2. Ineffective Regex Match Caching
**Locations**: [Parser.findMatch](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L433-L584) & [Parser.matchBegin](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L595-L700)

#### The Issue:
The parser maintains two caches: `match_cache` (keyed by rule ID) and `exec_cache` (keyed by regex ID).
* **Weak Cache Check**: In `findMatch`, the retrieval check for `exec_cache` requires an exact match of the search start position:
  ```zig
  if (mm.anchor_start == hard_start and mm.start > hard_start) { ... }
  ```
  As the scanner advances horizontally across a line, `hard_start` changes, rendering the cached match immediately useless even if the match starts far ahead (e.g. `mm.start > hard_start`).
* **Cache Exclusions**: 
  - If a regex matches exactly at `hard_start` (`mm.start == hard_start`), it is *never* stored or retrieved from `exec_cache`.
  - In `matchBegin`, successful matches (`m.count > 0`) for `rx_match` and `rx_begin` are **never cached** in `match_cache`; only mismatches (`m.count == 0`) are stored.

#### Why it is a bottleneck:
TextMate grammars consist of hundreds of nested rules (as seen in [c.json](file:///home/iceman/Developer/zig/textmate.zig/src/resources/grammars/c.json)). The same regex rules are repeatedly tested at adjacent positions. Without effective caching of successful matches and range-based validation, the parser constantly falls back to executing slow regex engine searches.

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

### 4. Heap Allocations via Oniguruma Regions
**Location**: [Parser.findMatch](file:///home/iceman/Developer/zig/textmate.zig/src/parser.zig#L501-L518)

#### The Issue:
Inside the regex matching block:
```zig
const reg = blk: {
    var result: oni.Region = .{};
    _ = @constCast(re).searchAdvanced(block, hard_start, hard_end, &result, ...) catch ...
    break :blk result;
};
...
defer @constCast(r).deinit();
```
An [oni.Region](file:///home/iceman/Developer/zig/textmate.zig/pkg/oniguruma/region.zig#L4-L51) struct is declared on the stack, but Oniguruma dynamically allocates internal memory buffers for capture ranges (`beg` and `end` arrays) during search. The `defer @constCast(r).deinit()` call invokes `onig_region_free`, which releases this memory.

#### Why it is a bottleneck:
This results in heap allocation and deallocation for **every single regex execution**. Because Oniguruma allows reusing a pre-allocated `onig_region` to avoid re-allocating memory if the buffer size is sufficient, discarding and recreating the region on every search is highly inefficient.

---

### 5. Over-evaluation of Child Patterns during End Matches
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
Add cached injection fields to the `Parser` struct:
```zig
left_injections: std.ArrayList(*Syntax),
right_injections: std.ArrayList(*Syntax),
injections_dirty: bool = true,
```
Mark `injections_dirty = true` on `push`, `pop`, and `deserialize`. In `matchPatterns`, only re-collect and re-evaluate injections if `injections_dirty` is true, otherwise reuse the cached list.

### Recommendation 2: Improve Regex Cache Matching Conditions
Modify `findMatch` and `matchBegin`/`matchEnd` cache checks to support range-based validation for non-anchored patterns:
1. A cached mismatch (`count == 0`) is valid for all starting positions $P \ge \text{anchor\_start}$.
2. A cached match (`count > 0`) is valid for all starting positions $P$ where $\text{anchor\_start} \le P \le \text{match.start}$.
This permits caching successful matches and increases the cache hit rate exponentially as the parser moves forward.

### Recommendation 3: Pre-parse Scope Selectors
Parse selector strings once into an AST or token stream during grammar JSON loading, storing the structured representation inside `Syntax` injection nodes. This eliminates character-by-character string parsing at runtime.

### Recommendation 4: Reuse Oniguruma Region Buffers
Keep a thread-local or parser-owned `oni.Region` instance. Reuse it across searches instead of creating and freeing region buffers on every regex execution.

### Recommendation 5: Optimize End-Match Short-Circuiting
Relax the short-circuiting condition in `parseLine` so that if an end match is found at the current position, the parser can skip child pattern matching without requiring the match to extend to the end of the line.
