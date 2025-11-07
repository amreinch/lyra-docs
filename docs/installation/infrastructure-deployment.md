# Deploy Lyra Infrastructure

This guide walks you through deploying the required infrastructure components for Lyra Platform on your Kubernetes cluster.

## Overview

After setting up your Kubernetes cluster, you need to deploy the infrastructure components that Lyra depends on:

1. **Ceph/Rook Storage** - Persistent storage backend
2. **PostgreSQL Database** - Primary database for Lyra
3. **Redis Cache** - Caching and session management
4. **CSI Drivers** - External storage integration (SMB, NFS, S3)
5. **MetalLB Load Balancer** - External service access

**Prerequisites:**
- ✅ Kubernetes cluster created and configured ([see Kubernetes Setup](kubernetes-setup.md))
- ✅ Rancher UI access configured
- ✅ Harbor registry with Lyra charts available
- ✅ `kubectl` access to your cluster

**Estimated Time:** 45-60 minutes

---

## Deployment Method

All infrastructure components are deployed using Helm charts via Rancher UI following a consistent pattern:

1. Navigate to **Apps & Marketplace → Charts** in Rancher
2. Search for the chart name (e.g., `rook-ceph-lyra-operator`)
3. Click **Install**
4. Configure:
   - **Namespace:** As specified in each step
   - **Name:** As specified in each step (fixed release names)
   - Review configuration values
5. Click **Install**
6. Monitor deployment and verify pods are running

**Harbor Registry Integration:** All charts are pre-configured to use Harbor registry (`registry.lyra.ovh`) and require the `harbor-registry-secret` to be available in the deployment namespace.

---

## Step 1: Install Ceph/Rook Storage

Lyra requires persistent storage provided by Ceph/Rook.

### Prerequisites: Verify Storage Disks

Before proceeding, verify that worker nodes have the required storage disks for Ceph/Rook.

**Check Disks on Worker Nodes:**

SSH to each worker node and verify disk configuration:

```bash
# Check available disks
lsblk
```

**Expected output:**
```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0   100G  0 disk           # OS disk
└─sda1   8:1    0   100G  0 part /
sdb      8:16   0   500G  0 disk           # Storage disk (unformatted)
sdc      8:32   0   500G  0 disk           # Storage disk (optional)
```

**Verify:**
- ✅ `/dev/sda` is the OS disk with mountpoint `/`
- ✅ `/dev/sdb` (and optionally `/dev/sdc`, `/dev/sdd`) are unformatted
- ✅ Storage disks show no `MOUNTPOINT` (must be raw/unformatted)

**If storage disks are missing:**
1. Provision additional disks on your VMs/servers
2. Ensure disks are attached but NOT formatted or partitioned
3. Restart the verification process

### Install Rook Operator via Rancher

Install the **rook-ceph-lyra-operator** chart following the deployment method described above.

**Chart:** `rook-ceph-lyra-operator`

**Chart Configuration:**
- **Name:** `rook-ceph-operator`
- **Namespace:** `rook-ceph`
- **Chart Version:** Latest stable version
- **Project:** Lyra Platform

**Verify Rook Operator is running:**
   ```bash
   kubectl get pods -n rook-ceph
   ```

   **Expected output:**
   ```
   NAME                                  READY   STATUS    RESTARTS   AGE
   rook-ceph-operator-xxxxx              1/1     Running   0          2m
   rook-discover-xxxxx                   1/1     Running   0          2m
   rook-discover-yyyyy                   1/1     Running   0          2m
   rook-discover-zzzzz                   1/1     Running   0          2m
   ```

   **Important:**
   - There will be one `rook-discover` pod for each node with the Worker role
   - Wait until all pods show `Running` status and `1/1` READY before proceeding
   - The discovery pods detect available storage devices on each node

### Deploy Ceph Cluster

Now that the Rook operator is running, deploy the Ceph cluster using the **rook-ceph-lyra-cluster** Helm chart.

**Purpose of rook-ceph-lyra-cluster:**
- Automatically creates and configures the Ceph storage cluster
- Deploys Ceph Monitor (MON) pods for cluster coordination
- Creates Ceph OSD (Object Storage Daemon) pods on each worker node's storage disks
- Deploys Ceph Manager (MGR) pods for cluster management
- Automatically creates and configures storage classes (RBD block storage and CephFS)
- Sets up the default storage class for Kubernetes persistent volumes

Install the **rook-ceph-lyra-cluster** chart following the deployment method above.

**Chart:** `rook-ceph-lyra-cluster`

**Chart Configuration:**
- **Name:** `rook-ceph-cluster`
- **Namespace:** `rook-ceph`
- **Chart Version:** Latest stable version
- **Project:** Lyra Platform

**Monitor Ceph cluster creation** (takes 5-10 minutes):
```bash
kubectl get pods -n rook-ceph -w
```

**Verify all pods are running after deployment completes:**
```bash
kubectl get pods -n rook-ceph
```

