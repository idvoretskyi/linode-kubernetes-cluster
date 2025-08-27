# Core configuration
variable "enabled" {
  description = "Enable/disable the monitoring stack"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace for monitoring components"
  type        = string
  default     = "monitoring"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = list(string)
  default     = []
}

# Storage configuration
variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "linode-block-storage"
}

# Metrics Server configuration
variable "enable_metrics_server" {
  description = "Enable metrics-server for resource metrics"
  type        = bool
  default     = true
}

variable "metrics_server_version" {
  description = "Version of metrics-server helm chart"
  type        = string
  default     = "3.12.1"
}

variable "metrics_server_resources" {
  description = "Resource requests and limits for metrics-server"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "200Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1000Mi"
    }
  }
}

# Prometheus Stack configuration
variable "enable_prometheus_stack" {
  description = "Enable Prometheus monitoring stack"
  type        = bool
  default     = true
}

variable "prometheus_stack_version" {
  description = "Version of kube-prometheus-stack helm chart"
  type        = string
  default     = "61.3.0"
}

# Prometheus configuration
variable "prometheus_retention" {
  description = "Data retention period for Prometheus"
  type        = string
  default     = "15d"

  validation {
    condition     = can(regex("^[0-9]+[dwmy]$", var.prometheus_retention))
    error_message = "Prometheus retention must be in format like '15d', '2w', '1m', '1y'."
  }
}

variable "prometheus_resources" {
  description = "Resource requests and limits for Prometheus"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "200m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "2000m"
      memory = "2Gi"
    }
  }
}

variable "prometheus_storage_enabled" {
  description = "Enable persistent storage for Prometheus"
  type        = bool
  default     = true
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "10Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i$", var.prometheus_storage_size))
    error_message = "Storage size must be in Kubernetes format like '10Gi', '1Ti'."
  }
}

# Grafana configuration
variable "enable_grafana" {
  description = "Enable Grafana dashboard"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana (use random if not specified)"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "grafana_resources" {
  description = "Resource requests and limits for Grafana"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

variable "grafana_storage_enabled" {
  description = "Enable persistent storage for Grafana"
  type        = bool
  default     = true
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "2Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i$", var.grafana_storage_size))
    error_message = "Storage size must be in Kubernetes format like '2Gi', '1Ti'."
  }
}

variable "grafana_service_type" {
  description = "Grafana service type"
  type        = string
  default     = "NodePort"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.grafana_service_type)
    error_message = "Service type must be ClusterIP, NodePort, or LoadBalancer."
  }
}

variable "grafana_nodeport" {
  description = "NodePort for Grafana service (when service type is NodePort)"
  type        = number
  default     = 31000

  validation {
    condition     = var.grafana_nodeport >= 30000 && var.grafana_nodeport <= 32767
    error_message = "NodePort must be between 30000 and 32767."
  }
}

variable "grafana_ingress_enabled" {
  description = "Enable ingress for Grafana"
  type        = bool
  default     = false
}

variable "grafana_ingress_hosts" {
  description = "Ingress hosts for Grafana"
  type        = list(string)
  default     = []
}

# Alertmanager configuration
variable "enable_alertmanager" {
  description = "Enable Alertmanager"
  type        = bool
  default     = true
}

variable "alertmanager_resources" {
  description = "Resource requests and limits for Alertmanager"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }
}

variable "alertmanager_storage_enabled" {
  description = "Enable persistent storage for Alertmanager"
  type        = bool
  default     = false
}

variable "alertmanager_storage_size" {
  description = "Storage size for Alertmanager"
  type        = string
  default     = "1Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i$", var.alertmanager_storage_size))
    error_message = "Storage size must be in Kubernetes format like '1Gi', '1Ti'."
  }
}

# Component toggles
variable "enable_node_exporter" {
  description = "Enable Node Exporter for node metrics"
  type        = bool
  default     = true
}

variable "enable_kube_state_metrics" {
  description = "Enable kube-state-metrics for cluster state metrics"
  type        = bool
  default     = true
}

# Custom monitoring configuration
variable "custom_service_monitors" {
  description = "List of custom ServiceMonitor manifests"
  type        = list(any)
  default     = []
}

variable "custom_dashboards" {
  description = "List of custom Grafana dashboards"
  type = list(object({
    name    = string
    content = string
  }))
  default = []
}

# Environment-specific presets
variable "environment_preset" {
  description = "Environment preset for resource sizing (development, staging, production)"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment_preset)
    error_message = "Environment preset must be development, staging, or production."
  }
}