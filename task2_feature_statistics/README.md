# Task 2 — Feature Statistics

Compute global **COUNT / MIN / MAX / SUM / MEAN** over 1000 random integers (0–499).

## Files
- `mapper.py` — emits `ALL_STATS \t value` (one key → one reducer)
- `reducer.py` — running min/max/sum/count → final stats
- `run.sh` — generates `features.txt`, uploads to HDFS, runs job
- `output.txt` — captured result

## Run
```bash
./run.sh
```

## Output (example)
```
COUNT   1000
MIN     0
MAX     499
SUM     251255
MEAN    251.2550
```
Values vary per run (random input). MIN≈0, MAX≈499, MEAN≈250 expected.

## Notes
- Single hardcoded key (`ALL_STATS`) funnels all records to one reducer → true global stats.
- Python 3.5 → no f-strings.
- RM JVM crash under qemu fixed in `docker-compose.yml` via `-XX:-UseBiasedLocking -XX:+UseSerialGC`.
