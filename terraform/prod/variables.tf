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

variable "enable_nat" {
  type        = bool
  description = "Enable NAT Gateway for private subnet internet access"
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

variable "enable_https" {
  type        = bool
  description = "Enable HTTPS on ALB (requires certificate)"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS (required if enable_https=true)"
}

variable "db_username" {
  type        = string
  description = "RDS master username"
}

variable "db_password" {
  type        = string
  description = "RDS master password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Initial database name"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "RDS allocated storage in GB"
  default     = 20
}

variable "db_publicly_accessible" {
  type        = bool
  description = "Whether RDS is publicly accessible"
  default     = false
}

variable "db_allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to connect to RDS from outside VPC"
  default     = []
}

variable "db_skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on destroy"
  default     = false
}

variable "db_backup_retention_period" {
  type        = number
  description = "Backup retention period in days"
  default     = 7
}

variable "bootstrap_db" {
  type        = bool
  description = "Populate DB schema/data after RDS provisioning"
  default     = false
}

variable "db_schema_file" {
  type        = string
  description = "Path to SQL schema file used by DB bootstrap"
  default     = "../../db/ddl/all-tables.sql"
}

variable "db_seed_file" {
  type        = string
  description = "Path to SQL seed file used by DB bootstrap"
  default     = "../../db/seed/seed.sql"
}
