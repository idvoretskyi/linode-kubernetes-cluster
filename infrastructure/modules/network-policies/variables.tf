variable "install_monitoring" {
  description = "Whether the monitoring (kube-prometheus-stack) add-on is installed"
  type        = bool
  default     = false
}

variable "install_opencost" {
  description = "Whether the opencost add-on is installed"
  type        = bool
  default     = false
}

variable "monitoring_namespace" {
  description = "Namespace used by kube-prometheus-stack"
  type        = string
  default     = "monitoring"
}

variable "opencost_namespace" {
  description = "Namespace used by opencost"
  type        = string
  default     = "opencost"
}
