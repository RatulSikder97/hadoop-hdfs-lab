#!/bin/bash
# Run Task 1: Sales Aggregation on the Hadoop cluster.
# Run from the host machine. Requires the cluster to be up.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Copy code + input into the namenode container
docker cp "$DIR/mapper.py"  namenode:/tmp/t1_mapper.py
docker cp "$DIR/reducer.py" namenode:/tmp/t1_reducer.py
docker cp "$DIR/sales.txt"  namenode:/tmp/sales.txt

# 2. Put input into HDFS and run the streaming job
docker exec namenode bash -c '
  hdfs dfs -mkdir -p /data/task1
  hdfs dfs -put -f /tmp/sales.txt /data/task1/sales.txt
  hdfs dfs -rm -r -f /output/task1 2>/dev/null || true

  hadoop jar /opt/hadoop-3.2.1/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar \
    -files /tmp/t1_mapper.py,/tmp/t1_reducer.py \
    -input /data/task1/sales.txt \
    -output /output/task1 \
    -mapper "python3 t1_mapper.py" \
    -reducer "python3 t1_reducer.py"

  echo "OUTPUT"
  hdfs dfs -cat "/output/task1/part-*"
'
