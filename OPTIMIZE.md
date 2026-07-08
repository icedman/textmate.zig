# Performance Optimization Plan

Recent changes introduced in commit `100d838a63a428f930c0bf4e3f4ba55a38ad327e` added support for grammar injections and PHP injection test cases. While correct, this addition introduced a severe performance regression, making parsing roughly twice as slow.

This document details the root cause of the regression and outlines a phased optimization plan to restore and exceed previous parsing performance.

---

## 1. Root Cause Analysis

On every invocation of `matchPatterns` (which occurs multiple times per character/token to find matching rules), the parser now performs heavy redundant computations:

### A. Dynamic Scope Stack Processing
* The parser loops through the active `StateContext` stack on *every* matching attempt, extracts the scope names, splits them by spaces, and dynamically allocates and appends them to a temporary `scopes` list.

### B. Inefficient Selector Evaluation
* The parser loops through the injections of the active grammar as well as **all loaded grammars** in the library cache (`gml.cache`).
* For every injection rule, it calls `matchesScopeSelector(scopes, selector)`.
* `matchesScopeSelector` splits the selector by commas, trims whitespace, instantiates a `SelectorEvaluator` parser, and recursively parses the selector string (handling `&`, `|`, `-`, parenthesized sub-expressions, etc.) at runtime.

### C. No Invalidation Check
* The active injections list and parsed selectors are evaluated from scratch even if the parser position is merely moving forward on the same line under the **exact same scope stack**.

---

## 2. Proposed Optimizations

We propose three key optimizations to resolve these overheads, sorted by complexity and performance impact.

### Phase 1: Active Injection Caching (Highest Impact)
The active injections list depends solely on the current scope stack (`state.stack`). The scope stack only changes on three events:
1. A new context is **pushed** onto the stack.
2. A context is **popped** from the stack.
3. The parser state is **deserialized**.

**Implementation**:
* Add `left_injections: std.ArrayList(*Syntax)`, `right_injections: std.ArrayList(*Syntax)`, and `injections_dirty: bool = true` to the `Parser` struct.
* In `push`, `pop`, and `deserialize`, set `injections_dirty = true`.
* In `matchPatterns`, check if `injections_dirty` is true. If yes, clear the cached injection lists, compute the active injections (iterating grammars and evaluating selectors), and set `injections_dirty = false`.
* If `injections_dirty` is false, reuse the cached `left_injections` and `right_injections` directly.

> [!NOTE]
> Since the scope stack remains identical for the majority of pattern matching steps across a line, this cache will avoid >95% of all injection collections and selector evaluations.

---

### Phase 2: Pre-parsed Scope Selectors
Parsing the selector string (e.g. `L:text.html.php - (meta.embedded | comment)`) dynamically is extremely expensive. 

**Implementation**:
* Define a lightweight AST or token representation for scope selectors.
* Parse the selector string once when loading/parsing the JSON grammar into the `Syntax` tree.
* Store the pre-parsed selector representation on the `Syntax` injection nodes so that evaluation becomes a simple AST walk without any string parsing or allocation.

---

### Phase 3: Global Injection Indexing
Instead of iterating over `gml.cache` (all loaded grammars) in `matchPatterns` to collect injections:

**Implementation**:
* Maintain a global registry/index of all registered injection rules in `GrammarLibrary`.
* When a grammar is added, register its injections into the index.
* When matching, query the index instead of iterating over every grammar cache entry.

---

## 3. Expected Performance Recovery

| Optimization | Expected Speedup | Complexity |
| :--- | :--- | :--- |
| **Phase 1: Cache** | **~90% recovery** (back to original speed) | Low |
| **Phase 2: Pre-parsing** | **~5% speedup** | Medium |
| **Phase 3: Indexing** | **~3% speedup** | Medium |
