#!/usr/bin/env python3
"""
Reducer for Task 3 — Mutual Friend Recommendation.

For each pair key the reducer receives a list of values.
  - if "DIRECT" appears → the two users are already friends → skip
  - otherwise           → the values are the mutual friends → emit
"""
import sys


def flush(pair, is_direct, mutuals):
    if pair is None or is_direct or not mutuals:
        return
    uniq = sorted(set(mutuals))
    print("{}\t{}".format(pair, ",".join(uniq)))


current_pair = None
is_direct = False
mutuals = []

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    pair, value = line.split('\t', 1)

    if pair != current_pair:
        flush(current_pair, is_direct, mutuals)
        current_pair = pair
        is_direct = False
        mutuals = []

    if value == "DIRECT":
        is_direct = True
    else:
        mutuals.append(value)

flush(current_pair, is_direct, mutuals)
