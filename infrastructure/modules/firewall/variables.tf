variable "firewall_name" {
  description = "Name of the firewall"
  type        = string

  validation {
    condition     = length(var.firewall_name) > 0 && length(var.firewall_name) <= 32
    error_message = "Firewall name must be between 1 and 32 characters."
  }
}

variable "tags" {
  description = "Tags to apply to the firewall"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.tags) <= 64
    error_message = "Maximum 64 tags allowed per firewall."
  }
}

variable "inbound_policy" {
  description = "Default policy for inbound traffic"
  type        = string
  default     = "DROP"

  validation {
    condition     = contains(["ACCEPT", "DROP"], var.inbound_policy)
    error_message = "Inbound policy must be either ACCEPT or DROP."
  }
}

variable "outbound_policy" {
  description = "Default policy for outbound traffic"
  type        = string
  default     = "ACCEPT"

  validation {
    condition     = contains(["ACCEPT", "DROP"], var.outbound_policy)
    error_message = "Outbound policy must be either ACCEPT or DROP."
  }
}

variable "inbound_rules" {
  description = "List of inbound firewall rules"
  type = list(object({
    label    = string
    action   = string
    protocol = string
    ports    = string
    ipv4     = list(string)
    ipv6     = optional(list(string), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.inbound_rules : contains(["ACCEPT", "DROP"], rule.action)
    ])
    error_message = "All inbound rule actions must be either ACCEPT or DROP."
  }

  validation {
    condition = alltrue([
      for rule in var.inbound_rules : contains(["TCP", "UDP", "ICMP"], rule.protocol)
    ])
    error_message = "All inbound rule protocols must be TCP, UDP, or ICMP."
  }
}

variable "outbound_rules" {
  description = "List of outbound firewall rules"
  type = list(object({
    label    = string
    action   = string
    protocol = string
    ports    = string
    ipv4     = list(string)
    ipv6     = optional(list(string), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.outbound_rules : contains(["ACCEPT", "DROP"], rule.action)
    ])
    error_message = "All outbound rule actions must be either ACCEPT or DROP."
  }

  validation {
    condition = alltrue([
      for rule in var.outbound_rules : contains(["TCP", "UDP", "ICMP"], rule.protocol)
    ])
    error_message = "All outbound rule protocols must be TCP, UDP, or ICMP."
  }
}

variable "cluster_id" {
  description = "ID of the cluster to attach the firewall to (optional)"
  type        = string
  default     = null
}

# Preset configurations for common use cases
variable "enable_ssh" {
  description = "Enable SSH access (port 22)"
  type        = bool
  default     = true
}

variable "enable_http" {
  description = "Enable HTTP access (port 80)"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Enable HTTPS access (port 443)"
  type        = bool
  default     = true
}

variable "enable_k8s_api" {
  description = "Enable Kubernetes API access (port 6443)"
  type        = bool
  default     = true
}

variable "enable_nodeports" {
  description = "Enable NodePort access (ports 30000-32767)"
  type        = bool
  default     = true
}

variable "allowed_ips" {
  description = "List of IP addresses/CIDRs allowed to access the cluster"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for ip in var.allowed_ips : can(cidrhost(ip, 0))
    ])
    error_message = "All allowed IPs must be valid CIDR blocks."
  }
}