# Distributed Hadoop Cluster — Fault Tolerance & MapReduce

A multi-node Apache Hadoop 3.2.1 cluster running on Docker Compose, used to study HDFS
fault tolerance and to run a set of MapReduce jobs written in Python via Hadoop Streaming.

## Cluster Architecture

| Service | Role |
|---------|------|
| `namenode` | HDFS master — manages the filesystem namespace and block metadata |
| `datanode` (×3) | HDFS workers — store the actual data blocks (replicated) |
| `resourcemanager` | YARN — schedules and runs MapReduce jobs |

The `datanode` service has no fixed container name, which is what allows it to be scaled
to multiple replicas with a single flag.

## Prerequisites
- Docker and Docker Compose

## Quick Start

```bash
# 1. Build and start the cluster with 3 DataNodes
docker compose up -d --build --scale datanode=3

# 2. Verify the cluster is healthy (should report 3 live DataNodes)
docker exec namenode hdfs dfsadmin -report | grep "Live datanodes"

# 3. Run a task (example)
./task1_sales_aggregation/run.sh
```

Web UIs (once the cluster is up):
- NameNode: http://localhost:9870
- ResourceManager: http://localhost:8088

## Repository Structure

```
.
├── docker-compose.yml          # cluster definition
├── hadoop.env                  # shared Hadoop configuration
├── namenode/ , datanode/       # per-service Dockerfiles
├── task1_sales_aggregation/    # total revenue per product
├── task2_feature_statistics/   # global COUNT/MIN/MAX/SUM/MEAN
├── task3_mutual_friends/       # mutual-friend recommendation
└── fault_tolerance/            # HDFS node-failure & recovery demo
```

## Tasks

| Task | Description | Run |
|------|-------------|-----|
| **1 — Sales Aggregation** | Sum total revenue per product from `Product,Price` records. | `./task1_sales_aggregation/run.sh` |
| **2 — Feature Statistics** | Compute global COUNT/MIN/MAX/SUM/MEAN over 1,000 integers. | `./task2_feature_statistics/run.sh` |
| **3 — Mutual Friends** | Recommend mutual friends for non-friend user pairs. | `./task3_mutual_friends/run.sh` |
| **Fault Tolerance** | Replicate a file, kill a DataNode, watch HDFS self-heal. | `./fault_tolerance/run.sh` |

Each task directory contains its own `README.md`, the `mapper.py`/`reducer.py` (or demo
script), the input data, a `run.sh` launcher, and a captured `output.txt`.

## Implementation Notes
- **Python 3.5** ships in the container images, so the scripts avoid f-strings and use
  `"{}".format(...)` instead.
- **qemu JVM workaround:** on Apple Silicon (amd64 emulated on arm64) the OpenJDK 8 JVM
  can abort at a safepoint (`guarantee(PageArmed == 0) failed`). This is mitigated in
  `docker-compose.yml` with `-XX:-UseBiasedLocking -XX:+UseSerialGC -XX:-UsePerfData`.
- **Persistence:** the images use anonymous volumes for HDFS metadata, so the NameNode
  container should be *restarted* rather than *recreated* to avoid reformatting HDFS.
```bash
docker compose down            # stop and remove containers when finished
```
