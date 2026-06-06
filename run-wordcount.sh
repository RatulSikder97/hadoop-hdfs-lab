#!/usr/bin/env bash
set -e
DIR="$(dirname "$0")"

# Copy the Python scripts into the namenode container
docker cp "$DIR/mapper.py"  namenode:/tmp/mapper.py
docker cp "$DIR/reducer.py" namenode:/tmp/reducer.py

docker exec namenode bash -c '
# Run from a fresh, clean working dir owned by this process (avoids the
# sticky-bit permission clash that /tmp causes during job-jar unpacking)
rm -rf /tmp/wc_job
mkdir -p /tmp/wc_job
cp /tmp/mapper.py /tmp/reducer.py /tmp/wc_job/
cd /tmp/wc_job
chmod +x mapper.py reducer.py

# Hadoop refuses to write to an existing output dir, so clear it first
hdfs dfs -rm -r -f /user/student/output_python

# Submit the Python MapReduce job via Hadoop Streaming.
# -files ships the scripts to every task via the distributed cache.
hadoop jar /opt/hadoop-3.2.1/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar \
  -files mapper.py,reducer.py \
  -mapper "python3 mapper.py" \
  -reducer "python3 reducer.py" \
  -input /user/student/hdfs_input/large_dataset.txt \
  -output /user/student/output_python
'

# Read the result back from HDFS
docker exec namenode hdfs dfs -cat /user/student/output_python/part-00000 | head -n 10
