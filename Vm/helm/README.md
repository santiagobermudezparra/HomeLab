# Homarr Deployment Guide for Kubernetes

This guide provides instructions for deploying Homarr on Kubernetes using Helm.

## What is Homarr?

Homarr is a sleek, modern dashboard that puts all your apps and services in one place. It's a customizable homepage for your self-hosted services, allowing you to organize and access them from a single interface. Homarr supports widgets, app integrations, and a clean, responsive UI.

Official Repository: [https://github.com/oben01/charts/tree/main/charts/homarr](https://github.com/oben01/charts/tree/main/charts/homarr)

## Prerequisites

- Kubernetes cluster
- Helm installed
- `kubectl` configured to access your cluster

## Deployment Steps for SQLite Database (Default)

### Step 1: Create the namespace

```bash
kubectl create namespace homarr
```

### Step 2: Create the encryption key secret

```bash
# Generate a random encryption key
ENCRYPTION_KEY=$(openssl rand -hex 32)

# Create the secret with just the encryption key
kubectl create secret generic db-secret \
  --from-literal=db-encryption-key="$ENCRYPTION_KEY" \
  --namespace homarr
```

### Step 3: Create a values.yaml file

Create a file named `values.yaml` with the following content:

```yaml
# -- Number of replicas
replicaCount: 2

# Database configuration - using SQLite
database:
  externalDatabaseEnabled: false
  
# Disable the MySQL dependency
mysql:
  enabled: false

# Reference the existing secret
envSecrets:
  dbCredentials:
    existingSecret: "db-secret"  # Use the existing secret

# Enable persistence for SQLite database
persistence:
  homarrDatabase:
    enabled: true
    size: "1Gi"
    storageClassName: "local-path"  # Use your cluster's storage class
  
  # Optional: Enable persistence for images
  homarrImages:
    enabled: true
    size: "1Gi"
    storageClassName: "local-path"  # Use your cluster's storage class

# Set timezone
env:
  TZ: "UTC"  # Change to your timezone if needed
```

Note: Adjust the `storageClassName` to match the storage class available in your cluster.

### Step 4: Add the Homarr Helm repository

```bash
helm repo add homarr-labs https://homarr-labs.github.io/charts/
helm repo update
```

### Step 5: Install the Helm chart

```bash
helm install homarr homarr-labs/homarr \
  --namespace homarr \
  --values values.yaml
```

### Step 6: Verify the installation

```bash
# Check if the pods are running
kubectl get pods -n homarr

# Check the services
kubectl get services -n homarr

# Check the persistent volume claims
kubectl get pvc -n homarr
```

## Alternative: Deployment with MySQL Database

If you prefer to use MySQL instead of SQLite, follow these steps:

### Step 1: Create the namespace

```bash
kubectl create namespace homarr
```

### Step 2: Create the database secret

```bash
# Generate a random encryption key
ENCRYPTION_KEY=$(openssl rand -hex 32)

# Create the secret
kubectl create secret generic db-secret \
  --from-literal=db-encryption-key="$ENCRYPTION_KEY" \
  --from-literal=db-url="mysql://homarr:homarr@homarr-mysql:3306/homarrdb" \
  --from-literal=mysql-root-password="rootpassword" \
  --from-literal=mysql-password="homarr" \
  --namespace homarr
```

Note: Replace `rootpassword` and `homarr` with secure passwords for production environments.

### Step 3: Create a values.yaml file for MySQL

```yaml
# -- Number of replicas
replicaCount: 2

# Database configuration
database:
  externalDatabaseEnabled: false  # We'll use the included MySQL dependency

# MySQL dependency configuration
mysql:
  auth:
    database: homarrdb
    username: homarr
    existingSecret: db-secret  # Use the secret we created above

# Enable persistence for database
persistence:
  homarrDatabase:
    enabled: true
    size: "1Gi"
  
  # Optional: Enable persistence for images
  homarrImages:
    enabled: true
    size: "1Gi"

# Set timezone
env:
  TZ: "UTC"  # Change to your timezone
```

### Steps 4-6: Same as for SQLite deployment

Follow steps 4 through 6 from the SQLite deployment instructions.

## Adding Ingress (Optional)

To expose Homarr outside your cluster with an Ingress, add this to your values.yaml:

```yaml
ingress:
  enabled: true
  ingressClassName: "nginx"  # Change to your ingress controller
  annotations:
    # Add any annotations needed for your ingress controller
  hosts:
    - host: homarr.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - hosts:
        - homarr.yourdomain.com
      secretName: homarr-tls  # Create this TLS secret separately or use cert-manager
```

## Troubleshooting

### Check Logs
```bash
kubectl logs -f deployment/homarr -n homarr
```

### Check Events
```bash
kubectl get events -n homarr
```

### Secret Management
If you need to update the secret:
```bash
kubectl delete secret db-secret -n homarr
# Then recreate it with the new values
```

## Additional Resources

- [Homarr Documentation](https://homarr.dev/docs/getting-started/introduction)
- [Helm Chart Repository](https://github.com/oben01/charts/tree/main/charts/homarr)
- [Homarr GitHub Repository](https://github.com/ajnart/homarr)
