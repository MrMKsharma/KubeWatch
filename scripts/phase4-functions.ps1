# Phase 4 Helper Functions for KubeWatch Tracing Platform
#
# Usage:
#   . .\scripts\phase4-functions.ps1

function Show-Phase4Menu {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  KubeWatch Phase 4 - Tracing Platform Functions      "
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Commands:"
    Write-Host "  kw4-port-forward       - Port forward all services"
    Write-Host "  kw4-tempo-port-forward - Port forward Tempo only"
    Write-Host "  kw4-frontend-port      - Port forward Frontend service"
    Write-Host "  kw4-check-status       - Check all services status"
    Write-Host "  kw4-generate-traces    - Generate sample traces"
    Write-Host "  kw4-view-traces        - Open Grafana traces view"
    Write-Host "  kw4-help               - Show this menu"
    Write-Host ""
}

function kw4-port-forward {
    Write-Host "Starting port forwarding for all services..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Keep this terminal open and use separate terminals for:"
    Write-Host ""
    Write-Host "  Grafana (metrics/logs):"
    Write-Host "    kubectl port-forward -n monitoring svc/grafana 3000:80"
    Write-Host ""
    Write-Host "  Tempo (traces):"
    Write-Host "    kubectl port-forward -n tracing svc/tempo 3200:3200"
    Write-Host ""
    Write-Host "  Frontend service:"
    Write-Host "    kubectl port-forward -n tracing svc/frontend 8080:8080"
    Write-Host ""
    Write-Host "Press Ctrl+C to stop all port forwards."
    Write-Host ""
    
    # Start port forwards in background
    kubectl port-forward -n monitoring svc/grafana 3000:80 &
    kubectl port-forward -n tracing svc/tempo 3200:3200 &
    kubectl port-forward -n tracing svc/frontend 8080:8080 &
    
    Write-Host "Port forwarding started. Press any key to stop..." -ForegroundColor Green
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Kill all background jobs
    Get-Job | Stop-Job -Force
    Get-Job | Remove-Job
}

function kw4-tempo-port-forward {
    Write-Host "Port forwarding Tempo on port 3200..." -ForegroundColor Cyan
    Write-Host "Access Tempo at: http://localhost:3200"
    Write-Host ""
    kubectl port-forward -n tracing svc/tempo 3200:3200
}

function kw4-frontend-port {
    Write-Host "Port forwarding Frontend service on port 8080..." -ForegroundColor Cyan
    Write-Host "Access frontend at: http://localhost:8080"
    Write-Host ""
    kubectl port-forward -n tracing svc/frontend 8080:8080
}

function kw4-check-status {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  KubeWatch Phase 4 - Service Status                  "
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Tempo Status:" -ForegroundColor Yellow
    kubectl get pods -n tracing -l app.kubernetes.io/name=tempo 2>$null
    Write-Host ""
    
    Write-Host "OpenTelemetry Collector Status:" -ForegroundColor Yellow
    kubectl get pods -n tracing -l app.kubernetes.io/name=otel-collector 2>$null
    Write-Host ""
    
    Write-Host "Microservices Status:" -ForegroundColor Yellow
    kubectl get pods -n tracing -l app 2>$null
    Write-Host ""
    
    Write-Host "Services:" -ForegroundColor Yellow
    kubectl get services -n tracing 2>$null
    Write-Host ""
}

function kw4-generate-traces {
    Write-Host "Generating traces by accessing frontend..." -ForegroundColor Cyan
    
    # Port forward in background if not already
    $forwarding = kubectl get pods -n tracing -l app=frontend -o jsonpath='{.items[*].metadata.name}' 2>$null
    
    if ($forwarding) {
        # Get pod name and port forward
        $podName = kubectl get pods -n tracing -l app=frontend -o jsonpath='{.items[0].metadata.name}'
        
        # Create a temp job for port forwarding
        Write-Host "Forwarding to frontend pod $podName..." -ForegroundColor Cyan
        
        # Access the service directly
        $result = kubectl exec -n tracing $podName -- curl -s http://localhost:8080/order 2>$null
        
        if ($result) {
            Write-Host "OK Trace generated successfully" -ForegroundColor Green
            Write-Host ""
            Write-Host "View traces in Grafana:"
            Write-Host "  1. Port forward: kubectl port-forward -n monitoring svc/grafana 3000:80"
            Write-Host "  2. Go to: http://localhost:3000 → Explore → Tempo"
            Write-Host ""
        } else {
            Write-Host "[WARN] Could not generate trace (service may not be ready)" -ForegroundColor Yellow
            Write-Host "Try again in a moment..." -ForegroundColor Cyan
        }
    } else {
        Write-Host "[ERROR] Frontend service not found" -ForegroundColor Red
    }
}

function kw4-view-traces {
    Write-Host "Opening Grafana traces view..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Ensure port forwarding is running:"
    Write-Host "   kubectl port-forward -n monitoring svc/grafana 3000:80"
    Write-Host ""
    Write-Host "2. Open browser: http://localhost:3000"
    Write-Host "3. Login: admin / kubewatch123"
    Write-Host "4. Navigate to: Explore → Tempo"
    Write-Host ""
}

# Auto-run menu if script is executed directly
if ($MyInvocation.InvocationName -ne ".") {
    Show-Phase4Menu
}