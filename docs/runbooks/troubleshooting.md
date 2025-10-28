# Troubleshooting Guide

## Quick Diagnostics

### Cluster Health
```bash
export KUBECONFIG=./kubeconfig.yaml
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

### Resource Usage
```bash
kubectl top nodes
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory
```

### Recent Events
```bash
kubectl get events --sort-by='.metadata.creationTimestamp' | tail -20
```

## Common Issues

### Cluster Access Problems

**Symptoms**: kubectl commands timeout or fail

**Diagnosis**:
```bash
# Test connectivity
kubectl cluster-info
kubectl config current-context

# Check kubeconfig
kubectl config view
```

**Solutions**:
- Regenerate kubeconfig: `tofu output -raw kubeconfig | base64 -d > kubeconfig.yaml`
- Verify API token is set: `echo $LINODE_TOKEN`
- Check firewall rules allow port 6443

### Pod Issues

**Symptoms**: Pods stuck in Pending/CrashLoopBackOff

**Diagnosis**:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Common Causes**:
- Insufficient resources
- Image pull failures
- Configuration errors
- Storage issues

### Network Problems

**Symptoms**: Services unreachable, DNS failures

**Diagnosis**:
```bash
# Test DNS
kubectl exec -it <pod> -- nslookup kubernetes.default.svc.cluster.local

# Check services
kubectl get svc -A
kubectl get endpoints -A

# Test connectivity
kubectl run test-pod --image=busybox --restart=Never -- sleep 3600
kubectl exec -it test-pod -- ping <service-ip>
```

**Solutions**:
- Restart CoreDNS: `kubectl rollout restart deployment/coredns -n kube-system`
- Check network policies
- Verify service selectors

### Storage Issues

**Symptoms**: PVCs stuck in Pending, mount failures

**Diagnosis**:
```bash
kubectl get pvc -A
kubectl describe pvc <pvc-name>
kubectl get storageclass
```

**Solutions**:
- Check storage class configuration
- Verify CSI driver status
- Review volume attachment status

### Monitoring Stack Issues

**Symptoms**: Grafana/Prometheus unavailable

**Diagnosis**:
```bash
kubectl get pods -n monitoring
kubectl logs -n monitoring deployment/prometheus-stack-grafana
kubectl get svc -n monitoring
```

**Solutions**:
- Restart monitoring components: `kubectl rollout restart deployment -n monitoring`
- Check resource limits: `kubectl describe pod -n monitoring <pod-name>`
- Verify persistent volume claims: `kubectl get pvc -n monitoring`

## Recovery Procedures

### Restart Components
```bash
# System components
kubectl rollout restart deployment/coredns -n kube-system
kubectl rollout restart daemonset/calico-node -n kube-system

# Monitoring stack
kubectl rollout restart deployment -n monitoring
```

### Resource Cleanup
```bash
# Clean up failed pods
kubectl delete pods --field-selector=status.phase=Failed -A

# Clean up completed jobs
kubectl delete jobs --field-selector=status.conditions[0].type=Complete -A
```

### Emergency Recovery
```bash
# Recreate cluster (destructive)
tofu destroy
tofu apply

# Reset monitoring stack
kubectl delete namespace monitoring
tofu apply
```

## Performance Issues

### High Resource Usage
```bash
# Identify resource-heavy pods
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory

# Check node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Scaling Solutions
```bash
# Scale deployment
kubectl scale deployment <name> --replicas=<count>

# Add cluster nodes (edit terraform.tfvars)
tofu plan
tofu apply
```

## Monitoring and Alerting

### Access Monitoring
- Grafana: `http://<node-ip>:30300` (admin/admin)
- Prometheus: Port-forward to localhost:9090

### Key Metrics to Watch
- Node CPU and memory usage
- Pod restart counts
- Network I/O patterns
- Storage utilization

### Custom Dashboards
Import additional Grafana dashboards for specific workloads or infrastructure components as needed.