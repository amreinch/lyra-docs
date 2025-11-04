# Prerequisites

Before deploying Lyra Platform, ensure your environment meets these requirements.

## Infrastructure Requirements

### Kubernetes Cluster

**Minimum Requirements:**
- Kubernetes version: **1.24+** (Recommended: **1.27+**)
- Worker nodes: **3+** nodes
- CPU: **8+ cores** per node
- Memory: **16GB+** per node
- Storage: **100GB+** available

**Recommended for Production:**
- Kubernetes version: **1.27+**
- Worker nodes: **5+** nodes
- CPU: **16+ cores** per node
- Memory: **32GB+** per node
- Storage: **500GB+** Ceph cluster

### Storage Backend

Lyra requires persistent storage for:
- PostgreSQL database
- Redis cache
- Tenant-specific AI model storage
- Application logs and backups

**Supported Storage:**
- **Ceph/Rook** (Recommended) - RBD (block) and CephFS (shared filesystem)
- **NFS** - For shared storage
- **Local PV** - Development only

**Storage Classes Required:**
- `rook-ceph-block` (or equivalent) - For RBD block storage
- `rook-cephfs` (or equivalent) - For shared filesystem storage

### Container Registry

**Harbor Registry:**
- Version: **2.8+**
- Accessible from Kubernetes cluster
- Robot account with push/pull permissions
- Helm chart repository enabled

**Example Setup:**
- Registry URL: `registry.lyra.ovh`
- Project: `lyra`
- Robot Account: `robot$lyra-deployer`

## Network Requirements

### Ingress Controller

**Required:**
- Nginx Ingress Controller (Recommended) or Traefik
- MetalLB or cloud load balancer for external access
- Wildcard DNS or individual A records

**DNS Records:**
- `lyra.yourdomain.com` → Lyra frontend
- `api.lyra.yourdomain.com` → Lyra backend API (optional, can use same domain)

### SSL/TLS Certificates

**Options:**
1. **Let's Encrypt** (Recommended for production)
   - cert-manager installed in cluster
   - HTTP-01 or DNS-01 challenge configured

2. **Manual Certificates**
   - Valid SSL certificate and private key
   - Stored as Kubernetes Secret

3. **Self-Signed** (Development only)
   - Generated during deployment
   - Browser warnings expected

### Firewall & Network Policies

**Required Ports:**
- `443` (HTTPS) - Frontend and API access
- `80` (HTTP) - Redirect to HTTPS

**Kubernetes Internal:**
- `5432` - PostgreSQL
- `6379` - Redis
- `8000` - Backend API (internal)
- `3000` - Frontend dev server (development only)

## Software Dependencies

### Required Tools

**On Deployment Machine:**
```bash
# Docker for building images
docker --version  # 20.10+

# kubectl for Kubernetes management
kubectl version --client  # 1.24+

# Helm for chart management
helm version  # 3.10+

# Git for version control
git --version  # 2.30+
```

### Optional Tools

**Recommended:**
```bash
# Rancher CLI (if using Rancher)
rancher --version

# Harbor CLI (for registry management)
harbor version

# k9s (for cluster monitoring)
k9s version
```

## Database Requirements

### PostgreSQL

**Version:** 13+ (Recommended: 15+)

**Options:**
1. **Managed Database** (Recommended for production)
   - Cloud provider managed PostgreSQL
   - Automatic backups and high availability
   - Example: AWS RDS, Azure Database for PostgreSQL, Google Cloud SQL

2. **In-Cluster PostgreSQL**
   - Deployed via Helm chart
   - Persistent volume for data
   - Regular backup strategy required

**Database Configuration:**
```yaml
host: postgresql.lyra.svc.cluster.local
port: 5432
database: lyra
username: lyra_user
password: [secure password]
```

**Required Extensions:**
- `uuid-ossp` - For UUID generation
- `pg_trgm` - For text search (optional)

### Redis

**Version:** 6+ (Recommended: 7+)

**Options:**
1. **Managed Redis** (Recommended for production)
   - Cloud provider managed Redis
   - Automatic failover with Redis Sentinel

2. **In-Cluster Redis**
   - Deployed via Helm chart
   - Redis Sentinel for high availability
   - Persistent volume for AOF/RDB backups

**Redis Configuration:**
```yaml
host: redis-master.lyra.svc.cluster.local
port: 6379
password: [secure password]
sentinel:
  enabled: true
  master: mymaster
```

## Access & Permissions

### Kubernetes RBAC

**Service Account Requirements:**
- Namespace admin permissions for Lyra namespace
- Permissions to create/delete namespaces (for tenant provisioning)
- StorageClass list/read permissions
- PVC/PV create/delete permissions

**Example ClusterRole:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind:ClusterRole
metadata:
  name: lyra-provisioner
rules:
- apiGroups: [""]
  resources: ["namespaces", "persistentvolumeclaims", "persistentvolumes"]
  verbs: ["create", "delete", "get", "list", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list"]
```

### Harbor Registry Access

**Required:**
1. **Robot Account** with push/pull permissions
2. **Kubernetes Secret** for image pulling:

```bash
kubectl create secret docker-registry harbor-registry-secret \
  --docker-server=registry.lyra.ovh \
  --docker-username=robot$lyra-deployer \
  --docker-password=<robot-token> \
  --namespace=lyra
```

## Pre-Installation Checklist

Before proceeding to deployment, verify:

- [ ] Kubernetes cluster is running and accessible
- [ ] kubectl context is set to correct cluster
- [ ] Storage classes are available (`kubectl get sc`)
- [ ] Ingress controller is installed
- [ ] MetalLB or LoadBalancer is configured
- [ ] Harbor registry is accessible
- [ ] Harbor robot account created
- [ ] DNS records are configured
- [ ] SSL certificates are ready (or cert-manager is configured)
- [ ] PostgreSQL database is provisioned
- [ ] Redis instance is provisioned
- [ ] Docker is installed on build machine
- [ ] Git repository access configured

## Environment-Specific Notes

### Development Environment

For development/testing:
- Single-node Kubernetes (k3s, minikube, kind) acceptable
- Local storage or hostPath volumes OK
- Self-signed certificates OK
- In-cluster PostgreSQL and Redis sufficient

### Staging Environment

For staging/QA:
- Multi-node Kubernetes cluster recommended
- Persistent storage with backups
- Valid SSL certificates
- Separate database instances
- Resource quotas enabled

### Production Environment

For production deployments:
- High-availability Kubernetes cluster (3+ master nodes)
- Dedicated storage cluster (Ceph recommended)
- Valid SSL certificates with auto-renewal
- Managed database services (RDS, Cloud SQL, etc.)
- Managed Redis with Sentinel
- Monitoring and alerting (Prometheus, Grafana)
- Regular backup strategy
- Disaster recovery plan

---

## Next Steps

Once you've met all prerequisites, proceed to:

**→ [Initial Deployment](initial-deployment.md)**

Need help? Check our [troubleshooting guide](../troubleshooting/index.md) or [open an issue](https://github.com/amreinch/lyra/issues).
