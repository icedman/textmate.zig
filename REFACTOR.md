# Performance

O(n) ~ Time is linear to number of lines

# Benchmarks 

## Release mode runs


## Debug mode runs

CPU: AMD Ryzen AI 9 HX 370 (24) @ 5.16 GHz

* with atom based scope matching

lines: 222905
execs: 18938979
execs/line: 84
recompile: 0
skips: 74704939
done in 43.564070s
state depth: 1
retained: 1
grammar: c
theme: dracula-soft

* aggressive caching

lines: 222905
execs: 16398602
skips: 51936514
done in 158.582904s
state depth: 1

lines: 222905
execs: 66425451
skips: 1878126
done in 181.834465s
state depth: 1

CPU: Intel(R) Core(TM) i5-6200U (4) @ 2.80 GHz

* with scope cache

sqlite3.c
lines: 222905
execs: 74863391
skips: 3067456
done in 1060.909353s
state depth: 105

lines: 222905
execs: 74951684
skips: 2979163
done in 1161.408925s
state depth: 105

commit 23d0eb1c32efbf341ea22050bd47865aaed5c69d

* fixed include resolution .. more patterns have to be checked now 

tinywl.c
lines: 1002
execs: 368243
skips: 6020
done in 0.476562s
state depth: 10

sqlite3.c
lines: 222905
execs: 76223680
skips: 1707167
done in 203.368550s
state depth: 105

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



