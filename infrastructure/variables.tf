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
  description = "Configuration for node pools. Defaults to a single g6-standard-1 node (~$24/mo) with autoscaling 1-3."
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
      count = 1
      autoscaler = {
        min = 1
        max = 3
      }
    }
  ]
}

variable "ha_control_plane" {
  description = "Enable high availability for the control plane (adds ~$60/month)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = ["lke", "kubernetes"]
}

# ==========================================
# Firewall Configuration
# ==========================================

variable "firewall_enabled" {
  description = "Enable firewall creation"
  type        = bool
  default     = true
}

variable "firewall_enable_nodeports" {
  description = "Enable NodePort access through firewall (uses allowed_kubectl_ips)"
  type        = bool
  default     = true
}

variable "allowed_kubectl_ips" {
  description = "IP addresses (CIDR) allowed to access kubectl API (port 443) and NodePorts. Restrict in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for ip in var.allowed_kubectl_ips : can(cidrhost(ip, 0))])
    error_message = "Each allowed_kubectl_ips entry must be a valid CIDR (e.g., '203.0.113.10/32')."
  }
}

variable "allowed_monitoring_ips" {
  description = "IP addresses (CIDR) allowed to access monitoring UIs (Grafana, Prometheus). Restrict in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for ip in var.allowed_monitoring_ips : can(cidrhost(ip, 0))])
    error_message = "Each allowed_monitoring_ips entry must be a valid CIDR (e.g., '203.0.113.10/32')."
  }
}

# ==========================================
# Metrics Server (opt-out)
# ==========================================

variable "install_metrics_server" {
  description = "Install Kubernetes Metrics Server (enables 'kubectl top' and HPA). Lightweight, recommended."
  type        = bool
  default     = true
}

# ==========================================
# Monitoring Stack (opt-in - costs extra storage)
# ==========================================

variable "install_monitoring" {
  description = "Install kube-prometheus-stack (Prometheus + Grafana + Alertmanager). Disabled by default to save cost."
  type        = bool
  default     = false
}

variable "monitoring_namespace" {
  description = "Namespace to deploy monitoring components"
  type        = string
  default     = "monitoring"
}

variable "monitoring_use_ephemeral_storage" {
  description = "Use emptyDir (ephemeral) storage for monitoring components instead of persistent block storage. Free, but data is lost on pod restart."
  type        = bool
  default     = false
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
  default     = "7d"
}

variable "prometheus_storage_size" {
  description = "Prometheus persistent storage size"
  type        = string
  default     = "20Gi"
}

variable "grafana_storage_size" {
  description = "Grafana persistent storage size"
  type        = string
  default     = "5Gi"
}

variable "alertmanager_storage_size" {
  description = "Alertmanager persistent storage size"
  type        = string
  default     = "2Gi"
}

# ==========================================
# OpenCost (opt-in)
# ==========================================

variable "install_opencost" {
  description = "Install OpenCost for Kubernetes cost monitoring. Requires install_monitoring=true. Disabled by default."
  type        = bool
  default     = false
}

variable "opencost_namespace" {
  description = "Namespace for OpenCost deployment"
  type        = string
  default     = "opencost"
}

# ==========================================
# Network Policies (opt-out)
# ==========================================

variable "install_network_policies" {
  description = "Install default-deny NetworkPolicies for monitoring and opencost namespaces (CIS 5.3). Enabled by default; requires Calico or another CNI that enforces NetworkPolicy (LKE uses Calico)."
  type        = bool
  default     = true
}

# ==========================================
# Node Exporter (opt-in)
# ==========================================

variable "monitoring_enable_node_exporter" {
  description = "Enable node-exporter DaemonSet in the monitoring stack. Requires hostNetwork/hostPID/hostPath access (PSS privileged). Disabled by default — metrics-server covers kubectl top and HPA without host access."
  type        = bool
  default     = false
}
