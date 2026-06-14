# EventBridge Module
# Creates EventBridge rules for domain events

variable "environment" {
  type = string
}

variable "lambda_function_arn" {
  type = string
}

resource "aws_cloudwatch_event_rule" "order_created" {
  name        = "vegan-mundi-${var.environment}-order-created"
  description = "Routes order created events to lambda"

  event_pattern = jsonencode({
    source      = ["vegan-mundi.order-service"]
    detail-type = ["OrderCreated"]
  })
}

resource "aws_cloudwatch_event_target" "order_created_lambda" {
  rule      = aws_cloudwatch_event_rule.order_created.name
  target_id = "order-confirmation-lambda"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.order_created.arn
}

output "rule_arn" {
  value = aws_cloudwatch_event_rule.order_created.arn
}

output "rule_name" {
  value = aws_cloudwatch_event_rule.order_created.name
}
