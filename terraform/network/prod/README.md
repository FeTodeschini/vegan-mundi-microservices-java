# Prod Network Stack

This stack provisions only the production VPC layer.

## Resources

- VPC
- Public subnets
- Private subnets
- Internet Gateway
- NAT Gateway (optional via enable_nat)
- Route tables and associations

## Usage

1. Copy vars template:
   - `cp terraform.tfvars.example terraform.tfvars.local`
2. Initialize backend with dedicated state key:
   - Example key: `vegan-mundi/network/prod/terraform.tfstate`
3. Run:
   - `terraform init -reconfigure ...`
   - `terraform plan -var-file=terraform.tfvars.local`
   - `terraform apply -var-file=terraform.tfvars.local`

## Outputs for other stacks

Use these outputs as inputs to Jenkins and app stacks:

- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`
