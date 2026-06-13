#!/bin/bash
# HDFS Fault Tolerance & Data Recovery
#
# Demonstrates that HDFS survives a DataNode failure with zero data loss:
#   1. upload a file with replication factor 3
#   2. locate its blocks/replicas with fsck
#   3. simulate a node failure (stop a datanode)
#   4. self-healing — NameNode detects the dead node, file stays readable
#   5. restore the node — cluster returns to 3 live DataNodes
#
# Each step pauses so the output can be reviewed/captured.
# Requires the cluster up with 3 datanodes:
#   docker compose up -d --scale datanode=3
set -euo pipefail

DN_FAIL="hadoop_map_reduce-datanode-2"   # node we deliberately stop in step 3

pause() { echo; read -rp ">>> $1 — press ENTER to continue..."; echo; }

echo "############################################################"
echo "# HDFS FAULT TOLERANCE & DATA RECOVERY"
echo "############################################################"

# --- 1. Upload a file with replication factor 3 ------------------------------
echo; echo "===== 1. Upload testfile.txt with replication = 3 ====="
docker exec namenode bash -c '
  echo "Hello Hadoop Cluster" > /tmp/testfile.txt
  hdfs dfs -mkdir -p /data
  hdfs dfs -rm -f /data/testfile.txt 2>/dev/null || true
  hdfs dfs -D dfs.replication=3 -put /tmp/testfile.txt /data/
  echo "--- file listing (note the 3 in the replication column) ---"
  hdfs dfs -ls /data/testfile.txt
'
pause "STEP 1"

# --- 2. Locate the blocks (FSCK) ---------------------------------------------
echo "===== 2. Locate blocks & replicas with fsck ====="
docker exec namenode hdfs fsck /data/testfile.txt -files -blocks -locations
pause "STEP 2"

# --- 3. Simulate a node failure ----------------------------------------------
echo "===== 3. Simulate node failure: stop ${DN_FAIL} ====="
docker stop "${DN_FAIL}"
echo "--- DataNode containers still running ---"
docker ps --format '{{.Names}}\t{{.Status}}' | grep datanode || true
pause "STEP 3"

# --- 4. Self-healing ---------------------------------------------------------
echo "===== 4. NameNode detects the dead node ====="
echo "Note: it can take up to ~10 min for the NameNode to mark a node DEAD via"
echo "missed heartbeats. The block is still readable from a surviving replica."
docker exec namenode hdfs dfsadmin -report | grep -E "Live datanodes|Dead datanodes" || true
echo "--- the file is still readable (zero data loss) ---"
docker exec namenode hdfs dfs -cat /data/testfile.txt
echo "--- fsck still reports HEALTHY ---"
docker exec namenode hdfs fsck /data/testfile.txt | grep -E "Status|replicas|Under-replicated|HEALTHY" || true
pause "STEP 4"

# --- 5. Restore the node -----------------------------------------------------
echo "===== 5. Restore the failed node ====="
docker start "${DN_FAIL}"
echo "--- waiting for the node to re-register... ---"
for _ in $(seq 1 30); do
  live=$(docker exec namenode hdfs dfsadmin -report 2>/dev/null | grep -m1 "Live datanodes" || true)
  echo "  ${live}"
  case "${live}" in *"(3)"*) break;; esac
  sleep 5
done
docker exec namenode hdfs dfsadmin -report | grep -E "Live datanodes|Dead datanodes" || true
pause "STEP 5"

echo "############################################################"
echo "# COMPLETE — cluster survived a node failure with no data loss"
echo "############################################################"
