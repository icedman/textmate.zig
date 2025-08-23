# Textmate Parser in Zig

This is textmate parser implementation in Zig based on my tiny-textmate parser (in C).

Based on:
The C version [tiny-textmate](https://github.com/icedman/tiny-textmate/)
The C++ version from Macromate [tm-parser](https://github.com/icedman/tm-parser)

** THIS LIBRARY IS NOT YET READY FOR CONSUMPTION **

# Themes and Grammars

Themes and grammars were taken from the ShijiJs project:

https://github.com/shikijs/textmate-grammars-themes

# Oniguruma Package

Copied from Ghostty

# build

```sh
zig build
```

# usage

```sh
zig build run
```
or

```sh
./zig-out/bin/textmate_zig ./src/main.zig
```
