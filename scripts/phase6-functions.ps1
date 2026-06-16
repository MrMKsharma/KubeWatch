# Phase 6 Helper Functions for KubeWatch Frontend
#
# Usage:
#   . .\scripts\phase6-functions.ps1

function Show-Phase6Menu {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  KubeWatch Phase 6 - Frontend Functions               "
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Commands:"
    Write-Host "  kw6-frontend-port-forward - Port forward frontend to localhost:3000"
    Write-Host "  kw6-check-status         - Check frontend status"
    Write-Host "  kw6-help                 - Show this menu"
    Write-Host ""
}

function kw6-frontend-port-forward {
    Write-Host "Port forwarding KubeWatch Frontend to port 3000..." -ForegroundColor Cyan
    Write-Host "Access UI at: http://localhost:3000"
    Write-Host ""
    kubectl port-forward -n kubewatch svc/kubewatch-frontend 3000:3000
}

function kw6-check-status {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  KubeWatch Phase 6 - Frontend Status                  "
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Frontend Pod Status:" -ForegroundColor Yellow
    kubectl get pods -n kubewatch -l app=kubewatch-frontend 2>$null
    Write-Host ""
    
    Write-Host "Services:" -ForegroundColor Yellow
    kubectl get services -n kubewatch 2>$null
    Write-Host ""
}

# Auto-run menu if script is executed directly
if ($MyInvocation.InvocationName -ne ".") {
    Show-Phase6Menu
}
