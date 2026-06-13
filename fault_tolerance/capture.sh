#!/bin/bash
# Capture the terminal output of each fault-tolerance step into screenshots/.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
SS="$DIR/screenshots"
mkdir -p "$SS"
DN="hadoop_map_reduce-datanode-2"

ne() { docker exec namenode bash -c "$1" 2>/dev/null; }   # run inside namenode

# ---------- Fig 4: upload with replication 3 ----------
{
  echo '# echo "Hello Hadoop Cluster" > testfile.txt'
  echo '# hdfs dfs -mkdir -p /data'
  echo '# hdfs dfs -D dfs.replication=3 -put testfile.txt /data/'
  echo '# hdfs dfs -ls /data/testfile.txt'
  ne 'echo "Hello Hadoop Cluster" > /tmp/testfile.txt;
      hdfs dfs -mkdir -p /data;
      hdfs dfs -rm -f /data/testfile.txt 2>/dev/null;
      hdfs dfs -D dfs.replication=3 -put /tmp/testfile.txt /data/;
      hdfs dfs -ls /data/testfile.txt'
} | tee "$SS/fig4_upload.txt"

# ---------- Fig 5: fsck block locations ----------
{
  echo '# hdfs fsck /data/testfile.txt -files -blocks -locations'
  ne 'hdfs fsck /data/testfile.txt -files -blocks -locations'
} | tee "$SS/fig5_fsck.txt"

# ---------- Fig 6: simulate node failure ----------
{
  echo '$ docker stop '"$DN"
  docker stop "$DN"
  echo
  echo '$ docker ps --format "{{.Names}}\t{{.Status}}" | grep datanode'
  docker ps --format '{{.Names}}\t{{.Status}}' | grep datanode
} | tee "$SS/fig6_stop.txt"

# wait for the NameNode to mark the node dead (recheck-interval lowered to 15s)
echo ">>> waiting for dead-node detection..."
for i in $(seq 1 12); do
  sleep 10
  d=$(ne 'hdfs dfsadmin -report' | grep -m1 "Dead datanodes" || true)
  echo "   ~$((i*10))s: $d"
  case "$d" in *"(1)"*) break;; esac
done

# ---------- Fig 7: self-healing ----------
{
  echo '# hdfs dfsadmin -report'
  ne 'hdfs dfsadmin -report' | grep -E "Live datanodes|Dead datanodes|^Name:|Decommission Status|Last contact"
  echo
  echo '# hdfs dfs -cat /data/testfile.txt   (file still readable - zero data loss)'
  ne 'hdfs dfs -cat /data/testfile.txt'
  echo
  echo '# hdfs fsck /data/testfile.txt'
  ne 'hdfs fsck /data/testfile.txt' | grep -E "Status|Under-replicated|Average block replication|HEALTHY"
} | tee "$SS/fig7_selfheal.txt"

# ---------- Fig 8: restore the node ----------
{
  echo '$ docker start '"$DN"
  docker start "$DN"
  echo
  echo '# hdfs dfsadmin -report   (cluster back to 3 live)'
  for i in $(seq 1 20); do
    n=$(ne 'hdfs dfsadmin -report' | grep -m1 "Live datanodes" || true)
    case "$n" in *"(3)"*) break;; esac
    sleep 5
  done
  ne 'hdfs dfsadmin -report' | grep -E "Live datanodes|Dead datanodes"
} | tee "$SS/fig8_restore.txt"

echo
echo "=========================================================="
echo "DONE. Figures saved to: $SS"
ls -1 "$SS"
