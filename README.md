# Akamai LKE Cluster

[![OpenTofu Validate](https://github.com/idvoretskyi/akamai-lke-cluster/actions/workflows/tofu-validate.yml/badge.svg)](https://github.com/idvoretskyi/akamai-lke-cluster/actions/workflows/tofu-validate.yml)
[![Security Scanning](https://github.com/idvoretskyi/akamai-lke-cluster/actions/workflows/security.yml/badge.svg)](https://github.com/idvoretskyi/akamai-lke-cluster/actions/workflows/security.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[![OpenTofu](https://img.shields.io/badge/OpenTofu-%E2%89%A5%201.6-844FBA)](https://opentofu.org/)
[![Linode](https://img.shields.io/badge/Cloud-Linode%20LKE-00A95C)](https://www.linode.com/products/kubernetes/)
[![CIS Kubernetes](https://img.shields.io/badge/CIS_K8s-Section_5_Baseline-1F6FEB)](docs/security/cis-compliance.md)
[![Pod Security](https://img.shields.io/badge/Pod_Security-baseline-success)](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
[![Scanned with Trivy](https://img.shields.io/badge/Scanned_with-Trivy-1904DA)](https://trivy.dev/)
[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-success)](.github/dependabot.yml)

A minimal, cost-optimized OpenTofu template for provisioning Linode Kubernetes Engine (LKE) clusters with optional add-ons (metrics-server, kube-prometheus-stack, OpenCost).

Defaults target a **dev/non-production cluster at ~$24/month** (1 × `g6-standard-1` node, no monitoring storage). Add-ons are opt-in to keep the bill predictable.

> **Note on spot instances:** Linode LKE does not currently offer spot/preemptible nodes. The cheapest option is the smallest shared-CPU plan (`g6-standard-1`).

## Features

- Minimum-viable footprint: 1 node, no persistent storage by default
- Automatic kubeconfig merging into `~/.kube/config`
- Opt-in add-ons: `metrics-server`, `kube-prometheus-stack`, `opencost`
- Optional ephemeral (emptyDir) monitoring storage for zero block-storage cost
- Built-in firewall with kubectl, monitoring, and NodePort allowlists
- Autoscaling node pools (default: 1 → 3 nodes)
- Pod Security Standards (`baseline` enforce, `restricted` audit/warn) on all add-on namespaces
- Default-deny NetworkPolicies for monitoring and opencost (CIS 5.3, default ON)
- Non-blocking apply-time warning when firewall IPs are open to `0.0.0.0/0`

## Prerequisites

- [OpenTofu](https://opentofu.org/) 1.6+
- `kubectl`
- A Linode API token (via [Linode CLI](https://www.linode.com/docs/products/tools/cli/get-started/) or the [Cloud Manager](https://cloud.linode.com/profile/tokens))

## Quick Start

```bash
# 1. Set Linode token
export LINODE_TOKEN=$(linode-cli configure get token)
# or: export LINODE_TOKEN='your-token-here'

# 2. Configure
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (especially allowed_kubectl_ips for production)

# 3. Deploy
tofu init
tofu plan
tofu apply

# 4. Use the cluster (kubeconfig is auto-merged into ~/.kube/config)
kubectl config use-context lke<CLUSTER_ID>-ctx
kubectl get nodes
```

## Cost Estimate

| Configuration                                         | Approx. Monthly Cost |
| ----------------------------------------------------- | -------------------- |
| Dev (1 × g6-standard-1, no monitoring)                | **~$24**             |
| Dev + ephemeral monitoring (free emptyDir storage)    | ~$24                 |
| Dev + persistent monitoring (~27Gi block storage)     | ~$27                 |
| Small (2 × g6-standard-2)                             | ~$72                 |
| Production HA (3 × g6-standard-2 + HA control plane)  | ~$168                |

LKE control plane (non-HA) is free. HA control plane adds ~$60/mo. Block storage is ~$0.10/Gi/month. Prices subject to change — see [Linode Pricing](https://www.linode.com/pricing/).

## Configuration

All configuration lives in `infrastructure/terraform.tfvars`. Copy from `terraform.tfvars.example` to start.

### Core variables

| Variable              | Default                  | Description                                      |
| --------------------- | ------------------------ | ------------------------------------------------ |
| `cluster_name_prefix` | `""` (uses `whoami`)     | Prefix for the cluster label                     |
| `region`              | `us-east`                | Linode region                                    |
| `kubernetes_version`  | `1.34`                   | Kubernetes version                               |
| `ha_control_plane`    | `false`                  | Enable HA control plane (~$60/mo)                |
| `node_pools`          | `1 × g6-standard-1, 1-3` | Node pool definitions with autoscaler            |
| `tags`                | `["lke","kubernetes"]`   | Resource tags                                    |

### Firewall

| Variable                    | Default         | Description                                        |
| --------------------------- | --------------- | -------------------------------------------------- |
| `firewall_enabled`          | `true`          | Create a Linode firewall attached to nodes         |
| `firewall_enable_nodeports` | `true`          | Open NodePort range (30000-32767)                  |
| `allowed_kubectl_ips`       | `["0.0.0.0/0"]` | CIDRs for kubectl API (443) **and NodePorts**      |
| `allowed_monitoring_ips`    | `["0.0.0.0/0"]` | CIDRs for monitoring UIs (80/443/3000/9090)        |

The firewall hardcodes `inbound_policy = DROP` and `outbound_policy = ACCEPT`.

### Add-ons (opt-in)

| Variable                            | Default | Description                                                       |
| ----------------------------------- | ------- | ----------------------------------------------------------------- |
| `install_metrics_server`            | `true`  | Enables `kubectl top` and HPA. Lightweight.                       |
| `install_monitoring`                | `false` | kube-prometheus-stack (Prometheus + Grafana + Alertmanager).      |
| `install_opencost`                  | `false` | OpenCost (requires `install_monitoring = true`).                  |
| `monitoring_use_ephemeral_storage`  | `false` | Use `emptyDir` instead of PVCs (free, but data lost on restart).  |
| `monitoring_enable_node_exporter`   | `false` | Enable node-exporter DaemonSet. Requires privileged host access; metrics-server covers HPA/top without it. |
| `install_network_policies`          | `true`  | Default-deny NetworkPolicies for monitoring + opencost namespaces (CIS 5.3). |
| `prometheus_storage_size`           | `20Gi`  | Persistent storage size for Prometheus.                           |
| `prometheus_retention`              | `7d`    | Prometheus retention window.                                      |
| `grafana_storage_size`              | `5Gi`   | Persistent storage size for Grafana.                              |
| `alertmanager_storage_size`         | `2Gi`   | Persistent storage size for Alertmanager.                         |
| `grafana_admin_password`            | `admin` | **Change in production.**                                         |

## Accessing Add-ons

```bash
# Resource usage (metrics-server)
kubectl top nodes
kubectl top pods -A

# Grafana (if install_monitoring=true)
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# http://localhost:3000  (admin / <grafana_admin_password>)

# Prometheus
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090

# OpenCost
kubectl port-forward -n opencost svc/opencost 9090:9090
```

## Project Structure

```
.
├── README.md
├── SECURITY.md
├── LICENSE
├── .github/workflows/         # CI: tofu-validate + trivy security scan
├── infrastructure/
│   ├── cluster.tf             # LKE cluster + kubeconfig merge
│   ├── firewall.tf            # Linode firewall + open-IP advisory
│   ├── locals.tf              # Cluster naming + kubeconfig parsing
│   ├── modules.tf             # Add-on module wiring
│   ├── outputs.tf             # Outputs
│   ├── providers.tf           # linode / kubernetes / helm providers
│   ├── variables.tf           # Input variables
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── metrics-server/
│       ├── kube-prometheus-stack/
│       ├── opencost/
│       └── network-policies/  # Default-deny NetworkPolicies (CIS 5.3)
└── docs/
    ├── architecture/
    ├── cost/
    ├── runbooks/
    ├── examples/
    └── security/              # CIS compliance mapping
```

## Security

This template applies CIS Kubernetes Benchmark Section 5 controls by default:

- **Pod Security Standards** — `baseline` enforced on `monitoring` and `opencost` namespaces; `restricted` audit + warn surfaces further hardening opportunities.
- **NetworkPolicies** — default-deny ingress + egress on all add-on namespaces, with selective allows for known traffic. Requires Calico (LKE default). Controlled by `install_network_policies` (default `true`).
- **Firewall** — `inbound_policy = DROP`; explicit allows only. A non-blocking warning is printed at apply time when `allowed_kubectl_ips` or `allowed_monitoring_ips` contain `0.0.0.0/0`.
- **node-exporter disabled by default** — it requires privileged host access (`hostNetwork`, `hostPID`, `hostPath`). `metrics-server` covers `kubectl top` and HPA without it. Enable via `monitoring_enable_node_exporter = true`.
- **Trivy CI** — IaC scan fails the build on CRITICAL or HIGH findings; MEDIUM findings are reported non-blocking.

See [docs/security/cis-compliance.md](docs/security/cis-compliance.md) for the full CIS control mapping and [SECURITY.md](SECURITY.md) for the vulnerability disclosure policy.

### Security checklist for production

1. Set `allowed_kubectl_ips` and `allowed_monitoring_ips` to your actual CIDRs.
2. Set a strong `grafana_admin_password`.
3. Enable `ha_control_plane = true`.
4. Configure a remote state backend (S3-compatible or OpenTofu Cloud).
5. Never commit `terraform.tfvars` containing secrets — it is gitignored.

## Documentation

- [Architecture](docs/architecture/)
- [Cost Analysis](docs/cost/)
- [Operations & Runbooks](docs/runbooks/)
- [Examples](docs/examples/)
- [Security & CIS Compliance](docs/security/)

## License

MIT — see [LICENSE](LICENSE).
