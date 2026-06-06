#!/usr/bin/env python3
#
# MapReduce REDUCER for the word-count job (Hadoop Streaming).
# Receives "word<TAB>count" lines already sorted by key (Hadoop's shuffle & sort),
# sums the counts for each word, and emits "word<TAB>total".
#
import sys

current_word = None
current_count = 0

# The Reducer receives sorted input from Hadoop via standard input
for line in sys.stdin:
    line = line.strip()
    word, count = line.split('\t', 1)

    try:
        count = int(count)
    except ValueError:
        continue

    # If the word matches the previous word, add to the count
    if current_word == word:
        current_count += count
    else:
        # If it's a new word, output the previous word's total count
        if current_word:
            print('%s\t%s' % (current_word, current_count))
        current_word = word
        current_count = count

# Output the very last word
if current_word == word:
    print('%s\t%s' % (current_word, current_count))
