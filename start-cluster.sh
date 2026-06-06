#!/usr/bin/env bash
#
# Build the cluster images (Hadoop + python3) and (re)start all containers,
# then wait for the NameNode to leave safe mode and report the python3 version
# in each container.
#
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Rebuilding and starting the cluster"
docker compose down
docker compose build
docker compose up -d

echo "==> Waiting for the NameNode to leave safe mode"
for _ in $(seq 1 60); do
  if docker exec namenode hdfs dfsadmin -safemode get 2>/dev/null | grep -q "Safe mode is OFF"; then
    echo "    NameNode is ready."
    break
  fi
  sleep 5
done

echo "==> python3 version in each container"
for container in namenode datanode resourcemanager; do
  printf '    %-16s' "$container"
  docker exec "$container" python3 --version
done
