# Big Data Lab — Hadoop & HDFS

A single-node Hadoop cluster (HDFS + YARN) run in Docker Compose, used to explore
**HDFS block splitting** and a **Python MapReduce word-count** via Hadoop Streaming.

> **Author:** Ratul Sikder
> **Hadoop:** 3.2.1 (bde2020 images) · **Containers:** namenode, datanode, resourcemanager

---

## Repository layout

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Defines the 3-node cluster (bde2020 images + python3) |
| `hadoop.env` | Hadoop / HDFS / YARN configuration |
| `apache-cluster/` | Alternative cluster on official **apache/hadoop:3.4.1** images (+ NodeManager) |
| `Dockerfile.python` | Layers `python3` onto the base images (needed for Streaming) |
| `mapper.py` | MapReduce **mapper** — emits `word \t 1` |
| `reducer.py` | MapReduce **reducer** — sums counts per word |
| `start-cluster.sh` | Build images (with python3) and start the cluster |
| `run-block-splitting.sh` | Task 2 — block-splitting experiment + `fsck` |
| `run-wordcount.sh` | Task 3 — submit the Python MapReduce job |
| `fetch-output.sh` | Copy the job result out of HDFS to the host |
| `setup-python.sh` | (fallback) install python3 into running containers |
| `sample-output.txt` | Trimmed word-count result (full output is generated) |

---

## Prerequisites

- Docker & Docker Compose
- If your user is not in the `docker` group, prefix the commands below with `sudo`.

---

## How to run

All commands are run from this directory.

### 1. Start the cluster (builds images with python3 baked in)

```bash
sudo bash start-cluster.sh
```

Web UIs once it's up: NameNode <http://localhost:9870> · YARN <http://localhost:8088>

> **Alternative — newer Apache images:** to run the cluster on the official
> `apache/hadoop:3.4.1` images (with a real NodeManager / working YARN) instead,
> use the `apache-cluster/` folder:
> ```bash
> cd apache-cluster && sudo docker compose up -d
> ```
> See `apache-cluster/README.md` for details.

### 2. Task 2 — HDFS block splitting

Generates a ~12 MB text file and uploads it to HDFS with a **forced 1 MB block
size**, then runs `fsck` to show how it is split into blocks.

```bash
sudo bash run-block-splitting.sh
```

### 3. Task 3 — Python MapReduce (word count)

Submits `mapper.py` + `reducer.py` to the cluster via Hadoop Streaming and prints
the top of the result.

```bash
sudo bash run-wordcount.sh
```

Save the full result to the host:

```bash
sudo bash fetch-output.sh      # writes wordcount.txt
```

### 4. Cleanup

```bash
sudo docker compose down
```

---

## Results

### Task 2 — block splitting

The input file is ~12 MB. Forcing a 1 MB block size splits it into **12 blocks**:

```
Total size: 12,088,895 B → 12 blocks
  blocks 0–10 : 1,048,576 bytes each   (11 full 1 MB blocks)
  block  11   :   554,559 bytes        (final partial block)
```

`fsck` reports the filesystem **HEALTHY**. Blocks show as "under-replicated"
(requested replication = 3, but only 1 DataNode exists) — expected for a
single-node cluster, not an error.

### Task 3 — word count

Each of the 200,000 input lines is `big data mapreduce hadoop distributed
processing line N`, so the 7 sentence words each total **200,000**, and every
unique line-number token totals **1** (see `sample-output.txt`):

```
big          200000
data         200000
distributed  200000
hadoop       200000
line         200000
mapreduce    200000
processing   200000
```