**Expected pods after full deployment (example with 6 worker nodes):**
```
NAME                                                         READY   STATUS      RESTARTS   AGE
csi-cephfsplugin-xxxxx                                       3/3     Running     0          7m
csi-cephfsplugin-yyyyy                                       3/3     Running     0          7m
csi-cephfsplugin-zzzzz                                       3/3     Running     0          7m
csi-cephfsplugin-aaaaa                                       3/3     Running     0          7m
csi-cephfsplugin-bbbbb                                       3/3     Running     0          7m
csi-cephfsplugin-provisioner-xxxxxxxxxx-xxxxx                6/6     Running     0          7m
csi-cephfsplugin-provisioner-xxxxxxxxxx-yyyyy                6/6     Running     0          7m
csi-cephfsplugin-ccccc                                       3/3     Running     0          7m
csi-rbdplugin-xxxxx                                          3/3     Running     0          7m
csi-rbdplugin-yyyyy                                          3/3     Running     0          7m
csi-rbdplugin-zzzzz                                          3/3     Running     0          7m
csi-rbdplugin-provisioner-xxxxxxxxxx-xxxxx                   6/6     Running     0          7m
csi-rbdplugin-provisioner-xxxxxxxxxx-yyyyy                   6/6     Running     0          7m
csi-rbdplugin-aaaaa                                          3/3     Running     0          7m
csi-rbdplugin-bbbbb                                          3/3     Running     0          7m
csi-rbdplugin-ccccc                                          3/3     Running     0          7m
rook-ceph-crashcollector-nodename1-xxxxxxxxxx-xxxxx          1/1     Running     0          5m
rook-ceph-crashcollector-nodename2-xxxxxxxxxx-xxxxx          1/1     Running     0          5m
rook-ceph-crashcollector-nodename3-xxxxxxxxxx-xxxxx          1/1     Running     0          5m
rook-ceph-crashcollector-nodename4-xxxxxxxxxx-xxxxx          1/1     Running     0          5m
rook-ceph-crashcollector-nodename5-xxxxxxxxxx-xxxxx          1/1     Running     0          5m
rook-ceph-crashcollector-nodename6-xxxxxxxxxx-xxxxx          1/1     Running     0          5m
rook-ceph-exporter-nodename1-xxxxxxxxxx-xxxxx                1/1     Running     0          5m
rook-ceph-exporter-nodename2-xxxxxxxxxx-xxxxx                1/1     Running     0          5m
rook-ceph-exporter-nodename3-xxxxxxxxxx-xxxxx                1/1     Running     0          5m
rook-ceph-exporter-nodename4-xxxxxxxxxx-xxxxx                1/1     Running     0          5m
rook-ceph-exporter-nodename5-xxxxxxxxxx-xxxxx                1/1     Running     0          5m
rook-ceph-exporter-nodename6-xxxxxxxxxx-xxxxx                1/1     Running     0          5m
rook-ceph-mds-ceph-filesystem-a-xxxxxxxxxx-xxxxx             2/2     Running     0          5m
rook-ceph-mds-ceph-filesystem-b-xxxxxxxxxx-xxxxx             2/2     Running     0          5m
rook-ceph-mgr-a-xxxxxxxxxx-xxxxx                             3/3     Running     0          6m
rook-ceph-mgr-b-xxxxxxxxxx-xxxxx                             3/3     Running     0          5m
rook-ceph-mon-a-xxxxxxxxxx-xxxxx                             2/2     Running     0          7m
rook-ceph-mon-b-xxxxxxxxxx-xxxxx                             2/2     Running     0          7m
rook-ceph-mon-c-xxxxxxxxxx-xxxxx                             2/2     Running     0          6m
rook-ceph-operator-xxxxxxxxxx-xxxxx                          1/1     Running     0          10m
rook-ceph-osd-0-xxxxxxxxxx-xxxxx                             2/2     Running     0          5m
rook-ceph-osd-1-xxxxxxxxxx-xxxxx                             2/2     Running     0          5m
rook-ceph-osd-2-xxxxxxxxxx-xxxxx                             2/2     Running     0          5m
rook-ceph-osd-3-xxxxxxxxxx-xxxxx                             2/2     Running     0          5m
rook-ceph-osd-4-xxxxxxxxxx-xxxxx                             2/2     Running     0          5m
rook-ceph-osd-5-xxxxxxxxxx-xxxxx                             2/2     Running     0          5m
rook-ceph-osd-prepare-nodename1-xxxxx                        0/1     Completed   0          6m
rook-ceph-osd-prepare-nodename2-xxxxx                        0/1     Completed   0          6m
rook-ceph-osd-prepare-nodename3-xxxxx                        0/1     Completed   0          6m
rook-ceph-osd-prepare-nodename4-xxxxx                        0/1     Completed   0          6m
rook-ceph-osd-prepare-nodename5-xxxxx                        0/1     Completed   0          6m
rook-ceph-osd-prepare-nodename6-xxxxx                        0/1     Completed   0          6m
rook-ceph-rgw-ceph-objectstore-a-xxxxxxxxxx-xxxxx            2/2     Running     0          4m
rook-ceph-tools-xxxxxxxxxx-xxxxx                             1/1     Running     0          9m
rook-discover-xxxxx                                          1/1     Running     0          9m
rook-discover-yyyyy                                          1/1     Running     0          9m
rook-discover-zzzzz                                          1/1     Running     0          9m
rook-discover-aaaaa                                          1/1     Running     0          9m
rook-discover-bbbbb                                          1/1     Running     0          9m
rook-discover-ccccc                                          1/1     Running     0          9m
```

**Pod Components Explained:**

