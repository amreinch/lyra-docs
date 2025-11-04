# Prerequisites

Before installing Lyra Platform, ensure your environment meets all the necessary requirements.

## System Requirements

### Minimum Hardware Requirements

| Component | Specification |
|-----------|---------------|
| **Worker Nodes** | 3 nodes minimum |
| **CPU per Node** | 8 cores (x86_64) |
| **Memory per Node** | 16 GB RAM |
| **Storage per Node** | 100 GB SSD |
| **Network** | 1 Gbps connectivity |

### Recommended Hardware Requirements

| Component | Specification |
|-----------|---------------|
| **Worker Nodes** | 5+ nodes |
| **CPU per Node** | 16+ cores (x86_64) |
| **Memory per Node** | 32 GB RAM |
| **Storage per Node** | 500 GB SSD |
| **Network** | 10 Gbps connectivity |

!!! warning "Production Deployments"
    For production environments, we strongly recommend following the recommended specifications to ensure optimal performance, reliability, and scalability.

## Software Requirements

### Kubernetes

- **Version**: 1.24 or higher (recommended: 1.27+)
- **Distribution**: Any CNCF-certified Kubernetes distribution
  - Vanilla Kubernetes (kubeadm)
  - RKE2
  - K3s (for development/testing)
  - EKS, GKE, AKS (cloud providers)

### Client Tools

Required tools on your management machine:

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| **kubectl** | 1.24+ | Kubernetes CLI |
| **helm** | 3.0+ | Package manager |
| **docker** | 20.10+ | Container runtime |
| **git** | 2.0+ | Version control |

Optional but recommended:

| Tool | Purpose |
|------|---------|
| **k9s** | Kubernetes TUI |
| **kubectx/kubens** | Context switching |
| **jq** | JSON processing |

## Network Requirements

### Port Requirements

#### Control Plane

| Port | Protocol | Purpose |
|------|----------|---------|
| 6443 | TCP | Kubernetes API server |
| 2379-2380 | TCP | etcd server client API |
| 10250 | TCP | Kubelet API |
| 10259 | TCP | kube-scheduler |
| 10257 | TCP | kube-controller-manager |

#### Worker Nodes

| Port | Protocol | Purpose |
|------|----------|---------|
| 10250 | TCP | Kubelet API |
| 30000-32767 | TCP | NodePort Services |

#### Lyra Application

| Port | Protocol | Purpose |
|------|----------|---------|
| 80 | TCP | HTTP (redirects to HTTPS) |
| 443 | TCP | HTTPS |
| 5432 | TCP | PostgreSQL |
| 6379 | TCP | Redis |
| 389/636 | TCP | LDAP/LDAPS (optional) |

### DNS Requirements

Required DNS records:

```
# Production example
lyra.yourdomain.com          A/CNAME    → Load Balancer IP
api.lyra.yourdomain.com      A/CNAME    → Load Balancer IP
*.lyra.yourdomain.com        A/CNAME    → Load Balancer IP (wildcard)

# Optional
harbor.yourdomain.com        A/CNAME    → Harbor Registry
rancher.yourdomain.com       A/CNAME    → Rancher UI
docs.yourdomain.com          A/CNAME    → Documentation
```

### Firewall Rules

Ensure the following traffic is allowed:

- ✅ Inter-node communication (all ports between cluster nodes)
- ✅ Inbound HTTPS (443) from users
- ✅ Outbound internet access (for pulling images)
- ✅ LDAP connectivity (if using LDAP integration)

## Storage Requirements

### Persistent Storage

Lyra requires persistent storage for:

- **PostgreSQL Database**: 50 GB minimum (100 GB recommended)
- **Redis Data**: 10 GB minimum
- **Tenant Storage**: Variable (plan according to tenant needs)
- **AI Systems Storage**: 100 GB+ per tenant (for models)

### Supported Storage Classes

- ✅ **Rook-Ceph** (recommended)
- ✅ **NFS**
- ✅ **Local Path Provisioner** (development only)
- ✅ **Cloud Provider Storage** (EBS, Persistent Disk, etc.)

!!! tip "Storage Recommendation"
    We recommend **Rook-Ceph** for production deployments as it provides:
    - High availability
    - Dynamic provisioning
    - Block and filesystem storage
    - Good performance

## SSL/TLS Certificates

### Certificate Requirements

You will need SSL/TLS certificates for:

- Main application domain (e.g., `lyra.yourdomain.com`)
- API endpoint (e.g., `api.lyra.yourdomain.com`)
- Wildcard certificate (optional but recommended)

### Certificate Options

