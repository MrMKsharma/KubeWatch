#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Phase 7 Setup Script - GitOps with ArgoCD
.DESCRIPTION
    Installs and configures ArgoCD for GitOps workflows
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
        $ingressPods = kubectl get pods -n ingress-nginx 2>&1
        if (-not $?) {
            Write-Error-Custom "Phase 1 (Ingress-NGINX) not found. Please run Phase 1 first."
            Write-Info "  .\scripts\setup-phase1.ps1"
            exit 1
        }
        Write-Info "Prerequisites check passed OK"
    }
    catch {
        Write-Error-Custom "Error checking prerequisites: $_"
        exit 1
    }
}

function Add-ArgoCD-Helm-Repo {
    Write-Info "Adding ArgoCD Helm repository..."
    helm repo add argo https://argoproj.github.io/argo-helm 2>&1 | Out-Null
    helm repo update 2>&1 | Out-Null
    Write-Info "Helm repository added OK"
}

function Install-ArgoCD {
    Write-Info "Installing ArgoCD..."
    $valuesPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "helm") "argocd-values.yaml"

    helm upgrade --install argocd argo/argo-cd `
        --namespace argocd `
        --create-namespace `
        --values $valuesPath `
        --wait `
        --timeout 10m 2>&1 | Out-Null

    Write-Info "ArgoCD installed OK"
}

function Apply-Ingress {
    Write-Info "Applying ArgoCD ingress..."
    $ingressPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "argocd-ingress.yaml"
    kubectl apply -f $ingressPath 2>&1 | Out-Null
    Write-Info "Ingress applied OK"
}

function Print-Summary {
    Write-Info "Phase 7 Setup Complete OK"
    Write-Host ""

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Phase 7: GitOps with ArgoCD Complete" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "ArgoCD Pods:" -ForegroundColor Green
    kubectl get pods -n argocd
    Write-Host ""

    Write-Host "Get Admin Password:" -ForegroundColor Green
    Write-Host "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    Write-Host ""

    Write-Host "Access ArgoCD UI:" -ForegroundColor Green
    Write-Host "  1. Port Forwarding:"
    Write-Host "     kubectl port-forward svc/argocd-server -n argocd 8080:443"
    Write-Host "     Then open: https://localhost:8080"
    Write-Host ""
    Write-Host "  2. Via Ingress (if configured):"
    Write-Host "     https://argocd.kubewatch.local"
    Write-Host ""

    Write-Host "Login Credentials:" -ForegroundColor Green
    Write-Host "  Username: admin"
    Write-Host "  Password: [from above command]"
    Write-Host ""

    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "  1. Log into ArgoCD UI"
    Write-Host "  2. Create an Application for KubeWatch components"
    Write-Host "  3. Check docs/PHASE7.md for complete guide"
    Write-Host ""
}

try {
    if (-not $SkipPrerequisiteCheck) {
        Check-Prerequisites
    }

    Add-ArgoCD-Helm-Repo
    Install-ArgoCD
    Apply-Ingress
    Print-Summary
}
catch {
    Write-Error-Custom "Setup failed: $_"
    exit 1
}
