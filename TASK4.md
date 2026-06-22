# Task 4 — Distributed Storage & Replication

Prove a file's blocks are copied across both worker PCs.

## Command

Run on the **master** (Mac):

```sh
docker exec -it namenode bash

# inside the container:
echo "Hadoop across multiple PCs is awesome" > sample.txt
hdfs dfs -mkdir -p /user/student
hdfs dfs -D dfs.replication=2 -put sample.txt /user/student/
hdfs fsck /user/student/sample.txt -files -blocks -locations
```

## Result

```
sample.txt 38 bytes, replicated: replication=2, 1 block(s):  OK
0. blk_1073741825_1001 len=38 Live_repl=2
   [192.168.65.1:9866 ...]    -> PC-B  10.100.201.161
   [192.168.65.1:19866 ...]   -> PC-C  10.100.201.133
Status: HEALTHY   Average block replication: 2.0
```

## How it works (algorithm)

Write flow: **Client → NameNode → DataNode pipeline**.

```
WRITE(file, R = replication):
  split file into blocks of 128 MB

  for each block B:
      # 1. CLIENT asks NameNode where to put it
      Client  -> NameNode : "where do I write B? (need R copies)"

      # 2. NameNode picks R DataNodes and returns an ordered list
      NameNode chooses targets = [DN1, DN2, ... DNr]   # by free space + rack
      NameNode -> Client : targets

      # 3. CLIENT writes to the FIRST DataNode only, as a pipeline
      Client -> DN1 : stream B
      DN1    -> DN2 : forward B      # DN replicates to next
      DN2    -> DN3 : forward B      # ... until R copies exist
      # ACKs travel back: DN3 -> DN2 -> DN1 -> Client

      # 4. Each DataNode confirms storage to the NameNode
      DNi -> NameNode : "I have B" (block report / heartbeat)

  Client -> NameNode : close file (commit)
```

Read / repair loop the NameNode runs forever:

```
every few seconds:
  each DataNode -> NameNode : heartbeat + block report
  for each block B:
      live = count of DataNodes currently holding B
      if live <  R:  schedule a copy  (under-replicated -> re-replicate)
      if live >  R:  delete a copy    (over-replicated)
```

- **Client streams to ONE node**, DataNodes pipeline the rest — the client's uplink isn't multiplied by R.
- `fsck -locations` lists the DataNodes per block. Two entries = two physical machines.
- Docker Desktop reports internal IP `192.168.65.1`, so the **port** identifies each PC: `:9866` = PC-B (`.161`), `:19866` = PC-C (`.133`).
- `Live_repl=2` + `HEALTHY` = block survives losing one PC.

## What if replication = 3?

We only have **2 DataNodes**, so 3 copies is impossible — HDFS can place at most 1 copy per DataNode.

```sh
hdfs dfs -D dfs.replication=3 -put -f sample.txt /user/student/sample3.txt
hdfs fsck /user/student/sample3.txt -files -blocks -locations
```

Expected result:

```
sample3.txt ... replication=3, 1 block(s):
0. blk_... Live_repl=2          # only 2 actual copies
Under-replicated blocks: 1 (100.0 %)
Status: HEALTHY                 # data is fine, just below target
Target Replicas: 3
```

- Write **still succeeds** with 2 copies; the file is fully readable.
- The NameNode marks the block **under-replicated** and keeps retrying.
- The moment a **3rd DataNode** joins, the repair loop above auto-copies the block to it → `Live_repl=3`, under-replicated clears. No re-upload needed.
- Rule: `actual copies = min(replication, number of live DataNodes)`.
