data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_iam_policy_document" "jenkins_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins" {
  name               = "vegan-mundi-${var.environment}-jenkins-host-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume.json
}

resource "aws_iam_role_policy_attachment" "jenkins" {
  for_each = toset(var.attach_policy_arns)

  role       = aws_iam_role.jenkins.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "vegan-mundi-${var.environment}-jenkins-host-profile"
  role = aws_iam_role.jenkins.name
}

resource "aws_security_group" "jenkins" {
  name        = "vegan-mundi-${var.environment}-jenkins-sg"
  description = "Security group for Jenkins host"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_ssh_cidrs
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_jenkins_cidrs
    content {
      description = "Jenkins UI"
      from_port   = var.jenkins_port
      to_port     = var.jenkins_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  key_name                    = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    jenkins_port = var.jenkins_port
    repo_url     = var.repo_url
    repo_branch  = var.repo_branch
  })

  tags = {
    Name = "vegan-mundi-${var.environment}-jenkins"
  }
}

resource "aws_eip" "jenkins" {
  count    = var.create_eip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.jenkins.id

  tags = {
    Name = "vegan-mundi-${var.environment}-jenkins-eip"
  }
}
