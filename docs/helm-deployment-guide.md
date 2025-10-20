# Helm Deployment Guide for AKS

This guide explains how to deploy applications using Helm to your Terraform-managed AKS cluster.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Subscription                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────────────────────────┐ │
│  │   Terraform     │    │           AKS Cluster              │ │
│  │  Infrastructure │────│                                     │ │
│  │                 │    │  ┌─────────────────────────────────┐ │ │
│  │ • Resource Group│    │  │        Helm Applications        │ │ │
│  │ • AKS Cluster   │    │  │                                 │ │ │
│  │ • Networking    │    │  │ ┌─────────┐  ┌─────────────────┐ │ │ │
│  │ • Security      │    │  │ │ Airbyte │  │   Monitoring    │ │ │ │
│  │ • Monitoring    │    │  │ │   Dev   │  │  (Future)       │ │ │ │
│  └─────────────────┘    │  │ └─────────┘  └─────────────────┘ │ │ │
│                         │  │ ┌─────────┐  ┌─────────────────┐ │ │ │
│                         │  │ │ Airbyte │  │   Other Apps    │ │ │ │
│                         │  │ │ Staging │  │  (Future)       │ │ │ │
│                         │  │ └─────────┘  └─────────────────┘ │ │ │
│                         │  │ ┌─────────┐                      │ │ │
│                         │  │ │ Airbyte │                      │ │ │
│                         │  │ │  Prod   │                      │ │ │
│                         │  │ └─────────┘                      │ │ │
│                         │  └─────────────────────────────────┘ │ │
│                         └─────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### 1. Prerequisites

Ensure you have completed the infrastructure setup:

```bash
# 1. Deploy AKS cluster with Terraform
cd tf/
terraform init
terraform apply

# 2. Verify cluster is running
terraform output cluster_connection_info
```

### 2. Connect to Your Cluster

```bash
cd helm/
./scripts/connect-cluster.sh
```

### 3. Deploy Airbyte

```bash
# Development environment
./scripts/deploy.sh airbyte dev

# Staging environment  
./scripts/deploy.sh airbyte staging

# Production environment
./scripts/deploy.sh airbyte prod
```

## 📁 Project Structure Integration

### Terraform (Infrastructure Layer)
```
tf/
├── main.tf           # AKS cluster definition
├── outputs.tf        # Cluster connection info
├── variables.tf      # Infrastructure variables
└── terraform.tfvars  # Environment-specific values
```

### Helm (Application Layer)
```
helm/
├── scripts/          # Deployment automation
├── applications/     # Application configurations
│   └── airbyte/     # Airbyte-specific configs
│       ├── Chart.yaml
│       └── values/   # Environment-specific values
└── charts/          # Custom charts (if needed)
```

## 🔧 Environment Management

### Simplified Development Environment

This playground uses a single-environment approach optimized for learning:

1. **Namespace**: `airbyte-dev` - Single development namespace
2. **Configuration Files**:
   ```
   values-simplified.yaml  # Simplified configuration for easy deployment
   values/common.yaml      # Base configuration
   values/dev.yaml         # Development overrides
   ```

3. **Resource Allocation**:
   - **Development**: Minimal resources optimized for learning
   - Single replicas for all components
   - Smaller resource limits to run on local/small clusters

### Configuration Management

#### Development Environment Features
- Single replicas for all services
- Minimal resource requirements
- Debug logging enabled
- Port-forwarding for access (no ingress complexity)
- Simple passwords for easy setup
- No TLS/SSL

#### Staging Environment
- Production-like configuration
- Moderate resource allocation
- Standard logging
- Staging domain with TLS
- Monitoring enabled

#### Production Environment
- High availability (multiple replicas)
- Full resource allocation
- Production logging
- Production domain with TLS
- Full monitoring and alerting
- Backup enabled

## 🔐 Security Integration

### Terraform-Managed Security
- Network Security Groups
- API Server authorized IP ranges
- Azure Policy integration
- RBAC configuration

### Helm-Managed Security
- Kubernetes RBAC per application
- Network policies for pod-to-pod communication
- Secret management
- Pod security contexts

### Secret Management Strategy

1. **Development**: Simple passwords in values files
2. **Staging/Production**: Kubernetes secrets + Azure Key Vault

```bash
# Create production secrets
kubectl create secret generic airbyte-postgresql-secret \
  --from-literal=postgres-password="$(openssl rand -base64 32)" \
  --namespace airbyte-prod

kubectl create secret generic airbyte-minio-secret \
  --from-literal=root-user="admin" \
  --from-literal=root-password="$(openssl rand -base64 32)" \
  --namespace airbyte-prod
```

## 🔄 CI/CD Integration

### Recommended Workflow

1. **Infrastructure Changes**: 
   ```bash
   cd tf/
   terraform plan
   terraform apply
   ```

2. **Application Deployment**:
   ```bash
   cd helm/
   ./scripts/deploy.sh airbyte dev --dry-run  # Test first
   ./scripts/deploy.sh airbyte dev            # Deploy
   ```

3. **Promotion Pipeline**:
   ```
   Dev → Staging → Production
   ```

### GitOps Approach (Future)

Consider integrating with:
- **ArgoCD** for GitOps-based deployments
- **Flux** for automated Helm releases
- **GitHub Actions** for CI/CD pipelines

## 📊 Monitoring and Observability

### Built-in Monitoring
- Azure Monitor integration (via Terraform)
- Container Insights
- Log Analytics workspace

### Application-Level Monitoring
- Helm chart includes Prometheus metrics
- ServiceMonitor for Prometheus Operator
- Grafana dashboards (future enhancement)

### Logging Strategy
- **Development**: Debug level, local storage
- **Staging**: Info level, persistent storage
- **Production**: Info level, persistent storage with backup

## 🛠️ Troubleshooting

### Common Issues

1. **Cluster Connection Issues**:
   ```bash
   # Re-run connection script
   ./scripts/connect-cluster.sh
   
   # Verify manually
   az aks get-credentials --resource-group <rg> --name <cluster>
   kubectl cluster-info
   ```

2. **Helm Deployment Failures**:
   ```bash
   # Check deployment status
   helm status airbyte-dev -n airbyte-dev
   
   # Check pod logs
   kubectl logs -n airbyte-dev -l app.kubernetes.io/name=airbyte
   
   # Debug with dry-run
   ./scripts/deploy.sh airbyte dev --dry-run
   ```

3. **Resource Issues**:
   ```bash
   # Check node resources
   kubectl top nodes
   kubectl describe nodes
   
   # Check pod resources
   kubectl top pods -n airbyte-dev
   ```

### Cleanup and Recovery

```bash
# Clean up specific environment
./scripts/cleanup.sh airbyte dev

# Force cleanup if stuck
./scripts/cleanup.sh airbyte dev --force

# Redeploy after cleanup
./scripts/deploy.sh airbyte dev
```

## 📚 Next Steps

1. **Add More Applications**:
   - Create new directories under `helm/applications/`
   - Follow the same pattern as Airbyte

2. **Implement GitOps**:
   - Set up ArgoCD or Flux
   - Create Git-based deployment workflows

3. **Enhanced Monitoring**:
   - Deploy Prometheus and Grafana
   - Set up alerting rules

4. **Backup Strategy**:
   - Implement Velero for cluster backups
   - Set up database backup automation

## 🔗 References

- [Helm Documentation](https://helm.sh/docs/)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Airbyte Helm Chart v2](https://docs.airbyte.com/platform/deploying-airbyte/chart-v2-community)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
