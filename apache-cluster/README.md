# Apache Hadoop cluster (3.4.1)

An alternative to the bde2020 cluster in the parent folder, built on the
**official `apache/hadoop:3.4.1`** images. It includes a **NodeManager**, so YARN
runs real job containers (not just local mode).

| File | Purpose |
|------|---------|
| `docker-compose.yml` | namenode, datanode, resourcemanager, nodemanager |
| `Dockerfile` | Adds `python3` to the apache/hadoop image (only if missing) |
| `config` | Hadoop config in the apache-image `<FILE>.XML_<property>` format |

## Run (from this folder)

```bash
sudo docker compose up -d      # start (first run builds the image)
sudo docker compose down       # stop
```

Web UIs: NameNode <http://localhost:9870> · YARN <http://localhost:8088>

## Notes

- This cluster uses the **same container names and ports** (`9870`, `8088`) as the
  bde2020 cluster in the parent folder, so **only run one at a time**. Stop the
  other first with `docker compose down` in the relevant folder.
- `python3` is **baked into the image** by `Dockerfile` (it auto-detects the base
  image's package manager and installs python3 only if it isn't already there),
  so the Python MapReduce / Streaming job works out of the box.
- The Hadoop Streaming jar here is at
  `/opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.4.1.jar`
  (different path/version from the bde2020 cluster).

See [`../README.md`](../README.md) for the full lab walkthrough (Tasks 2 & 3).
