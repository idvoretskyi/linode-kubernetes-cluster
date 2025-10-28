# Linode Kubernetes Cluster

A simple, clean OpenTofu template for deploying Kubernetes clusters on Linode (LKE).

## Features

- **Simple & Clean**: Flat structure with no complex modules or scripts
- **Cost Optimized**: Start with ~$24/month for a single-node cluster
- **Secure**: Built-in firewall rules and network policies
- **Production Ready**: Autoscaling, HA control plane options
- **Direct Commands**: No Makefile needed - use OpenTofu commands directly

## Prerequisites

- [OpenTofu](https://opentofu.org/) or Terraform 1.6+
- [Linode CLI](https://www.linode.com/docs/products/tools/cli/get-started/) (optional)
- kubectl
- Linode API token

## Quick Start

### 1. Get Your Linode Token

```bash
# Option 1: Configure linode-cli (recommended)
linode-cli configure

# Option 2: Set environment variable
export LINODE_TOKEN='your-token-here'
```

### 2. Configure Your Cluster

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferences
```

### 3. Deploy

```bash
cd infrastructure

# Initialize
tofu init

# Review the plan
tofu plan

# Deploy
tofu apply
```

### 4. Connect to Your Cluster

```bash
# Extract kubeconfig
tofu output -raw kubeconfig | base64 -d > kubeconfig.yaml

# Set environment variable
export KUBECONFIG=./kubeconfig.yaml

# Test connection
kubectl cluster-info
kubectl get nodes
```

### 5. Monitoring (Prometheus + Grafana + metrics-server)

This template includes an optional monitoring module that installs:
- kube-prometheus-stack (Prometheus + Grafana)
- metrics-server (used by HPA and kubectl top)

Because Helm/Kubernetes providers read your local kubeconfig, install monitoring in two phases:

1) Create the cluster (done above via `tofu apply`).
2) Export kubeconfig and re-apply to install monitoring:

```bash
cd infrastructure
tofu output -raw kubeconfig | base64 -d > kubeconfig.yaml
export KUBECONFIG="$PWD/kubeconfig.yaml"

# Install monitoring (Helm releases)
tofu apply
```

Access Grafana:
- Service type: NodePort (default)
- Port: 31000 (configurable)

```bash
kubectl -n monitoring get svc prometheus-stack-grafana

# If you have a public node IP, browse to:
#   http://<node-ip>:31000
# Or port-forward locally:
kubectl -n monitoring port-forward svc/prometheus-stack-grafana 3000:80
open http://localhost:3000
```

Defaults (PoC):
- Admin password: `admin` (set via chart values; change for production)
- Alertmanager: disabled
- Persistence: disabled (Grafana)
- metrics-server uses `--kubelet-insecure-tls` by default for dev clusters

You can control monitoring via `terraform.tfvars`:

```hcl
monitoring_namespace                    = "monitoring"
monitoring_enable_prometheus_stack      = true
monitoring_enable_metrics_server        = true
monitoring_grafana_nodeport             = 31000
monitoring_metrics_server_insecure_tls  = true   # set false for production
```

Outputs that help:
```bash
tofu output monitoring_namespace
tofu output monitoring_grafana_nodeport
tofu output monitoring_components
```

## Configuration

All configuration is done through [infrastructure/terraform.tfvars](infrastructure/terraform.tfvars.example):

### Basic Settings

```hcl
project_name = "my-project"
environment  = "dev"
cluster_name = "my-cluster"
region       = "us-east"
k8s_version  = "1.33"
```

### Node Pools

```hcl
node_pools = [
  {
    type  = "g6-standard-1"  # ~$24/month per node
    count = 1
    autoscaler = {
      min = 1
      max = 3
    }
  }
]
```

**Available Node Types:**
- `g6-standard-1`: 1 vCPU, 2GB RAM (~$24/month) - Dev/testing
- `g6-standard-2`: 2 vCPU, 4GB RAM (~$36/month) - Small production
- `g6-standard-4`: 4 vCPU, 8GB RAM (~$72/month) - Production

### High Availability

```hcl
control_plane_ha = true  # Adds ~$60/month for HA control plane
```

### Firewall

```hcl
firewall_enabled        = true
firewall_allowed_ips    = ["your.ip.address/32"]  # Restrict access
firewall_inbound_policy = "DROP"
```

## Cost Estimate

| Configuration | Monthly Cost |
|--------------|--------------|
| Dev (1 node, g6-standard-1) | ~$24 |
| Small Prod (2 nodes, g6-standard-2) | ~$72 |
| Prod HA (3 nodes, g6-standard-2, HA control plane) | ~$168 |

*LKE control plane (non-HA) is free. Prices subject to change.*

## Commands

```bash
# Initialize and deploy
tofu init
tofu plan
tofu apply

# Get outputs
tofu output
tofu output -raw kubeconfig | base64 -d > kubeconfig.yaml

# Destroy
tofu destroy
```

## Project Structure

```
.
├── README.md
├── CLAUDE.md                      # Claude Code instructions
├── LICENSE
├── infrastructure/
│   ├── main.tf                    # Main infrastructure (cluster + firewall)
│   ├── variables.tf               # Variable definitions
│   ├── outputs.tf                 # Output definitions
│   └── terraform.tfvars.example   # Example configuration
└── docs/                          # Additional documentation
```

**Design Philosophy:**
- No complex module hierarchies - all resources in main.tf
- No helper scripts - direct OpenTofu commands only
- No Makefile - keep it simple
- Single tfvars.example file - no environment directories

## Security Notes

1. **Restrict firewall access**: Change `firewall_allowed_ips` from `0.0.0.0/0` to your IP
2. **Token security**: Never commit `LINODE_TOKEN` or `terraform.tfvars` to git
3. **State file**: Contains sensitive data - store securely (consider remote state)

## Documentation

- [Architecture](docs/architecture/) - Design decisions and cluster architecture
- [Cost Analysis](docs/cost/) - Detailed cost breakdown
- [Operations](docs/runbooks/) - Management and troubleshooting
- [Examples](docs/examples/) - Sample workloads

## License

MIT
