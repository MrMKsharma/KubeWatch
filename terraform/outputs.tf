output "cluster_name" {
  description = "Name of the Kind cluster"
  value       = kind_cluster.kubewatch.name
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = kind_cluster.kubewatch.kubeconfig_path
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = kind_cluster.kubewatch.endpoint
}
