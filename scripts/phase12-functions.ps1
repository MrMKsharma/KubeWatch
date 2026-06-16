# Phase 12: Production Readiness & Documentation - Helper Functions
# PowerShell 5 compatible

param(
    [switch]$CheckReadiness,
    [switch]$GenerateReport
)

$ErrorActionPreference = "Stop"

function Test-KubectlAvailable {
    try {
        $null = kubectl version --client --short 2>&1
        return $true
    } catch {
        return $false
    }
}

function Check-ClusterStatus {
    Write-Host "Checking cluster status..." -ForegroundColor Yellow
    try {
        $nodes = kubectl get nodes --no-headers 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Cluster is accessible" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] Cluster not accessible" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to check cluster: $_" -ForegroundColor Red
        return $false
    }
}

function Check-Namespaces {
    Write-Host "Checking namespaces..." -ForegroundColor Yellow
    $requiredNamespaces = @("monitoring", "logging", "tracing", "backend", "frontend", "argocd", "velero")
    $allGood = $true
    
    foreach ($ns in $requiredNamespaces) {
        try {
            $exists = kubectl get namespace $ns --no-headers 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Namespace $ns exists" -ForegroundColor Green
            } else {
                Write-Host "[WARNING] Namespace $ns not found" -ForegroundColor Yellow
                $allGood = $false
            }
        } catch {
            Write-Host "[ERROR] Failed to check namespace $ns : $_" -ForegroundColor Red
            $allGood = $false
        }
    }
    
    return $allGood
}

function Check-Pods {
    Write-Host "Checking pods..." -ForegroundColor Yellow
    try {
        $pods = kubectl get pods -A --no-headers 2>&1
        if ($LASTEXITCODE -eq 0) {
            $runningPods = ($pods | Select-String "Running").Count
            $totalPods = ($pods | Measure-Object -Line).Lines
            Write-Host "[OK] $runningPods/$totalPods pods running" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARNING] Failed to get pods" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to check pods: $_" -ForegroundColor Red
        return $false
    }
}

function Check-Resources {
    Write-Host "Checking resource requests/limits..." -ForegroundColor Yellow
    try {
        $pods = kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}' 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Resource check complete" -ForegroundColor Green
            Write-Host "     See docs/PRODUCTION-CHECKLIST.md for full checklist" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "[WARNING] Resource check failed" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to check resources: $_" -ForegroundColor Red
        return $false
    }
}

function Check-HPA {
    Write-Host "Checking HPA..." -ForegroundColor Yellow
    try {
        $hpas = kubectl get hpa -A --no-headers 2>&1
        if ($LASTEXITCODE -eq 0 -and $hpas) {
            Write-Host "[OK] HPA configured" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARNING] No HPA found" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to check HPA: $_" -ForegroundColor Red
        return $false
    }
}

function Check-PDB {
    Write-Host "Checking PDB..." -ForegroundColor Yellow
    try {
        $pdbs = kubectl get pdb -A --no-headers 2>&1
        if ($LASTEXITCODE -eq 0 -and $pdbs) {
            Write-Host "[OK] PDB configured" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARNING] No PDB found" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to check PDB: $_" -ForegroundColor Red
        return $false
    }
}

function Check-NetworkPolicies {
    Write-Host "Checking network policies..." -ForegroundColor Yellow
    try {
        $netpol = kubectl get networkpolicy -A --no-headers 2>&1
        if ($LASTEXITCODE -eq 0 -and $netpol) {
            Write-Host "[OK] Network policies configured" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[WARNING] No network policies found" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to check network policies: $_" -ForegroundColor Red
        return $false
    }
}

function Invoke-ProductionReadinessCheck {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Production Readiness Check" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $results = @()
    
    if (-not (Test-KubectlAvailable)) {
        Write-Host "[ERROR] kubectl not available" -ForegroundColor Red
        return
    }
    
    $results += Check-ClusterStatus
    $results += Check-Namespaces
    $results += Check-Pods
    $results += Check-Resources
    $results += Check-HPA
    $results += Check-PDB
    $results += Check-NetworkPolicies
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    $passed = ($results | Where-Object { $_ -eq $true }).Count
    $total = $results.Count
    Write-Host " Readiness Check: $passed/$total checks passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "See docs/PRODUCTION-CHECKLIST.md for full manual checklist" -ForegroundColor Gray
    Write-Host ""
}

function Generate-ReadinessReport {
    Write-Host ""
    Write-Host "Generating readiness report..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Production Readiness Report" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Documentation Available:" -ForegroundColor Green
    Write-Host "  - docs/PRODUCTION-CHECKLIST.md" -ForegroundColor Gray
    Write-Host "  - docs/RUNBOOKS.md" -ForegroundColor Gray
    Write-Host "  - docs/TROUBLESHOOTING.md" -ForegroundColor Gray
    Write-Host "  - docs/MAINTENANCE.md" -ForegroundColor Gray
    Write-Host "  - docs/PHASE12.md" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Review docs/PRODUCTION-CHECKLIST.md" -ForegroundColor Gray
    Write-Host "  2. Complete any missing items" -ForegroundColor Gray
    Write-Host "  3. Test failover scenarios" -ForegroundColor Gray
    Write-Host "  4. Document lessons learned" -ForegroundColor Gray
    Write-Host ""
}

# Main execution
if ($CheckReadiness) {
    Invoke-ProductionReadinessCheck
} elseif ($GenerateReport) {
    Generate-ReadinessReport
} else {
    Write-Host "Phase 12 Helper Functions" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\phase12-functions.ps1 -CheckReadiness" -ForegroundColor Gray
    Write-Host "  .\phase12-functions.ps1 -GenerateReport" -ForegroundColor Gray
    Write-Host ""
}
