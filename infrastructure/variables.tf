# Project identification
variable "project_name" {
  description = "Name of the project (used for tagging and naming)"
  type        = string
  default     = "lke-poc"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "development", "staging", "stage", "prod", "production"], var.environment)
    error_message = "Environment must be one of: dev, development, staging, stage, prod, production."
  }
}

variable "name_suffix" {
  description = "Optional suffix for resource names (random generated if empty)"
  type        = string
  default     = ""

  validation {
    condition     = var.name_suffix == "" || can(regex("^[a-z0-9]{4,8}$", var.name_suffix))
    error_message = "Name suffix must be 4-8 characters of lowercase letters and numbers."
  }
}

# Cluster configuration
variable "cluster_name" {
  description = "Base name of the Kubernetes cluster"
  type        = string
  default     = "lke-cluster"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "Linode region for the cluster"
  type        = string

  validation {
    condition = contains([
      "us-east", "us-west", "us-central", "us-southeast", "us-iad", "us-ord", "us-sea", "us-mia", "us-lax",
      "eu-west", "eu-central", "fr-par", "nl-ams", "se-sto", "es-mad", "gb-lon", "it-mil", "de-fra-2",
      "ap-south", "ap-northeast", "ap-west", "ap-southeast", "sg-sin-2", "jp-tyo-3", "jp-osa",
      "ca-central", "br-gru", "in-maa", "in-bom-2", "id-cgk", "au-mel"
    ], var.region)
    error_message = "Region must be a valid Linode region."
  }
}

variable "k8s_version" {
  description = "Kubernetes version for the LKE cluster"
  type        = string
  default     = "1.33"

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.k8s_version))
    error_message = "Kubernetes version must be in format 'x.y' (e.g., '1.33')."
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
      count = 1
      autoscaler = {
        min = 1
        max = 3
      }
    }
  ]

  validation {
    condition     = length(var.node_pools) > 0
    error_message = "At least one node pool must be specified."
  }
}

variable "control_plane_ha" {
  description = "Enable high availability for control plane"
  type        = bool
  default     = false
}

# Firewall configuration
variable "firewall_enable_ssh" {
  description = "Enable SSH access through firewall"
  type        = bool
  default     = true
}

variable "firewall_enable_http" {
  description = "Enable HTTP access through firewall"
  type        = bool
  default     = true
}

variable "firewall_enable_https" {
  description = "Enable HTTPS access through firewall"
  type        = bool
  default     = true
}

variable "firewall_enable_k8s_api" {
  description = "Enable Kubernetes API access through firewall"
  type        = bool
  default     = true
}

variable "firewall_enable_nodeports" {
  description = "Enable NodePort access through firewall"
  type        = bool
  default     = true
}

variable "firewall_allowed_ips" {
  description = "List of IP addresses/CIDRs allowed to access the cluster"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for ip in var.firewall_allowed_ips : can(cidrhost(ip, 0))
    ])
    error_message = "All allowed IPs must be valid CIDR blocks."
  }
}

variable "firewall_inbound_policy" {
  description = "Default policy for inbound traffic"
  type        = string
  default     = "DROP"

  validation {
    condition     = contains(["ACCEPT", "DROP"], var.firewall_inbound_policy)
    error_message = "Inbound policy must be either ACCEPT or DROP."
  }
}

variable "firewall_outbound_policy" {
  description = "Default policy for outbound traffic"
  type        = string
  default     = "ACCEPT"

  validation {
    condition     = contains(["ACCEPT", "DROP"], var.firewall_outbound_policy)
    error_message = "Outbound policy must be either ACCEPT or DROP."
  }
}

variable "firewall_inbound_rules" {
  description = "Custom inbound firewall rules"
  type = list(object({
    label    = string
    action   = string
    protocol = string
    ports    = string
    ipv4     = list(string)
    ipv6     = optional(list(string), [])
  }))
  default = []
}

variable "firewall_outbound_rules" {
  description = "Custom outbound firewall rules"
  type = list(object({
    label    = string
    action   = string
    protocol = string
    ports    = string
    ipv4     = list(string)
    ipv6     = optional(list(string), [])
  }))
  default = []
}

# General configuration
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for tag in var.tags : can(regex("^[a-zA-Z0-9:._-]+$", tag))
    ])
    error_message = "Tags must contain only alphanumeric characters, colons, periods, underscores, and hyphens."
  }
}

# Monitoring configuration
variable "monitoring_enabled" {
  description = "Enable/disable the monitoring stack"
  type        = bool
  default     = true
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring components"
  type        = string
  default     = "monitoring"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.monitoring_namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

# Monitoring component toggles
variable "monitoring_enable_metrics_server" {
  description = "Enable metrics-server for resource metrics"
  type        = bool
  default     = true
}

variable "monitoring_enable_prometheus_stack" {
  description = "Enable Prometheus monitoring stack"
  type        = bool
  default     = true
}

variable "monitoring_enable_grafana" {
  description = "Enable Grafana dashboard"
  type        = bool
  default     = true
}

variable "monitoring_enable_alertmanager" {
  description = "Enable Alertmanager"
  type        = bool
  default     = true
}

variable "monitoring_enable_node_exporter" {
  description = "Enable Node Exporter for node metrics"
  type        = bool
  default     = true
}

variable "monitoring_enable_kube_state_metrics" {
  description = "Enable kube-state-metrics for cluster state metrics"
  type        = bool
  default     = true
}

# Grafana configuration
variable "monitoring_grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "monitoring_grafana_service_type" {
  description = "Grafana service type"
  type        = string
  default     = "NodePort"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.monitoring_grafana_service_type)
    error_message = "Service type must be ClusterIP, NodePort, or LoadBalancer."
  }
}

variable "monitoring_grafana_nodeport" {
  description = "NodePort for Grafana service (when service type is NodePort)"
  type        = number
  default     = 31000

  validation {
    condition     = var.monitoring_grafana_nodeport >= 30000 && var.monitoring_grafana_nodeport <= 32767
    error_message = "NodePort must be between 30000 and 32767."
  }
}

# Storage configuration
variable "monitoring_storage_class" {
  description = "Storage class for monitoring persistent volumes"
  type        = string
  default     = "linode-block-storage"
}

variable "monitoring_prometheus_storage_enabled" {
  description = "Enable persistent storage for Prometheus"
  type        = bool
  default     = true
}

variable "monitoring_prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "10Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i$", var.monitoring_prometheus_storage_size))
    error_message = "Storage size must be in Kubernetes format like '10Gi', '1Ti'."
  }
}

variable "monitoring_grafana_storage_enabled" {
  description = "Enable persistent storage for Grafana"
  type        = bool
  default     = true
}

variable "monitoring_grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "2Gi"

  validation {
    condition     = can(regex("^[0-9]+[KMGT]i$", var.monitoring_grafana_storage_size))
    error_message = "Storage size must be in Kubernetes format like '2Gi', '1Ti'."
  }
}

# Prometheus configuration
variable "monitoring_prometheus_retention" {
  description = "Data retention period for Prometheus"
  type        = string
  default     = "15d"

  validation {
    condition     = can(regex("^[0-9]+[dwmy]$", var.monitoring_prometheus_retention))
    error_message = "Prometheus retention must be in format like '15d', '2w', '1m', '1y'."
  }
}