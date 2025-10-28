# Cluster Operations

## Prerequisites

- OpenTofu/Terraform CLI
- kubectl configured
- Linode API token
- Repository access

## Basic Operations

### Deploy Cluster
```bash
cd infrastructure
export LINODE_TOKEN='your-token'
tofu init
tofu plan
tofu apply
```

### Access Cluster
```bash
tofu output -raw kubeconfig | base64 -d > kubeconfig.yaml
export KUBECONFIG=./kubeconfig.yaml
kubectl cluster-info
```

### Scale Cluster
```bash
# Edit node count in terraform.tfvars
# Then apply changes
tofu plan
tofu apply
```

### Update Configuration
```bash
# Edit terraform.tfvars or module variables
tofu plan
tofu apply
```

## Monitoring

### Access Grafana
- **NodePort**: `http://<node-ip>:30300`
- **Port Forward**: `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80`

### Access Prometheus
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
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
tofu destroy
tofu apply
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