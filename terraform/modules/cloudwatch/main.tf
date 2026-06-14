# CloudWatch Module
# Creates log groups and alarms for microservices

variable "environment" {
  type = string
}

variable "services" {
  type = list(string)
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/vegan-mundi-${var.environment}"
  retention_in_days = 14

  tags = {
    Name        = "vegan-mundi-${var.environment}-ecs-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "service" {
  for_each = toset(var.services)

  name              = "/ecs/vegan-mundi-${var.environment}/${each.key}"
  retention_in_days = 14

  tags = {
    Name        = "vegan-mundi-${var.environment}-${each.key}-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/vegan-mundi-order-confirmation-${var.environment}"
  retention_in_days = 14

  tags = {
    Name        = "vegan-mundi-${var.environment}-lambda-logs"
    Environment = var.environment
  }
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.ecs.arn
}
