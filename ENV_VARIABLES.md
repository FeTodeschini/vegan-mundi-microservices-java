# Environment Variables Reference

This document lists all environment variables used by the Vegan Mundi Java platform.

## Service Configuration

### All Services
```bash
# Server
SERVER_PORT=8080
SERVER_SERVLET_CONTEXT_PATH=/

# Database
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/vegan_mundi_dev
SPRING_DATASOURCE_USERNAME=vegan_user
SPRING_DATASOURCE_PASSWORD=vegan_password
SPRING_DATASOURCE_DRIVER_CLASS_NAME=com.mysql.cj.jdbc.Driver

# Logging
LOGGING_LEVEL_ROOT=INFO
LOGGING_LEVEL_COM_VEGANMUNDI=DEBUG
LOGGING_FILE_NAME=logs/application.log

# Actuator
MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,metrics,prometheus
MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS=when-authorized
```

### JWT (Account Service)
```bash
# Token configuration
JWT_SECRET=your-super-secret-key-min-32-chars
JWT_EXPIRATION=86400000  # 24 hours in milliseconds
JWT_REFRESH_EXPIRATION=604800000  # 7 days
```

### AWS Services

#### Account Service (Secrets Manager)
```bash
AWS_REGION=us-east-2
AWS_SECRETS_MANAGER_SECRET_NAME=vegan-mundi/account-service
```

#### Order Service (EventBridge)
```bash
AWS_EVENTBRIDGE_RULE_NAME=vegan-mundi-order-created
AWS_SNS_TOPIC_ARN=arn:aws:sns:us-east-2:123456789:vegan-mundi-orders
```

#### Gallery Service (S3)
```bash
AWS_S3_BUCKET=vegan-mundi-assets
AWS_S3_REGION=us-east-2
AWS_S3_OBJECT_ACL=private
```

#### Lambda (Order Confirmation)
```bash
SENDER_EMAIL=orders@veganmundi.com
ANALYTICS_TABLE=vegan-mundi-order-analytics
AWS_LAMBDA_LOG_LEVEL=INFO
```

## Development Environment Setup

### Local Development
```bash
# Terminal 1: MySQL (native/local)
# Start the MySQL service using your OS service manager first

# Terminal 2: Build
mvn clean package -DskipTests

# Terminal 3: Account Service
export SERVER_PORT=8001
export JWT_SECRET=dev-secret-key-change-in-production
java -jar services/account-service/target/vegan-mundi-account-service-1.0.0-SNAPSHOT.jar

# Terminal 4: Class Service
export SERVER_PORT=8002
java -jar services/class-service/target/vegan-mundi-class-service-1.0.0-SNAPSHOT.jar

# Terminal 5: Order Service
export SERVER_PORT=8003
export AWS_EVENTBRIDGE_RULE_NAME=vegan-mundi-order-created-dev
java -jar services/order-service/target/vegan-mundi-order-service-1.0.0-SNAPSHOT.jar
```

## CI/CD Environment (Jenkins)

### Build Stage
```bash
# Maven settings
MAVEN_OPTS="-Xmx2g"
MAVEN_HOME=/opt/maven

# Build parameters
SKIP_TESTS=false
ENVIRONMENT=dev
```

### Docker Stage
```bash
# ECR credentials
AWS_REGION=us-east-2
AWS_ACCOUNT_ID=123456789
ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

### Terraform Stage
```bash
# Terraform environment
TF_INPUT=false
TF_IN_AUTOMATION=true
TF_LOG=INFO  # Change to TRACE for debugging
TF_LOG_PATH=terraform.log

# AWS credentials (via IAM role in production)
AWS_REGION=us-east-2
```

### Deployment Stage
```bash
# ECS deployment
ECS_CLUSTER=vegan-mundi-dev-cluster
ECS_REGION=us-east-2
IMAGE_TAG=${BUILD_NUMBER}
```

## Production Environment

### Security
```bash
# Use AWS Secrets Manager for these:
JWT_SECRET=<random-64-char-string>
DB_PASSWORD=<strong-password>
API_KEYS=<service-to-service-keys>

