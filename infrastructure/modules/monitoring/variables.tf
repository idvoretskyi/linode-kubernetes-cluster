variable "namespace" {
  description = "Namespace to deploy monitoring components"
  type        = string
  default     = "monitoring"
}

variable "enable_prometheus_stack" {
  description = "Enable kube-prometheus-stack (Prometheus + Grafana + Alertmanager)"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Enable metrics-server for kubectl top and HPA"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password (use strong password in production)"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "grafana_service_type" {
  description = "Grafana service type (ClusterIP, NodePort, LoadBalancer)"
  type        = string
  default     = "NodePort"
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.grafana_service_type)
    error_message = "Service type must be ClusterIP, NodePort, or LoadBalancer"
  }
}

variable "grafana_nodeport" {
  description = "Grafana NodePort (only used when service type is NodePort)"
  type        = number
  default     = 30300
  validation {
    condition     = var.grafana_nodeport >= 30000 && var.grafana_nodeport <= 32767
    error_message = "NodePort must be between 30000 and 32767"
  }
}

variable "metrics_server_insecure_tls" {
  description = "Pass --kubelet-insecure-tls to metrics-server (needed for some clusters)"
  type        = bool
  default     = true
}
