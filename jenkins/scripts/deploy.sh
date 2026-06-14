#!/bin/bash
# Deploy script for ECS updates

set -e

ENVIRONMENT=${1:-test}
IMAGE_TAG=${BUILD_NUMBER:-latest}

echo "Deploying to $ENVIRONMENT environment..."

CLUSTER="vegan-mundi-${ENVIRONMENT}-cluster"
SERVICES=("account-service" "class-service" "order-service" "review-service" "delivery-service" "gallery-service" "price-service")

for service in "${SERVICES[@]}"; do
    echo "Updating $service..."
    # Update service deployment (triggers rolling update)
    aws ecs update-service \
        --cluster "$CLUSTER" \
        --service "vegan-mundi-${service}-service" \
        --force-new-deployment \
        --region us-east-2 > /dev/null
done

echo "✓ Deployment initiated"