# Use HTTPS
SERVER_SSL_ENABLED=true
SERVER_SSL_KEY_STORE_TYPE=PKCS12
SERVER_SSL_KEY_STORE=/etc/ssl/cert.p12
SERVER_SSL_KEY_STORE_PASSWORD=${KEYSTORE_PASSWORD}
```

### Database
```bash
# Production RDS
SPRING_DATASOURCE_URL=jdbc:mysql://vegan-mundi-mysql-prod.xxxxx.us-east-2.rds.amazonaws.com:3306/vegan_mundi_prod
SPRING_DATASOURCE_USERNAME=admin
SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=20
SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE=5
```

### AWS Services
```bash
# Assume IAM role (no hardcoded credentials)
AWS_ROLE_ARN=arn:aws:iam::123456789:role/vegan-mundi-ecs-task-role
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token

# Event routing
AWS_EVENTBRIDGE_RULE_NAME=vegan-mundi-order-created-prod
AWS_SNS_TOPIC_ARN=arn:aws:sns:us-east-2:123456789:vegan-mundi-orders-prod

# S3 for assets
AWS_S3_BUCKET=vegan-mundi-assets-prod
```

### Monitoring
```bash
# CloudWatch
LOGGING_LEVEL_ROOT=WARN
LOGGING_PATTERN_CONSOLE=%d{ISO8601} - %msg%n
MANAGEMENT_METRICS_EXPORT_CLOUDWATCH_ENABLED=true
MANAGEMENT_METRICS_EXPORT_CLOUDWATCH_NAMESPACE=VeganMundi
```

## GitHub Actions (Optional Alternative to Jenkins)

```yaml
env:
  AWS_REGION: us-east-2
  ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
  MAVEN_VERSION: 3.9.1
  JAVA_VERSION: 17
```

## Setting Environment Variables

### Local (bash/zsh)
```bash
# In ~/.bashrc or ~/.zshrc
export JWT_SECRET="dev-secret-key"
export SPRING_DATASOURCE_URL="jdbc:mysql://localhost:3306/vegan_mundi_dev"
```

### Local (Windows PowerShell)
```powershell
$env:JWT_SECRET = "dev-secret-key"
$env:SPRING_DATASOURCE_URL = "jdbc:mysql://localhost:3306/vegan_mundi_dev"
```

### Docker Container
```dockerfile
ENV JWT_SECRET="dev-secret-key"
ENV SPRING_DATASOURCE_URL="jdbc:mysql://mysql:3306/vegan_mundi_dev"
```

### ECS Task Definition
```json
{
  "containerDefinitions": [
    {
      "environment": [
        {
          "name": "JWT_SECRET",
          "value": "..."
        },
        {
          "name": "SPRING_DATASOURCE_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-2:123456789:secret:vegan-mundi/db-password"
        }
      ]
    }
  ]
}
```

## Secrets Management (Production)

Use AWS Secrets Manager for sensitive values:

```bash
# Store secret
aws secretsmanager create-secret \
  --name vegan-mundi/account-service \
  --secret-string '{"jwt-secret":"...","api-key":"..."}'

# Retrieve in application
@Value("#{secretManagerClient.getSecretValue('vegan-mundi/account-service').getSecretString()}")
private String secretJson;
```

## Validation Checklist

Before deploying, verify:

- [ ] All required environment variables set
- [ ] No hardcoded secrets in code or config files
- [ ] Database connection working
- [ ] AWS credentials configured
- [ ] Docker registry accessible
- [ ] SSL certificates valid (production)
- [ ] Log levels appropriate for environment

---

**Last Updated**: June 2026
**Environment Scope**: Development, Staging, Production
