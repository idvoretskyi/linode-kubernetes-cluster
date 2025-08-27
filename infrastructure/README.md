# Infrastructure

This directory contains the modularized OpenTofu infrastructure code for deploying Linode Kubernetes clusters.

## Structure

```
infrastructure/
├── main.tf                    # Root module configuration
├── variables.tf              # Input variables
├── outputs.tf                # Output values
├── modules/                  # Reusable modules
│   ├── lke-cluster/         # LKE cluster module
│   ├── firewall/            # Firewall module
│   └── monitoring/          # Monitoring stack (Prometheus/Grafana)
└── environments/            # Environment-specific configs
    ├── dev/                # Development environment
    ├── staging/            # Staging environment (template)
    └── prod/               # Production environment
```

## Quick Start

### 1. Choose Environment Configuration

```bash
# For development
cp environments/dev/terraform.tfvars terraform.tfvars

# For production
cp environments/prod/terraform.tfvars terraform.tfvars
```

### 2. Customize Configuration

Edit `terraform.tfvars` to match your requirements:

```hcl
# Basic required settings
region = "us-east"
firewall_allowed_ips = ["YOUR.IP.ADDRESS.HERE/32"]

# Optional customizations
cluster_name = "my-cluster"
project_name = "my-project"
```

### 3. Deploy Infrastructure

```bash
# Set your Linode API token
export LINODE_TOKEN="your-linode-api-token"

# Initialize and deploy
tofu init
tofu plan
tofu apply
```

### 4. Access Your Cluster

```bash
# Extract kubeconfig
tofu output -raw kubeconfig | base64 -d > kubeconfig.yaml
export KUBECONFIG=./kubeconfig.yaml

# Test connectivity
kubectl cluster-info
kubectl get nodes
```

## Modules

### LKE Cluster Module (`modules/lke-cluster/`)

Creates a Linode Kubernetes Engine cluster with:
- Configurable node pools
- Autoscaling support
- High availability options
- Comprehensive validation

**Usage:**
```hcl
module "lke_cluster" {
  source = "./modules/lke-cluster"

  cluster_name     = "my-cluster"
  region          = "us-east"
  k8s_version     = "1.33"
  control_plane_ha = false

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
}
```

### Firewall Module (`modules/firewall/`)

Creates a Linode Firewall with:
- Preset rules for common services
- Custom rule support
- IP allowlist configuration
- Security best practices

**Usage:**
```hcl
module "firewall" {
  source = "./modules/firewall"

  firewall_name = "cluster-firewall"
  allowed_ips   = ["203.0.113.0/24"]
  
  enable_ssh      = true
  enable_k8s_api  = true
  enable_nodeports = false  # Production security
}
```

## Environment Configurations

### Development (`environments/dev/`)
- Single node for cost optimization
- Open firewall for ease of development
- No high availability
- Estimated cost: ~$26/month

### Production (`environments/prod/`)
- Multiple nodes with autoscaling
- Restrictive firewall rules
- High availability control plane
- Estimated cost: ~$110+/month

## Security Considerations

### ⚠️ Before Open Sourcing

1. **Remove sensitive data** from all files
2. **Update firewall rules** - avoid `0.0.0.0/0` access
3. **Review all default values** for security implications
4. **Add comprehensive validation** for user inputs

### 🔒 Production Security

1. **Restrict IP access**: Update `firewall_allowed_ips`
2. **Disable SSH**: Set `firewall_enable_ssh = false` if not needed
3. **Disable NodePorts**: Set `firewall_enable_nodeports = false`
4. **Enable control plane HA**: Set `control_plane_ha = true`
5. **Use strong naming**: Avoid predictable cluster names

## Validation Features

The modules include comprehensive validation for:
- ✅ Cluster and resource naming conventions
- ✅ Valid Linode regions and instance types
- ✅ Kubernetes version format
- ✅ IP address CIDR formats
- ✅ Autoscaler configuration limits
- ✅ Firewall rule syntax
- ✅ Resource limits and quotas

## Cost Optimization

### Development Environment
```hcl
# Minimal cost configuration
node_pools = [
  {
    type  = "g6-standard-1"  # $24/month
    count = 1
    autoscaler = { min = 1, max = 2 }
  }
]
control_plane_ha = false     # Free
# Total: ~$26/month
```

### Production Environment
```hcl
# High availability configuration
node_pools = [
  {
    type  = "g6-standard-2"  # $36/month each
    count = 3
    autoscaler = { min = 2, max = 10 }
  }
]
control_plane_ha = true      # $60/month
# Total: ~$168/month baseline
```

## Troubleshooting

### Common Issues

**Module not found errors:**
```bash
# Ensure you're in the infrastructure/ directory
cd infrastructure/
tofu init
```

**Invalid CIDR block errors:**
```bash
# Check your firewall_allowed_ips format
firewall_allowed_ips = ["192.168.1.0/24"]  # Good
firewall_allowed_ips = ["192.168.1.1"]     # Bad - missing /32
```

**Resource naming conflicts:**
```bash
# Use a unique name_suffix
name_suffix = "abc123"
```

## Examples

See individual module README files for detailed examples:
- [LKE Cluster Examples](modules/lke-cluster/README.md)
- [Firewall Examples](modules/firewall/README.md)

## Contributing

When contributing to the infrastructure code:

1. **Test all changes** in development environment first
2. **Update documentation** for any new variables or outputs
3. **Add validation** for new input parameters
4. **Follow naming conventions** established in the modules
5. **Security review** any firewall or access changes

## Support

For issues with the infrastructure modules:
1. Check module documentation and examples
2. Validate your configuration with `tofu validate`
3. Review Linode provider documentation
4. Check Linode service status