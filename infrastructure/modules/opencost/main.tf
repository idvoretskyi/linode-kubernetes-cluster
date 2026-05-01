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

# Create namespace for OpenCost with Pod Security Standards labels.
# opencost runs as a normal deployment → baseline enforce is sufficient.
resource "kubernetes_namespace_v1" "opencost" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"             = "opencost"
      "app.kubernetes.io/managed-by"       = "opentofu"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

# OpenCost - Kubernetes cost monitoring and management
resource "helm_release" "opencost" {
  depends_on = [kubernetes_namespace_v1.opencost]
  name       = "opencost"
  repository = "https://opencost.github.io/opencost-helm-chart"
  chart      = "opencost"
  version    = var.opencost_version
  namespace  = var.namespace

  timeout = 300
  wait    = true

  values = [
    yamlencode({
      opencost = {
        exporter = {
          defaultClusterId    = var.cluster_id
          cloudProviderApiKey = "" # Not needed for Linode
        }
        prometheus = {
          internal = {
            enabled       = true
            serviceName   = var.prometheus_service_name
            namespaceName = var.prometheus_namespace
            port          = 9090
          }
        }
        ui = {
          enabled = true
        }
      }
      # Right-sized for small/dev clusters
      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
        limits = {
          cpu    = "200m"
          memory = "256Mi"
        }
      }
      service = {
        type = "ClusterIP"
        port = 9003
      }
    })
  ]
}
