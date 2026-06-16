# Phase 4: Distributed Tracing Platform

## Overview

Phase 4 implements distributed tracing for the KubeWatch platform using:
- **Grafana Tempo** - High-scale trace storage and visualization
- **OpenTelemetry** - Standard instrumentation for services
- **Sample Microservices** - Frontend, Orders, Payments, Inventory

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    KubeWatch Tracing Stack                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Microservices (Go + OpenTelemetry SDK)                        │
│  ├─ Frontend (port 8080)                                       │
│  ├─ Orders (port 8081)                                         │
│  ├─ Payments (port 8082)                                       │
│  └─ Inventory (port 8083)                                      │
│         │                                                        │
│         └─(OTLP gRPC)──▶                                        │
│                                                                 │
│  OpenTelemetry Collector (port 4317)                          │
│  ├─ Receives spans from services                               │
│  ├─ Processes and batches                                      │
│  └─ Forwards to Tempo                                          │
│         │                                                        │
│         └─(OTLP gRPC)──▶                                        │
│                                                                 │
│  Grafana Tempo (port 3200)                                     │
│  ├─ Distributor (receives spans)                               │
│  ├─ Ingester (buffers and flushes)                            │
│  ├─ Query frontend                                             │
│  └─ Storage (filesystem/DFS)                                   │
│         │                                                        │
│         └─(5Gi PVC)──▶                                          │
│         └─PersistentVolume                                      │
│                                                                 │
│  Grafana (port 3000)                                           │
│  ├─ Tempo datasource                                           │
│  ├─ Trace visualization                                        │
│  ├─ Service graph                                              │
│  └─ Correlation with metrics/logs                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Components

### 1. Grafana Tempo

Tempo is a distributed tracing system designed for high scale and cost efficiency.

**Key Features**:
- Single binary for all components (distributor, ingester, querier)
- Block-based storage for efficient retention
- Native Grafana integration
- No dependency on databases

**Configuration**:
- Storage: Filesystem (local) or S3/GCS (production)
- Retention: 7 days (168h)
- Replication: 1 (single-node) or 3 (HA)
- Port: 3200 (HTTP), 4317 (OTLP gRPC)

### 2. OpenTelemetry Collector

The Collector receives trace data from services and forwards it to Tempo.

**Configuration**:
- Receivers: OTLP (gRPC and HTTP)
- Processors: batch, memory_limiter
- Exporters: OTLP to Tempo
- Port: 4317 (gRPC), 4318 (HTTP)

### 3. Microservices

Four Go microservices demonstrate tracing:

#### Frontend Service (port 8080)
- Entry point for user requests
- Calls Orders service
- Generates traces for request flow

#### Orders Service (port 8081)
- Creates orders
- Calls Inventory and Payments services
- Generates distributed traces

#### Payments Service (port 8082)
- Processes payments
- Simulates payment processing
- Generates trace spans

#### Inventory Service (port 8083)
- Checks stock availability
- Simulates inventory check
- Generates trace spans

---

## Installation

### Prerequisites

- Phase 1: Kind cluster running
- Phase 2: Prometheus running
- Phase 3: Loki running

### Automated Deployment

```bash
cd C:\Users\sharm\Desktop\Test\KubeWatch
.\scripts\setup-phase4.ps1
```

**What this script does**:
1. Validates prerequisites
2. Creates `tracing` namespace
3. Configures Grafana Tempo Helm chart
4. Creates OpenTelemetry Collector configuration
5. Deploys Tempo and Collector
6. Deploys 4 microservices
7. Configures Grafana datasource
8. Verifies deployment

**Time**: 5-10 minutes

---

## Verification

### Check Pods

```bash
kubectl get pods -n tracing
```

Expected output:
```
NAME                       READY   STATUS    RESTARTS   AGE
frontend-5d6f8b7c9-abc12   1/1     Running   0          2m
inventory-7c8d9e4f5-def34  1/1     Running   0          2m
orders-8e9f0a1b2-ghi56      1/1     Running   0          2m
payments-9f0a1b2c3-jkl78    1/1     Running   0          2m
tempo-0                    1/1     Running   0          3m
otel-collector-xyz789      1/1     Running   0          3m
```

### Check Services

```bash
kubectl get services -n tracing
```

### Check Tempo

```bash
kubectl get statefulset tempo -n tracing
kubectl get svc tempo -n tracing
```

---

## Usage

### Port Forwarding

```bash
# Terminal 1: Grafana (for viewing traces)
kubectl port-forward -n monitoring svc/grafana 3000:80

# Terminal 2: Tempo (for direct access)
kubectl port-forward -n tracing svc/tempo 3200:3200

# Terminal 3: Frontend service
kubectl port-forward -n tracing svc/frontend 8080:8080
```

### Generate Traces

