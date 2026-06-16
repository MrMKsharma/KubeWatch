# KubeWatch

## 🚀 Production-Grade Kubernetes Observability Platform

KubeWatch is a comprehensive, end-to-end observability solution for Kubernetes clusters, designed and built with real-world SRE practices in mind.

---

## 💡 The Problem It Solves

Managing Kubernetes clusters at scale comes with critical observability challenges:
1. **Silos**: Metrics, logs, and traces are scattered across multiple tools
2. **Complexity**: Setting up a production-grade stack requires deep expertise
3. **Lack of Custom Integration**: No single pane of glass tailored for SRE workflows
4. **No GitOps/IaC**: Manual deployments lead to configuration drift and errors
5. **Missing Cost & SLO Management**: No built-in tools for tracking spend or error budgets

---

## 🎯 How KubeWatch Solves It

KubeWatch unifies all your observability needs into a single, cohesive platform:
1. **Unified Dashboard**: Beautiful React frontend that aggregates metrics, logs, and traces
2. **Custom Go API**: Built-in endpoints for health, status, metrics, nodes, and alerts
3. **GitOps Ready**: Fully automated deployments via ArgoCD
4. **Infrastructure as Code**: Terraform modules for consistent cluster provisioning
5. **Production Hardened**: Network policies, RBAC, resource limits, and pod security standards
6. **Cost & SLO Aware**: Designed with cost tracking and SLO management in mind

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│           KubeWatch Frontend            │
│         (React + TypeScript)            │
└──────────────────────┬──────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────┐
│         Custom Go Backend API           │
│    (OpenTelemetry Instrumented)         │
└──────────────────────┬──────────────────┘
                       │
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
┌────────────┐  ┌───────────┐  ┌──────────┐
│  Prometheus│  │   Loki    │  │  Tempo   │
│  (Metrics) │  │  (Logs)   │  │ (Traces) │
└────────────┘  └───────────┘  └──────────┘
       ▲               ▲               ▲
       └───────────────┴───────────────┘
                       │
          ┌────────────┴────────────┐
          │  Kubernetes Clusters    │
          │  (Kind / EKS / GKE)    │
          └─────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technologies |
|-------|--------------|
| **Orchestration** | Kubernetes (Kind for local, EKS/GKE for production) |
| **Metrics** | Prometheus, kube-state-metrics, Node Exporter |
| **Logging** | Grafana Loki, Promtail |
| **Tracing** | Grafana Tempo, OpenTelemetry |
| **GitOps** | ArgoCD |
| **IaC** | Terraform |
| **Backend** | Go + Gorilla Mux |
| **Frontend** | React + TypeScript + Vite |
| **Package Manager** | Helm 3 |
| **Visualization** | Grafana |

---

## 🚀 Quick Start (Local Demo)

### Prerequisites
- Node.js 18+
- Go 1.21+
- Docker Desktop (for Kind)
- Kind (optional, if you want to try full cluster)

### 1. Run Backend API
```bash
cd backend/api
go run main.go
```
API will be running at http://localhost:8090

### 2. Run Frontend
```bash
cd frontend
npm install
npm run dev
```
Frontend will be running at http://localhost:3000

---

## 🌟 Key Features

- ✅ **Real-time Dashboard**: Beautiful dark theme with live metrics
- ✅ **Metrics Visualization**: CPU, Memory, Network charts (1hr history)
- ✅ **Cluster Overview**: Node status and pod counts
- ✅ **Alerts Feed**: Recent alerts with severity indicators
- ✅ **Services Status**: Health of all observability components
- ✅ **Auto-refresh**: Data updates every 30 seconds
- ✅ **GitOps Ready**: ArgoCD configurations provided
- ✅ **IaC Included**: Terraform modules for cloud clusters
- ✅ **Production Hardened**: Security policies and resource limits

---

## 📦 Repository Structure

```
kubewatch/
├── backend/
│   ├── api/              # Custom Go Backend
│   ├── services/         # Demo Microservices
│   └── docker/           # Dockerfiles
├── frontend/
│   └── src/              # React + TypeScript App
├── infra/
│   ├── helm/             # Helm values
│   ├── kind/             # Kind cluster config
│   ├── kubernetes/       # Manifests
│   └── terraform/        # Terraform modules
├── monitoring/
│   ├── alerts/           # Prometheus rules
│   └── dashboards/       # Grafana dashboards
├── docs/
├── scripts/
└── tests/
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

---

## 👨‍💻 Author

**[Manish Sharma](https://www.linkedin.com/in/manishsharma31/)**

Passionate about Kubernetes, observability, and building tools that make SRE lives easier!
