#!/bin/bash

# Connect to AKS cluster using Terraform outputs
# This script reads the cluster information from Terraform state and configures kubectl

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if we're in the right directory
if [[ ! -d "../tf" ]]; then
    print_error "This script should be run from the helm/ directory"
    print_error "Current directory: $(pwd)"
    exit 1
fi

# Check if Terraform state exists
if [[ ! -f "../tf/terraform.tfstate" ]]; then
    print_error "Terraform state not found. Please deploy the AKS cluster first:"
    echo "  cd ../tf"
    echo "  terraform apply"
    exit 1
fi

print_status "Connecting to AKS cluster..."

# Get cluster information from Terraform outputs
cd ../tf

# Check if terraform is available
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed or not in PATH"
    exit 1
fi

# Get cluster details
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null)
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null)

if [[ -z "$RESOURCE_GROUP" ]] || [[ -z "$CLUSTER_NAME" ]]; then
    print_error "Could not retrieve cluster information from Terraform outputs"
    print_error "Make sure the AKS cluster is deployed and Terraform state is available"
    exit 1
fi

print_status "Resource Group: $RESOURCE_GROUP"
print_status "Cluster Name: $CLUSTER_NAME"

# Check if Azure CLI is logged in
if ! az account show &> /dev/null; then
    print_error "Azure CLI is not logged in. Please run 'az login' first"
    exit 1
fi

# Get AKS credentials
print_status "Getting AKS credentials..."
if az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing; then
    print_success "Successfully connected to AKS cluster"
else
    print_error "Failed to get AKS credentials"
    exit 1
fi

# Verify connection
print_status "Verifying cluster connection..."
if kubectl cluster-info &> /dev/null; then
    print_success "Cluster connection verified"
    
    # Show cluster info
    echo ""
    print_status "Cluster Information:"
    kubectl cluster-info
    
    echo ""
    print_status "Node Status:"
    kubectl get nodes
    
    echo ""
    print_success "Ready to deploy applications with Helm!"
    echo ""
    echo "Next steps:"
    echo "  # Deploy Airbyte using simplified configuration"
    echo "  ./scripts/deploy-simple.sh"
    echo ""
    echo "  # Or deploy using standard configuration"
    echo "  ./scripts/deploy.sh airbyte"
    
else
    print_error "Failed to connect to cluster"
    exit 1
fi

cd - > /dev/null
