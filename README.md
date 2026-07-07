# TextMate Parser in Zig

A highly performant, fully spec-compliant TextMate grammar parser and syntax highlighter library written in Zig. This project is powered by the **Oniguruma** regular expression engine (statically linked, compiled from C sources).

## Features

- **Spec-Compliant Parsing**: Support for complex TextMate nested scopes, lookahead/lookbehind assertions, and cross-line state transitions.
- **Embedded Resources**: Built-in support for popular themes (e.g., Dracula, Monokai) and language grammars from the [ShikiJs](https://github.com/shikijs/textmate-grammars-themes) project.
- **Optimized Regex Caching**: Efficient match and execution caching pipelines to minimize Oniguruma search overhead on consecutive lines.
- **Pluggable Processors**: Customizable parsing event handlers (e.g., `RenderProcessor` for ANSI terminals, `RenderHtmlProcessor` for HTML output, `DumpProcessor` for debugging scopes).
- **Fast and Lightweight**: Minimal memory overhead, using Zig's custom allocator models.

---

## Getting Started

### Requirements
- **Zig 0.15.x** or **0.16.0-dev**

### Building the Project
Clone the repository and compile the library and example applications:
```sh
zig build
```

### Running Examples
You can run the included `catx` utility (which highlights source files directly to your ANSI terminal):
```sh
# Run catx on a file (defaulting to the Dracula theme)
./zig-out/bin/catx src/parser.zig

# Customize the theme or grammar
./zig-out/bin/catx -t monokai -g source.zig src/parser.zig

# Output highlighted HTML instead of ANSI terminal codes
./zig-out/bin/catx -m src/parser.zig > output.html
```

---

## Library Usage

To integrate `textmate.zig` into your own Zig project:

### 1. Configure `build.zig`
Add the textmate library as a dependency in your `build.zig.zon`:
```zig
.{
    .name = "my-project",
    .version = "0.1.0",
    .dependencies = .{
        .textmate = .{
            .path = "../path/to/textmate.zig", // or a Git URL & hash
        },
    },
}
```

Then expose the module in your executable build step in `build.zig`:
```zig
const textmate_dep = b.dependency("textmate", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("textmate", textmate_dep.module("textmate"));
```

### 2. Basic Code Example
Here is the minimal boilerplate required to initialize the library, load a theme & grammar, and parse a file line by line:

```zig
const std = @import("std");
const tm = @import("textmate");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 1. Initialize Oniguruma Engine
    try tm.oni.init(&.{tm.oni.Encoding.utf8});
    try tm.oni.testing.ensureInit();

    // 2. Initialize Theme and Grammar Libraries
    try tm.ThemeLibrary.initLibrary(allocator);
    defer tm.ThemeLibrary.deinitLibrary();
    
    try tm.GrammarLibrary.initLibrary(allocator);
    defer tm.GrammarLibrary.deinitLibrary();

    const thl = tm.ThemeLibrary.getLibrary().?;
    const gml = tm.GrammarLibrary.getLibrary().?;

    // Load embedded themes/grammars, or custom JSON files
    try thl.addEmbeddedThemes();
    try gml.addEmbeddedGrammars();

    const theme = try thl.themeFromName("dracula-soft");
    const grammar = try gml.grammarFromScopeName("source.zig");

    // 3. Initialize Parser, ParseState, and Processor
    var parser = try tm.Parser.init(allocator, grammar);
    defer parser.deinit();

    var state = try parser.initState();
    defer state.deinit();

    // RenderProcessor formats output with ANSI escape sequences
    var processor = try tm.RenderProcessor.init(allocator);
    defer processor.deinit();

    // Connect them
    parser.processor = &processor;
    parser.atoms = &theme.atoms;
    processor.theme = theme;
    processor.state = &state;

    // 4. Feed Source Lines to the Parser
    const source_code = 
        \\pub fn main() !void {
        \\    std.debug.print("Hello, World!\n", .{});
        \\}
    ;

    processor.startDocument();
    var it = std.mem.splitScalar(u8, source_code, '\n');
    var first_line = true;
    while (it.next()) |line| {
        // Parse the line (the parser expects the newline character to be included)
        const line_with_newline = try std.fmt.allocPrint(allocator, "{s}\n", .{line});
        defer allocator.free(line_with_newline);

        _ = try parser.parseLine(&state, line_with_newline, first_line);
        first_line = false;
    }
    processor.endDocument();
}
```

---

## Running Tests
Run the entire unit and integration test suite to verify spec correctness:
```sh
zig build tests
```

## References and Inspiration
- [tiny-textmate (C)](https://github.com/icedman/tiny-textmate/)
- [tm-parser (C++)](https://github.com/icedman/tm-parser)
- [Ghostty Oniguruma Bindings](https://github.com/ghostty-org/ghostty)
