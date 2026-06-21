# Lambda Module
# Creates Lambda function for order confirmation processing

variable "environment" {
  type = string
}

variable "iam_role_arn" {
  type = string
}

variable "lambda_package_path" {
  type        = string
  description = "Path to the built Lambda deployment artifact (JAR/ZIP)."
}

resource "aws_lambda_function" "order_confirmation" {
  function_name = "vegan-mundi-order-confirmation-${var.environment}"
  role          = var.iam_role_arn
  handler       = "com.veganmundi.lambda.OrderConfirmationHandler::handleRequest"
  runtime       = "java17"
  memory_size   = 512
  timeout       = 30

  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)

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
