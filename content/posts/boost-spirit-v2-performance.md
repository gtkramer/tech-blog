
---
title: "Boost Spirit v2 Performance with STL Files"
date: 2018-03-26T21:41:00-07:00
draft: true
---

``` bash
Run 5 times, averages to 8.418 seconds

#include <gperftools/profiler.h>
ProfilerStart("/home/george/Documents/Projects/C++/amsg/gperf.lol");
parseBinaryFile();
ProfilerStop();

$ g++ --std=c++14 -Wpedantic parser.cpp -lprofiler -o parser

$ CPUPROFILE_FREQUENCY=100 ./parser
Length of file: 11723284
Parsing SUCCEEDED!
Number of facets parsed: 234464
PROFILE: interrupts/evictions/bytes = 275/29/105928

$ CPUPROFILE_FREQUENCY=500 ./parser
Length of file: 11723284
Parsing SUCCEEDED!
Number of facets parsed: 234464
PROFILE: interrupts/evictions/bytes = 1380/411/480952

$ CPUPROFILE_FREQUENCY=1000 ./parser
Length of file: 11723284
Parsing SUCCEEDED!
Number of facets parsed: 234464
PROFILE: interrupts/evictions/bytes = 2769/1023/885728

$ CPUPROFILE_FREQUENCY=2000 ./parser
Length of file: 11723284
Parsing SUCCEEDED!
Number of facets parsed: 234464
PROFILE: interrupts/evictions/bytes = 2727/1002/870808

$ pprof --dot ./parser ../gperf.lol > gperf.dot
$ dot -Tsvg gperf.dot -o gperf.svg

Cannot use heap profiler because not using tcmalloc anywhere.


pacman -S valgrind
valgrind --tool=callgrind ./parser
pip3 install gprof2dot
gprof2dot --format=callgrind --output=callgrind.dot callgrind.out.9066
dot -Tsvg gperf.dot -o gperf.svg
```