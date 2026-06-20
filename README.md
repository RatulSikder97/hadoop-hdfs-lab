<div align="center">

# 🐘 Hadoop & HDFS Lab

### Hands-on distributed computing with Apache Hadoop, HDFS & MapReduce

![Hadoop](https://img.shields.io/badge/Apache_Hadoop-3.2.1-66CCFF?style=for-the-badge&logo=apachehadoop&logoColor=black)
![Docker](https://img.shields.io/badge/Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/Python_Streaming-3776AB?style=for-the-badge&logo=python&logoColor=white)
![HDFS](https://img.shields.io/badge/HDFS-Distributed_FS-FF6F00?style=for-the-badge)

*A collection of lab work building and operating multi-node Hadoop clusters on Docker —*
*from HDFS internals to fault tolerance, distributed MapReduce, and a real multi-machine cluster over a LAN.*

</div>

---

## 📚 Labs

Each lab lives on its own branch. Click through to explore the code and instructions.

<table>
<tr>
<td width="50%" valign="top">

### 🧱 [Lab 1 — HDFS Internals & Word Count](https://github.com/RatulSikder97/hadoop-hdfs-lab/tree/lab-1)

Build a Hadoop cluster on Docker and explore how HDFS works under the hood.

- ⚙️ Cluster setup (NameNode · DataNode · YARN)
- 🔪 **HDFS block splitting** — force a 1 MB block size and inspect with `fsck`
- 🔤 **Word Count** MapReduce via Hadoop Streaming (Python)
- 🐳 Bonus: alternative cluster on official `apache/hadoop` images

```bash
git checkout lab-1
```

</td>
<td width="50%" valign="top">

### 🛡️ [Lab 2 — Fault Tolerance & MapReduce](https://github.com/RatulSikder97/hadoop-hdfs-lab/tree/lab-2)

Scale the cluster and prove it survives node failure with zero data loss.

- 📈 Scale to a **3-DataNode** cluster
- 💥 **Fault tolerance** — kill a node, watch HDFS self-heal
- 🧮 Three MapReduce jobs:
  - Sales aggregation (revenue per product)
  - Feature statistics (COUNT/MIN/MAX/SUM/MEAN)
  - Mutual-friend recommendation (graph)

```bash
git checkout lab-2
```

</td>
</tr>
<tr>
<td colspan="2" valign="top">

### 🌐 [Lab 3 — Multi-PC HDFS Cluster over LAN](https://github.com/RatulSikder97/hadoop-hdfs-lab/tree/lab-3)

Take the cluster off a single machine — run the NameNode and three DataNodes on **four separate physical PCs** across a real LAN.

- 🖥️ NameNode + **3 DataNodes**, one per machine (not Docker replicas)
- 🌐 **Cross-host networking** — LAN-IP `fs.defaultFS`, bind-host vs. advertised host, hostname-based block transfer
- 📦 **replication = 3** — every block on all three nodes; survives two going offline
- 🔎 Guided `check-cluster.sh` — step-by-step health & verification
- 🧳 One portable `datanode-bundle.tgz` to drop on every DataNode PC

```bash
git checkout lab-3
```

</td>
</tr>
</table>

---

## 🚀 Quick Start

```bash
# clone the repo
git clone https://github.com/RatulSikder97/hadoop-hdfs-lab.git
cd hadoop-hdfs-lab

# switch to the lab you want
git checkout lab-1     # or: lab-2, lab-3

# follow that lab's README to bring up the cluster
docker compose up -d --build
```

> **Prerequisites:** Docker & Docker Compose. Each branch has its own detailed `README.md`.
> **Lab 3** spans multiple machines, so it uses its own per-role compose files
> (`docker-compose.namenode.yml` / `docker-compose.datanode.yml`) instead of the single command above.

---

## 🧰 Tech Stack

| Layer | Technology |
|-------|------------|
| Distributed FS | **HDFS** (replication, block management, fault tolerance) |
| Compute | **MapReduce** via Hadoop Streaming |
| Language | **Python 3** mappers & reducers |
| Orchestration | **Docker Compose** (multi-container cluster) |
| Resource Mgmt | **YARN** (ResourceManager) |

---

<div align="center">

🌿 **Branches:** [`main`](https://github.com/RatulSikder97/hadoop-hdfs-lab) · [`lab-1`](https://github.com/RatulSikder97/hadoop-hdfs-lab/tree/lab-1) · [`lab-2`](https://github.com/RatulSikder97/hadoop-hdfs-lab/tree/lab-2) · [`lab-3`](https://github.com/RatulSikder97/hadoop-hdfs-lab/tree/lab-3)

</div>