```bash
# Access the frontend
curl http://localhost:8080

# Place an order (triggers distributed trace)
curl http://localhost:8080/order

# Check status
curl http://localhost:8080/status
```

### View in Grafana

1. Open: http://localhost:3000
2. Login: `admin` / `kubewatch123`
3. Navigate to: **Explore** → **Traces**
4. Select datasource: **tempo**
5. Query traces:
   - Service: frontend
   - Operation: /order
   - Time range: Last 15 minutes

### Service Graph

In Grafana:
1. Go to **Explore** → **Traces**
2. Click **Service Graph** tab
3. View service dependencies
4. Identify latency bottlenecks

---

## OpenTelemetry Instrumentation

### Go SDK Setup

```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.12.0"
)

func init() {
    ctx := context.Background()
    
    exporter, err := otlptrace.New(ctx,
        otlptracegrpc.NewClient(
            otlptracegrpc.WithEndpoint("otel-collector:4317"),
            otlptracegrpc.WithInsecure(),
        ),
    )
    if err != nil {
        log.Fatal(err)
    }
    
    res, err := resource.New(ctx,
        resource.WithAttributes(
            semconv.ServiceNameKey.String("service-name"),
            semconv.ServiceVersionKey.String("1.0.0"),
        ),
    )
    
    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(res),
    )
    otel.SetTracerProvider(tp)
}
```

### Tracing HTTP Handlers

```go
import (
    "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

http.HandleFunc("/endpoint", func(w http.ResponseWriter, r *http.Request) {
    ctx, span := tracer.Start(r.Context(), "endpoint")
    defer span.End()
    
    // Your handler logic here
})

http.ListenAndServe(":8080", otelhttp.NewHandler(http.DefaultServeMux, "service-name"))
```

---

## Configuration

### Tempo Values

Key configuration options in `grafana-tempo-values.yaml`:

```yaml
tempo:
  storage:
    trace:
      backend: filesystem
      filesystem:
        path: /var/tempo/traces
      wal:
        path: /var/tempo/wal
  retention: 168h  # 7 days
  replicas: 1      # Increase for HA
```

### OpenTelemetry Collector

Configuration in `tracing-ingress.yaml`:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

exporters:
  otlp:
    client:
      endpoint: tempo:4317
      tls:
        insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [otlp]
```

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod -n tracing <pod-name>

# Check logs
kubectl logs -n tracing <pod-name>
```

### No Traces Visible

1. Check OTel collector is receiving:
   ```bash
   kubectl logs -n tracing svc/otel-collector
   ```

2. Check Tempo is ingesting:
   ```bash
   kubectl logs -n tracing svc/tempo
   ```

3. Verify service is sending:
   ```bash
   # Add logging to service
   log.Printf("Sending trace to otel-collector:4317")
   ```

### Connection Issues

```bash
# Test connectivity
kubectl run -n tracing test --rm -it --image=busybox -- sh
# Inside pod:
wget -O- http://otel-collector:4317
wget -O- http://tempo:3200/status
```

---

## Performance Tuning

### Production Recommendations

1. **Increase Replicas**:
   ```yaml
   replicas: 3  # For HA
   ```

2. **Use S3 Storage**:
   ```yaml
   storage:
     trace:
       backend: s3
       s3:
         bucket: my-tempo-bucket
         region: us-east-1
   ```

3. **Tune Retention**:
   ```yaml
   retention: 720h  # 30 days
   ```

4. **Resource Limits**:
   ```yaml
   resources:
     limits:
       cpu: 2
       memory: 4Gi
     requests:
       cpu: 500m
       memory: 2Gi
   ```

---

## Integration with Metrics and Logs

### Tempo + Prometheus + Loki

Grafana enables correlation across all three:

1. **Trace → Metrics**: Find high-latency traces, then check metrics
2. **Trace → Logs**: Find problematic trace, then check logs
3. **Metrics → Trace**: Find anomalies in metrics, then trace requests

### Dashboard Example

In Grafana:
1. Create new dashboard
2. Add panel: Tempo traces
3. Add panel: Prometheus metrics
4. Add panel: Loki logs
5. Link panels by trace ID

---

## Cost Estimation

### Kind (Local)

- Storage: ~1GB/day
- Monthly: ~30GB

### Production (EKS/GKE)

- Tempo: ~$50-100/month
- Storage: ~$5-10/month (S3)
- Total: ~$55-110/month

---

## Next Steps

✅ Phase 4 Complete - Tracing Platform  
⏳ Phase 5 - Custom Backend API  
⏳ Phase 6 - React Frontend  
⏳ Phase 7 - GitOps (ArgoCD)  

---

**KubeWatch Phase 4 - Distributed Tracing Platform**  
**Status**: Complete  
**Documentation**: This file