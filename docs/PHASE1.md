# Phase 1: Local Production Environment

**Objective**: Build a production-grade local Kubernetes environment with Kind, Helm, ingress, and storage.

## Deliverables

✅ **Kind cluster** (kubewatch) - 1 control-plane + 2 worker nodes  
✅ **Production namespaces** - monitoring, logging, tracing, gitops  
✅ **Helm setup** - configured with 3 Helm repos  
✅ **Ingress-nginx** - 2 replicas with HA  
✅ **Cert-manager** - with TLS certificate issuers  
✅ **Metrics-server** - for resource metrics  
✅ **Local storage** - PV provisioner for data persistence  
✅ **Certificate issuers** - self-signed, Let's Encrypt staging & prod  

## Components Overview

### 1. Kind Cluster (`infra/kind/kind-config.yaml`)

**Configuration**:
- 1 control-plane + 2 worker nodes (3-node cluster)
- Kubernetes v1.28.0
- Port mappings: 80 (HTTP), 443 (HTTPS) for Ingress
- Local storage mount: `/mnt/storage` for persistent data
- Feature gates: EphemeralContainers, LocalStorageCapacityIsolation

**Why this setup**:
- Multi-node cluster simulates production behavior
- Worker nodes test scheduling & affinity
- Port mappings allow local Ingress access without services
- Local storage enables PV/PVC testing

### 2. Ingress-NGINX (`infra/helm/ingress-nginx-values.yaml`)

**Production Features Applied**:
- ✅ 2 replicas with pod anti-affinity (HA)
- ✅ Pod Disruption Budget (min 1 available)
- ✅ Resource requests/limits (scaled for Kind)
- ✅ Non-root security context
- ✅ Prometheus metrics enabled
- ✅ LoadBalancer service with externalTrafficPolicy: Local

### 3. Cert-Manager (`infra/helm/cert-manager-values.yaml`)

**Certificate Authorities**:
- `selfsigned` - for local/internal use (no external calls)
- `letsencrypt-staging` - for testing before prod certs
- `letsencrypt-prod` - for real certificates (later, when public)

**Components**:
- cert-manager-controller (main reconciler)
- webhook (validates CRDs)
- cainjector (injects CA certificates)

### 4. Metrics-Server

**Purpose**: Enables `kubectl top nodes/pods` and Horizontal Pod Autoscaler.

**Configuration**: 
- Kubelet insecure TLS (safe for local dev)
- Minimal resources (10m CPU, 32Mi memory)

### 5. Storage

**Local Storage Class**:
- Provisioner: `kubernetes.io/no-provisioner` (manual binding)
- 10Gi PersistentVolume on control-plane node
- Used by Prometheus, Loki, Tempo in later phases

## Namespaces

| Namespace | Purpose | Phase |
|-----------|---------|-------|
| `monitoring` | Prometheus, Grafana, Alertmanager | 2 |
| `logging` | Loki, Promtail | 3 |
| `tracing` | Tempo, OpenTelemetry Collector | 4 |
| `gitops` | ArgoCD | 7 |
| `ingress-nginx` | Ingress controller | 1 |
| `cert-manager` | TLS/certificate management | 1 |
| `kube-system` | Kubernetes system components | 1 |

## Prerequisites

Install on your machine (one-time setup):

```powershell
# Windows - use Chocolatey or manually download

# Option 1: Chocolatey
choco install kind kubectl helm -y

# Option 2: Manual
# Kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation
# Kubectl: https://kubernetes.io/docs/tasks/tools/
# Helm: https://helm.sh/docs/intro/install/
```

Verify installation:

```bash
kind version
kubectl version --client
helm version
```

## Setup Phase 1

### Automated Setup (Recommended)

```powershell
cd infra\kind
.\setup-phase1.ps1
```

The script will:
1. ✅ Check prerequisites (kind, kubectl, helm)
2. ✅ Create Kind cluster (3 nodes)
3. ✅ Wait for cluster readiness
4. ✅ Create 7 namespaces
5. ✅ Add Helm repositories
6. ✅ Install ingress-nginx
7. ✅ Install cert-manager
8. ✅ Install metrics-server
9. ✅ Apply storage & TLS configs
10. ✅ Print cluster information

