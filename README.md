# Textmate Parser in Zig

This is textmate parser implementation in Zig based on my tiny-textmate parser (in C).

Based on:

The C version [tiny-textmate](https://github.com/icedman/tiny-textmate/)

The C++ version from Macromate [tm-parser](https://github.com/icedman/tm-parser)

**THIS LIBRARY IS NOT YET READY FOR CONSUMPTION**

# Themes and Grammars

Themes and grammars were taken from the [ShikiJs](https://github.com/shikijs/textmate-grammars-themes) project.

# Oniguruma Package

Copied from Ghostty

# build

Building the library requires **zig 0.15**

```sh
zig build
```

# usage

```sh
zig build run -- {filename}
```
or

```sh
./zig-out/bin/catx {filename} 
```
Run 'help' for instructions on selecting a theme and other info

```sh
./zig-out/bin/catx -h 
```

### Using the library

** minimal boilerplate to parse and render **

1. Load a Theme
2. Load a Grammar
3. Init a Parser
4. Init an initial ParseState
5. Create a Processor
6. Read a file line by line and feed to Parser

** library **

Themes and Grammars may be handled by the ThemeLibrary and GrammarLibrary

Init the libraries by adding a resource folder

** Processors **

Processors have callback functions for parsing events such as when a token range is found.

Assign a Processor to a Parser

Assign a ParserState to a Processor

