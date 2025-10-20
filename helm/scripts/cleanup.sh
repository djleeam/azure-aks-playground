#!/bin/bash

# Cleanup script for Helm applications
# Usage: ./cleanup.sh <application> <environment> [--force]
# Example: ./cleanup.sh airbyte dev
# Example: ./cleanup.sh airbyte prod --force

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
    echo "Usage: $0 <application> [--force]"
    echo ""
    echo "Applications:"
    echo "  airbyte    - Cleanup Airbyte deployment"
    echo ""
    echo "Environment:"
    echo "  This script cleans up the development environment (airbyte-dev namespace)"
    echo ""
    echo "Options:"
    echo "  --force    - Skip confirmation prompts"
    echo ""
    echo "Examples:"
    echo "  $0 airbyte"
    echo "  $0 airbyte --force"
}

# Check arguments
if [[ $# -lt 1 ]]; then
    print_error "Missing required arguments"
    show_usage
    exit 1
fi

APPLICATION=$1
ENVIRONMENT="dev"  # Fixed to development environment
FORCE_MODE=false

# Check for --force flag
if [[ "$2" == "--force" ]]; then
    FORCE_MODE=true
fi

# Validate application
case $APPLICATION in
    airbyte)
        ;;
    *)
        print_error "Unknown application: $APPLICATION"
        show_usage
        exit 1
        ;;
esac

# Environment is fixed to dev for this playground setup
print_status "Cleaning up development environment (airbyte-dev namespace)"

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    print_error "kubectl is not configured or cluster is not accessible"
    exit 1
fi

NAMESPACE="${APPLICATION}-${ENVIRONMENT}"
RELEASE_NAME="${APPLICATION}-${ENVIRONMENT}"

print_warning "This will remove the $APPLICATION deployment from $ENVIRONMENT environment"
print_warning "Namespace: $NAMESPACE"
print_warning "Release: $RELEASE_NAME"

# Check if release exists
if ! helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
    print_warning "Release $RELEASE_NAME not found in namespace $NAMESPACE"
    print_status "Checking if namespace exists..."
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_warning "Namespace $NAMESPACE exists but no Helm release found"
        
        if [[ "$FORCE_MODE" == "false" ]]; then
            echo ""
            read -p "Do you want to delete the namespace anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "Cleanup cancelled"
                exit 0
            fi
        fi
        
        print_status "Deleting namespace $NAMESPACE..."
        kubectl delete namespace "$NAMESPACE"
        print_success "Namespace deleted"
    else
        print_status "Nothing to clean up"
    fi
    exit 0
fi

# Show current status
print_status "Current deployment status:"
helm status "$RELEASE_NAME" -n "$NAMESPACE" || true

echo ""
print_status "Resources in namespace $NAMESPACE:"
kubectl get all -n "$NAMESPACE" || true

# Confirmation for production
if [[ "$ENVIRONMENT" == "prod" && "$FORCE_MODE" == "false" ]]; then
    echo ""
    print_error "⚠️  WARNING: You are about to delete a PRODUCTION deployment!"
    print_error "This action cannot be undone and will result in data loss!"
    echo ""
    read -p "Type 'DELETE PRODUCTION' to confirm: " -r
    if [[ "$REPLY" != "DELETE PRODUCTION" ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
fi

# Confirmation for other environments
if [[ "$FORCE_MODE" == "false" ]]; then
    echo ""
    read -p "Are you sure you want to delete this deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
fi

# Perform cleanup
print_status "Uninstalling Helm release..."
if helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"; then
    print_success "Helm release uninstalled"
else
    print_error "Failed to uninstall Helm release"
    exit 1
fi

# Wait a bit for resources to be cleaned up
print_status "Waiting for resources to be cleaned up..."
sleep 10

# Check if namespace still has resources
REMAINING_RESOURCES=$(kubectl get all -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [[ $REMAINING_RESOURCES -gt 0 ]]; then
    print_warning "Some resources still exist in namespace $NAMESPACE"
    kubectl get all -n "$NAMESPACE"
    
    if [[ "$FORCE_MODE" == "false" ]]; then
        echo ""
        read -p "Do you want to force delete the namespace? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Namespace $NAMESPACE left with remaining resources"
            print_status "You can manually clean up with: kubectl delete namespace $NAMESPACE"
            exit 0
        fi
    fi
    
    print_status "Force deleting namespace..."
    kubectl delete namespace "$NAMESPACE" --force --grace-period=0
else
    print_status "Deleting namespace..."
    kubectl delete namespace "$NAMESPACE"
fi

print_success "Cleanup completed successfully!"

# Show final status
print_status "Verifying cleanup..."
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    print_warning "Namespace $NAMESPACE still exists (may be in terminating state)"
else
    print_success "Namespace $NAMESPACE has been deleted"
fi
