variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-2"
}

variable "environment" {
  type        = string
  description = "Environment name for jenkins stack"
  default     = "jenkins"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Jenkins EC2 will be deployed"
}

variable "public_subnet_id" {
  type        = string
  description = "Public subnet ID for Jenkins EC2"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for Jenkins host"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Optional EC2 key pair name"
  default     = ""
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR ranges allowed to SSH to Jenkins host"
  default     = []
}

variable "allowed_jenkins_cidrs" {
  type        = list(string)
  description = "CIDR ranges allowed to access Jenkins UI"
  default     = ["0.0.0.0/0"]
}

variable "jenkins_port" {
  type        = number
  description = "Jenkins UI port"
  default     = 8080
}

variable "root_volume_size" {
  type        = number
  description = "Root EBS volume size in GB"
  default     = 40
}

variable "create_eip" {
  type        = bool
  description = "Whether to create and associate an Elastic IP"
  default     = true
}

variable "repo_url" {
  type        = string
  description = "Optional git repo URL to clone during bootstrap"
  default     = ""
}

variable "repo_branch" {
  type        = string
  description = "Git branch for bootstrap clone"
  default     = "main"
}

variable "attach_policy_arns" {
  type        = list(string)
  description = "IAM policies attached to Jenkins EC2 role"
  default = [
    "arn:aws:iam::aws:policy/PowerUserAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}
