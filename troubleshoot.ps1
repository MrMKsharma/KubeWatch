Write-Host "🔍 KubeWatch Troubleshooting" -ForegroundColor Cyan

Write-Host "`n📊 Pods in monitoring namespace:" -ForegroundColor Yellow
kubectl get pods -n monitoring

Write-Host "`n💾 Persistent Volume Claims:" -ForegroundColor Yellow
kubectl get pvc -n monitoring

Write-Host "`n📦 Persistent Volumes:" -ForegroundColor Yellow
kubectl get pv

Write-Host "`n❓ Checking why pods are pending (if any):" -ForegroundColor Yellow
kubectl get pods -n monitoring --field-selector=status.phase=Pending | ForEach-Object {
    $podName = $_.Name
    if ($podName) {
        Write-Host "`nPod: $podName" -ForegroundColor Red
        kubectl describe pod -n monitoring $podName
    }
}
