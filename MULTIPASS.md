# Multi‑PC Hadoop on ONE Mac — with Multipass

This runbook reproduces the **"Physical Multi‑PC Clustering, Distributed MapReduce &
Fault Recovery"** lab on a single Apple‑Silicon Mac, using **Multipass** Ubuntu VMs as
stand‑ins for the physical PCs.

| Lab role         | Real lab | Here (Multipass)                 |
|------------------|----------|----------------------------------|
| PC‑A (Master)    | a laptop | VM `master`  → `--profile master`|
| PC‑B (Worker)    | a laptop | VM `worker1` → `--profile worker`|
| PC‑C (Worker)    | a laptop | VM `worker2` → `--profile worker`|

Each VM gets its **own IP** on Multipass's bridge (`192.168.64.0/24` on macOS) and can
reach the others — exactly like 3 PCs on the same WiFi. We reuse this repo's
`docker-compose.yml` + `hadoop.env` **unchanged** by mounting the folder into every VM.

> **Why 3 VMs?** `hadoop.env` sets `dfs.replication=2`, so every block must live on **two**
> DataNodes. With two workers you can kill one and still read the file — the whole point of
> the fault‑recovery section.

> **Apple‑Silicon note:** the `bde2020/hadoop-*` images are **amd64‑only**. Your M4 Pro VMs
> are arm64, so each VM runs those containers under **QEMU emulation** (installed in Step 4).
> It works; MapReduce is just slower than native. That is fine for a learning lab.

---

## Step 0 — Install Multipass (one time)

```sh
brew install --cask multipass
multipass version
```

**How it works:** Multipass is a lightweight VM manager. On macOS it uses Apple's native
`vmnet` to give each VM a real IP and a shared L2 network, so VM‑to‑VM traffic (HDFS block
transfer, YARN registration) flows just like cross‑PC LAN traffic.

---

## Step 1 — Launch the three "PCs"

```sh
multipass launch --name master  --cpus 2 --memory 3G --disk 12G 24.04
multipass launch --name worker1 --cpus 2 --memory 3G --disk 12G 24.04
multipass launch --name worker2 --cpus 2 --memory 3G --disk 12G 24.04

multipass list
```

**How it works:** Three independent Ubuntu 24.04 guests boot up, each with its own kernel,
filesystem, and IP. From Hadoop's perspective these are three separate machines. ~9 GB RAM
total — comfortable inside your 24 GB.

---

## Step 2 — Capture each VM's IP into shell variables

```sh
MASTER_IP=$(multipass info master  | awk '/IPv4/{print $2}')
W1_IP=$(multipass info worker1 | awk '/IPv4/{print $2}')
W2_IP=$(multipass info worker2 | awk '/IPv4/{print $2}')
echo "master=$MASTER_IP  worker1=$W1_IP  worker2=$W2_IP"
```

**How it works:** These IPs are the lab's `MASTER_IP` / `WORKER_IP`. The NameNode advertises
itself at `MASTER_IP:9000`; each DataNode advertises its **own** VM IP so the NameNode hands
clients a reachable address instead of a useless internal Docker‑bridge IP.

---

## Step 3 — Mount this repo into every VM

```sh
REPO=/Users/ratulsikder/LAB/hadoop-hdfs-lab
multipass mount "$REPO" master:/lab
multipass mount "$REPO" worker1:/lab
multipass mount "$REPO" worker2:/lab
```

**How it works:** All three VMs now see the same `docker-compose.yml` + `hadoop.env` at
`/lab`. One unified Compose file, role chosen at runtime by `--profile` — no per‑machine
file editing, exactly as the lab intends.

---

## Step 4 — Install Docker + amd64 emulation in each VM

```sh
for vm in master worker1 worker2; do
  echo "=== provisioning $vm ==="
  multipass exec $vm -- bash -c 'curl -fsSL https://get.docker.com | sudo sh'
  multipass exec $vm -- sudo usermod -aG docker ubuntu
  # Register QEMU so arm64 VMs can run the amd64 Hadoop images:
  multipass exec $vm -- sudo docker run --privileged --rm tonistiigi/binfmt --install amd64
done
```

