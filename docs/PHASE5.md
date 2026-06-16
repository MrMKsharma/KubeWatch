# Phase 5: Custom Backend API

## Overview

Phase 5 implements a custom Go REST API for KubeWatch, integrating with all existing observability components.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              KubeWatch Backend API                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  REST API (gorilla/mux)                          │  │
│  │  ├─ /api/v1/health                                │  │
│  │  ├─ /api/v1/status                                │  │
│  │  ├─ /api/v1/metrics/query                         │  │
│  │  ├─ /api/v1/logs/query                            │  │
│  │  └─ /api/v1/traces/query                          │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                              │
│                          ▼                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Integrations                                      │  │
│  │  ├─ Kubernetes API (client-go)                    │  │
│  │  ├─ Prometheus API                                │  │
│  │  ├─ Loki API                                      │  │
│  │  └─ Tempo API                                     │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Components

### 1. Custom Backend API (Go)
- Built with Go's standard library + gorilla/mux
- Kubernetes API integration via client-go
- - Prometheus/Loki/Tempo query endpoints
- - OpenTelemetry instrumentation
-

### 2. Kubernetes Manifests
- - Namespace `kubewatch`
- - ServiceAccount with ClusterRole permissions
- - Deployment + Service
-

---

## Installation

### Prerequisites

- Phase 1: Kind cluster running
- Phase 2: Prometheus running
- Phase 3: Loki running
- Phase 4: Tempo running

### Automated Deployment

```bash
cd C:\Users\sharm\Desktop\Test\KubeWatch
.\scripts\setup-phase5.ps1
```

**What this script does**:
1. Validates prerequisites
2. Creates `kubewatch` namespace
3. Creates RBAC resources
4. Deploys backend API
5. Verifies deployment

---

## Verification

### Check Pods

```bash
kubectl get pods -n kubewatch
```

Expected output:
```
NAME                            READY   STATUS    RESTARTS   AGE
kubewatch-api-xxxxxxxxxx-xxxxx  1/1     Running   0          2m
```

### Check Services

```bash
kubectl get svc -n kubewatch
```

---

## Usage

### Port Forwarding

```bash
kubectl port-forward -n kubewatch svc/kubewatch-api 8090:8090
```

### Test Endpoints

```bash
# Health check
curl http://localhost:8090/api/v1/health

# Status
curl http://localhost:8090/api/v1/status
```

---

## Configuration

### Backend API

Key configuration via environment variables:
- `PROMETHEUS_URL`: Prometheus API endpoint
- `LOKI_URL`: Loki API endpoint
- `TEMPO_URL`: Tempo API endpoint
- `PORT`: API port (default 8090)

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod -n kubewatch -l app=kubewatch-api

# Check logs
kubectl logs -n kubewatch -l app=kubewatch-api
```

---

## Next Steps

✅ Phase 5 Complete - Custom Backend API
⏳ Phase 6 - React Frontend

---

**KubeWatch Phase 5 - Custom Backend API**
**Status**: Complete
**Documentation**: This file
