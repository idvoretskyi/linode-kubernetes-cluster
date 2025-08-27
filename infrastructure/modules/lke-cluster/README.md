# LKE Cluster Module

This module creates a Linode Kubernetes Engine (LKE) cluster with configurable node pools and autoscaling.

## Features

- Configurable Kubernetes version
- Multiple node pools with different instance types
- Cluster autoscaling support
- High availability control plane option
- Comprehensive validation
- Resource tagging

## Usage

```hcl
module "lke_cluster" {
  source = "./modules/lke-cluster"

  cluster_name      = "my-k8s-cluster"
  region           = "us-east"
  k8s_version      = "1.33"
  control_plane_ha = false

  node_pools = [
    {
      type  = "g6-standard-1"
      count = 2
      autoscaler = {
        min = 1
        max = 5
      }
    }
  ]

  tags = ["production", "kubernetes", "project-name"]
}
```

## Requirements

| Name | Version |
|------|---------|
| linode | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| linode | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the Kubernetes cluster | `string` | n/a | yes |
| region | Linode region for the cluster | `string` | n/a | yes |
| k8s_version | Kubernetes version for the LKE cluster | `string` | `"1.33"` | no |
| node_pools | Configuration for node pools | `list(object)` | n/a | yes |
| control_plane_ha | Enable high availability for control plane | `bool` | `false` | no |
| tags | Tags to apply to resources | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the LKE cluster |
| cluster_label | The label of the LKE cluster |
| cluster_endpoint | The API server endpoint of the LKE cluster |
| cluster_status | The status of the LKE cluster |
| cluster_region | The region where the cluster is deployed |
| k8s_version | The Kubernetes version of the cluster |
| kubeconfig | Base64 encoded kubeconfig for the cluster |
| node_pools | Information about the node pools |
| dashboard_url | The dashboard URL for the cluster |

## Node Pool Configuration

The `node_pools` variable accepts a list of objects with the following structure:

```hcl
node_pools = [
  {
    type  = "g6-standard-1"  # Linode instance type
    count = 2               # Initial number of nodes
    autoscaler = {          # Optional autoscaling configuration
      min = 1               # Minimum nodes
      max = 5               # Maximum nodes
    }
  }
]
```

### Supported Instance Types

Common Linode instance types for LKE:
- `g6-standard-1`: 1 vCPU, 2GB RAM
- `g6-standard-2`: 2 vCPU, 4GB RAM
- `g6-standard-4`: 4 vCPU, 8GB RAM
- `g6-standard-6`: 6 vCPU, 16GB RAM

## Validation

The module includes comprehensive validation for:
- Cluster name length (1-32 characters)
- Valid Linode regions
- Kubernetes version format
- Node pool count limits (1-100)
- Autoscaler configuration (min >= 1, max >= min, max <= 100)
- Tag count limits (maximum 64)

## Examples

### Basic Cluster
```hcl
module "basic_cluster" {
  source = "./modules/lke-cluster"

  cluster_name = "basic-cluster"
  region      = "us-east"
  
  node_pools = [
    {
      type  = "g6-standard-1"
      count = 1
    }
  ]
}
```

### High Availability Cluster
```hcl
module "ha_cluster" {
  source = "./modules/lke-cluster"

  cluster_name      = "ha-cluster"
  region           = "us-east"
  control_plane_ha = true
  
  node_pools = [
    {
      type  = "g6-standard-2"
      count = 3
      autoscaler = {
        min = 2
        max = 10
      }
    }
  ]

  tags = ["production", "high-availability"]
}
```

### Multi-Pool Cluster
```hcl
module "multi_pool_cluster" {
  source = "./modules/lke-cluster"

  cluster_name = "multi-pool-cluster"
  region      = "us-east"
  
  node_pools = [
    {
      type  = "g6-standard-1"  # General workloads
      count = 2
      autoscaler = {
        min = 1
        max = 5
      }
    },
    {
      type  = "g6-standard-4"  # CPU-intensive workloads
      count = 1
      autoscaler = {
        min = 0
        max = 3
      }
    }
  ]
}
```