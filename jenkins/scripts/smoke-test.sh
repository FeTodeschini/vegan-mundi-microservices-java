#!/bin/bash
# Smoke test script post-deployment

set -e

ENVIRONMENT=${1:-test}

echo "Running smoke tests for $ENVIRONMENT..."

# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?contains(LoadBalancerName, 'vegan-mundi-${ENVIRONMENT}')].DNSName" \
    --output text \
    --region us-east-2)

if [ -z "$ALB_DNS" ]; then
    echo "❌ ALB not found"
    exit 1
fi

echo "ALB: $ALB_DNS"

# Test endpoints
SERVICES=("account" "classes" "orders" "reviews" "deliveries" "gallery" "prices")

for service in "${SERVICES[@]}"; do
    echo -n "Testing /$service/health... "
    if curl -sf "http://${ALB_DNS}/api/${service}/health" > /dev/null; then
        echo "✓"
    else
        echo "✗ (FAILED)"
        exit 1
    fi
done

echo "✓ All smoke tests passed"
