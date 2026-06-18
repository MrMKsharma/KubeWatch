# KubeWatch Simple Demo Script
Write-Host "======================================" -ForegroundColor Magenta
Write-Host "  KubeWatch Demo" -ForegroundColor Magenta
Write-Host "======================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "Step 1: Opening documentation..." -ForegroundColor Cyan
Write-Host "  - README.md" -ForegroundColor Gray
Write-Host "  - docs/CLIENT_DEMO_GUIDE.md" -ForegroundColor Gray
Write-Host "  - docs/PRODUCTION-CHECKLIST.md" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 2: Check services..." -ForegroundColor Cyan
try {
    $r = Invoke-WebRequest -Uri "http://localhost:3001" -UseBasicParsing -TimeoutSec 5
    if ($r.StatusCode -eq 200) {
        Write-Host "  ✅ Frontend running at http://localhost:3001" -ForegroundColor Green
        Start-Process "http://localhost:3001"
    }
} catch {
    Write-Host "  ⚠️ Frontend not running" -ForegroundColor Yellow
}

try {
    $r = Invoke-WebRequest -Uri "http://localhost:8090/api/v1/health" -UseBasicParsing -TimeoutSec 5
    if ($r.StatusCode -eq 200) {
        $d = $r.Content | ConvertFrom-Json
        Write-Host "  ✅ Backend API running (Status: $($d.status))" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠️ Backend not running" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Magenta
Write-Host "Open docs/CLIENT_DEMO_GUIDE.md for the full guide!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Magenta
