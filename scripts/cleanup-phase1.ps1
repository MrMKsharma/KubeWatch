#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Clean up Phase 1 resources
.DESCRIPTION
    Deletes the Kind cluster and storage directory
#>

param(
    [switch]$Force = $false
)

# Configuration
$ErrorActionPreference = "Stop"

function Write-Info { Write-Host "[INFO] $_" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $_" -ForegroundColor Yellow }

try {
    Write-Info "Cleaning up Phase 1 resources..."
    
    if (-not $Force) {
        $confirm = Read-Host "Delete Kind cluster 'kubewatch'? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Warn "Cleanup cancelled"
            exit 0
        }
    }
    
    # Delete cluster
    $clusters = kind get clusters 2>$null
    if ($clusters -contains "kubewatch") {
        Write-Info "Deleting cluster..."
        kind delete cluster --name kubewatch
    }
    
    # Clean storage
    $storageDir = "C:\tmp\kubewatch-storage"
    if (Test-Path $storageDir) {
        Write-Info "Removing storage directory..."
        Remove-Item -Recurse -Force $storageDir
    }
    
    Write-Info "Cleanup complete OK"
}
catch {
    Write-Host "[ERROR] $_" -ForegroundColor Red
    exit 1
}
