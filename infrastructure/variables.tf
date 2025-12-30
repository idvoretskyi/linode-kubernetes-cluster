variable "cluster_name_prefix" {
  description = "Prefix for the LKE cluster name (will use system username if not set)"
  type        = string
  default     = ""
}

variable "region" {
  description = "Linode region for the cluster"
  type        = string
  default     = "us-east"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]{3,4}$", var.region))
    error_message = "Region must match pattern 'xx-yyy' or 'xx-yyyy' (e.g., 'us-east')."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the LKE cluster"
  type        = string
  default     = "1.34" # Latest stable version

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be in the format 'X.Y' (e.g., '1.34')."
  }
}

variable "node_pools" {
  description = "Configuration for node pools"
  type = list(object({
    type  = string
    count = number
    autoscaler = optional(object({
      min = number
      max = number
    }))
  }))

  default = [
    {
      type  = "g6-standard-1"
      count = 3
      autoscaler = {
        min = 1
        max = 5
      }
    }
  ]
}

variable "ha_control_plane" {
  description = "Enable high availability for the control plane"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = ["lke", "kubernetes"]
}

# Firewall configuration
variable "firewall_enabled" {
  description = "Enable firewall creation"
  type        = bool
  default     = true
}

variable "firewall_enable_nodeports" {
  description = "Enable NodePort access through firewall"
  type        = bool
  default     = true
}

variable "firewall_allowed_ips" {
  description = "List of IP addresses/CIDRs allowed for general access (NodePorts)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for ip in var.firewall_allowed_ips : can(cidrhost(ip, 0))])
    error_message = "Each firewall_allowed_ips entry must be a valid CIDR (e.g., '203.0.113.10/32')."
  }
}

variable "allowed_kubectl_ips" {
  description = "IP addresses allowed to access kubectl API (port 443)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Consider restricting this in production

  validation {
    condition     = alltrue([for ip in var.allowed_kubectl_ips : can(cidrhost(ip, 0))])
    error_message = "Each allowed_kubectl_ips entry must be a valid CIDR (e.g., '203.0.113.10/32')."
  }
}

variable "allowed_monitoring_ips" {
  description = "IP addresses allowed to access monitoring UIs (Grafana, Prometheus)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Consider restricting this in production

  validation {
    condition     = alltrue([for ip in var.allowed_monitoring_ips : can(cidrhost(ip, 0))])
    error_message = "Each allowed_monitoring_ips entry must be a valid CIDR (e.g., '203.0.113.10/32')."
  }
}

variable "firewall_inbound_policy" {
  description = "Default policy for inbound traffic"
  type        = string
  default     = "DROP"
}

variable "firewall_outbound_policy" {
  description = "Default policy for outbound traffic"
  type        = string
  default     = "ACCEPT"
}

# Metrics Server Configuration
variable "install_metrics_server" {
  description = "Install Kubernetes Metrics Server for resource metrics API"
  type        = bool
  default     = true
}

# Monitoring Stack Configuration
variable "install_monitoring" {
  description = "Install kube-prometheus-stack for comprehensive monitoring"
  type        = bool
  default     = true
}

variable "monitoring_namespace" {
  description = "Namespace to deploy monitoring components"
  type        = string
  default     = "monitoring"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana (change in production)"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Prometheus persistent storage size"
  type        = string
  default     = "50Gi"
}

variable "grafana_storage_size" {
  description = "Grafana persistent storage size"
  type        = string
  default     = "10Gi"
}
