# Phase 2: Metrics Platform

**Objective**: Install and configure the metrics monitoring platform (Prometheus, Grafana, Alertmanager).

## Deliverables

✅ **Prometheus** - Metrics collection and storage  
✅ **Grafana** - Dashboards and visualization  
✅ **Alertmanager** - Alert routing and notification  
✅ **Node Exporter** - Node-level metrics  
✅ **Kube-State-Metrics** - Kubernetes object metrics  
✅ **PrometheusRules** - Alert definitions  
✅ **Ingress routes** - HTTPS access to components  
✅ **PersistentVolumes** - Data persistence  

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Metrics Platform (Phase 2)                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │  Prometheus (StatefulSet)                      │   │
│  │  - Scrapes metrics from all targets            │   │
│  │  - 5Gi persistent storage                      │   │
│  │  - 15 days retention                           │   │
│  └────────────────────────────────────────────────┘   │
│                    ▲                                    │
│                    │ (scrapes)                         │
│    ┌───────────────┼───────────────┐                  │
│    │               │               │                  │
│    ▼               ▼               ▼                  │
│  Node Exporter  kube-state-   kubelet              │
│  (nodes)        metrics       (pods)               │
│  (network)      (objects)     (containers)         │
│                                                     │
│  ┌────────────────────────────────────────────────┐   │
│  │  Grafana (Deployment)                          │   │
│  │  - Dashboards and visualizations               │   │
│  │  - 1Gi persistent storage                       │   │
│  │  - Multiple data sources                       │   │
│  └────────────────────────────────────────────────┘   │
│                    ▲                                    │
│                    │ (queries)                         │
│                    │                                    │
│  ┌────────────────────────────────────────────────┐   │
│  │  Alertmanager (StatefulSet)                    │   │
│  │  - Manages alert routing                       │   │
│  │  - 1Gi persistent storage                       │   │
│  │  - Multiple receivers (email, Slack, etc)      │   │
│  └────────────────────────────────────────────────┘   │
│                    ▲                                    │
│                    │ (alert rules)                     │
│                    │                                    │
│         PrometheusRule CRDs                           │
│         (cluster-alerts.yaml)                        │
│                                                     │
└─────────────────────────────────────────────────────────┘
```

## Components

### 1. Prometheus

**Purpose**: Collects and stores time-series metrics from all cluster components.

**Configuration** (`kube-prometheus-stack-values.yaml`):
- **Storage**: 5Gi PersistentVolume
- **Retention**: 15 days
- **Scrape interval**: 30 seconds
- **Evaluation interval**: 30 seconds
- **ServiceMonitors**: Enabled for auto-discovery
- **External labels**: cluster=kubewatch, environment=local

**Metrics collected**:
- Node metrics (CPU, memory, network, disk)
- Pod metrics (CPU, memory, network)
- Container metrics (resource usage)
- Kubernetes API server metrics
- Scheduler metrics
- Controller manager metrics

### 2. Grafana

**Purpose**: Visualization and dashboarding of metrics.

**Configuration**:
- **Storage**: 1Gi PersistentVolume
- **Admin password**: kubewatch123 (change in production)
- **Data source**: Prometheus (auto-configured)
- **Dashboards**: Default Kubernetes dashboards included
- **Plugins**: Ready for additional visualization plugins

**Pre-installed dashboards**:
- Kubernetes cluster overview
- Pod metrics
- Node metrics
- Prometheus stats
- Custom KubeWatch dashboard

**Access**: 
- URL: https://grafana.kubewatch.local
- Username: admin
- Password: kubewatch123

### 3. Alertmanager

**Purpose**: Routes and manages alerts from Prometheus.

**Configuration**:
- **Storage**: 1Gi PersistentVolume
- **Receivers**: null (add email/Slack/etc as needed)
- **Routes**: Grouped by alertname, cluster, service
- **Group wait**: 30s (time to collect alerts)
- **Group interval**: 5m (re-evaluation)

**Alert routing**:
```
AlertRule (Prometheus)
    ↓
Alertmanager
    ├─ Group alerts
    ├─ Deduplicate
    ├─ Route to receivers
    └─ Send notifications
```

### 4. Node Exporter

**Purpose**: Exports Prometheus metrics from each node.

**Metrics**:
- CPU usage
- Memory usage
- Disk usage
- Network I/O
- System load
- Filesystem metrics
- And 100+ more

### 5. Kube-State-Metrics

**Purpose**: Exports Kubernetes object metrics (Deployments, StatefulSets, Pods, etc).

**Metrics**:
- Pod status (running, pending, failed)
- Deployment replicas
- StatefulSet replicas
- Job status
- Container resource requests/limits
- And more

## Alert Rules

**5 Production Alerts** defined in `monitoring/alerts/cluster-alerts.yaml`:

### 1. HighNodeCPUUsage
```
Condition: CPU > 80% for 5 minutes
Severity: warning
Action: Investigate node performance
```

### 2. HighNodeMemoryUsage
```
Condition: Memory > 80% for 5 minutes
Severity: warning
Action: Check for memory leaks
```

### 3. HighDiskUsage
```
Condition: Disk < 20% free for 5 minutes
Severity: warning
Action: Clean up or add storage
```

### 4. NodeDown
```
Condition: Node not responding for 1 minute
Severity: critical
Action: Check node health immediately
```

### 5. PodCrashLoopBackOff
```
Condition: Pod restarting > 5 times per hour
Severity: critical
Action: Investigate pod logs
```

## Setup Instructions

### Prerequisites

Phase 1 must be running:
```bash
kubectl get pods -n ingress-nginx
# Should show 2 ingress-nginx-controller pods
```

### Deploy Phase 2

```powershell
cd C:\Users\sharm\Desktop\Test\KubeWatch
.\scripts\setup-phase2.ps1
```

**What the script does**:
1. ✅ Checks Phase 1 cluster is running
2. ✅ Adds Prometheus Helm repository
3. ✅ Creates PersistentVolumeClaims for storage
4. ✅ Installs kube-prometheus-stack
5. ✅ Applies PrometheusRule alert definitions
6. ✅ Creates Ingress routes for web access
7. ✅ Waits for all components to be ready

**Time**: ~5-10 minutes

### Manual Verification

```bash
# Check Prometheus
kubectl get pods -n monitoring | grep prometheus

