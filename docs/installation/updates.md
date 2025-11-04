# Updates & Maintenance

This guide covers updating Lyra Platform, maintenance procedures, and troubleshooting common update issues.

## Update Overview

Lyra uses semantic versioning (`MAJOR.MINOR.PATCH`) and supports rolling updates with zero downtime.

### Update Types

| Type | Description | Downtime | Example |
|------|-------------|----------|---------|
| **Patch** | Bug fixes, minor changes | None | 1.0.0 → 1.0.1 |
| **Minor** | New features, backward compatible | None | 1.0.1 → 1.1.0 |
| **Major** | Breaking changes, migrations | Possible | 1.1.0 → 2.0.0 |

### Update Frequency

**Recommended:**
- **Patch updates**: Apply within 1-2 weeks
- **Minor updates**: Apply within 1 month
- **Major updates**: Plan carefully, test thoroughly

---

## Pre-Update Checklist

Before any update, complete these steps:

- [ ] **Backup database**
- [ ] **Backup configuration** (Helm values, secrets)
- [ ] **Review changelog** for breaking changes
- [ ] **Test in staging** environment first
- [ ] **Schedule maintenance window** (for major updates)
- [ ] **Notify users** (if downtime expected)
- [ ] **Have rollback plan** ready

---

## Update Procedure

### Step 1: Check Current Version

```bash
# Check deployed Helm chart version
helm list -n lyra

# Check pod image versions
kubectl get pods -n lyra -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

# Check application version (via API)
curl https://lyra.yourdomain.com/api/v1/version
```

### Step 2: Backup Database

**PostgreSQL Backup:**
```bash
# Create backup
kubectl exec -n lyra postgresql-0 -- pg_dump -U lyra_user lyra > backup-$(date +%Y%m%d).sql

# Or using pg_dumpall for full cluster backup
kubectl exec -n lyra postgresql-0 -- pg_dumpall -U postgres > backup-full-$(date +%Y%m%d).sql

# Upload to object storage
aws s3 cp backup-$(date +%Y%m%d).sql s3://lyra-backups/
```

**Database Backup Best Practices:**
- Automated daily backups
- Retention policy (30 days)
- Off-site storage
- Regular restore testing

### Step 3: Build New Images

Update version numbers and build new container images:

```bash
cd infrastructure/lyra

# Update version in build scripts
# Edit build-and-push-frontend.sh, backend.sh, scheduler.sh
# Change FRONTEND_IMAGE_TAG="1.0.1" (example)

# Build and push frontend
./build-and-push-frontend.sh

# Build and push backend
./build-and-push-backend.sh

# Build and push scheduler
./build-and-push-scheduler.sh
```

**Verify in Harbor:**
```
https://registry.lyra.ovh/harbor/projects/lyra/repositories
- lyra-frontend:1.0.1 ✓
- lyra-backend:1.0.1 ✓
- lyra-scheduler:1.0.1 ✓
```

### Step 4: Update Helm Values

Update your `values.yaml` or Rancher configuration:

```yaml
backend:
  image:
    tag: "1.0.1"  # Update version

frontend:
  image:
    tag: "1.0.1"  # Update version

scheduler:
  image:
    tag: "1.0.1"  # Update version
```

### Step 5: Apply Update

#### Option A: Update via Rancher UI

1. Navigate to **Apps & Marketplace** → **Installed Apps**
2. Find `lyra` application
3. Click **Upgrade**
4. Update image tags to new version
5. Review changes
6. Click **Upgrade**

#### Option B: Update via Helm CLI

```bash
# Update Helm repository
helm repo update

# Upgrade Lyra
helm upgrade lyra lyra-harbor/lyra-app \
  --namespace lyra \
  --values values.yaml \
  --version 1.0.1
```

#### Option C: Update via OCI Registry

```bash
helm upgrade lyra \
  oci://registry.lyra.ovh/lyra/lyra-app \
  --version 1.0.1 \
  --namespace lyra \
  --values values.yaml
```

### Step 6: Monitor Update

**Watch pod rollout:**
```bash
# Watch all pods
kubectl get pods -n lyra -w

# Watch specific deployment
kubectl rollout status deployment/lyra-backend -n lyra
kubectl rollout status deployment/lyra-frontend -n lyra
kubectl rollout status deployment/lyra-scheduler -n lyra
```

**Expected behavior:**
```
lyra-backend-new-abc123    0/1     ContainerCreating   0          5s
lyra-backend-new-abc123    1/1     Running             0          15s
lyra-backend-old-xyz789    1/1     Terminating         0          5m
```

**Check logs during rollout:**
```bash
kubectl logs -f -n lyra -l app=lyra-backend --tail=50
```

