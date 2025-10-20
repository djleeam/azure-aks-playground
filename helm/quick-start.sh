#!/bin/bash

# One-command Airbyte deployment for AKS
# This script handles everything: connection, repository setup, and deployment

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🚀 Airbyte Quick Start for AKS"
echo "================================"

# Step 1: Connect to AKS cluster
print_status "Step 1: Connecting to AKS cluster..."
if [[ -f "../tf/terraform.tfstate" ]]; then
    cd ../tf
    RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null)
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null)
    
    if [[ -n "$RESOURCE_GROUP" && -n "$CLUSTER_NAME" ]]; then
        print_status "Found cluster: $CLUSTER_NAME in $RESOURCE_GROUP"
        az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
        print_success "Connected to AKS cluster"
    else
        print_error "Could not get cluster info from Terraform. Please run 'terraform apply' first."
        exit 1
    fi
    cd - > /dev/null
else
    print_error "Terraform state not found. Please deploy AKS cluster first:"
    echo "  cd tf && terraform apply"
    exit 1
fi

# Step 2: Verify cluster connection
print_status "Step 2: Verifying cluster connection..."
if kubectl cluster-info &> /dev/null; then
    print_success "Cluster connection verified"
else
    print_error "Cannot connect to cluster"
    exit 1
fi

# Step 3: Setup Helm repository
print_status "Step 3: Setting up Helm repository..."
if ! helm repo list | grep -q "airbyte"; then
    helm repo add airbyte https://airbytehq.github.io/charts
    print_success "Added Airbyte repository"
else
    print_status "Airbyte repository already exists"
fi
helm repo update

# Step 4: Deploy Airbyte
print_status "Step 4: Deploying Airbyte..."
kubectl create namespace airbyte --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install airbyte airbyte/airbyte \
    --namespace airbyte \
    --values applications/airbyte/values-simplified.yaml \
    --timeout 600s \
    --wait

print_success "✅ Airbyte deployed successfully!"

# Step 5: Show access instructions
echo ""
print_success "🎉 Deployment Complete!"
echo "========================"
echo ""
print_status "📋 Quick Access:"
echo "  1. Start port-forward (auto-restart):"
echo "     ./scripts/port-forward-airbyte.sh"
echo ""
echo "  2. Or manual port-forward:"
echo "     kubectl port-forward -n airbyte svc/airbyte-airbyte-server-svc 8080:8001"
echo ""
echo "  3. Open browser to: http://localhost:8080"
echo ""
print_status "🔧 Management Commands:"
echo "  • Check status:    kubectl get pods -n airbyte"
echo "  • View logs:       kubectl logs -n airbyte -l app.kubernetes.io/name=airbyte"
echo "  • Scale up:        ./scripts/scale-airbyte.sh medium"
echo "  • Cleanup:         helm uninstall airbyte -n airbyte"
echo ""
print_warning "💡 Tip: Keep the port-forward command running in a separate terminal"
