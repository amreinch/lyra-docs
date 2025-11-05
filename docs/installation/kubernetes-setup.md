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

### Option A: Using Existing Nodes (Custom Cluster)

This is the recommended approach for bare-metal or VM deployments.

1. **Click "Create" button** in Rancher dashboard

2. **Select "Custom"** cluster type

3. **Configure Cluster Settings:**

   **Cluster Name:** `lyra-production` (or your preferred name)

   **Kubernetes Version:** Select 1.27+ (recommended: latest stable)

   **Network Provider:**
   - **Canal** (recommended) - Provides both networking and network policy
   - Alternative: Calico, Flannel

   **Cloud Provider:** None (for bare-metal/VMs)

4. **Click "Next"**

### Option B: Using Cloud Provider

If using a cloud provider (AWS, Azure, GCP), select the appropriate provider and follow the cloud-specific configuration steps.

---

## Step 3: Configure Node Roles

Rancher will display a registration command for adding nodes. You'll generate different commands for control plane and worker nodes.

### Configure Control Plane Nodes

1. **Check the boxes:**
   - ✅ etcd
   - ✅ Control Plane
   - ⬜ Worker (leave unchecked for dedicated control plane)

2. **Copy the registration command** shown in the Rancher UI

3. **SSH to your control plane server(s)** and run the command:
   ```bash
   # Example command (yours will be different):
   sudo docker run -d --privileged --restart=unless-stopped \
     --net=host -v /etc/kubernetes:/etc/kubernetes \
     -v /var/run:/var/run \
     rancher/rancher-agent:v2.x.x \
     --server https://rancher-server-url \
     --token xxxxx \
     --ca-checksum xxxxx \
     --etcd --controlplane
   ```

4. **Repeat for all control plane nodes:**
   - Minimum: 1 node (development)
   - Production: 3 nodes (high availability)

5. **Wait for nodes to appear** in Rancher UI with status "Active"

### Configure Worker Nodes

1. **Back in Rancher UI, check the boxes:**
   - ⬜ etcd (leave unchecked)
   - ⬜ Control Plane (leave unchecked)
   - ✅ Worker

2. **Copy the new registration command**

3. **SSH to your worker server(s)** and run the command:
   ```bash
   # Example command (yours will be different):
   sudo docker run -d --privileged --restart=unless-stopped \
     --net=host -v /etc/kubernetes:/etc/kubernetes \
     -v /var/run:/var/run \
     rancher/rancher-agent:v2.x.x \
     --server https://rancher-server-url \
     --token xxxxx \
     --ca-checksum xxxxx \
     --worker
   ```

4. **Repeat for all worker nodes:**
   - Minimum: 3 nodes (development)
   - Production: 5+ nodes

5. **Wait for all nodes to become "Active"**

---

## Step 4: Verify Cluster Status

### Check Cluster in Rancher UI

1. Navigate to **Cluster Management** → **Clusters**

2. Your cluster should show:
   - **State:** Active
   - **Provider:** Custom
   - **Nodes:** All nodes showing as "Active"

3. Click on your cluster name to view details

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

## Step 5: Verify Storage Disks

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

## Step 6: Install Ceph/Rook Storage

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
