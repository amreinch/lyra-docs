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

**Control Plane Nodes:**
- **Quantity**: 1 node
- **CPU**: 4+ cores
- **Memory**: 8GB+
- **Disk**: 100GB+ (OS disk - typically `/dev/sda`)

**Worker Nodes:**
- **Quantity**: 3+ nodes
- **CPU**: 8+ cores per node
- **Memory**: 16GB+ per node
- **Disk**: 100GB+ (OS disk - typically `/dev/sda`)

### Recommended for Production

**Control Plane Nodes (High Availability):**
- **Quantity**: 3 nodes
- **CPU**: 8+ cores per node
- **Memory**: 16GB+ per node
- **Disk**: 200GB+ (OS disk - typically `/dev/sda`)

**Worker Nodes:**
- **Quantity**: 5+ nodes
- **CPU**: 16+ cores per node
- **Memory**: 32GB+ per node
- **Disk**: 200GB+ (OS disk - typically `/dev/sda`)

**Note**: Control plane nodes manage the cluster and should be dedicated to control plane workloads only. For high availability in production, always use 3 control plane nodes.

---

## 4. Storage

Lyra requires persistent storage for databases, caches, and tenant data.

### Storage Requirements

**What needs storage:**
- PostgreSQL database
- Redis cache
- AI model files (per tenant)
- Application backups

**Minimum storage**: 100GB
**Recommended**: 500GB+ with Ceph/Rook cluster

### Additional Storage Disks

**Required**: Each Kubernetes node should have one or more dedicated storage disks for Ceph/Rook.

**Storage Disk Rules:**
- **OS Disk**: `/dev/sda` is reserved for the operating system
- **Storage Disks**: All other disks (`/dev/sdb`, `/dev/sdc`, etc.) will be used for storage
- **Disk State**: Raw/unformatted - leave disks unformatted
- **Format**: Do NOT format or partition storage disks - Ceph will manage them directly

**Minimum Configuration:**
- **Development**: 1 additional disk per node (e.g., `/dev/sdb`)
- **Size**: 100GB minimum per storage disk
- **Production**: 500GB+ recommended per storage disk

**Example: Single Storage Disk**
```bash
# Check available disks
lsblk

# Expected: Unformatted disk for storage
# NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
# sda      8:0    0   100G  0 disk           <- OS disk (do not use)
# └─sda1   8:1    0   100G  0 part /
# sdb      8:16   0   500G  0 disk           <- Storage disk (will be used)
```

**Example: Multiple Storage Disks**
```bash
# Check available disks
lsblk

# Expected: Multiple unformatted disks for storage
# NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
# sda      8:0    0   100G  0 disk           <- OS disk (do not use)
# └─sda1   8:1    0   100G  0 part /
# sdb      8:16   0   500G  0 disk           <- Storage disk (will be used)
# sdc      8:32   0   500G  0 disk           <- Storage disk (will be used)
# sdd      8:48   0   500G  0 disk           <- Storage disk (will be used)
```

**Important**: Ceph/Rook will automatically detect and use all raw block devices excluding `/dev/sda`. Do NOT manually format, partition, or mount these disks.

### Storage Classes Required

You need at least one of these storage types:

1. **Block Storage** (RWO - ReadWriteOnce)
   - For databases (PostgreSQL)
   - Storage class example: `rook-ceph-block`, `local-path`, `gp2`

2. **Shared Storage** (RWX - ReadWriteMany) *(Optional)*
   - For AI model sharing between pods
   - Storage class example: `rook-cephfs`, `nfs-client`

### Verify Storage Classes

```bash
# List available storage classes
kubectl get storageclass

# You should see at least one storage class marked as (default)
```

**Example output:**
```
NAME                   PROVISIONER                     AGE
rook-ceph-block       rook-ceph.rbd.csi.ceph.com      30d
rook-cephfs           rook-ceph.cephfs.csi.ceph.com   30d
```

---

## 5. Database (PostgreSQL)

Lyra requires PostgreSQL for application data storage.

### Requirements

- **PostgreSQL version**: 13+ (Recommended: 15+)
- **Database size**: 10GB+ (grows with usage)
- **Backup**: Automated backup strategy required

### Options

**Option A: Managed Database Service** (Recommended)
- AWS RDS PostgreSQL
- Azure Database for PostgreSQL
- Google Cloud SQL
- Automated backups and high availability included

