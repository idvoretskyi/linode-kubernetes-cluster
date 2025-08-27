# Cluster Operations

## Prerequisites

- OpenTofu/Terraform CLI
- kubectl configured
- Linode API token
- Repository access

## Basic Operations

### Deploy Cluster
```bash
make dev  # or make prod
export LINODE_TOKEN='your-token'
make init plan apply
```

### Access Cluster
```bash
make kubeconfig
export KUBECONFIG=./kubeconfig.yaml
kubectl cluster-info
```

### Scale Cluster
```bash
# Edit node count in terraform.tfvars
# Then apply changes
make plan apply
```

### Update Configuration
```bash
# Edit terraform.tfvars or module variables
make plan apply
```

## Monitoring

### Access Grafana
- **NodePort**: `http://<node-ip>:31000`
- **Port Forward**: `kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80`

### Access Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
```

## Health Checks

### Cluster Status
```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

### Resource Usage
```bash
kubectl top nodes
kubectl top pods -A
```

## Troubleshooting

### Common Issues

**Cluster Unreachable**:
- Check kubeconfig
- Verify firewall rules
- Check Linode status page

**Pods Not Starting**:
- Check resource limits
- Verify node capacity
- Review pod events

**Storage Issues**:
- Check PVC status
- Verify storage classes
- Review CSI driver logs

### Recovery

**Restart Services**:
```bash
kubectl rollout restart deployment -n <namespace>
```

**Recreate Cluster**:
```bash
make destroy
make apply
```

## Backup

### Configuration Backup
```bash
kubectl get all --all-namespaces -o yaml > backup.yaml
```

### State Backup
```bash
# Backup Terraform state before major changes
cp terraform.tfstate terraform.tfstate.backup
```