# Phase 7 Helper Functions for KubeWatch GitOps (ArgoCD)
#
# Usage:
#   . .\scripts\phase7-functions.ps1

function Show-Phase7Menu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  KubeWatch Phase 7 - GitOps Functions" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Commands:"
    Write-Host "  kw7-port-forward        - Port forward ArgoCD UI to localhost:8080"
    Write-Host "  kw7-get-password        - Retrieve initial admin password"
    Write-Host "  kw7-check-status        - Check ArgoCD status"
    Write-Host "  kw7-apply-example       - Apply example ArgoCD Application"
    Write-Host "  kw7-help                - Show this menu"
    Write-Host ""
}

function kw7-port-forward {
    Write-Host "Port forwarding ArgoCD UI to port 8080..." -ForegroundColor Cyan
    Write-Host "Access UI at: https://localhost:8080" -ForegroundColor Green
    Write-Host ""
    kubectl port-forward svc/argocd-server -n argocd 8080:443
}

function kw7-get-password {
    Write-Host "Retrieving ArgoCD initial admin password..." -ForegroundColor Cyan
    $password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>&1
    if (-not $password) {
        Write-Host "[ERROR] Could not retrieve password" -ForegroundColor Red
        return
    }
    $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
    Write-Host "ArgoCD Admin Password: $decoded" -ForegroundColor Green
    Write-Host ""
}

function kw7-check-status {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  ArgoCD Status" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "ArgoCD Pods:" -ForegroundColor Yellow
    kubectl get pods -n argocd
    Write-Host ""

    Write-Host "ArgoCD Services:" -ForegroundColor Yellow
    kubectl get svc -n argocd
    Write-Host ""

    Write-Host "ArgoCD Applications:" -ForegroundColor Yellow
    kubectl get applications -n argocd 2>&1
    Write-Host ""
}

function kw7-apply-example {
    Write-Host "Applying example ArgoCD Application..." -ForegroundColor Cyan
    $examplePath = Join-Path (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "infra") "kubernetes") "argocd-application-example.yaml"
    if (-not (Test-Path $examplePath)) {
        Write-Host "[ERROR] Example Application not found: $examplePath" -ForegroundColor Red
        return
    }
    Write-Host "WARNING: Edit argocd-application-example.yaml to set your repo URL first!" -ForegroundColor Yellow
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        kubectl apply -f $examplePath
        Write-Host "Example Application applied OK" -ForegroundColor Green
    } else {
        Write-Host "Aborted"
    }
}

# Auto-run menu if script is executed directly
if ($MyInvocation.InvocationName -ne ".") {
    Show-Phase7Menu
}
