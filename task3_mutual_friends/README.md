# Task 3 — Mutual Friend Recommendation

Given an adjacency list of users → friends, recommend mutual friends for every
pair of users **who are not already friends**.

## Files
- `friends.txt` — input adjacency list (`User:F1,F2,...` per line)
- `mapper.py` — emits `DIRECT` markers + pair-with-mutual-link tuples
- `reducer.py` — drops pairs marked `DIRECT`, lists mutuals for the rest
- `run.sh` — runs the job on the cluster
- `output.txt` — captured result

## Run
```bash
./run.sh
```

## Output
```
A-E   B,C
B-D   A,C
D-E   C
```
A–E share mutuals B and C, B–D share A and C, D–E share C.
All other pairs are already direct friends → skipped.

## Algorithm

**Mapper** for each line `U:F1,F2,...`
- emit `sorted(U,Fi) \t DIRECT` for every friend Fi
- emit `sorted(Fi,Fj) \t U` for every pair `(Fi,Fj)` in `itertools.combinations(friends, 2)`

Sorting the pair guarantees `(X,Y)` and `(Y,X)` reach the same reducer.

**Reducer** for each pair key
- if any value is `DIRECT` → users already friends → skip
- else → deduped values are the mutual friends → emit `Pair \t M1,M2,...`

## Notes
- Python 3.5 → no f-strings.
- Pairs always emitted in alphabetical order (so the reducer key space is well-defined).
- For dense graphs the combinations blow up quadratically with each user's
  degree — fine here, would need a secondary-sort optimisation at real scale.
