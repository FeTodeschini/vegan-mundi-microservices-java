terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for remote state
  # To initialize:
  # terraform init -backend-config="bucket=YOUR_BUCKET" \
  #                -backend-config="key=vegan-mundi/terraform.tfstate" \
  #                -backend-config="region=us-east-2" \
  #                -backend-config="dynamodb_table=vegan-mundi-tf-lock"
  
  backend "s3" {
    # These values must be provided via backend-config or terraform init
    # bucket         = "vegan-mundi-tf-state"
    # key            = "vegan-mundi/terraform.tfstate"
    # region         = "us-east-2"
    # dynamodb_table = "vegan-mundi-tf-lock"
    # encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "vegan-mundi"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}
