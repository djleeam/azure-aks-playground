#!/bin/bash

# Auto-restarting port-forward script for Airbyte
# This script maintains a persistent connection to Airbyte with automatic restart on disconnect
# Usage: ./port-forward-airbyte.sh [port] [namespace]

set -e

# Default values
PORT=${1:-8080}
NAMESPACE=${2:-airbyte}
SERVICE_NAME="airbyte-airbyte-server-svc"
SERVICE_PORT="8001"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to check if service exists
check_service() {
    if ! kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" &> /dev/null; then
        print_error "Service $SERVICE_NAME not found in namespace $NAMESPACE"
        print_status "Available services in $NAMESPACE:"
        kubectl get svc -n "$NAMESPACE" 2>/dev/null || echo "  No services found or namespace doesn't exist"
        return 1
    fi
    return 0
}

# Function to check if port is available
check_port() {
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port $PORT is already in use"
        print_status "Processes using port $PORT:"
        lsof -Pi :$PORT -sTCP:LISTEN
        echo ""
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Cleanup function
cleanup() {
    print_warning "Received interrupt signal. Cleaning up..."
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

echo "🔗 Airbyte Port-Forward with Auto-Restart"
echo "=========================================="
print_status "Target: $SERVICE_NAME:$SERVICE_PORT in namespace '$NAMESPACE'"
print_status "Local port: $PORT"
print_status "Access URL: http://localhost:$PORT"
echo ""

# Initial checks
print_status "Checking prerequisites..."

# Check if kubectl is available and configured
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    print_error "kubectl is not configured or cluster is not accessible"
    print_status "Try running: ./connect-cluster.sh"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    print_error "Namespace '$NAMESPACE' does not exist"
    print_status "Available namespaces:"
    kubectl get namespaces
    exit 1
fi

# Check if service exists
if ! check_service; then
    exit 1
fi

# Check if port is available
check_port

print_success "All checks passed!"
echo ""

# Main port-forward loop with auto-restart
RESTART_COUNT=0
while true; do
    if [[ $RESTART_COUNT -gt 0 ]]; then
        print_warning "Connection lost. Restarting port-forward (attempt #$RESTART_COUNT)..."
        sleep 2
    else
        print_status "Starting port-forward..."
    fi
    
    # Start port-forward
    kubectl port-forward -n "$NAMESPACE" svc/"$SERVICE_NAME" "$PORT:$SERVICE_PORT" 2>&1 | while read line; do
        # Filter out some verbose kubectl messages but keep important ones
        if [[ "$line" =~ "Forwarding from" ]]; then
            print_success "$line"
        elif [[ "$line" =~ "Handling connection" ]]; then
            # Only show first few connection messages to avoid spam
            if [[ $RESTART_COUNT -eq 0 ]]; then
                print_status "Receiving connections..."
                RESTART_COUNT=1  # Prevent further connection messages
            fi
        elif [[ "$line" =~ "error" ]] || [[ "$line" =~ "Error" ]]; then
            print_error "$line"
        else
            echo "$line"
        fi
    done
    
    # If we get here, the port-forward has exited
    RESTART_COUNT=$((RESTART_COUNT + 1))
    
    # Check if service still exists before restarting
    if ! check_service; then
        print_error "Service no longer exists. Exiting."
        exit 1
    fi
    
    # Add exponential backoff for rapid failures
    if [[ $RESTART_COUNT -gt 5 ]]; then
        SLEEP_TIME=$((RESTART_COUNT > 10 ? 30 : RESTART_COUNT * 2))
        print_warning "Multiple failures detected. Waiting ${SLEEP_TIME}s before retry..."
        sleep $SLEEP_TIME
    fi
done
