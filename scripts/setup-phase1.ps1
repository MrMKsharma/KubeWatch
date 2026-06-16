#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Phase 1 Setup Script - Creates Kind cluster with Helm components
.DESCRIPTION
    Sets up a production-ready local Kubernetes environment with:
    - Kind cluster (single node)
    - Namespaces (monitoring, logging, tracing, gitops)
    - Ingress-NGINX
    - Cert-Manager (TLS)
    - Metrics-Server (resource metrics)
    - Local Storage (PV provisioner)
.EXAMPLE
    .\setup-phase1.ps1
.AUTHOR
    KubeWatch Team
#>

param(
    [switch]$Force = $false,
    [switch]$SkipPrerequisiteCheck = $false,
    [switch]$Debug = $false
)

# Configuration
$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"

# Color constants
$Colors = @{
    Info    = "`e[32m"  # Green
    Warn    = "`e[33m"  # Yellow
    Error   = "`e[31m"  # Red
    Reset   = "`e[0m"   # Reset
}

function Write-Info {
    param([string]$Message)
    Write-Host "$($Colors.Info)[INFO]$($Colors.Reset) $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "$($Colors.Warn)[WARN]$($Colors.Reset) $Message"
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "$($Colors.Error)[ERROR]$($Colors.Reset) $Message"
}

function Write-Debug-Custom {
    param([string]$Message)
    if ($Debug) {
        Write-Host "[DEBUG] $Message" -ForegroundColor Gray
    }
}

function Check-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    $missing = @()
    
    foreach ($tool in @("kind", "kubectl", "helm")) {
        if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
            $missing += $tool
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Error-Custom "Missing required tools: $($missing -join ', ')"
        Write-Info "Install from:"
        Write-Info "  - Kind: https://kind.sigs.k8s.io/"
        Write-Info "  - Kubectl: https://kubernetes.io/docs/tasks/tools/"
        Write-Info "  - Helm: https://helm.sh/"
        exit 1
    }
    
    Write-Info "Prerequisites check passed OK"
}

function Setup-Storage {
    Write-Info "Setting up storage directory..."
    
    # Windows paths
    $storageDir = "C:\tmp\kubewatch-storage"
    
    if (-not (Test-Path $storageDir)) {
        New-Item -ItemType Directory -Path $storageDir -Force | Out-Null
        Write-Debug-Custom "Created storage directory: $storageDir"
    }
    
    Write-Info "Storage directory ready: $storageDir OK"
    return $storageDir
}

function Create-Cluster {
    Write-Info "Checking for existing Kind clusters..."
    
    # First, check current kubectl context
    try {
        $currentContext = kubectl config current-context 2>$null
        Write-Debug-Custom "Current kubectl context: $currentContext"
        if ($currentContext -like "kind-*") {
            $clusterName = $currentContext -replace "^kind-", ""
            Write-Info "Using existing cluster from kubectl context: $clusterName OK"
            return
        }
    }
    catch {
        Write-Debug-Custom "No current kubectl context found"
    }
    
    # Check if any kind clusters exist
    try {
        $clusters = kind get clusters 2>$null
        Write-Debug-Custom "Found clusters: $($clusters -join ', ')"
    }
    catch {
        Write-Debug-Custom "No existing clusters found"
        $clusters = @()
    }
    
    if ($clusters.Count -gt 0) {
        $clusterName = $clusters[0]
        Write-Info "Using existing cluster: $clusterName OK"
        kind export kubeconfig --name $clusterName
        return
    }
    
    Write-Info "No existing clusters found, creating new cluster..."
    
    # Get the script directory - nested Join-Path for PowerShell 5 compatibility
    $configPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kind") "kind-config.yaml"
    
    if (-not (Test-Path $configPath)) {
        Write-Error-Custom "Config file not found: $configPath"
        exit 1
    }
    Write-Debug-Custom "Using kind config: $configPath"
    
    # Try to create cluster
    try {
        kind create cluster --config $configPath
        Write-Info "Kind cluster created OK"
    }
    catch {
        Write-Error-Custom "Failed to create kind cluster: $_"
        exit 1
    }
}

function Wait-ForCluster {
    Write-Info "Waiting for cluster to be ready..."
    
    $maxAttempts = 60
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        $attempt++
        Write-Debug-Custom "Waiting for cluster... Attempt $attempt/$maxAttempts"
        
        try {
            $clusterInfo = kubectl cluster-info 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Debug-Custom "Cluster is responding"
                break
            }
        }
        catch {
            Write-Debug-Custom "Cluster not responding yet: $_"
        }
        
        Start-Sleep -Seconds 3
    }
    
    if ($attempt -eq $maxAttempts) {
        Write-Error-Custom "Cluster not ready after $($maxAttempts * 3) seconds"
        exit 1
    }
    
    Write-Info "Cluster is responding OK"
    
    # Wait for nodes to be ready
    Write-Info "Waiting for nodes to be ready..."
    kubectl wait --for=condition=ready node --all --timeout=300s
    Write-Info "Nodes are ready OK"
}

