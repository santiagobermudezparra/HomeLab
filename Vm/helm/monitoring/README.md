 Monitoring Stack Implementation Guide

This guide provides instructions for setting up the Prometheus monitoring stack on Kubernetes using Helm.

## Overview

We use the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) Helm chart, which provides a complete monitoring solution including:

- Prometheus Operator
- Prometheus Server
- Alertmanager
- Grafana
- Various exporters for Kubernetes monitoring

## Prerequisites

- Kubernetes cluster (version 1.19+)
- Helm (version 3+)
- kubectl command-line tool

## Implementation Steps

### 1. Add the Prometheus Community Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 2. Create a Monitoring Namespace (if not already exists)

```bash
kubectl create namespace monitoring
```

### 3. Create a Values File

Create a file named `prometheus-values.yaml` with your desired configuration:

```yaml
# Grafana configuration with LoadBalancer for external access
grafana:
  service:
    type: LoadBalancer
    port: 3000
    targetPort: 3000

# Configure persistent storage for Prometheus
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

# Configure persistent storage for Alertmanager
alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
```

### 4. Install the Prometheus Stack

```bash
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  -f prometheus-values.yaml \
  -n monitoring
```

Or to upgrade an existing installation:

```bash
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack \
  -f prometheus-values.yaml \
  -n monitoring
```

### 5. Verify the Installation

```bash
kubectl get pods -n monitoring
kubectl get services -n monitoring
```

## Accessing the Services

### Grafana

After the LoadBalancer service is provisioned, find the external IP:

```bash
kubectl get service prometheus-stack-grafana -n monitoring
```

Then access Grafana at: `http://<EXTERNAL-IP>:3000`

Default credentials:
- Username: admin
- Password (retrieve with):
  ```bash
  kubectl get secret -n monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
  ```

### Prometheus (Internal Access)

For secure access to Prometheus via port-forwarding:

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090
```

Then access: `http://localhost:9090`

### Alertmanager (Internal Access)

For secure access to Alertmanager via port-forwarding:

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-alertmanager 9093:9093
```

Then access: `http://localhost:9093`

## Configuration Options

The kube-prometheus-stack chart offers extensive configuration options. Common modifications include:

- Changing retention periods for Prometheus data
- Configuring alert rules
- Setting up additional scrape targets
- Customizing Grafana dashboards and data sources

Refer to the [official chart documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) for all available options.

## Maintenance

### Updating Configuration

1. Modify your `prometheus-values.yaml` file
2. Apply changes with:
   ```bash
   helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack \
     -f prometheus-values.yaml \
     -n monitoring
   ```

### Uninstalling

To remove the stack:

```bash
helm uninstall prometheus-stack -n monitoring
```

Note: This will not remove persistent volumes. To clean up completely, you should also delete the PVCs and CRDs.

## References

- [kube-prometheus-stack Chart Documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Operator Documentation](https://prometheus-operator.dev/)
- [Grafana Documentation](https://grafana.com/docs/)
