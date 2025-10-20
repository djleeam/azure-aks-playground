#!/bin/bash

# Script to create Kubernetes secrets for Airbyte production deployment
# This script should be run after the cluster is set up and before production deployment

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

# Function to generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    print_error "kubectl is not configured or cluster is not accessible"
    exit 1
fi

print_status "Creating Kubernetes secrets for Airbyte production deployment"

# Create production namespace if it doesn't exist
NAMESPACE="airbyte-prod"
print_status "Ensuring namespace exists: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Generate passwords
POSTGRES_PASSWORD=$(generate_password)
MINIO_ROOT_PASSWORD=$(generate_password)

print_status "Generated secure passwords for production deployment"

# Create PostgreSQL secret
print_status "Creating PostgreSQL secret..."
kubectl create secret generic airbyte-postgresql-secret \
    --from-literal=postgres-password="$POSTGRES_PASSWORD" \
    --from-literal=password="$POSTGRES_PASSWORD" \
    --namespace "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

print_success "PostgreSQL secret created"

# Create MinIO secret
print_status "Creating MinIO secret..."
kubectl create secret generic airbyte-minio-secret \
    --from-literal=root-user="admin" \
    --from-literal=root-password="$MINIO_ROOT_PASSWORD" \
    --namespace "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

print_success "MinIO secret created"

# Create TLS secret placeholder (you'll need to replace with actual certificates)
print_status "Creating TLS secret placeholder..."
kubectl create secret tls airbyte-tls \
    --cert=/dev/null \
    --key=/dev/null \
    --namespace "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f - || true

print_warning "TLS secret created as placeholder. Replace with actual certificates before production deployment."

# Display created secrets
print_status "Created secrets in namespace $NAMESPACE:"
kubectl get secrets -n "$NAMESPACE"

print_success "All secrets created successfully!"

echo ""
print_warning "IMPORTANT SECURITY NOTES:"
echo "1. Store the generated passwords securely (e.g., in Azure Key Vault)"
echo "2. Replace the TLS secret with actual certificates before production deployment"
echo "3. Consider using Azure Key Vault CSI driver for enhanced secret management"
echo "4. Regularly rotate these passwords"

echo ""
print_status "Generated passwords (store these securely):"
echo "PostgreSQL Password: $POSTGRES_PASSWORD"
echo "MinIO Root Password: $MINIO_ROOT_PASSWORD"
