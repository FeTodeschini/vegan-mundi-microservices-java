# Test environment configuration
environment = "test"
aws_region  = "us-east-2"

# Networking
vpc_cidr            = "10.2.0.0/16"
availability_zones  = ["us-east-2a", "us-east-2b"]
enable_nat          = true

# Compute
instance_type    = "t3.micro"
desired_capacity = 2
min_capacity     = 1
max_capacity     = 3

# Database
db_username = "admin"
db_name                    = "vegan_mundi_test"
db_instance_class          = "db.t3.micro"
db_allocated_storage       = 20
db_publicly_accessible     = true
db_allowed_cidr_blocks     = ["76.98.179.193/32", "74.220.50.0/24", "74.220.58.0/24"]
db_skip_final_snapshot     = true
db_backup_retention_period = 1
bootstrap_db               = false
db_schema_file             = "../../db/ddl/all-tables.sql"
db_seed_file               = "../../db/seed/seed.sql"

# TLS
enable_https    = false
certificate_arn = ""