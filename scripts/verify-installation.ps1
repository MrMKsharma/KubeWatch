# KubeWatch Installation Verification Script
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "KubeWatch Installation Verification" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if frontend is running
Write-Host "[1/3] Checking if frontend is accessible..." -ForegroundColor Green
try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3001" -UseBasicParsing -TimeoutSec 5
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "✅ Frontend is running at http://localhost:3001" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Frontend returned status code: $($frontendResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Frontend not accessible: $_" -ForegroundColor Red
    Write-Host "  Try running: cd frontend; npm run dev" -ForegroundColor Gray
}
Write-Host ""

# Check if backend is running
Write-Host "[2/3] Checking if backend API is accessible..." -ForegroundColor Green
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:8090/api/v1/health" -UseBasicParsing -TimeoutSec 5
    if ($healthResponse.StatusCode -eq 200) {
        $healthData = $healthResponse.Content | ConvertFrom-Json
        Write-Host "✅ Backend API is running at http://localhost:8090" -ForegroundColor Green
        Write-Host "   Status: $($healthData.status)" -ForegroundColor Gray
        Write-Host "   Version: $($healthData.version)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️ Backend returned status code: $($healthResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Backend not accessible: $_" -ForegroundColor Red
    Write-Host "  Try running: cd backend/api; go run main.go" -ForegroundColor Gray
}
Write-Host ""

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Verification Complete" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎉 KubeWatch is ready to use!" -ForegroundColor Green
Write-Host "   Open http://localhost:3001 in your browser" -ForegroundColor Cyan
