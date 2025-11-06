# Install & Configure Kubernetes Cluster

This guide walks you through creating and configuring a Kubernetes cluster using Rancher for deploying Lyra Platform.

## Overview

After completing the prerequisites, you'll use Rancher to:

1. Create a new Kubernetes cluster
2. Configure cluster nodes (control plane and workers)
3. Configure storage for Ceph/Rook
4. Verify cluster is ready for Lyra deployment

**Estimated Time:** 30-60 minutes (including node provisioning)

---

## Step 1: Access Rancher UI

1. Open your web browser and navigate to your Rancher server:
   ```
   https://your-rancher-server-ip
   ```

2. Login with the credentials you set during initial setup

3. You should see the Rancher dashboard with cluster management options

---

## Step 2: Create Kubernetes Cluster

This guide uses bare-metal or VM deployments with a custom cluster configuration.

1. **Click "Create" button** in Rancher dashboard

2. **Select "Custom"** cluster type

3. **Configure Cluster Settings:**

   **Cluster Name:** `lyra-production` (or your preferred name)

   **Kubernetes Version:** v1.33.5+rke2r1 (recommended)

   **Network Provider:** Calico - Provides both networking and network policy

   **Cloud Provider:** None (for bare-metal/VMs)

4. **Click "Next"**

---

## Step 3: Configure Node Roles

Before configuring nodes, it's important to understand the three roles in Kubernetes:

---

### etcd Role

**Purpose**
Distributed key-value database that stores all cluster data and state.

**Responsibilities**
- Stores cluster configuration and state
- Maintains consistency across the cluster
- Provides cluster-wide data persistence

**Requirements**
- **Must be odd number** of nodes (3, 5, or 7) for quorum and fault tolerance
- Low latency storage (SSD recommended)
- Reliable network connectivity between etcd nodes

---

### Control Plane Role

**Purpose**
Manages the Kubernetes cluster and makes decisions about workload scheduling.

**Responsibilities**
- API server (kubectl commands go here)
- Scheduler (decides which node runs which pod)
- Controller manager (maintains desired cluster state)
- Cloud controller manager (cloud provider integration)

**Requirements**
- Adequate CPU and memory for cluster management
- Should be highly available (3 nodes recommended for production)

---

### Worker Role

**Purpose**
Runs application workloads and services.

**Responsibilities**
- Runs containerized applications (pods)
- Provides compute resources for workloads
- Executes storage operations (when Ceph/Rook is deployed)

**Requirements**
- Storage disks for Ceph/Rook (e.g., `/dev/sdb`, `/dev/sdc`)
- Adequate CPU and memory for application workloads
- Can be scaled horizontally (add more workers as needed)

---

### Deployment Strategies

Rancher will display a registration command for adding nodes. Choose one of the deployment strategies below based on your infrastructure.

### Deployment Strategy A: Dedicated Roles (Recommended for Production)

This approach separates control plane and worker responsibilities for better isolation and performance.

**Node Configuration:**
- **Control Plane Nodes**: etcd + Control Plane only (no Worker role)
- **Worker Nodes**: Worker role only
- **Total Nodes**: Minimum 4 nodes (1 control plane + 3 workers) or 8+ nodes for HA (3 control plane + 5 workers)

#### Configure Control Plane Nodes

1. **In Rancher UI, check the boxes:**
   - ✅ etcd
   - ✅ Control Plane
   - ⬜ Worker (leave unchecked)

2. **Copy the registration command** shown in the Rancher UI

3. **SSH to your control plane server(s)** and run the command:
   ```bash
   # Example command (yours will be different):
   curl -fL https://rancher-server-ip/system-agent-install.sh | sudo sh -s - \
     --server https://rancher-server-ip \
     --label 'cattle.io/os=linux' \
     --token xxxxx \
     --ca-checksum xxxxx \
     --etcd --controlplane

   # If using self-signed certificate, add --insecure flag:
   curl --insecure -fL https://rancher-server-ip/system-agent-install.sh | sudo sh -s - \
     --server https://rancher-server-ip \
     --label 'cattle.io/os=linux' \
     --token xxxxx \
     --ca-checksum xxxxx \
     --etcd --controlplane
   ```

4. **Repeat for all control plane nodes** (1 for dev, 3 for HA production)

5. **Wait for nodes to appear** in Rancher UI with status "Active"

#### Configure Worker Nodes

1. **In Rancher UI, check the boxes:**
   - ⬜ etcd (leave unchecked)
   - ⬜ Control Plane (leave unchecked)
   - ✅ Worker

2. **Copy the new registration command**

