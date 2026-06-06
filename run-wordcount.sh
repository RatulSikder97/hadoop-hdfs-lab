#!/usr/bin/env bash
#
# Task 3 - Python MapReduce word count via Hadoop Streaming.
# Ship mapper.py/reducer.py to the namenode container, submit the streaming job
# over the HDFS input file, and print the first 10 lines of the result.
#
set -euo pipefail
DIR="$(dirname "$0")"

STREAMING_JAR="/opt/hadoop-3.2.1/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar"
INPUT="/user/student/hdfs_input/large_dataset.txt"
OUTPUT="/user/student/output_python"

echo "==> Copying mapper.py and reducer.py into the namenode container"
docker cp "$DIR/mapper.py"  namenode:/tmp/mapper.py
docker cp "$DIR/reducer.py" namenode:/tmp/reducer.py

echo "==> Submitting the Hadoop Streaming job"
docker exec namenode bash -c '
  set -e

  # Run from a fresh, clean working dir owned by this process to avoid the
  # sticky-bit permission clash that /tmp causes during job-jar unpacking.
  rm -rf /tmp/wc_job
  mkdir -p /tmp/wc_job
  cp /tmp/mapper.py /tmp/reducer.py /tmp/wc_job/
  cd /tmp/wc_job
  chmod +x mapper.py reducer.py

  # Hadoop refuses to write to an existing output dir, so clear it first.
  hdfs dfs -rm -r -f '"$OUTPUT"'

  # -files ships the scripts to every task via the distributed cache.
  hadoop jar '"$STREAMING_JAR"' \
    -files mapper.py,reducer.py \
    -mapper "python3 mapper.py" \
    -reducer "python3 reducer.py" \
    -input '"$INPUT"' \
    -output '"$OUTPUT"'
'

echo "==> First 10 lines of the result"
docker exec namenode hdfs dfs -cat "$OUTPUT/part-00000" | head -n 10
