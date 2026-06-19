# Terraform Run Guide

This repository is the source of truth for shared RDS provisioning.

## Ownership Model

- RDS is provisioned in this repo via `module.rds` in environment stacks (`dev`, `test`, `prod`).
- Other repos (for example Node backend config) should consume DB endpoint/credentials and must not create the same DB.

## Apply Full Environment

```bash
cd terraform/prod
terraform init
terraform plan -var-file="terraform.tfvars" -var-file="terraform.tfvars.local"
terraform apply -var-file="terraform.tfvars" -var-file="terraform.tfvars.local"
```

## Apply Only RDS

Use Terraform targeting when you intentionally want only DB resources:

```bash
cd terraform/prod
terraform plan \
  -target=module.rds \
  -var-file="terraform.tfvars" \
  -var-file="terraform.tfvars.local"

terraform apply \
  -target=module.rds \
  -var-file="terraform.tfvars" \
  -var-file="terraform.tfvars.local"
```

## Apply Only Specific Infrastructure Modules

Examples:

```bash
# Only ECS cluster/ASG resources
terraform apply -target=module.ecs -var-file="terraform.tfvars" -var-file="terraform.tfvars.local"

# Only ALB resources
terraform apply -target=module.alb -var-file="terraform.tfvars" -var-file="terraform.tfvars.local"

# Only ECR repositories
terraform apply -target=module.ecr -var-file="terraform.tfvars" -var-file="terraform.tfvars.local"
```

## Important Notes About -target

- `-target` is best for controlled partial operations, break-fix, or phased rollout.
- After targeted apply, run a full `terraform plan` (without `-target`) to detect drift and pending changes.
- Keep this as an operational tool, not the normal day-to-day workflow.

## Useful Outputs

```bash
terraform output db_endpoint
terraform output db_port
terraform output db_name
```

Use these values to configure both Node and Java backends.
