#!/bin/bash

# Verification script for Helm setup
# This script verifies that all prerequisites are met for Airbyte deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "🔍 Verifying Helm setup for Airbyte deployment..."

# Check if we're in the right directory
if [[ ! -d "applications" ]]; then
    print_error "This script should be run from the helm/ directory"
    exit 1
fi

# Check prerequisites
ERRORS=0

print_status "Checking prerequisites..."

# Check Helm
if command -v helm &> /dev/null; then
    HELM_VERSION=$(helm version --short)
    print_success "Helm is installed: $HELM_VERSION"
else
    print_error "Helm is not installed"
    ERRORS=$((ERRORS + 1))
fi

# Check kubectl
if command -v kubectl &> /dev/null; then
    if kubectl cluster-info &> /dev/null; then
        CLUSTER_NAME=$(kubectl config current-context)
        print_success "kubectl is configured and connected to: $CLUSTER_NAME"
    else
        print_error "kubectl is installed but not connected to a cluster"
        ERRORS=$((ERRORS + 1))
    fi
else
    print_error "kubectl is not installed"
    ERRORS=$((ERRORS + 1))
fi

# Check Azure CLI
if command -v az &> /dev/null; then
    if az account show &> /dev/null; then
        SUBSCRIPTION=$(az account show --query name -o tsv)
        print_success "Azure CLI is logged in to: $SUBSCRIPTION"
    else
        print_warning "Azure CLI is installed but not logged in"
    fi
else
    print_warning "Azure CLI is not installed (optional for Helm deployment)"
fi

# Check Helm repositories
print_status "Checking Helm repositories..."

if helm repo list | grep -q "airbyte"; then
    print_success "Airbyte repository is already added"
else
    print_status "Adding Airbyte repository..."
    helm repo add airbyte https://airbytehq.github.io/charts
    print_success "Airbyte repository added"
fi

# Update repositories
print_status "Updating Helm repositories..."
helm repo update

# Search for Airbyte charts
print_status "Available Airbyte charts:"
helm search repo airbyte

# Check if Chart.yaml exists and dependencies
if [[ -f "applications/airbyte/Chart.yaml" ]]; then
    print_success "Airbyte Chart.yaml found"
    
    # Check dependencies
    print_status "Updating Helm dependencies for Airbyte..."
    cd applications/airbyte
    helm dependency update
    cd - > /dev/null
    print_success "Dependencies updated"
else
    print_error "Airbyte Chart.yaml not found"
    ERRORS=$((ERRORS + 1))
fi

# Check values files
print_status "Checking values files..."
for env in common dev staging prod; do
    if [[ -f "applications/airbyte/values/${env}.yaml" ]]; then
        print_success "Values file found: ${env}.yaml"
    else
        print_error "Values file missing: ${env}.yaml"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check if cluster has sufficient resources
if kubectl cluster-info &> /dev/null; then
    print_status "Checking cluster resources..."
    
    # Check nodes
    NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
    print_status "Cluster has $NODE_COUNT node(s)"
    
    # Check if nodes are ready
    READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready ")
    if [[ $READY_NODES -eq $NODE_COUNT ]]; then
        print_success "All nodes are ready"
    else
        print_warning "Some nodes are not ready ($READY_NODES/$NODE_COUNT)"
    fi
    
    # Check available resources
    print_status "Node resource summary:"
    kubectl top nodes 2>/dev/null || print_warning "Metrics server not available (kubectl top nodes failed)"
fi

# Summary
echo ""
if [[ $ERRORS -eq 0 ]]; then
    print_success "✅ All checks passed! Ready to deploy Airbyte"
    echo ""
    print_status "Next steps:"
    echo "  # Deploy to development environment"
    echo "  ./scripts/deploy.sh airbyte dev"
    echo ""
    echo "  # Deploy to production environment (after setting up secrets)"
    echo "  ./k8s/secrets/create-secrets.sh"
    echo "  ./scripts/deploy.sh airbyte prod"
else
    print_error "❌ $ERRORS error(s) found. Please fix the issues above before deploying."
    exit 1
fi
