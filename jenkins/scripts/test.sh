#!/bin/bash
# Test runner script

set -e

ENVIRONMENT=${1:-test}

echo "Running tests for $ENVIRONMENT..."

mvn test

echo "✓ All tests passed"
