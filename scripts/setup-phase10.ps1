# Phase 10: Performance Testing & Optimization Setup
#
# Prerequisites: Phases 1‑9 must be running
# Time: ~3-5 minutes
#
# Usage:
#   cd C:\Users\sharm\Desktop\Test\KubeWatch
#   .\scripts\setup-phase10.ps1

param(
    [switch]$Help,
    [switch]$Debug = $false,
    [switch]$SkipHealthCheck = $false
)

# Load helper functions
. "$PSScriptRoot\kubewatch-functions.ps1"

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Show-Help {
    Write-Host @"
Phase 10: Performance Testing & Optimization Setup

DESCRIPTION
    Deploys optimized resource configurations, HPAs, and performance dashboards.

PREREQUISITES
    OK Phases 1‑9 must be deployed and running
    OK kubectl available and configured

COMPONENTS
    • Optimized resource requests/limits for KubeWatch components
    • Horizontal Pod Autoscalers (HPA)
    • Pod Disruption Budgets (PDB)
    • Performance dashboards in Grafana

USAGE
    .\setup-phase10.ps1                    # Run with defaults
    .\setup-phase10.ps1 -SkipHealthCheck   # Skip prerequisite validation

OPTIONS
    -Help              Show this help message
    -SkipHealthCheck   Skip prerequisite validation

AFTER DEPLOYMENT
    1. Verify HPAs: kubectl get hpa -A
    2. (Optional) Load the helper functions and run tests:
       . .\scripts\phase10-functions.ps1
       kw10-run-load-test

DOCUMENTATION
    See docs/PHASE10.md for complete guide
    See PHASE10-QUICK-START.md for 5-minute reference

"@
}

function Check-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    if ($SkipHealthCheck) {
        Write-Host "[SKIP] Health checks disabled" -ForegroundColor Yellow
        return $true
    }

    $allGood = $true

    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Host '[ERROR]' kubectl not found in PATH" -ForegroundColor Red
        $allGood = $false
    } else {
        Write-Host "[OK] kubectl available" -ForegroundColor Green
    }

    # Check cluster connectivity
    try {
        $clusterInfo = kubectl cluster-info 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Kubernetes cluster accessible" -ForegroundColor Green
        } else {
            Write-Host '[ERROR]' Cannot access Kubernetes cluster" -ForegroundColor Red
            $allGood = $false
        }
    } catch {
        Write-Host '[ERROR]' Cannot access Kubernetes cluster: $_" -ForegroundColor Red
        $allGood = $false
    }

    if (-not $allGood) {
        Write-Host ""
        Write-Host "[FATAL] Prerequisites not met. Please run Phases 1‑9 first." -ForegroundColor Red
        exit 1
    }

    Write-Host "[OK] All prerequisites satisfied" -ForegroundColor Green
    Write-Host ""
}

function Deploy-Optimizations {
    Write-Header "Deploying Performance Optimizations"

    Write-Host "Applying optimization manifests..." -ForegroundColor Cyan
    $optimizationPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "performance"
    kubectl apply -f $optimizationPath 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Optimization manifests applied successfully" -ForegroundColor Green
    } else {
        Write-Host '[ERROR]' Failed to apply optimization manifests" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
}

function Verify-Deployment {
    Write-Header "Verifying Phase 10 Deployment"

    Write-Host "Checking HPAs..." -ForegroundColor Cyan
    $hpaList = kubectl get hpa -A 2>&1
    if ($LASTEXITCODE -eq 0 -and $hpaList) {
        Write-Host "[OK] HPAs found" -ForegroundColor Green
        Write-Host $hpaList
    } else {
        Write-Host '[WARN]' No HPAs found" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Port forwarding recommendations:" -ForegroundColor Cyan
    Write-Host "  Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80" -ForegroundColor Gray
    Write-Host ""
}

function Show-NextSteps {
    Write-Header "Phase 10 Complete!"

    Write-Host "OK Performance Testing & Optimization is ready!

Next Steps:

    1. VERIFY OPTIMIZATIONS
       kubectl get hpa -A
       kubectl get pods -A -o custom-columns=NAME:.metadata.name,CPU_REQUEST:.spec.containers[*].resources.requests.cpu,MEM_REQUEST:.spec.containers[*].resources.requests.memory

    2. (OPTIONAL) RUN LOAD TESTS
       . .\scripts\phase10-functions.ps1
       kw10-run-load-test

    3. CHECK PERFORMANCE DASHBOARDS
       kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
       Open http://localhost:3000 in your browser

Documentation:
    See docs/PHASE10.md for complete reference
    See PHASE10-QUICK-START.md for 5-minute guide

" -ForegroundColor Green
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Header "KubeWatch Phase 10: Performance Testing & Optimization"
Write-Host "Deploying performance optimizations..." -ForegroundColor Cyan
Write-Host ""

Check-Prerequisites
Deploy-Optimizations
Verify-Deployment
Show-NextSteps

Write-Host "Phase 10 setup completed! OK" -ForegroundColor Green
