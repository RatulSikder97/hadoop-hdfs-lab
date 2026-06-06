#!/usr/bin/env bash
set -e

docker exec namenode bash -c '
rm -f large_dataset.txt
for i in {1..200000}; do
  echo "big data mapreduce hadoop distributed processing line $i" >> large_dataset.txt
done
hdfs dfs -mkdir -p /user/student/hdfs_input
hdfs dfs -rm -f -skipTrash /user/student/hdfs_input/large_dataset.txt || true
hdfs dfs -D dfs.blocksize=1048576 -put large_dataset.txt /user/student/hdfs_input/
'

docker exec namenode hdfs fsck /user/student/hdfs_input/large_dataset.txt -files -blocks -locations
