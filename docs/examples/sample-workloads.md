# Sample Workloads

## Prerequisites

```bash
export KUBECONFIG=./kubeconfig.yaml
kubectl cluster-info
```

## Basic Web Application

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  namespace: demo
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    nodePort: 30080
  type: NodePort
```

## Application with Storage

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-storage
  namespace: demo
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-app
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: data-app
  template:
    metadata:
      labels:
        app: data-app
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sleep', '3600']
        volumeMounts:
        - name: data
          mountPath: /data
        resources:
          requests:
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "64Mi"
            cpu: "50m"
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: data-storage
```

## Monitoring Test Application

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-demo
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: metrics-demo
  template:
    metadata:
      labels:
        app: metrics-demo
    spec:
      containers:
      - name: app
        image: prom/node-exporter:latest
        ports:
        - containerPort: 9100
        resources:
          requests:
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "64Mi"
            cpu: "50m"
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-demo-service
  namespace: demo
spec:
  selector:
    app: metrics-demo
  ports:
  - port: 9100
    targetPort: 9100
  type: ClusterIP
```

## Deploy Examples

```bash
# Apply sample workload
kubectl apply -f sample-workload.yaml

# Check deployment
kubectl get pods -n demo
kubectl get svc -n demo

# Access web application
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
curl http://$NODE_IP:30080

# Clean up
kubectl delete namespace demo
```

## Load Testing

```bash
# Create test load
kubectl run load-generator \
  --image=busybox \
  --restart=Never \
  --rm -i --tty \
  -- /bin/sh -c "while true; do wget -q -O- http://web-app-service.demo.svc.cluster.local; done"
```

## Resource Monitoring

```bash
# Watch resource usage
kubectl top pods -n demo
kubectl top nodes

# Monitor autoscaling
kubectl get hpa -n demo --watch
```