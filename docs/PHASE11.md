# Phase 11: Disaster Recovery & Backups – Complete Guide

---

## Table of Contents
1. [What's in this Phase?](#whats-in-this-phase)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Backing Up KubeWatch](#backing-up-kubewatch)
5. [Restoring from Backup](#restoring-from-backup)
6. [Verification](#verification)

---

## What's in this Phase?
This phase implements disaster recovery and backup capabilities for KubeWatch using Velero! We'll cover both Kubernetes resource backups and basic persistent volume (PV) snapshots.

---

## Prerequisites
1. ✅ Phases 1‑10 complete
2. ✅ `kubectl` configured and connected to your cluster

---

## Step-by-Step Deployment

### Step 1: Run the Setup Script
```bash
cd C:\Users\sharm\Desktop\Test\KubeWatch
.\scripts\setup-phase11.ps1
```

This deploys Velero with local storage (for our Kind cluster) and configures it!

---

## Backing Up KubeWatch
### Create an On-Demand Backup
Load the helper functions:
```bash
. .\scripts\phase11-functions.ps1
```
Then, run:
```bash
kw11-backup-kubewatch
```
This creates a backup of all KubeWatch‑related namespaces!

### Scheduled Backups
The setup also creates a schedule that runs a backup daily!

---

## Restoring from Backup
### List All Backups
First, see what backups you have:
```bash
kw11-list-backups
```

### Restore a Specific Backup
To restore from a backup named "kubewatch-backup-XXXXXXX":
```bash
kw11-restore-backup --name kubewatch-backup-XXXXXXX
```

---

## Verification
After restoring, verify all resources are back!
```bash
# Check deployments
kubectl get deployments -A
# Check namespaces
kubectl get namespaces
```

---

## Next Steps
Next up: **Phase 12 – Production Readiness & Documentation**!
