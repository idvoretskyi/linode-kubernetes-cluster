terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.1"
    }
  }
}

# Create monitoring namespace
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "kube-prometheus-stack"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Kube Prometheus Stack - comprehensive monitoring solution
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name

  create_namespace = false
  depends_on       = [kubernetes_namespace_v1.monitoring]

  wait          = true
  timeout       = 900
  wait_for_jobs = true

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = merge(
          {
            retention                               = var.prometheus_retention
            serviceMonitorSelectorNilUsesHelmValues = false
            podMonitorSelectorNilUsesHelmValues     = false
          },
          var.use_ephemeral_storage ? {} : {
            storageSpec = {
              volumeClaimTemplate = {
                spec = {
                  storageClassName = "linode-block-storage"
                  accessModes      = ["ReadWriteOnce"]
                  resources = {
                    requests = {
                      storage = var.prometheus_storage_size
                    }
                  }
                }
              }
            }
          }
        )
      }
      grafana = {
        enabled       = true
        adminPassword = var.grafana_admin_password
        persistence = var.use_ephemeral_storage ? {
          enabled = false
          } : {
          enabled          = true
          size             = var.grafana_storage_size
          storageClassName = "linode-block-storage"
        }
      }
      alertmanager = {
        enabled = true
        alertmanagerSpec = var.use_ephemeral_storage ? {} : {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "linode-block-storage"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.alertmanager_storage_size
                  }
                }
              }
            }
          }
        }
      }
      nodeExporter = {
        enabled = true
      }
      kubeStateMetrics = {
        enabled = true
      }
    })
  ]
}
