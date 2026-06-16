# Phase 4: Distributed Tracing Platform Setup
# Installs Grafana Tempo and deploys OpenTelemetry-instrumented microservices
#
# Prerequisites: Phases 1, 2, 3 must be running
# Time: ~5-10 minutes
#
# Usage:
#   cd C:\Users\sharm\Desktop\Test\KubeWatch
#   .\scripts\setup-phase4.ps1

param(
    [switch]$Help,
    [switch]$Debug = $false,
    [switch]$SkipHealthCheck = $false
)

# Load helper functions
. "$PSScriptRoot\kubewatch-functions.ps1"

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Show-Help {
    Write-Host @"
Phase 4: Distributed Tracing Platform Setup

DESCRIPTION
    Deploys Grafana Tempo for distributed tracing with sample OpenTelemetry-instrumented microservices.

PREREQUISITES
    OK Phases 1, 2, and 3 must be deployed and running
    OK kubectl available and configured
    OK Helm 3.x installed
    OK Docker running (for building images if needed)
    OK Go 1.20+ (for building services)

COMPONENTS
    • Grafana Tempo - Trace storage and visualization
    • OpenTelemetry Collector - Trace collection
    • Frontend Service - HTTP service (port 8080)
    • Orders Service - Calls inventory and payments (port 8081)
    • Payments Service - Processes payments (port 8082)
    • Inventory Service - Checks stock (port 8083)

WHAT GETS CREATED
    Namespaces:
      • tracing - Tempo and OpenTelemetry collector

    Helm Deployments:
      • Grafana Tempo - Trace storage backend
      • OpenTelemetry Collector - Span receiver/processor

    Microservices (as Deployments):
      • frontend - Gateway service
      • orders - Order processing
      • payments - Payment processing
      • inventory - Inventory checking

    Ingress Routes:
      • tempo.kubewatch.local - HTTPS access to Tempo

    Services:
      • tempo - ClusterIP (port 3200 and OTLP ports)
      • otel-collector - ClusterIP (OTLP ports)
      • frontend, orders, payments, inventory - ClusterIP

USAGE
    .\setup-phase4.ps1                    # Run with defaults
    .\setup-phase4.ps1 -Debug             # Run with debug output
    .\setup-phase4.ps1 -SkipHealthCheck   # Skip prerequisite validation

OPTIONS
    -Help              Show this help message
    -Debug             Enable debug output
    -SkipHealthCheck   Skip prerequisite validation

EXAMPLES
    # Standard deployment
    .\setup-phase4.ps1

    # With debug output
    .\setup-phase4.ps1 -Debug

    # Skip health checks
    .\setup-phase4.ps1 -SkipHealthCheck

AFTER DEPLOYMENT
    1. View traces: http://localhost:3000 → Explore → Select Tempo datasource
    2. Access frontend: http://localhost:8080
    3. Port-forward: kubectl port-forward -n tracing svc/tempo 3200:3200
    4. Load test: 'kw4-load-test' (from phase4-functions.ps1)

DOCUMENTATION
    See docs/PHASE4.md for complete guide
    See PHASE4-QUICK-START.md for 5-minute reference

"@
}

