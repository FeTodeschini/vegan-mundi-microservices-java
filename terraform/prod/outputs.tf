output "alb_dns_name" {
  value       = module.alb.load_balancer_dns_name
  description = "DNS name of the load balancer"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID created for prod stack"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Private subnet IDs created for prod stack"
}

output "alb_arn" {
  value       = module.alb.load_balancer_arn
  description = "ARN of the load balancer"
}

output "ecs_cluster_name" {
  value       = module.ecs.cluster_name
  description = "Name of the ECS cluster"
}

output "ecs_cluster_arn" {
  value       = module.ecs.cluster_arn
  description = "ARN of the ECS cluster"
}

output "ecr_repository_urls" {
  value       = module.ecr.repository_urls
  description = "URLs of ECR repositories"
}

output "cloudwatch_log_group" {
  value       = module.cloudwatch.log_group_name
  description = "CloudWatch log group for ECS"
}

output "eventbridge_rule_arn" {
  value       = module.eventbridge.rule_arn
  description = "EventBridge rule ARN for order events"
}

output "lambda_function_arn" {
  value       = module.lambda.function_arn
  description = "Lambda function ARN for order confirmation"
}

output "db_endpoint" {
  value       = module.rds.db_endpoint
  description = "RDS endpoint"
}

output "db_port" {
  value       = module.rds.db_port
  description = "RDS port"
}

output "db_name" {
  value       = module.rds.db_name
  description = "RDS database name"
}

output "db_subnet_group_name" {
  value       = module.rds.db_subnet_group_name
  description = "RDS DB subnet group name"
}

output "db_publicly_accessible" {
  value       = module.rds.db_publicly_accessible
  description = "Whether RDS is publicly accessible"
}
