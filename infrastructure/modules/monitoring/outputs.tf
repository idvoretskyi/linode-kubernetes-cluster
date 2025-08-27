# Namespace outputs
output "namespace_name" {
  description = "Name of the monitoring namespace"
  value       = var.enabled ? kubernetes_namespace.monitoring[0].metadata[0].name : null
}

output "namespace_labels" {
  description = "Labels applied to the monitoring namespace"
  value       = var.enabled ? kubernetes_namespace.monitoring[0].metadata[0].labels : null
}

# Metrics Server outputs
output "metrics_server_enabled" {
  description = "Whether metrics-server is enabled"
  value       = var.enabled && var.enable_metrics_server
}

output "metrics_server_version" {
  description = "Version of metrics-server deployed"
  value       = var.enabled && var.enable_metrics_server ? var.metrics_server_version : null
}

# Prometheus outputs
output "prometheus_enabled" {
  description = "Whether Prometheus is enabled"
  value       = var.enabled && var.enable_prometheus_stack
}

output "prometheus_retention" {
  description = "Prometheus data retention period"
  value       = var.enabled && var.enable_prometheus_stack ? var.prometheus_retention : null
}

output "prometheus_storage_enabled" {
  description = "Whether Prometheus has persistent storage"
  value       = var.enabled && var.enable_prometheus_stack ? var.prometheus_storage_enabled : null
}

output "prometheus_storage_size" {
  description = "Size of Prometheus storage"
  value       = var.enabled && var.enable_prometheus_stack && var.prometheus_storage_enabled ? var.prometheus_storage_size : null
}

# Grafana outputs
output "grafana_enabled" {
  description = "Whether Grafana is enabled"
  value       = var.enabled && var.enable_grafana
}

output "grafana_service_type" {
  description = "Grafana service type"
  value       = var.enabled && var.enable_grafana ? var.grafana_service_type : null
}

output "grafana_nodeport" {
  description = "Grafana NodePort (if using NodePort service)"
  value       = var.enabled && var.enable_grafana && var.grafana_service_type == "NodePort" ? var.grafana_nodeport : null
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.enabled && var.enable_grafana ? var.grafana_admin_password : null
  sensitive   = true
}

output "grafana_storage_enabled" {
  description = "Whether Grafana has persistent storage"
  value       = var.enabled && var.enable_grafana ? var.grafana_storage_enabled : null
}

# Alertmanager outputs
output "alertmanager_enabled" {
  description = "Whether Alertmanager is enabled"
  value       = var.enabled && var.enable_alertmanager
}

output "alertmanager_storage_enabled" {
  description = "Whether Alertmanager has persistent storage"
  value       = var.enabled && var.enable_alertmanager ? var.alertmanager_storage_enabled : null
}

# Component status
output "node_exporter_enabled" {
  description = "Whether Node Exporter is enabled"
  value       = var.enabled && var.enable_node_exporter
}

output "kube_state_metrics_enabled" {
  description = "Whether kube-state-metrics is enabled"
  value       = var.enabled && var.enable_kube_state_metrics
}

# Access information
output "access_instructions" {
  description = "Instructions for accessing monitoring services"
  value = var.enabled ? {
    grafana = var.enable_grafana ? {
      url = var.grafana_service_type == "NodePort" ? "http://<NODE_IP>:${var.grafana_nodeport}" : "Check kubectl get svc -n ${var.namespace}"
      username = "admin"
      password = var.grafana_admin_password
      note     = var.grafana_service_type == "NodePort" ? "Replace <NODE_IP> with any cluster node IP" : "Use port-forward or configure ingress for access"
    } : null
    prometheus = var.enable_prometheus_stack ? {
      url  = "kubectl port-forward -n ${var.namespace} svc/prometheus-stack-kube-prom-prometheus 9090:9090"
      note = "Access via port-forward at http://localhost:9090"
    } : null
    alertmanager = var.enable_alertmanager ? {
      url  = "kubectl port-forward -n ${var.namespace} svc/prometheus-stack-kube-prom-alertmanager 9093:9093"
      note = "Access via port-forward at http://localhost:9093"
    } : null
  } : null
}

# Resource summary
output "resource_summary" {
  description = "Summary of deployed monitoring resources"
  value = var.enabled ? {
    namespace    = var.namespace
    components = {
      metrics_server    = var.enable_metrics_server
      prometheus        = var.enable_prometheus_stack
      grafana          = var.enable_grafana
      alertmanager     = var.enable_alertmanager
      node_exporter    = var.enable_node_exporter
      kube_state_metrics = var.enable_kube_state_metrics
    }
    storage = {
      prometheus_storage   = var.prometheus_storage_enabled ? var.prometheus_storage_size : "disabled"
      grafana_storage     = var.grafana_storage_enabled ? var.grafana_storage_size : "disabled"
      alertmanager_storage = var.alertmanager_storage_enabled ? var.alertmanager_storage_size : "disabled"
    }
    environment_preset = var.environment_preset
  } : null
}