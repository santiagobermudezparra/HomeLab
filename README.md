# HomeLab Kubernetes Project

This repository contains Kubernetes configurations for a personal HomeLab environment, organizing various self-hosted services and applications.

## What is this HomeLab?

This HomeLab is a personal Kubernetes cluster for hosting and managing various applications and services in a home environment. It provides a structured approach to deploying, scaling, and managing containerized applications using Kubernetes.

## Repository Structure

The repository is organized into the following directories:

- **Vm** - Configuration for virtual machines and related services
  - **Initial Setup** - Initial configuration and setup scripts
  - **Neverdie** - High availability configurations
  - **Oracle-keepalive** - Configuration for Oracle Cloud keepalive services
  - **deployments** - Kubernetes deployment manifests
  - **helm** - Helm charts and releases, including Homarr
  - **linkding** - Configuration for Linkding bookmark manager
  - **mealie** - Configuration for Mealie recipe manager
  - **DS_Store** - (System files, can be ignored)

## Getting Started with Kubernetes

### Prerequisites

- A Kubernetes cluster (k3s, minikube, or any other distribution)
- `kubectl` installed and configured
- Docker or another container runtime
- Helm (for chart-based deployments)

### Basic Kubernetes Concepts

- **Pods**: The smallest deployable units in Kubernetes that can contain one or more containers
- **Deployments**: Manage the creation and scaling of pods
- **Services**: Expose applications running on pods as network services
- **ConfigMaps/Secrets**: Store configuration data and sensitive information
- **Persistent Volumes**: Provide storage that persists beyond the lifecycle of pods

### Common Commands

#### Applying Configurations

```bash
# Apply a configuration file
kubectl apply -f deployment.yaml

# Apply all configurations in a directory
kubectl apply -f ./deployments/

# Apply with namespace specified
kubectl apply -f service.yaml -n my-namespace
```

#### Managing Resources

```bash
# Get pods
kubectl get pods

# Get services
kubectl get services

# Get deployments
kubectl get deployments

# Get all resources in a namespace
kubectl get all -n my-namespace
```

#### Logs and Debugging

```bash
# View logs for a pod
kubectl logs pod-name

# Execute command in a pod
kubectl exec -it pod-name -- /bin/bash

# Describe a resource for detailed information
kubectl describe pod pod-name
```

## Helm Charts

This repository includes Helm charts for simplified application deployment. Helm is a package manager for Kubernetes that allows you to define, install, and upgrade complex Kubernetes applications.

### Using Helm with Homarr

Our repository includes configuration for Homarr, a sleek, modern dashboard that puts all your apps and services in one place.

#### Deploying Homarr with SQLite Database

1. Create the namespace:
```bash
kubectl create namespace homarr
```

2. Create the encryption key secret:
```bash
# Generate a random encryption key
ENCRYPTION_KEY=$(openssl rand -hex 32)

# Create the secret with just the encryption key
kubectl create secret generic db-secret \
  --from-literal=db-encryption-key="$ENCRYPTION_KEY" \
  --namespace homarr
```

3. Install using Helm:
```bash
# Add the repository
helm repo add homarr-labs https://homarr-labs.github.io/charts/
helm repo update

# Install the chart
helm install homarr homarr-labs/homarr \
  --namespace homarr \
  --values helm/homarr/values.yaml
```

For more detailed documentation on the Homarr deployment, please see the [helm/homarr/README.md](helm/homarr/README.md) file.

## Other Applications

### Linkding

Linkding is a bookmark manager that's deployed in the `linkding` directory. To deploy:

```bash
kubectl apply -f linkding/deployment.yaml
kubectl apply -f linkding/service.yaml
```

### Mealie

Mealie is a recipe manager and meal planner with a RestAPI backend and a reactive frontend application. To deploy:

```bash
kubectl apply -f mealie/deployment.yaml
kubectl apply -f mealie/service.yaml
kubectl apply -f mealie/persistent-volume.yaml
```

## Persistent Storage

Many applications require persistent storage. The repository includes persistent volume configurations:

```bash
# Example of applying a persistent volume claim
kubectl apply -f some-app/pvc.yaml
```

## Troubleshooting

### Common Issues

1. **Pods in CrashLoopBackOff**: Check the logs with `kubectl logs pod-name`
2. **Pending Pods**: Might indicate resource constraints or PVC issues
3. **Service Connectivity**: Ensure services and labels are correctly configured

### Useful Debugging Commands

```bash
# Check pod status
kubectl get pods -n namespace

# Describe the pod for detailed information
kubectl describe pod pod-name -n namespace

# Check logs
kubectl logs pod-name -n namespace

# Check events
kubectl get events -n namespace
```

## Contributing

Feel free to contribute to this HomeLab project by submitting pull requests or opening issues for improvements or bug fixes.



