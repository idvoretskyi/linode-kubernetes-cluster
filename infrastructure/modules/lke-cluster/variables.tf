variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 32
    error_message = "Cluster name must be between 1 and 32 characters."
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

  validation {
    condition     = length(var.node_pools) > 0
    error_message = "At least one node pool must be specified."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : pool.count >= 1 && pool.count <= 100
    ])
    error_message = "Node pool count must be between 1 and 100."
  }

  validation {
    condition = alltrue([
      for pool in var.node_pools : 
      pool.autoscaler == null || (
        pool.autoscaler.min >= 1 && 
        pool.autoscaler.max >= pool.autoscaler.min && 
        pool.autoscaler.max <= 100
      )
    ])
    error_message = "Autoscaler min must be >= 1, max must be >= min and <= 100."
  }
}

variable "control_plane_ha" {
  description = "Enable high availability for control plane"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.tags) <= 64
    error_message = "Maximum 64 tags allowed per resource."
  }
}