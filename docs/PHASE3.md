# Phase 3: Logging Platform

**Objective**: Install and configure centralized log aggregation (Loki + Promtail).

## Deliverables

✅ **Loki** - Log storage and querying  
✅ **Promtail** - Log collection from pods  
✅ **Grafana Integration** - View logs in dashboards  
✅ **Log Queries** - Common LogQL patterns  
✅ **Ingress Routes** - HTTPS access to Loki  
✅ **PersistentVolume** - Log data persistence  

## Architecture

```
Pods (all namespaces)
  ↓
Promtail (DaemonSet on each node)
  ↓ (collects logs)
Loki (centralized log aggregation)
  ↓ (indexes & stores)
Storage (3Gi PersistentVolume)
  ↓
Grafana (queries & visualizes logs)
  ↓
LogQL queries
```

## Components

### Loki
- **Purpose**: Central log storage & query engine
- **Storage**: 3Gi persistent volume
- **Log retention**: Unlimited (disk space dependent)
- **Port**: 3100

**Configuration**:
```yaml
- Ingester: Chunks logs into blocks
- Chunk size: 256KB
- Retention: 168h (7 days) - configurable
- Compression: Snappy
```

### Promtail
- **Purpose**: Collects logs from pods
- **Deployment**: DaemonSet (one per node)
- **Log sources**:
  - Pod logs (stdout/stderr)
  - Container logs
  - Kubernetes events

**Configuration**:
```yaml
- Job: kubernetes-pods
- Relabeling: Adds pod, namespace, app labels
- Tolerations: Runs on all nodes including taints
```

### Integration with Grafana
- Loki added as data source
- Explore → Logs to search
- Logs can be visualized in dashboards

## Setup Instructions

### Prerequisites

Phases 1 & 2 running:
```bash
kubectl get pods -n monitoring | grep prometheus
# Should show prometheus-kube-prometheus-stack pods
```

### Deploy Phase 3

```powershell
cd C:\Users\sharm\Desktop\Test\KubeWatch
.\scripts\setup-phase3.ps1
```

**What happens**:
1. ✅ Checks Phase 2 running
2. ✅ Adds Grafana Helm repository
3. ✅ Creates 3Gi PVC for Loki
4. ✅ Installs Loki + Promtail
5. ✅ Configures Loki ingress
6. ✅ Adds Loki datasource to Grafana
7. ✅ Waits for all components ready

**Time**: ~5-10 minutes

### Verify Deployment

```bash
# Check Loki
kubectl get statefulset loki -n logging
kubectl get pods -n logging

# Check Promtail collection
kubectl get daemonset loki-promtail -n logging
kubectl logs -n logging -l app=promtail --tail=10

# Check storage
kubectl get pvc -n logging
```

## Accessing Logs

### In Grafana (Recommended)

1. Open Grafana: http://localhost:3000
2. Go to **Explore**
3. Select data source: **Loki**
4. Write LogQL query
5. Click **Run**

### Via Loki API

```bash
# Query logs directly
curl 'http://localhost:3100/loki/api/v1/query_range?query={namespace="monitoring"}&start=<unix_ns>&end=<unix_ns>&limit=1000'
```

## LogQL Query Language

### Basic Syntax

```logql
# Label selector (similar to PromQL)
{job="loki"}
{namespace="monitoring", app="prometheus"}

# Multiple labels
{job="loki", instance="localhost"}
```

### Line Filters

```logql
# Include lines
{namespace="monitoring"} |= "error"

# Exclude lines
{namespace="monitoring"} != "debug"

# Regex match
{namespace="monitoring"} |~ "error[0-9]+"
```

### Combinations

```logql
# Error logs in monitoring namespace
{namespace="monitoring"} |= "error"

# Prometheus logs with warnings
{pod="prometheus-0"} |= "warning"

# Non-debug logs
{namespace="monitoring"} != "debug" != "trace"

# Lines with "connection refused"
{namespace="monitoring"} |= "connection refused"
```

### Metrics Queries (Rate)

```logql
# Count logs over 5 minutes
count_over_time({namespace="monitoring"} |= "error" [5m])

# Rate of errors
rate({namespace="monitoring"} |= "error" [5m])
```

## Common Use Cases

### Monitor Applications

```logql
# All logs from a specific pod
{pod="my-app-0"}

# All logs from an app
{app="my-app"}

# All logs from namespace
{namespace="production"}
```

### Find Issues

```logql
# All errors
{namespace="monitoring"} |= "error"

# Connection issues
{namespace="monitoring"} |= "connection"

# Timeout errors
{namespace="monitoring"} |= "timeout"

# Out of memory
{namespace="monitoring"} |= "OOM"
```

### Monitor Specific Services

```logql
# Prometheus logs
{namespace="monitoring", pod=~"prometheus-.*"}

# Grafana logs
{namespace="monitoring", pod=~"grafana-.*"}

# Alertmanager logs
{namespace="monitoring", pod=~"alertmanager-.*"}
```

## Creating Log Dashboards

### In Grafana

1. Create new dashboard
2. Add panel
3. Data source: Loki
4. Write LogQL query
5. Customize visualization
6. Save dashboard

**Example dashboard**:
- Panel 1: Error logs by namespace
- Panel 2: Log volume trend
- Panel 3: Top error messages
- Panel 4: Pod restart events

## Troubleshooting

### Promtail not collecting logs

```bash
# Check Promtail pods
kubectl get pods -n logging -l app=promtail

# Check Promtail logs
kubectl logs -n logging -l app=promtail --tail=50

# Verify Promtail config
kubectl get configmap -n logging loki-promtail -o yaml
```

### Loki not storing logs

```bash
# Check Loki pod
kubectl get statefulset loki -n logging

# Check Loki logs
kubectl logs -n logging loki-0

# Check PVC
kubectl get pvc -n logging
kubectl describe pvc loki-pvc -n logging
```

### No logs in Grafana

```bash
# Verify Loki datasource
kubectl exec -n monitoring grafana-0 -- curl localhost:3000/api/datasources

# Check Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

### Disk full

```bash
# Check storage usage
kubectl exec -n logging loki-0 -- du -sh /loki

# Clean old logs (manual)
# Edit Loki retention policy in Helm values
```

## Performance Tuning

### For Large Clusters

Increase resources:

```yaml
loki:
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

promtail:
  resources:
    limits:
      cpu: 200m
      memory: 256Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

### For Long Retention

Increase storage and adjust retention:

```yaml
loki:
  persistence:
    size: 10Gi  # Increase as needed
  
  config:
    limits_config:
      retention_period: 720h  # 30 days
```

## Production Considerations

1. **Log Retention**: Configure based on compliance/needs
2. **Storage**: Use external storage for production (S3, GCS)
3. **Backup**: Regular backups of log data
4. **Filtering**: Filter verbose logs to save space
5. **Querying**: Use indexes for faster queries

## Integration with Phase 2 (Metrics)

**Correlate logs with metrics**:
- View pod logs when metrics spike
- Troubleshoot performance issues
- Root cause analysis

## Next Phase

→ **Phase 4: Distributed Tracing**
- Install Grafana Tempo
- Collect request traces
- View trace flows

## References

- [Loki Documentation](https://grafana.com/docs/loki/)
- [LogQL Language](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/)
