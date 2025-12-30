# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a modern, simplified OpenTofu template for provisioning cost-effective Linode Kubernetes clusters (LKE) with optional monitoring. The project has been refactored (December 2024) to follow best practices from the linode-gpu-k8s repository, featuring automatic kubeconfig merging, improved provider configurations, and modular monitoring components.

## Technology Stack

- **Infrastructure as Code**: OpenTofu 1.6+ (Terraform-compatible)
- **Cloud Provider**: Linode LKE (Managed Kubernetes)
- **Providers**: Linode (~3.5), Kubernetes (~3.0), Helm (~3.0)
- **Monitoring**: kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
- **Metrics**: metrics-server for kubectl top and HPA

## Prerequisites

Essential tools:
- OpenTofu (or Terraform 1.6+)
- kubectl
- linode-cli (optional, for token management)

Verification:
```bash
tofu version
kubectl version --client
linode-cli --version
```

## Repository Structure

```
.
├── infrastructure/
│   ├── main.tf                           # Main infrastructure + kubeconfig merge
│   ├── variables.tf                      # Variable definitions with validations
│   ├── outputs.tf                        # Helpful outputs with commands
│   ├── terraform.tfvars.example          # Example configuration
│   └── modules/
│       ├── metrics-server/               # Metrics Server module
│       └── kube-prometheus-stack/        # Monitoring stack module
├── docs/                                 # Additional documentation
├── CLAUDE.md                             # This file
└── README.md                             # User-facing documentation
```

## Development Commands

### Infrastructure Management
```bash
cd infrastructure/

# Set Linode token (get from linode-cli config)
export LINODE_TOKEN=$(linode-cli configure get token)
# Or manually: export LINODE_TOKEN='your-token-here'

# Initialize
tofu init

# Plan changes
tofu plan

# Apply changes (kubeconfig auto-merged to ~/.kube/config)
tofu apply

# Check cluster
kubectl get nodes

# Destroy
tofu destroy
```

## Architecture Principles

### Modern OpenTofu Patterns
- **Automatic kubeconfig merging**: No local kubeconfig file needed, merges to ~/.kube/config
- **Provider chaining**: Kubernetes and Helm providers use cluster kubeconfig directly
- **Username-based naming**: Uses system username by default for cluster prefix
- **Conditional modules**: Monitoring and metrics-server are optional
- **terraform_data resource**: For kubeconfig merge provisioner

### Cost Optimization
- Default to smallest instance types (g6-standard-1, ~$24/month per node)
- LKE control plane is free (non-HA) or $60/month (HA)
- Autoscaling enabled by default (min=1, max=5)
- Optional monitoring (can be disabled to save resources)

### Security
- Firewall enabled by default with configurable rules
- Separate IP allowlists for kubectl, monitoring, and NodePorts
- Token via environment variable (LINODE_TOKEN)
- Sensitive outputs properly marked
- Firewall attached to cluster nodes automatically

## Key Features (2024 Refactoring)

### 1. Automatic Kubeconfig Management
- Merges kubeconfig into `~/.kube/config` automatically
- Creates backup before merging
- Sets context as active
- No local kubeconfig file needed

### 2. Improved Provider Configuration
- Kubernetes provider uses cluster kubeconfig directly
- Helm provider configured with same credentials
- No complex `try()` workarounds needed

### 3. Modular Monitoring
- **metrics-server**: Enables `kubectl top` and HPA (Horizontal Pod Autoscaling)
- **kube-prometheus-stack**: Full monitoring with Prometheus, Grafana, Alertmanager
- Both modules are optional (set `install_metrics_server=false` or `install_monitoring=false`)

### 4. Enhanced Variables
- Input validation for regions, IPs, Kubernetes version
- Separate firewall rules for kubectl, monitoring, and general access
- Sensible defaults for all variables

### 5. Helpful Outputs
- `setup_commands`: Copy-paste commands to access cluster
- `monitoring_access_commands`: Instructions for accessing Grafana/Prometheus
- `cluster_info`: Summary of all cluster details

## Configuration

All configuration via `terraform.tfvars`:

```hcl
# Cluster naming (empty = uses system username)
cluster_name_prefix = ""

# Cluster configuration
region              = "us-east"
kubernetes_version  = "1.34"        # Latest: 1.34
ha_control_plane    = false

# Node pools
node_pools = [
  {
    type  = "g6-standard-1"
    count = 3
    autoscaler = {
      min = 1
      max = 5
    }
  }
]

# Firewall
firewall_enabled          = true
firewall_enable_nodeports = true
allowed_kubectl_ips       = ["0.0.0.0/0"]  # Change for production!
allowed_monitoring_ips    = ["0.0.0.0/0"]  # Change for production!

# Monitoring (optional)
install_monitoring      = true
install_metrics_server  = true
grafana_admin_password  = "admin"  # Change in production!
```

