# Monitoring Module

This module deploys a comprehensive monitoring stack for Kubernetes clusters including Prometheus, Grafana, Alertmanager, metrics-server, and related components.

## Features

- **Metrics Server**: Resource metrics for `kubectl top` and HPA
- **Prometheus Stack**: Time-series database for metrics collection
- **Grafana**: Visualization dashboard with pre-configured dashboards
- **Alertmanager**: Alert routing and management
- **Node Exporter**: Host-level metrics collection
- **Kube State Metrics**: Cluster state metrics
- **Environment Presets**: Optimized resource configurations for dev/staging/prod
- **Persistent Storage**: Optional storage for data retention
- **Custom Dashboards**: Support for custom Grafana dashboards

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitoring Namespace                     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Grafana   │  │ Prometheus  │  │   Alertmanager     │  │
│  │             │  │             │  │                    │  │
│  │ Dashboard   │◄─┤  Metrics    │◄─┤  Alert Routing     │  │
│  │ NodePort    │  │  Storage    │  │  Notifications     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │Node Exporter│  │Kube State   │  │  Metrics Server    │  │
│  │(DaemonSet)  │  │Metrics      │  │                    │  │
│  │             │  │             │  │  kubectl top       │  │
│  │Host Metrics │  │K8s Metrics  │  │  HPA Support       │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  enabled = true
  namespace = "monitoring"
  
  # Use development preset
  environment_preset = "development"
  
  tags = ["monitoring", "prometheus", "grafana"]
}
```

### Production Configuration

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  enabled = true
  namespace = "monitoring"
  
  # Production preset with custom overrides
  environment_preset = "production"
  
  # Custom Grafana configuration
  grafana_admin_password = "secure-password-here"
  grafana_service_type   = "LoadBalancer"
  
  # Extended retention
  prometheus_retention = "90d"
  
  # Persistent storage
  prometheus_storage_enabled = true
  grafana_storage_enabled    = true
  
  tags = ["monitoring", "prometheus", "grafana", "production"]
}
```

### Development Configuration

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  enabled = true
  
  # Development preset - minimal resources, no persistence
  environment_preset = "development"
  
  # Disable some components for cost savings
  enable_alertmanager = false
  
  # Shorter retention for development
  prometheus_retention = "3d"
  
  tags = ["monitoring", "development"]
}
```

## Environment Presets

The module includes three environment presets that automatically configure resource requests, limits, and storage settings:

### Development
- **Use Case**: Local development, testing, cost-minimal setups
- **Retention**: 7 days
- **Storage**: Disabled by default (ephemeral)
- **Resources**: Minimal CPU/memory allocations
- **Components**: All enabled but with reduced resources

### Staging  
- **Use Case**: Pre-production testing, integration environments
- **Retention**: 15 days
- **Storage**: Enabled with moderate sizes
- **Resources**: Moderate CPU/memory allocations
- **Components**: Full stack with production-like configuration

### Production
- **Use Case**: Production workloads, long-term monitoring
- **Retention**: 30 days
- **Storage**: Enabled with larger persistent volumes
- **Resources**: High CPU/memory allocations for performance
- **Components**: Full stack optimized for reliability and performance

## Variables

### Core Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| enabled | Enable/disable the monitoring stack | `bool` | `true` |
| namespace | Kubernetes namespace for monitoring | `string` | `"monitoring"` |
| environment_preset | Environment preset (development/staging/production) | `string` | `"development"` |
| storage_class | Storage class for persistent volumes | `string` | `"linode-block-storage"` |

### Component Toggles

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| enable_metrics_server | Enable metrics-server | `bool` | `true` |
| enable_prometheus_stack | Enable Prometheus stack | `bool` | `true` |
| enable_grafana | Enable Grafana | `bool` | `true` |
| enable_alertmanager | Enable Alertmanager | `bool` | `true` |
| enable_node_exporter | Enable Node Exporter | `bool` | `true` |
| enable_kube_state_metrics | Enable kube-state-metrics | `bool` | `true` |

### Prometheus Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| prometheus_retention | Data retention period | `string` | `"15d"` |
| prometheus_storage_enabled | Enable persistent storage | `bool` | `true` |
| prometheus_storage_size | Storage size | `string` | `"10Gi"` |

### Grafana Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| grafana_admin_password | Admin password | `string` | `"admin"` |
| grafana_service_type | Service type | `string` | `"NodePort"` |
| grafana_nodeport | NodePort number | `number` | `31000` |
| grafana_storage_enabled | Enable persistent storage | `bool` | `true` |
| grafana_storage_size | Storage size | `string` | `"2Gi"` |

## Outputs

### Access Information

| Output | Description |
|--------|-------------|
| access_instructions | Complete access instructions for all services |
| grafana_nodeport | Grafana NodePort number |
| grafana_admin_password | Grafana admin password (sensitive) |

### Component Status

| Output | Description |
|--------|-------------|
| namespace_name | Monitoring namespace name |
| prometheus_enabled | Prometheus deployment status |
| grafana_enabled | Grafana deployment status |
| metrics_server_enabled | Metrics server deployment status |

## Accessing Services

### Grafana Dashboard

**NodePort Access (default)**:
```bash
# Get cluster node IP
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

