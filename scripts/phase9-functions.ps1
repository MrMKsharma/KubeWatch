# Phase 9 Helper Functions for KubeWatch Security
#
# Usage:
#   . .\scripts\phase9-functions.ps1

function Show-Phase9Menu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  KubeWatch Phase 9 - Security Functions" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Commands:"
    Write-Host "  kw9-check        - Check all security resources"
    Write-Host "  kw9-apply        - Re-apply security manifests"
    Write-Host "  kw9-help         - Show this menu"
    Write-Host ""
}

function kw9-check {
    Write-Host "Checking security resources..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "=== RBAC ===" -ForegroundColor Yellow
    Write-Host "ClusterRoles (kubewatch):"
    kubectl get clusterroles -l app=kubewatch
    Write-Host "ClusterRoleBindings (kubewatch):"
    kubectl get clusterrolebindings -l app=kubewatch
    Write-Host "Namespace Roles & RoleBindings (kubewatch):"
    kubectl get roles,rolebindings -A -l app=kubewatch
    Write-Host ""

    Write-Host "=== Network Policies ===" -ForegroundColor Yellow
    kubectl get networkpolicies -A
    Write-Host ""
}

function kw9-apply {
    Write-Host "Re-applying security manifests..." -ForegroundColor Cyan
    $securityPath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "security"
    kubectl apply -f $securityPath
    Write-Host "Security manifests applied OK" -ForegroundColor Green
}

# Auto-run menu if script is executed directly
if ($MyInvocation.InvocationName -ne ".") {
    Show-Phase9Menu
}
