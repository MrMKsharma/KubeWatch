variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "kubewatch"
}

variable "kind_node_image" {
  description = "Kind node image to use"
  type        = string
  default     = "kindest/node:v1.28.0"
}
