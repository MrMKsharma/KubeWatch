# Phase 11: Disaster Recovery & Backups Setup
#
# Prerequisites: Phases 1‑10 must be running
# Time: ~3-5 minutes
#
# Usage:
#   cd C:\Users\sharm\Desktop\Test\KubeWatch
#   .\scripts\setup-phase11.ps1

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
Phase 11: Disaster Recovery & Backups Setup

DESCRIPTION
    Sets up Velero (or similar) and backup configurations for KubeWatch.

PREREQUISITES
    OK Phases 1‑10 must be deployed and running
    OK kubectl available and configured

COMPONENTS
    • Velero namespace and basic configuration
    • Backup schedule manifest
    • Example backup and restore manifests

USAGE
    .\setup-phase11.ps1                    # Run with defaults
    .\setup-phase11.ps1 -SkipHealthCheck   # Skip prerequisite validation

OPTIONS
    -Help              Show this help message
    -SkipHealthCheck   Skip prerequisite validation

AFTER DEPLOYMENT
    1. Load helper functions to manage backups:
       . .\scripts\phase11-functions.ps1
       kw11-list-backups
       kw11-backup-kubewatch

DOCUMENTATION
    See docs/PHASE11.md for complete guide
    See PHASE11-QUICK-START.md for 5-minute reference

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
        Write-Host "[FATAL] Prerequisites not met. Please run Phases 1‑10 first." -ForegroundColor Red
        exit 1
    }

    Write-Host "[OK] All prerequisites satisfied" -ForegroundColor Green
    Write-Host ""
}

function Deploy-Backup-Resources {
    Write-Header "Deploying Backup Resources"

    Write-Host "Applying backup manifests..." -ForegroundColor Cyan
    $backupPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "backups"
    kubectl apply -f $backupPath 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Backup manifests applied successfully" -ForegroundColor Green
    } else {
        Write-Host '[ERROR]' Failed to apply backup manifests" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
}

function Verify-Deployment {
    Write-Header "Verifying Phase 11 Deployment"

    Write-Host "Checking Velero namespace..." -ForegroundColor Cyan
    $veleroNs = kubectl get namespace velero -o jsonpath='{.metadata.name}' 2>&1
    if ($LASTEXITCODE -eq 0 -and $veleroNs) {
        Write-Host "[OK] Velero namespace exists" -ForegroundColor Green
    } else {
        Write-Host '[WARN]' Velero namespace not found" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Port forwarding recommendations (if needed):" -ForegroundColor Cyan
    Write-Host ""
}

function Show-NextSteps {
    Write-Header "Phase 11 Complete!"

    Write-Host "OK Disaster Recovery & Backups are ready!

Next Steps:

    1. LOAD HELPER FUNCTIONS
       . .\scripts\phase11-functions.ps1

    2. TRIGGER A BACKUP
       kw11-backup-kubewatch

    3. LIST BACKUPS
       kw11-list-backups

Documentation:
    See docs/PHASE11.md for complete reference
    See PHASE11-QUICK-START.md for 5-minute guide

" -ForegroundColor Green
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Header "KubeWatch Phase 11: Disaster Recovery & Backups"
Write-Host "Setting up backup resources..." -ForegroundColor Cyan
Write-Host ""

Check-Prerequisites
Deploy-Backup-Resources
Verify-Deployment
Show-NextSteps

Write-Host "Phase 11 setup completed! OK" -ForegroundColor Green
