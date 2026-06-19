terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "vegan-mundi-tf-state-211125337663-us-east-2"
    key     = "vegan-mundi/network/prod/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "vegan-mundi"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Stack       = "network"
    }
  }
}
