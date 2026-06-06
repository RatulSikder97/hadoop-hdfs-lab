#!/usr/bin/env python3
import sys

# The Mapper reads data line-by-line from standard input
for line in sys.stdin:
    line = line.strip()
    words = line.split()
    for word in words:
        print('%s\t1' % word)
