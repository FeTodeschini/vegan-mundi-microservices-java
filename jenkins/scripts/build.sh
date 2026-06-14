#!/bin/bash
# Build script for Jenkins CI/CD pipeline

set -e

ENVIRONMENT=${1:-test}
SKIP_TESTS=${2:-false}
IMAGE_TAG=${BUILD_NUMBER:-latest}

echo "========================================="
echo "Building Vegan Mundi Services"
echo "Environment: $ENVIRONMENT"
echo "Image Tag: $IMAGE_TAG"
echo "Skip Tests: $SKIP_TESTS"
echo "========================================="

# Build with Maven
echo "Building all services with Maven..."
if [ "$SKIP_TESTS" = "true" ]; then
    mvn clean package -DskipTests -q
else
    mvn clean package -q
fi

echo "✓ Maven build successful"
