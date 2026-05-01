variable "namespace" {
  description = "Kubernetes namespace for monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "kube_prometheus_stack_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "84.5.0"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "7d"
}

variable "prometheus_storage_size" {
  description = "Prometheus persistent storage size (or emptyDir sizeLimit if ephemeral)"
  type        = string
  default     = "20Gi"
}

variable "grafana_storage_size" {
  description = "Grafana persistent storage size"
  type        = string
  default     = "5Gi"
}

variable "alertmanager_storage_size" {
  description = "Alertmanager persistent storage size (or emptyDir sizeLimit if ephemeral)"
  type        = string
  default     = "2Gi"
}

variable "use_ephemeral_storage" {
  description = "Use emptyDir instead of PVCs (zero block-storage cost; data lost on pod restart)"
  type        = bool
  default     = false
}

variable "enable_node_exporter" {
  description = "Enable node-exporter DaemonSet. Requires hostNetwork/hostPID/hostPath (PSS privileged). Disabled by default; metrics-server covers kubectl top and HPA without host access."
  type        = bool
  default     = false
}
