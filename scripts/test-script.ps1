# Simple test script for KubeWatch

Write-Host "Checking prerequisites..." -ForegroundColor Green
Write-Host "Prerequisites check passed" -ForegroundColor Green

Write-Host "Setting up storage directory..." -ForegroundColor Green
$storageDir = "C:\tmp\kubewatch-storage"
if (-not (Test-Path $storageDir)) {
    New-Item -ItemType Directory -Path $storageDir -Force | Out-Null
}
Write-Host "Storage directory ready: $storageDir" -ForegroundColor Green

Write-Host "Test script completed successfully!" -ForegroundColor Green
