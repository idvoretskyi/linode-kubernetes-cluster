# Cluster outputs
output "cluster_id" {
  description = "The ID of the LKE cluster"
  value       = module.lke_cluster.cluster_id
}

output "cluster_name" {
  description = "The full name of the LKE cluster"
  value       = module.lke_cluster.cluster_label
}

output "cluster_endpoint" {
  description = "The API server endpoint of the LKE cluster"
  value       = module.lke_cluster.cluster_endpoint
}

output "cluster_status" {
  description = "The status of the LKE cluster"
  value       = module.lke_cluster.cluster_status
}

output "cluster_region" {
  description = "The region where the cluster is deployed"
  value       = module.lke_cluster.cluster_region
}

output "k8s_version" {
  description = "The Kubernetes version of the cluster"
  value       = module.lke_cluster.k8s_version
}

output "kubeconfig" {
  description = "Base64 encoded kubeconfig for the cluster"
  value       = module.lke_cluster.kubeconfig
  sensitive   = true
}

output "node_pools" {
  description = "Information about the node pools"
  value       = module.lke_cluster.node_pools
}

output "dashboard_url" {
  description = "The dashboard URL for the cluster"
  value       = module.lke_cluster.dashboard_url
}

# Firewall outputs
output "firewall_id" {
  description = "The ID of the cluster firewall"
  value       = module.firewall.firewall_id
}

output "firewall_name" {
  description = "The name of the cluster firewall"
  value       = module.firewall.firewall_label
}

output "firewall_status" {
  description = "The status of the firewall"
  value       = module.firewall.firewall_status
}

# Connection information
output "connection_info" {
  description = "Instructions for connecting to the cluster"
  value = {
    endpoint = module.lke_cluster.cluster_endpoint
    region   = module.lke_cluster.cluster_region
    setup_commands = [
      "# Save the kubeconfig:",
      "echo '${module.lke_cluster.kubeconfig}' | base64 -d > kubeconfig.yaml",
      "",
      "# Set KUBECONFIG environment variable:",
      "export KUBECONFIG=./kubeconfig.yaml",
      "",
      "# Verify connection:",
      "kubectl cluster-info",
      "kubectl get nodes"
    ]
  }
  sensitive = true
}

# Monitoring outputs
output "monitoring_enabled" {
  description = "Whether monitoring stack is enabled"
  value       = var.monitoring_enabled
}

output "monitoring_namespace" {
  description = "Monitoring namespace name"
  value       = var.monitoring_enabled ? module.monitoring.namespace_name : null
}

output "monitoring_access_instructions" {
  description = "Instructions for accessing monitoring services"
  value       = var.monitoring_enabled ? module.monitoring.access_instructions : null
  sensitive   = true
}

output "monitoring_grafana_nodeport" {
  description = "Grafana NodePort number"
  value       = var.monitoring_enabled ? module.monitoring.grafana_nodeport : null
}

output "monitoring_grafana_password" {
  description = "Grafana admin password"
  value       = var.monitoring_enabled ? module.monitoring.grafana_admin_password : null
  sensitive   = true
}

output "monitoring_resource_summary" {
  description = "Summary of monitoring resources"
  value       = var.monitoring_enabled ? module.monitoring.resource_summary : null
}

# Resource summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    cluster = {
      id       = module.lke_cluster.cluster_id
      name     = module.lke_cluster.cluster_label
      region   = module.lke_cluster.cluster_region
      version  = module.lke_cluster.k8s_version
      endpoint = module.lke_cluster.cluster_endpoint
    }
    firewall = {
      id   = module.firewall.firewall_id
      name = module.firewall.firewall_label
    }
    monitoring = var.monitoring_enabled ? {
      enabled    = true
      namespace  = module.monitoring.namespace_name
      components = module.monitoring.resource_summary.components
    } : {
      enabled    = false
      namespace  = null
      components = null
    }
    node_pools = [
      for pool in module.lke_cluster.node_pools : {
        type  = pool.type
        count = pool.count
        nodes = length(pool.nodes)
      }
    ]
    tags = local.common_tags
  }
}