3. **SSH to your worker server(s)** and run the command:
   ```bash
   # Example command (yours will be different):
   curl -fL https://rancher-server-ip/system-agent-install.sh | sudo sh -s - \
     --server https://rancher-server-ip \
     --label 'cattle.io/os=linux' \
     --token xxxxx \
     --ca-checksum xxxxx \
     --worker

   # If using self-signed certificate, add --insecure flag:
   curl --insecure -fL https://rancher-server-ip/system-agent-install.sh | sudo sh -s - \
     --server https://rancher-server-ip \
     --label 'cattle.io/os=linux' \
     --token xxxxx \
     --ca-checksum xxxxx \
     --worker
   ```

4. **Repeat for all worker nodes** (3+ nodes minimum)

5. **Wait for all nodes to become "Active"**

---

### Deployment Strategy B: Combined Roles (For Smaller Deployments)

This approach combines all roles on the same nodes to reduce server count.

**Node Configuration:**
- **Combined Role Nodes**: etcd + Control Plane + Worker (all three roles)
- **etcd Nodes**: Must be odd number (3, 5, or 7) for quorum
- **Total Nodes**: Variable - you can add worker-only nodes to combined role nodes

**Note**: Only the nodes with **etcd** role need to be an odd number. You can mix:
- 3 nodes with etcd + control plane + worker (required minimum)
- Additional worker-only nodes as needed (any number)

**Benefits:**
- Fewer servers required (3 nodes instead of 4-8)
- Lower infrastructure costs
- Simpler for development/testing or small production deployments

**Considerations:**
- Control plane and application workloads share resources
- Less isolation than dedicated roles
- Still provides high availability with 3+ nodes

#### Configure Combined Role Nodes

1. **In Rancher UI, check ALL boxes:**
   - ✅ etcd
   - ✅ Control Plane
   - ✅ Worker

2. **Copy the registration command**

3. **SSH to each server** and run the command:
   ```bash
   # Example command (yours will be different):
   curl -fL https://rancher-server-ip/system-agent-install.sh | sudo sh -s - \
     --server https://rancher-server-ip \
     --label 'cattle.io/os=linux' \
     --token xxxxx \
     --ca-checksum xxxxx \
     --etcd --controlplane --worker

   # If using self-signed certificate, add --insecure flag:
   curl --insecure -fL https://rancher-server-ip/system-agent-install.sh | sudo sh -s - \
     --server https://rancher-server-ip \
     --label 'cattle.io/os=linux' \
     --token xxxxx \
     --ca-checksum xxxxx \
     --etcd --controlplane --worker
   ```

4. **Repeat for combined role nodes** (must be odd number: 3, 5, or 7 nodes with etcd)

5. **(Optional) Add dedicated worker nodes:**
   If you need more capacity, you can add worker-only nodes following the steps in Strategy A.

6. **Wait for all nodes to become "Active"**

**Important**: Each node with Worker role must have storage disks (e.g., `/dev/sdb`) for Ceph/Rook.

**Example Hybrid Configuration:**
- 3 nodes: etcd + control plane + worker (with storage disks)
- 2 nodes: worker only (with storage disks)
- Total: 5 nodes (3 etcd nodes for quorum + 2 additional workers for capacity)

---

### Which Strategy to Choose?

| Scenario | Recommended Strategy | Node Count | Configuration |
|----------|---------------------|------------|---------------|
| **Development/Testing** | Combined Roles | 3 nodes | 3 nodes (etcd + control + worker) |
| **Small Production** | Combined Roles | 3-5 nodes | 3 nodes (etcd + control + worker) + 0-2 workers |
| **Medium Production** | Hybrid or Dedicated | 5-8 nodes | 3 nodes (etcd + control + worker) + 2-5 workers OR 1-3 control + 4-5 workers |
| **Large Production (HA)** | Dedicated Roles | 8+ nodes | 3 control + 5+ workers |
| **Enterprise/High-Traffic** | Dedicated Roles | 10+ nodes | 3 control + 7+ workers |

**Key Points:**
- **etcd nodes**: Always odd number (3, 5, or 7) for quorum
- **Worker nodes**: Can be any number
- **Hybrid**: Combine strategies - etcd+control+worker nodes PLUS dedicated workers

---

## Step 4: Verify Cluster Status

### Check Cluster in Rancher UI

1. Navigate to **Cluster Management** → **Clusters**

2. Your cluster should show:
   - **State:** Active
   - **Provider:** Custom
   - **Nodes:** All nodes showing as "Active"

3. Click on your cluster name to view details

