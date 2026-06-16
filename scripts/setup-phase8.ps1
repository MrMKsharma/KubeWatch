#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Phase 8 Setup Script - Infrastructure as Code (IaC) with Terraform
.DESCRIPTION
    Automates Terraform initialization and deployment for KubeWatch
#>

param(
    [switch]$SkipPrerequisiteCheck = $false
)

# Configuration
$ErrorActionPreference = "Stop"

# Color constants
$Colors = @{
    Info    = "`e[32m"
    Warn    = "`e[33m"
    Error   = "`e[31m"
    Reset   = "`e[0m"
}

function Write-Info { param([string]$Message) Write-Host "$($Colors.Info)[INFO]$($Colors.Reset) $Message" }
function Write-Warn { param([string]$Message) Write-Host "$($Colors.Warn)[WARN]$($Colors.Reset) $Message" }
function Write-Error-Custom { param([string]$Message) Write-Host "$($Colors.Error)[ERROR]$($Colors.Reset) $Message" }

function Check-Prerequisites {
    Write-Info "Checking prerequisites..."

    $missing = @()
    foreach ($tool in @("terraform", "kind")) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            $missing += $tool
        }
    }

    if ($missing.Count -gt 0) {
        Write-Error-Custom "Missing required tools: $($missing -join ', ')"
        Write-Info "Install Terraform: https://developer.hashicorp.com/terraform/downloads"
        Write-Info "Install Kind: https://kind.sigs.k8s.io/"
        exit 1
    }

    Write-Info "Prerequisites check passed OK"
}

function Initialize-Terraform {
    Write-Info "Initializing Terraform..."
    $terraformPath = Join-Path (Join-Path $PSScriptRoot "..") "terraform"
    Set-Location $terraformPath
    terraform init
    Write-Info "Terraform initialized OK"
}

function Run-Terraform-Plan {
    Write-Info "Running Terraform plan..."
    terraform plan
    Write-Info "Plan complete OK"
}

function Ask-To-Apply {
    $apply = Read-Host "Apply the Terraform configuration? (y/N)"
    if ($apply -eq "y" -or $apply -eq "Y") {
        Write-Info "Applying Terraform configuration..."
        terraform apply -auto-approve
        Write-Info "Apply complete OK"
    }
    else {
        Write-Info "Apply cancelled"
    }
}

function Print-Summary {
    Write-Info "Phase 8 Setup Complete OK"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Phase 8: IaC with Terraform Complete" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Terraform Configuration Location:" -ForegroundColor Green
    Write-Host "  $PWD"
    Write-Host ""
    Write-Host "Useful Terraform Commands:" -ForegroundColor Green
    Write-Host "  terraform plan      - Preview changes"
    Write-Host "  terraform apply     - Apply changes"
    Write-Host "  terraform destroy   - Destroy resources"
    Write-Host "  terraform output    - Show output values"
    Write-Host ""
    Write-Host "For helper functions, run:" -ForegroundColor Green
    Write-Host "  . .\scripts\phase8-functions.ps1"
    Write-Host ""
}

try {
    if (-not $SkipPrerequisiteCheck) {
        Check-Prerequisites
    }

    Initialize-Terraform
    Run-Terraform-Plan
    Ask-To-Apply
    Print-Summary
}
catch {
    Write-Error-Custom "Setup failed: $_"
    exit 1
}