### Step 7: Verify Update

**1. Check Pod Status:**
```bash
kubectl get pods -n lyra

# All pods should be Running with new image versions
kubectl describe pod -n lyra lyra-backend-<pod-id> | grep Image:
```

**2. Test Application:**
```bash
# Test API health
curl https://lyra.yourdomain.com/api/v1/health

# Test version endpoint
curl https://lyra.yourdomain.com/api/v1/version
```

**3. Test UI:**
- Login to web interface
- Navigate through main features
- Check for JavaScript errors in browser console
- Verify data loads correctly

**4. Run Smoke Tests:**
```bash
# Test critical functionality
- User login/logout
- Tenant switching
- Create/read/update operations
- Background jobs running
```

---

## Database Migrations

For updates that include database schema changes:

### Automatic Migrations

Lyra backend automatically runs migrations on startup using Alembic.

**Monitor migration logs:**
```bash
kubectl logs -n lyra -l app=lyra-backend --tail=100 | grep alembic
```

**Expected output:**
```
INFO  [alembic.runtime.migration] Running upgrade xxx -> yyy, add new table
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [app.db.init_db] Database migration completed successfully
```

### Manual Migration (if needed)

```bash
# Access backend pod
BACKEND_POD=$(kubectl get pods -n lyra -l app=lyra-backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n lyra $BACKEND_POD -- bash

# Run migrations manually
alembic upgrade head

# Check migration status
alembic current

# View migration history
alembic history
```

### Migration Troubleshooting

**If migration fails:**
```bash
# Check current database revision
alembic current

# View pending migrations
alembic history

# Rollback one migration
alembic downgrade -1

# Or rollback to specific revision
alembic downgrade <revision-id>
```

---

## Rollback Procedures

### Helm Rollback

If update causes issues, rollback to previous version:

```bash
# View rollout history
helm history lyra -n lyra

# Rollback to previous release
helm rollback lyra -n lyra

# Or rollback to specific revision
helm rollback lyra <revision-number> -n lyra
```

### Manual Pod Rollback

```bash
# Rollback deployment to previous version
kubectl rollout undo deployment/lyra-backend -n lyra
kubectl rollout undo deployment/lyra-frontend -n lyra
kubectl rollout undo deployment/lyra-scheduler -n lyra

# Check rollback status
kubectl rollout status deployment/lyra-backend -n lyra
```

### Database Rollback

**Restore from backup:**
```bash
# Download backup
aws s3 cp s3://lyra-backups/backup-20240101.sql .

# Restore database
kubectl exec -i -n lyra postgresql-0 -- psql -U lyra_user lyra < backup-20240101.sql
```

**Rollback Alembic migrations:**
```bash
# Access backend pod
kubectl exec -it -n lyra $BACKEND_POD -- bash

# Rollback to previous migration
alembic downgrade -1

# Or rollback to specific revision
alembic downgrade <revision-id>
```

---

## Update Strategies

### Rolling Update (Default)

**Best for:** Patch and minor updates

**Characteristics:**
- Zero downtime
- Gradual pod replacement
- Automatic rollback if health checks fail

**Configuration:**
```yaml
backend:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

### Blue-Green Deployment

**Best for:** Major updates, high-risk changes

**Process:**
1. Deploy new version alongside old (green environment)
2. Test thoroughly
3. Switch traffic to new version
4. Monitor for issues
5. Decommission old version

**Implementation:**
```bash
# Deploy new version with different name
helm install lyra-v2 lyra-harbor/lyra-app \
  --namespace lyra-v2 \
  --values values-v2.yaml

# Test lyra-v2
# Switch ingress to point to lyra-v2
# Monitor for issues
# Remove old lyra installation if stable
```

### Canary Deployment

**Best for:** Testing updates with subset of users

**Process:**
1. Deploy new version to small percentage of pods
2. Monitor metrics and errors
3. Gradually increase traffic to new version
4. Complete rollout if stable

**Requires:** Istio or similar service mesh

---

## Maintenance Tasks

### Regular Maintenance Schedule

**Daily:**
- Monitor pod health and resource usage
- Check application logs for errors
- Verify backups completed successfully

**Weekly:**
- Review resource usage trends
- Check for available updates
- Clean up old logs and temporary files

**Monthly:**
- Apply security patches
- Review and rotate secrets/credentials
- Test disaster recovery procedures

### Log Management

**View logs:**
```bash
# Application logs
kubectl logs -n lyra -l app=lyra-backend --tail=100

# Stream logs
kubectl logs -n lyra -l app=lyra-backend -f

