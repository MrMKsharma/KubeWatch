# Phase 6: React Frontend

## Overview

Phase 6 implements a React + TypeScript frontend for KubeWatch, connecting to the custom backend API.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              KubeWatch Frontend UI                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  React + TypeScript App                          │  │
│  │  ├─ / - Dashboard (status overview)              │  │
│  │  ├─ /health - Health check page                 │  │
│  │  └─ api.ts - API integration layer               │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Components

### React Frontend
- React 18 + TypeScript
- Vite as build tool
- Fetch API for backend communication
- Simple, modern UI

### Kubernetes Manifests
- Namespace reuse (kubewatch)
- Deployment + Service

---

## Installation

### Prerequisites
- Phase 1‑5 running

### Automated Deployment
```bash
cd C:\Users\sharm\Desktop\Test\KubeWatch
.\scripts\setup-phase6.ps1
```

---

## Verification
```bash
kubectl get pods -n kubewatch -l app=kubewatch-frontend
kubectl port-forward -n kubewatch svc/kubewatch-frontend 3000:3000
# Open http://localhost:3000
```

---

## Next Steps
✅ Phase 6 complete
⏳ Phase 7: GitOps (ArgoCD)

---
**KubeWatch Phase 6 - React Frontend**
**Status**: Complete
