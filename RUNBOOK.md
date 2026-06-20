# Multi-PC Hadoop Cluster — Runbook

NameNode/Master: `10.100.201.155` · Workers: `10.100.202.31`, `10.100.202.49`

Put `docker-compose.yml`, `docker-compose.worker.yml`, and `hadoop.env` in the same folder on every PC.

## Master PC (10.100.201.155)

```bash
cd ~/Documents/hadoop-hdfs-lab
MASTER_IP=10.100.201.155 docker compose --profile master up -d
```

UIs: NameNode http://10.100.201.155:9870 · YARN http://10.100.201.155:8088

## Worker PC 1 (10.100.202.31)

```bash
cd ~/Documents/hadoop-hdfs-lab
sudo ufw allow 9864,9866,9867,8042/tcp
WORKER_IP=10.100.202.31 docker compose -f docker-compose.worker.yml up -d --force-recreate
```

## Worker PC 2 (10.100.202.49)

```bash
cd ~/Documents/hadoop-hdfs-lab
sudo ufw allow 9864,9866,9867,8042/tcp
WORKER_IP=10.100.202.49 docker compose -f docker-compose.worker.yml up -d --force-recreate
```

## Verify (Master PC)

```bash
docker exec namenode hdfs dfsadmin -report | grep -E "Live datanodes|^Name:|^Hostname:"
docker exec resourcemanager yarn node -list
docker exec namenode bash -c 'echo "hadoop across multiple PCs" > /tmp/s.txt && hdfs dfs -mkdir -p /user/student && hdfs dfs -put -f /tmp/s.txt /user/student/sample.txt && hdfs dfs -cat /user/student/sample.txt'
docker exec namenode hdfs fsck /user/student/sample.txt -files -blocks -locations
```

## Stop

```bash
# Master
docker compose --profile master down
# Each worker
docker compose -f docker-compose.worker.yml down
```
