# Firewall Module

This module creates a Linode Firewall with configurable rules for securing Kubernetes clusters and other workloads.

## Features

- Default firewall policies (inbound DROP, outbound ACCEPT)
- Common preset rules for Kubernetes clusters
- Custom inbound/outbound rules support
- Automatic rule generation for SSH, HTTP, HTTPS, K8s API, and NodePorts
- IP allowlist configuration
- Resource tagging

## Usage

### Basic Usage with Presets
```hcl
module "k8s_firewall" {
  source = "./modules/firewall"

  firewall_name = "k8s-cluster-firewall"
  
  # Enable common services (default: all true)
  enable_ssh       = true
  enable_http      = true
  enable_https     = true
  enable_k8s_api   = true
  enable_nodeports = true
  
  # Restrict access to specific IPs
  allowed_ips = ["203.0.113.0/24", "198.51.100.0/24"]
  
  tags = ["kubernetes", "production"]
}
```

### Advanced Usage with Custom Rules
```hcl
module "custom_firewall" {
  source = "./modules/firewall"

  firewall_name   = "custom-firewall"
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"
  
  # Disable presets
  enable_ssh       = false
  enable_http      = false
  enable_https     = false
  enable_k8s_api   = false
  enable_nodeports = false
  
  # Custom inbound rules
  inbound_rules = [
    {
      label    = "custom-ssh"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "2222"
      ipv4     = ["192.168.1.0/24"]
      ipv6     = []
    },
    {
      label    = "database"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "5432"
      ipv4     = ["10.0.0.0/8"]
      ipv6     = []
    }
  ]
  
  # Custom outbound rules
  outbound_rules = [
    {
      label    = "dns"
      action   = "ACCEPT"
      protocol = "UDP"
      ports    = "53"
      ipv4     = ["0.0.0.0/0"]
      ipv6     = []
    }
  ]
  
  tags = ["custom", "secure"]
}
```

### Cluster Integration
```hcl
module "lke_cluster" {
  source = "./modules/lke-cluster"
  # ... cluster configuration
}

module "cluster_firewall" {
  source = "./modules/firewall"

  firewall_name = "${module.lke_cluster.cluster_label}-firewall"
  cluster_id    = module.lke_cluster.cluster_id
  
  # Allow access only from office network
  allowed_ips = ["203.0.113.0/24"]
  
  tags = module.lke_cluster.tags
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

### Required Inputs

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| firewall_name | Name of the firewall | `string` | yes |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| tags | Tags to apply to the firewall | `list(string)` | `[]` |
| inbound_policy | Default policy for inbound traffic | `string` | `"DROP"` |
| outbound_policy | Default policy for outbound traffic | `string` | `"ACCEPT"` |
| inbound_rules | Custom inbound firewall rules | `list(object)` | `[]` |
| outbound_rules | Custom outbound firewall rules | `list(object)` | `[]` |
| cluster_id | ID of cluster to attach firewall to | `string` | `null` |

### Preset Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_ssh | Enable SSH access (port 22) | `bool` | `true` |
| enable_http | Enable HTTP access (port 80) | `bool` | `true` |
| enable_https | Enable HTTPS access (port 443) | `bool` | `true` |
| enable_k8s_api | Enable Kubernetes API (port 6443) | `bool` | `true` |
| enable_nodeports | Enable NodePort range (30000-32767) | `bool` | `true` |
| allowed_ips | IP addresses/CIDRs allowed access | `list(string)` | `["0.0.0.0/0"]` |

## Outputs

| Name | Description |
|------|-------------|
| firewall_id | The ID of the created firewall |
| firewall_label | The label of the created firewall |
| firewall_status | The status of the firewall |
| inbound_policy | The default inbound policy |
| outbound_policy | The default outbound policy |
| inbound_rules | List of inbound rules applied |
| outbound_rules | List of outbound rules applied |

## Rule Structure

Custom rules use the following structure:

```hcl
{
  label    = "rule-name"        # Descriptive label
  action   = "ACCEPT"           # ACCEPT or DROP
  protocol = "TCP"              # TCP, UDP, or ICMP
  ports    = "80"               # Port or port range (e.g., "80", "80-90")
  ipv4     = ["0.0.0.0/0"]     # List of IPv4 CIDR blocks
  ipv6     = []                 # List of IPv6 CIDR blocks (optional)
}
```

## Security Best Practices

### Production Environment
```hcl
module "production_firewall" {
  source = "./modules/firewall"

  firewall_name = "prod-k8s-firewall"
  
  # Restrict SSH access
  enable_ssh = true
  allowed_ips = [
    "203.0.113.0/24",    # Office network
    "198.51.100.5/32"    # Bastion host
  ]
  
  # Disable direct NodePort access
  enable_nodeports = false
  
  tags = ["production", "secure"]
}
```

### Development Environment
```hcl
module "dev_firewall" {
  source = "./modules/firewall"

  firewall_name = "dev-k8s-firewall"
  
  # More permissive for development
  allowed_ips = ["0.0.0.0/0"]
  
  tags = ["development", "permissive"]
}
```

## Common Port References

| Service | Protocol | Port(s) | Description |
|---------|----------|---------|-------------|
| SSH | TCP | 22 | Secure Shell access |
| HTTP | TCP | 80 | Web traffic |
| HTTPS | TCP | 443 | Secure web traffic |
| Kubernetes API | TCP | 6443 | Cluster management |
| NodePorts | TCP | 30000-32767 | Kubernetes services |
| PostgreSQL | TCP | 5432 | Database |
| MySQL | TCP | 3306 | Database |
| Redis | TCP | 6379 | Cache |
| DNS | UDP | 53 | Domain resolution |

## Validation

The module includes validation for:
- Firewall name length (1-32 characters)
- Valid actions (ACCEPT/DROP)
- Valid protocols (TCP/UDP/ICMP)
- Valid CIDR blocks for IP addresses
- Tag count limits (maximum 64)

## Examples

See the `examples/` directory for complete usage examples.