## Common Operations

### First Deployment
```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
export LINODE_TOKEN=$(linode-cli configure get token)
# Or manually: export LINODE_TOKEN='your-token-here'
tofu init
tofu apply
```

### Access Cluster
```bash
# Kubeconfig is already merged to ~/.kube/config
kubectl config use-context lke<CLUSTER_ID>-ctx
kubectl get nodes
kubectl get pods -A
```

### Access Monitoring (if enabled)
```bash
# Grafana (default: admin/admin)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Visit: http://localhost:3000

# Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Visit: http://localhost:9090

# Check resource usage (if metrics-server installed)
kubectl top nodes
kubectl top pods -A
```

### Update Cluster
```bash
# Edit terraform.tfvars (e.g., change node count, add monitoring)
tofu plan
tofu apply
```

### Cleanup
```bash
# List contexts
kubectl config get-contexts

# Delete cluster
tofu destroy

# Clean up kubectl context (optional)
kubectl config delete-context lke<CLUSTER_ID>-ctx
```

## Modules

### metrics-server
- **Purpose**: Provides resource metrics API for `kubectl top` and HPA
- **Chart**: kubernetes-sigs/metrics-server v3.12.2
- **Configuration**: Optimized for Linode LKE (--kubelet-insecure-tls)
- **HA**: 2 replicas with pod disruption budget

### kube-prometheus-stack
- **Purpose**: Comprehensive monitoring with Prometheus, Grafana, Alertmanager
- **Chart**: prometheus-community/kube-prometheus-stack v80.8.0
- **Storage**: Uses Linode block storage (linode-block-storage-retain)
- **Components**:
  - Prometheus (50Gi storage, 15d retention)
  - Grafana (10Gi storage)
  - Alertmanager (10Gi storage)
  - Node Exporter
  - Kube State Metrics

## Troubleshooting

### Provider Configuration Errors
The refactored code uses direct kubeconfig parsing in providers, which requires the cluster to exist first. If you see provider errors:
1. The cluster creates successfully on first apply
2. Monitoring modules install on the same apply (after cluster exists)

### Kubeconfig Not Merged
If kubeconfig isn't automatically merged:
```bash
# Manual merge
tofu output -raw kubeconfig | base64 -d > /tmp/kubeconfig-lke.yaml
KUBECONFIG=~/.kube/config:/tmp/kubeconfig-lke.yaml kubectl config view --flatten > ~/.kube/config.tmp
mv ~/.kube/config.tmp ~/.kube/config
```

### Monitoring Pods Not Starting
```bash
# Check pods
kubectl get pods -n monitoring

# Check storage
kubectl get pvc -n monitoring

# Check events
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

## Security Best Practices

1. **Never commit secrets**: Add `terraform.tfvars` to `.gitignore`
2. **Restrict firewall IPs**: Replace `0.0.0.0/0` with your actual IP/CIDR
3. **Change Grafana password**: Set strong `grafana_admin_password` in production
4. **Use remote state**: Configure S3/Terraform Cloud backend for team collaboration
5. **Enable HA control plane**: Set `ha_control_plane = true` for production

## Comparison to Original

### What Changed (December 2024 Refactoring)
✅ **Updated provider versions**: Kubernetes ~3.0, Helm ~3.0, Linode ~3.5
✅ **Automatic kubeconfig merge**: Uses terraform_data + local-exec provisioner
✅ **Modular monitoring**: Separated into metrics-server and kube-prometheus-stack
✅ **Simplified variables**: Removed unused variables, added validations
✅ **Better outputs**: Helpful commands and cluster info
✅ **Username-based naming**: Auto-generates cluster prefix from whoami
✅ **Improved firewall**: Separate rules for kubectl, monitoring, NodePorts

### What Stayed the Same
✅ Linode LKE as the managed Kubernetes platform
✅ Cost-optimized defaults (g6-standard-1 instances)
✅ Autoscaling support
✅ Terraform/OpenTofu compatibility

## Inspiration

This refactoring was inspired by https://github.com/idvoretskyi/linode-gpu-k8s, which demonstrates modern OpenTofu patterns for Linode LKE clusters, including automatic kubeconfig management, modular Helm deployments, and clean separation of concerns.
