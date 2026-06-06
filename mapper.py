#!/usr/bin/env python3
"""MapReduce mapper for the word-count job (Hadoop Streaming).

Reads text from standard input, splits each line into words, and emits one
"word<TAB>1" pair per word. No counting is done here - that is the reducer's job.
"""
import sys


def main():
    for line in sys.stdin:
        for word in line.strip().split():
            print("%s\t1" % word)


if __name__ == "__main__":
    main()
