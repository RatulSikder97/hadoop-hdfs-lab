#!/usr/bin/env python3
#
# MapReduce MAPPER for the word-count job (Hadoop Streaming).
# Reads text on stdin, splits each line into words, and emits "word<TAB>1" per
# word. It does no counting — summing is the reducer's job.
#
import sys

# The Mapper reads data line-by-line from standard input
for line in sys.stdin:
    line = line.strip()
    words = line.split()
    for word in words:
        print('%s\t1' % word)