# Previous pod logs (after crash)
kubectl logs -n lyra <pod-name> --previous
```

**Log rotation:**
```yaml
# Configure in deployment
spec:
  containers:
  - name: backend
    volumeMounts:
    - name: logs
      mountPath: /var/log/lyra
  volumes:
  - name: logs
    emptyDir:
      sizeLimit: 1Gi
```

### Resource Cleanup

**Remove old images from nodes:**
```bash
# Prune unused images
kubectl run --rm -it cleanup --image=alpine/k8s:1.27.1 --restart=Never -- \
  kubectl debug node/<node-name> --image=alpine/k8s:1.27.1 -- \
  docker system prune -af
```

**Clean up completed jobs:**
```bash
kubectl delete job -n lyra --field-selector status.successful=1
```

### Secret Rotation

**Rotate database password:**
```bash
# Update password in database
# Update secret
kubectl create secret generic lyra-db-secret \
  --from-literal=password='<new-password>' \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart pods to pick up new secret
kubectl rollout restart deployment/lyra-backend -n lyra
```

---

## Monitoring Updates

### Health Checks

**Application health:**
```bash
# Health endpoint
curl https://lyra.yourdomain.com/api/v1/health

# Readiness check
kubectl get pods -n lyra -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

### Resource Usage

**Check resource consumption:**
```bash
# Pod resource usage
kubectl top pods -n lyra

# Node resource usage
kubectl top nodes
```

### Performance Metrics

**Monitor via Prometheus/Grafana:**
- Request latency
- Error rates
- Database query performance
- Redis cache hit rate
- Pod CPU/memory usage

---

## Troubleshooting Common Update Issues

### Image Pull Errors

**Symptom:** `ImagePullBackOff` or `ErrImagePull`

**Solutions:**
```bash
# Verify Harbor credentials
kubectl get secret harbor-registry-secret -n lyra -o yaml

# Test image pull manually
kubectl run test --rm -it --image=registry.lyra.ovh/lyra/lyra-backend:1.0.1 \
  --image-pull-policy=Always --restart=Never -- sh
```

### Pod CrashLoopBackOff

**Symptom:** Pods continuously restarting

**Solutions:**
```bash
# Check logs
kubectl logs -n lyra <pod-name> --previous

# Check events
kubectl describe pod -n lyra <pod-name>

# Common causes:
# - Database migration failure
# - Configuration error
# - Resource limits too low
```

### Database Connection Issues

**Symptom:** "could not connect to database" errors

**Solutions:**
```bash
# Test database connectivity
kubectl run -it --rm psql --image=postgres:15 --restart=Never -- \
  psql -h postgresql.lyra.svc.cluster.local -U lyra_user -d lyra

# Check database pod
kubectl get pods -n lyra | grep postgres

# Check database logs
kubectl logs -n lyra postgresql-0
```

### Failed Migration

**Symptom:** Migration errors in backend logs

**Solutions:**
```bash
# Check migration status
kubectl exec -it -n lyra $BACKEND_POD -- alembic current

# View migration error details
kubectl logs -n lyra -l app=lyra-backend | grep -A 20 "migration failed"

# Manual migration
kubectl exec -it -n lyra $BACKEND_POD -- alembic upgrade head

# If migration corrupted, restore from backup and retry
```

---

## Update Communication

### Pre-Update Notification

**Email template:**
```
Subject: Scheduled Lyra Platform Maintenance - [Date]

Dear Users,

We will be performing a scheduled update of Lyra Platform:

Date: [Date]
Time: [Start Time] - [End Time] [Timezone]
Expected Duration: [Duration]
Expected Downtime: None / Minimal / [Duration]

Updates include:
- [Feature/Fix 1]
- [Feature/Fix 2]
- [Security patches]

Actions required: None / [Specific actions]

We apologize for any inconvenience.

Best regards,
Lyra Platform Team
```

### Post-Update Communication

**Email template:**
```
Subject: Lyra Platform Update Completed Successfully

Dear Users,

The scheduled Lyra Platform update has been completed successfully.

New version: 1.0.1
Update duration: [Actual duration]

New features:
- [Feature 1]
- [Feature 2]

Please report any issues to: support@lyra.com

Thank you for your patience.

Best regards,
Lyra Platform Team
```

---

## Next Steps

✅ **Updates Configured!**

- **[Prerequisites](prerequisites.md)** - Review infrastructure requirements
- **[Initial Deployment](initial-deployment.md)** - Deploy Lyra from scratch
- **[GitHub Releases](https://github.com/amreinch/lyra/releases)** - Check for new versions

---

Need help? Check our [troubleshooting guide](../troubleshooting/index.md) or [open an issue](https://github.com/amreinch/lyra/issues).
