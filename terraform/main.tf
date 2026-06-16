# KubeWatch Phase 8: Terraform Configuration
# Kind Cluster & Namespaces

terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.5.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
  }
}

# Configure Kind provider
provider "kind" {
}

# Configure Kubernetes provider using the Kind cluster
provider "kubernetes" {
  host = kind_cluster.kubewatch.endpoint
  client_certificate = kind_cluster.kubewatch.client_certificate
  client_key = kind_cluster.kubewatch.client_key
  cluster_ca_certificate = kind_cluster.kubewatch.cluster_ca_certificate
}

# Create Kind Cluster
resource "kind_cluster" "kubewatch" {
  name = var.cluster_name

  node_config {
    image = var.kind_node_image
  }
}

# Create core KubeWatch Namespaces
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      name = "monitoring"
    }
  }
}

resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
    labels = {
      name = "logging"
    }
  }
}

resource "kubernetes_namespace" "tracing" {
  metadata {
    name = "tracing"
    labels = {
      name = "tracing"
    }
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      name = "argocd"
    }
  }
}

resource "kubernetes_namespace" "gitops" {
  metadata {
    name = "gitops"
    labels = {
      name = "gitops"
    }
  }
}

resource "kubernetes_namespace" "ingress-nginx" {
  metadata {
    name = "ingress-nginx"
    labels = {
      name = "ingress-nginx"
    }
  }
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
    labels = {
      name = "cert-manager"
    }
  }
}
