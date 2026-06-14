# Lambda Module
# Creates Lambda function for order confirmation processing

variable "environment" {
  type = string
}

variable "iam_role_arn" {
  type = string
}

resource "aws_lambda_function" "order_confirmation" {
  function_name = "vegan-mundi-order-confirmation-${var.environment}"
  role          = var.iam_role_arn
  handler       = "com.veganmundi.lambda.OrderConfirmationHandler::handleRequest"
  runtime       = "java17"
  memory_size   = 512
  timeout       = 30

  # Placeholder package for initial infra provisioning.
  filename         = "${path.module}/placeholder/lambda-placeholder.zip"
  source_code_hash = filebase64sha256("${path.module}/placeholder/lambda-placeholder.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name        = "vegan-mundi-order-confirmation-${var.environment}"
    Environment = var.environment
  }
}

output "function_arn" {
  value = aws_lambda_function.order_confirmation.arn
}

output "function_name" {
  value = aws_lambda_function.order_confirmation.function_name
}
