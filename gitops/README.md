# GitOps (Argo CD) Manifests

This directory contains Argo CD application definitions for managing KubeWatch deployments using GitOps.

## Structure
- `applications/` - All Argo CD Application manifests
  - `root-app.yaml` - App of Apps pattern (bootstraps everything)
  - `kubewatch-app.yaml` - Main KubeWatch application
  - `monitoring-app.yaml` - Prometheus + Grafana stack
  - `logging-app.yaml` - Loki + Promtail stack
  - `tracing-app.yaml` - Grafana Tempo stack

## Getting Started
1. Update the `repoURL` field in all YAML files to point to your repository
2. Apply the root app first:
   ```bash
   kubectl apply -f gitops/applications/root-app.yaml
   ```
3. Argo CD will automatically sync all other applications
