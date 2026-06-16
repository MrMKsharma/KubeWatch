# Phase 10 Helper Functions for Performance Testing & Optimization
#
# Usage:
#   . .\scripts\phase10-functions.ps1

function Show-Phase10Menu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  KubeWatch Phase 10 – Performance Functions" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Commands:"
    Write-Host "  kw10-check-hpa         – Check Horizontal Pod Autoscalers"
    Write-Host "  kw10-check-resources   – Check resource requests/limits"
    Write-Host "  kw10-run-load-test     – Run a k6 load test (if k6 installed)"
    Write-Host "  kw10-help              – Show this menu"
    Write-Host ""
}

function kw10-check-hpa {
    Write-Host "Checking Horizontal Pod Autoscalers..." -ForegroundColor Cyan
    kubectl get hpa -A
}

function kw10-check-resources {
    Write-Host "Checking resource requests and limits..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "KubeWatch Namespace:" -ForegroundColor Yellow
    kubectl get pods -n kubewatch -o custom-columns=NAME:.metadata.name,CPU_REQ:.spec.containers[0].resources.requests.cpu,MEM_REQ:.spec.containers[0].resources.requests.memory,CPU_LIMIT:.spec.containers[0].resources.limits.cpu,MEM_LIMIT:.spec.containers[0].resources.limits.memory
}

function kw10-run-load-test {
    $k6Installed = Get-Command k6 -ErrorAction SilentlyContinue
    if (-not $k6Installed) {
        Write-Host "[ERROR] k6 is not installed. Please install k6 from https://k6.io/docs/getting-started/installation/" -ForegroundColor Red
        return
    }

    Write-Host "Starting load test..." -ForegroundColor Cyan
    $testPath = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "tests") "performance\k6-test.js"
    if (-not (Test-Path $testPath)) {
        Write-Host "[ERROR] Test script not found at $testPath" -ForegroundColor Red
        return
    }
    Write-Host "Running k6 test from $testPath..." -ForegroundColor Cyan
    k6 run $testPath
}

function kw10-help {
    Show-Phase10Menu
}

# Auto‑run menu if script is executed directly
if ($MyInvocation.InvocationName -ne ".") {
    Show-Phase10Menu
}
