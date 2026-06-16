# Phase 8 Helper Functions for KubeWatch IaC (Terraform)
#
# Usage:
#   . .\scripts\phase8-functions.ps1

function Show-Phase8Menu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  KubeWatch Phase 8 - IaC Functions" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Commands:"
    Write-Host "  kw8-init        - Run `terraform init`"
    Write-Host "  kw8-plan        - Run `terraform plan`"
    Write-Host "  kw8-apply       - Run `terraform apply`"
    Write-Host "  kw8-destroy     - Run `terraform destroy`"
    Write-Host "  kw8-output      - Run `terraform output`"
    Write-Host "  kw8-check       - Check Terraform and cluster status"
    Write-Host "  kw8-help        - Show this menu"
    Write-Host ""
}

function kw8-init {
    Write-Host "Initializing Terraform..." -ForegroundColor Cyan
    $terraformPath = Join-Path (Join-Path $PSScriptRoot "..") "terraform"
    Set-Location $terraformPath
    terraform init
}

function kw8-plan {
    Write-Host "Running Terraform plan..." -ForegroundColor Cyan
    $terraformPath = Join-Path (Join-Path $PSScriptRoot "..") "terraform"
    Set-Location $terraformPath
    terraform plan
}

function kw8-apply {
    Write-Host "Applying Terraform configuration..." -ForegroundColor Cyan
    $terraformPath = Join-Path (Join-Path $PSScriptRoot "..") "terraform"
    Set-Location $terraformPath
    terraform apply
}

function kw8-destroy {
    Write-Host "Destroying Terraform resources..." -ForegroundColor Yellow
    Write-Host "WARNING: This will delete your Kind cluster and namespaces!" -ForegroundColor Red
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        $terraformPath = Join-Path (Join-Path $PSScriptRoot "..") "terraform"
        Set-Location $terraformPath
        terraform destroy
    } else {
        Write-Host "Destroy cancelled"
    }
}

function kw8-output {
    Write-Host "Showing Terraform outputs..." -ForegroundColor Cyan
    $terraformPath = Join-Path (Join-Path $PSScriptRoot "..") "terraform"
    Set-Location $terraformPath
    terraform output
}

function kw8-check {
    Write-Host "Checking status..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Terraform Status:" -ForegroundColor Yellow
    $terraformPath = Join-Path (Join-Path $PSScriptRoot "..") "terraform"
    if (Test-Path (Join-Path $terraformPath ".terraform")) {
        Write-Host "  Terraform initialized: OK" -ForegroundColor Green
    } else {
        Write-Host "  Terraform initialized: NO (run kw8-init)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Kubernetes Status:" -ForegroundColor Yellow
    try {
        kubectl cluster-info 2>&1 | Out-Null
        if ($?) {
            Write-Host "  Cluster reachable: OK" -ForegroundColor Green
            Write-Host "  Cluster nodes:"
            kubectl get nodes
            Write-Host "  Cluster namespaces:"
            kubectl get namespaces
        }
    }
    catch {
        Write-Host "  Cluster reachable: NO" -ForegroundColor Red
    }
}

# Auto-run menu if script is executed directly
if ($MyInvocation.InvocationName -ne ".") {
    Show-Phase8Menu
}
