# Production environment configuration
environment = "prod"
aws_region  = "us-east-2"

# Networking (dedicated prod VPC)
vpc_cidr           = "10.1.0.0/16"
availability_zones = ["us-east-2a", "us-east-2b"]
enable_nat         = true

# Compute
instance_type     = "t3.micro"
desired_capacity  = 2
min_capacity      = 2
max_capacity      = 3

# Database
db_username = "admin"
db_name                    = "vegan_mundi_prod"
db_instance_class          = "db.t3.micro"
db_allocated_storage       = 20
db_publicly_accessible     = false
db_allowed_cidr_blocks     = ["76.98.179.193/32"]
db_skip_final_snapshot     = false
db_backup_retention_period = 7
bootstrap_db               = false
db_schema_file             = "../../db/ddl/all-tables.sql"
db_seed_file               = "../../db/seed/seed.sql"

# TLS
enable_https    = false
# certificate_arn = "arn:aws:acm:us-east-2:123456789:certificate/xxxxx"
