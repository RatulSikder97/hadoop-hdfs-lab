# Apache Hadoop cluster (3.4.1)

An alternative to the bde2020 cluster in the parent folder, built on the
**official `apache/hadoop:3.4.1`** images. It includes a **NodeManager**, so YARN
runs real job containers (not just local mode).

| File | Purpose |
|------|---------|
| `docker-compose.yml` | namenode, datanode, resourcemanager, nodemanager |
| `config` | Hadoop config in the apache-image `<FILE>.XML_<property>` format |

## Run (from this folder)

```bash
sudo docker compose up -d      # start
sudo docker compose down       # stop
```

Web UIs: NameNode <http://localhost:9870> · YARN <http://localhost:8088>

## Notes

- The `apache/hadoop` image may not ship `python3`. To run the Python MapReduce
  job, install it in the containers first.
- The Hadoop Streaming jar here is at
  `/opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.4.1.jar`
  (different path/version from the bde2020 cluster).
