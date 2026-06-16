# Phase 8: Infrastructure as Code (IaC) with Terraform - Complete Guide

---

## Table of Contents
1. [What is Terraform?](#what-is-terraform)
2. [Why use Terraform with KubeWatch?](#why-use-terraform-with-kubewatch)
3. [Prerequisites](#prerequisites)
4. [Step‑by‑Step Deployment](#step-by-step-deployment)
5. [Terraform Configuration Explained](#terraform-configuration-explained)
6. [Cleanup](#cleanup)

---

## What is Terraform?

Terraform is an open‑source infrastructure as code tool that lets you define both cloud and on‑premises resources in human‑readable configuration files that you can version, reuse, and share.

## Why use Terraform with KubeWatch?

- **Reproducibility**: Create identical environments every time
- **Version Control**: Track infrastructure changes in Git
- **Automation**: No more manual `kubectl apply` runs
- **Idempotent**: Apply the same config multiple times safely

## Prerequisites
1. ✅ `terraform` installed (https://developer.hashicorp.com/terraform/downloads)
2. ✅ `kind` installed
3. ✅ `kubectl` configured

## Step‑by‑Step Deployment

### Step 1: Run the Setup Script
```bash
cd C:\Users\sharm\Desktop\Test\KubeWatch
.\scripts\setup-phase8.ps1
```

### Step 2: Initialize Terraform
```bash
cd C:\Users\sharm\Desktop\Test\KubeWatch\terraform
terraform init
```

### Step 3: Review the Plan
```bash
terraform plan
```

### Step 4: Apply the Configuration
```bash
terraform apply
```

### Step 5: Verify
```bash
kubectl get nodes
kubectl get namespaces
```

## Terraform Configuration Explained

### `terraform/main.tf`
Defines the resources:
- Kind cluster (using `tehcyx/kind` provider)
- Namespaces

### `terraform/variables.tf`
Defines configurable inputs (e.g., cluster name, node count).

### `terraform/outputs.tf`
Shows useful values after apply (e.g., cluster name, kubeconfig path).

## Cleanup
To delete everything created by Terraform:
```bash
terraform destroy
```
