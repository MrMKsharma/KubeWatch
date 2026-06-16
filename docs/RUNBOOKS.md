# Operational Runbooks

## Runbook 1: Pod Failure
**Impact**: Service degradation or outage  
**Severity**: Medium-High

### Symptoms
- Pod in CrashLoopBackOff or Error state
- Service unavailable

### Steps
1. **Identify the failed pod**
   ```powershell
   kubectl get pods -A | Select-String -Pattern "CrashLoopBackOff|Error"
   ```

2. **Check pod logs**
   ```powershell
   kubectl logs <pod-name> -n <namespace>
   kubectl logs <pod-name> -n <namespace> --previous
   ```

3. **Check pod events**
   ```powershell
   kubectl describe pod <pod-name> -n <namespace>
   ```

4. **Delete the pod to allow rescheduling**
   ```powershell
   kubectl delete pod <pod-name> -n <namespace>
   ```

5. **Verify recovery**
   ```powershell
   kubectl get pods -n <namespace> -w
   ```

---

## Runbook 2: Node Failure
**Impact**: Multiple pods may be affected  
**Severity**: High

### Symptoms
- Node in NotReady state
- Multiple pods pending or evicted

### Steps
1. **Check node status**
   ```powershell
   kubectl get nodes
   ```

2. **Drain the node**
   ```powershell
   kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
   ```

3. **Delete the node (if needed)**
   ```powershell
   kubectl delete node <node-name>
   ```

4. **Recreate the cluster (Kind-specific)**
   ```powershell
   kind delete cluster --name kubewatch
   .\scripts\setup-phase1.ps1
   ```

---

## Runbook 3: Service Unavailable
**Impact**: Service outage  
**Severity**: High

### Symptoms
- Can't reach service via Ingress
- 5xx errors

### Steps
1. **Check service status**
   ```powershell
   kubectl get svc -n <namespace>
   ```

2. **Check ingress**
   ```powershell
   kubectl get ingress -n <namespace>
   kubectl describe ingress <ingress-name> -n <namespace>
   ```

3. **Check endpoints**
   ```powershell
   kubectl get endpoints <service-name> -n <namespace>
   ```

4. **Check pod status**
   ```powershell
   kubectl get pods -n <namespace>
   ```

---

## Runbook 4: Backup and Restore
**Impact**: Data recovery  
**Severity**: Medium

### Backup Steps
1. **Create a backup**
   ```powershell
   velero backup create kubewatch-backup --include-namespaces=monitoring,logging,tracing,backend,frontend
   ```

2. **Verify backup**
   ```powershell
   velero backup describe kubewatch-backup
   velero backup logs kubewatch-backup
   ```

### Restore Steps
1. **List available backups**
   ```powershell
   velero backup get
   ```

2. **Restore from backup**
   ```powershell
   velero restore create --from-backup kubewatch-backup
   ```

3. **Verify restore**
   ```powershell
   velero restore get
   kubectl get pods -A
   ```

---

## Runbook 5: Scaling Services
**Impact**: Performance improvement  
**Severity**: Low

### Steps
1. **Manual scaling**
   ```powershell
   kubectl scale deployment <deployment-name> -n <namespace> --replicas=3
   ```

2. **Check HPA**
   ```powershell
   kubectl get hpa -n <namespace>
   ```

3. **Adjust HPA (if needed)**
   ```powershell
   kubectl edit hpa <hpa-name> -n <namespace>
   ```