4. **Verify Machines Tab:**
   - Navigate to **Cluster Management** → **Clusters** → **Your Cluster Name**
   - Click on the **Machines** tab
   - **Important:** When every node under the Machines tab shows status **"Running"**, the initial cluster creation has completed successfully
   - All machines should display:
     - **State:** Running
     - **Node:** Node name (e.g., control-node-1, worker-node-1)
     - **Roles:** Assigned roles (etcd, controlplane, worker)

### Verify with kubectl

1. **Download kubeconfig** from Rancher:
   - Click your cluster name
   - Click "Download KubeConfig" button
   - Save the file (e.g., `kubeconfig-lyra.yaml`)

2. **Set KUBECONFIG environment variable:**
   ```bash
   export KUBECONFIG=/path/to/kubeconfig-lyra.yaml
   ```

3. **Verify cluster connectivity:**
   ```bash
   kubectl cluster-info
   ```

   **Expected output:**
   ```
   Kubernetes control plane is running at https://...
   CoreDNS is running at https://...
   ```

4. **Check node status:**
   ```bash
   kubectl get nodes
   ```

   **Expected output:**
   ```
   NAME            STATUS   ROLES                       AGE   VERSION
   control-node-1  Ready    controlplane,etcd           5m    v1.27.x
   control-node-2  Ready    controlplane,etcd           5m    v1.27.x
   control-node-3  Ready    controlplane,etcd           5m    v1.27.x
   worker-node-1   Ready    worker                      5m    v1.27.x
   worker-node-2   Ready    worker                      5m    v1.27.x
   worker-node-3   Ready    worker                      5m    v1.27.x
   ```

   All nodes should show `Ready` status.

---

## Step 5: Configure Rancher for Deployments

After cluster creation, configure Rancher settings required for application deployments.

### Create Lyra Project in Rancher

**IMPORTANT**: Rancher Projects provide organizational structure and resource isolation for related applications. Create a dedicated project for the Lyra Platform and its components.

1. **Navigate to Projects/Namespaces:**
   - Click your cluster name in Rancher
   - Go to **Projects/Namespaces** in the left sidebar

2. **Create New Project:**
   - Click **Create Project** button
   - **Project Name:** `Lyra Platform`
   - **Description:** `Lyra application and infrastructure components`
   - **Resource Quotas:** (Optional) Set limits for the project
   - **Container Default Resource Limit:** (Optional) Set default limits

3. **Click Create**

**What will be deployed in this project:**
- Lyra Backend application
- Lyra Frontend application
- Lyra Scheduler service
- PostgreSQL database
- Redis cache
- Supporting infrastructure services

**Benefits of using a dedicated project:**
- Logical grouping of all Lyra-related deployments
- Resource quota management for the entire platform
- Simplified RBAC (Role-Based Access Control)
- Clear separation from other applications
- Easier monitoring and troubleshooting

### Add Lyra Helm Chart Repository

**REQUIRED**: Add the Lyra OCI Helm chart repository to the project to enable deployment of Lyra applications.

1. Go to **Lyra Platform** cluster and navigate to **Apps** → **Repositories**

2. **Click Create** and configure the repository:
   - **Name:** `lyra-charts`
   - Select **OCI Repository**
   - **Index URL:** `oci://registry.lyra.ovh/lyra-charts`
   - **Authentication:** Create an HTTP Basic Auth Secret
     - **Username:** Your Harbor username
     - **Password:** Your Harbor password/token
   - Click **Create** to save

**Verification:**
- The repository should appear in the list with status "Active"
- This enables deployment of Lyra Helm charts directly through Rancher UI

### Configure Container Registry Access

**CRITICAL**: Create a project-level registry secret to allow all deployments in the Lyra Platform project to pull images from Harbor.

1. **Navigate to your cluster** in Rancher and go to **Storage** → **Project Secrets**

2. **Click Create** and configure the registry secret:
   - **Type:** Select **Registry**
   - **Project:** Select **Lyra Platform** (the project you created earlier)
   - **Name:** `harbor-registry-secret` (must use this exact name)
   - **Registry Domain Name:** `registry.lyra.ovh`
   - **Username:** Your Harbor username (from Prerequisites)
   - **Password:** Your Harbor password/token
   - Click **Create** to save

**Why project-level secret:**
- Automatically available to all namespaces created within the Lyra Platform project
- Deployments will automatically create their namespaces and inherit this secret
- No need to manually create the secret in each namespace
- Simplifies Helm chart deployments

**Important:** The secret must be named exactly `harbor-registry-secret` as Lyra Helm charts reference this name.

**Note:** Namespaces within the Lyra Platform project will be created automatically by Helm chart deployments in the next installation steps.

---

## Step 6: Deploy Lyra Applications and Services

