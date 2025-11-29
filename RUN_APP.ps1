# Dhan-AI App Runner Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Dhan-AI - App Runner Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if in correct directory
$currentDir = Get-Location
Write-Host "Current directory: $currentDir" -ForegroundColor Yellow

if (-not $currentDir.ToString().EndsWith("dhan_ai")) {
    Write-Host "⚠️  WARNING: Not in dhan_ai directory!" -ForegroundColor Red
    Write-Host "Changing to dhan_ai directory..." -ForegroundColor Yellow
    Set-Location "C:\Users\adity\Desktop\dhan_ai"
}

# Clean build
Write-Host ""
Write-Host "Step 1: Cleaning build cache..." -ForegroundColor Green
flutter clean

Write-Host ""
Write-Host "Step 2: Getting dependencies..." -ForegroundColor Green
flutter pub get

Write-Host ""
Write-Host "Step 3: Running app on device..." -ForegroundColor Green
Write-Host "Device: RZCXA1SNX6H" -ForegroundColor Cyan
Write-Host ""
flutter run -d RZCXA1SNX6H