**CSI Drivers (Storage Interface):**
- `csi-cephfsplugin-*` - CephFS driver pods (one per worker node, 3/3 containers)
- `csi-cephfsplugin-provisioner-*` - CephFS provisioner (2 replicas for HA, 6/6 containers)
- `csi-rbdplugin-*` - RBD block storage driver pods (one per worker node, 3/3 containers)
- `csi-rbdplugin-provisioner-*` - RBD provisioner (2 replicas for HA, 6/6 containers)

**Ceph Core Components:**
- `rook-ceph-mon-*` - Monitor pods for cluster coordination (3 replicas, 2/2 containers)
- `rook-ceph-mgr-*` - Manager pods for cluster management (2 replicas, 3/3 containers)
- `rook-ceph-osd-*` - Object Storage Daemon pods (one per storage disk, 2/2 containers)
- `rook-ceph-mds-ceph-filesystem-*` - Metadata server for CephFS (2 replicas, 2/2 containers)
- `rook-ceph-rgw-ceph-objectstore-*` - RADOS Gateway for object storage (1+ replicas, 2/2 containers)

**Support Components:**
- `rook-ceph-operator-*` - Rook operator managing the cluster (1/1 container)
- `rook-discover-*` - Storage device discovery (one per worker node, 1/1 container)
- `rook-ceph-crashcollector-*` - Crash reporting (one per worker node, 1/1 container)
- `rook-ceph-exporter-*` - Metrics exporters (one per worker node, 1/1 container)
- `rook-ceph-osd-prepare-*` - OSD preparation jobs (Completed status, one per node)
- `rook-ceph-tools-*` - Ceph CLI tools pod (1/1 container)

**Important:**
- **Wait until all pods show `Running` or `Completed` status** before proceeding
- Number of pods will vary based on your cluster configuration:
  - **Per worker node**: 1 csi-cephfsplugin, 1 csi-rbdplugin, 1 rook-discover, 1 crashcollector, 1 exporter, 1 osd-prepare (Completed)
  - **Per storage disk**: 1 rook-ceph-osd pod
  - **Fixed replicas**: 3 MON, 2 MGR, 2 MDS, 2 CSI provisioners (each type)
- The cluster is ready when all pods are running/completed and healthy

**Verify storage class:**
```bash
kubectl get storageclass
```

**Expected output:**
```
NAME                        PROVISIONER                     AGE
rook-ceph-block (default)   rook-ceph.rbd.csi.ceph.com      1m
```

---

## Step 2: Deploy PostgreSQL Database

Lyra Platform requires PostgreSQL as its primary database. The deployment follows the operator pattern with two separate Helm charts.

### Database Deployment Architecture

**Operator Pattern**: PostgreSQL deployment uses two charts:
1. **postgres-operator**: Manages PostgreSQL clusters (installed once)
2. **postgres-cluster**: Actual PostgreSQL database instances (one per cluster needed)

**Namespace**: All database components are deployed in the `databases` namespace.

### Install PostgreSQL Operator

The PostgreSQL operator manages the lifecycle of PostgreSQL clusters within Kubernetes.

**Purpose of postgres-operator:**
- Manages PostgreSQL cluster creation and lifecycle
- Handles high availability and failover
- Automates backups and recovery
- Monitors database health and performance

Install the **postgres-operator** chart following the deployment method described above.

**Chart:** `postgres-operator`

**Chart Configuration:**
- **Name:** `postgres-operator`
- **Namespace:** `databases`
- **Chart Version:** Latest stable version
- **Project:** `Lyra Platform`

**Verify PostgreSQL Operator is running:**
```bash
kubectl get pods -n databases
```

**Expected output:**
```
NAME                                 READY   STATUS    RESTARTS   AGE
postgres-operator-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
```

**Important:**
- Wait until the operator pod shows `Running` status and `1/1` READY before proceeding
- The operator must be running before deploying any PostgreSQL clusters

### Deploy PostgreSQL Cluster

Now that the PostgreSQL operator is running, deploy the actual PostgreSQL database cluster.

**Purpose of postgres-cluster:**
- Creates a highly available PostgreSQL database cluster
- Configures persistent storage using Ceph/Rook
- Provides automatic backups and point-in-time recovery
- Creates database users and credentials
- Manages automatic failover and replication

Install the **postgres-cluster** chart following the deployment method described above.

**Chart:** `postgres-cluster`

**Chart Configuration:**
- **Name:** `postgres-cluster` (or your preferred cluster name)
- **Namespace:** `databases`
- **Chart Version:** Latest stable version
- **Project:** `Lyra Platform`

**Important Configuration Values:**
- **Cluster Name**: Name of your PostgreSQL cluster (e.g., `lyra-postgres`)
- **Number of Instances**: Replica count (default: 3 for HA, minimum: 1 for development)
- **Storage Size**: Persistent volume size (default: `10Gi` for development, `100Gi+` for production)
- **Storage Class**: `rook-ceph-block` (uses Ceph storage from Step 1)
- **Database Name**: Initial database to create (e.g., `lyra_db`)
- **Database User**: Application database user (e.g., `lyra_user`)

**Monitor PostgreSQL cluster creation** (takes 2-5 minutes):
```bash
kubectl get pods -n databases -w
```

