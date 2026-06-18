Write-Host "Starting KubeWatch Cluster Setup..." -ForegroundColor Cyan

# Step 1: Delete any existing cluster
Write-Host "`n[1/7] Cleaning up existing cluster..." -ForegroundColor Yellow
kind delete cluster --name kubewatch 2>&1 | Out-Null

# Step 2: Create Kind cluster
Write-Host "`n[2/7] Creating Kind cluster..." -ForegroundColor Yellow
kind create cluster --name kubewatch --config infra/kind/kind-config.yaml

# Step 3: Wait for cluster ready
Write-Host "`n[3/7] Waiting for cluster to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Step 4: Create storage directories on Kind node FIRST!
Write-Host "`n[4/7] Creating storage directories on Kind node..." -ForegroundColor Yellow
docker exec kubewatch-control-plane mkdir -p /mnt/storage /mnt/storage2 /mnt/storage3 /mnt/storage4

# Step 5: Add Helm repos (if not exists)
Write-Host "`n[5/7] Adding Helm repositories..." -ForegroundColor Yellow
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>&1 | Out-Null
helm repo add jetstack https://charts.jetstack.io 2>&1 | Out-Null
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>&1 | Out-Null
helm repo update

# Step 6: Install metrics-server (fixed PowerShell quoting!)
Write-Host "`n[6/7] Installing metrics-server..." -ForegroundColor Yellow
helm upgrade --install metrics-server metrics-server/metrics-server --namespace kube-system --set "args={--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname}"

# Step 7: Create storage classes and PVs
Write-Host "`n[7/7] Creating storage resources..." -ForegroundColor Yellow
kubectl apply -f infra/kubernetes/storage-class.yaml
kubectl apply -f additional-pvs.yaml

# Step 8: Install kube-prometheus-stack
Write-Host "`n[8/8] Installing Prometheus + Grafana stack..." -ForegroundColor Yellow
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --values infra/helm/kube-prometheus-stack-values.yaml

# Wait for all monitoring pods
Write-Host "`nWaiting for all monitoring pods to be ready (this can take a few minutes)..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod --all -n monitoring --timeout=10m

Write-Host "`nCluster setup complete!" -ForegroundColor Green
Write-Host "`nAccess Grafana at: http://localhost:3000"
Write-Host "Username: admin"
Write-Host "Password: Run this command to get it: "
Write-Host "`$pass = kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}'; [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(`$pass))"
Write-Host "`nAccess Prometheus at: http://localhost:9091"
Write-Host "`nTo port-forward Grafana & Prometheus, run in separate terminals:"
Write-Host "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
Write-Host "  kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9091:9090"
