terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

# Metrics Server (required for HPA and kubectl top)
resource "helm_release" "metrics_server" {
  count = var.enabled && var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_version
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name

  values = [
    yamlencode({
      args = [
        "--cert-dir=/tmp",
        "--secure-port=4443",
        "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
        "--kubelet-use-node-status-port",
        "--metric-resolution=15s"
      ]
      resources = {
        requests = {
          cpu    = var.metrics_server_resources.requests.cpu
          memory = var.metrics_server_resources.requests.memory
        }
        limits = {
          cpu    = var.metrics_server_resources.limits.cpu
          memory = var.metrics_server_resources.limits.memory
        }
      }
    })
  ]

  # Allow longer wait for resources to become ready and rollback on failure
  timeout = 600
  wait    = true
  atomic  = true

  depends_on = [kubernetes_namespace.monitoring]
}

# Prometheus Stack (includes Prometheus, Alertmanager, Grafana, Node Exporter)
resource "helm_release" "prometheus_stack" {
  count = var.enabled && var.enable_prometheus_stack ? 1 : 0

  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.prometheus_stack_version
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name

  values = [
    yamlencode({
      # Prometheus configuration
      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention
          resources = {
            requests = {
              cpu    = var.prometheus_resources.requests.cpu
              memory = var.prometheus_resources.requests.memory
            }
            limits = {
              cpu    = var.prometheus_resources.limits.cpu
              memory = var.prometheus_resources.limits.memory
            }
          }
          storageSpec = var.prometheus_storage_enabled ? {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          } : null
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          ruleSelectorNilUsesHelmValues           = false
        }
      }

      # Grafana configuration
      grafana = {
        enabled       = var.enable_grafana
        adminPassword = var.grafana_admin_password
        resources = {
          requests = {
            cpu    = var.grafana_resources.requests.cpu
            memory = var.grafana_resources.requests.memory
          }
          limits = {
            cpu    = var.grafana_resources.limits.cpu
            memory = var.grafana_resources.limits.memory
          }
        }
        persistence = {
          enabled          = var.grafana_storage_enabled
          storageClassName = var.storage_class
          size             = var.grafana_storage_size
        }
        service = {
          type     = var.grafana_service_type
          nodePort = var.grafana_service_type == "NodePort" ? var.grafana_nodeport : null
        }
        ingress = {
          enabled = var.grafana_ingress_enabled
          hosts   = var.grafana_ingress_hosts
        }
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [{
              name            = "default"
              orgId           = 1
              folder          = ""
              type            = "file"
              disableDeletion = false
              editable        = true
              options = {
                path = "/var/lib/grafana/dashboards/default"
              }
            }]
          }
        }
        dashboards = {
          default = {
            kubernetes-cluster-dashboard = {
              gnetId     = 7249
              revision   = 1
              datasource = "Prometheus"
            }
            kubernetes-pod-overview = {
              gnetId     = 6336
              revision   = 1
              datasource = "Prometheus"
            }
            node-exporter-full = {
              gnetId     = 1860
              revision   = 33
              datasource = "Prometheus"
            }
          }
        }
      }

      # Alertmanager configuration
      alertmanager = {
        enabled = var.enable_alertmanager
        alertmanagerSpec = {
          resources = {
            requests = {
              cpu    = var.alertmanager_resources.requests.cpu
              memory = var.alertmanager_resources.requests.memory
            }
            limits = {
              cpu    = var.alertmanager_resources.limits.cpu
              memory = var.alertmanager_resources.limits.memory
            }
          }
          storage = var.alertmanager_storage_enabled ? {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.alertmanager_storage_size
                  }
                }
              }
            }
          } : null
        }
      }

      # Node Exporter configuration
      nodeExporter = {
        enabled = var.enable_node_exporter
      }

      # Kube State Metrics configuration
      kubeStateMetrics = {
        enabled = var.enable_kube_state_metrics
      }
    })
  ]

  # Allow longer wait for resources to become ready and rollback on failure
  timeout = 1200
  wait    = true
  atomic  = true

  depends_on = [kubernetes_namespace.monitoring]
}

# Custom ServiceMonitor for additional monitoring
resource "kubernetes_manifest" "custom_service_monitors" {
  count = var.enabled && length(var.custom_service_monitors) > 0 ? length(var.custom_service_monitors) : 0

  manifest = var.custom_service_monitors[count.index]

  depends_on = [helm_release.prometheus_stack]
}

# Monitoring dashboard ConfigMaps
resource "kubernetes_config_map" "monitoring_dashboards" {
  count = var.enabled && length(var.custom_dashboards) > 0 ? length(var.custom_dashboards) : 0

  metadata {
    name      = var.custom_dashboards[count.index].name
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "${var.custom_dashboards[count.index].name}.json" = var.custom_dashboards[count.index].content
  }

  depends_on = [helm_release.prometheus_stack]
}