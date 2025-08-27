# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a proof-of-concept repository for provisioning a cost-effective Linode Kubernetes cluster using OpenTofu (Terraform-compatible) and CNCF technologies. The project is in early development stages and serves as a minimal, extendable template for cloud-native infrastructure work.

## Technology Stack

- **Infrastructure as Code**: OpenTofu (Terraform-compatible)
- **Cloud Provider**: Linode
- **Orchestration**: Kubernetes (upstream CNCF)
- **Container Runtime**: containerd
- **CNI**: Cilium (configurable)
- **GitOps**: Flux or ArgoCD
- **Monitoring**: Prometheus + Grafana
- **Package Management**: Helm

## Prerequisites

Essential tools required for development:
- OpenTofu (or Terraform 1.6+) CLI
- kubectl
- linode-cli (optional but recommended)
- git

Verification commands:
```bash
opentofu version || terraform version
kubectl version --client --short
git --version
```

## Planned Repository Structure

Based on the README specifications:

- `infrastructure/` - OpenTofu HCL modules and root configurations
- `platform/` - Kubernetes manifests, Helm charts, or Kustomize overlays
- `docs/` - Design notes, cost models, and runbooks
- `examples/` - Demo workloads and GitOps bootstrap files

## Development Commands

### Infrastructure Management
```bash
# Navigate to infrastructure directory (when implemented)
cd infrastructure/

# Initialize OpenTofu
opentofu init

# Plan infrastructure changes
opentofu plan

# Apply infrastructure changes
opentofu apply

# Destroy infrastructure
opentofu destroy
```

### Kubernetes Operations
```bash
# Apply platform configurations
kubectl apply -f platform/

# Install/upgrade Helm charts
helm upgrade --install <release-name> <chart-path>

# Check cluster status
kubectl get nodes
kubectl get pods -A
```

## Architecture Principles

### Cost Optimization
- Use smallest supported Linode instance types for testing
- Implement node pools with autoscaling (cluster-autoscaler)
- Use shared/low-cost CPU plans for non-production
- Keep logging/metrics retention minimal for evaluation clusters
- Implement proper tainting for development nodes

### CNCF-First Approach
- Prioritize open-source, CNCF-graduated projects
- Avoid vendor lock-in through modular design
- Use upstream Kubernetes without proprietary extensions

### GitOps Workflow
- Infrastructure changes through code review
- Kubernetes deployments via Flux or ArgoCD
- Version control for all configuration

## Development Workflow

1. **Infrastructure Changes**: Modify OpenTofu configurations in `infrastructure/`
2. **Platform Updates**: Update Kubernetes manifests in `platform/`
3. **Testing**: Use minimal Linode instances for validation
4. **GitOps Bootstrap**: Deploy Flux/ArgoCD for continuous deployment

## Future Implementation Notes

This repository is currently in planning stage. The immediate next steps include:
- Implementing `infrastructure/opentofu/` with Linode provider configuration
- Adding `platform/bootstrap/` with GitOps manifests
- Creating cost documentation in `docs/`
- Adding a Makefile for common operations