# Project identification
variable "project_name" {
  description = "Name of the project (used for tagging and naming)"
  type        = string
  default     = "lke-poc"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Cluster configuration
variable "cluster_name" {
  description = "Base name of the Kubernetes cluster"
  type        = string
  default     = "lke-cluster"
}

variable "region" {
  description = "Linode region for the cluster"
  type        = string
  default     = "us-east"
}

variable "k8s_version" {
  description = "Kubernetes version for the LKE cluster"
  type        = string
  default     = "1.34"
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
}

variable "control_plane_ha" {
  description = "Enable high availability for control plane"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = list(string)
  default     = []
}

# Firewall configuration
variable "firewall_enabled" {
  description = "Enable firewall creation"
  type        = bool
  default     = true
}

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
