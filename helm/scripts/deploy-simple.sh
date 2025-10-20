#!/bin/bash

# Simplified deployment script for Airbyte
# Usage: ./deploy-simple.sh [--dry-run]

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if dry-run flag is provided
DRY_RUN=""
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    print_status "Running in dry-run mode"
fi

print_status "🚀 Deploying Airbyte to AKS cluster..."

# Check prerequisites
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    print_error "kubectl is not configured. Run '../scripts/connect-cluster.sh' first"
    exit 1
fi

# Add repository if not exists
if ! helm repo list | grep -q "airbyte"; then
    print_status "Adding Airbyte repository..."
    helm repo add airbyte https://airbytehq.github.io/charts
fi

print_status "Updating Helm repositories..."
helm repo update

# Create namespace
print_status "Creating namespace..."
kubectl create namespace airbyte-dev --dry-run=client -o yaml | kubectl apply -f -

# Deploy Airbyte directly (no wrapper chart)
print_status "Deploying Airbyte..."
helm upgrade --install airbyte airbyte/airbyte \
    --namespace airbyte-dev \
    --values applications/airbyte/values-simplified.yaml \
    --timeout 600s \
    --wait \
    $DRY_RUN

if [[ -z "$DRY_RUN" ]]; then
    print_success "✅ Airbyte deployed successfully!"
    
    echo ""
    print_status "📋 Access Information:"
    echo "  1. Port-forward to access Airbyte:"
    echo "     kubectl port-forward -n airbyte-dev svc/airbyte-webapp 8080:80"
    echo ""
    echo "  2. Open browser to: http://localhost:8080"
    echo ""
    echo "  3. Check deployment status:"
    echo "     kubectl get pods -n airbyte-dev"
    echo ""
    echo "  4. View logs:"
    echo "     kubectl logs -n airbyte-dev -l app.kubernetes.io/name=airbyte"
else
    print_success "✅ Dry-run completed successfully!"
fi
