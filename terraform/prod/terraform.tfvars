# Production environment configuration
environment = "prod"
aws_region  = "us-east-2"

# Networking (from terraform/network/prod outputs)
vpc_id             = "vpc-REPLACE_ME"
public_subnet_ids  = ["subnet-PUBLIC-1", "subnet-PUBLIC-2"]
private_subnet_ids = ["subnet-PRIVATE-1", "subnet-PRIVATE-2"]

# Compute
instance_type     = "t3.small"
desired_capacity  = 3
min_capacity      = 2
max_capacity      = 6

# Database
db_username = "admin"
db_name                    = "vegan_mundi_prod"
db_instance_class          = "db.t3.micro"
db_allocated_storage       = 20
db_publicly_accessible     = false
db_skip_final_snapshot     = false
db_backup_retention_period = 7
bootstrap_db               = false
db_schema_file             = "../../db/ddl/all-tables.sql"
db_seed_file               = "../../db/seed/seed.sql"

# TLS
enable_https    = true
# certificate_arn = "arn:aws:acm:us-east-2:123456789:certificate/xxxxx"
