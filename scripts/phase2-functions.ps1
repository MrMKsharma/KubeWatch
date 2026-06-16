#!/usr/bin/env pwsh

# Phase 2 specific helper functions
# Source this file to add Phase 2 commands

function kw2-grafana-port-forward {
    Write-Host "Opening Grafana port-forward..." -ForegroundColor Cyan
    Write-Host "Access at: http://localhost:3000" -ForegroundColor Green
    kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
}

function kw2-prometheus-port-forward {
    Write-Host "Opening Prometheus port-forward..." -ForegroundColor Cyan
    Write-Host "Access at: http://localhost:9090" -ForegroundColor Green
    kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
}

function kw2-alertmanager-port-forward {
    Write-Host "Opening Alertmanager port-forward..." -ForegroundColor Cyan
    Write-Host "Access at: http://localhost:9093" -ForegroundColor Green
    kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
}

function kw2-status {
    Write-Host ""
    Write-Host "=== Phase 2 Monitoring Components ===" -ForegroundColor Cyan
    kubectl get pods -n monitoring
    Write-Host ""
    
    Write-Host "=== Storage ===" -ForegroundColor Cyan
    kubectl get pvc -n monitoring
    Write-Host ""
    
    Write-Host "=== Services ===" -ForegroundColor Cyan
    kubectl get svc -n monitoring
    Write-Host ""
}

function kw2-prometheus-rules {
    Write-Host "=== Active Alert Rules ===" -ForegroundColor Cyan
    kubectl get prometheusrule -n monitoring
}

function kw2-view-alerts {
    Write-Host "Opening Prometheus alerts page..." -ForegroundColor Cyan
    Write-Host "Run: kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090" -ForegroundColor Yellow
    Write-Host "Then visit: http://localhost:9090/alerts" -ForegroundColor Green
}

function kw2-test-alert {
    Write-Host "Creating high CPU load to test alerts..." -ForegroundColor Yellow
    Write-Host "This will run for 5 minutes..." -ForegroundColor Gray
    kubectl run stress-test --image=progrium/stress -- --cpu 4 --timeout 300s -n default
    Write-Host ""
    Write-Host "Check alerts in Alertmanager after 5 minutes" -ForegroundColor Green
}

function kw2-cleanup-test {
    Write-Host "Cleaning up test pods..." -ForegroundColor Cyan
    kubectl delete pod -l 'run=stress-test' -n default 2>/dev/null
    Write-Host "Cleanup complete" -ForegroundColor Green
}

function kw2-logs {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("prometheus", "grafana", "alertmanager")]
        [string]$Component
    )
    
    Write-Host "Streaming $Component logs..." -ForegroundColor Cyan
    kubectl logs -n monitoring -l app.kubernetes.io/name=$Component --tail=100 -f
}

function kw2-export-dashboard {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DashboardName,
        
        [string]$OutputPath = "."
    )
    
    Write-Host "Exporting dashboard: $DashboardName" -ForegroundColor Cyan
    
    # Get Grafana pod
    $pod = kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}'
    
    if ([string]::IsNullOrEmpty($pod)) {
        Write-Host "Grafana pod not found" -ForegroundColor Red
        return
    }
    
    # Use Grafana API to export
    Write-Host "Dashboard export requires manual export from Grafana UI" -ForegroundColor Yellow
    Write-Host "1. Open Grafana" -ForegroundColor White
    Write-Host "2. Go to dashboard: $DashboardName" -ForegroundColor White
    Write-Host "3. Click menu → Export" -ForegroundColor White
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Phase 2 Monitoring Platform Helper Functions      ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access Components:" -ForegroundColor Green
Write-Host "  kw2-grafana-port-forward       - Port forward to Grafana (3000)" -ForegroundColor White
Write-Host "  kw2-prometheus-port-forward    - Port forward to Prometheus (9090)" -ForegroundColor White
Write-Host "  kw2-alertmanager-port-forward  - Port forward to Alertmanager (9093)" -ForegroundColor White
Write-Host ""

Write-Host "Status & Monitoring:" -ForegroundColor Green
Write-Host "  kw2-status                     - Show monitoring components status" -ForegroundColor White
Write-Host "  kw2-prometheus-rules           - List alert rules" -ForegroundColor White
Write-Host "  kw2-view-alerts                - View active alerts in Prometheus" -ForegroundColor White
Write-Host "  kw2-logs <component>           - Stream logs (prometheus/grafana/alertmanager)" -ForegroundColor White
Write-Host ""

Write-Host "Testing:" -ForegroundColor Green
Write-Host "  kw2-test-alert                 - Trigger test alert (high CPU load)" -ForegroundColor White
Write-Host "  kw2-cleanup-test               - Clean up test pods" -ForegroundColor White
Write-Host ""

Write-Host "Configuration:" -ForegroundColor Green
Write-Host "  kw2-export-dashboard <name>    - Export Grafana dashboard" -ForegroundColor White
Write-Host ""
