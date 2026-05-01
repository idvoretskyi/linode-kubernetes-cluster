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

# Metrics Server - provides resource metrics API for kubectl top and HPA
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_version
  namespace  = var.namespace

  timeout = 300
  wait    = true

  values = [
    yamlencode({
      # Required for Linode LKE compatibility
      args = [
        "--kubelet-insecure-tls",
        "--kubelet-preferred-address-types=InternalIP"
      ]
      # Right-sized for small/dev clusters
      resources = {
        requests = {
          cpu    = "50m"
          memory = "100Mi"
        }
        limits = {
          cpu    = "150m"
          memory = "200Mi"
        }
      }
      replicas = 1
      podDisruptionBudget = {
        enabled = false
      }
    })
  ]
}
