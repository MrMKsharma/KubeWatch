# Phase 7: GitOps with ArgoCD - Complete Guide

---

## Table of Contents
1. [What is GitOps?](#what-is-gitops)
2. [Why ArgoCD?](#why-argocd)
3. [Prerequisites](#prerequisites)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [ArgoCD UI](#argocd-ui)
6. [Creating Your First Application](#creating-your-first-application)
7. [Best Practices](#best-practices)

---

## What is GitOps?

GitOps is a set of practices that uses Git as a single source of truth for declarative infrastructure and application deployments. With GitOps:
- All Kubernetes manifests are stored in Git
- Changes are reviewed and approved via PRs
- Rollbacks are simple Git reverts
- Cluster state is continuously synced with Git

## Why ArgoCD?

ArgoCD is a GitOps continuous delivery tool for Kubernetes:
- Declarative, Git-based deployments
- Automated syncing and drift detection
- Beautiful web UI
- Great for multi-cluster environments
- Integrates with all major Git providers (GitHub, GitLab, etc.)

## Prerequisites
1. ✅ Phase 1 complete (Ingress-NGINX running)
2. ✅ `kubectl` configured
3. ✅ `helm` installed

## Step-by-Step Deployment

### Step 1: Run Setup Script
```bash
cd C:\Users\sharm\Desktop\Test\KubeWatch
.\scripts\setup-phase7.ps1
```

### Step 2: Verify Installation
Check pods in the `argocd` namespace:
```bash
kubectl get pods -n argocd
```

### Step 3: Get Admin Credentials
Retrieve the initial admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Step 4: Access the UI
Option 1: Port Forwarding
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then open: https://localhost:8080

Option 2: Via Ingress (if configured)
Open: https://argocd.kubewatch.local in your browser

## ArgoCD UI

### Login
- **Username**: `admin`
- **Password**: from Step 3

### Key Sections
1. **Applications**: List of managed applications and their sync status
2. **Settings**: Configure ArgoCD (repos, clusters, projects)
3. **User Info**: Manage account settings

## Creating Your First Application

### Example Application (KubeWatch Backend API)
Create an ArgoCD Application manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kubewatch-backend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/kubewatch.git
    targetRevision: HEAD
    path: infra/kubernetes
  destination:
    server: https://kubernetes.default.svc
    namespace: kubewatch
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Best Practices
1. **Always use Git**: Store all manifests in Git
2. **Automate Syncing**: Use ArgoCD's auto-sync for continuous delivery
3. **Use Projects**: Organize applications into projects (default, production, etc.)
4. **Enable Pruning**: Let ArgoCD delete resources removed from Git
5. **Self-Heal**: Automatically fix drift between Git and cluster state
