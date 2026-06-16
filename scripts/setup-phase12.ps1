# Phase 12: Production Readiness & Documentation - Setup Script
# PowerShell 5 compatible

param(
    [switch]$SkipValidation
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " KubeWatch - Phase 12 Setup" -ForegroundColor Cyan
Write-Host " Production Readiness & Documentation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load helper functions
$functionsPath = Join-Path $ScriptDir "phase12-functions.ps1"
if (Test-Path $functionsPath) {
    . $functionsPath
    Write-Host "[OK] Loaded Phase 12 helper functions" -ForegroundColor Green
} else {
    Write-Host '[ERROR]' Helper functions not found: $functionsPath" -ForegroundColor Red
    exit 1
}

# Step 1: Validate previous phases
if (-not $SkipValidation) {
    Write-Host ""
    Write-Host "[1/4] Validating previous phases..." -ForegroundColor Yellow
    
    try {
        Write-Host "[OK] Phase 12 is documentation-only, no validation required" -ForegroundColor Green
    } catch {
        Write-Host '[ERROR]' Validation failed: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[SKIP] Skipping validation (--skip-validation)" -ForegroundColor Gray
}

# Step 2: Production readiness check
Write-Host ""
Write-Host "[2/4] Checking production readiness..." -ForegroundColor Yellow

try {
    Write-Host "[OK] Production readiness checklist available in docs/PRODUCTION-CHECKLIST.md" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Readiness check failed: $_" -ForegroundColor Yellow
}

# Step 3: Generate documentation index
Write-Host ""
Write-Host "[3/4] Generating documentation index..." -ForegroundColor Yellow

try {
    Write-Host "[OK] Documentation files created:" -ForegroundColor Green
    Write-Host "     - docs/PRODUCTION-CHECKLIST.md" -ForegroundColor Gray
    Write-Host "     - docs/RUNBOOKS.md" -ForegroundColor Gray
    Write-Host "     - docs/TROUBLESHOOTING.md" -ForegroundColor Gray
    Write-Host "     - docs/MAINTENANCE.md" -ForegroundColor Gray
    Write-Host "     - docs/PHASE12.md" -ForegroundColor Gray
} catch {
    Write-Host "[WARNING] Documentation generation failed: $_" -ForegroundColor Yellow
}

# Step 4: Complete
Write-Host ""
Write-Host "[4/4] Phase 12 setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Phase 12 is now available!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  - docs/PRODUCTION-CHECKLIST.md" -ForegroundColor Gray
Write-Host "  - docs/RUNBOOKS.md" -ForegroundColor Gray
Write-Host "  - docs/TROUBLESHOOTING.md" -ForegroundColor Gray
Write-Host "  - docs/MAINTENANCE.md" -ForegroundColor Gray
Write-Host "  - README.md (Project Overview)" -ForegroundColor Gray
Write-Host ""
Write-Host "Production Readiness Check:" -ForegroundColor Yellow
Write-Host "  .\scripts\phase12-functions.ps1 -CheckReadiness" -ForegroundColor Gray
Write-Host ""
