terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.1"
    }
  }
}

# ---------------------------------------------------------------------------
# Default-deny ingress + egress for the monitoring namespace.
# Selective allows are added below for known traffic patterns.
# ---------------------------------------------------------------------------

resource "kubernetes_network_policy_v1" "monitoring_default_deny" {
  count = var.install_monitoring ? 1 : 0

  metadata {
    name      = "default-deny-all"
    namespace = var.monitoring_namespace
  }

  spec {
    pod_selector {} # selects all pods in the namespace
    policy_types = ["Ingress", "Egress"]
    # No ingress/egress rules → deny all by default
  }
}

# Allow Prometheus to scrape kube-state-metrics and other in-namespace targets
resource "kubernetes_network_policy_v1" "monitoring_allow_intra_namespace" {
  count = var.install_monitoring ? 1 : 0

  metadata {
    name      = "allow-intra-namespace"
    namespace = var.monitoring_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = var.monitoring_namespace
          }
        }
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = var.monitoring_namespace
          }
        }
      }
    }
  }
}

# Allow DNS resolution (UDP/TCP 53) for all pods in monitoring namespace
resource "kubernetes_network_policy_v1" "monitoring_allow_dns" {
  count = var.install_monitoring ? 1 : 0

  metadata {
    name      = "allow-dns-egress"
    namespace = var.monitoring_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

# Allow Prometheus to reach the Kubernetes API server for service discovery
resource "kubernetes_network_policy_v1" "monitoring_allow_kube_api" {
  count = var.install_monitoring ? 1 : 0

  metadata {
    name      = "allow-kube-api-egress"
    namespace = var.monitoring_namespace
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "prometheus"
      }
    }
    policy_types = ["Egress"]

    egress {
      ports {
        port     = "443"
        protocol = "TCP"
      }
      ports {
        port     = "6443"
        protocol = "TCP"
      }
    }
  }
}

# Allow Grafana/Prometheus UIs to be reached via port-forward (from kubectl proxy)
resource "kubernetes_network_policy_v1" "monitoring_allow_ui_ingress" {
  count = var.install_monitoring ? 1 : 0

  metadata {
    name      = "allow-ui-ingress"
    namespace = var.monitoring_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    ingress {
      ports {
        port     = "3000"
        protocol = "TCP"
      }
      ports {
        port     = "9090"
        protocol = "TCP"
      }
      ports {
        port     = "80"
        protocol = "TCP"
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Default-deny for the opencost namespace
# ---------------------------------------------------------------------------

resource "kubernetes_network_policy_v1" "opencost_default_deny" {
  count = var.install_opencost ? 1 : 0

  metadata {
    name      = "default-deny-all"
    namespace = var.opencost_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# Allow opencost to reach Prometheus in the monitoring namespace
resource "kubernetes_network_policy_v1" "opencost_allow_prometheus_egress" {
  count = var.install_opencost ? 1 : 0

  metadata {
    name      = "allow-prometheus-egress"
    namespace = var.opencost_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = var.monitoring_namespace
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "prometheus"
          }
        }
      }
      ports {
        port     = "9090"
        protocol = "TCP"
      }
    }
  }
}

# Allow opencost DNS + UI ingress + Kubernetes API egress
resource "kubernetes_network_policy_v1" "opencost_allow_dns" {
  count = var.install_opencost ? 1 : 0

  metadata {
    name      = "allow-dns-egress"
    namespace = var.opencost_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "opencost_allow_ui_ingress" {
  count = var.install_opencost ? 1 : 0

  metadata {
    name      = "allow-ui-ingress"
    namespace = var.opencost_namespace
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

    ingress {
      ports {
        port     = "9090"
        protocol = "TCP"
      }
      ports {
        port     = "9003"
        protocol = "TCP"
      }
    }
  }
}
