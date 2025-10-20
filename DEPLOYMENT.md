# Deployment Guide: AKS + Airbyte

This guide provides step-by-step instructions for deploying Airbyte to your Terraform-managed AKS cluster in a simplified development environment.

## 🎯 Overview

This playground project demonstrates a clean separation between:
- **Infrastructure** (Terraform) - AKS cluster, networking, security
- **Applications** (Helm) - Airbyte data integration platform

This setup is optimized for learning and development, using a single environment approach to reduce complexity.

## 📋 Prerequisites

Before starting, ensure you have:

1. **Azure CLI** installed and logged in
2. **Terraform** >= 1.0 installed
3. **Helm** >= 3.0 installed
4. **kubectl** installed
5. **k9s** installed (optional, for cluster management)
6. An **Azure subscription** with appropriate permissions

## 🚀 Step-by-Step Deployment

### Step 1: Deploy AKS Infrastructure

```bash
# 1. Clone and navigate to the project
git clone <your-repo-url>
cd azure-aks-playground

# 2. Login to Azure
az login
az account set --subscription <your-subscription-id>

# 3. Configure Terraform variables
cd tf/
cp terraform.tfvars.security-example terraform.tfvars

# 4. Edit terraform.tfvars with your settings
# Update the following values:
# - prefix: Your project prefix
# - resource_group_name: Your resource group name
# - location: Your preferred Azure region
# - api_server_authorized_ip_ranges: Your IP addresses

# 5. Deploy the infrastructure
terraform init
terraform plan
terraform apply
```

### Step 2: Verify AKS Deployment

```bash
# Check deployment status
terraform output cluster_connection_info

# Connect to the cluster
az aks get-credentials --resource-group <your-rg> --name <your-cluster>

# Verify cluster is running
kubectl cluster-info
kubectl get nodes

# Optional: Launch k9s for interactive management
k9s
```

### Step 3: Prepare Helm Environment

```bash
# Navigate to helm directory
cd ../helm

# Connect to your AKS cluster (automated script)
./scripts/connect-cluster.sh

# Verify setup and add Airbyte repository
./scripts/verify-setup.sh

# Verify connection
kubectl cluster-info
```

### Step 4: Deploy Airbyte

You can deploy Airbyte using either the simplified script or the standard deployment script:

#### Option A: Simplified Deployment (Recommended for beginners)

```bash
# Deploy using the simplified configuration
./scripts/deploy-simple.sh

# This automatically:
# - Creates the airbyte-dev namespace
# - Deploys Airbyte with minimal configuration
# - Uses port-forwarding for access (no ingress complexity)
```

#### Option B: Standard Deployment

```bash
# Deploy to development environment
./scripts/deploy.sh airbyte

# Check deployment status
kubectl get pods -n airbyte-dev
kubectl get services -n airbyte-dev
```

#### Accessing Airbyte

```bash
# Port forward to access Airbyte UI
kubectl port-forward -n airbyte-dev svc/airbyte-webapp 8080:80

# Then visit: http://localhost:8080
```

## 🔧 Configuration Management

### Development Environment Configuration

This playground uses a simplified single-environment approach:

| Component | Namespace | Access Method | Resources | Configuration |
|-----------|-----------|---------------|-----------|---------------|
| Airbyte | `airbyte-dev` | Port-forward | Minimal | Development-optimized |

### Customizing Deployments

1. **Simplified Configuration**: `helm/applications/airbyte/values-simplified.yaml`
2. **Common Values**: `helm/applications/airbyte/values/common.yaml`
3. **Development Overrides**: `helm/applications/airbyte/values/dev.yaml`
4. **Redeploy**: `./scripts/deploy.sh airbyte` or `./scripts/deploy-simple.sh`

### Managing Secrets

```bash
# Development: Simple passwords in values files (for learning purposes)
# For production use, consider proper secret management

# Create custom secrets if needed
kubectl create secret generic my-secret \
  --from-literal=key1=value1 \
  --namespace airbyte-dev

# Update values file to reference the secret
# Then redeploy
```

## 🔐 Security Considerations

### Infrastructure Security (Terraform)
- ✅ API server authorized IP ranges
- ✅ Network security groups
- ✅ Azure Policy integration
- ✅ Private cluster option available

### Application Security (Helm)
- ✅ Kubernetes RBAC per namespace
- ✅ Pod security contexts
- ✅ Basic secret management (development-focused)

### Security Notes for Development Environment

This playground setup prioritizes simplicity over security for learning purposes:
- Uses simple passwords in configuration files
- Network policies are disabled for easier troubleshooting
- Ingress is optional (port-forwarding recommended)
- TLS/SSL is not configured by default

For production deployments, consider implementing proper security measures.

## 📊 Monitoring and Troubleshooting

### Check Deployment Status

```bash
# Helm release status
helm status airbyte-dev -n airbyte-dev

# Pod status
kubectl get pods -n airbyte-dev

# Pod logs
kubectl logs -n airbyte-dev -l app.kubernetes.io/name=airbyte

# Service status
kubectl get services -n airbyte-dev
```

### Common Issues and Solutions

1. **Pods stuck in Pending**:
   ```bash
   kubectl describe pods -n airbyte-dev
   # Check for resource constraints or node issues
   ```

2. **Ingress not working**:
   ```bash
   kubectl get ingress -n airbyte-dev
   kubectl describe ingress -n airbyte-dev
   # Check ingress controller and DNS configuration
   ```

3. **Database connection issues**:
   ```bash
   kubectl logs -n airbyte-dev -l app.kubernetes.io/component=server
   # Check PostgreSQL pod status and secrets
   ```

### Cleanup and Recovery

```bash
# Clean up development environment
./scripts/cleanup.sh airbyte

# Force cleanup if stuck
./scripts/cleanup.sh airbyte --force

# Redeploy after cleanup
./scripts/deploy.sh airbyte
```

## 🔄 CI/CD Integration

### Recommended Workflow

1. **Infrastructure Changes**:
   ```bash
   cd tf/
   terraform plan
   terraform apply
   ```

2. **Application Updates**:
   ```bash
   cd helm/
   # Test changes
   ./scripts/deploy.sh airbyte --dry-run

   # Deploy to development environment
   ./scripts/deploy.sh airbyte

   # Or use simplified deployment
   ./scripts/deploy-simple.sh
   ```

### GitOps Integration (Future)

Consider implementing:
- **ArgoCD** for GitOps-based deployments
- **GitHub Actions** for automated CI/CD
- **Flux** for Helm release automation

## 📚 Next Steps

1. **Add More Applications**:
   - Follow the same pattern under `helm/applications/`
   - Create monitoring stack (Prometheus, Grafana)
   - Add logging aggregation (ELK stack)

2. **Enhance Security**:
   - Implement Azure Key Vault CSI driver
   - Set up Pod Security Standards
   - Configure network policies

3. **Improve Operations**:
   - Set up backup automation
   - Implement disaster recovery
   - Add performance monitoring

## 🆘 Support

If you encounter issues:

1. Check the [troubleshooting guide](docs/helm-deployment-guide.md#troubleshooting)
2. Review pod logs and events
3. Verify cluster connectivity and resources
4. Check Helm release status

## 🔗 References

- [Terraform AKS Module](https://registry.terraform.io/modules/Azure/aks/azurerm/latest)
- [Airbyte Helm Chart v2](https://docs.airbyte.com/platform/deploying-airbyte/chart-v2-community)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Helm Documentation](https://helm.sh/docs/)
