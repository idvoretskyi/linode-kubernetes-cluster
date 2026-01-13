terraform {
  required_version = ">= 1.6"

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 3.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

# Provider will automatically use LINODE_TOKEN environment variable
# Set via: export LINODE_TOKEN=$(linode-cli configure get token)
# Or manually: export LINODE_TOKEN='your-token-here'
provider "linode" {
  # token is read from LINODE_TOKEN environment variable
}

# Kubernetes provider for managing K8s resources
# Uses kubeconfig from the LKE cluster resource
provider "kubernetes" {
  host                   = yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig)).clusters[0].cluster.server
  token                  = yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig)).users[0].user.token
  cluster_ca_certificate = base64decode(yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig)).clusters[0].cluster["certificate-authority-data"])
}

# Helm provider for installing charts
# Uses same kubeconfig data as the kubernetes provider
provider "helm" {
  kubernetes = {
    host                   = yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig)).clusters[0].cluster.server
    token                  = yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig)).users[0].user.token
    cluster_ca_certificate = base64decode(yamldecode(base64decode(linode_lke_cluster.cluster.kubeconfig)).clusters[0].cluster["certificate-authority-data"])
  }
}

# Determine cluster name prefix (use provided value or system username)
locals {
  cluster_prefix = var.cluster_name_prefix != "" ? var.cluster_name_prefix : replace(lower(data.external.username.result.username), "/[^a-z0-9-]/", "-")

  common_tags = concat(var.tags, [
    "managed-by:opentofu",
    "owner:${local.cluster_prefix}"
  ])
}

# Get system username if cluster_name_prefix is not set
data "external" "username" {
  program = ["sh", "-c", "echo '{\"username\":\"'$(whoami)'\"}'"]
}

# LKE Cluster
resource "linode_lke_cluster" "cluster" {
  label       = "${local.cluster_prefix}-lke"
  k8s_version = var.kubernetes_version
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
    high_availability = var.ha_control_plane
  }
}

# Merge kubeconfig into ~/.kube/config (no local file storage)
resource "terraform_data" "merge_kubeconfig" {
  triggers_replace = {
    kubeconfig_content = base64decode(linode_lke_cluster.cluster.kubeconfig)
    cluster_id         = linode_lke_cluster.cluster.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create ~/.kube directory if it doesn't exist
      mkdir -p ~/.kube

      # Backup existing config if it exists
      if [ -f ~/.kube/config ]; then
        cp ~/.kube/config ~/.kube/config.backup.$(date +%Y%m%d-%H%M%S)
      fi

      # Write kubeconfig to temporary file
      TEMP_KUBECONFIG=$(mktemp)
      cat > $TEMP_KUBECONFIG << 'KUBECONFIGEOF'
${base64decode(linode_lke_cluster.cluster.kubeconfig)}
KUBECONFIGEOF
      chmod 600 $TEMP_KUBECONFIG

      # Merge the new kubeconfig
      KUBECONFIG=~/.kube/config:$TEMP_KUBECONFIG kubectl config view --flatten > ~/.kube/config.tmp
      mv ~/.kube/config.tmp ~/.kube/config
      chmod 600 ~/.kube/config

      # Clean up temporary file
      rm -f $TEMP_KUBECONFIG

      # Set the new context as active
      kubectl config use-context lke${linode_lke_cluster.cluster.id}-ctx

      echo "✓ Kubeconfig merged into ~/.kube/config"
      echo "✓ Context 'lke${linode_lke_cluster.cluster.id}-ctx' is now active"
      echo "✓ No local kubeconfig file created (stored in ~/.kube/config only)"
    EOT
  }
}

# Firewall for LKE cluster
resource "linode_firewall" "cluster_firewall" {
  count = var.firewall_enabled ? 1 : 0

  label = "${local.cluster_prefix}-lke-firewall"
  tags  = local.common_tags

  inbound {
    label    = "allow-kubectl"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "443"
    ipv4     = var.allowed_kubectl_ips
  }

  inbound {
    label    = "allow-monitoring-ui"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80,443,3000,9090"
    ipv4     = var.allowed_monitoring_ips
  }

  inbound {
    label    = "allow-kubelet-metrics"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "10250"
    ipv4     = ["0.0.0.0/0"]
  }

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

  inbound_policy  = var.firewall_inbound_policy
  outbound_policy = var.firewall_outbound_policy

  linodes = flatten([for pool in linode_lke_cluster.cluster.pool : [for node in pool.nodes : node.instance_id]])

  depends_on = [linode_lke_cluster.cluster]
}

# Metrics Server Module (optional)
module "metrics_server" {
  count  = var.install_metrics_server ? 1 : 0
  source = "./modules/metrics-server"

  namespace = "kube-system"

  depends_on = [
    linode_lke_cluster.cluster,
    terraform_data.merge_kubeconfig
  ]
}

# Kube Prometheus Stack Module (optional)
module "kube_prometheus_stack" {
  count  = var.install_monitoring ? 1 : 0
  source = "./modules/kube-prometheus-stack"

  namespace               = var.monitoring_namespace
  grafana_admin_password  = var.grafana_admin_password
  prometheus_retention    = var.prometheus_retention
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size    = var.grafana_storage_size

  depends_on = [
    module.metrics_server,
    linode_lke_cluster.cluster,
    terraform_data.merge_kubeconfig
  ]
}

# OpenCost Module (optional)
module "opencost" {
  count  = var.install_opencost ? 1 : 0
  source = "./modules/opencost"

  namespace                = var.opencost_namespace
  cluster_id               = linode_lke_cluster.cluster.id
  prometheus_service_name  = "kube-prometheus-stack-prometheus"
  prometheus_namespace     = var.monitoring_namespace

  depends_on = [
    module.kube_prometheus_stack,
    linode_lke_cluster.cluster,
    terraform_data.merge_kubeconfig
  ]
}
