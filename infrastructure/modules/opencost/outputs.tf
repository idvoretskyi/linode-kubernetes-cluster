output "namespace" {
  description = "Namespace where OpenCost is deployed"
  value       = helm_release.opencost.namespace
}

output "service_name" {
  description = "OpenCost service name"
  value       = helm_release.opencost.name
}

output "ui_port" {
  description = "OpenCost UI port"
  value       = 9003
}
