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
