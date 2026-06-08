#!/usr/bin/env python3
"""
Task 2 Reducer — Feature Statistics
"""
import sys

count = 0
total_sum = 0.0
min_val = float('inf')
max_val = float('-inf')

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        _key, value = line.split('\t')
        value = float(value)
    except ValueError:
        continue

    count += 1
    total_sum += value
    if value < min_val:
        min_val = value
    if value > max_val:
        max_val = value

if count > 0:
    mean_val = total_sum / count
    def _fmt(x):
        return str(int(x)) if x == int(x) else "{:.4f}".format(x)
    print("COUNT\t{}".format(count))
    print("MIN\t{}".format(_fmt(min_val)))
    print("MAX\t{}".format(_fmt(max_val)))
    print("SUM\t{}".format(_fmt(total_sum)))
    print("MEAN\t{:.4f}".format(mean_val))
