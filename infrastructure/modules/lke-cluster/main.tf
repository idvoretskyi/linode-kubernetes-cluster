terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
  }
}

resource "linode_lke_cluster" "cluster" {
  k8s_version = var.k8s_version
  label       = var.cluster_name
  region      = var.region
  tags        = var.tags

  dynamic "pool" {
    for_each = var.node_pools
    content {
      type  = pool.value.type
      count = pool.value.count

      dynamic "autoscaler" {
        for_each = pool.value.autoscaler != null ? [pool.value.autoscaler] : []
        content {
          min = autoscaler.value.min
          max = autoscaler.value.max
        }
      }
    }
  }

  control_plane {
    high_availability = var.control_plane_ha
  }
}