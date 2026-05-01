variable "namespace" {
  description = "Namespace to deploy OpenCost into"
  type        = string
  default     = "opencost"
}

variable "opencost_version" {
  description = "Version of the OpenCost Helm chart"
  type        = string
  default     = "2.5.17"
}

variable "cluster_id" {
  description = "Cluster ID for OpenCost identification"
  type        = string
}

variable "prometheus_service_name" {
  description = "Prometheus service name for data source"
  type        = string
  default     = "kube-prometheus-stack-prometheus"
}

variable "prometheus_namespace" {
  description = "Prometheus namespace"
  type        = string
  default     = "monitoring"
}
