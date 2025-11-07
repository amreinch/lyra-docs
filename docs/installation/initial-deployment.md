# Initial Deployment

This guide walks you through deploying Lyra Platform for the first time using Rancher and Harbor.

## Overview

Lyra deployment follows these steps:

1. Deploy via Rancher UI
2. Verify deployment
3. Create initial superuser

**Prerequisites:**
- ✅ Kubernetes cluster configured ([Kubernetes Setup](kubernetes-setup.md))
- ✅ Infrastructure deployed ([Infrastructure Deployment](infrastructure-deployment.md))
- ✅ Lyra Helm charts available in Harbor registry
- ✅ `kubectl` access to your cluster

**Estimated Time:** 10-15 minutes

---

## Step 1: Deploy via Rancher UI

The Lyra Helm chart comes with predefined values that automatically connect to the infrastructure components deployed in the previous step.

### Installation Steps

1. **Navigate to Apps & Marketplace**
   - Open Rancher UI
   - Select your Kubernetes cluster
   - Click **Apps & Marketplace** in the left sidebar

2. **Find Lyra Application Chart**
   - Click **Charts** tab
   - Search for `lyra-app` in the Harbor catalog
   - Click on the **lyra-app** chart

3. **Configure Installation**
   - **Name:** `lyra` (fixed release name)
   - **Namespace:** `lyra` (will be created automatically)
   - **Project:** Select **Lyra Platform** (created in Kubernetes Setup)
   - **Chart Version:** Select latest version (e.g., `1.0.0`)

4. **Review Predefined Configuration**

   The chart includes predefined values that automatically configure:

   - **Images**: Points to Harbor registry (`registry.lyra.ovh/lyra/`)
     - Backend, Frontend, Scheduler images with correct tags
     - Automatic image pull using project-level Harbor secret

   - **Database**: Connects to PostgreSQL cluster from Infrastructure Deployment
     - Host: `lyra-postgres-rw.databases.svc.cluster.local`
     - Credentials retrieved automatically from PostgreSQL secret

   - **Redis**: Connects to Redis HA and Ephemeral instances
     - Redis HA with Sentinel for persistent data
     - Redis Ephemeral for session storage

   - **Storage**: Uses Ceph/Rook storage classes
     - Persistent volumes for uploads and data

   - **Ingress**: Pre-configured for external access
     - MetalLB load balancer integration
     - TLS certificate management

5. **Optional: Customize Values (Only if Needed)**

   If you need to customize any values (e.g., ingress hostname):
   - In Rancher UI, look for configuration forms
   - Common customizations:
     - **Ingress Hostname**: Your domain name (e.g., `lyra.yourdomain.com`)
     - **Replica Counts**: Adjust for your environment (defaults: backend=2, frontend=2, scheduler=1)
     - **Resource Limits**: Adjust CPU/memory if needed

   **Note**: All infrastructure connections (database, Redis, storage) are pre-configured correctly. Do NOT modify these unless you have a specific reason.

6. **Install Application**
   - Review the configuration summary
   - Click **Install**
   - Wait for deployment to complete (typically 2-5 minutes)

### Monitor Deployment Progress

You can monitor the deployment in Rancher:

1. Go to **Workloads** → **Deployments**
2. Filter by namespace `lyra`
3. Watch for all deployments to show "Active" status:
   - `lyra-backend`
   - `lyra-frontend`
   - `lyra-scheduler`

---

## Step 2: Verify Deployment

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

## Step 3: Initial Superuser Setup

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
