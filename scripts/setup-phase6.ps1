# Phase 6: React Frontend Setup
# Installs KubeWatch's React frontend
#
# Prerequisites: Phases 1-5 must be running
# Time: ~3-5 minutes
#
# Usage:
#   cd C:\Users\sharm\Desktop\Test\KubeWatch
#   .\scripts\setup-phase6.ps1

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
Phase 6: React Frontend Setup

DESCRIPTION
    Deploys KubeWatch's React + TypeScript frontend.

PREREQUISITES
    OK Phases 1-5 must be deployed and running
    OK kubectl available and configured

COMPONENTS
    • KubeWatch Frontend - React Web UI (port 3000)

WHAT GETS CREATED
    • Deployment + Service for frontend
    • Ingress for frontend + backend path routing

USAGE
    .\setup-phase6.ps1                    # Run with defaults
    .\setup-phase6.ps1 -Debug             # Run with debug output
    .\setup-phase6.ps1 -SkipHealthCheck   # Skip prerequisite validation

OPTIONS
    -Help              Show this help message
    -Debug             Enable debug output
    -SkipHealthCheck   Skip prerequisite validation

AFTER DEPLOYMENT
    1. Port forward frontend: kubectl port-forward -n kubewatch svc/kubewatch-frontend 3000:3000
    2. Open http://localhost:3000 in browser

DOCUMENTATION
    See docs/PHASE6.md for complete guide
    See PHASE6-QUICK-START.md for 5-minute reference

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

    # Check Phase 1 (Kind cluster)
    try {
        $kindNodes = kubectl get nodes -o jsonpath='{.items[*].metadata.name}' 2>&1
        if ($LASTEXITCODE -eq 0 -and $kindNodes) {
            Write-Host "[OK] Phase 1 (Kubernetes cluster) deployed" -ForegroundColor Green
        } else {
            Write-Host '[ERROR]' Phase 1 not detected" -ForegroundColor Red
            $allGood = $false
        }
    } catch {
        Write-Host '[ERROR]' Cannot verify Phase 1: $_" -ForegroundColor Red
        $allGood = $false
    }

    # Check Phase 5 (backend API)
    try {
        $apiPods = kubectl get pods -n kubewatch -l app=kubewatch-api -o jsonpath='{.items[*].metadata.name}' 2>&1
        if ($LASTEXITCODE -eq 0 -and $apiPods) {
            Write-Host "[OK] Phase 5 (backend API) deployed" -ForegroundColor Green
        } else {
            Write-Host '[WARN]' Phase 5 (backend API) not detected" -ForegroundColor Yellow
        }
    } catch {
        Write-Host '[WARN]' Cannot verify Phase 5: $_" -ForegroundColor Yellow
    }

    if (-not $allGood) {
        Write-Host ""
        Write-Host "[FATAL] Prerequisites not met. Please run Phases 1-5 first." -ForegroundColor Red
        exit 1
    }

    Write-Host "[OK] All prerequisites satisfied" -ForegroundColor Green
    Write-Host ""
}

function Deploy-Frontend {
    Write-Header "Deploying KubeWatch Frontend"

    Write-Host "Applying frontend manifests..." -ForegroundColor Cyan
    kubectl apply -f "$PSScriptRoot\..\infra\kubernetes\frontend.yaml" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Frontend manifests applied" -ForegroundColor Green
    } else {
        Write-Host '[ERROR]' Failed to apply frontend manifests" -ForegroundColor Red
        exit 1
    }

    # Wait for frontend to be ready
    Write-Host "Waiting for frontend pod to be ready..." -ForegroundColor Cyan
    kubectl wait --for=condition=ready pod -l app=kubewatch-frontend -n kubewatch --timeout=300s 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Frontend pod ready" -ForegroundColor Green
    } else {
        Write-Host '[WARN]' Timeout waiting for frontend pod (it may still be starting)" -ForegroundColor Yellow
    }

    Write-Host ""
}

function Verify-Deployment {
    Write-Header "Verifying Phase 6 Deployment"

    Write-Host "Checking frontend pod..." -ForegroundColor Cyan
    $frontendPods = kubectl get pods -n kubewatch -l app=kubewatch-frontend -o jsonpath='{.items[*].metadata.name}' 2>&1

    if ($frontendPods) {
        Write-Host "[OK] Frontend deployed" -ForegroundColor Green
    } else {
        Write-Host '[WARN]' Frontend pod not found" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Port forwarding recommendations:" -ForegroundColor Cyan
    Write-Host "  Frontend: kubectl port-forward -n kubewatch svc/kubewatch-frontend 3000:3000" -ForegroundColor Gray
    Write-Host ""
}

function Show-NextSteps {
    Write-Header "Phase 6 Complete!"

    Write-Host "OK React Frontend is ready!

Next Steps:

    1. VERIFY SERVICES
       kubectl get pods -n kubewatch
       kubectl get svc -n kubewatch

    2. PORT FORWARD
       kubectl port-forward -n kubewatch svc/kubewatch-frontend 3000:3000

    3. ACCESS UI
       Open http://localhost:3000 in your browser

Documentation:
    See docs/PHASE6.md for complete reference
    See PHASE6-QUICK-START.md for 5-minute guide

" -ForegroundColor Green
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Header "KubeWatch Phase 6: React Frontend"
Write-Host "Installing KubeWatch React Web UI" -ForegroundColor Cyan
Write-Host ""

Check-Prerequisites
Deploy-Frontend
Verify-Deployment
Show-NextSteps

Write-Host "Phase 6 setup completed! OK" -ForegroundColor Green
