# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a clean, simple OpenTofu template for provisioning cost-effective Linode Kubernetes clusters (LKE). The project has been refactored to use a flat, straightforward structure without complex module hierarchies or helper scripts.

## Technology Stack

- **Infrastructure as Code**: OpenTofu (Terraform-compatible)
- **Cloud Provider**: Linode LKE (Managed Kubernetes)
- **Container Runtime**: containerd (managed by LKE)

## Prerequisites

Essential tools:
- OpenTofu (or Terraform 1.6+)
- kubectl
- linode-cli (optional, for token management)

Verification:
```bash
tofu version
kubectl version --client
```

## Repository Structure

```
.
├── infrastructure/
│   ├── main.tf                    # Main infrastructure (cluster + firewall)
│   ├── variables.tf               # Variable definitions
│   ├── outputs.tf                 # Output definitions
│   └── terraform.tfvars.example   # Example configuration
├── docs/                          # Additional documentation
└── README.md                      # User-facing documentation
```

## Development Commands

### Infrastructure Management
```bash
cd infrastructure/

# Initialize
tofu init

# Plan changes
tofu plan

# Apply changes
tofu apply

# Get kubeconfig
tofu output -raw kubeconfig | base64 -d > kubeconfig.yaml
export KUBECONFIG=./kubeconfig.yaml

# Destroy
tofu destroy
```

## Architecture Principles

### Simplicity First
- **Single file infrastructure**: All resources in main.tf
- **No complex modules**: Flat structure for easy understanding
- **No scripts**: Direct OpenTofu commands only
- **Minimal dependencies**: Only Linode and Random providers

### Cost Optimization
- Default to smallest instance types (g6-standard-1, ~$24/month)
- LKE control plane is free (non-HA)
- Autoscaling enabled by default (min=1, max=3)

### Security
- Firewall enabled by default
- Configurable allowed IPs
- Token via environment variable (LINODE_TOKEN)
- Sensitive outputs marked as sensitive

## Configuration

All configuration via `terraform.tfvars`:

```hcl
# Basic settings
project_name = "my-project"
environment  = "dev"
cluster_name = "my-cluster"
region       = "us-east"
k8s_version  = "1.33"

# Node pools
node_pools = [
  {
    type  = "g6-standard-1"
    count = 1
    autoscaler = {
      min = 1
      max = 3
    }
  }
]

# Firewall
firewall_enabled     = true
firewall_allowed_ips = ["0.0.0.0/0"]  # Change for production!
```

## Key Changes from Previous Version

1. **Removed Makefile**: Direct OpenTofu commands instead
2. **Removed scripts/**: No helper scripts needed
3. **Flattened modules**: All resources in single main.tf
4. **Removed monitoring module**: Keep it simple, add later if needed
5. **Removed environment directories**: Single tfvars.example file
6. **Simplified outputs**: Only essential cluster information

## Common Operations

### First deployment
```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
export LINODE_TOKEN='your-token'
tofu init
tofu apply
```

### Get kubeconfig
```bash
tofu output -raw kubeconfig | base64 -d > kubeconfig.yaml
export KUBECONFIG=./kubeconfig.yaml
kubectl get nodes
```

### Update cluster
```bash
# Edit terraform.tfvars
tofu plan
tofu apply
```

### Destroy cluster
```bash
tofu destroy
```

## Security Notes

1. Never commit `terraform.tfvars` or `LINODE_TOKEN`
2. Restrict `firewall_allowed_ips` in production
3. State file contains sensitive data - use remote state for production
4. All secrets passed via environment variables

## Future Enhancements

Optional additions that can be made later:
- Remote state backend (S3, Terraform Cloud)
- Monitoring stack (Prometheus/Grafana via Helm)
- GitOps setup (Flux or ArgoCD)
- Custom CNI (Cilium)
- Additional node pools for different workloads
