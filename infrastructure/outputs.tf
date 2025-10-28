output "cluster_id" {
  description = "The ID of the LKE cluster"
  value       = linode_lke_cluster.cluster.id
}

output "cluster_name" {
  description = "The name of the LKE cluster"
  value       = linode_lke_cluster.cluster.label
}

output "cluster_region" {
  description = "The region of the LKE cluster"
  value       = linode_lke_cluster.cluster.region
}

output "k8s_version" {
  description = "The Kubernetes version"
  value       = linode_lke_cluster.cluster.k8s_version
}

output "api_endpoints" {
  description = "The API endpoints for the cluster"
  value       = linode_lke_cluster.cluster.api_endpoints
}

output "kubeconfig" {
  description = "The base64 encoded kubeconfig for the cluster"
  value       = linode_lke_cluster.cluster.kubeconfig
  sensitive   = true
}

output "status" {
  description = "The status of the cluster"
  value       = linode_lke_cluster.cluster.status
}

output "firewall_id" {
  description = "The ID of the firewall (if enabled)"
  value       = var.firewall_enabled ? linode_firewall.cluster_firewall[0].id : null
}

output "connection_commands" {
  description = "Commands to connect to the cluster"
  value       = <<-EOT
    # Save kubeconfig
    tofu output -raw kubeconfig | base64 -d > kubeconfig.yaml

    # Set environment variable
    export KUBECONFIG=./kubeconfig.yaml

    # Test connection
    kubectl cluster-info
    kubectl get nodes
  EOT
}

# Monitoring Outputs
output "monitoring_namespace" {
  description = "The namespace where monitoring components are deployed"
  value       = module.monitoring.namespace
}

output "monitoring_components" {
  description = "List of enabled monitoring components"
  value       = module.monitoring.components
}

output "monitoring_access_instructions" {
  description = "Instructions for accessing monitoring components"
  value       = module.monitoring.access_instructions
  sensitive   = true
}

output "monitoring_grafana_nodeport" {
  description = "Grafana NodePort (if using NodePort service)"
  value       = module.monitoring.grafana_nodeport
}
