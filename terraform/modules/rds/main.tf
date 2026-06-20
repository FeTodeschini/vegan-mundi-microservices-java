# RDS Module
# Creates MySQL RDS instance, subnet group, security group and optional schema/data bootstrap.

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_id" {
  type = string
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = []
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "publicly_accessible" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 1
}

variable "bootstrap_db" {
  type    = bool
  default = false
}

variable "db_schema_file" {
  type    = string
  default = ""
}

variable "db_seed_file" {
  type    = string
  default = ""
}

resource "aws_security_group" "rds" {
  name        = "vegan-mundi-${var.environment}-rds-sg"
  description = "RDS MySQL security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [var.allowed_security_group_id]
    description     = "Allow MySQL traffic from ECS instances"
  }

  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = var.db_port
      to_port     = var.db_port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
      description = "Allow MySQL traffic from approved external CIDRs"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "vegan-mundi-${var.environment}-rds-sg"
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "vegan-mundi-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "vegan-mundi-${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "main" {
  identifier              = "vegan-mundi-${var.environment}"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  port                    = var.db_port
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = var.publicly_accessible
  skip_final_snapshot     = var.skip_final_snapshot
  backup_retention_period = var.backup_retention_period
  apply_immediately       = true

  tags = {
    Name        = "vegan-mundi-${var.environment}"
    Environment = var.environment
  }
}

resource "null_resource" "db_bootstrap" {
  count = var.bootstrap_db ? 1 : 0

  triggers = {
    endpoint   = aws_db_instance.main.address
    db_name    = var.db_name
    schema_sha = var.db_schema_file != "" ? filesha256(var.db_schema_file) : ""
    seed_sha   = var.db_seed_file != "" ? filesha256(var.db_seed_file) : ""
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/bootstrap_db.sh \"${aws_db_instance.main.address}\" \"${var.db_port}\" \"${var.db_username}\" \"${var.db_name}\" \"${var.db_schema_file}\" \"${var.db_seed_file}\""

    environment = {
      MYSQL_PWD = var.db_password
    }
  }

  depends_on = [aws_db_instance.main]
}

output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_security_group_id" {
  value = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.main.name
}

output "db_publicly_accessible" {
  value = aws_db_instance.main.publicly_accessible
}
