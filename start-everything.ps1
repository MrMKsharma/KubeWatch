Write-Host "Starting ALL KubeWatch Components..." -ForegroundColor Cyan

# First, check if cluster is running
$clusterExists = kind get clusters | Select-String "kubewatch"
if (-not $clusterExists) {
    Write-Host "`nCluster not found - creating it first..." -ForegroundColor Yellow
    .\start-cluster.ps1
} else {
    Write-Host "`nCluster already exists - skipping cluster creation..." -ForegroundColor Green
}

# Step 1: Get Grafana password
Write-Host "`n[1/6] Getting Grafana credentials..." -ForegroundColor Yellow
$pass = kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}'
$grafanaPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($pass))
Write-Host "Grafana Username: admin" -ForegroundColor Green
Write-Host "Grafana Password: $grafanaPassword" -ForegroundColor Green

# Step 2: Start port-forwards for Grafana & Prometheus in separate terminals
Write-Host "`n[2/6] Starting monitoring port-forwards..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9091:9090"
Start-Sleep -Seconds 2

# Step 3: Start custom KubeWatch backend in separate terminal
Write-Host "`n[3/6] Starting KubeWatch Backend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend/api; go run main.go"
Start-Sleep -Seconds 3

# Step 4: Install frontend dependencies (if needed)
Write-Host "`n[4/6] Checking frontend dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "frontend/node_modules")) {
    Write-Host "Installing npm dependencies..." -ForegroundColor Yellow
    cd frontend; npm install; cd ..
} else {
    Write-Host "Frontend dependencies already installed!" -ForegroundColor Green
}

# Step 5: Start custom KubeWatch frontend in separate terminal
Write-Host "`n[5/6] Starting KubeWatch Frontend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; npm run dev"
Start-Sleep -Seconds 5

# Step 6: Open all UIs
Write-Host "`n[6/6] Opening UIs in your browser..." -ForegroundColor Yellow
Start-Process "http://localhost:3000"
Start-Process "http://localhost:9091"
Start-Process "http://localhost:8090/api/v1/health"
Start-Process "http://localhost:3001"

Write-Host "`nALL KubeWatch Components Are Running!" -ForegroundColor Green
Write-Host "`nAccess UIs:" -ForegroundColor Cyan
Write-Host "  - Grafana: http://localhost:3000"
Write-Host "  - Prometheus: http://localhost:9091"
Write-Host "  - Custom Backend: http://localhost:8090"
Write-Host "  - Custom Frontend: http://localhost:3001"
