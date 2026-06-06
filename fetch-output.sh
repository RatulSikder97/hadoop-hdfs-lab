#!/usr/bin/env bash
#
# Pull the Task 3 word-count result out of HDFS and save it next to this script
# as wordcount.txt, then print the first 20 lines.
#
set -euo pipefail
DIR="$(dirname "$0")"

OUTPUT="/user/student/output_python/part-00000"

echo "==> Copying the result out of HDFS to the host"
docker exec namenode hdfs dfs -get -f "$OUTPUT" /tmp/wordcount.txt
docker cp namenode:/tmp/wordcount.txt "$DIR/wordcount.txt"

echo "==> Saved to $DIR/wordcount.txt"
echo "==> First 20 lines"
head -n 20 "$DIR/wordcount.txt"
