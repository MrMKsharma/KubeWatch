# Troubleshooting Guide

## Table of Contents
1. [General Troubleshooting Steps](#general-troubleshooting-steps)
2. [Common Issues](#common-issues)
3. [Network Issues](#network-issues)
4. [Storage Issues](#storage-issues)
5. [Observability Issues](#observability-issues)

---

## General Troubleshooting Steps

1. **Check pod status**
   ```powershell
   kubectl get pods -A
   ```

2. **Check pod logs**
   ```powershell
   kubectl logs <pod-name> -n <namespace>
   ```

3. **Check pod description**
   ```powershell
   kubectl describe pod <pod-name> -n <namespace>
   ```

4. **Check events**
   ```powershell
   kubectl get events -A --sort-by='.lastTimestamp'
   ```

5. **Check node status**
   ```powershell
   kubectl get nodes
   kubectl describe node <node-name>
   ```

---

## Common Issues

### Issue 1: Pods stuck in Pending
**Symptoms**: Pod remains in Pending state

**Troubleshooting**:
1. Check for resource constraints:
   ```powershell
   kubectl describe pod <pod-name> -n <namespace>
   ```
2. Check node resources:
   ```powershell
   kubectl describe nodes
   ```
3. Check for taints/tolerations:
   ```powershell
   kubectl describe node <node-name> | Select-String "Taints"
   ```

### Issue 2: Pods stuck in CrashLoopBackOff
**Symptoms**: Pod keeps crashing and restarting

**Troubleshooting**:
1. Check pod logs:
   ```powershell
   kubectl logs <pod-name> -n <namespace>
   kubectl logs <pod-name> -n <namespace> --previous
   ```
2. Check pod description for events:
   ```powershell
   kubectl describe pod <pod-name> -n <namespace>
   ```

### Issue 3: ImagePullBackOff
**Symptoms**: Pod can't pull the container image

**Troubleshooting**:
1. Check image name and tag
2. Check image repository access
3. Check image pull secrets:
   ```powershell
   kubectl get secrets -n <namespace>
   ```

---

## Network Issues

### Issue: Can't access service via Ingress
**Symptoms**: Connection refused or timeout

**Troubleshooting**:
1. Check ingress controller:
   ```powershell
   kubectl get pods -n ingress-nginx
   ```
2. Check ingress resource:
   ```powershell
   kubectl get ingress -n <namespace>
   kubectl describe ingress <ingress-name> -n <namespace>
   ```
3. Check service:
   ```powershell
   kubectl get svc -n <namespace>
   kubectl describe svc <service-name> -n <namespace>
   ```
4. Check endpoints:
   ```powershell
   kubectl get endpoints <service-name> -n <namespace>
   ```

### Issue: Network Policies blocking traffic
**Symptoms**: Pods can't communicate

**Troubleshooting**:
1. Check network policies:
   ```powershell
   kubectl get networkpolicy -A
   ```
2. Temporarily remove network policies to test:
   ```powershell
   kubectl delete networkpolicy <policy-name> -n <namespace>
   ```

---

## Storage Issues

### Issue: PVC pending in Kind cluster
**Symptoms**: PVC remains in Pending state, monitoring pods stuck
**Fix**: Create storage directories on the Kind node!
```powershell
docker exec kubewatch-control-plane mkdir -p /mnt/storage /mnt/storage2 /mnt/storage3 /mnt/storage4
```


---

## Observability Issues

### Issue: Metrics not showing up in Grafana
**Symptoms**: Grafana dashboards are empty

**Troubleshooting**:
1. Check Prometheus:
   ```powershell
   kubectl get pods -n monitoring
   ```
2. Port-forward to Prometheus:
   ```powershell
   kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
   ```
3. Check targets in Prometheus UI (http://localhost:9090/targets)
4. Check Prometheus logs:
   ```powershell
   kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0
   ```

### Issue: Logs not showing up in Loki
**Symptoms**: Can't find logs in Grafana

**Troubleshooting**:
1. Check Loki:
   ```powershell
   kubectl get pods -n logging
   ```
2. Check Promtail:
   ```powershell
   kubectl get pods -n logging -l app.kubernetes.io/name=promtail
   ```
3. Check Promtail logs:
   ```powershell
   kubectl logs -n logging -l app.kubernetes.io/name=promtail
   ```

### Issue: Traces not showing up in Tempo
**Symptoms**: Can't find traces in Grafana

**Troubleshooting**:
1. Check Tempo:
   ```powershell
   kubectl get pods -n tracing
   ```
2. Check OpenTelemetry Collector:
   ```powershell
   kubectl get pods -n tracing
   ```
3. Check OTel Collector logs:
   ```powershell
   kubectl logs -n tracing -l app.kubernetes.io/name=opentelemetry-collector
   ```
