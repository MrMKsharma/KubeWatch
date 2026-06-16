# Phase 10: Performance Testing & Optimization – Complete Guide

---

## Table of Contents
1. [What's in this Phase?](#whats-in-this-phase)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Performance Testing](#performance-testing)
5. [Resource Optimization](#resource-optimization)
6. [Verification](#verification)
7. [Cleanup](#cleanup)

---

## What's in this Phase?
This phase adds performance testing capabilities and resource optimization to the KubeWatch platform!

### Key Components
- **k6 Load‑Testing Scripts** – for testing backend API and frontend
- **Resource Tuning** – optimized requests/limits for all KubeWatch deployments
- **HPA (Horizontal Pod Autoscaler)** – automatic scaling for backend and microservices
- **Performance Dashboards** – Grafana dashboards to track metrics like latency, throughput, and error rates

---

## Prerequisites
1. ✅ Phases 1‑9 complete
2. ✅ `kubectl` configured and connected to your cluster
3. ✅ (Optional) Install `k6` for load testing (https://k6.io/docs/getting-started/installation/)

---

## Step-by-Step Deployment

### Step 1: Run the Setup Script
First, let's deploy the optimized resources!

```bash
cd C:\Users\sharm\Desktop\Test\KubeWatch
.\scripts\setup-phase10.ps1
```

This applies:
- Optimized resource requests/limits
- Horizontal Pod Autoscalers (HPA)
- Performance dashboards

### Step 2: Verify the Deployments
Check if all resources are running:

```bash
# Check deployments
kubectl get deployments -A

# Check HPA resources
kubectl get hpa -A
```

---

## Performance Testing

### Run a Load Test
If you have `k6` installed, let's run a quick test on the backend API!

First, load the helper functions:
```bash
. .\scripts\phase10-functions.ps1
```

Then, run a test:
```bash
kw10-run-load-test
```

This will send traffic to the backend API's health and status endpoints!

---

## Resource Optimization
### Optimized Resource Requests/Limits
The deployment applies the following recommended resources:
- **Backend API**: 100m CPU, 128Mi memory (request), 200m CPU, 256Mi memory (limit)
- **Frontend**: 50m CPU, 64Mi memory (request), 100m CPU, 128Mi memory (limit)
- **Microservices (Phase 4)**: 50m CPU, 64Mi memory each

### Horizontal Pod Autoscalers
We've configured HPAs to scale between 1 and 5 replicas based on CPU usage!

---

## Verification
### Check Performance Dashboards
To view performance metrics:
1. Port‑forward Grafana:
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```
2. Open http://localhost:3000 in your browser
3. Log in with username `admin` and retrieve the password:
```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d
```
4. Check out the new **KubeWatch Performance** dashboard!

---

## Cleanup
If you want to remove the performance optimization resources (but keep other components):
```bash
kubectl delete -f .\infra\kubernetes\performance\
```

---

## Next Steps
Next up: **Phase 11 – Disaster Recovery & Backups**!
