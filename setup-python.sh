#!/usr/bin/env bash
#
# Fallback: install python3 into already-running bde2020 containers.
# Those images run Debian Stretch (EOL), so apt is first repointed at
# archive.debian.org. Not needed when the cluster is built via start-cluster.sh,
# which bakes python3 into the image (see Dockerfile.python).
#
set -euo pipefail

install_python() {
  local container="$1"
  echo "==> [$container] repointing apt to archive.debian.org and installing python3"
  docker exec "$container" bash -c '
    set -e
    sed -i \
      -e "s|http://deb.debian.org/debian|http://archive.debian.org/debian|g" \
      -e "s|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g" \
      -e "/stretch-updates/d" \
      /etc/apt/sources.list
    apt-get -o Acquire::Check-Valid-Until=false update
    apt-get install -y python3
    python3 --version
  '
}

install_python namenode
install_python datanode
echo "==> Done"