**Verify all PostgreSQL pods are running:**
```bash
kubectl get pods -n databases
```

**Expected output (for 3-replica cluster):**
```
NAME                                 READY   STATUS    RESTARTS   AGE
postgres-operator-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
lyra-postgres-1                      1/1     Running   0          3m
lyra-postgres-2                      1/1     Running   0          2m
lyra-postgres-3                      1/1     Running   0          2m
```

**Pod Components:**
- `postgres-operator-*` - PostgreSQL operator managing clusters
- `lyra-postgres-1`, `lyra-postgres-2`, `lyra-postgres-3` - PostgreSQL database instances (replicas)

**Verify PostgreSQL cluster status:**
```bash
kubectl get cluster -n databases
```

**Expected output:**
```
NAME            AGE   INSTANCES   READY   STATUS                     PRIMARY
lyra-postgres   3m    3           3       Cluster in healthy state   lyra-postgres-1
```

**Verify PostgreSQL services:**
```bash
kubectl get svc -n databases
```

**Expected output:**
```
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
lyra-postgres-r     ClusterIP   10.43.xxx.xxx   <none>        5432/TCP   3m
lyra-postgres-ro    ClusterIP   10.43.xxx.xxx   <none>        5432/TCP   3m
lyra-postgres-rw    ClusterIP   10.43.xxx.xxx   <none>        5432/TCP   3m
```

**Service Endpoints:**
- `lyra-postgres-rw` - Read-Write endpoint (primary) - Use this for application connections
- `lyra-postgres-ro` - Read-Only endpoint (replicas) - Use for read-only queries
- `lyra-postgres-r` - Read endpoint (any instance) - Load-balanced across all instances

**Retrieve Database Credentials:**

CloudNativePG automatically creates a Kubernetes secret with the application database credentials:

```bash
# List secrets in databases namespace
kubectl get secrets -n databases

# View the application database credentials secret
kubectl get secret lyra-postgres-app -n databases -o yaml
```

**Retrieve specific credentials:**
```bash
# Get database username
kubectl get secret lyra-postgres-app -n databases -o jsonpath='{.data.username}' | base64 -d

# Get database password
kubectl get secret lyra-postgres-app -n databases -o jsonpath='{.data.password}' | base64 -d

# Get full connection URI
kubectl get secret lyra-postgres-app -n databases -o jsonpath='{.data.uri}' | base64 -d
```

**Important:**
- Save database credentials securely - they will be needed for Lyra application configuration
- The connection string format: `postgresql://<username>:<password>@lyra-postgres-rw.databases.svc.cluster.local:5432/<database>`
- Always use the `-rw` (read-write) endpoint for application connections that need write access
- Use the `-ro` (read-only) endpoint for read-only queries to distribute load across replicas

---

## Step 3: Deploy Redis Cache

Lyra Platform requires Redis for caching and session management. The deployment consists of two Redis instances with different purposes.

### Redis Deployment Architecture

**Dual Redis Pattern**: Lyra uses two separate Redis deployments:
1. **redis (HA)**: Persistent Redis with Sentinel for critical data (token blacklist, important caches)
2. **redis-ephemeral**: Non-persistent Redis with LRU eviction for temporary sessions

**Namespace**: Both Redis instances are deployed in the `databases` namespace.

### Deploy Redis HA (Persistent)

The persistent Redis deployment provides high availability with Redis Sentinel for automatic failover.

**Purpose of redis (HA):**
- Stores critical data that must persist across restarts
- Token blacklist for authentication security
- Important application caches
- High availability with Redis Sentinel
- Automatic failover and replication
- Persistent storage using Ceph/Rook

Install the **redis** chart following the deployment method described above.

**Chart:** `redis`

**Chart Configuration:**
- **Name:** `redis` (fixed release name for consistent service naming)
- **Namespace:** `databases`
- **Chart Version:** Latest stable version
- **Project:** `Lyra Platform`

**Important Configuration Values:**
- **Replicas**: 3 instances (1 master + 2 replicas) for high availability
- **Storage Size**: 5Gi persistent volume per instance
- **Storage Class**: `rook-ceph-block` (uses Ceph storage from Step 1)
- **Max Memory**: 512MB per instance
- **Eviction Policy**: `noeviction` (critical data must not be evicted)
- **Persistence**: RDB snapshots + AOF (append-only file)
- **Sentinel Quorum**: 2 (minimum sentinels for failover decision)

**Monitor Redis HA deployment** (takes 2-3 minutes):
```bash
kubectl get pods -n databases -w
```

**Verify all Redis HA pods are running:**
```bash
kubectl get pods -n databases -l app=redis-ha
```

**Expected output:**
```
NAME                       READY   STATUS    RESTARTS   AGE
redis-redis-ha-server-0    3/3     Running   0          2m
redis-redis-ha-server-1    3/3     Running   0          2m
redis-redis-ha-server-2    3/3     Running   0          2m
```

**Pod Components:**
- Each pod runs 3 containers: Redis server + Sentinel + Metrics exporter
- 3 replicas provide high availability with automatic failover
- Sentinel monitors Redis instances and manages failover
- Metrics exporter provides Prometheus metrics for monitoring

**Verify Redis HA services:**
```bash
kubectl get svc -n databases -l app=redis-ha
```

