#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Phase 2 Setup Script - Installs metrics platform (Prometheus + Grafana + Alertmanager)
.DESCRIPTION
    Installs and configures kube-prometheus-stack for cluster monitoring:
    - Prometheus (metrics collection)
    - Grafana (dashboards)
    - Alertmanager (alert routing)
    - Node exporter (node metrics)
    - kube-state-metrics (Kubernetes metrics)
.EXAMPLE
    .\setup-phase2.ps1
#>

param(
    [switch]$Force = $false,
    [switch]$SkipPrerequisiteCheck = $false
)

$ErrorActionPreference = "Stop"

# Color constants
$Colors = @{
    Info    = "`e[32m"
    Warn    = "`e[33m"
    Error   = "`e[31m"
    Reset   = "`e[0m"
}

function Write-Info { Write-Host "$($Colors.Info)[INFO]$($Colors.Reset) $args" }
function Write-Warn { Write-Host "$($Colors.Warn)[WARN]$($Colors.Reset) $args" }
function Write-Error-Custom { Write-Host "$($Colors.Error)[ERROR]$($Colors.Reset) $args" }

function Check-Phase1 {
    Write-Info "Checking Phase 1 deployment..."
    
    try {
        $pods = kubectl get pods -n ingress-nginx 2>$null
        if (-not $?) {
            Write-Error-Custom "Phase 1 cluster not found!"
            Write-Info "Run Phase 1 setup first: .\scripts\setup-phase1.ps1"
            exit 1
        }
        
        Write-Info "Phase 1 cluster found OK"
    }
    catch {
        Write-Error-Custom "Error checking cluster: $_"
        exit 1
    }
}

function Add-Prometheus-Repo {
    Write-Info "Adding Prometheus Helm repository..."
    
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null
    helm repo update | Out-Null
    
    Write-Info "Prometheus repository added OK"
}

function Create-Storage-PVCs {
    Write-Info "Creating storage for monitoring components..."
    
    # Create PVCs for Prometheus, Grafana, Alertmanager
    $pvcYaml = @'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-pvc
  namespace: monitoring
spec:
  storageClassName: local-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-pvc
  namespace: monitoring
spec:
  storageClassName: local-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: alertmanager-pvc
  namespace: monitoring
spec:
  storageClassName: local-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
'@
    
    $pvcYaml | kubectl apply -f -
    
    Write-Info "Storage PVCs created OK"
}

function Install-Prometheus-Stack {
    Write-Info "Installing kube-prometheus-stack..."
    
    $valuesPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "helm") "kube-prometheus-stack-values.yaml"
    
    helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack `
        --namespace monitoring `
        --values $valuesPath `
        --wait `
        --timeout 10m 2>&1 | Out-Null
    
    Write-Info "kube-prometheus-stack installed OK"
}

function Apply-Alert-Rules {
    Write-Info "Applying Prometheus alert rules..."
    
    $alertsPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "monitoring") "alerts") "cluster-alerts.yaml"
    
    kubectl apply -f $alertsPath | Out-Null
    
    Write-Info "Alert rules applied OK"
}

function Apply-Ingress {
    Write-Info "Creating ingress routes..."
    
    $ingressPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "monitoring-ingress.yaml"
    
    kubectl apply -f $ingressPath | Out-Null
    
    Write-Info "Ingress routes created OK"
}

function Wait-For-Deployment {
    Write-Info "Waiting for monitoring components to be ready..."
    
    # Wait for Prometheus
    kubectl rollout status statefulset/kube-prometheus-stack-prometheus -n monitoring --timeout=5m 2>&1 | Out-Null
    
    # Wait for Grafana
    kubectl rollout status deployment/kube-prometheus-stack-grafana -n monitoring --timeout=5m 2>&1 | Out-Null
    
    # Wait for Alertmanager
    kubectl rollout status statefulset/kube-prometheus-stack-alertmanager -n monitoring --timeout=5m 2>&1 | Out-Null
    
    Write-Info "All components are ready OK"
}

function Print-Summary {
    Write-Info "Phase 2 Setup Complete! OK"
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "            PHASE 2 - METRICS PLATFORM READY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Monitoring Namespace Pods:" -ForegroundColor Green
    kubectl get pods -n monitoring
    Write-Host ""
    
    Write-Host "Prometheus Endpoints:" -ForegroundColor Green
    Write-Host "  Grafana:       https://grafana.kubewatch.local" -ForegroundColor Cyan
    Write-Host "     Login: admin / kubewatch123" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Prometheus:    https://prometheus.kubewatch.local" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Alertmanager:  https://alertmanager.kubewatch.local" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Access from localhost:" -ForegroundColor Green
    Write-Host "  Add to /etc/hosts (macOS/Linux) or %WINDIR%\System32\drivers\etc\hosts (Windows):" -ForegroundColor Gray
    Write-Host "    127.0.0.1  grafana.kubewatch.local prometheus.kubewatch.local alertmanager.kubewatch.local" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Or use port-forward:" -ForegroundColor Gray
    Write-Host "    kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "  1. Access Grafana and explore dashboards" -ForegroundColor White
    Write-Host "  2. Check Prometheus for available metrics" -ForegroundColor White
    Write-Host "  3. View alerts in Alertmanager" -ForegroundColor White
    Write-Host "  4. Proceed to Phase 3: Logging Platform" -ForegroundColor White
    Write-Host ""
}

# Main execution
try {
    if (-not $SkipPrerequisiteCheck) {
        Check-Phase1
    }
    
    Add-Prometheus-Repo
    Create-Storage-PVCs
    Install-Prometheus-Stack
    Apply-Alert-Rules
    Apply-Ingress
    Wait-For-Deployment
    Print-Summary
}
catch {
    Write-Error-Custom "Setup failed: $_"
    exit 1
}
