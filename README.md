# Linode Kubernetes Cluster

A modular OpenTofu template for deploying production-ready Kubernetes clusters on Linode with comprehensive monitoring.

## Features

- **Modular Architecture**: Reusable components for cluster, firewall, and monitoring
- **Cost Optimized**: Environment-specific configurations for development and production
- **CNCF Technologies**: Kubernetes, Prometheus, Grafana, and other cloud-native tools
- **Production Ready**: Complete observability stack and operational procedures
- **Security Focused**: Hardened configurations and best practices

## Prerequisites

- OpenTofu (or Terraform 1.6+)
- kubectl
- linode-cli configured with your API token (`linode-cli configure`)

## Quick Start

```bash
# Setup environment
make dev  # or make prod

# Deploy infrastructure (token auto-detected from linode-cli)
make init plan apply

# Access cluster
make kubeconfig
export KUBECONFIG=./kubeconfig.yaml
kubectl cluster-info
```

## Components

- **LKE Cluster**: Managed Kubernetes with autoscaling
- **Firewall**: Security rules and network policies  
- **Monitoring**: Prometheus, Grafana, and metrics collection
- **Documentation**: Architecture guides and runbooks

## Documentation

- [Infrastructure](infrastructure/README.md) - OpenTofu modules and configuration
- [Architecture](docs/architecture/) - Design decisions and cluster overview
- [Cost Analysis](docs/cost/) - Pricing and optimization strategies
- [Operations](docs/runbooks/) - Management and troubleshooting guides
- [Examples](docs/examples/) - Sample workloads and configurations

## License

MIT