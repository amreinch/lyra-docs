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

1. **Navigate to Apps → Repositories:**
   - Click your cluster name in Rancher
   - Go to **Apps** → **Repositories** in the left sidebar

2. **Click Create** and configure the repository:
   - **Name:** `lyra-charts`
   - **Target:** Select **Lyra Platform** project
   - **Index URL:** `oci://registry.lyra.ovh/lyra-charts`
   - **Authentication:** (Optional) Add Harbor credentials if required
     - **Username:** Your Harbor username
     - **Password:** Your Harbor password/token

3. **Click Create** to save

**Verification:**
- The repository should appear in the list with status "Active"
- This enables deployment of Lyra Helm charts directly through Rancher UI

### Enable Monitoring (Optional but Recommended)

1. **Navigate to Cluster Tools:**
   - Click your cluster name in Rancher
   - Go to **Cluster Tools** in the left sidebar

2. **Install Monitoring:**
   - Find **Monitoring** in the list
   - Click **Install**
   - Keep default settings or customize as needed
   - Click **Install** and wait for completion

**Benefits:**
- Resource usage metrics (CPU, memory, disk)
- Pod and node monitoring
- Grafana dashboards for visualization
- Prometheus for metrics collection

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

## Step 6: Verify Storage Disks

Before proceeding, verify that worker nodes have the required storage disks for Ceph/Rook.

### Check Disks on Worker Nodes

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

---

## Step 7: Install Ceph/Rook Storage

Lyra requires persistent storage provided by Ceph/Rook.

### Install Rook Operator via Rancher

1. **In Rancher UI, navigate to:**
   - Click your cluster name
   - Go to **Apps & Marketplace** → **Charts**

2. **Search for "Rook-Ceph"**

3. **Click "Install"** and configure:

   **Name:** `rook-ceph`

   **Namespace:** `rook-ceph` (create new)

   **Chart Version:** Latest stable version

4. **Click "Install"** and wait for deployment

5. **Verify Rook Operator is running:**
   ```bash
   kubectl get pods -n rook-ceph
   ```

   **Expected output:**
   ```
   NAME                                  READY   STATUS    RESTARTS   AGE
   rook-ceph-operator-xxxxx              1/1     Running   0          2m
   rook-discover-xxxxx                   1/1     Running   0          2m
   ```

### Create Ceph Cluster

1. **Create Ceph cluster configuration file** `ceph-cluster.yaml`:

   ```yaml
   apiVersion: ceph.rook.io/v1
   kind: CephCluster
   metadata:
     name: rook-ceph
     namespace: rook-ceph
   spec:
     cephVersion:
       image: quay.io/ceph/ceph:v17.2.6
     dataDirHostPath: /var/lib/rook
     mon:
       count: 3
       allowMultiplePerNode: false
     mgr:
       count: 2
       allowMultiplePerNode: false
     dashboard:
       enabled: true
     storage:
       useAllNodes: true
       useAllDevices: false
       deviceFilter: "^sd[b-z]"  # Use sdb, sdc, sdd, etc. (NOT sda)
       config:
         osdsPerDevice: "1"
   ```

2. **Apply the configuration:**
   ```bash
   kubectl apply -f ceph-cluster.yaml
   ```

3. **Monitor Ceph cluster creation** (takes 5-10 minutes):
   ```bash
   kubectl get pods -n rook-ceph -w
   ```

   Wait until you see:
   - `rook-ceph-mon-*` pods running
   - `rook-ceph-osd-*` pods running (one per storage disk)
   - `rook-ceph-mgr-*` pods running

### Create Storage Classes

1. **Create block storage class** `ceph-block-sc.yaml`:

   ```yaml
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
     name: rook-ceph-block
   provisioner: rook-ceph.rbd.csi.ceph.com
   parameters:
     clusterID: rook-ceph
     pool: replicapool
     imageFormat: "2"
     imageFeatures: layering
     csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
     csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
     csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
     csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
     csi.storage.k8s.io/fstype: ext4
   allowVolumeExpansion: true
   reclaimPolicy: Delete
   ```

2. **Apply storage class:**
   ```bash
   kubectl apply -f ceph-block-sc.yaml
   ```

3. **Set as default storage class:**
   ```bash
   kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
   ```

4. **Verify storage class:**
   ```bash
   kubectl get storageclass
   ```

   **Expected output:**
   ```
   NAME                        PROVISIONER                     AGE
   rook-ceph-block (default)   rook-ceph.rbd.csi.ceph.com      1m
   ```

---

## Step 7: Verify Cluster Readiness

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
