# Environment-specific resource presets
locals {
  environment_presets = {
    development = {
      prometheus = {
        retention = "7d"
        resources = {
          requests = { cpu = "100m", memory = "256Mi" }
          limits   = { cpu = "500m", memory = "1Gi" }
        }
        storage_enabled = false
        storage_size    = "5Gi"
      }
      grafana = {
        resources = {
          requests = { cpu = "50m", memory = "64Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
        storage_enabled = false
        storage_size    = "1Gi"
      }
      alertmanager = {
        resources = {
          requests = { cpu = "50m", memory = "64Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
        storage_enabled = false
        storage_size    = "1Gi"
      }
      metrics_server = {
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
      }
    }
    staging = {
      prometheus = {
        retention = "15d"
        resources = {
          requests = { cpu = "200m", memory = "512Mi" }
          limits   = { cpu = "1000m", memory = "2Gi" }
        }
        storage_enabled = true
        storage_size    = "10Gi"
      }
      grafana = {
        resources = {
          requests = { cpu = "100m", memory = "128Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
        storage_enabled = true
        storage_size    = "2Gi"
      }
      alertmanager = {
        resources = {
          requests = { cpu = "100m", memory = "128Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
        storage_enabled = true
        storage_size    = "2Gi"
      }
      metrics_server = {
        resources = {
          requests = { cpu = "100m", memory = "200Mi" }
          limits   = { cpu = "1000m", memory = "1Gi" }
        }
      }
    }
    production = {
      prometheus = {
        retention = "30d"
        resources = {
          requests = { cpu = "500m", memory = "1Gi" }
          limits   = { cpu = "2000m", memory = "4Gi" }
        }
        storage_enabled = true
        storage_size    = "50Gi"
      }
      grafana = {
        resources = {
          requests = { cpu = "200m", memory = "256Mi" }
          limits   = { cpu = "1000m", memory = "1Gi" }
        }
        storage_enabled = true
        storage_size    = "5Gi"
      }
      alertmanager = {
        resources = {
          requests = { cpu = "200m", memory = "256Mi" }
          limits   = { cpu = "1000m", memory = "1Gi" }
        }
        storage_enabled = true
        storage_size    = "5Gi"
      }
      metrics_server = {
        resources = {
          requests = { cpu = "200m", memory = "400Mi" }
          limits   = { cpu = "2000m", memory = "2Gi" }
        }
      }
    }
  }

  # Resolve environment preset
  current_preset = local.environment_presets[var.environment_preset]
  
  # Apply preset values with variable overrides
  final_prometheus_retention = var.prometheus_retention != "15d" ? var.prometheus_retention : local.current_preset.prometheus.retention
  final_prometheus_resources = var.prometheus_resources.requests.cpu != "200m" || var.prometheus_resources.requests.memory != "512Mi" ? var.prometheus_resources : local.current_preset.prometheus.resources
  final_prometheus_storage_enabled = var.prometheus_storage_enabled != true ? var.prometheus_storage_enabled : local.current_preset.prometheus.storage_enabled
  final_prometheus_storage_size = var.prometheus_storage_size != "10Gi" ? var.prometheus_storage_size : local.current_preset.prometheus.storage_size

  final_grafana_resources = var.grafana_resources.requests.cpu != "100m" || var.grafana_resources.requests.memory != "128Mi" ? var.grafana_resources : local.current_preset.grafana.resources
  final_grafana_storage_enabled = var.grafana_storage_enabled != true ? var.grafana_storage_enabled : local.current_preset.grafana.storage_enabled
  final_grafana_storage_size = var.grafana_storage_size != "2Gi" ? var.grafana_storage_size : local.current_preset.grafana.storage_size

  final_alertmanager_resources = var.alertmanager_resources.requests.cpu != "100m" || var.alertmanager_resources.requests.memory != "128Mi" ? var.alertmanager_resources : local.current_preset.alertmanager.resources
  final_alertmanager_storage_enabled = var.alertmanager_storage_enabled != false ? var.alertmanager_storage_enabled : local.current_preset.alertmanager.storage_enabled
  final_alertmanager_storage_size = var.alertmanager_storage_size != "1Gi" ? var.alertmanager_storage_size : local.current_preset.alertmanager.storage_size

  final_metrics_server_resources = var.metrics_server_resources.requests.cpu != "100m" || var.metrics_server_resources.requests.memory != "200Mi" ? var.metrics_server_resources : local.current_preset.metrics_server.resources
}