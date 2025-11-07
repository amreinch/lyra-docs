# Initial Deployment

This guide walks you through deploying Lyra Platform for the first time using Rancher and Harbor.

## Overview

Lyra deployment follows these steps:

1. Configure Helm chart values
2. Deploy via Rancher UI
3. Verify deployment
4. Create initial superuser

**Prerequisites:**
- ✅ Kubernetes cluster configured ([Kubernetes Setup](kubernetes-setup.md))
- ✅ Infrastructure deployed ([Infrastructure Deployment](infrastructure-deployment.md))
- ✅ Lyra Helm charts available in Harbor registry
- ✅ `kubectl` access to your cluster

**Estimated Time:** 15-30 minutes

---

## Step 1: Configure Helm Values

The Lyra Helm chart can be configured through Rancher UI forms or via a `values.yaml` file.

### Option A: Configure via Rancher UI (Recommended)

1. Open Rancher UI
2. Navigate to **Apps & Marketplace**
3. Click **Repositories** → Add your Harbor Helm repository if not already added
4. Click **Charts** → Find `lyra-app`
5. Click **Install**
6. Fill in the configuration form

**Key Configuration Sections:**

#### Image Configuration
```yaml
backend:
  image:
    repository: registry.lyra.ovh/lyra/lyra-backend
    tag: "1.0.0"
    pullPolicy: IfNotPresent

frontend:
  image:
    repository: registry.lyra.ovh/lyra/lyra-frontend
    tag: "1.0.0"
    pullPolicy: IfNotPresent

scheduler:
  image:
    repository: registry.lyra.ovh/lyra/lyra-scheduler
    tag: "1.0.0"
    pullPolicy: IfNotPresent

# Harbor registry secret created in Kubernetes Setup at project level
# Images will be pulled using harbor-registry-secret automatically
```

#### Database Configuration
```yaml
database:
  # Connection to PostgreSQL cluster deployed in Infrastructure Deployment
  host: "lyra-postgres-rw.databases.svc.cluster.local"
  port: 5432
  name: "lyra_db"
  # Credentials retrieved from postgres-cluster secret automatically
```

#### Redis Configuration
```yaml
redis:
  # Connection to Redis HA deployed in Infrastructure Deployment
  sentinel:
    enabled: true
    service: "redis-redis-ha.databases.svc.cluster.local"
    port: 26379
    masterName: "redis-master"
  # Connection to Redis Ephemeral for sessions
  ephemeral:
    host: "redis-ephemeral.databases.svc.cluster.local"
    port: 6379
```

#### Ingress Configuration
```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: lyra.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: lyra-tls
      hosts:
        - lyra.yourdomain.com
```

### Option B: Configure via values.yaml File

Create `custom-values.yaml`:

```yaml
# Image configuration
backend:
  image:
    repository: registry.lyra.ovh/lyra/lyra-backend
    tag: "1.0.0"
  replicas: 2
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "2000m"
      memory: "2Gi"

frontend:
  image:
    repository: registry.lyra.ovh/lyra/lyra-frontend
    tag: "1.0.0"
  replicas: 2
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"

scheduler:
  image:
    repository: registry.lyra.ovh/lyra/lyra-scheduler
    tag: "1.0.0"
  replicas: 1
  resources:
    requests:
      cpu: "250m"
      memory: "256Mi"
    limits:
      cpu: "1000m"
      memory: "1Gi"

# Database connection (from Infrastructure Deployment)
database:
  host: "lyra-postgres-rw.databases.svc.cluster.local"
  port: 5432
  name: "lyra_db"

# Redis connection (from Infrastructure Deployment)
redis:
  sentinel:
    enabled: true
    service: "redis-redis-ha.databases.svc.cluster.local"
    port: 26379
    masterName: "redis-master"
  ephemeral:
    host: "redis-ephemeral.databases.svc.cluster.local"
    port: 6379

# Ingress
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: lyra.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: lyra-tls
      hosts:
        - lyra.yourdomain.com

# Application configuration
config:
  jwtSecretKey: "<generate-secure-random-key>"
  jwtAlgorithm: "HS256"
  accessTokenExpireMinutes: 30
  refreshTokenExpireDays: 60
```

---

## Step 2: Deploy via Rancher

### Using Rancher UI

1. **Navigate to Apps & Marketplace**
   - Select your cluster
   - Click **Apps & Marketplace** in left sidebar

2. **Find Lyra Chart**
   - Click **Charts** tab
   - Search for `lyra-app`
   - Click on the chart

