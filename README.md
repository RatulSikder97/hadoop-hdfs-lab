# Multi-PC HDFS Cluster — lab-3 (3 DataNodes)

A NameNode on this PC and **three** DataNodes on other PCs, over the LAN.
Replication is set to **3**, so every block is copied to all three nodes.

| Role     | Host             | Compose file                   |
|----------|------------------|--------------------------------|
| NameNode | 10.100.200.101   | docker-compose.namenode.yml    |
| DataNode | 10.100.200.112   | docker-compose.datanode.yml    |
| DataNode | 10.100.201.210   | docker-compose.datanode.yml    |
| DataNode | 10.100.202.213 ¹ | docker-compose.datanode.yml    |

¹ Placeholder IP for the 3rd PC — replace with its real LAN IP in
`check-cluster.sh` (`DN_IPS`). The DataNode itself needs no edit; it advertises
whatever you pass in `DN_HOST` at start time.

The same `docker-compose.datanode.yml` runs on **every** DataNode PC — you just
tell it that machine's LAN IP via the `DN_HOST` env var at start time.

Shared config: `hadoop.env` (must sit next to whichever compose file you run).

---

## 1. NameNode — on THIS PC (10.100.200.101)

```bash
docker compose -f docker-compose.namenode.yml up -d
docker logs -f namenode          # watch it come up
```
Web UI: http://10.100.200.101:9870  (Datanodes tab shows who has joined)

---

## 2. DataNodes — on each DataNode PC

Copy **two files** to the machine: `hadoop.env` and `docker-compose.datanode.yml`
(put them in the same folder), then on that machine start it with **its own LAN IP**
in `DN_HOST`:

```bash
# DataNode 1 (10.100.200.112):
DN_HOST=10.100.200.112 docker compose -f docker-compose.datanode.yml up -d

# DataNode 2 (10.100.201.210):
DN_HOST=10.100.201.210 docker compose -f docker-compose.datanode.yml up -d

# DataNode 3 (replace with its real LAN IP):
DN_HOST=10.100.202.213 docker compose -f docker-compose.datanode.yml up -d

docker logs -f datanode
```

`DN_HOST` is the IP the NameNode/clients use to reach this node's data ports
(9866/9864/9867), so it **must** be that machine's real LAN IP. If you omit it,
it defaults to `10.100.200.112` (DataNode 1).

Each DataNode dials `10.100.200.101:9000`, registers, and starts sending
heartbeats + block reports.

> All three example DataNode IPs are inside the same `10.100.200.0/22` subnet
> (covers 10.100.200.0–10.100.203.255), so `.200.112`, `.201.210` and `.202.213`
> reach each other and the NameNode directly.

---

## 3. Verify the cluster

On either PC:
```bash
# From the NameNode host:
docker exec namenode hdfs dfsadmin -report
```
With all three nodes up you should see `Live datanodes (3)` listing
`10.100.200.112`, `10.100.201.210` and the third PC's IP.

Or run the guided checker (from the NameNode host):
```bash
./check-cluster.sh        # or ./check-cluster.sh -p to pause between steps
```

Quick read/write test:
```bash
docker exec namenode bash -lc 'echo "hello from three-pc hdfs" > /tmp/t.txt && \
  hdfs dfs -mkdir -p /test && \
  hdfs dfs -put -f /tmp/t.txt /test/ && \
  hdfs dfs -cat /test/t.txt'
```

---

## Firewall note
Each DataNode PC must be able to reach **10.100.200.101:9000** (and 9870).
This PC (and any client) must reach **every** DataNode's
**9866/9864/9867** (e.g. `10.100.200.112:9866`, `10.100.201.210:9866`, …).
On the same LAN these are usually open; if a write hangs at "could only be
replicated to 0 nodes", a firewall is blocking a DataNode's 9866.

## Networking design (why it's set up this way)
- `fs.defaultFS` uses the LAN **IP**, not a docker service name (DNS doesn't
  cross hosts).
- NameNode binds `0.0.0.0` but advertises `10.100.200.101` via the
  `*-bind-host` settings, so a port-published container still works.
- `dfs.client.use.datanode.hostname=true` + `dfs.datanode.hostname=<LAN IP>`
  make block read/writes reach the DataNode through published ports on any
  Docker host (Linux, Docker Desktop, etc.).

## If an IP changes
- NameNode IP → edit `fs.defaultFS` in `hadoop.env`, recreate the NameNode.
- A DataNode IP → just restart that node with the new `DN_HOST=<new IP>`
  (no file edit needed).

## Replication
`hadoop.env` sets `dfs.replication=3`, so every block is copied to all three
DataNodes — the cluster survives up to **two** nodes going offline. Blocks only
reach full replication once 3 DataNodes are live; with fewer live nodes they
stay under-replicated (HDFS heals them automatically as the rest join).

Tune it to taste in `hadoop.env`:
- `=1` → spread blocks, no redundancy (max usable space)
- `=2` → survive one node offline
- `=3` → survive two nodes offline (current)

Changing `HDFS_CONF_dfs_replication` only affects **new** files. To re-replicate
existing data to the new factor, run e.g.
`docker exec namenode hdfs dfs -setrep -R 3 /`.
