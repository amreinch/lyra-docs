# Prerequisites

Before deploying Lyra Platform, ensure you have access to the required services and your environment meets these requirements.

## 1. Rancher Management Server

**REQUIRED**: Rancher is used to manage Kubernetes clusters and deploy Lyra Platform via Helm charts.

### System Requirements

To install Rancher, you need a dedicated Linux server with Docker:

- **Operating System**: Linux (Ubuntu 20.04+, Debian 11+, RHEL 8+, or similar)
- **Docker**: Docker Engine installed and running
- **Network**: Dedicated management server (recommended to be separate from Kubernetes cluster nodes)

### Why Separate from Kubernetes Cluster?

**Best Practice**: Install Rancher on a dedicated Linux system that is NOT part of the Kubernetes cluster you will manage. This provides:

- Management interface remains available even if cluster has issues
- Easier troubleshooting and maintenance
- Better security isolation
- Ability to manage multiple clusters from one Rancher instance

### Install Docker

If Docker is not yet installed on your Rancher management server:

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Verify installation
docker --version

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker
```

**Note**: After Docker is installed, you'll need registry access (see next section) before installing Rancher.

---

## 2. Registry Access

**REQUIRED**: You need access to Lyra's container registry to pull the application images.

### Registry Information

- **Registry URL**: `registry.lyra.ovh`
- **Container Images Project**: `lyra` (contains all application images)
- **Helm Charts Project**: `lyra-charts` (contains deployment charts)

### Getting Access

Contact the Lyra team to receive your registry credentials:

- Username and password/token
- Pull permissions for required projects

### Verify Access

Once you receive your credentials, verify you can access the registry:

```bash
# Login to registry
docker login registry.lyra.ovh
Username: [your-username]
Password: [your-password]

# Verify access to projects
curl -u "[your-username]:[your-password]" \
  https://registry.lyra.ovh/api/v2.0/projects/lyra/repositories
```

**Expected response**: JSON list of available repositories in the lyra project

### Install Rancher

Once you have verified registry access, you can now install Rancher.

**Option A: Using Lyra Registry (Recommended)**

First, check available Rancher versions in the registry:

```bash
# List available Rancher versions
curl -u "[your-username]:[your-password]" \
  https://registry.lyra.ovh/v2/lyra/rancher/tags/list

# Or using the API with formatted output
curl -u "[your-username]:[your-password]" \
  https://registry.lyra.ovh/api/v2.0/projects/lyra/repositories/rancher/artifacts | jq -r '.[].tags[].name'
```

Then pull and run Rancher with a specific version:

```bash
# Login to registry (already done in previous step)
docker login registry.lyra.ovh

# Pull Rancher from Lyra registry (use specific version)
docker pull registry.lyra.ovh/lyra/rancher:v2.12.2

# Run Rancher from Lyra registry
sudo docker run -d \
  --name rancher \
  --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  registry.lyra.ovh/lyra/rancher:v2.12.2

# Check Rancher is running
docker ps | grep rancher
```

**Option B: Using Docker Hub (Alternative)**

If you prefer to use the official Rancher image from Docker Hub:

```bash
# Pull and run Rancher from Docker Hub
sudo docker run -d \
  --name rancher \
  --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:latest

# Check Rancher is running
docker ps | grep rancher
```

### Access Rancher UI

**Note**: Rancher takes several minutes to fully start. During initialization, you may see log messages like "API Aggregation not ready" - this is normal.

Monitor the startup process:

```bash
# Watch Rancher logs
docker logs -f rancher

# Wait for this message: "Bootstrap Password:"
# This indicates Rancher is ready
```

Once Rancher is ready:

1. Open browser to `https://your-rancher-server-ip`
2. You will see the Rancher login screen
3. Retrieve the bootstrap password:
   ```bash
   # Using container name (simplest method)
   sudo docker logs rancher 2>&1 | grep "Bootstrap Password:"

   # Or automatically using container ID (if you need it)
   sudo sh -c 'docker logs $(docker ps -q -f name=rancher) 2>&1 | grep "Bootstrap Password:"'
   ```
4. Copy the password from the output
5. Login with the bootstrap password
6. Complete the initial setup wizard:
   - **Set Password**: Choose to use a randomly generated password or set your own secure password
   - **Server URL**: Set the Rancher server URL (e.g., `https://your-rancher-server-ip` or your domain)
   - **Accept Terms**: Review and accept the End User License Agreement (EULA) and Terms & Conditions
7. Rancher is now ready to import or create Kubernetes clusters

**Important**: You must complete this initial setup on first login for security and proper configuration.

**Typical startup time**: 2-5 minutes depending on server resources

---

## 3. Server Resources

Lyra Platform requires a Kubernetes cluster with adequate server resources.

### Minimum Requirements (Development/Testing)

| Component | Quantity | CPU | Memory | OS Disk (`/dev/sda`) | Storage Disks (Ceph/Rook) |
|-----------|----------|-----|--------|---------------------|---------------------------|
| **Control Plane Nodes** | 1 node | 2 cores | 4GB | 50GB+ | Not required |
| **Worker Nodes** | 3+ nodes | 8+ cores per node | 16GB+ per node | 50GB+ per node | 1x 100GB+ disk per node (e.g., `/dev/sdb`) |

