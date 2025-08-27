terraform {
  required_version = ">= 1.6"
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "linode" {
  # token is set via LINODE_TOKEN environment variable
}

provider "kubernetes" {
  host                   = module.lke_cluster.cluster_endpoint
  token                  = module.lke_cluster.cluster_token
  cluster_ca_certificate = base64decode(module.lke_cluster.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.lke_cluster.cluster_endpoint
    token                  = module.lke_cluster.cluster_token
    cluster_ca_certificate = base64decode(module.lke_cluster.cluster_ca_certificate)
  }
}

# Local variables for consistency
locals {
  cluster_name = var.cluster_name
  region       = var.region
  
  # Common tags applied to all resources
  common_tags = concat(var.tags, [
    "managed-by:opentofu",
    "project:${var.project_name}",
    "environment:${var.environment}"
  ])
  
  # Generate unique names to avoid conflicts
  unique_suffix = var.name_suffix != "" ? var.name_suffix : random_id.suffix.hex
}

# Generate a random suffix if none provided
resource "random_id" "suffix" {
  byte_length = 4
}

# LKE Cluster Module
module "lke_cluster" {
  source = "./modules/lke-cluster"

  cluster_name      = "${local.cluster_name}-${local.unique_suffix}"
  region            = local.region
  k8s_version       = var.k8s_version
  node_pools        = var.node_pools
  control_plane_ha  = var.control_plane_ha
  tags              = local.common_tags
}

# Firewall Module
module "firewall" {
  source = "./modules/firewall"

  firewall_name    = "${local.cluster_name}-firewall-${local.unique_suffix}"
  tags             = local.common_tags
  
  # Firewall presets
  enable_ssh       = var.firewall_enable_ssh
  enable_http      = var.firewall_enable_http
  enable_https     = var.firewall_enable_https
  enable_k8s_api   = var.firewall_enable_k8s_api
  enable_nodeports = var.firewall_enable_nodeports
  
  # Access control
  allowed_ips      = var.firewall_allowed_ips
  inbound_policy   = var.firewall_inbound_policy
  outbound_policy  = var.firewall_outbound_policy
  
  # Custom rules
  inbound_rules    = var.firewall_inbound_rules
  outbound_rules   = var.firewall_outbound_rules
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  enabled            = var.monitoring_enabled
  namespace          = var.monitoring_namespace
  environment_preset = var.environment == "dev" ? "development" : var.environment == "prod" ? "production" : var.environment

  # Component toggles
  enable_metrics_server    = var.monitoring_enable_metrics_server
  enable_prometheus_stack  = var.monitoring_enable_prometheus_stack
  enable_grafana          = var.monitoring_enable_grafana
  enable_alertmanager     = var.monitoring_enable_alertmanager
  enable_node_exporter    = var.monitoring_enable_node_exporter
  enable_kube_state_metrics = var.monitoring_enable_kube_state_metrics

  # Grafana configuration
  grafana_admin_password = var.monitoring_grafana_admin_password
  grafana_service_type   = var.monitoring_grafana_service_type
  grafana_nodeport      = var.monitoring_grafana_nodeport

  # Storage configuration  
  storage_class                = var.monitoring_storage_class
  prometheus_storage_enabled   = var.monitoring_prometheus_storage_enabled
  prometheus_storage_size      = var.monitoring_prometheus_storage_size
  grafana_storage_enabled      = var.monitoring_grafana_storage_enabled
  grafana_storage_size         = var.monitoring_grafana_storage_size

  # Resource configuration
  prometheus_retention = var.monitoring_prometheus_retention

  tags = local.common_tags

  depends_on = [module.lke_cluster]
}