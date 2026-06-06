#!/usr/bin/env bash
#
# Task 2 - HDFS block-splitting experiment.
# Generate a ~12 MB text file inside the namenode container, upload it to HDFS
# with a forced 1 MB block size, then run fsck to show the resulting blocks.
#
set -euo pipefail

HDFS_FILE="/user/student/hdfs_input/large_dataset.txt"

echo "==> Generating data and uploading to HDFS with a 1 MB block size"
docker exec namenode bash -c '
  set -e
  rm -f large_dataset.txt
  for i in {1..200000}; do
    echo "big data mapreduce hadoop distributed processing line $i" >> large_dataset.txt
  done
  hdfs dfs -mkdir -p /user/student/hdfs_input
  hdfs dfs -rm -f -skipTrash /user/student/hdfs_input/large_dataset.txt || true
  hdfs dfs -D dfs.blocksize=1048576 -put large_dataset.txt /user/student/hdfs_input/
'

echo "==> fsck block report"
docker exec namenode hdfs fsck "$HDFS_FILE" -files -blocks -locations
