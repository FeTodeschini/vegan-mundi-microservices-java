# Terraform Jenkins Stack (Jenkins Host)

This stack provisions a dedicated EC2 host for Jenkins, separate from app environments.

## Why this exists

- Keeps CI/CD available even when test/prod app stacks are destroyed.
- Isolates Terraform state and blast radius for Jenkins infrastructure.
- Supports final architecture: Jenkins on EC2, app workloads on ECS.

## Files

- `providers.tf`: AWS provider + remote state backend placeholder.
- `variables.tf`: Inputs for network, host sizing, access, IAM policies.
- `main.tf`: IAM role/profile, security group, Jenkins EC2, optional EIP.
- `outputs.tf`: Instance identifiers and Jenkins URL outputs.
- `terraform.tfvars.local.example`: Template for local values.
- `user_data.sh.tftpl`: Bootstrap script for Docker + optional repo clone.

## Bootstrap

1. Copy tfvars template:
   - `cp terraform.tfvars.local.example terraform.tfvars.local`
2. Set `vpc_id`, `public_subnet_id`, and tighten CIDRs.
3. Initialize backend with a dedicated key, for example:
   - `vegan-mundi/jenkins/terraform.tfstate`
4. Run:
   - `terraform init -reconfigure ...`
   - `terraform plan -var-file=terraform.tfvars.local`
   - `terraform apply -var-file=terraform.tfvars.local`

## Recommended backend separation

- Jenkins key: `vegan-mundi/jenkins/terraform.tfstate`
- Prod key: `vegan-mundi/prod/terraform.tfstate`
- Test key: `vegan-mundi/test/terraform.tfstate`

## Security notes

- Restrict `allowed_ssh_cidrs` and `allowed_jenkins_cidrs`.
- Replace broad IAM policies with least privilege once stable.
- Keep secrets in Jenkins credentials, not committed files.
