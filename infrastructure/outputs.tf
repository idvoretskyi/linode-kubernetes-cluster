output "cluster_id" {
  description = "The ID of the LKE cluster"
  value       = linode_lke_cluster.cluster.id
}

output "cluster_label" {
  description = "The label of the LKE cluster"
  value       = linode_lke_cluster.cluster.label
}

output "cluster_region" {
  description = "The region where the cluster is deployed"
  value       = linode_lke_cluster.cluster.region
}

output "kubernetes_version" {
  description = "The Kubernetes version running on the cluster"
  value       = linode_lke_cluster.cluster.k8s_version
}

output "api_endpoints" {
  description = "The API endpoints for the cluster"
  value       = linode_lke_cluster.cluster.api_endpoints
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = "~/.kube/config (merged)"
}

output "cluster_dashboard_url" {
  description = "URL to the cluster dashboard"
  value       = linode_lke_cluster.cluster.dashboard_url
}

output "node_pool_count" {
  description = "Number of nodes across all pools"
  value       = sum([for pool in linode_lke_cluster.cluster.pool : pool.count])
}

output "firewall_id" {
  description = "The ID of the firewall protecting the cluster"
  value       = var.firewall_enabled ? linode_firewall.cluster_firewall[0].id : null
}

output "kubectl_context" {
  description = "The kubectl context name for this cluster"
  value       = "lke${linode_lke_cluster.cluster.id}-ctx"
}

output "monitoring_namespace" {
  description = "Monitoring stack namespace (if installed)"
  value       = var.install_monitoring ? module.kube_prometheus_stack[0].namespace : null
}

output "opencost_namespace" {
  description = "OpenCost namespace (if installed)"
  value       = var.install_opencost ? module.opencost[0].namespace : null
}

output "setup_commands" {
  description = "Commands to access the cluster"
  value       = <<-EOT
    # Kubeconfig has been merged into ~/.kube/config
    kubectl config use-context lke${linode_lke_cluster.cluster.id}-ctx
    kubectl get nodes
  EOT
}

output "cluster_info" {
  description = "Cluster information summary"
  value = {
    cluster_id         = linode_lke_cluster.cluster.id
    cluster_label      = linode_lke_cluster.cluster.label
    region             = linode_lke_cluster.cluster.region
    kubernetes_version = linode_lke_cluster.cluster.k8s_version
    kubectl_context    = "lke${linode_lke_cluster.cluster.id}-ctx"
    ha_control_plane   = var.ha_control_plane
    node_count         = sum([for pool in linode_lke_cluster.cluster.pool : pool.count])
    metrics_enabled    = var.install_metrics_server
    monitoring_enabled = var.install_monitoring
    opencost_enabled   = var.install_opencost
  }
}
