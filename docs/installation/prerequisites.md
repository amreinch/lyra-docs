# Prerequisites

Before deploying Lyra Platform, ensure you have access to the required services and your environment meets these requirements.

## 1. Registry Access

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

---

## 2. Kubernetes Cluster

A functioning Kubernetes cluster is required to deploy Lyra Platform.

### Minimum Requirements

- **Kubernetes version**: 1.24+ (Recommended: 1.27+)
- **Worker nodes**: 3+ nodes
- **CPU**: 8+ cores per node
- **Memory**: 16GB+ per node
- **Storage**: 100GB+ available

### Recommended for Production

- **Kubernetes version**: 1.27+
- **Worker nodes**: 5+ nodes
- **CPU**: 16+ cores per node
- **Memory**: 32GB+ per node
- **Storage**: 500GB+ with dedicated storage cluster

### Supported Kubernetes Distributions

- **RKE2** (Recommended)
- **K3s**
- **Kubeadm**
- **Managed Kubernetes** (EKS, AKS, GKE)

### Verify Kubernetes Access

```bash
# Check cluster connection
kubectl cluster-info

# Check node status
kubectl get nodes

# Expected: All nodes in Ready state
```

---

## 3. Storage

Lyra requires persistent storage for databases, caches, and tenant data.

### Storage Requirements

**What needs storage:**
- PostgreSQL database
- Redis cache
- AI model files (per tenant)
- Application backups

**Minimum storage**: 100GB
**Recommended**: 500GB+ with Ceph/Rook cluster

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

## 4. Database (PostgreSQL)

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

## 5. Redis Cache

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

## 6. Ingress & Networking

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

## 7. Required Tools

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