**Option B: In-Cluster PostgreSQL**
- Deploy PostgreSQL in Kubernetes
- Requires persistent volume
- Manual backup configuration needed

### What You Need

Either:
- Access credentials to existing PostgreSQL instance, OR
- Ability to provision PostgreSQL in your cluster

**Connection details required:**
```
Host: postgresql.lyra.svc.cluster.local
Port: 5432
Database: lyra
Username: lyra_user
Password: [secure password]
```

---

## 6. Redis Cache

Lyra uses Redis for session management and caching.

### Requirements

- **Redis version**: 6+ (Recommended: 7+)
- **High availability**: Redis Sentinel recommended for production

### Options

**Option A: Managed Redis** (Recommended)
- AWS ElastiCache
- Azure Cache for Redis
- Google Cloud Memorystore

**Option B: In-Cluster Redis**
- Deploy Redis in Kubernetes
- Use Redis Sentinel for HA
- Persistent volume for AOF backups

### What You Need

Either:
- Access credentials to existing Redis instance, OR
- Ability to provision Redis in your cluster

**Connection details required:**
```
Host: redis-master.lyra.svc.cluster.local
Port: 6379
Password: [secure password]
```

---

## 7. Ingress & Networking

External access to Lyra requires ingress configuration.

### Ingress Controller

**Required**: One of the following
- Nginx Ingress Controller (Recommended)
- Traefik
- HAProxy Ingress

### Load Balancer

**Required**: External IP assignment
- MetalLB (for bare-metal clusters)
- Cloud provider LoadBalancer (ELB, ALB, etc.)

### DNS Configuration

**Required**: DNS records pointing to your cluster

Example:
- `lyra.yourdomain.com` → Your cluster's external IP
- `*.lyra.yourdomain.com` → Your cluster's external IP (wildcard)

### SSL/TLS Certificates

**Options:**

1. **Let's Encrypt** (Recommended)
   - Free automated certificates
   - Requires cert-manager in cluster
   - HTTP-01 or DNS-01 challenge

2. **Manual Certificates**
   - Bring your own SSL certificate
   - Store as Kubernetes Secret

3. **Self-Signed** (Development only)
   - Auto-generated during deployment
   - Browser security warnings

---

## 8. Required Tools

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

### Access & Credentials
- [ ] Harbor registry credentials received
- [ ] Can login to `registry.lyra.ovh`
- [ ] Can see `lyra` project images

### Kubernetes
- [ ] Kubernetes cluster is running
- [ ] `kubectl` can connect to cluster
- [ ] At least 3 worker nodes in Ready state
- [ ] Sufficient CPU and memory available

### Storage
- [ ] At least one StorageClass available
- [ ] Can provision PersistentVolumeClaims
- [ ] Sufficient storage capacity (100GB+)

### Database & Cache
- [ ] PostgreSQL 13+ accessible or provisionable
- [ ] Redis 6+ accessible or provisionable
- [ ] Database credentials prepared

### Networking
- [ ] Ingress controller installed
- [ ] LoadBalancer can assign external IP
- [ ] DNS records configured (or ready to configure)
- [ ] SSL certificate ready or cert-manager installed

### Tools
- [ ] kubectl installed and configured
- [ ] Helm 3.10+ installed
- [ ] Git installed

---

## Quick Verification Commands

Run these commands to verify your environment:

```bash
# 1. Harbor access
docker login registry.lyra.ovh

# 2. Kubernetes connection
kubectl cluster-info
kubectl get nodes

# 3. Storage classes
kubectl get storageclass

# 4. Ingress controller
kubectl get pods -n ingress-nginx
# or
kubectl get pods -n kube-system | grep traefik

# 5. Available resources
kubectl top nodes
```

---

## Getting Help

If you don't meet these prerequisites:

1. **Missing Harbor access** → Contact Lyra team for registry credentials
2. **No Kubernetes cluster** → See Kubernetes setup guides
3. **Storage questions** → Contact your infrastructure team
4. **Database/Redis hosting** → Consider managed services

---

## Next Steps

✅ **Prerequisites met?**

Proceed to: **[Initial Deployment](initial-deployment.md)**

---

**Need assistance?** Contact Lyra support or [open an issue](https://github.com/amreinch/lyra/issues)
