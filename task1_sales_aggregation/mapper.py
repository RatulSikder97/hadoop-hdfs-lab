#!/usr/bin/env python3
import sys

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    parts = line.split(',')
    if len(parts) != 2:
        continue
    product, price = parts[0].strip(), parts[1].strip()
    print(f"{product}\t{price}")
