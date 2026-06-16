variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-2"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "prod"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for the region"
  default     = ["us-east-2a", "us-east-2b"]
}

variable "enable_nat" {
  type        = bool
  description = "Enable NAT Gateway for private subnet internet access"
  default     = true
}
