#!/bin/bash
# Rollback script - reverts to previous ECS task definitions

set -e

ENVIRONMENT=${1:-test}

echo "⚠️ Rolling back $ENVIRONMENT deployment..."

CLUSTER="vegan-mundi-${ENVIRONMENT}-cluster"
SERVICES=("account-service" "class-service" "order-service" "review-service" "delivery-service" "gallery-service" "price-service")

for service in "${SERVICES[@]}"; do
    echo "Rolling back $service..."
    
    # Get current task definition
    CURRENT_TASK=$(aws ecs describe-services \
        --cluster "$CLUSTER" \
        --services "vegan-mundi-${service}-service" \
        --query 'services[0].taskDefinition' \
        --output text \
        --region us-east-2)
    
    # Get previous task definition revision
    REVISION=$(echo "$CURRENT_TASK" | sed 's/.*://g')
    PREV_REVISION=$((REVISION - 1))
    TASK_NAME=$(echo "$CURRENT_TASK" | sed "s/:$REVISION//g")
    PREV_TASK="${TASK_NAME}:${PREV_REVISION}"
    
    # Update service to previous task definition
    aws ecs update-service \
        --cluster "$CLUSTER" \
        --service "vegan-mundi-${service}-service" \
        --task-definition "$PREV_TASK" \
        --region us-east-2 > /dev/null
    
    echo "Rolled back to $PREV_TASK"
done

echo "✓ Rollback complete"
