variable "aws_region" {
  type        = string
  default     = "us-east-2"
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, test, prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for the region"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for ECS"
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of EC2 instances"
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of EC2 instances"
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of EC2 instances"
}

variable "enable_nat" {
  type        = bool
  description = "Enable NAT Gateway for private subnet internet access"
}

variable "enable_https" {
  type        = bool
  description = "Enable HTTPS on ALB (requires certificate)"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS (required if enable_https=true)"
}