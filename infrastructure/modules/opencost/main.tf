terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}

# Create namespace for OpenCost
resource "kubernetes_namespace" "opencost" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "opencost"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# OpenCost - Kubernetes cost monitoring and management
resource "helm_release" "opencost" {
  depends_on = [kubernetes_namespace.opencost]
  name       = "opencost"
  repository = "https://opencost.github.io/opencost-helm-chart"
  chart      = "opencost"
  version    = var.opencost_version
  namespace  = var.namespace

  timeout = 300
  wait    = true

  values = [
    yamlencode({
      # OpenCost configuration
      opencost = {
        exporter = {
          defaultClusterId = var.cluster_id
          cloudProviderApiKey = ""  # Not needed for Linode
        }
        prometheus = {
          internal = {
            enabled = true
            serviceName = var.prometheus_service_name
            namespaceName = var.prometheus_namespace
            port = 9090
          }
        }
        ui = {
          enabled = true
        }
      }
      # Resource limits
      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
      # Service configuration
      service = {
        type = "ClusterIP"
        port = 9003
      }
    })
  ]
}
