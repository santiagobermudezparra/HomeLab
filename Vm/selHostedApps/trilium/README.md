lium Notes - Kubernetes Deployment

This repository contains Kubernetes manifests for deploying Trilium Notes, a hierarchical note-taking application with a focus on building personal knowledge bases.

## Overview

Trilium Notes is a self-hosted, markdown-friendly note-taking application that allows you to create a personal knowledge base in a hierarchical tree structure. This deployment uses the official Trilium Docker image and configures it to run with persistent storage in Kubernetes.

## Prerequisites

- Kubernetes cluster (local or cloud)
- `kubectl` configured to communicate with your cluster
- Storage class available in your cluster (default is `local-path`)

## Configuration Files

This deployment consists of four main configuration files:

1. **namespace.yaml** - Creates a dedicated namespace for Trilium
2. **storage.yaml** - Defines the persistent volume claim for Trilium's data
3. **deployment.yaml** - Configures the Trilium application deployment
4. **service.yaml** - Exposes Trilium to access from outside the cluster

## Deployment

Follow these steps to deploy Trilium Notes to your Kubernetes cluster:

1. Create the namespace first:
   ```bash
   kubectl apply -f namespace.yaml
   ```

2. Create the persistent volume claim:
   ```bash
   kubectl apply -f storage.yaml
   ```

3. Deploy the Trilium application:
   ```bash
   kubectl apply -f deployment.yaml
   ```

4. Create the service:
   ```bash
   kubectl apply -f service.yaml
   ```

## Port Configuration

The default configuration maps external port 7474 to Trilium's internal port 8080. You can modify the port in `service.yaml` if needed.

## Accessing Trilium

Once deployed, you can access Trilium in the following ways:

1. **LoadBalancer IP** (if available):
   ```bash
   kubectl get svc trilium-service -n trilium
   ```
   Then access via the EXTERNAL-IP at port 7474.

2. **Port forwarding** (for local development/testing):
   ```bash
   kubectl port-forward -n trilium svc/trilium-service 7474:7474
   ```
   Then access at http://localhost:7474

## Initial Setup

When you first access Trilium, you'll be prompted to set up the database. Follow the on-screen instructions to create your administrator account.

## Storage

Trilium data is persisted to `/home/node/trilium-data` in the container, which is mapped to a persistent volume through the PVC defined in `storage.yaml`. By default, it requests 1Gi of storage, which you can adjust based on your needs.

## Versions

- Trilium: 0.63.7
- This configuration was tested with Kubernetes v1.25+

## Maintenance

### Upgrading

To upgrade to a newer version of Trilium, update the image tag in `deployment.yaml` and reapply:

```bash
kubectl apply -f deployment.yaml
```

### Backup

To backup your Trilium data, you can copy the persistent volume data or set up a more structured backup process for your PVC.

## Troubleshooting

Check the logs if you encounter any issues:

```bash
kubectl logs -f -n trilium -l app=trilium
```


