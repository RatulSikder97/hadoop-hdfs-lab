# Fault Tolerance — HDFS Data Recovery

Demonstrates that HDFS survives a DataNode failure with **zero data loss**: a file
written with replication factor 3 stays readable after a node is stopped, and the
cluster heals automatically when the node returns.

## Prerequisites
Cluster up with **3 DataNodes**:
```bash
docker compose up -d --scale datanode=3
docker exec namenode hdfs dfsadmin -report | grep "Live datanodes"   # -> Live datanodes (3)
```

## Files
- `run.sh` — guided demo; pauses at each step so the output can be reviewed/captured
- `capture.sh` — non-interactive variant that records each step's output to `screenshots/`

## Run
```bash
./run.sh
```

## Steps
| Step | Action | Expected result |
|------|--------|-----------------|
| 1 | `hdfs dfs -D dfs.replication=3 -put testfile.txt /data/` | File written with 3 replicas |
| 2 | `hdfs fsck /data/testfile.txt -files -blocks -locations` | 1 block, 3 replicas, HEALTHY |
| 3 | `docker stop <datanode>` | One DataNode removed |
| 4 | `hdfs dfsadmin -report` | NameNode marks the node dead; file still HEALTHY & readable |
| 5 | `docker start <datanode>` | Node re-registers; cluster back to 3 live |

## Result
The cluster detects the failure, keeps serving the file from surviving replicas, and
re-replicates the under-replicated block automatically — recovering with no manual
intervention and no data loss.

## Notes
- A DataNode is marked **dead** only after the heartbeat timeout
  (`2 × dfs.namenode.heartbeat.recheck-interval + 10 × dfs.heartbeat.interval`,
  ~10.5 min by default). The interval can be lowered at runtime with
  `hdfs dfsadmin -reconfig namenode <host:port> start` to observe the dead state sooner.
- Fault tolerance (the file staying readable) is immediate regardless of that timeout.
