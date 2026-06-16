output "jenkins_instance_id" {
  description = "EC2 instance ID for Jenkins host"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Public IP of Jenkins host"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_eip" {
  description = "Elastic IP if enabled"
  value       = var.create_eip ? aws_eip.jenkins[0].public_ip : null
}

output "jenkins_url" {
  description = "Jenkins UI URL"
  value       = var.create_eip ? "http://${aws_eip.jenkins[0].public_ip}:${var.jenkins_port}" : "http://${aws_instance.jenkins.public_ip}:${var.jenkins_port}"
}

output "jenkins_security_group_id" {
  description = "Security group ID attached to Jenkins host"
  value       = aws_security_group.jenkins.id
}

output "jenkins_role_arn" {
  description = "IAM role ARN used by Jenkins host"
  value       = aws_iam_role.jenkins.arn
}
