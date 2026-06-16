# Phase 9: Security & Compliance - Complete Guide

---

## Table of Contents
1. [Why Security Matters](#why-security-matters)
2. [Key Concepts](#key-concepts)
3. [Prerequisites](#prerequisites)
4. [Step‑by‑Step Deployment](#step-by-step-deployment)
5. [RBAC Explained](#rbac-explained)
6. [Network Policies Explained](#network-policies-explained)
7. [Cleanup](#cleanup)

---

## Why Security Matters

Even in a local cluster, it's important to follow security best practices to prevent mistakes from having unintended consequences! For production deployments, these security measures are essential.

## Key Concepts

1. **RBAC**: Role‑Based Access Control – restrict who can do what in your cluster
2. **Network Policies**: Control pod‑to‑pod communication
3. **Security Contexts**: Control how pods/containers run (user ID, capabilities, etc.)

## Prerequisites
1. ✅ Phase 1 complete (Ingress‑NGINX)
2. ✅ `kubectl` configured

## Step‑by‑Step Deployment

### Step 1: Run the Setup Script
```bash
cd C:\Users\sharm\Desktop\Test\KubeWatch
.\scripts\setup-phase9.ps1
```

### Step 2: Verify RBAC
```bash
kubectl get clusterroles -l app=kubewatch
kubectl get clusterrolebindings -l app=kubewatch
kubectl get roles,rolebindings -A -l app=kubewatch
```

### Step 3: Verify Network Policies
```bash
kubectl get networkpolicies -A
```

## RBAC Explained

What we have:
- **ClusterRole `kubewatch-admin`**: Full access to KubeWatch resources
- **ClusterRoleBinding `kubewatch-admin`**: Binds `kubewatch-admin` to a user
- **Namespace‑scoped roles for read‑only access** (in monitoring/logging/tracing/argocd)

## Network Policies Explained

What we have:
- **Default deny all network policy** in all KubeWatch namespaces
- **Allow policies** for necessary ingress/egress (e.g., ingress‑nginx, monitoring scraping)

## Cleanup
To delete security resources (if needed):
```bash
kubectl delete -f infra/kubernetes/security/
```
