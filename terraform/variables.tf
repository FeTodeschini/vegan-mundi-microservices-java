variable "aws_region" {
  type        = string
  default     = "us-east-2"
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, test, prod)"
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for the region"
  default     = ["us-east-2a", "us-east-2b"]
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for ECS"
  default     = "t3.small"
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of EC2 instances"
  default     = 2
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of EC2 instances"
  default     = 1
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of EC2 instances"
  default     = 4
}

variable "db_username" {
  type        = string
  description = "Database master username"
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Initial database name"
  default     = "vegan_mundi"
}

variable "enable_nat" {
  type        = bool
  description = "Enable NAT Gateway for private subnet internet access"
  default     = true
}

variable "enable_https" {
  type        = bool
  description = "Enable HTTPS on ALB (requires certificate)"
  default     = false
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS (required if enable_https=true)"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Additional tags for resources"
  default     = {}
}
