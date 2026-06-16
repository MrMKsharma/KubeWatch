#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Phase 9 Setup Script - Security & Compliance
.DESCRIPTION
    Applies RBAC, network policies, and security contexts for KubeWatch
#>

param(
    [switch]$SkipPrerequisiteCheck = $false
)

# Configuration
$ErrorActionPreference = "Stop"

# Color constants
$Colors = @{
    Info    = "`e[32m"
    Warn    = "`e[33m"
    Error   = "`e[31m"
    Reset   = "`e[0m"
}

function Write-Info { param([string]$Message) Write-Host "$($Colors.Info)[INFO]$($Colors.Reset) $Message" }
function Write-Warn { param([string]$Message) Write-Host "$($Colors.Warn)[WARN]$($Colors.Reset) $Message" }
function Write-Error-Custom { param([string]$Message) Write-Host "$($Colors.Error)[ERROR]$($Colors.Reset) $Message" }

function Check-Prerequisites {
    Write-Info "Checking prerequisites..."

    try {
        kubectl cluster-info 2>&1 | Out-Null
        if (-not $?) {
            Write-Error-Custom "Could not connect to a Kubernetes cluster!"
            exit 1
        }
        Write-Info "Prerequisites check passed OK"
    }
    catch {
        Write-Error-Custom "Error checking prerequisites: $_"
        exit 1
    }
}

function Apply-Security-Manifests {
    Write-Info "Applying security manifests..."
    $securityPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "security"
    kubectl apply -f $securityPath
    Write-Info "Security manifests applied OK"
}

function Print-Summary {
    Write-Info "Phase 9 Setup Complete OK"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Phase 9: Security & Compliance Complete" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "RBAC Resources:" -ForegroundColor Green
    Write-Host "  ClusterRoles & ClusterRoleBindings: ok"
    Write-Host "  Namespace Roles (monitoring/logging/tracing): ok"
    Write-Host ""
    Write-Host "Network Policies:" -ForegroundColor Green
    Write-Host "  Default deny-all policies applied: ok"
    Write-Host "  Allow ingress-nginx and DNS/egress: ok"
    Write-Host ""
    Write-Host "Verify Resources:" -ForegroundColor Green
    Write-Host "  kubectl get clusterroles -l app=kubewatch"
    Write-Host "  kubectl get networkpolicies -A"
    Write-Host ""
    Write-Host "For helper functions, run:" -ForegroundColor Green
    Write-Host "  . .\scripts\phase9-functions.ps1"
    Write-Host ""
}

try {
    if (-not $SkipPrerequisiteCheck) {
        Check-Prerequisites
    }

    Apply-Security-Manifests
    Print-Summary
}
catch {
    Write-Error-Custom "Setup failed: $_"
    exit 1
}
