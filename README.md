# textmate parser

This is textmate parser implementation in Zig based on my tiny-textmate parser (in C).

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
./zig-out/bin/textmate_zig ./data/tinywl.c
```

# progress

commit 08b5493bd89bcc100e07956be9a5e7a8efe8beb5 
* some regex match caching
* scope - style resolution (very primitive, no nesting)

CPU: AMD Ryzen AI 9 HX 370 (24) @ 5.16 GHz

tinywl.c (1002 lines)
execs: 324327
skips: 5981
done in 0.492104s
state depth: 2

sqlite3.c (222905 lines)
execs: 66128096
skips: 1557716
done in 88.919690s
state depth: 2