With the cluster configured and Rancher settings in place, you can now deploy Lyra Platform applications and services using Helm charts.

### Deployment Overview

Lyra Platform consists of multiple components that need to be deployed in order:

1. **Infrastructure Services** (PostgreSQL, Redis, Storage and more)
2. **Lyra Core Applications** (Backend, Frontend, Scheduler)

All deployments are managed through Rancher's Apps & Marketplace interface using the Helm charts from your Harbor registry.

### Deploy via Rancher UI

1. **Select lyra-charts repository:**
   - Go to your **Lyra Platform** cluster in Rancher and navigate to **Apps** → **Charts**
   - This will give you access to all Lyra infrastructure and application charts

2. **Install desired chart:**
   - Browse available charts (lyra-app, postgresql, redis, etc.)
   - Click on the chart you want to install
   - Click **Install**
   - **Chart Version:** Select the desired version (e.g., `1.0.0`)

3. **Configure Deployment:**
   - **Namespace:** The Helm charts define the namespace automatically
   - **Names:** Names are also defined by the Helm chart
   - **Project:** Select **Lyra Platform** from the dropdown (the project you created earlier)
   - **Helm Values:** Each chart includes predefined values that can be customized through Rancher's configuration forms. All values are already configured to work out of the box, but you can adjust them to match your specific requirements.

4. **Click Install** and wait for deployment to complete

---

## Step 7: Install Ceph/Rook Storage

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

Install the **rook-ceph-lyra-operator** chart following the deployment process described above in Step 6.

**Chart Configuration:**
- **Name:** `rook-ceph-operator`
- **Namespace:** `rook-ceph`
- **Chart Version:** Latest stable version

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

Install the **rook-ceph-lyra-cluster** chart following the deployment process described in Step 6.

**Chart Configuration:**
- **Name:** `rook-ceph-cluster`
- **Namespace:** `rook-ceph`
- **Chart Version:** Latest stable version

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

## Step 8: Deploy PostgreSQL Database

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
- Provides connection pooling with PgBouncer
- Monitors database health and performance

Install the **postgres-operator** chart following the deployment process described in Step 6.

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
- Sets up connection pooling with PgBouncer
- Provides automatic backups and point-in-time recovery
- Creates database users and credentials

Install the **postgres-cluster** chart following the deployment process described in Step 6.

**Chart Configuration:**
- **Name:** `postgres-cluster` (or your preferred cluster name)
- **Namespace:** `databases`
- **Chart Version:** Latest stable version
- **Project:** `Lyra Platform`

**Important Configuration Values:**
- **Cluster Name**: Name of your PostgreSQL cluster (e.g., `lyra-postgres`)
- **Number of Instances**: Replica count (recommended: 2+ for HA)
- **Storage Size**: Persistent volume size (e.g., `10Gi` for development, `100Gi+` for production)
- **Storage Class**: `rook-ceph-block` (uses Ceph storage from Step 7)
- **Database Name**: Initial database to create (e.g., `lyra`)
- **Database User**: Application database user (e.g., `lyra_user`)

**Monitor PostgreSQL cluster creation** (takes 2-5 minutes):
```bash
kubectl get pods -n databases -w
```

**Verify all PostgreSQL pods are running:**
```bash
kubectl get pods -n databases
```

**Expected output (for 2-replica cluster):**
```
NAME                                 READY   STATUS    RESTARTS   AGE
postgres-operator-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
lyra-postgres-0                      1/1     Running   0          2m
lyra-postgres-1                      1/1     Running   0          2m
lyra-postgres-pooler-xxxxxxxxxx-xxxxx 1/1     Running   0          2m
```

**Pod Components:**
- `postgres-operator-*` - PostgreSQL operator managing clusters
- `lyra-postgres-0`, `lyra-postgres-1` - PostgreSQL database instances (replicas)
- `lyra-postgres-pooler-*` - PgBouncer connection pooler

**Verify PostgreSQL cluster status:**
```bash
kubectl get postgresql -n databases
```

**Expected output:**
```
NAME            TEAM   VERSION   PODS   VOLUME   CPU-REQUEST   MEMORY-REQUEST   AGE   STATUS
lyra-postgres   lyra   16        2      10Gi     100m          256Mi            2m    Running
```

**Verify PostgreSQL services:**
```bash
kubectl get svc -n databases
```

**Expected output:**
```
NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
lyra-postgres              ClusterIP   10.43.xxx.xxx   <none>        5432/TCP   2m
lyra-postgres-pooler       ClusterIP   10.43.xxx.xxx   <none>        5432/TCP   2m
lyra-postgres-repl         ClusterIP   10.43.xxx.xxx   <none>        5432/TCP   2m
```

