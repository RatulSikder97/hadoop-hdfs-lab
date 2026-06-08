#!/usr/bin/env python3
import sys

for line in sys.stdin:
    value = line.strip()
    if not value:
        continue
    try:
        # validate that it is numeric — skip bad rows silently
        float(value)
    except ValueError:
        continue
    print("ALL_STATS\t{}".format(value))
