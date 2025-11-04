# Lyra Platform Documentation

Welcome to the comprehensive documentation for **Lyra Platform** - a modern, multi-tenant application platform with integrated AI capabilities.

## What is Lyra?

Lyra is a Kubernetes-native platform that provides:

- **Multi-Tenant Architecture**: Isolated tenant environments with dedicated Kubernetes namespaces
- **User Management**: Comprehensive user, group, and role management with LDAP integration
- **AI Systems**: Deploy and manage AI models (Ollama, vLLM) with auto-scaling capabilities
- **Enterprise Authentication**: JWT-based authentication with Redis caching and LDAP support
- **Resource Management**: Kubernetes integration for compute, storage, and networking resources

## Quick Links

<div class="grid cards" markdown>

-   :material-download:{ .lg .middle } __Installation Guide__

    ---

    Step-by-step instructions to deploy Lyra on your Kubernetes cluster

    [:octicons-arrow-right-24: Get started](installation/index.md)

-   :material-account-cog:{ .lg .middle } __Administration__

    ---

    Learn how to manage users, tenants, and system configuration

    [:octicons-arrow-right-24: Admin guide](admin/index.md)

-   :material-book-open:{ .lg .middle } __User Guide__

    ---

    Documentation for end users working with Lyra platform

    [:octicons-arrow-right-24: User docs](user/index.md)

-   :material-api:{ .lg .middle } __API Reference__

    ---

    Complete REST API documentation for developers

    [:octicons-arrow-right-24: API docs](api/index.md)

</div>

## Architecture Overview

Lyra consists of several key components working together to provide a complete multi-tenant platform.

### Component Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Frontend** | React 18 + TypeScript | Modern web interface |
| **Backend** | FastAPI + SQLAlchemy | REST API server |
| **Database** | PostgreSQL | Primary data storage |
| **Cache** | Redis | Session and token management |
| **Scheduler** | APScheduler | Background job processing |
| **Orchestration** | Kubernetes | Container orchestration |
| **Storage** | Ceph (Rook) | Persistent storage |
| **Registry** | Harbor | Container image registry |
| **Management** | Rancher | Kubernetes management UI |

## Key Features

### Multi-Tenancy
- Isolated tenant environments with Kubernetes namespace per tenant
- Per-tenant resource quotas and storage allocation
- Tenant-specific user management and permissions

### Authentication & Authorization
- JWT-based authentication with automatic token refresh
- Multi-provider support (local users + LDAP integration)
- Hierarchical role-based permissions system
- Fine-grained CRUD permissions

### AI Systems Management
- Deploy Ollama or vLLM AI servers per tenant
- Model management with progress tracking
- Resource allocation with auto-scaling (HPA)
- Shared storage with tenant isolation

### LDAP Integration
- Automated user and group synchronization
- Orphan detection and cleanup
- Domain-based identity management
- Group-to-role mapping

## System Requirements

### Minimum Requirements
- **Kubernetes Cluster**: 1.24+
- **Nodes**: 3+ worker nodes
- **CPU**: 8+ cores per node
- **Memory**: 16GB+ per node
- **Storage**: 100GB+ available storage

### Recommended Requirements
- **Kubernetes Cluster**: 1.27+
- **Nodes**: 5+ worker nodes
- **CPU**: 16+ cores per node
- **Memory**: 32GB+ per node
- **Storage**: 500GB+ Ceph cluster

## Getting Started

Ready to deploy Lyra? Follow our comprehensive installation guide:

1. [Prerequisites](installation/prerequisites.md) - Prepare your environment
2. [Kubernetes Setup](installation/kubernetes.md) - Set up your cluster
3. [Storage Setup](installation/storage.md) - Configure Ceph storage
4. [Lyra Deployment](installation/lyra.md) - Deploy the application

## Support

Need help? Check our [troubleshooting guide](troubleshooting/index.md) or reach out to the Lyra team.

## License

[Add your license information here]
