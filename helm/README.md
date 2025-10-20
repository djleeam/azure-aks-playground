# Helm Deployments for AKS

This directory contains Helm charts and configurations for deploying applications to the AKS cluster managed by Terraform.

## 🏗️ Structure

```
helm/
├── README.md                 # This file
├── scripts/                  # Helper scripts
│   ├── deploy.sh            # Main deployment script
│   ├── connect-cluster.sh   # Cluster connection helper
│   └── cleanup.sh           # Cleanup script
├── charts/                   # Custom charts (if needed)
└── applications/             # Application-specific configurations
    ├── airbyte/             # Airbyte data integration platform
    └── monitoring/          # Future: Prometheus, Grafana, etc.
```

## 🚀 Quick Start

### Prerequisites

1. **AKS cluster deployed** via Terraform (see `../tf/` directory)
2. **Helm 3.x** installed
3. **kubectl** configured to connect to your AKS cluster
4. **Azure CLI** logged in

### Connect to Your Cluster

```bash
# From the project root
cd helm
./scripts/connect-cluster.sh
```

### Deploy Airbyte

```bash
# Deploy to development environment
./scripts/deploy.sh airbyte dev

# Deploy to production environment
./scripts/deploy.sh airbyte prod
```

## 📋 Available Applications

### Airbyte
- **Purpose**: Open-source data integration platform
- **Chart Version**: 2.0.18 (Community Edition)
- **App Version**: 2.0.0
- **Repository**: airbyte (https://airbytehq.github.io/charts)
- **Environment**: Development (simplified single-environment setup)
- **Documentation**: [Airbyte Helm Chart v2](https://docs.airbyte.com/platform/deploying-airbyte/chart-v2-community)

## 🔧 Configuration Management

This playground uses a simplified configuration approach:

- `values-simplified.yaml` - Simplified configuration for easy deployment
- `common.yaml` - Shared base configuration
- `dev.yaml` - Development environment overrides

## 🛠️ Helper Scripts

### `connect-cluster.sh`
Connects kubectl to your AKS cluster using Terraform outputs.

### `deploy.sh`
Main deployment script that:
1. Validates prerequisites
2. Connects to the cluster
3. Deploys the specified application with environment-specific values

### `cleanup.sh`
Safely removes applications and cleans up resources.

## 🔐 Security Considerations

- Secrets are managed through Kubernetes secrets
- Integration with Azure Key Vault for sensitive data
- RBAC policies applied per application
- Network policies for traffic isolation

## 📚 Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [AKS Helm Best Practices](https://docs.microsoft.com/en-us/azure/aks/kubernetes-helm)
- [Airbyte Documentation](https://docs.airbyte.com/)