# Check Grafana
kubectl get pods -n monitoring | grep grafana

# Check Alertmanager
kubectl get pods -n monitoring | grep alertmanager

# Check storage
kubectl get pvc -n monitoring

# Port forward (if not using Ingress)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
```

## Accessing the Platform

### Option 1: Ingress (Recommended)

Add to `/etc/hosts` (macOS/Linux) or `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
127.0.0.1  grafana.kubewatch.local prometheus.kubewatch.local alertmanager.kubewatch.local
```

Then access:
- **Grafana**: https://grafana.kubewatch.local
- **Prometheus**: https://prometheus.kubewatch.local
- **Alertmanager**: https://alertmanager.kubewatch.local

### Option 2: Port Forward

```bash
# Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Access: http://localhost:3000

# Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Access: http://localhost:9090

# Alertmanager
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# Access: http://localhost:9093
```

## Using Grafana

### Login

1. Navigate to Grafana
2. Username: `admin`
3. Password: `kubewatch123`
4. Change password on first login (recommended)

### Explore Dashboards

**Available dashboards**:
- Kubernetes Cluster Health (custom)
- Prometheus Overview
- Node Exporter Full
- Kubernetes API Server
- Kubernetes Scheduler
- And more

### Create Custom Dashboard

1. Click "+" → "Dashboard"
2. Add panels
3. Select Prometheus as data source
4. Write PromQL queries
5. Save dashboard

**Example PromQL queries**:
```promql
# CPU usage per node
rate(node_cpu_seconds_total{mode="user"}[5m]) * 100

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Pod count by namespace
count(kube_pod_info) by (namespace)

# Container restarts
rate(kube_pod_container_status_restarts_total[1h])
```

## Using Prometheus

### Query Interface

Navigate to Prometheus UI → Graph tab

### Example queries

**CPU metrics**:
```promql
rate(container_cpu_usage_seconds_total[5m])
```

**Memory metrics**:
```promql
container_memory_usage_bytes / 1024 / 1024
```

**Pod status**:
```promql
kube_pod_status_phase
```

**Network I/O**:
```promql
rate(container_network_receive_bytes_total[5m])
```

## Using Alertmanager

### View Alerts

Navigate to Alertmanager UI → Alerts tab

### Alert states

- **Firing**: Alert is currently active
- **Resolved**: Alert has cleared
- **Silenced**: Alert is muted

### Create Custom Alert

Edit `monitoring/alerts/cluster-alerts.yaml`:

```yaml
- alert: MyCustomAlert
  expr: some_metric > 100
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "My alert"
    description: "Details here"
```

Then apply:
```bash
kubectl apply -f monitoring/alerts/cluster-alerts.yaml
```

## Testing

### Test Alert Rules

```bash
# List all alert rules
kubectl get prometheusrule -n monitoring

# View rule details
kubectl describe prometheusrule kubewatch-cluster-rules -n monitoring

# Check Prometheus for active alerts
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Navigate to http://localhost:9090/alerts
```

### Trigger a Test Alert

```bash
# Make a pod consume excessive CPU to trigger HighNodeCPUUsage
kubectl run -it --image=progrium/stress stress -- --cpu 4 --timeout 300s

# Check Alertmanager
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
# Navigate to http://localhost:9093 and view firing alerts
```

### Test Grafana Dashboard

1. Open Grafana dashboard
2. Set time range to "Last 6 hours"
3. Verify all panels are showing data
4. Check for errors in browser console

## Troubleshooting

### Prometheus not scraping metrics

```bash
# Check service monitors
kubectl get servicemonitor -n monitoring

# Check Prometheus status
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

### Grafana not connecting to Prometheus

```bash
# Check data source configuration
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d

# Check Prometheus service
kubectl get svc -n monitoring | grep prometheus
```

### Alerts not firing

```bash
# Check alert rules
kubectl get prometheusrule -n monitoring

# Check Prometheus alerts page
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit http://localhost:9090/rules
```

### Storage full

```bash
# Check PVC usage
kubectl get pvc -n monitoring

# Check Prometheus retention settings
kubectl get prometheus kube-prometheus-stack-prometheus -n monitoring -o jsonpath='{.spec.retention}'
```

## Production Considerations

### For production deployments:

1. **Change Grafana admin password**
   ```bash
   kubectl set env deployment/kube-prometheus-stack-grafana -n monitoring GF_SECURITY_ADMIN_PASSWORD=<new-password>
   ```

2. **Configure alert receivers** (email, Slack, PagerDuty)
   - Edit Alertmanager config
   - Add SMTP/webhook credentials
   - Update route receivers

3. **Adjust storage** based on retention needs
   - 5Gi is suitable for 15 days on medium cluster
   - Increase for longer retention

4. **Use external storage** for long-term metrics
   - Phase 12: Add Thanos for multi-cluster metrics
   - Store metrics in S3/GCS

5. **Configure backup** for Grafana dashboards
   - Export dashboards regularly
   - Store in Git

6. **Set resource limits** in Helm values
   - Adjust CPU/memory for your cluster size

## Next Phase

→ **Phase 3: Logging Platform** (Week 2)
- Install Loki + Promtail
- Collect pod logs
- Create log dashboards

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/overview/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)