=== "Let's Encrypt (Recommended)"

    **Free, automated, trusted**

    - Use cert-manager in Kubernetes
    - Automatic renewal
    - ACME protocol support

    ```yaml
    # Install cert-manager
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    ```

=== "Commercial Certificate"

    **Purchased from CA**

    - Extended validation options
    - Insurance/warranty
    - Support from CA

=== "Self-Signed (Development Only)"

    **For testing only**

    - Not trusted by browsers
    - Certificate warnings
    - Not for production

## Database Requirements

### PostgreSQL

- **Version**: 12+ (recommended: 14+)
- **Configuration**:
  - `max_connections`: 200+
  - `shared_buffers`: 25% of RAM
  - `effective_cache_size`: 50% of RAM
  - `work_mem`: 5-10 MB per connection
  - `maintenance_work_mem`: 256 MB+

### Deployment Options

=== "Kubernetes Deployment"

    **Recommended for testing**

    ```bash
    helm install postgresql bitnami/postgresql
    ```

=== "External Database"

    **Recommended for production**

    - Managed service (RDS, Cloud SQL, etc.)
    - Dedicated VM with backups
    - High availability setup

## Redis Requirements

### Redis Configuration

- **Version**: 6.0+ (recommended: 7.0+)
- **Deployment**: Standalone or Sentinel
- **Memory**: 2 GB minimum (adjust based on usage)

### Deployment Options

=== "Kubernetes Deployment"

    ```bash
    helm install redis bitnami/redis
    ```

=== "External Redis"

    - Managed service (ElastiCache, etc.)
    - Dedicated VM
    - Sentinel cluster for HA

## LDAP Server (Optional)

If integrating with LDAP:

### Requirements

- **Protocol**: LDAP or LDAPS (SSL/TLS)
- **Version**: Any standard LDAP server
  - Active Directory
  - OpenLDAP
  - FreeIPA
  - 389 Directory Server

### Connection Information Needed

- LDAP server hostname/IP
- Port (389 for LDAP, 636 for LDAPS)
- Bind DN and password
- Base DN for users and groups
- Search filters (if custom schema)

## Access Requirements

### Cluster Access

You need:

- ✅ `kubectl` access with cluster-admin privileges
- ✅ Kubeconfig file configured
- ✅ Ability to create namespaces
- ✅ Ability to create cluster-wide resources (CRDs, ClusterRoles)

### Registry Access

You need access to:

- ✅ Docker Hub (or alternative public registry)
- ✅ Harbor registry (if using private registry)
- ✅ Image pull secrets configured

## Pre-Installation Checklist

Use this checklist to ensure you're ready to proceed:

### Infrastructure

- [ ] Kubernetes cluster running (1.24+)
- [ ] Required number of nodes (3+ workers)
- [ ] Sufficient CPU/RAM per node
- [ ] Storage solution available
- [ ] Network connectivity verified
- [ ] DNS configured
- [ ] Firewall rules configured

### Tools

- [ ] kubectl installed and configured
- [ ] Helm 3+ installed
- [ ] Docker installed (for building images)
- [ ] Git installed

### Resources

- [ ] SSL/TLS certificates obtained
- [ ] PostgreSQL database available
- [ ] Redis instance available
- [ ] LDAP server accessible (if using)

### Access

- [ ] Cluster admin access confirmed
- [ ] Registry access configured
- [ ] SSH access to nodes (if needed)

### Planning

- [ ] Domain names decided
- [ ] Storage capacity planned
- [ ] Backup strategy defined
- [ ] Monitoring solution identified

## Validation Commands

Run these commands to validate your environment:

```bash
# Check Kubernetes version
kubectl version --short

# Check nodes
kubectl get nodes

# Check available storage classes
kubectl get storageclass

# Verify cluster has enough resources
kubectl top nodes

# Check DNS resolution
nslookup lyra.yourdomain.com

# Verify helm
helm version

# Test Docker
docker --version
```

## Next Steps

Once all prerequisites are met, proceed to:

1. [Kubernetes Setup](kubernetes.md) - Configure your Kubernetes cluster
2. [Storage Setup](storage.md) - Deploy Ceph storage
3. [Networking Setup](networking.md) - Configure MetalLB

## Getting Help

If you're missing prerequisites or need assistance:

- Review the [troubleshooting guide](../troubleshooting/index.md)
- Check the [FAQ](../troubleshooting/faq.md)
- Contact Lyra support

!!! note "Ready to Proceed?"
    If all prerequisites are met, you're ready to move on to [Kubernetes Setup](kubernetes.md)!