3. **Configure Installation**
   - **Name:** `lyra`
   - **Namespace:** `lyra` (create if doesn't exist)
   - **Chart Version:** Select latest version

4. **Configure Values**
   - Use UI forms to configure (see Step 3 above)
   - Or switch to **YAML** tab and paste your `custom-values.yaml`

5. **Install**
   - Review configuration
   - Click **Install**
   - Wait for deployment to complete

### Using Helm CLI (Alternative)

```bash
# Add Harbor Helm repository
helm repo add lyra-harbor https://registry.lyra.ovh/chartrepo/lyra
helm repo update

# Install Lyra
helm install lyra lyra-harbor/lyra-app \
  --namespace lyra \
  --create-namespace \
  --values custom-values.yaml \
  --version 1.0.0

# Or install from OCI registry
helm install lyra \
  oci://registry.lyra.ovh/lyra/lyra-app \
  --version 1.0.0 \
  --namespace lyra \
  --create-namespace \
  --values custom-values.yaml
```

---

## Step 3: Verify Deployment

### Check Pod Status

```bash
kubectl get pods -n lyra
```

**Expected output:**
```
NAME                              READY   STATUS    RESTARTS   AGE
lyra-backend-7d9f8c4b5d-abc12     1/1     Running   0          2m
lyra-backend-7d9f8c4b5d-def34     1/1     Running   0          2m
lyra-frontend-6c8d7b5a4e-ghi56    1/1     Running   0          2m
lyra-frontend-6c8d7b5a4e-jkl78    1/1     Running   0          2m
lyra-scheduler-5b7c8d9e6f-mno90   1/1     Running   0          2m
```

All pods should be `Running` with `1/1` READY.

### Check Services

```bash
kubectl get svc -n lyra
```

**Expected output:**
```
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
lyra-backend     ClusterIP   10.43.100.50    <none>        8000/TCP   2m
lyra-frontend    ClusterIP   10.43.100.51    <none>        80/TCP     2m
```

### Check Ingress

```bash
kubectl get ingress -n lyra
```

**Expected output:**
```
NAME    CLASS   HOSTS                 ADDRESS          PORTS     AGE
lyra    nginx   lyra.yourdomain.com   192.168.1.100    80, 443   2m
```

### Test Application Access

```bash
# Test HTTP redirect
curl -I http://lyra.yourdomain.com

# Test HTTPS access
curl -k https://lyra.yourdomain.com

# Expected: 200 OK with HTML content
```

### Check Logs

```bash
# Backend logs
kubectl logs -n lyra -l app=lyra-backend --tail=50

# Frontend logs
kubectl logs -n lyra -l app=lyra-frontend --tail=50

# Scheduler logs
kubectl logs -n lyra -l app=lyra-scheduler --tail=50
```

**Look for:**
- No error messages
- Database connection successful
- Redis connection successful
- Application startup messages

---

## Step 4: Initial Superuser Setup

After deployment, you need to create the first superuser account.

### Access Backend Pod

```bash
# Get backend pod name
BACKEND_POD=$(kubectl get pods -n lyra -l app=lyra-backend -o jsonpath='{.items[0].metadata.name}')

# Access pod shell
kubectl exec -it -n lyra $BACKEND_POD -- bash
```

### Create Superuser

**Option A: Using CLI Script (Recommended)**

```bash
# Inside the pod
python -m app.scripts.create_superuser \
  --username admin \
  --email admin@lyra.local \
  --password <secure-password>
```

**Option B: Using Python Interactive**

```python
# Inside the pod
python

from app.db.session import SessionLocal
from app.services.user import create_user
from app.schemas.user import UserCreate

db = SessionLocal()

# Create superuser
user_data = UserCreate(
    username="admin",
    email="admin@lyra.local",
    password="<secure-password>",
    is_superuser=True,
    is_active=True
)

user = create_user(db, user_data)
print(f"Superuser created: {user.username}")

db.close()
```

### Test Login

1. Open `https://lyra.yourdomain.com` in browser
2. Login with superuser credentials:
   - Username: `admin`
   - Password: `<your-password>`
3. Verify you can access the dashboard

---

## Post-Deployment Configuration

### Configure System Settings

1. Login as superuser
2. Navigate to **Settings** → **System**
3. Configure:
   - **System Timezone**: Set your preferred timezone for scheduling
   - **Email Settings**: Configure SMTP for notifications (optional)
   - **Backup Settings**: Configure backup schedules

### Create First Tenant

1. Navigate to **Tenants** → **Create Tenant**
2. Fill in:
   - **Name**: Your organization name
   - **Slug**: URL-friendly identifier (e.g., `acme-corp`)
   - **Description**: Brief description
3. Click **Create**

### Configure Kubernetes Integration

1. Navigate to **Settings** → **Kubernetes**
2. Verify connection to cluster
3. Configure:
   - Default storage classes
   - Resource quotas
   - Network policies

---

## Troubleshooting

### Pods Not Starting

**Check events:**
```bash
kubectl describe pod -n lyra <pod-name>
```

**Common issues:**
- Image pull errors → Check Harbor credentials
- CrashLoopBackOff → Check application logs
- Pending → Check resource availability

### Database Connection Issues

**Verify database connectivity:**
```bash
kubectl exec -it -n lyra $BACKEND_POD -- bash
python -c "from app.db.session import engine; engine.connect()"
```

**Check PostgreSQL status:**
```bash
kubectl get pods -n databases -l app.kubernetes.io/name=lyra-postgres
kubectl get cluster -n databases lyra-postgres
```

### Ingress Not Working

**Check ingress controller:**
```bash
kubectl get pods -n ingress-nginx
```

**Check certificate:**
```bash
kubectl describe certificate lyra-tls -n lyra
```

**Test internal service:**
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://lyra-backend.lyra.svc.cluster.local:8000/api/v1/health
```

---

## Next Steps

✅ **Deployment Complete!**

Now you can:

1. **[Configure Updates](updates.md)** - Set up update procedures
2. **Create Users and Tenants** - Start onboarding your organization
3. **Configure LDAP** (Optional) - Integrate with your directory service
4. **Set up Monitoring** - Configure Prometheus and Grafana

---

Need help? Check our [troubleshooting guide](../troubleshooting/index.md) or [open an issue](https://github.com/amreinch/lyra/issues).
