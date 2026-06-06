#!/usr/bin/env python3
"""MapReduce reducer for the word-count job (Hadoop Streaming).

Reads "word<TAB>count" pairs from standard input. Hadoop's shuffle-and-sort
phase guarantees the pairs arrive grouped and sorted by word, so the reducer
just sums consecutive counts for the same word and emits "word<TAB>total".
"""
import sys


def main():
    current_word = None
    current_count = 0

    for line in sys.stdin:
        word, _, count = line.strip().partition("\t")
        try:
            count = int(count)
        except ValueError:
            continue  # skip malformed lines

        if word == current_word:
            current_count += count
        else:
            if current_word is not None:
                print("%s\t%s" % (current_word, current_count))
            current_word = word
            current_count = count

    # Emit the final word once the input is exhausted.
    if current_word is not None:
        print("%s\t%s" % (current_word, current_count))


if __name__ == "__main__":
    main()