**Expected output:**
```
NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
redis-redis-ha               ClusterIP   None            <none>        6379/TCP,26379/TCP   2m
redis-redis-ha-announce-0    ClusterIP   10.43.xxx.xxx   <none>        6379/TCP,26379/TCP   2m
redis-redis-ha-announce-1    ClusterIP   10.43.xxx.xxx   <none>        6379/TCP,26379/TCP   2m
redis-redis-ha-announce-2    ClusterIP   10.43.xxx.xxx   <none>        6379/TCP,26379/TCP   2m
```

**Service Endpoints:**
- `redis-redis-ha` - Headless service for discovery
- `redis-redis-ha-announce-*` - Individual pod services
- Port 6379: Redis data port
- Port 26379: Sentinel port

### Deploy Redis Ephemeral (Sessions)

The ephemeral Redis deployment provides fast, memory-only storage for temporary data like user sessions.

**Purpose of redis-ephemeral:**
- Temporary session storage
- Short-lived caches
- LRU (Least Recently Used) eviction when memory is full
- No persistence - data is lost on restart (by design)
- Single instance (HA not required for ephemeral data)
- Lower resource usage

Install the **redis-ephemeral** chart following the deployment method described above.

**Chart:** `redis-ephemeral`

**Chart Configuration:**
- **Name:** `redis-ephemeral`
- **Namespace:** `databases`
- **Chart Version:** Latest stable version
- **Project:** `Lyra Platform`

**Important Configuration Values:**
- **Replicas**: 1 instance (HA not needed for ephemeral data)
- **Storage**: None (memory-only, no persistence)
- **Max Memory**: 256MB
- **Eviction Policy**: `allkeys-lru` (evict least recently used keys when full)
- **Persistence**: Disabled (no RDB snapshots, no AOF)

**Verify Redis Ephemeral is running:**
```bash
kubectl get pods -n databases -l app=redis-ephemeral
```

**Expected output:**
```
NAME                               READY   STATUS    RESTARTS   AGE
redis-ephemeral-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
```

**Verify Redis Ephemeral service:**
```bash
kubectl get svc -n databases redis-ephemeral
```

**Expected output:**
```
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
redis-ephemeral   ClusterIP   10.43.xxx.xxx   <none>        6379/TCP   1m
```

**Service Endpoint:**
- `redis-ephemeral` - ClusterIP service for ephemeral Redis access
- Port 6379: Redis data port

### Verify Complete Redis Deployment

**Check all Redis pods:**
```bash
kubectl get pods -n databases -l 'app in (redis-ha,redis-ephemeral)'
```

**Expected output:**
```
NAME                                READY   STATUS    RESTARTS   AGE
redis-redis-ha-server-0             2/2     Running   0          3m
redis-redis-ha-server-1             2/2     Running   0          3m
redis-redis-ha-server-2             2/2     Running   0          3m
redis-ephemeral-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
```

### Redis Connection Information

**For Lyra Application Configuration:**

**Redis HA (Persistent):**
- **Connection**: Sentinel-aware connection required
- **Sentinel Service**: `redis-redis-ha.databases.svc.cluster.local:26379`
- **Master Name**: `redis-master`
- **Use Case**: Token blacklist, persistent caches

**Redis Ephemeral:**
- **Connection**: Direct Redis connection
- **Service**: `redis-ephemeral.databases.svc.cluster.local:6379`
- **Use Case**: User sessions, temporary data

**Important:**
- No authentication is configured by default (protected by Kubernetes network policies)
- Applications connect via ClusterIP services (internal cluster access only)
- Redis HA requires Sentinel-aware client libraries
- Redis Ephemeral uses standard Redis protocol

---

## Step 4: Deploy CSI Drivers for External Storage

### CSI Drivers Overview

Container Storage Interface (CSI) drivers enable Kubernetes to mount external storage systems as persistent volumes. Lyra supports three CSI drivers for accessing external file shares and object storage:

1. **SMB/CIFS CSI Driver** - Mount Windows SMB shares and Samba file servers
2. **NFS CSI Driver** - Mount NFS (Network File System) shares
3. **S3 CSI Driver** - Mount S3-compatible object storage (AWS S3, MinIO, etc.)

**Use Cases:**
- Mounting existing file shares for document processing
- Accessing shared media storage
- Connecting to S3 buckets for data lakes
- Integration with legacy file servers

**Namespace:** All CSI drivers are deployed in the `csi-drivers` namespace.

**Important:** CSI drivers only provide the mounting capability. Actual storage connections (credentials, paths) are configured later via StorageClasses and PersistentVolumeClaims managed by Lyra.

---

### Deploy SMB/CIFS CSI Driver

The SMB CSI driver enables mounting Windows file shares and Samba servers.

**Chart:** `csi-smb-lyra`

**Chart Configuration:**
- **Name:** `csi-smb-driver`
- **Namespace:** `csi-drivers`
- **Chart Version:** Latest stable version
- **Project:** Lyra Platform

**Verify SMB CSI Driver:**

```bash
# Check CSI driver pods
kubectl get pods -n csi-drivers -l app.kubernetes.io/name=csi-driver-smb
```

