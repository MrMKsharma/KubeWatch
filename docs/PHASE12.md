# Phase 12: Production Readiness & Documentation - Complete Guide

## 📋 Table of Contents
1. [Production Readiness](#production-readiness)
2. [SLO/SLI Definitions](#slosli-definitions)
3. [Operational Runbooks](#operational-runbooks)
4. [Troubleshooting Guide](#troubleshooting-guide)
5. [Maintenance Procedures](#maintenance-procedures)

---

## Production Readiness

### Checklist
- [ ] All pods have resource requests and limits
- [ ] All critical services have HPA configured
- [ ] All critical services have PDB configured
- [ ] Network policies are enforced
- [ ] RBAC is properly configured
- [ ] Backup and restore tested
- [ ] Alerting configured and tested
- [ ] Logs are aggregated and searchable
- [ ] Metrics are collected and visualized
- [ ] Tracing is working end-to-end
- [ ] Documentation is complete
- [ ] Runbooks are available

### Validation
```powershell
# Check resource requests/limits
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.containers[*].resources}{"\n"}{end}'

# Check HPA
kubectl get hpa -A

# Check PDB
kubectl get pdb -A

# Check network policies
kubectl get networkpolicy -A
```

---

## SLO/SLI Definitions

### Service Level Objectives (SLOs)
1. **API Availability**: 99.9% over 30 days
2. **API Latency**: < 500ms p95 over 30 days
3. **Cluster Uptime**: 99.5% over 30 days

### Service Level Indicators (SLIs)
1. **API Availability**: (Successful requests / Total requests) * 100
2. **API Latency**: 95th percentile of request duration
3. **Cluster Uptime**: (Time cluster is available / Total time) * 100

---

## Operational Runbooks

### Runbook 1: Pod Failure
1. Identify failed pod: `kubectl get pods -A | grep -v Running`
2. Check pod logs: `kubectl logs <pod-name> -n <namespace>`
3. Check pod events: `kubectl describe pod <pod-name> -n <namespace>`
4. Delete pod to allow rescheduling: `kubectl delete pod <pod-name> -n <namespace>`

### Runbook 2: Node Failure
1. Check node status: `kubectl get nodes`
2. Drain node: `kubectl drain <node-name> --ignore-daemonsets`
3. Delete node (if needed): `kubectl delete node <node-name>`
4. Add new node (Kind): `kind create cluster --name kubewatch`

### Runbook 3: Backup and Restore
1. Create backup: See Phase 11
2. Restore from backup: See Phase 11

---

## Troubleshooting Guide

### Common Issues

#### Issue: Pods not starting
```powershell
# Check pod status
kubectl get pods -A

# Check events
kubectl get events -A --sort-by='.lastTimestamp'
```

#### Issue: Can't access services
```powershell
# Check ingress
kubectl get ingress -A

# Check service
kubectl get svc -A

# Check endpoints
kubectl get endpoints -A
```

#### Issue: Metrics not showing up
```powershell
# Check Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Check targets in Prometheus UI
```

---

## Maintenance Procedures

### Upgrading Components
```powershell
# Upgrade Helm releases
helm repo update
helm upgrade <release-name> <chart-name> -n <namespace>

# Example: Upgrade Prometheus
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

### Scaling the Cluster
```powershell
# Scale deployments
kubectl scale deployment <deployment-name> -n <namespace> --replicas=<n>

# Scale with HPA (already configured)
kubectl get hpa -A
```

### Cleaning Up
```powershell
# Clean up old pods
kubectl delete pods --field-selector=status.phase=Succeeded -A

# Clean up old jobs
kubectl delete jobs --field-selector=status.successful=1 -A
```
