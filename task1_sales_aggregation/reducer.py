#!/usr/bin/env python3
import sys

current_product = None
current_sum = 0

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    product, price = line.split('\t')
    price = int(price)

    if current_product == product:
        current_sum += price
    else:
        if current_product is not None:
            print("{}\t{}".format(current_product, current_sum))
        current_product = product
        current_sum = price

if current_product is not None:
    print("{}\t{}".format(current_product, current_sum))