**Expected output:**
```
NAME                                READY   STATUS    RESTARTS   AGE
csi-smb-controller-xxxxxxxxx-xxxxx  4/4     Running   0          2m
csi-smb-node-xxxxx                  3/3     Running   0          2m
csi-smb-node-xxxxx                  3/3     Running   0          2m
csi-smb-node-xxxxx                  3/3     Running   0          2m
csi-smb-node-xxxxx                  3/3     Running   0          2m
csi-smb-node-xxxxx                  3/3     Running   0          2m
csi-smb-node-xxxxx                  3/3     Running   0          2m
```

**Pod Components:**
- **csi-smb-controller**: Controller pod managing volume provisioning (4 containers: smb plugin, csi-provisioner, csi-resizer, liveness probe)
- **csi-smb-node**: DaemonSet running on each node for volume mounting (3 containers: smb plugin, node-driver-registrar, liveness probe)

**Verify CSI Driver Registration:**

```bash
# Check CSIDriver object
kubectl get csidriver smb.csi.k8s.io
```

**Expected output:**
```
NAME              ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES        AGE
smb.csi.k8s.io    false            false            false             <unset>         false               Persistent   2m
```

---

### Deploy NFS CSI Driver

The NFS CSI driver enables mounting NFS (Network File System) shares.

**Chart:** `csi-nfs-lyra`

**Chart Configuration:**
- **Name:** `csi-nfs-driver`
- **Namespace:** `csi-drivers`
- **Chart Version:** Latest stable version
- **Project:** Lyra Platform

**Verify NFS CSI Driver:**

```bash
# Check CSI driver pods
kubectl get pods -n csi-drivers -l app.kubernetes.io/name=csi-driver-nfs
```

**Expected output:**
```
NAME                                READY   STATUS    RESTARTS   AGE
csi-nfs-controller-xxxxxxxxx-xxxxx  5/5     Running   0          2m
csi-nfs-node-xxxxx                  3/3     Running   0          2m
csi-nfs-node-xxxxx                  3/3     Running   0          2m
csi-nfs-node-xxxxx                  3/3     Running   0          2m
csi-nfs-node-xxxxx                  3/3     Running   0          2m
csi-nfs-node-xxxxx                  3/3     Running   0          2m
csi-nfs-node-xxxxx                  3/3     Running   0          2m
```

**Pod Components:**
- **csi-nfs-controller**: Controller pod managing volume provisioning (5 containers: nfs plugin, csi-provisioner, csi-snapshotter, csi-resizer, liveness probe)
- **csi-nfs-node**: DaemonSet running on each node for volume mounting (3 containers: nfs plugin, node-driver-registrar, liveness probe)

**Verify CSI Driver Registration:**

```bash
# Check CSIDriver object
kubectl get csidriver nfs.csi.k8s.io
```

**Expected output:**
```
NAME              ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES                  AGE
nfs.csi.k8s.io    false            false            false             <unset>         false               Persistent,Ephemeral   2m
```

---

### Deploy S3 CSI Driver

The S3 CSI driver enables mounting S3-compatible object storage (AWS S3, MinIO, etc.) as file systems.

**Chart:** `csi-s3-lyra`

**Chart Configuration:**
- **Name:** `csi-s3-driver`
- **Namespace:** `csi-drivers`
- **Chart Version:** Latest stable version
- **Project:** Lyra Platform

**Verify S3 CSI Driver:**

```bash
# Check CSI driver pods
kubectl get pods -n csi-drivers -l app.kubernetes.io/name=aws-mountpoint-s3-csi-driver
```

**Expected output:**
```
NAME                                     READY   STATUS    RESTARTS   AGE
s3-csi-controller-xxxxxxxxxx-xxxxx       1/1     Running   0          2m
s3-csi-node-xxxxx                        3/3     Running   0          2m
s3-csi-node-xxxxx                        3/3     Running   0          2m
s3-csi-node-xxxxx                        3/3     Running   0          2m
s3-csi-node-xxxxx                        3/3     Running   0          2m
s3-csi-node-xxxxx                        3/3     Running   0          2m
s3-csi-node-xxxxx                        3/3     Running   0          2m
```

**Pod Components:**
- **s3-csi-controller**: Controller pod for plugin registration (1 container: s3 driver)
- **s3-csi-node**: DaemonSet running on each node for S3 bucket mounting (3 containers: s3 driver, node-driver-registrar, liveness probe)

**Verify CSI Driver Registration:**

```bash
# Check CSIDriver object
kubectl get csidriver s3.csi.aws.com
```

**Expected output:**
```
NAME             ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES        AGE
s3.csi.aws.com   false            true             false             <unset>         false               Persistent   2m
```

---

### CSI Drivers Summary

After deploying all three CSI drivers, verify the complete CSI infrastructure:

**Check all CSI driver pods:**
```bash
kubectl get pods -n csi-drivers
```

