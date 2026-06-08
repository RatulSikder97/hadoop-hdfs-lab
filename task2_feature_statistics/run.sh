#!/bin/bash
# Run Task 2: Feature Statistics on the Hadoop cluster.
# Generates 1000 random integers 0..499, then computes COUNT/MIN/MAX/SUM/MEAN.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Ship mapper / reducer into the namenode container
docker cp "$DIR/mapper.py"  namenode:/tmp/t2_mapper.py
docker cp "$DIR/reducer.py" namenode:/tmp/t2_reducer.py

# 2. Generate the dataset inside the namenode and stage it on HDFS,
#    then launch the streaming job.
#    Matches the lab manual exactly: `for i in {1..1000}; do echo $((RANDOM % 500)) >> features.txt; done`
docker exec namenode bash -c '
  cd /tmp
  rm -f features.txt
  for i in {1..1000}; do echo $((RANDOM % 500)) >> features.txt; done
  hdfs dfs -mkdir -p /data/task2
  hdfs dfs -put -f /tmp/features.txt /data/task2/features.txt
  hdfs dfs -rm -r -f /output/task2 2>/dev/null || true

  hadoop jar /opt/hadoop-3.2.1/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar \
    -files /tmp/t2_mapper.py,/tmp/t2_reducer.py \
    -input /data/task2/features.txt \
    -output /output/task2 \
    -mapper "python3 t2_mapper.py" \
    -reducer "python3 t2_reducer.py"

  echo "=========== TASK 2 OUTPUT ==========="
  hdfs dfs -cat "/output/task2/part-*"
'
