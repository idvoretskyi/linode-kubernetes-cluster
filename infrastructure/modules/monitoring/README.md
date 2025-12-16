# Monitoring Module

This module provisions cluster monitoring components for a Linode-hosted Kubernetes cluster. It is intended to be used from the root `infrastructure/` stack and deploys observability tooling via Helm and direct Kubernetes resources.

## Features
- Installs core monitoring Helm charts (e.g., Prometheus stack, Grafana) via the Helm provider.
- Exposes required outputs for integration with the rest of the stack.
- Configurable namespaces, chart versions, and resource tuning via variables.

## Usage
Example usage from a parent stack:

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name       = var.cluster_name
  monitoring_enabled = true

  # Optional overrides
  prometheus_chart_version = "<pin-your-version>"
  grafana_admin_password   = var.grafana_admin_password
}
```

Run with OpenTofu:
```bash
tofu init
tofu plan
tofu apply
```

## Inputs
- `cluster_name` (string): Logical name of the target cluster.
- `monitoring_enabled` (bool): Toggle to enable/disable deployment.
- `prometheus_chart_version` (string): Optional chart version pin.
- `grafana_admin_password` (string, sensitive): Admin password for Grafana.

Refer to [variables.tf](./variables.tf) for the authoritative list and defaults.

## Outputs
Common outputs include:
- `grafana_url`: Exposed service URL or ingress for Grafana.
- `prometheus_endpoint`: Endpoint for Prometheus queries.

See [outputs.tf](./outputs.tf) for exact output names and types.

## Notes
- This module uses providers compatible with OpenTofu. Ensure you run `tofu` commands instead of Terraform.
- Pin chart versions for reproducibility in production.