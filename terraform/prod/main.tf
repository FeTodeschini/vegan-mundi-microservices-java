# Main configuration for prod environment
# This file instantiates all modules, including a dedicated prod VPC.
terraform {
  required_version = ">= 1.0"
}

module "vpc" {
  source = "../modules/vpc"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat         = var.enable_nat
}

module "alb" {
  source = "../modules/alb"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids

  enable_https    = var.enable_https
  certificate_arn = var.certificate_arn
}

module "ecr" {
  source = "../modules/ecr"

  environment = var.environment

  services = [
    "account-service",
    "class-service",
    "order-service",
    "review-service",
    "delivery-service",
    "gallery-service",
    "price-service"
  ]
}

module "iam" {
  source = "../modules/iam"

  environment = var.environment
}

module "ecs" {
  source = "../modules/ecs"

  environment           = var.environment
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  instance_type        = var.instance_type
  desired_capacity     = var.desired_capacity
  min_capacity         = var.min_capacity
  max_capacity         = var.max_capacity
  ecs_instance_role_arn  = module.iam.ecs_instance_role_arn
  ecs_instance_profile_name = module.iam.ecs_instance_profile_name
}

module "cloudwatch" {
  source = "../modules/cloudwatch"

  environment = var.environment
  services = [
    "account-service",
    "class-service",
    "order-service",
    "review-service",
    "delivery-service",
    "gallery-service",
    "price-service"
  ]
}

module "lambda" {
  source = "../modules/lambda"

  environment         = var.environment
  iam_role_arn        = module.iam.lambda_execution_role_arn
  lambda_package_path = var.lambda_package_path
}

module "eventbridge" {
  source = "../modules/eventbridge"

  environment            = var.environment
  lambda_function_arn   = module.lambda.function_arn
}

module "rds" {
  source = "../modules/rds"

  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.public_subnet_ids
  # Keep prod RDS independent from ECS so targeted ECS destroy does not pull RDS into the destroy graph.
  allowed_security_group_id = null
  allowed_cidr_blocks       = var.db_allowed_cidr_blocks

  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  db_instance_class       = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  publicly_accessible     = true
  skip_final_snapshot     = var.db_skip_final_snapshot
  backup_retention_period = var.db_backup_retention_period

  bootstrap_db   = var.bootstrap_db
  db_schema_file = var.db_schema_file
  db_seed_file   = var.db_seed_file
}
