# Installation & Updates

This section covers everything you need to deploy, configure, and maintain Lyra Platform.

## Installation Overview

Lyra Platform is deployed as a Helm chart to Kubernetes clusters. The deployment process includes:

1. **Prerequisites** - Preparing your environment and infrastructure
2. **Kubernetes Setup** - Creating and configuring your Kubernetes cluster
3. **Infrastructure Deployment** - Deploying storage, databases, and networking
4. **Initial Deployment** - Installing Lyra Platform applications
5. **Updates & Maintenance** - Keeping your Lyra installation up-to-date

## Installation Guides

### [Prerequisites](prerequisites.md)
System requirements, dependencies, and infrastructure preparation.

**Topics covered:**
- Kubernetes cluster requirements
- Storage requirements (Ceph/Rook)
- Container registry setup (Harbor)
- Network and ingress configuration
- SSL/TLS certificates

### [Kubernetes Setup](kubernetes-setup.md)
Create and configure a Kubernetes cluster using Rancher.

**Topics covered:**
- Creating Kubernetes cluster via Rancher
- Configuring cluster nodes (control plane and workers)
- Node role configuration (etcd, control plane, worker)
- Rancher project setup for Lyra
- Harbor registry integration
- Cluster verification

### [Infrastructure Deployment](infrastructure-deployment.md)
Deploy required infrastructure components for Lyra Platform.

**Topics covered:**
- Ceph/Rook storage cluster deployment
- PostgreSQL database cluster (HA with 3 replicas)
- Redis HA and Ephemeral instances
- CSI drivers for external storage (SMB, NFS, S3)
- MetalLB load balancer configuration
- Infrastructure verification

### [Initial Deployment](initial-deployment.md)
Step-by-step guide for deploying Lyra Platform for the first time.

**Topics covered:**
- Deploying Lyra application via Rancher UI
- Using predefined Helm chart values
- Verifying deployment status
- Creating initial superuser account

### [Updates & Maintenance](updates.md)
Managing updates, upgrades, and ongoing maintenance.

**Topics covered:**
- Update strategies and best practices
- Rolling vs. blue-green deployments
- Backup and restore procedures
- Rollback procedures
- Health monitoring

## Quick Start

For experienced users, here's the quick installation workflow:

1. **Complete Prerequisites**
   - Set up Kubernetes cluster via Rancher
   - Deploy infrastructure (Ceph, PostgreSQL, Redis, CSI drivers, MetalLB)

2. **Deploy Lyra via Rancher UI**
   - Navigate to Apps & Marketplace → Charts
   - Search for `lyra-app` in Harbor catalog
   - Click Install with predefined values
   - Wait for deployment to complete

3. **Verify and Configure**
   ```bash
   # Check deployment status
   kubectl get pods -n lyra

   # Create initial superuser
   kubectl exec -it -n lyra <backend-pod> -- python -m app.scripts.create_superuser
   ```

## Deployment Architecture

Lyra uses a modern Kubernetes-native deployment architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                      Ingress / Load Balancer                │
│                    (MetalLB + Nginx Ingress)                │
└────────────────────┬────────────────────────────────────────┘
                     │
     ┌───────────────┴───────────────┐
     │                               │
┌────▼─────┐                   ┌────▼──────┐
│ Frontend │                   │  Backend  │
│  (React) │◄─────────────────►│ (FastAPI) │
└──────────┘                   └─────┬─────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
               ┌────▼─────┐    ┌────▼─────┐    ┌────▼────┐
               │PostgreSQL│    │  Redis   │    │Scheduler│
               └──────────┘    └──────────┘    └─────────┘
                                     │
                              ┌──────▼──────┐
                              │  Kubernetes │
                              │   (Tenant   │
                              │  Namespaces)│
                              └─────────────┘
```

## Container Images

Lyra consists of three main container images stored in Harbor:

| Image | Purpose | Build Script |
|-------|---------|--------------|
| `lyra-frontend` | React web interface | `build-and-push-frontend.sh` |
| `lyra-backend` | FastAPI REST API | `build-and-push-backend.sh` |
| `lyra-scheduler` | Background job processor | `build-and-push-scheduler.sh` |

All images are versioned and stored in your Harbor registry at `registry.lyra.ovh/lyra/`.

## Helm Chart

The Lyra Helm chart (`lyra-app`) is stored in Harbor's Helm repository and includes:

- Kubernetes deployments for all components
- Services and ingress configuration
- ConfigMaps and Secrets management
- Resource quotas and limits
- Health checks and probes
- HPA (Horizontal Pod Autoscaler) configurations

## Support & Troubleshooting

If you encounter issues during installation:

1. Check the [Prerequisites](prerequisites.md) are met
2. Review logs: `kubectl logs -n lyra -l app=lyra-backend`
3. Verify connectivity: `kubectl get pods -n lyra`
4. Visit [GitHub Issues](https://github.com/amreinch/lyra/issues)

---

## Getting Started

Ready to deploy Lyra Platform? Follow this installation workflow:

1. **[Prerequisites](prerequisites.md)** - Prepare your environment
2. **[Kubernetes Setup](kubernetes-setup.md)** - Create your cluster
3. **[Infrastructure Deployment](infrastructure-deployment.md)** - Deploy infrastructure
4. **[Initial Deployment](initial-deployment.md)** - Deploy Lyra applications
5. **[Updates & Maintenance](updates.md)** - Keep your system updated

Begin with the [Prerequisites](prerequisites.md) guide.
