# Multi-PC HDFS Cluster — Distributed Across Real Machines (Lab 3)

A genuinely distributed Apache Hadoop 3.2.1 HDFS cluster whose nodes run on
**separate physical PCs** over a LAN — one NameNode and three DataNodes, four
machines in total. Where Lab 2 scaled DataNode *replicas* on a single Docker
host, this lab spreads them across the network and handles the real cross-host
networking that makes HDFS work between machines.

## Cluster Architecture

| Node       | Host (LAN IP)             | Compose file                | Role                                  |
|------------|---------------------------|-----------------------------|---------------------------------------|
| NameNode   | 10.100.200.101 (this Mac) | docker-compose.namenode.yml | HDFS master — namespace + block metadata |
| DataNode 1 | 10.100.200.112            | docker-compose.datanode.yml | block storage                         |
| DataNode 2 | 10.100.201.210            | docker-compose.datanode.yml | block storage                         |
| DataNode 3 | 10.100.202.213 †          | docker-compose.datanode.yml | block storage                         |

† Placeholder — replace with the 3rd PC's real LAN IP in `check-cluster.sh`
(`DN_IPS`). The DataNode itself needs no edit; it advertises whatever you pass
in `DN_HOST` at start time.

All hosts sit in the same `10.100.200.0/22` subnet (covers 10.100.200.0–
10.100.203.255), so every machine reaches every other directly.
`dfs.replication=3`, so every block is copied to all three DataNodes — the
cluster survives up to **two** nodes going offline.

The **same** `docker-compose.datanode.yml` runs on every DataNode PC; each one
advertises its own LAN IP through the `DN_HOST` environment variable at start
time, so there is exactly one DataNode file to maintain.

## Prerequisites

- Docker & Docker Compose on every machine
- All machines on the same LAN/subnet, able to reach each other's IPs
- Images run under `linux/amd64`; on Apple Silicon they run via qemu emulation

## Setup — the easy way (interactive wizard)

`cluster-setup.sh` generates every config file from a few prompts and can launch
the containers — no hand-editing.

**On the NameNode machine:**

```bash
./cluster-setup.sh namenode
```

It asks for the NameNode LAN IP, RPC/UI ports, how many DataNodes will join and
each one's IP, and the replication factor — then writes `hadoop.env`, both
compose files, `check-cluster.sh`, and `datanode-bundle.tgz`, and offers to start
the NameNode.

**On each DataNode PC** — copy `datanode-bundle.tgz` over, then:

```bash
tar -xzf datanode-bundle.tgz     # unpacks configs + the wizard
./cluster-setup.sh datanode
```

It reuses the NameNode's `hadoop.env` (so `fs.defaultFS` and replication match),
asks only for **this PC's LAN IP**, and starts the DataNode.

**Back on the NameNode host, verify:**

```bash
./check-cluster.sh
```

> Run it with no argument (`./cluster-setup.sh`) to pick the role from a menu.
> Prefer to wire it up by hand? The manual steps below do exactly the same thing.

## Files

| File                          | Purpose                                                        |
|-------------------------------|----------------------------------------------------------------|
| `cluster-setup.sh`            | Interactive wizard — generates the configs below and launches  |
| `docker-compose.namenode.yml` | NameNode service — runs on this Mac                            |
| `docker-compose.datanode.yml` | DataNode service — runs on every DataNode PC                   |
| `hadoop.env`                  | Shared HDFS configuration, used by both compose files          |
| `datanode-bundle.tgz`         | `hadoop.env` + datanode compose, zipped to copy to each PC     |
| `check-cluster.sh`            | Step-by-step health/verification script (run on NameNode host) |

## Quick Start

### 1. NameNode — on this PC (10.100.200.101)

```bash
docker compose -f docker-compose.namenode.yml up -d
docker logs -f namenode          # watch it come up
```

Web UI: http://10.100.200.101:9870 — the **Datanodes** tab shows who has joined.

### 2. DataNodes — on each of the 3 PCs

Copy `datanode-bundle.tgz` to the machine and unpack it (or copy `hadoop.env`
and `docker-compose.datanode.yml` into the same folder), then start the node
with **its own LAN IP** in `DN_HOST`:

```bash
tar -xzf datanode-bundle.tgz

DN_HOST=10.100.200.112 docker compose -f docker-compose.datanode.yml up -d   # DataNode 1
DN_HOST=10.100.201.210 docker compose -f docker-compose.datanode.yml up -d   # DataNode 2
DN_HOST=10.100.202.213 docker compose -f docker-compose.datanode.yml up -d   # DataNode 3 (use real IP)

docker logs -f datanode
```

`DN_HOST` is the address the NameNode and clients use to reach this node's data
ports (9866/9864/9867), so it **must** be that machine's real LAN IP. Omit it
and it defaults to `10.100.200.112` (DataNode 1). Each DataNode dials
`10.100.200.101:9000`, registers, and starts sending heartbeats + block reports.

### 3. Verify the cluster

On the NameNode host:

```bash
./check-cluster.sh           # guided, step-by-step  (-p pauses between steps)

# …or the one-liner:
docker exec namenode hdfs dfsadmin -report | grep "Live datanodes"
```

With all three nodes up you should see `Live datanodes (3)`. Quick read/write
test:

```bash
docker exec namenode bash -lc 'echo "hello from three-pc hdfs" > /tmp/t.txt && \
  hdfs dfs -mkdir -p /test && \
  hdfs dfs -put -f /tmp/t.txt /test/ && \
  hdfs dfs -cat /test/t.txt'
```

## How It Works — Cross-Host Networking

Running HDFS across machines (rather than one Docker host) needs a handful of
settings a single-host compose never hits. They all live in `hadoop.env`:

- **`fs.defaultFS` uses the LAN IP**, not a Docker service name — Docker's
  internal DNS doesn't cross hosts.
- The NameNode **binds `0.0.0.0`** (`dfs.namenode.{rpc,servicerpc,http}-bind-host`)
  but advertises `10.100.200.101`, so a port-published container is reachable
  from other PCs.
- **`dfs.client.use.datanode.hostname=true`** + **`dfs.datanode.hostname=<LAN IP>`**
  make block reads/writes reach each DataNode through its published ports.
- **`dfs.namenode.datanode.registration.ip-hostname-check=false`** lets
  DataNodes register by IP without reverse DNS.
- **`HADOOP_OPTS=-XX:-UseBiasedLocking -XX:+UseSerialGC -XX:-UsePerfData`**
  stabilises OpenJDK 8 under qemu on Apple Silicon.

> bde2020 image env naming: `_` → `.`, `___` → `-`
> (so `dfs_namenode_rpc___bind___host` == `dfs.namenode.rpc-bind-host`).

## Replication

`hadoop.env` sets `dfs.replication=3` — every block is copied to all three
DataNodes, surviving up to two offline. Blocks only reach full replication once
3 DataNodes are live; with fewer, they stay under-replicated and HDFS heals them
automatically as the rest join. Changing the factor affects **new** files only —
re-replicate existing data with `docker exec namenode hdfs dfs -setrep -R 3 /`.

Tune it in `hadoop.env`:

- `=1` → spread blocks, no redundancy (max usable space)
- `=2` → survive one node offline
- `=3` → survive two nodes offline (current)

## Troubleshooting

- **Write hangs at "could only be replicated to 0 nodes"** — a firewall is
  blocking a DataNode's port `9866`. Each DataNode PC must reach
  `10.100.200.101:9000` and `:9870`; this PC (and any client) must reach every
  DataNode's `9866/9864/9867`.
- **A DataNode's IP changed** — just restart that node with the new
  `DN_HOST=<new IP>` (no file edit). If the **NameNode** IP changes, edit
  `fs.defaultFS` in `hadoop.env` and recreate the NameNode.
- **You edited `hadoop.env` or the datanode compose** — regenerate the bundle so
  each PC gets the new config:
  `tar -czf datanode-bundle.tgz hadoop.env docker-compose.datanode.yml`.

---

Part of the [Hadoop & HDFS Lab](https://github.com/RatulSikder97/hadoop-hdfs-lab) series ·
Branches: [`main`](https://github.com/RatulSikder97/hadoop-hdfs-lab) ·
[`lab-1`](https://github.com/RatulSikder97/hadoop-hdfs-lab/tree/lab-1) ·
[`lab-2`](https://github.com/RatulSikder97/hadoop-hdfs-lab/tree/lab-2) ·
[`lab-3`](https://github.com/RatulSikder97/hadoop-hdfs-lab/tree/lab-3)
