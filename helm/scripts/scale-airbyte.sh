#!/bin/bash

# Simple scaling script for Airbyte components
# Usage: ./scale-airbyte.sh [small|medium|large]

set -e

SCALE=${1:-small}

case $SCALE in
    small)
        WEBAPP_REPLICAS=1
        SERVER_REPLICAS=1
        WORKER_REPLICAS=1
        echo "🔧 Scaling to SMALL (development-like)"
        ;;
    medium)
        WEBAPP_REPLICAS=1
        SERVER_REPLICAS=2
        WORKER_REPLICAS=2
        echo "🔧 Scaling to MEDIUM (staging-like)"
        ;;
    large)
        WEBAPP_REPLICAS=2
        SERVER_REPLICAS=2
        WORKER_REPLICAS=3
        echo "🔧 Scaling to LARGE (production-like)"
        ;;
    *)
        echo "Usage: $0 [small|medium|large]"
        exit 1
        ;;
esac

# Scale deployments
kubectl scale deployment airbyte-webapp --replicas=$WEBAPP_REPLICAS -n airbyte
kubectl scale deployment airbyte-server --replicas=$SERVER_REPLICAS -n airbyte  
kubectl scale deployment airbyte-worker --replicas=$WORKER_REPLICAS -n airbyte

echo "✅ Scaled Airbyte to $SCALE configuration"
echo "📊 Current status:"
kubectl get deployments -n airbyte
