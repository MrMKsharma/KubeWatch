# Phase 5 Helper Functions for KubeWatch Backend API
#
# Usage:
#   . .\scripts\phase5-functions.ps1

function Show-Phase5Menu {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  KubeWatch Phase 5 - Backend API Functions            "
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Commands:"
    Write-Host "  kw5-api-port-forward   - Port forward backend API"
    Write-Host "  kw5-check-status       - Check backend API status"
    Write-Host "  kw5-test-api           - Test backend API endpoints"
    Write-Host "  kw5-help               - Show this menu"
    Write-Host ""
}

function kw5-api-port-forward {
    Write-Host "Port forwarding KubeWatch API on port 8090..." -ForegroundColor Cyan
    Write-Host "Access API at: http://localhost:8090"
    Write-Host ""
    kubectl port-forward -n kubewatch svc/kubewatch-api 8090:8090
}

function kw5-check-status {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  KubeWatch Phase 5 - Service Status                  "
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Backend API Status:" -ForegroundColor Yellow
    kubectl get pods -n kubewatch -l app=kubewatch-api 2>$null
    Write-Host ""
    
    Write-Host "Services:" -ForegroundColor Yellow
    kubectl get services -n kubewatch 2>$null
    Write-Host ""
}

function kw5-test-api {
    Write-Host "Testing KubeWatch API endpoints..." -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "1. Testing /api/v1/health:" -ForegroundColor Yellow
    $health = kubectl exec -n kubewatch -l app=kubewatch-api -- curl -s http://localhost:8090/api/v1/health 2>$null
    if ($health) {
        Write-Host "OK Success: $health" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to test health endpoint" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "2. Testing /api/v1/status:" -ForegroundColor Yellow
    $status = kubectl exec -n kubewatch -l app=kubewatch-api -- curl -s http://localhost:8090/api/v1/status 2>$null
    if ($status) {
        Write-Host "OK Success: $status" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to test status endpoint" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Auto-run menu if script is executed directly
if ($MyInvocation.InvocationName -ne ".") {
    Show-Phase5Menu
}
