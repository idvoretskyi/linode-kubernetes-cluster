terraform {
  required_version = ">= 1.6"
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "3.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "opentofu/helm"
      version = "3.1.0"
    }
  }
}

provider "linode" {
  # token is set via LINODE_TOKEN environment variable
}

# Generate a random suffix for unique naming
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  cluster_name  = "${var.cluster_name}-${random_id.suffix.hex}"
  firewall_name = "${substr(var.project_name, 0, 10)}-fw-${random_id.suffix.hex}"

  common_tags = concat(var.tags, [
    "managed-by:opentofu",
    "project:${var.project_name}",
    "environment:${var.environment}"
  ])
}

# Kubernetes and Helm providers for monitoring
# These providers will use the generated kubeconfig after cluster creation
provider "kubernetes" {
  host                   = try(linode_lke_cluster.cluster.api_endpoints[0], "")
  cluster_ca_certificate = try(base64decode(yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig)).clusters[0].cluster["certificate-authority-data"]), "")
  token                  = try(yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig)).users[0].user.token, "")
}

provider "helm" {
  kubernetes = {
    host                   = try(linode_lke_cluster.cluster.api_endpoints[0], "")
    cluster_ca_certificate = try(base64decode(yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig)).clusters[0].cluster["certificate-authority-data"]), "")
    token                  = try(yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig)).users[0].user.token, "")
  }
}

# LKE Cluster
resource "linode_lke_cluster" "cluster" {
  k8s_version = var.k8s_version
  label       = local.cluster_name
  region      = var.region
  tags        = local.common_tags

  dynamic "pool" {
    for_each = var.node_pools
    content {
      type  = pool.value.type
      count = pool.value.count

      dynamic "autoscaler" {
        for_each = pool.value.autoscaler != null ? [pool.value.autoscaler] : []
        content {
          min = autoscaler.value.min
          max = autoscaler.value.max
        }
      }
    }
  }

  control_plane {
    high_availability = var.control_plane_ha
  }
}

# Firewall
resource "linode_firewall" "cluster_firewall" {
  count           = var.firewall_enabled ? 1 : 0
  label           = local.firewall_name
  tags            = local.common_tags
  inbound_policy  = var.firewall_inbound_policy
  outbound_policy = var.firewall_outbound_policy

  # SSH
  dynamic "inbound" {
    for_each = var.firewall_enable_ssh ? [1] : []
    content {
      label    = "allow-ssh"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "22"
      ipv4     = var.firewall_allowed_ips
    }
  }

  # HTTP
  dynamic "inbound" {
    for_each = var.firewall_enable_http ? [1] : []
    content {
      label    = "allow-http"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "80"
      ipv4     = var.firewall_allowed_ips
    }
  }

  # HTTPS
  dynamic "inbound" {
    for_each = var.firewall_enable_https ? [1] : []
    content {
      label    = "allow-https"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "443"
      ipv4     = var.firewall_allowed_ips
    }
  }

  # Kubernetes API
  dynamic "inbound" {
    for_each = var.firewall_enable_k8s_api ? [1] : []
    content {
      label    = "allow-k8s-api"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "6443"
      ipv4     = var.firewall_allowed_ips
    }
  }

  # NodePorts
  dynamic "inbound" {
    for_each = var.firewall_enable_nodeports ? [1] : []
    content {
      label    = "allow-nodeports"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "30000-32767"
      ipv4     = var.firewall_allowed_ips
    }
  }

  # Custom inbound rules
  dynamic "inbound" {
    for_each = var.firewall_inbound_rules
    content {
      label    = inbound.value.label
      action   = inbound.value.action
      protocol = inbound.value.protocol
      ports    = inbound.value.ports
      ipv4     = inbound.value.ipv4
      ipv6     = try(inbound.value.ipv6, null)
    }
  }

  # Custom outbound rules
  dynamic "outbound" {
    for_each = var.firewall_outbound_rules
    content {
      label    = outbound.value.label
      action   = outbound.value.action
      protocol = outbound.value.protocol
      ports    = outbound.value.ports
      ipv4     = outbound.value.ipv4
      ipv6     = try(outbound.value.ipv6, null)
    }
  }
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  namespace                   = var.monitoring_namespace
  enable_prometheus_stack     = var.monitoring_enable_prometheus_stack
  enable_metrics_server       = var.monitoring_enable_metrics_server
  grafana_nodeport            = var.monitoring_grafana_nodeport
  metrics_server_insecure_tls = var.monitoring_metrics_server_insecure_tls

  depends_on = [linode_lke_cluster.cluster]
}