**Expected output (all drivers deployed):**
```
NAME                                     READY   STATUS    RESTARTS   AGE
csi-smb-controller-xxxxxxxxx-xxxxx       4/4     Running   0          5m
csi-smb-node-xxxxx                       3/3     Running   0          5m
csi-smb-node-xxxxx                       3/3     Running   0          5m
csi-smb-node-xxxxx                       3/3     Running   0          5m
csi-smb-node-xxxxx                       3/3     Running   0          5m
csi-smb-node-xxxxx                       3/3     Running   0          5m
csi-smb-node-xxxxx                       3/3     Running   0          5m
csi-nfs-controller-xxxxxxxxx-xxxxx       5/5     Running   0          4m
csi-nfs-node-xxxxx                       3/3     Running   0          4m
csi-nfs-node-xxxxx                       3/3     Running   0          4m
csi-nfs-node-xxxxx                       3/3     Running   0          4m
csi-nfs-node-xxxxx                       3/3     Running   0          4m
csi-nfs-node-xxxxx                       3/3     Running   0          4m
csi-nfs-node-xxxxx                       3/3     Running   0          4m
s3-csi-controller-xxxxxxxxxx-xxxxx       1/1     Running   0          3m
s3-csi-node-xxxxx                        3/3     Running   0          3m
s3-csi-node-xxxxx                        3/3     Running   0          3m
s3-csi-node-xxxxx                        3/3     Running   0          3m
s3-csi-node-xxxxx                        3/3     Running   0          3m
s3-csi-node-xxxxx                        3/3     Running   0          3m
s3-csi-node-xxxxx                        3/3     Running   0          3m
```

**Check all registered CSI drivers:**
```bash
kubectl get csidriver
```

**Expected output:**
```
NAME              ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   MODES
nfs.csi.k8s.io    false            false            false             Persistent,Ephemeral
s3.csi.aws.com    false            true             false             Persistent
smb.csi.k8s.io    false            false            false             Persistent
```

**Important Notes:**

1. **No Storage Classes Created**: These charts only deploy CSI drivers. Storage classes are created later by Lyra when configuring document sources.

2. **Credentials Management**: S3 and authenticated SMB/NFS shares require credentials, which are managed through Kubernetes secrets created by Lyra.

3. **S3 Compatibility**: The S3 CSI driver works with AWS S3, MinIO, Ceph Object Gateway, and other S3-compatible storage systems.

4. **Node Requirements**:
   - SMB: Requires `cifs-utils` package on Linux nodes
   - NFS: Requires `nfs-common` package on Linux nodes
   - S3: No special node requirements (uses FUSE)

5. **Performance Considerations**:
   - SMB/NFS: Good for file-based workloads, supports concurrent access
   - S3: Best for read-heavy workloads, limited write performance
   - All drivers suitable for document processing pipelines

---

## Step 5: Deploy MetalLB Load Balancer

### MetalLB Overview

MetalLB is a load balancer implementation for bare-metal Kubernetes clusters. It enables Kubernetes services of type `LoadBalancer` to work on infrastructure that doesn't have a native load balancer (unlike cloud providers like AWS, GCP, Azure).

**Why MetalLB?**
- Provides external IP addresses for LoadBalancer services
- Enables external access to Kubernetes services (Ingress controllers, APIs, etc.)
- Essential for bare-metal and on-premises Kubernetes deployments
- Supports Layer 2 (ARP/NDP) and BGP modes

**Operating Mode:** Lyra uses Layer 2 (L2) mode by default, which is simpler and works on most networks without requiring router configuration.

**Namespace:** MetalLB is deployed in the `metallb-system` namespace.

---

### Deploy MetalLB

**Chart:** `metallb-lyra`

**Chart Configuration:**
- **Name:** `metallb`
- **Namespace:** `metallb-system`
- **Chart Version:** Latest stable version
- **Project:** Lyra Platform

**Important Configuration Values:**

Before installing, you must configure the IP address pool that MetalLB will use to assign external IPs to LoadBalancer services.

**IP Address Pool Configuration:**
```yaml
ipAddressPool:
  enabled: true
  name: "default-pool"
  addresses:
    - "192.168.0.150-192.168.0.200"  # Adjust for your network
```

**⚠️ IMPORTANT:** The IP address range must:
- Be on the same network/subnet as your Kubernetes nodes
- NOT overlap with your DHCP server's range
- NOT be already in use by other devices
- Be routable from your network

**Example Network Configuration:**
- Network: `192.168.0.0/24`
- Router: `192.168.0.1`
- Kubernetes Nodes: `192.168.0.57-192.168.0.62`
- DHCP Range: `192.168.0.100-192.168.0.149`
- **MetalLB Pool: `192.168.0.150-192.168.0.200`** ✅ (Safe range)

---

### Configure IP Address Pool via Rancher

When installing via Rancher, you'll be prompted to configure the IP address pool:

1. Navigate to **Apps & Marketplace → Charts** in Rancher
2. Search for `metallb-lyra` in Harbor catalog
3. Click **Install**
4. Configure:
   - **Namespace:** `metallb-system` (create if needed)
   - **IP Address Pool → Addresses:** Enter your IP range (e.g., `192.168.0.150-192.168.0.200`)
5. Review other settings (defaults are usually fine)
6. Click **Install**

---

### Verify MetalLB Deployment

**Check MetalLB pods:**
```bash
kubectl get pods -n metallb-system
```

**Expected output:**
```
NAME                                  READY   STATUS    RESTARTS   AGE
metallb-controller-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
metallb-speaker-xxxxx                 1/1     Running   0          2m
metallb-speaker-xxxxx                 1/1     Running   0          2m
metallb-speaker-xxxxx                 1/1     Running   0          2m
metallb-speaker-xxxxx                 1/1     Running   0          2m
metallb-speaker-xxxxx                 1/1     Running   0          2m
metallb-speaker-xxxxx                 1/1     Running   0          2m
```

