# Task 1 — Sales Aggregation

Compute **total revenue per product** from a CSV of transactions.

## Files
- `sales.txt` — input (`Product,Price` per line)
- `mapper.py` — emits `Product \t Price`
- `reducer.py` — sums prices per product (uses Hadoop's sort guarantee)
- `run.sh` — runs the job on the cluster
- `output.txt` — captured result

## Run
```bash
./run.sh
```

## Output
```
Laptop   2500
Monitor  300
Phone    700
Tablet   700
```

## Note
Container ships Python 3.5 → no f-strings. Use `"{}".format(...)`.
