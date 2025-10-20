# 🚀 Quick Start: AKS + Airbyte in 5 Minutes

Get Airbyte running on your AKS cluster with minimal setup.

## Prerequisites (2 minutes)

```bash
# Install required tools (if not already installed)
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform  
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# kubectl (usually comes with Azure CLI)
az aks install-cli
```

## Step 1: Deploy AKS Cluster (2 minutes)

```bash
# Clone and setup
git clone <your-repo-url>
cd azure-aks-playground

# Login to Azure
az login

# Deploy infrastructure
cd tf
cp terraform.tfvars.security-example terraform.tfvars
# Edit terraform.tfvars with your settings (prefix, location, etc.)
terraform init && terraform apply -auto-approve
```

## Step 2: Deploy Airbyte (1 minute)

```bash
# One command deployment
cd ../helm
./quick-start.sh
```

## Step 3: Access Airbyte

```bash
# Start port-forward (keep this running)
kubectl port-forward -n airbyte svc/airbyte-webapp 8080:80

# Open browser to: http://localhost:8080
```

## That's it! 🎉

You now have:
- ✅ AKS cluster running on Azure
- ✅ Airbyte data platform deployed
- ✅ Web UI accessible at localhost:8080

## Quick Commands

```bash
# Check status
kubectl get pods -n airbyte

# Scale up for testing
./scripts/scale-airbyte.sh medium

# View logs
kubectl logs -n airbyte -l app.kubernetes.io/name=airbyte

# Cleanup everything
helm uninstall airbyte -n airbyte
cd ../tf && terraform destroy -auto-approve
```

## Troubleshooting

**Pods not starting?**
```bash
kubectl describe pods -n airbyte
```

**Can't access UI?**
```bash
# Check if port-forward is running
kubectl port-forward -n airbyte svc/airbyte-webapp 8080:80
```

**Need more resources?**
```bash
./scripts/scale-airbyte.sh large
```

## Next Steps

- 📖 Read [DEPLOYMENT.md](DEPLOYMENT.md) for advanced configurations
- 🔐 Check [SECURITY.md](SECURITY.md) for production security
- 🔧 Explore [helm/README.md](helm/README.md) for customization options