### Recommended for Production

| Component | Quantity | CPU | Memory | OS Disk (`/dev/sda`) | Storage Disks (Ceph/Rook) |
|-----------|----------|-----|--------|---------------------|---------------------------|
| **Control Plane Nodes (HA)** | 3 nodes | 4 cores per node | 8GB per node | 100GB+ per node | Not required |
| **Worker Nodes** | 5+ nodes | 16+ cores per node | 32GB+ per node | 100GB+ per node | 1-3x 500GB+ disks per node (e.g., `/dev/sdb`, `/dev/sdc`, `/dev/sdd`) |

**Important Notes:**
- **OS Disk**: Used only for operating system and Kubernetes components (typically `/dev/sda`)
- **Storage Disks**: Raw/unformatted disks used exclusively by Ceph/Rook for persistent storage (all disks except `/dev/sda`)
- **Control Plane Nodes**: Manage the cluster and should be dedicated to control plane workloads only
- **High Availability**: For production, always use 3 control plane nodes

### Alternative: Control Plane as Worker Node

**For smaller deployments**, you can configure control plane nodes to also run application workloads by removing the default taint. This reduces the total number of nodes required.

**Benefits:**
- Fewer servers required (can start with 3 nodes instead of 4+)
- Lower infrastructure costs
- Simplified management for small deployments

**Considerations:**
- Control plane and application workloads compete for resources
- Less isolation between control plane and workloads
- Not recommended for high-traffic production environments
- Still need 3 control plane nodes for high availability

**Example Configuration:**

| Deployment Type | Control Plane Nodes | Dedicated Worker Nodes | Total Nodes |
|-----------------|---------------------|------------------------|-------------|
| **Dedicated (Recommended)** | 3 nodes (HA) | 5+ nodes | 8+ nodes |
| **Control Plane as Worker** | 3 nodes (HA + Worker) | 0 nodes | 3 nodes |
| **Hybrid** | 3 nodes (HA + Worker) | 2-3 nodes | 5-6 nodes |

**To enable workloads on control plane nodes:**
```bash
# Remove taint from control plane nodes to allow workload scheduling
kubectl taint nodes <control-plane-node-name> node-role.kubernetes.io/control-plane:NoSchedule-
kubectl taint nodes <control-plane-node-name> node-role.kubernetes.io/master:NoSchedule-
```

**When to use this approach:**
- ✅ Development and testing environments
- ✅ Small production deployments with limited resources
- ✅ Edge deployments with hardware constraints
- ❌ High-traffic production environments
- ❌ Environments requiring strict isolation

---

## 4. Required Tools

Install these tools on your workstation/deployment machine:

### Docker
```bash
docker --version
# Required: 20.10+
```

**Why**: Used only if you need to build custom images (not typical)

### kubectl
```bash
kubectl version --client
# Required: 1.24+
```

**Why**: Kubernetes cluster management

### Helm
```bash
helm version
# Required: 3.10+
```

**Why**: Lyra is deployed via Helm chart

### Git
```bash
git --version
# Required: 2.30+
```

**Why**: Version control and deployment scripts

---

## Pre-Installation Checklist

Before proceeding to installation, verify:

### 1. Rancher Management Server
- [ ] Rancher server is running
- [ ] Can access Rancher UI
- [ ] Rancher is configured and ready

### 2. Registry Access
- [ ] Registry credentials received
- [ ] Can login to `registry.lyra.ovh`
- [ ] Can see `lyra` and `lyra-charts` projects

### 3. Kubernetes Cluster
- [ ] Kubernetes cluster is created via Rancher
- [ ] Control plane nodes: 1 (min) or 3 (HA production)
- [ ] Worker nodes: 3+ nodes in Ready state
- [ ] Each worker node has storage disk(s) for Ceph/Rook
- [ ] `kubectl` can connect to cluster

### 4. Required Tools
- [ ] kubectl installed and configured
- [ ] Helm 3.10+ installed
- [ ] Git installed

---

## Quick Verification Commands

Run these commands to verify your environment:

```bash
# 1. Registry access
docker login registry.lyra.ovh

# 2. Kubernetes connection
kubectl cluster-info
kubectl get nodes

# 3. Check available disks on worker nodes
# SSH to a worker node and run:
lsblk
```

---

## Getting Help

If you don't meet these prerequisites:

1. **Missing Registry Access** → Contact Lyra team for registry credentials
2. **No Rancher Server** → Install Docker and Rancher (see Section 1)
3. **No Kubernetes Cluster** → Create cluster via Rancher UI
4. **Disk Configuration Questions** → Ensure each worker has raw/unformatted storage disks

---

## Next Steps

✅ **Prerequisites met?**

Proceed to: **[Initial Deployment](initial-deployment.md)**

---

**Need assistance?** Contact Lyra support or [open an issue](https://github.com/amreinch/lyra/issues)
