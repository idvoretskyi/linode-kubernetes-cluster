terraform {
  required_version = ">= 1.6"

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 3.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
  }
}

# Provider will automatically use LINODE_TOKEN environment variable
provider "linode" {}

# Kubernetes provider - uses parsed kubeconfig locals from locals.tf
provider "kubernetes" {
  host                   = local.cluster_host
  token                  = local.cluster_token
  cluster_ca_certificate = local.cluster_ca_cert
}

# Helm provider - same kubeconfig credentials
provider "helm" {
  kubernetes = {
    host                   = local.cluster_host
    token                  = local.cluster_token
    cluster_ca_certificate = local.cluster_ca_cert
  }
}
