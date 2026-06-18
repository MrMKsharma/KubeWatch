Write-Host "🛑 Stopping ALL KubeWatch Components..." -ForegroundColor Red

# Stop all background jobs
Write-Host "`nStopping background jobs..." -ForegroundColor Yellow
Stop-Job grafana-portforward,prometheus-portforward,backend,frontend -ErrorAction SilentlyContinue
Remove-Job grafana-portforward,prometheus-portforward,backend,frontend -ErrorAction SilentlyContinue

# Optional: Ask user if they want to delete the cluster
$deleteCluster = Read-Host "`nDo you want to delete the Kind cluster? (y/N)"
if ($deleteCluster -eq "y" -or $deleteCluster -eq "Y") {
    Write-Host "Deleting Kind cluster 'kubewatch'..." -ForegroundColor Yellow
    kind delete cluster --name kubewatch
}

Write-Host "`n✅ All KubeWatch components stopped!" -ForegroundColor Green
