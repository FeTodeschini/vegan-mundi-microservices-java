# Development environment configuration
environment = "dev"
aws_region  = "us-east-2"

# Networking
vpc_cidr               = "10.0.3.0/16"
availability_zones    = ["us-east-2a", "us-east-2b"]
enable_nat            = true

# Compute
instance_type     = "t3.micro"
desired_capacity  = 2
min_capacity      = 1
max_capacity      = 4

# TLS
enable_https = false
certificate_arn = ""

# Tags
tags = {
  CostCenter = "Engineering"
  Owner      = "DevOps"
}