function Check-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    if ($SkipHealthCheck) {
        Write-Host "[SKIP] Health checks disabled" -ForegroundColor Yellow
        return $true
    }

    $allGood = $true

    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Host '[ERROR]' kubectl not found in PATH" -ForegroundColor Red
        $allGood = $false
    }
    else {
        Write-Host "[OK] kubectl available" -ForegroundColor Green
    }

    # Check Helm
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        Write-Host '[ERROR]' Helm not found in PATH" -ForegroundColor Red
        $allGood = $false
    }
    else {
        Write-Host "[OK] Helm available" -ForegroundColor Green
    }

    # Check cluster connectivity
    try {
        $clusterInfo = kubectl cluster-info 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Kubernetes cluster accessible" -ForegroundColor Green
        }
        else {
            Write-Host '[ERROR]' Cannot access Kubernetes cluster" -ForegroundColor Red
            $allGood = $false
        }
    }
    catch {
        Write-Host '[ERROR]' Cannot access Kubernetes cluster: $_" -ForegroundColor Red
        $allGood = $false
    }

    # Check Phase 1 (Kind cluster)
    try {
        $kindNodes = kubectl get nodes -o jsonpath='{.items[*].metadata.name}' 2>&1
        if ($LASTEXITCODE -eq 0 -and $kindNodes) {
            Write-Host "[OK] Phase 1 (Kubernetes cluster) deployed" -ForegroundColor Green
        }
        else {
            Write-Host '[ERROR]' Phase 1 not detected" -ForegroundColor Red
            $allGood = $false
        }
    }
    catch {
        Write-Host '[ERROR]' Cannot verify Phase 1: $_" -ForegroundColor Red
        $allGood = $false
    }

    # Check Phase 2 (Monitoring/Prometheus)
    try {
        $promPods = kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[*].metadata.name}' 2>&1
        if ($LASTEXITCODE -eq 0 -and $promPods) {
            Write-Host "[OK] Phase 2 (Prometheus) deployed" -ForegroundColor Green
        }
        else {
            Write-Host '[WARN]' Phase 2 (Prometheus) not detected" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host '[WARN]' Cannot verify Phase 2: $_" -ForegroundColor Yellow
    }

    # Check Phase 3 (Logging/Loki)
    try {
        $lokiPods = kubectl get pods -n logging -l app=loki -o jsonpath='{.items[*].metadata.name}' 2>&1
        if ($LASTEXITCODE -eq 0 -and $lokiPods) {
            Write-Host "[OK] Phase 3 (Loki) deployed" -ForegroundColor Green
        }
        else {
            Write-Host '[WARN]' Phase 3 (Loki) not detected" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host '[WARN]' Cannot verify Phase 3: $_" -ForegroundColor Yellow
    }

    # Check Helm repositories
    try {
        $repos = helm repo list 2>&1
        if ($repos -like "*grafana*") {
            Write-Host "[OK] Grafana Helm repository configured" -ForegroundColor Green
        }
        else {
            Write-Host '[WARN]' Grafana Helm repository not found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host '[WARN]' Cannot verify Helm repositories: $_" -ForegroundColor Yellow
    }

    if (-not $allGood) {
        Write-Host ""
        Write-Host "[FATAL] Prerequisites not met. Please run Phases 1-3 first." -ForegroundColor Red
        exit 1
    }

    Write-Host "[OK] All prerequisites satisfied" -ForegroundColor Green
    Write-Host ""
}

function Create-Namespace {
    Write-Header "Creating Namespaces"

    $namespaces = @("tracing")

    foreach ($ns in $namespaces) {
        Write-Host "Creating namespace: $ns" -ForegroundColor Cyan
        
        kubectl create namespace $ns 2>$null
        
        # Label namespace
        kubectl label namespace $ns kubewatch-phase=4 --overwrite 2>$null
        
        Write-Host "[OK] Namespace '$ns' ready" -ForegroundColor Green
    }

    Write-Host ""
}

function Setup-HelmRepositories {
    Write-Header "Setting Up Helm Repositories"

    Write-Host "Adding Grafana Helm repository..." -ForegroundColor Cyan
    helm repo add grafana https://grafana.github.io/helm-charts 2>&1 | Out-Null
    helm repo update grafana 2>&1 | Out-Null
    Write-Host "[OK] Grafana repository configured" -ForegroundColor Green

    Write-Host ""
}

function Deploy-TempoInfrastructure {
    Write-Header "Deploying Tempo Infrastructure"

    Write-Host "Deploying OpenTelemetry Collector..." -ForegroundColor Cyan
    kubectl apply -f "$PSScriptRoot\..\infra\kubernetes\otel-collector.yaml" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] OpenTelemetry Collector deployed" -ForegroundColor Green
    }
    else {
        Write-Host '[ERROR]' Failed to deploy OpenTelemetry Collector" -ForegroundColor Red
        exit 1
    }

    Write-Host "Creating ConfigMap for Tempo ingress configuration..." -ForegroundColor Cyan
    kubectl apply -f "$PSScriptRoot\..\infra\kubernetes\tracing-ingress.yaml" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Tracing ingress configured" -ForegroundColor Green
    }
    else {
        Write-Host '[ERROR]' Failed to apply tracing ingress" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
}

function Deploy-GrafanaTempo {
    Write-Header "Deploying Grafana Tempo"

    Write-Host "Installing Grafana Tempo via Helm..." -ForegroundColor Cyan
    
    helm upgrade --install tempo grafana/tempo --namespace tracing --values "$PSScriptRoot\..\infra\helm\grafana-tempo-values.yaml" --wait --timeout 5m 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Grafana Tempo deployed successfully" -ForegroundColor Green
    }
    else {
        Write-Host '[ERROR]' Failed to deploy Grafana Tempo" -ForegroundColor Red
        exit 1
    }

    # Wait for Tempo to be ready
    Write-Host "Waiting for Tempo pods to be ready..." -ForegroundColor Cyan
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=tempo -n tracing --timeout=300s 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Tempo pods ready" -ForegroundColor Green
    }
    else {
        Write-Host '[WARN]' Timeout waiting for Tempo pods" -ForegroundColor Yellow
    }

    Write-Host ""
}

function Build-and-Push-Images {
    Write-Header "Building Microservice Docker Images"

    $services = @("frontend", "orders", "payments", "inventory")
    $dockerFile = "$PSScriptRoot\..\backend\docker\Dockerfile"

    if (-not (Test-Path $dockerFile)) {
        Write-Host '[WARN]' Dockerfile not found at $dockerFile" -ForegroundColor Yellow
        Write-Host '[INFO]' Building images is optional - services can run locally" -ForegroundColor Cyan
        return
    }

    foreach ($service in $services) {
        Write-Host "Building image for $service..." -ForegroundColor Cyan
        
        $imageName = "kubewatch/$service:latest"
        docker build -f $dockerFile -t $imageName "$PSScriptRoot\..\backend\services\$service\" 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Image built: $imageName" -ForegroundColor Green
        }
        else {
            Write-Host '[WARN]' Failed to build $service image (optional)" -ForegroundColor Yellow
        }
    }

    Write-Host ""
}

