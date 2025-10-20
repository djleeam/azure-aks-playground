# Azure AKS Terraform Playground

This repository demonstrates a complete Azure Kubernetes Service (AKS) deployment with application management using Terraform for infrastructure and Helm for applications.

## 🏗️ Architecture

### Infrastructure Layer (Terraform)
- **AKS Cluster** with system node pool
- **Azure Policy** integration for governance
- **Log Analytics** workspace for monitoring
- **Azure CNI** networking with network policies
- **System-assigned managed identity**
- **RBAC** enabled for security

### Application Layer (Helm)
- **Airbyte** data integration platform (Chart v2)
- **Environment separation** (dev, staging, prod)
- **Automated deployment scripts**
- **Security and monitoring integration**

## 📋 Prerequisites

Before you begin, ensure you have:

1. **Azure CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **k9s** installed for cluster management ([installation guide](https://k9scli.io/topics/install/))
4. **kubectl** installed (required by k9s as a dependency)
5. An **Azure subscription** with appropriate permissions

## 🚀 Quick Start

### 1. Clone and Navigate
```bash
git clone <your-repo-url>
cd azure-aks-playground/tf
```

### 2. Login to Azure
```bash
az login
az account set --subscription <your-subscription-id>
```

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Customize Configuration (Optional)
Edit `terraform.tfvars` to customize your deployment:

```hcl
# Basic Configuration
prefix              = "myproject"
resource_group_name = "myproject-aks-rg"
location           = "East US"
cluster_name       = "myproject-aks"

# Node Configuration
node_count = 3
vm_size    = "Standard_D4s_v5"

# Security & Monitoring
enable_azure_policy   = true
enable_log_analytics  = true
log_retention_in_days = 90

# Networking
network_plugin        = "azure"
network_policy        = "azure"
enable_private_cluster = false
```

### 5. Plan and Apply
```bash
terraform plan
terraform apply
```

### 6. Connect to Your Cluster and Deploy Applications
```bash
# Get cluster credentials
az aks get-credentials --resource-group demo-aks-rg --name demo-aks

# Navigate to Helm directory
cd ../helm

# Connect to cluster (automated)
./scripts/connect-cluster.sh

# Deploy Airbyte to development environment
./scripts/deploy.sh airbyte dev

# Launch k9s to manage your cluster
k9s
```

> **💡 Pro Tip**: k9s provides an intuitive terminal UI for Kubernetes. Use `:nodes` to view nodes, `:pods` for pods, `:svc` for services, and much more!

## 🚀 Quick Start Options

### Option 1: 5-Minute Quick Start ⚡ (Recommended for Learning)

```bash
# Deploy AKS + Airbyte in 5 minutes
cd tf && terraform apply -auto-approve
cd ../helm && ./quick-start.sh

# Access at: http://localhost:8080
```

See [QUICK-START.md](QUICK-START.md) for the fastest way to get started.

### Option 2: Production-Ready Deployment 🏗️

```bash
# Navigate to helm directory
cd helm

# Deploy Airbyte to different environments
./scripts/deploy.sh airbyte dev      # Development
./scripts/deploy.sh airbyte staging  # Staging
./scripts/deploy.sh airbyte prod     # Production
```

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## 📁 Project Structure

```
azure-aks-playground/
├── README.md                 # This file
├── DEPLOYMENT.md             # Step-by-step deployment guide
├── SECURITY.md               # Security configuration guide
├── NETWORK.md                # Network configuration details
├── tf/                       # Infrastructure (Terraform)
│   ├── main.tf              # Main AKS module configuration
│   ├── variables.tf         # Input variable definitions
│   ├── terraform.tfvars     # Variable values
│   ├── outputs.tf           # Output definitions
│   └── providers.tf         # Provider and version constraints
├── helm/                     # Application deployments (Helm)
│   ├── README.md            # Helm-specific documentation
│   ├── scripts/             # Deployment automation scripts
│   │   ├── connect-cluster.sh
│   │   ├── deploy.sh
│   │   └── cleanup.sh
│   └── applications/        # Application configurations
│       └── airbyte/         # Airbyte data integration platform
│           ├── Chart.yaml
│           ├── values-simplified.yaml  # Simplified configuration
│           └── values/      # Configuration files
│               ├── common.yaml
│               └── dev.yaml
├── k8s/                     # Raw Kubernetes manifests
│   ├── namespaces/
│   └── secrets/
└── docs/                    # Additional documentation
    └── helm-deployment-guide.md
```

## 🎮 Managing Your Cluster with k9s

### Installing k9s

**macOS (Homebrew):**
```bash
brew install k9s
```

**Linux (snap):**
```bash
sudo snap install k9s
```

**Windows (Chocolatey):**
```bash
choco install k9s
```

**Or download from [GitHub releases](https://github.com/derailed/k9s/releases)**

### k9s Quick Reference

Once connected to your cluster, k9s provides an intuitive interface:

| Command | Description |
|---------|-------------|
| `:nodes` | View cluster nodes |
| `:pods` | View all pods |
| `:svc` | View services |
| `:deploy` | View deployments |
| `:ns` | View namespaces |
| `:logs` | View pod logs |
| `?` | Help menu |
| `:quit` or `Ctrl+C` | Exit k9s |

### Why k9s over kubectl?

- **Visual Interface**: See your cluster resources in a terminal UI
- **Real-time Updates**: Watch resources change in real-time
- **Easy Navigation**: Browse through namespaces, pods, logs with arrow keys
- **Built-in Actions**: Delete, describe, edit resources with simple keystrokes
- **Log Streaming**: View logs from multiple pods simultaneously

> **Note**: k9s requires kubectl to be installed as it uses kubectl under the hood for cluster communication.

## 🔧 Configuration Options

### Key Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `prefix` | Prefix for all resources | `"demo"` | string |
| `resource_group_name` | Resource group name | `"demo-aks-rg"` | string |
| `location` | Azure region | `"West US"` | string |
| `cluster_name` | AKS cluster name | `"demo-aks"` | string |
| `node_count` | Number of nodes | `2` | number |
| `vm_size` | VM size for nodes | `"Standard_D2s_v5"` | string |
| `enable_azure_policy` | Enable Azure Policy | `true` | bool |
| `enable_log_analytics` | Enable Log Analytics | `true` | bool |
| `network_plugin` | Network plugin (azure/kubenet) | `"azure"` | string |
| `network_policy` | Network policy (azure/calico) | `"azure"` | string |
| `enable_private_cluster` | Enable private cluster | `false` | bool |

## 🔍 What's Included vs. Basic Setup

### ✅ Now Included (via Azure AKS Module)
- **Log Analytics** workspace for monitoring
- **Azure Policy** integration
- **Network policies** for security
- **Managed identity** configuration
- **RBAC** enabled by default
- **Disk encryption** 
- **Container insights** monitoring
- **Key vault** integration (optional)
- **Proper tagging** strategy

### 🎯 Production Considerations

For production use, consider:

1. **Enable private cluster**: Set `enable_private_cluster = true`
2. **Azure AD integration**: Configure `rbac_aad = true` in main.tf
3. **Multiple node pools**: Add user node pools for workloads
4. **Network security**: Implement proper subnet configuration
5. **Backup strategy**: Configure backup for persistent volumes
6. **Remote state**: Use Azure Storage for Terraform state
7. **CI/CD integration**: Implement automated deployments

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

## 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete step-by-step deployment guide
- **[SECURITY.md](SECURITY.md)** - Security configuration and best practices
- **[NETWORK.md](NETWORK.md)** - Network configuration details
- **[helm/README.md](helm/README.md)** - Helm-specific documentation
- **[docs/helm-deployment-guide.md](docs/helm-deployment-guide.md)** - Advanced Helm deployment guide

## 📚 External Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure AKS Terraform Module](https://registry.terraform.io/modules/Azure/aks/azurerm/latest)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Helm Documentation](https://helm.sh/docs/)
- [Airbyte Helm Chart v2](https://docs.airbyte.com/platform/deploying-airbyte/chart-v2-community)
- [k9s Documentation](https://k9scli.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is licensed under the MIT License.
