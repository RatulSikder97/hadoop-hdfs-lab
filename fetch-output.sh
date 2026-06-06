#!/usr/bin/env bash
# Pulls the Task 3 word-count result out of HDFS and saves it next to this script.
set -e
DIR="$(dirname "$0")"

# Copy the result from HDFS to the container's local /tmp
docker exec namenode hdfs dfs -get -f /user/student/output_python/part-00000 /tmp/wordcount.txt

# Copy it from the container onto the host, beside this script
docker cp namenode:/tmp/wordcount.txt "$DIR/wordcount.txt"

echo "Saved to: $DIR/wordcount.txt"
echo "----- first 20 lines -----"
head -n 20 "$DIR/wordcount.txt"