function Create-Namespaces {
    Write-Info "Creating namespaces..."
    
    $nsPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "namespaces.yaml"
    Write-Debug-Custom "Applying namespaces from: $nsPath"
    
    kubectl apply -f $nsPath
    Write-Info "Namespaces created OK"
}

function Add-HelmRepos {
    Write-Info "Adding Helm repositories..."
    
    $repos = @(
        @{ name = "ingress-nginx"; url = "https://kubernetes.github.io/ingress-nginx" },
        @{ name = "jetstack"; url = "https://charts.jetstack.io" },
        @{ name = "prometheus-community"; url = "https://prometheus-community.github.io/helm-charts" }
    )
    
    foreach ($repo in $repos) {
        Write-Debug-Custom "Adding repo: $($repo.name)"
        helm repo add $repo.name $repo.url 2>$null
    }
    
    helm repo update
    Write-Info "Helm repositories added OK"
}

function Install-IngressNginx {
    Write-Info "Installing ingress-nginx..."
    
    $valuesPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "helm") "ingress-nginx-values.yaml"
    Write-Debug-Custom "Using values file: $valuesPath"
    
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
        --namespace ingress-nginx `
        --values $valuesPath `
        --wait `
        --timeout 5m
    
    Write-Info "ingress-nginx installed OK"
}

function Install-CertManager {
    Write-Info "Installing cert-manager..."
    
    $valuesPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "helm") "cert-manager-values.yaml"
    Write-Debug-Custom "Using values file: $valuesPath"
    
    helm upgrade --install cert-manager jetstack/cert-manager `
        --namespace cert-manager `
        --values $valuesPath `
        --wait `
        --timeout 5m
    
    Write-Info "cert-manager installed OK"
}

function Install-MetricsServer {
    Write-Info "Installing metrics-server..."
    
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.4/components.yaml
    
    # Wait for deployment
    kubectl rollout status deployment/metrics-server -n kube-system --timeout=2m
    
    Write-Info "metrics-server installed OK"
}

function Apply-Configs {
    Write-Info "Applying storage and TLS configurations..."
    
    $storageConfigPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "storage-class.yaml"
    $certIssuerPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "cert-issuer.yaml"
    
    Write-Debug-Custom "Applying storage config: $storageConfigPath"
    Write-Debug-Custom "Applying cert issuer: $certIssuerPath"
    
    kubectl apply -f $storageConfigPath
    kubectl apply -f $certIssuerPath
    
    Write-Info "Configurations applied OK"
}

function Print-Summary {
    Write-Info "Phase 1 Setup Complete! OK"
    
    Write-Host ""
    Write-Host "======================================"
    Write-Host "Cluster Information:"
    Write-Host "======================================"
    kubectl cluster-info
    
    Write-Host ""
    Write-Host "======================================"
    Write-Host "Namespaces:"
    Write-Host "======================================"
    kubectl get namespaces
    
    Write-Host ""
    Write-Host "======================================"
    Write-Host "Nodes:"
    Write-Host "======================================"
    kubectl get nodes -o wide
    
    Write-Host ""
    Write-Host "======================================"
    Write-Host "Ingress-NGINX Pods:"
    Write-Host "======================================"
    kubectl get pods -n ingress-nginx
    
    Write-Host ""
    Write-Host "======================================"
    Write-Host "Cert-Manager Pods:"
    Write-Host "======================================"
    kubectl get pods -n cert-manager
    
    Write-Host ""
    Write-Host "======================================"
    Write-Host "Storage:"
    Write-Host "======================================"
    kubectl get storageclass,pv
    
    Write-Host ""
    Write-Host "======================================"
    Write-Host "Next Steps:"
    Write-Host "======================================"
    Write-Info "Cluster is ready for Phase 2"
    Write-Info "  Run: kubectl get pods -A"
    Write-Info "  To verify all components are running"
    Write-Info ""
    Write-Info "Run: .\scripts\setup-phase2.ps1"
    Write-Info "  Installing kube-prometheus-stack"
}

# Main execution
try {
    if (-not $SkipPrerequisiteCheck) {
        Check-Prerequisites
    }
    
    Setup-Storage | Out-Null
    Create-Cluster
    Wait-ForCluster
    Create-Namespaces
    Add-HelmRepos
    Install-IngressNginx
    Install-CertManager
    Install-MetricsServer
    Apply-Configs
    Print-Summary
}
catch {
    Write-Error-Custom "Setup failed: $_"
    Write-Error-Custom "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
