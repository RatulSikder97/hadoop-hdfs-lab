#!/bin/bash

docker exec -it namenode bash -c "
hdfs dfs -mkdir -p /input
hdfs dfs -put -f /input/sample.txt /input/

hdfs dfs -rm -r /output

hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-*.jar \
-input /input \
-output /output \
-mapper 'python mapper.py' \
-reducer 'python reducer.py' \
-file /mapper.py \
-file /reducer.py
"