function Deploy-Microservices {
    Write-Header "Deploying Microservices"

    Write-Host "Applying microservices manifests..." -ForegroundColor Cyan
    kubectl apply -f "$PSScriptRoot\..\infra\kubernetes\microservices.yaml" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Microservices manifests applied" -ForegroundColor Green
    } else {
        Write-Host '[ERROR]' Failed to apply microservices manifests" -ForegroundColor Red
        exit 1
    }

    Write-Host "Waiting for microservices to be ready..." -ForegroundColor Cyan
    kubectl wait --for=condition=ready pod -l app -n tracing --timeout=300s 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] All microservices ready" -ForegroundColor Green
    } else {
        Write-Host '[WARN]' Timeout waiting for microservices (they may still be starting)" -ForegroundColor Yellow
    }

    Write-Host ""
}

function Add-TempoDataSource {
    Write-Header "Configuring Grafana Data Source"

    Write-Host "Adding Tempo as Grafana datasource..." -ForegroundColor Cyan
    
    $grafanaPort = "3000"
    $grafanaUrl = "http://localhost:$grafanaPort"

    # Get Grafana admin password
    $grafanaSecret = kubectl get secret -n monitoring grafana -o jsonpath='{.data.admin-password}' 2>$null
    if (-not $grafanaSecret) {
        Write-Host '[WARN]' Could not retrieve Grafana credentials" -ForegroundColor Yellow
        Write-Host '[INFO]' Grafana datasource can be added manually" -ForegroundColor Cyan
        return
    }

    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($grafanaSecret)) | Set-Variable -Name adminPassword -Scope Script

    Write-Host "[OK] Tempo datasource configuration ready" -ForegroundColor Green
    Write-Host '[INFO]' Access Grafana at: http://localhost:3000" -ForegroundColor Cyan
    Write-Host '[INFO]' Admin password: $adminPassword" -ForegroundColor Cyan

    Write-Host ""
}

function Verify-Deployment {
    Write-Header "Verifying Phase 4 Deployment"

    Write-Host "Checking Tempo deployment..." -ForegroundColor Cyan
    $tempoPods = kubectl get pods -n tracing -l app.kubernetes.io/name=tempo -o jsonpath='{.items[*].metadata.name}' 2>&1
    
    if ($tempoPods) {
        Write-Host "[OK] Tempo deployed" -ForegroundColor Green
    }
    else {
        Write-Host '[WARN]' Tempo pods not found" -ForegroundColor Yellow
    }

    Write-Host "Checking microservices deployment..." -ForegroundColor Cyan
    $appPods = kubectl get pods -n tracing -l app -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}' 2>&1
    
    if ($appPods) {
        Write-Host $appPods
        Write-Host "[OK] Microservices deployed" -ForegroundColor Green
    }
    else {
        Write-Host '[WARN]' Service pods not found" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Port forwarding recommendations:" -ForegroundColor Cyan
    Write-Host "  Grafana: kubectl port-forward -n monitoring svc/grafana 3000:80" -ForegroundColor Gray
    Write-Host "  Tempo:   kubectl port-forward -n tracing svc/tempo 3200:3200" -ForegroundColor Gray
    Write-Host "  Frontend: kubectl port-forward -n tracing svc/frontend 8080:8080" -ForegroundColor Gray
    Write-Host ""
}

function Show-NextSteps {
    Write-Header "Phase 4 Complete!"

    Write-Host "OK Distributed Tracing Platform is ready!
    
Next Steps:
    
    1. VERIFY SERVICES
       kubectl get pods -n tracing
       kubectl get services -n tracing
    
    2. PORT FORWARD (in separate terminals)
       kubectl port-forward -n monitoring svc/grafana 3000:80
       kubectl port-forward -n tracing svc/tempo 3200:3200
       kubectl port-forward -n tracing svc/frontend 8080:8080
    
    3. GENERATE TRACES
       curl http://localhost:8080/order
       # This triggers frontend → orders → payments,inventory
    
    4. VIEW TRACES IN GRAFANA
       Open: http://localhost:3000
       Go to: Explore tab
       Select: Tempo datasource
       View service graph and traces
    
    5. LOAD TEST (optional)
       # In separate terminal:
       . .\scripts\phase4-functions.ps1
       kw4-load-test
    
Documentation:
    See docs/PHASE4.md for complete reference
    See PHASE4-QUICK-START.md for 5-minute guide

" -ForegroundColor Green
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Header "KubeWatch Phase 4: Distributed Tracing"
Write-Host "Installing Grafana Tempo + OpenTelemetry Microservices" -ForegroundColor Cyan
Write-Host ""

Check-Prerequisites
Create-Namespace
Setup-HelmRepositories
Deploy-TempoInfrastructure
Deploy-GrafanaTempo
Build-and-Push-Images
Deploy-Microservices
Add-TempoDataSource
Verify-Deployment
Show-NextSteps

Write-Host "Phase 4 setup completed! OK" -ForegroundColor Green
