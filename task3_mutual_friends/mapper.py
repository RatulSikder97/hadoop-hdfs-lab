#!/usr/bin/env python3
"""
Mapper for Task 3 — Mutual Friend Recommendation.

Input  : "User:Friend1,Friend2,..." (adjacency list)
Output :
    1. "X-Y \t DIRECT"   for every direct edge (X,Y)
                         (so the reducer can skip already-friends pairs)
    2. "X-Y \t U"        for every pair (X,Y) of U's friends
                         (means: U is a mutual friend of X and Y)

All pair keys are sorted alphabetically so that (X,Y) and (Y,X)
both reach the same reducer.
"""
import sys
import itertools


def make_pair(a, b):
    return "{}-{}".format(*sorted([a, b]))


for line in sys.stdin:
    line = line.strip()
    if not line or ':' not in line:
        continue
    user, friends_str = line.split(':', 1)
    user = user.strip()
    friends = [f.strip() for f in friends_str.split(',') if f.strip()]

    # 1. mark each direct friendship
    for friend in friends:
        print("{}\tDIRECT".format(make_pair(user, friend)))

    # 2. every pair of this user's friends has `user` as a mutual link
    for f1, f2 in itertools.combinations(friends, 2):
        print("{}\t{}".format(make_pair(f1, f2), user))