**How it works:** `get.docker.com` installs Docker Engine + the Compose plugin. The
`binfmt` step registers a QEMU translator in the kernel, so when Docker runs an amd64
Hadoop image the CPU instructions are emulated transparently. Without this, the containers
would refuse to start (`exec format error`).

---

## Step 5 — Point the cluster at the Master VM's IP

`hadoop.env` ships with a hard‑coded master IP (`10.100.201.155`). Rewrite it to your
**actual** master VM IP. Because `/lab` is a shared mount, you only do this once.

```sh
sed -i '' "s#hdfs://[0-9.]*:9000#hdfs://$MASTER_IP:9000#" "$REPO/hadoop.env"
sed -i '' "s#yarn_resourcemanager_hostname=[0-9.]*#yarn_resourcemanager_hostname=$MASTER_IP#" "$REPO/hadoop.env"
grep -E 'defaultFS|resourcemanager_hostname' "$REPO/hadoop.env"
```

**How it works:** `hadoop.env` is loaded as a Docker `env_file`, which does **not** expand
`${VAR}` — so the master IP must be a literal. `fs.defaultFS` tells every node where the
NameNode lives; `yarn.resourcemanager.hostname` tells every NodeManager where to register.
Both must equal the master VM's IP.

---

## Step 6 — Start the Master (NameNode + ResourceManager)

```sh
multipass exec master -- bash -c "cd /lab && MASTER_IP=$MASTER_IP docker compose --profile master up -d"
multipass exec master -- docker ps
```

**How it works:** The `master` profile starts two containers — the **NameNode** (HDFS
metadata + block map, UI on `9870`, RPC on `9000`) and the **ResourceManager** (YARN
scheduler, UI on `8088`, tracker on `8031`). Nothing stores data yet; the master only
coordinates. Give it ~30 s to finish booting.

---

## Step 7 — Start both Workers (DataNode + NodeManager)

```sh
multipass exec worker1 -- bash -c "cd /lab && MASTER_IP=$MASTER_IP WORKER_IP=$W1_IP docker compose --profile worker up -d"
multipass exec worker2 -- bash -c "cd /lab && MASTER_IP=$MASTER_IP WORKER_IP=$W2_IP docker compose --profile worker up -d"
```

**How it works:** Each `worker` profile starts a **DataNode** (stores HDFS blocks, registers
to `MASTER_IP:9000`) and a **NodeManager** (runs YARN containers, registers to
`MASTER_IP:8031`). The `WORKER_IP` env makes each DataNode advertise its own VM IP
(`dfs.datanode.hostname`) so cross‑VM block transfer actually connects. Within ~15 s both
workers appear in the master's live list.

---

## Step 8 — Verify the cluster is whole

```sh
# From the Mac browser — the master VM IP is reachable from the host:
open "http://$MASTER_IP:9870"   # HDFS UI  → 'Datanodes' tab shows worker1 + worker2 IPs
open "http://$MASTER_IP:8088"   # YARN UI  → 'Nodes' shows 2 active NodeManagers

# Or from the CLI:
multipass exec master -- docker exec namenode hdfs dfsadmin -report | grep -E 'Live datanodes|^Hostname|^Name'
```

**How it works:** Each DataNode sends a heartbeat + block report to the NameNode every few
seconds; the UI's *Datanodes* tab listing both worker IPs proves cross‑VM HDFS registration.
Likewise the YARN *Nodes* page proves both NodeManagers joined the scheduler. This is the
lab's "you should see your worker PCs connected via their physical IPs" checkpoint.

---

## Step 9 — Prove blocks are replicated across the VMs

```sh
multipass exec master -- docker exec namenode bash -c '
  echo "Hadoop across multiple PCs is awesome" > sample.txt
  hdfs dfs -mkdir -p /user/student
  hdfs dfs -D dfs.replication=2 -put -f sample.txt /user/student/
  hdfs fsck /user/student/sample.txt -files -blocks -locations
'
```

