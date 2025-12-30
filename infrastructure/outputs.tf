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

output "metrics_server_namespace" {
  description = "Metrics Server namespace (if installed)"
  value       = var.install_metrics_server ? module.metrics_server[0].namespace : null
}

output "monitoring_namespace" {
  description = "Monitoring stack namespace (if installed)"
  value       = var.install_monitoring ? module.kube_prometheus_stack[0].namespace : null
}

output "grafana_service" {
  description = "Grafana service name for port-forwarding (if installed)"
  value       = var.install_monitoring ? module.kube_prometheus_stack[0].grafana_service : null
}

output "prometheus_service" {
  description = "Prometheus service name for port-forwarding (if installed)"
  value       = var.install_monitoring ? module.kube_prometheus_stack[0].prometheus_service : null
}

output "setup_commands" {
  description = "Commands to set up kubectl access"
  value       = <<-EOT
    # Kubeconfig has been automatically merged into ~/.kube/config
    # Context: lke${linode_lke_cluster.cluster.id}-ctx

    # Switch to this cluster context (if not already active)
    kubectl config use-context lke${linode_lke_cluster.cluster.id}-ctx

    # Verify cluster access
    kubectl get nodes

    ${var.install_monitoring ? "# Monitoring stack installed - Access Grafana\n    kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80\n    # Then visit: http://localhost:3000\n    # Default credentials: admin / admin\n    \n    # Access Prometheus\n    kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090\n    # Then visit: http://localhost:9090" : "# Monitoring not installed - Run: tofu apply -var=\"install_monitoring=true\""}

    ${var.install_metrics_server ? "# Metrics Server installed - Check resource usage\n    kubectl top nodes\n    kubectl top pods -A" : "# Metrics Server not installed"}
  EOT
}

output "monitoring_access_commands" {
  description = "Commands to access monitoring stack (if installed)"
  sensitive   = true
  value = var.install_monitoring ? join("\n", [
    "# Access Grafana",
    "kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80",
    "# Then visit: http://localhost:3000",
    "# Default credentials: admin / ${var.grafana_admin_password}",
    "",
    "# Access Prometheus",
    "kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090",
    "# Then visit: http://localhost:9090",
    "",
    "# Access Alertmanager",
    "kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093",
    "# Then visit: http://localhost:9093"
  ]) : "Monitoring stack not installed"
}

output "cluster_info" {
  description = "Complete cluster information summary"
  value = {
    cluster_id         = linode_lke_cluster.cluster.id
    cluster_label      = linode_lke_cluster.cluster.label
    region             = linode_lke_cluster.cluster.region
    kubernetes_version = linode_lke_cluster.cluster.k8s_version
    kubectl_context    = "lke${linode_lke_cluster.cluster.id}-ctx"
    ha_control_plane   = var.ha_control_plane
    node_count         = sum([for pool in linode_lke_cluster.cluster.pool : pool.count])
    monitoring_enabled = var.install_monitoring
    metrics_enabled    = var.install_metrics_server
  }
}
