#!/usr/bin/env bash
#
# Builds the cluster images (Hadoop + python3) and (re)starts all containers,
# then waits for the NameNode to leave safe mode and prints the python3 version
# in each container so you know it's ready for the MapReduce job.
#
set -e
cd "$(dirname "$0")"

docker compose down
docker compose build
docker compose up -d

echo "----- waiting for namenode to leave safe mode -----"
for i in $(seq 1 60); do
  if docker exec namenode hdfs dfsadmin -safemode get 2>/dev/null | grep -q "Safe mode is OFF"; then
    echo "NameNode ready."
    break
  fi
  sleep 5
done

echo "----- python3 in each container -----"
for c in namenode datanode resourcemanager; do
  printf "%s: " "$c"
  docker exec "$c" python3 --version
done
