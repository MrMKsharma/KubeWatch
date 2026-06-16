#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Phase 3 Setup Script - Installs logging platform (Loki + Promtail)
.DESCRIPTION
    Installs and configures Loki for log aggregation:
    - Loki (log storage & querying)
    - Promtail (log collection from pods)
    - Integration with Grafana
.EXAMPLE
    .\setup-phase3.ps1
#>

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

$Colors = @{
    Info    = "`e[32m"
    Warn    = "`e[33m"
    Error   = "`e[31m"
    Reset   = "`e[0m"
}

function Write-Info { Write-Host "$($Colors.Info)[INFO]$($Colors.Reset) $args" }
function Write-Warn { Write-Host "$($Colors.Warn)[WARN]$($Colors.Reset) $args" }
function Write-Error-Custom { Write-Host "$($Colors.Error)[ERROR]$($Colors.Reset) $args" }

function Check-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    try {
        $pods = kubectl get pods -n monitoring 2>$null
        if (-not $?) {
            Write-Error-Custom "Phase 2 cluster not found!"
            Write-Info "Run Phase 2 setup first: .\scripts\setup-phase2.ps1"
            exit 1
        }
        
        Write-Info "Phase 2 monitoring platform found OK"
    }
    catch {
        Write-Error-Custom "Error checking cluster: $_"
        exit 1
    }
}

function Add-Loki-Repo {
    Write-Info "Adding Grafana Loki Helm repository..."
    
    helm repo add grafana https://grafana.github.io/helm-charts 2>$null
    helm repo update | Out-Null
    
    Write-Info "Loki repository added OK"
}

function Create-Storage-PVC {
    Write-Info "Creating storage for Loki..."
    
    $lokiYaml = @'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: loki-pvc
  namespace: logging
spec:
  storageClassName: local-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
'@
    
    $lokiYaml | kubectl apply -f -
    
    Write-Info "Loki storage PVC created OK"
}

function Install-Loki-Stack {
    Write-Info "Installing Loki stack..."
    
    $valuesPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "helm") "loki-stack-values.yaml"
    
    helm upgrade --install loki grafana/loki-stack `
        --namespace logging `
        --values $valuesPath `
        --wait `
        --timeout 10m 2>&1 | Out-Null
    
    Write-Info "Loki stack installed OK"
}

function Apply-Logging-Config {
    Write-Info "Applying logging configuration..."
    
    $ingressPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "logging-ingress.yaml"
    $alertsPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "monitoring") "alerts") "logging-alerts.yaml"
    
    kubectl apply -f $ingressPath | Out-Null
    kubectl apply -f $alertsPath | Out-Null
    
    Write-Info "Logging configuration applied OK"
}

function Add-Loki-Datasource {
    Write-Info "Adding Loki data source to Grafana..."
    
    # Get Grafana pod
    $pod = kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}'
    
    if ([string]::IsNullOrEmpty($pod)) {
        Write-Warn "Grafana pod not found, skipping datasource configuration"
        return
    }
    
    # Configure Loki datasource via Grafana API
    $result = kubectl exec -n monitoring $pod -- curl -X POST -H "Content-Type: application/json" `
        -d '{"name":"Loki","type":"loki","url":"http://loki:3100","access":"proxy","isDefault":false}' `
        http://localhost:3000/api/datasources 2>$null
    if (-not $result) {
        Write-Warn "Datasource configuration skipped"
    }
    
    Write-Info "Loki datasource added to Grafana OK"
}

function Wait-For-Deployment {
    Write-Info "Waiting for logging components to be ready..."
    
    # Wait for Loki
    kubectl rollout status statefulset/loki -n logging --timeout=5m 2>&1 | Out-Null
    
    # Wait for Promtail
    kubectl rollout status daemonset/loki-promtail -n logging --timeout=5m 2>&1 | Out-Null
    
    Write-Info "All logging components are ready OK"
}

function Print-Summary {
    Write-Info "Phase 3 Setup Complete! OK"
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "            PHASE 3 - LOGGING PLATFORM READY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Logging Components:" -ForegroundColor Green
    kubectl get pods -n logging
    Write-Host ""
    
    Write-Host "Log Collection:" -ForegroundColor Green
    Write-Host "  Loki:     http://loki:3100 (log storage)" -ForegroundColor Cyan
    Write-Host "  Promtail: Running on all nodes (DaemonSet)" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Access Logs:" -ForegroundColor Green
    Write-Host "  In Grafana:" -ForegroundColor White
    Write-Host "     1. Open Grafana (http://localhost:3000)" -ForegroundColor Gray
    Write-Host "     2. Select data source: Loki" -ForegroundColor Gray
    Write-Host "     3. Explore → Logs" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Common Queries:" -ForegroundColor Green
    Write-Host "  {namespace=`"monitoring`"}                    - All logs in monitoring" -ForegroundColor Cyan
    Write-Host "  {namespace=`"monitoring`"} |= `"error`"        - Error logs" -ForegroundColor Cyan
    Write-Host "  {pod=`"prometheus-0`"}                       - Prometheus pod logs" -ForegroundColor Cyan
    Write-Host "  {pod=~`"grafana.*`"} |= `"error`"             - Grafana error logs" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "  1. Access Grafana and explore logs" -ForegroundColor White
    Write-Host "  2. Check Promtail collection status" -ForegroundColor White
    Write-Host "  3. Create custom log dashboards" -ForegroundColor White
    Write-Host "  4. Proceed to Phase 4: Distributed Tracing" -ForegroundColor White
    Write-Host ""
}

try {
    Check-Prerequisites
    Add-Loki-Repo
    Create-Storage-PVC
    Install-Loki-Stack
    Apply-Logging-Config
    Add-Loki-Datasource
    Wait-For-Deployment
    Print-Summary
}
catch {
    Write-Error-Custom "Setup failed: $_"
    exit 1
}
