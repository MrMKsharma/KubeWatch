# Maintenance Procedures

## Table of Contents
1. [Regular Maintenance Tasks](#regular-maintenance-tasks)
2. [Upgrading Components](#upgrading-components)
3. [Scaling Operations](#scaling-operations)
4. [Cleanup Tasks](#cleanup-tasks)
5. [Backup Procedures](#backup-procedures)

---

## Regular Maintenance Tasks

### Weekly Tasks
1. **Check cluster health**
   ```powershell
   kubectl get nodes
   kubectl get pods -A
   ```

2. **Check resource usage**
   ```powershell
   kubectl top nodes
   kubectl top pods -A
   ```

3. **Review alerts**
   - Check Grafana Alerting
   - Check Alertmanager

### Monthly Tasks
1. **Review logs**
   - Check for error patterns
   - Check for security events

2. **Review backups**
   - Verify backup integrity
   - Test restore procedure

3. **Update documentation**
   - Update runbooks
   - Update troubleshooting guide

---

## Upgrading Components

### Upgrading Helm Releases

1. **Update Helm repositories**
   ```powershell
   helm repo update
   ```

2. **Check for updates**
   ```powershell
   helm search repo <chart-name> --versions
   ```

3. **Upgrade a release**
   ```powershell
   helm upgrade <release-name> <repo>/<chart-name> -n <namespace> -f <values-file>
   ```

### Example: Upgrading Prometheus
```powershell
helm repo update
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring -f .\infra\helm\kube-prometheus-stack-values.yaml
```

### Example: Upgrading Loki
```powershell
helm repo update
helm upgrade loki grafana/loki-stack -n logging -f .\infra\helm\loki-stack-values.yaml
```

---

## Scaling Operations

### Manual Scaling
```powershell
# Scale a deployment
kubectl scale deployment <deployment-name> -n <namespace> --replicas=<number>

# Example: Scale backend API to 3 replicas
kubectl scale deployment backend-api -n backend --replicas=3
```

### Horizontal Pod Autoscaler (HPA)
HPA is already configured for backend and frontend. To view or adjust:

```powershell
# View HPA
kubectl get hpa -A

# Edit HPA
kubectl edit hpa <hpa-name> -n <namespace>
```

---

## Cleanup Tasks

### Cleaning Up Completed Pods
```powershell
# Delete succeeded pods
kubectl delete pods --field-selector=status.phase=Succeeded -A

# Delete failed pods
kubectl delete pods --field-selector=status.phase=Failed -A
```

### Cleaning Up Completed Jobs
```powershell
# Delete successful jobs
kubectl delete jobs --field-selector=status.successful=1 -A

# Delete failed jobs
kubectl delete jobs --field-selector=status.failed=1 -A
```

### Cleaning Up Old Backups
```powershell
# List backups
velero backup get

# Delete old backups
velero backup delete <backup-name>
```

---

## Backup Procedures

### Scheduled Backups
Backups are scheduled via Velero. To check:
```powershell
velero schedule get
```

### Manual Backups
```powershell
# Create a backup
velero backup create kubewatch-backup --include-namespaces=monitoring,logging,tracing,backend,frontend

# Verify backup
velero backup describe kubewatch-backup
velero backup logs kubewatch-backup
```

### Restoring from Backup
```powershell
# List backups
velero backup get

# Restore
velero restore create --from-backup kubewatch-backup

# Verify restore
velero restore get
kubectl get pods -A
```

---

## Security Maintenance

### Rotating Secrets
```powershell
# Delete secret (will be recreated if using Helm)
kubectl delete secret <secret-name> -n <namespace>

# Or recreate manually
kubectl create secret generic <secret-name> -n <namespace> --from-literal=key=value
```

### Reviewing RBAC
```powershell
# List cluster roles
kubectl get clusterroles

# List role bindings
kubectl get clusterrolebindings

# Review network policies
kubectl get networkpolicy -A
```