**Service Endpoints:**
- `lyra-postgres` - Primary database connection endpoint
- `lyra-postgres-pooler` - Connection pooler endpoint (recommended for applications)
- `lyra-postgres-repl` - Read replica endpoint

**Retrieve Database Credentials:**

The PostgreSQL operator automatically creates Kubernetes secrets with database credentials:

```bash
# List secrets in databases namespace
kubectl get secrets -n databases

# View database user credentials
kubectl get secret <username>.<cluster-name>.credentials.postgresql.acid.zalan.do \
  -n databases -o jsonpath='{.data.password}' | base64 -d
```

**Example:**
```bash
# For user 'lyra_user' in cluster 'lyra-postgres'
kubectl get secret lyra_user.lyra-postgres.credentials.postgresql.acid.zalan.do \
  -n databases -o jsonpath='{.data.password}' | base64 -d
```

**Important:**
- Save database credentials securely - they will be needed for Lyra application configuration
- The connection string format: `postgresql://lyra_user:<password>@lyra-postgres-pooler.databases.svc.cluster.local:5432/lyra`
- Always use the pooler endpoint for application connections for better performance and connection management

---

## Step 9: Verify Cluster Readiness

### Final Verification Checklist

Run these commands to verify cluster is ready for Lyra deployment:

```bash
# 1. All nodes are ready
kubectl get nodes
# All should show STATUS: Ready

# 2. All system pods are running
kubectl get pods -n kube-system
# All should show STATUS: Running

# 3. Rook-Ceph is healthy
kubectl get pods -n rook-ceph
# All should show STATUS: Running

# 4. Storage class is available
kubectl get storageclass
# Should show rook-ceph-block as default

# 5. Test storage provisioning
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: rook-ceph-block
EOF

# 6. Check PVC status
kubectl get pvc test-pvc
# Should show STATUS: Bound

# 7. Clean up test PVC
kubectl delete pvc test-pvc
```

**All checks should pass before proceeding to Lyra deployment.**

---

## Optional: Control Plane as Worker Configuration

If you chose the "Control Plane as Worker" deployment model (see Prerequisites), configure it now:

### Remove Taints from Control Plane Nodes

```bash
# List control plane nodes
kubectl get nodes -l node-role.kubernetes.io/controlplane=true

# Remove taints from each control plane node
kubectl taint nodes <control-plane-node-name> node-role.kubernetes.io/control-plane:NoSchedule-
kubectl taint nodes <control-plane-node-name> node-role.kubernetes.io/master:NoSchedule-

# Repeat for all control plane nodes
```

### Add Storage Disks to Control Plane Nodes

If using control plane as workers, ensure each control plane node also has storage disks:

1. SSH to each control plane node
2. Verify storage disks with `lsblk`
3. Ensure `/dev/sdb` (and optionally more) are available and unformatted

Ceph will automatically detect and use these disks since we configured `useAllNodes: true`.

---

## Troubleshooting

### Nodes Not Appearing in Rancher

**Problem:** Node doesn't show up after running registration command

**Solutions:**
```bash
# Check if rancher-agent container is running
sudo docker ps | grep rancher-agent

# Check rancher-agent logs
sudo docker logs <container-id>

# Common issues:
# - Firewall blocking connection to Rancher server
# - Incorrect Rancher server URL
# - Network connectivity issues
```

### Ceph OSD Pods Not Starting

**Problem:** `rook-ceph-osd-*` pods stuck in pending or error state

**Solutions:**
```bash
# Check Rook operator logs
kubectl logs -n rook-ceph deployment/rook-ceph-operator

# Check if disks are being detected
kubectl get pods -n rook-ceph -l app=rook-ceph-osd-prepare

# Common issues:
# - Disks are already formatted (must be raw)
# - deviceFilter doesn't match your disk names
# - Not enough disks available
```

### Storage Class Not Working

**Problem:** PVC stuck in "Pending" status

**Solutions:**
```bash
# Describe the PVC to see error
kubectl describe pvc <pvc-name>

# Check Ceph cluster status
kubectl get cephcluster -n rook-ceph

# Check Ceph health
kubectl exec -n rook-ceph deployment/rook-ceph-tools -- ceph status

# Common issues:
# - Ceph cluster not healthy
# - Insufficient OSDs
# - Storage class misconfiguration
```

---

## Next Steps

✅ **Cluster Ready!**

Your Kubernetes cluster is now configured and ready for Lyra Platform deployment.

Proceed to: **[Initial Deployment](initial-deployment.md)**

---

**Need assistance?** Contact Lyra support or [open an issue](https://github.com/amreinch/lyra/issues)
