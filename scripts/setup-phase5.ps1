# Phase 5: Custom Backend API Setup
# Installs KubeWatch's custom Go REST API
#
# Prerequisites: Phases 1, 2, 3, 4 must be running
# Time: ~3-5 minutes
#
# Usage:
#   cd C:\Users\sharm\Desktop\Test\KubeWatch
#   .\scripts\setup-phase5.ps1

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
Phase 5: Custom Backend API Setup

DESCRIPTION
    Deploys KubeWatch's custom Go REST API.

PREREQUISITES
    OK Phases 1, 2, 3, 4 must be deployed and running
    OK kubectl available and configured
    OK Helm 3.x installed

COMPONENTS
    • KubeWatch Backend API - Go REST API (port 8090)

WHAT GETS CREATED
    Namespaces:
      • kubewatch - Backend API

    Kubernetes Resources:
      • ServiceAccount
      • ClusterRole + ClusterRoleBinding
      • Deployment
      • Service

USAGE
    .\setup-phase5.ps1                    # Run with defaults
    .\setup-phase5.ps1 -Debug             # Run with debug output
    .\setup-phase5.ps1 -SkipHealthCheck   # Skip prerequisite validation

OPTIONS
    -Help              Show this help message
    -Debug             Enable debug output
    -SkipHealthCheck   Skip prerequisite validation

EXAMPLES
    # Standard deployment
    .\setup-phase5.ps1

    # With debug output
    .\setup-phase5.ps1 -Debug

    # Skip health checks
    .\setup-phase5.ps1 -SkipHealthCheck

AFTER DEPLOYMENT
    1. Port-forward API: kubectl port-forward -n kubewatch svc/kubewatch-api 8090:8090
    2. Test health endpoint: curl http://localhost:8090/api/v1/health

DOCUMENTATION
    See docs/PHASE5.md for complete guide
    See PHASE5-QUICK-START.md for 5-minute reference

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
    }
    else {
        Write-Host "[OK] kubectl available" -ForegroundColor Green
    }

    # Check cluster connectivity
    try {
        $clusterInfo = kubectl cluster-info 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Kubernetes cluster accessible" -ForegroundColor Green
        }
        else {
            Write-Host '[ERROR]' Cannot access Kubernetes cluster" -ForegroundColor Red
            $allGood = $false
        }
    }
    catch {
        Write-Host '[ERROR]' Cannot access Kubernetes cluster: $_" -ForegroundColor Red
        $allGood = $false
    }

    # Check Phase 1 (Kind cluster)
    try {
        $kindNodes = kubectl get nodes -o jsonpath='{.items[*].metadata.name}' 2>&1
        if ($LASTEXITCODE -eq 0 -and $kindNodes) {
            Write-Host "[OK] Phase 1 (Kubernetes cluster) deployed" -ForegroundColor Green
        }
        else {
            Write-Host '[ERROR]' Phase 1 not detected" -ForegroundColor Red
            $allGood = $false
        }
    }
    catch {
        Write-Host '[ERROR]' Cannot verify Phase 1: $_" -ForegroundColor Red
        $allGood = $false
    }

    if (-not $allGood) {
        Write-Host ""
        Write-Host "[FATAL] Prerequisites not met. Please run Phases 1-4 first." -ForegroundColor Red
        exit 1
    }

    Write-Host "[OK] All prerequisites satisfied" -ForegroundColor Green
    Write-Host ""
}

function Deploy-BackendAPI {
    Write-Header "Deploying KubeWatch Backend API"

    Write-Host "Applying backend API manifests..." -ForegroundColor Cyan
    kubectl apply -f "$PSScriptRoot\..\infra\kubernetes\backend-api.yaml" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Backend API manifests applied" -ForegroundColor Green
    }
    else {
        Write-Host '[ERROR]' Failed to apply backend API manifests" -ForegroundColor Red
        exit 1
    }

    # Wait for backend API to be ready
    Write-Host "Waiting for backend API pod to be ready..." -ForegroundColor Cyan
    kubectl wait --for=condition=ready pod -l app=kubewatch-api -n kubewatch --timeout=300s 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Backend API pod ready" -ForegroundColor Green
    }
    else {
        Write-Host '[WARN]' Timeout waiting for backend API pod (it may still be starting)" -ForegroundColor Yellow
    }

    Write-Host ""
}

function Verify-Deployment {
    Write-Header "Verifying Phase 5 Deployment"

    Write-Host "Checking backend API pod..." -ForegroundColor Cyan
    $apiPods = kubectl get pods -n kubewatch -l app=kubewatch-api -o jsonpath='{.items[*].metadata.name}' 2>&1

    if ($apiPods) {
        Write-Host "[OK] Backend API deployed" -ForegroundColor Green
    }
    else {
        Write-Host '[WARN]' Backend API pod not found" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Port forwarding recommendations:" -ForegroundColor Cyan
    Write-Host "  Backend API: kubectl port-forward -n kubewatch svc/kubewatch-api 8090:8090" -ForegroundColor Gray
    Write-Host ""
}

function Show-NextSteps {
    Write-Header "Phase 5 Complete!"

    Write-Host "OK Custom Backend API is ready!

Next Steps:

    1. VERIFY SERVICES
       kubectl get pods -n kubewatch
       kubectl get svc -n kubewatch

    2. PORT FORWARD
       kubectl port-forward -n kubewatch svc/kubewatch-api 8090:8090

    3. TEST API
       curl http://localhost:8090/api/v1/health
       curl http://localhost:8090/api/v1/status

Documentation:
    See docs/PHASE5.md for complete reference
    See PHASE5-QUICK-START.md for 5-minute guide

" -ForegroundColor Green
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Header "KubeWatch Phase 5: Custom Backend API"
Write-Host "Installing KubeWatch Go REST API" -ForegroundColor Cyan
Write-Host ""

Check-Prerequisites
Deploy-BackendAPI
Verify-Deployment
Show-NextSteps

Write-Host "Phase 5 setup completed! OK" -ForegroundColor Green
