#!/bin/bash
# Initialize AWS environment for first deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-east-2}
ACCOUNT_ID=${3:-}

echo -e "${YELLOW}Initializing AWS Environment${NC}"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"

# Check AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Run: aws configure${NC}"
    exit 1
fi

if [ -z "$ACCOUNT_ID" ]; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo "AWS Account ID: $ACCOUNT_ID"
fi

# Create S3 bucket for Terraform state
STATE_BUCKET="vegan-mundi-tf-state-${ACCOUNT_ID}-${AWS_REGION}"
echo -e "${YELLOW}Creating Terraform state bucket...${NC}"

if aws s3 ls "s3://${STATE_BUCKET}" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Bucket already exists: s3://${STATE_BUCKET}"
else
    aws s3 mb "s3://${STATE_BUCKET}" --region "$AWS_REGION"
    echo -e "${GREEN}✓${NC} Created S3 bucket: s3://${STATE_BUCKET}"
fi

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$STATE_BUCKET" \
    --versioning-configuration Status=Enabled \
    --region "$AWS_REGION"

# Create DynamoDB table for Terraform locking
LOCK_TABLE="vegan-mundi-tf-lock-${ENVIRONMENT}"
echo -e "${YELLOW}Creating DynamoDB lock table...${NC}"

if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$AWS_REGION" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Table already exists: $LOCK_TABLE"
else
    aws dynamodb create-table \
        --table-name "$LOCK_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION"
    echo -e "${GREEN}✓${NC} Created DynamoDB table: $LOCK_TABLE"
fi

# Create ECR repositories
echo -e "${YELLOW}Creating ECR repositories...${NC}"

SERVICES=("account-service" "class-service" "order-service" "review-service" "delivery-service" "gallery-service" "price-service")

for service in "${SERVICES[@]}"; do
    REPO_NAME="vegan-mundi-${service}"
    
    if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Repository exists: $REPO_NAME"
    else
        aws ecr create-repository \
            --repository-name "$REPO_NAME" \
            --region "$AWS_REGION" \
            --image-scan-configuration scanOnPush=true
        echo -e "${GREEN}✓${NC} Created ECR repository: $REPO_NAME"
    fi
done

# Create Lambda repository
LAMBDA_REPO="vegan-mundi-order-confirmation"
if aws ecr describe-repositories --repository-names "$LAMBDA_REPO" --region "$AWS_REGION" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Lambda repository exists: $LAMBDA_REPO"
else
    aws ecr create-repository \
        --repository-name "$LAMBDA_REPO" \
        --region "$AWS_REGION"
    echo -e "${GREEN}✓${NC} Created Lambda repository: $LAMBDA_REPO"
fi

# Print Terraform backend configuration
echo -e "\n${GREEN}✅ AWS environment initialized${NC}\n"
echo -e "${YELLOW}Add the following to your terraform/${ENVIRONMENT}/backend.tf:${NC}"
cat << EOF

terraform {
  backend "s3" {
    bucket         = "${STATE_BUCKET}"
    key            = "vegan-mundi/${ENVIRONMENT}/terraform.tfstate"
    region         = "${AWS_REGION}"
    dynamodb_table = "${LOCK_TABLE}"
    encrypt        = true
  }
}

EOF

echo -e "${YELLOW}Then initialize Terraform:${NC}"
echo "cd terraform/${ENVIRONMENT}"
echo "terraform init"
