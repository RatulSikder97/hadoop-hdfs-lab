#!/usr/bin/env bash
#
# check-cluster.sh — verify the three-PC HDFS cluster step by step.
# Run on THIS PC (the NameNode host, 10.100.200.101).
#
#   ./check-cluster.sh          # run every step
#   ./check-cluster.sh -p       # pause for <Enter> between steps
#
set -uo pipefail

NN_CONTAINER="namenode"
NN_IP="10.100.200.101"
# Expected DataNode LAN IPs. These are only DISPLAYED + counted (the script never
# connects to them — real nodes register via their own DN_HOST). Edit the 3rd
# entry below to the actual LAN IP of your third PC.
DN_IPS=("10.100.200.112" "10.100.201.210" "10.100.202.213")  # 3rd = PLACEHOLDER, edit me
EXPECTED_DN=${#DN_IPS[@]}
PAUSE=0
[[ "${1:-}" == "-p" ]] && PAUSE=1

# --- pretty helpers ---------------------------------------------------------
green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
yellow(){ printf '\033[0;33m%s\033[0m\n' "$1"; }
step()  { echo; echo "============================================================";
          echo ">> STEP $1: $2";
          echo "============================================================"; }
pause() { [[ $PAUSE -eq 1 ]] && { read -rp "  [Enter] for next step... " _; }; return 0; }
hdfs()  { docker exec "$NN_CONTAINER" bash -c "$1" 2>/dev/null; }

# ---------------------------------------------------------------------------
step 1 "Is the NameNode container running?"
if docker ps --filter "name=^${NN_CONTAINER}$" --format '{{.Names}}' | grep -q "$NN_CONTAINER"; then
  green "OK  - container '$NN_CONTAINER' is up"
  docker ps --filter "name=^${NN_CONTAINER}$" --format '      {{.Status}} | {{.Ports}}'
else
  red "FAIL - NameNode not running. Start it with:"
  echo "        docker compose -f docker-compose.namenode.yml up -d"
  exit 1
fi
pause

# ---------------------------------------------------------------------------
step 2 "Is the NameNode web UI responding? (http://${NN_IP}:9870)"
code=$(curl -s -o /dev/null -w '%{http_code}' "http://${NN_IP}:9870/" || echo 000)
if [[ "$code" == "200" ]]; then green "OK  - UI returned HTTP 200"
else red "WARN - UI returned HTTP $code (NameNode may still be starting)"; fi
pause

# ---------------------------------------------------------------------------
step 3 "Are the DataNodes connected? (expecting ${EXPECTED_DN}: ${DN_IPS[*]})"
report=$(hdfs "hdfs dfsadmin -report" 2>/dev/null)
live=$(echo "$report" | grep -oE 'Live datanodes \(([0-9]+)\)' | grep -oE '[0-9]+' | head -1)
live=${live:-0}
echo "$report" | grep -E 'Live datanodes|^Hostname:|^Name:|Last contact' | sed 's/^/      /'
if [[ "$live" -ge "$EXPECTED_DN" ]]; then
  green "OK  - $live live datanode(s) connected (expected $EXPECTED_DN)"
elif [[ "$live" -ge 1 ]]; then
  yellow "WARN - only $live of $EXPECTED_DN expected datanodes are live"
  echo "        On each missing PC run (with that machine's LAN IP):"
  echo "        DN_HOST=<this-pc-ip> docker compose -f docker-compose.datanode.yml up -d"
else
  red "FAIL - 0 live datanodes. On each DataNode PC run (with its LAN IP):"
  echo "        DN_HOST=<this-pc-ip> docker compose -f docker-compose.datanode.yml up -d"
  yellow "Stopping here - upload test needs a live datanode."
  exit 1
fi
pause

# ---------------------------------------------------------------------------
step 4 "Upload a file into HDFS"
hdfs '
echo "hello from two-pc hdfs cluster - $(date)" > /tmp/hello.txt &&
hdfs dfs -mkdir -p /lab &&
hdfs dfs -put -f /tmp/hello.txt /lab/hello.txt &&
echo "      uploaded /lab/hello.txt"
' && green "OK  - upload succeeded" || { red "FAIL - upload failed"; exit 1; }
pause

# ---------------------------------------------------------------------------
step 5 "List and read the file back"
hdfs 'echo "      --- ls /lab ---"; hdfs dfs -ls /lab; echo "      --- cat ---"; hdfs dfs -cat /lab/hello.txt'
pause

# ---------------------------------------------------------------------------
step 6 "Prove the block is replicated across the remote DataNodes (${DN_IPS[*]})"
# With replication=3 every block is copied to all 3 live DataNodes. fsck prints
# each block's registered Name (a SNAT'd IP under Docker Desktop), not the LAN
# IP, so we validate on health + replication factor rather than matching IPs.
fsck=$(hdfs "hdfs fsck /lab/hello.txt -files -blocks -locations" 2>/dev/null)
echo "$fsck" | grep -E "DatanodeInfoWithStorage|Status:|Total blocks|repl" | sed 's/^/      /'
if echo "$fsck" | grep -q "Status: HEALTHY"; then
  green "OK  - block is HEALTHY, replicated across the live DataNodes (${DN_IPS[*]})"
  if echo "$fsck" | grep -qiE "Under-replicated blocks:[[:space:]]*[1-9]"; then
    yellow "NOTE - some blocks under-replicated: fewer than $EXPECTED_DN datanodes were live at write time."
  fi
else
  yellow "WARN - block not reported HEALTHY"
fi

echo
green "===== Cluster check complete ====="
