#!/usr/bin/env pwsh

# Quick reference for Phase 1 operations
# Usage: Run commands directly or source this file

# === Cluster Management ===

function kw-create {
    Write-Host "Creating KubeWatch cluster..."
    kind create cluster --config infra/kind/kind-config.yaml
}

function kw-delete {
    param([switch]$Force)
    if ($Force) {
        kind delete cluster --name kubewatch
    } else {
        $confirm = Read-Host "Delete cluster? (y/N)"
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            kind delete cluster --name kubewatch
        }
    }
}

function kw-status {
    Write-Host "=== Cluster Status ===" -ForegroundColor Cyan
    kubectl cluster-info
    Write-Host ""
    
    Write-Host "=== Nodes ===" -ForegroundColor Cyan
    kubectl get nodes -o wide
    Write-Host ""
    
    Write-Host "=== Namespaces ===" -ForegroundColor Cyan
    kubectl get namespaces
    Write-Host ""
    
    Write-Host "=== Resource Usage ===" -ForegroundColor Cyan
    kubectl top nodes 2>$null
}

# === Component Management ===

function kw-ingress-logs {
    Write-Host "=== Ingress-NGINX Logs ===" -ForegroundColor Cyan
    kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -f
}

function kw-ingress-status {
    Write-Host "=== Ingress-NGINX Status ===" -ForegroundColor Cyan
    kubectl get pods,svc -n ingress-nginx
}

function kw-cert-logs {
    Write-Host "=== Cert-Manager Logs ===" -ForegroundColor Cyan
    kubectl logs -n cert-manager -l app=cert-manager -f
}

function kw-cert-status {
    Write-Host "=== Cert-Manager Status ===" -ForegroundColor Cyan
    kubectl get pods -n cert-manager
    Write-Host ""
    kubectl get clusterissuer
}

# === Testing ===

function kw-test-ingress {
    Write-Host "Testing Ingress connectivity..." -ForegroundColor Cyan
    
    Write-Host "Deploying test application..."
    kubectl create deployment test-nginx --image=nginx -n default --dry-run=client -o yaml | kubectl apply -f -
    kubectl expose deployment test-nginx --port=80 -n default --dry-run=client -o yaml | kubectl apply -f -
    
    Write-Host "Creating ingress rule..."
    $ingressYaml = @'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: selfsigned
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - test.local
    secretName: test-tls
  rules:
  - host: test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-nginx
            port:
              number: 80
'@
    $ingressYaml | kubectl apply -f -
    
    Write-Host "Waiting for certificate..."
    Start-Sleep -Seconds 10
    
    Write-Host "Testing connection..."
    curl.exe -H "Host: test.local" http://localhost 2>$null | Select-Object -First 5
    
    Write-Host ""
    Write-Host "Testing result: $(if ($?) { 'SUCCESS OK' } else { 'FAILED' })"
}

function kw-test-storage {
    Write-Host "Testing Storage..." -ForegroundColor Cyan
    
    $pvcYaml = @'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: default
spec:
  storageClassName: local-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
'@
    $pvcYaml | kubectl apply -f -
    
    Write-Host "Waiting for PVC binding..."
    kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/test-pvc -n default --timeout=30s
    
    Write-Host "PVC binding result: $(if ($?) { 'SUCCESS OK' } else { 'FAILED' })"
    kubectl get pvc,pv -n default
}

function kw-test-metrics {
    Write-Host "Testing Metrics Server..." -ForegroundColor Cyan
    
    Write-Host "Waiting for metrics availability..."
    $attempt = 0
    while ($attempt -lt 6) {
        try {
            kubectl top nodes
            Write-Host "Metrics available OK"
            break
        }
        catch {
            $attempt++
            Write-Host "Attempt $attempt/6..."
            Start-Sleep -Seconds 5
        }
    }
}

# === Cleanup ===

function kw-cleanup-test {
    Write-Host "Cleaning up test resources..." -ForegroundColor Cyan
    kubectl delete ingress test-ingress -n default 2>$null
    kubectl delete deployment test-nginx -n default 2>$null
    kubectl delete service test-nginx -n default 2>$null
    kubectl delete pvc test-pvc -n default 2>$null
    Write-Host "Cleanup complete OK"
}

# === Shortcuts ===

function kw-describe-all {
    param([string]$Resource)
    kubectl describe $Resource -A
}

function kw-logs-all {
    param([string]$Label)
    kubectl logs -A -l $Label -f --tail=50
}

function kw-shell {
    param(
        [string]$Namespace = "default",
        [string]$Pod = ""
    )
    
    if ([string]::IsNullOrEmpty($Pod)) {
        Write-Host "Available pods in ${Namespace}:"
        kubectl get pods -n $Namespace --no-headers | ForEach-Object { $_.Split()[0] }
        $Pod = Read-Host "Enter pod name"
    }
    
    kubectl exec -it $Pod -n $Namespace -- /bin/sh
}

# === Information ===

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "         KubeWatch Phase 1 Quick Reference                 " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Cluster Management:" -ForegroundColor Green
Write-Host "  kw-create       - Create Kind cluster"
Write-Host "  kw-delete       - Delete cluster"
Write-Host "  kw-status       - Show cluster status"
Write-Host ""
Write-Host " Component Status:" -ForegroundColor Green
Write-Host "  kw-ingress-status  - Ingress-NGINX pods & services"
Write-Host "  kw-cert-status     - Cert-Manager pods & issuers"
Write-Host ""
Write-Host " Logs:" -ForegroundColor Green
Write-Host "  kw-ingress-logs - Stream Ingress-NGINX logs"
Write-Host "  kw-cert-logs    - Stream Cert-Manager logs"
Write-Host ""
Write-Host " Testing:" -ForegroundColor Green
Write-Host "  kw-test-ingress  - Test Ingress routing"
Write-Host "  kw-test-storage  - Test PVC binding"
Write-Host "  kw-test-metrics  - Test metrics-server"
Write-Host "  kw-cleanup-test  - Remove test resources"
Write-Host ""
Write-Host " Utilities:" -ForegroundColor Green
Write-Host "  kw-describe-all <resource>  - Describe all of a resource type"
Write-Host "  kw-logs-all <label>         - Stream logs by label"
Write-Host "  kw-shell [namespace] [pod]  - Open pod shell"
Write-Host ""
