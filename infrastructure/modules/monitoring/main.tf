terraform {
  required_providers {
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "opentofu/helm"
      version = "3.1.0"
    }
  }
}

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Deploy kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
resource "helm_release" "kube_prometheus_stack" {
  count = var.enable_prometheus_stack ? 1 : 0

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "56.0.5"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # Wait for deployment to complete
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [
    yamlencode({
      # Prometheus configuration
      prometheus = {
        prometheusSpec = {
          retention = "7d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
        service = {
          type = "ClusterIP"
        }
      }

      # Grafana configuration
      grafana = {
        enabled       = true
        adminPassword = var.grafana_admin_password
        service = {
          type     = var.grafana_service_type
          nodePort = var.grafana_service_type == "NodePort" ? var.grafana_nodeport : null
        }
        persistence = {
          enabled = true
          size    = "5Gi"
        }
        # Default dashboards
        defaultDashboardsEnabled = true
        # Configure data sources
        datasources = {
          "datasources.yaml" = {
            apiVersion = 1
            datasources = [
              {
                name      = "Prometheus"
                type      = "prometheus"
                url       = "http://kube-prometheus-stack-prometheus:9090"
                access    = "proxy"
                isDefault = true
              }
            ]
          }
        }
      }

      # Alertmanager configuration
      alertmanager = {
        enabled = true
        service = {
          type = "ClusterIP"
        }
      }

      # Node exporter
      nodeExporter = {
        enabled = true
      }

      # Kube state metrics
      kubeStateMetrics = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# Deploy metrics-server
resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"
  namespace  = "kube-system"

  wait    = true
  timeout = 300

  values = [
    yamlencode({
      args = concat(
        [
          "--cert-dir=/tmp",
          "--secure-port=4443"
        ],
        var.metrics_server_insecure_tls ? ["--kubelet-insecure-tls"] : []
      )
      resources = {
        limits = {
          memory = "256Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
      }
    })
  ]
}
