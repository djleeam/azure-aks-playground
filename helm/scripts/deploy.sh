#!/bin/bash

# Main deployment script for Helm applications
# Usage: ./deploy.sh <application> <environment> [additional-helm-args]
# Example: ./deploy.sh airbyte dev
# Example: ./deploy.sh airbyte prod --dry-run

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

# Function to show usage
show_usage() {
    echo "Usage: $0 <application> [additional-helm-args]"
    echo ""
    echo "Applications:"
    echo "  airbyte    - Deploy Airbyte data integration platform"
    echo ""
    echo "Environment:"
    echo "  This script deploys to the development environment (airbyte-dev namespace)"
    echo ""
    echo "Examples:"
    echo "  $0 airbyte"
    echo "  $0 airbyte --dry-run"
    echo "  $0 airbyte --timeout 600s"
    echo ""
    echo "Additional Helm arguments can be passed after the application name."
}

# Check arguments
if [[ $# -lt 1 ]]; then
    print_error "Missing required arguments"
    show_usage
    exit 1
fi

APPLICATION=$1
ENVIRONMENT="dev"  # Fixed to development environment
shift 1  # Remove first argument, rest are additional helm args
ADDITIONAL_ARGS="$@"

# Validate application
case $APPLICATION in
    airbyte)
        APP_DIR="applications/airbyte"
        ;;
    *)
        print_error "Unknown application: $APPLICATION"
        show_usage
        exit 1
        ;;
esac

# Environment is fixed to dev for this playground setup
print_status "Using development environment (airbyte-dev namespace)"

# Check if we're in the right directory
if [[ ! -d "applications" ]]; then
    print_error "This script should be run from the helm/ directory"
    print_error "Current directory: $(pwd)"
    exit 1
fi

# Check if application directory exists
if [[ ! -d "$APP_DIR" ]]; then
    print_error "Application directory not found: $APP_DIR"
    exit 1
fi

# Check if values file exists
VALUES_FILE="$APP_DIR/values/$ENVIRONMENT.yaml"
COMMON_VALUES_FILE="$APP_DIR/values/common.yaml"

if [[ ! -f "$VALUES_FILE" ]]; then
    print_error "Values file not found: $VALUES_FILE"
    exit 1
fi

if [[ ! -f "$COMMON_VALUES_FILE" ]]; then
    print_error "Common values file not found: $COMMON_VALUES_FILE"
    exit 1
fi

print_status "Deploying $APPLICATION to $ENVIRONMENT environment"

# Check prerequisites
print_status "Checking prerequisites..."

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install Helm 3.x"
    exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    print_error "kubectl is not configured or cluster is not accessible"
    print_error "Run './scripts/connect-cluster.sh' first to connect to your AKS cluster"
    exit 1
fi

# Get cluster info
CLUSTER_NAME=$(kubectl config current-context)
print_status "Connected to cluster: $CLUSTER_NAME"

# Create namespace if it doesn't exist
NAMESPACE="${APPLICATION}-${ENVIRONMENT}"
print_status "Ensuring namespace exists: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repository for Airbyte (if needed)
if [[ "$APPLICATION" == "airbyte" ]]; then
    print_status "Adding Airbyte Helm repository..."
    helm repo add airbyte https://airbytehq.github.io/charts
    helm repo update
fi

# Update dependencies
print_status "Updating Helm dependencies..."
cd "$APP_DIR"
helm dependency update

# Deploy using Helm
print_status "Deploying $APPLICATION..."
RELEASE_NAME="${APPLICATION}-${ENVIRONMENT}"

# Build helm command
HELM_CMD="helm upgrade --install $RELEASE_NAME . \
    --namespace $NAMESPACE \
    --values values/common.yaml \
    --values values/$ENVIRONMENT.yaml \
    --timeout 600s \
    --wait"

# Add additional arguments if provided
if [[ -n "$ADDITIONAL_ARGS" ]]; then
    HELM_CMD="$HELM_CMD $ADDITIONAL_ARGS"
fi

print_status "Executing: $HELM_CMD"
echo ""

# Execute the helm command
if eval $HELM_CMD; then
    print_success "Successfully deployed $APPLICATION to $ENVIRONMENT"
    
    # Show deployment status
    echo ""
    print_status "Deployment Status:"
    helm status "$RELEASE_NAME" --namespace "$NAMESPACE"
    
    echo ""
    print_status "Pod Status:"
    kubectl get pods -n "$NAMESPACE"
    
    echo ""
    print_status "Service Status:"
    kubectl get services -n "$NAMESPACE"
    
    # Show ingress info if available
    if kubectl get ingress -n "$NAMESPACE" &> /dev/null; then
        echo ""
        print_status "Ingress Status:"
        kubectl get ingress -n "$NAMESPACE"
    fi
    
    echo ""
    print_success "Deployment completed successfully!"
    
    # Environment-specific post-deployment info
    case $ENVIRONMENT in
        dev)
            echo ""
            print_status "Development Environment Access:"
            echo "  - Add '127.0.0.1 airbyte-dev.local' to your /etc/hosts file"
            echo "  - Access Airbyte at: http://airbyte-dev.local"
            echo "  - Or use port-forward: kubectl port-forward -n $NAMESPACE svc/${APPLICATION}-webapp 8080:80"
            ;;
        staging)
            echo ""
            print_status "Staging Environment Access:"
            echo "  - Access Airbyte at: https://airbyte-staging.yourdomain.com"
            echo "  - Or use port-forward: kubectl port-forward -n $NAMESPACE svc/${APPLICATION}-webapp 8080:80"
            ;;
        prod)
            echo ""
            print_status "Production Environment Access:"
            echo "  - Access Airbyte at: https://airbyte.yourdomain.com"
            echo "  - Monitor the deployment carefully"
            ;;
    esac
    
else
    print_error "Failed to deploy $APPLICATION to $ENVIRONMENT"
    exit 1
fi

cd - > /dev/null