# Access Grafana
open http://$NODE_IP:31000
# Username: admin
# Password: (see terraform output)
```

**Port Forward Access**:
```bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
open http://localhost:3000
```

### Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
open http://localhost:9090
```

### Alertmanager

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093
open http://localhost:9093
```

## Pre-configured Dashboards

The module includes several pre-configured Grafana dashboards:

1. **Kubernetes Cluster Overview** (GrafanaLabs 7249)
   - Cluster-wide resource utilization
   - Node status and capacity
   - Pod distribution

2. **Kubernetes Pod Overview** (GrafanaLabs 6336)
   - Pod resource usage
   - Container metrics
   - Network and storage metrics

3. **Node Exporter Full** (GrafanaLabs 1860)
   - Detailed host-level metrics
   - CPU, memory, disk, network
   - System health indicators

## Custom Dashboards

You can add custom dashboards via the `custom_dashboards` variable:

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  custom_dashboards = [
    {
      name    = "my-application-dashboard"
      content = file("${path.module}/dashboards/my-app.json")
    }
  ]
}
```

## Troubleshooting

### Common Issues

**Metrics Server not working**:
```bash
# Check metrics server status
kubectl get pods -n monitoring | grep metrics-server

# Test metrics
kubectl top nodes
kubectl top pods -A
```

**Grafana not accessible**:
```bash
# Check service
kubectl get svc -n monitoring | grep grafana

# Check pod logs
kubectl logs -n monitoring deployment/prometheus-stack-grafana
```

**Prometheus data not persisting**:
```bash
# Check PVC status
kubectl get pvc -n monitoring

# Check storage class
kubectl get storageclass
```

### Resource Requirements

**Minimum Node Requirements**:
- Development: 2 CPU, 4GB RAM
- Staging: 4 CPU, 8GB RAM  
- Production: 8 CPU, 16GB RAM

**Storage Requirements**:
- Prometheus: 5-50GB (depending on retention and cluster size)
- Grafana: 1-5GB (for dashboards and configuration)
- Alertmanager: 1-5GB (for alert state and silences)

## Security Considerations

1. **Grafana Password**: Change the default admin password in production
2. **Network Access**: Consider using ingress with TLS instead of NodePort
3. **RBAC**: The helm charts create appropriate RBAC rules
4. **Storage**: Use encrypted storage classes for sensitive environments
5. **Secrets**: Store sensitive configuration in Kubernetes secrets

## Cost Optimization

**Development Environment**:
- Disable persistent storage (`*_storage_enabled = false`)
- Reduce retention period (`prometheus_retention = "3d"`)
- Disable Alertmanager (`enable_alertmanager = false`)

**Production Environment**:
- Monitor actual resource usage and adjust limits
- Use appropriate storage classes (cheaper for archive data)
- Configure data retention policies based on compliance needs

## Dependencies

- Kubernetes 1.20+
- Helm provider
- Kubernetes provider  
- Storage class (for persistent volumes)
- Sufficient cluster resources