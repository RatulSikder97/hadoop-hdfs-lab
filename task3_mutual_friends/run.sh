#!/bin/bash
# Run Task 3: Mutual Friend Recommendation on the Hadoop cluster.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

docker cp "$DIR/mapper.py"   namenode:/tmp/t3_mapper.py
docker cp "$DIR/reducer.py"  namenode:/tmp/t3_reducer.py
docker cp "$DIR/friends.txt" namenode:/tmp/friends.txt

docker exec namenode bash -c '
  hdfs dfs -mkdir -p /data/task3
  hdfs dfs -put -f /tmp/friends.txt /data/task3/friends.txt
  hdfs dfs -rm -r -f /output/task3 2>/dev/null || true

  hadoop jar /opt/hadoop-3.2.1/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar \
    -files /tmp/t3_mapper.py,/tmp/t3_reducer.py \
    -input /data/task3/friends.txt \
    -output /output/task3 \
    -mapper "python3 t3_mapper.py" \
    -reducer "python3 t3_reducer.py"

  echo "=========== TASK 3 OUTPUT ==========="
  hdfs dfs -cat "/output/task3/part-*"
'