**How it works:** `fsck -locations` prints the IPs holding each block. With replication 2
you'll see **both** worker VM IPs for the single block — physical proof that HDFS pushed a
copy across the (virtual) LAN to a different machine. (The repo's `./check-cluster.sh`
automates Steps 8–9 if you'd rather run it inside the master VM.)

---

## Step 10 — Run a distributed MapReduce job (WordCount)

```sh
multipass exec master -- docker exec namenode bash -c '
  for i in $(seq 1 10000); do echo "docker hadoop mapreduce distributed cluster"; done > bigdata.txt
  hdfs dfs -put -f bigdata.txt /user/student/
  hadoop jar /opt/hadoop-3.2.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar \
    wordcount /user/student/bigdata.txt /user/student/output
  hdfs dfs -cat /user/student/output/part-r-00000
'
```

Watch it schedule across both workers at `http://$MASTER_IP:8088`.

**How it works:** The client asks the ResourceManager for containers; YARN places map/reduce
tasks on the NodeManagers running **inside the worker VMs**, so the job genuinely consumes
the CPU/RAM of separate machines. Each mapper reads the HDFS block local to its own VM
("data locality"), tallies words, and reducers merge the counts into `output/`.

---

## Step 11 — Fault recovery (the payoff)

**Scenario A — DataNode dies, data survives:**

```sh
multipass exec worker1 -- docker stop datanode               # crash PC‑B's storage
multipass exec master  -- docker exec namenode hdfs dfsadmin -report | grep -E 'Dead|Live datanodes'
multipass exec master  -- docker exec namenode hdfs dfs -cat /user/student/sample.txt
```

The file still prints instantly — the NameNode served the replica from `worker2`. After a
moment HDFS re‑replicates the now‑under‑replicated block to restore a count of 2.

**Scenario B — NodeManager dies mid‑job, job survives:**

```sh
# start a long job...
multipass exec master -- docker exec -d namenode \
  hadoop jar /opt/hadoop-3.2.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.2.1.jar pi 50 10000
# ...then kill a worker's compute while it runs:
multipass exec worker1 -- docker stop nodemanager
```

Watch `http://$MASTER_IP:8088`: YARN marks `worker1`'s NodeManager `LOST`, reassigns its
failed map attempts to `worker2`, and the job **still finishes**. That is HDFS replication +
YARN task re‑scheduling delivering end‑to‑end fault tolerance.

**Bring the killed services back:**

```sh
multipass exec worker1 -- bash -c "cd /lab && MASTER_IP=$MASTER_IP WORKER_IP=$W1_IP docker compose --profile worker up -d"
```

---

## Teardown

```sh
# Stop containers but keep the VMs:
for vm in master worker1 worker2; do multipass exec $vm -- bash -c 'cd /lab && docker compose --profile master --profile worker down'; done

# Or delete everything:
multipass delete master worker1 worker2 && multipass purge
```

---

## The whole system at a glance

```
            Mac host (browser: 9870 / 8088)
                       │  reachable over 192.168.64.0/24
   ┌───────────────────┼────────────────────────────┐
   │                   │                             │
┌──────────────┐  ┌──────────────────┐  ┌──────────────────┐
│ VM master    │  │ VM worker1       │  │ VM worker2       │
│ NameNode     │◀─┤ DataNode  ──────▶│  │ DataNode         │  HDFS: blocks
│ ResourceMgr  │◀─┤ NodeManager      │  │ NodeManager      │  YARN: compute
└──────────────┘  └──────────────────┘  └──────────────────┘
   metadata+         stores blocks +        replica of every
   scheduler         runs map/reduce         block (replication=2)
```

1. **VMs = PCs.** Multipass gives each role a real IP on a shared network, so HDFS/YARN
   cross‑host networking behaves exactly as on physical machines.
2. **Master coordinates, workers do the work.** NameNode holds the block map; DataNodes hold
   the bytes. ResourceManager schedules; NodeManagers execute.
3. **Replication = durability.** Every block sits on both workers, so losing one VM loses no
   data.
4. **YARN = resilience.** A dead NodeManager only costs a retry; surviving nodes finish the
   job.
5. **Profiles = one file, many roles.** The single `docker-compose.yml` is master or worker
   depending only on `--profile`, mirroring the "same file on every PC" design — just with
   VMs instead of laptops.
