output "namespace" {
  description = "The namespace where monitoring components are deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_stack_enabled" {
  description = "Whether kube-prometheus-stack is enabled"
  value       = var.enable_prometheus_stack
}

output "metrics_server_enabled" {
  description = "Whether metrics-server is enabled"
  value       = var.enable_metrics_server
}

output "grafana_service_type" {
  description = "Grafana service type"
  value       = var.grafana_service_type
}

output "grafana_nodeport" {
  description = "Grafana NodePort (if using NodePort service)"
  value       = var.grafana_service_type == "NodePort" ? var.grafana_nodeport : null
}

output "access_instructions" {
  description = "Instructions for accessing monitoring components"
  value = var.enable_prometheus_stack ? join("\n", compact([
    "# Access Grafana",
    var.grafana_service_type == "NodePort" ? "NodePort: Use any node IP with port ${var.grafana_nodeport}" : null,
    var.grafana_service_type == "ClusterIP" ? "Port-forward: kubectl port-forward -n ${var.namespace} svc/kube-prometheus-stack-grafana 3000:80" : null,
    var.grafana_service_type == "LoadBalancer" ? "LoadBalancer: kubectl get svc -n ${var.namespace} kube-prometheus-stack-grafana" : null,
    "Default credentials: admin / ${var.grafana_admin_password}",
    "",
    "# Access Prometheus",
    "kubectl port-forward -n ${var.namespace} svc/kube-prometheus-stack-prometheus 9090:9090",
    "",
    "# Access Alertmanager",
    "kubectl port-forward -n ${var.namespace} svc/kube-prometheus-stack-alertmanager 9093:9093",
    "",
    var.enable_metrics_server ? "# Test metrics-server" : null,
    var.enable_metrics_server ? "kubectl top nodes" : null,
    var.enable_metrics_server ? "kubectl top pods -A" : null,
  ])) : "Prometheus stack is disabled"
}

output "components" {
  description = "List of enabled monitoring components"
  value = concat(
    var.enable_prometheus_stack ? ["prometheus", "grafana", "alertmanager", "node-exporter", "kube-state-metrics"] : [],
    var.enable_metrics_server ? ["metrics-server"] : []
  )
}