### Manual Setup (If Script Fails)

```bash
# 1. Create cluster
kind create cluster --config infra/kind/kind-config.yaml

# 2. Create namespaces
kubectl apply -f infra/kubernetes/namespaces.yaml

# 3. Add Helm repos
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 4. Install ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --values infra/helm/ingress-nginx-values.yaml \
  --wait

# 5. Install cert-manager
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --values infra/helm/cert-manager-values.yaml \
  --wait

# 6. Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.4/components.yaml

# 7. Apply storage & TLS configs
kubectl apply -f infra/kubernetes/storage-class.yaml
kubectl apply -f infra/kubernetes/cert-issuer.yaml
```

## Verification

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes -o wide

# Namespaces
kubectl get namespaces

# Check ingress-nginx
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Check cert-manager
kubectl get pods -n cert-manager
kubectl get clusterissuer

# Check storage
kubectl get storageclass
kubectl get pv

# Check metrics-server (might take 30 seconds)
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
```

## Testing

### Test 1: Ingress Routing

```bash
# Create test deployment
kubectl create deployment nginx --image=nginx -n default
kubectl expose deployment nginx --port=80 -n default

# Create ingress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: selfsigned
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - test.local
    secretName: test-tls
  rules:
  - host: test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
EOF

# Wait 10s for cert, then test
sleep 10
curl -H "Host: test.local" http://localhost
```

**Expected**: Nginx default page (HTML)

### Test 2: Certificate Issuance

```bash
# Check if cert was issued
kubectl get certificate -n default
kubectl describe certificate test -n default

# Verify the secret
kubectl get secret test-tls -n default -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout | grep -A 2 "Subject:"
```

**Expected**: Certificate with subject matching `test.local`

### Test 3: Storage Binding

```bash
# Create PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: default
spec:
  storageClassName: local-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF

# Verify binding
kubectl get pvc -n default
kubectl get pv
```

**Expected**: PVC status `Bound` with PV `local-pv-1`

### Test 4: Resource Metrics

```bash
# This requires metrics-server fully ready (~30s)
kubectl top nodes
kubectl top pods -A
```

**Expected**: CPU and memory usage for all nodes/pods

## Troubleshooting

### Cluster won't start

```bash
# Check if another cluster is running
kind get clusters

# Delete if exists
kind delete cluster --name kubewatch

# Check Docker
docker ps
docker logs kubewatch-control-plane
```

### Pods stuck in Pending

```bash
# Check node resources
kubectl describe nodes

# Check PVC binding (for storage-related pods)
kubectl get pvc -A
kubectl get pv
```

### Ingress not working

```bash
# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Check ingress resource
kubectl describe ingress -n default test

# Test connectivity
kubectl run -it --image=curlimages/curl test-curl -- sh
# Inside pod: curl -H "Host: test.local" http://10.0.0.1:80
```

### Cert-manager not issuing certificates

```bash
# Check logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate status
kubectl describe certificate -n default test
```

## Next Phase

→ **Phase 2: Metrics Platform** (Early next week)
- Install kube-prometheus-stack (Prometheus + Grafana)
- Create monitoring dashboards
- Set up Alertmanager alerts

## Architecture

```
┌─────────────────────────────────────────┐
│         KubeWatch Kind Cluster          │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────┐ │
│  │ Control  │  │ Worker 1 │  │ W 2  │ │
│  │ Plane    │  │          │  │      │ │
│  └──────────┘  └──────────┘  └──────┘ │
│       │             │            │     │
│       └─────────────┴────────────┘     │
│              Kubernetes                │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  ingress-nginx (2 replicas)     │───┼─→ :80, :443
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  cert-manager (1 replica)       │   │
│  │  - Manages TLS certificates     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  metrics-server (1 replica)     │   │
│  │  - kubectl top nodes/pods       │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Local Storage (10Gi PV)        │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘

        Docker Desktop / Linux
```

## References

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Ingress-NGINX Helm Chart](https://kubernetes.github.io/ingress-nginx/deploy/)
- [Cert-Manager Installation](https://cert-manager.io/docs/installation/)
- [Metrics-Server](https://github.com/kubernetes-sigs/metrics-server)
- [Kubernetes Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