**Pod Components:**
- **metallb-controller**: Central controller managing IP address allocation (1 replica)
- **metallb-speaker**: DaemonSet running on each node for L2 advertisement (announces IPs via ARP)

**Verify IP Address Pool:**
```bash
kubectl get ipaddresspool -n metallb-system
```

**Expected output:**
```
NAME           AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
default-pool   true          false             ["192.168.0.150-192.168.0.200"]
```

**Verify L2 Advertisement:**
```bash
kubectl get l2advertisement -n metallb-system
```

**Expected output:**
```
NAME                    IPADDRESSPOOLS   IPADDRESSPOOL SELECTORS   INTERFACES
default-advertisement   []               []                        []
```

---

### Test MetalLB

Create a test LoadBalancer service to verify MetalLB assigns an external IP:

```bash
# Create a test service
kubectl create deployment nginx-test --image=nginx --port=80
kubectl expose deployment nginx-test --type=LoadBalancer --port=80

# Check the service
kubectl get svc nginx-test
```

**Expected output:**
```
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE
nginx-test   LoadBalancer   10.43.xxx.xxx   192.168.0.150     80:xxxxx/TCP   30s
```

**✅ Success:** The `EXTERNAL-IP` field shows an IP from your MetalLB pool (not `<pending>`)

**Test external access:**
```bash
# Access the service from outside the cluster
curl http://192.168.0.150
# Should return nginx welcome page
```

**Clean up test service:**
```bash
kubectl delete svc nginx-test
kubectl delete deployment nginx-test
```

---

### MetalLB Important Notes

1. **Network Requirements:**
   - All nodes must be on the same Layer 2 network
   - Network switches must support ARP (most do by default)
   - Firewall must allow traffic to the IP pool range

2. **IP Address Management:**
   - MetalLB assigns IPs from the pool on a first-come, first-served basis
   - IPs are retained when services are deleted (can be reclaimed)
   - You can configure multiple IP pools for different purposes

3. **BGP Mode (Advanced):**
   - If you have BGP-capable routers, you can use BGP mode instead of L2
   - BGP provides better load distribution and fault tolerance
   - Requires router configuration (not covered in this guide)

4. **Integration with Ingress:**
   - MetalLB will assign an external IP to your Ingress controller
   - This enables external access to all Ingress-managed applications
   - Typically one LoadBalancer IP for the Ingress controller serves all apps

5. **High Availability:**
   - MetalLB speakers use memberlist protocol to coordinate
   - If a node fails, another speaker takes over IP advertisement
   - Controller has built-in leader election

---

## Infrastructure Deployment Complete

**✅ Congratulations!** You have successfully deployed all required infrastructure components for Lyra Platform.

### Deployed Components Summary

**Storage Infrastructure:**
- ✅ Rook-Ceph storage cluster with RBD and CephFS storage classes
- ✅ CSI drivers for external storage (SMB, NFS, S3)

**Database Infrastructure:**
- ✅ PostgreSQL cluster (3 replicas with high availability)
- ✅ Redis HA (persistent with Sentinel)
- ✅ Redis Ephemeral (memory-only for sessions)

**Networking Infrastructure:**
- ✅ MetalLB load balancer with configured IP pool
- ✅ Layer 2 mode for external service access

**Cluster Configuration:**
- ✅ All components deployed in appropriate namespaces
- ✅ Harbor registry integration configured
- ✅ All components using persistent storage

---

## Next Steps

Now that the infrastructure is deployed, you can proceed with:

1. **[Deploy Lyra Application](initial-deployment.md)** - Deploy the Lyra platform application
2. **[Configure Ingress](../guides/ingress-setup.md)** - Set up external access to Lyra
3. **[Configure Monitoring](../guides/monitoring-setup.md)** - Set up Prometheus and Grafana monitoring

---

## Verification Commands

Run these commands to verify all infrastructure components are healthy:

```bash
# 1. Check Ceph storage
kubectl get pods -n rook-ceph
kubectl get storageclass

# 2. Check PostgreSQL
kubectl get pods -n databases -l app.kubernetes.io/name=lyra-postgres
kubectl get cluster -n databases

# 3. Check Redis
kubectl get pods -n databases -l 'app in (redis-ha,redis-ephemeral)'

# 4. Check CSI drivers
kubectl get pods -n csi-drivers
kubectl get csidriver

# 5. Check MetalLB
kubectl get pods -n metallb-system
kubectl get ipaddresspool -n metallb-system
```

All pods should show `Running` status before proceeding to application deployment.

---

## Next Steps

✅ **Infrastructure Deployed!**

Your Kubernetes cluster now has all required infrastructure components:
- ✅ Ceph/Rook storage with persistent volumes
- ✅ PostgreSQL database cluster (3 replicas)
- ✅ Redis HA and Ephemeral instances
- ✅ CSI drivers for external storage (SMB, NFS, S3)
- ✅ MetalLB load balancer configured

**Proceed to:** [Initial Deployment](initial-deployment.md)

Deploy the Lyra Platform applications (Backend, Frontend, Scheduler).

---

Need help? Check our [troubleshooting guide](../troubleshooting/index.md) or [open an issue](https://github.com/amreinch/lyra/issues).
