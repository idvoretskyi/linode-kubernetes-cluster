output "namespace" {
  description = "Namespace where OpenCost is deployed"
  value       = var.namespace
}

output "service_name" {
  description = "OpenCost service name"
  value       = "opencost"
}

output "ui_port" {
  description = "OpenCost UI port"
  value       = 9090
}
