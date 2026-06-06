#!/usr/bin/env bash
# Installs python3 into the Hadoop containers.
# These images run Debian Stretch (EOL), so apt is repointed at archive.debian.org.
set -e

fix_and_install() {
  local c="$1"
  echo "=== [$c] repointing apt to archive.debian.org and installing python3 ==="
  docker exec "$c" bash -c '
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

fix_and_install namenode
fix_and_install datanode
echo "=== done ==="
