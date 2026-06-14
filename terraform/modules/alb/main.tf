# ALB Module
# Creates Application Load Balancer with HTTP/HTTPS listeners and target groups.

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "enable_https" {
  type = bool
}

variable "certificate_arn" {
  type = string
}

locals {
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

resource "aws_security_group" "alb" {
  name        = "vegan-mundi-${var.environment}-alb-sg"
  description = "Allow HTTP/HTTPS access to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "vegan-mundi-${var.environment}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_lb" "main" {
  name               = "vegan-mundi-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  tags = {
    Name        = "vegan-mundi-${var.environment}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "services" {
  for_each = toset(local.services)

  name        = substr(replace("vm-${var.environment}-${each.key}", "service", "svc"), 0, 32)
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["account-service"].arn
  }
}

resource "aws_lb_listener" "https" {
  count = var.enable_https && var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["account-service"].arn
  }
}

output "load_balancer_dns_name" {
  value = aws_lb.main.dns_name
}

output "load_balancer_arn" {
  value = aws_lb.main.arn
}

output "target_group_arns" {
  value = { for k, v in aws_lb_target_group.services : k => v.arn }
}

output "security_group_id" {
  value = aws_security_group.alb.id
}
