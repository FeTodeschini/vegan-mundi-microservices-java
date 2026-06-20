# Vegan Mundi - Java Microservices on AWS ECS
## 🕐 Vegan Mundi Cooking Classes Platform Evolution Timeline

**1-Initial version-React/Typescript + NodeJs on EC2 (2024):**
- Back-end in NodeJs hosted on an EC2 instance manually provisioned for learning purposes (NGNIX and all dependencies were manually configured)
- React/Typescript front-end also hosted on EC2 for the reason aforementioned
- This is the Front-End + NodeJs repo: [vegan-mundi](https://github.com/FeTodeschini/vegan-mundi)
- No AI used back then

**2-Second version-React/Typescript on Vercel + NodeJs on Render (2025):**
- NodeJs back-end migrated to Render for costs saving and simplicity
- Front-end migrated to Vercel, for the same reason
- AI (GitHub Copilot) used as an assistant and for troubleshooting (not in Agentic mode)

**3-Current version-React/Typescript + Java on AWS ECS (found in this repo, 2026):**
- Complete migration from Node.js to Java microservices deployed on AWS ECS backed by EC2 (no Fargate was used on purpose) with Terraform infrastructure-as-code, Jenkins CI/CD in Docker on dedicated EC2, and event-driven serverless components
- Front-end kept on Vercel
- It is possible to switch between the NodeJs and Java back-end with the /backend-switch prompt
- AI (GitHub Copilot) fully used on Agentic Mode, leveraging prompts for repetitive tasks

## Quick Overview

- **Architecture**: Microservices (Spring Boot) on ECS EC2 behind ALB
- **Infrastructure**: AWS (VPC, ALB, ECS, ECR, RDS/MySQL, Lambda, EventBridge)
- **IaC**: Terraform with modular structure
- **CI/CD**: Jenkins with automated testing and deployment running in a Docker container in dedicated EC2
- **Database**: Shared MySQL on AWS RDS (consumed by both Node and Java backends)
- **Auth**: Stateless JWT with signature validation
- **Features**: 7 microservices + 1 Lambda event processor

## 🚀 Quick Start

### Prerequisites
- Java 17+
- Maven 3.8+
- Docker & Docker Compose
- Terraform 1.0+
- AWS CLI v2
- AWS account with appropriate IAM permissions

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/vegan-mundi-microservices-java.git
cd vegan-mundi-microservices-java

# Set up local environment (see SETUP.md for detailed instructions)
./scripts/setup-local-env.sh

# Build all services
mvn clean package

# Run locally (start services against your local MySQL)
mvn clean package
```

## 📁 Project Structure

```
vegan-mundi-microservices-java/
├── services/              # 7 microservices + shared library
│   ├── account-service/
│   ├── class-service/
│   ├── order-service/
│   ├── review-service/
│   ├── delivery-service/
│   ├── gallery-service/
│   ├── price-service/
│   └── shared-library/
├── lambda/                # Serverless event handlers
├── terraform/             # Infrastructure as Code
│   ├── modules/          # Reusable Terraform modules
│   ├── dev/              # Legacy cloud dev config (local dev is preferred)
│   ├── test/             # Test environment config
│   └── prod/             # Production environment config
├── jenkins/              # CI/CD pipeline configuration
├── docker/               # Container configurations
├── docs/                 # Architecture & documentation
└── .github/prompts/      # GitHub Copilot slash prompts
```

## 🏗️ Architecture

### Service Decomposition

| Service | Responsibility |
|---------|---|
| **account-service** | User authentication, profiles, registration |
| **class-service** | Class catalog, filtering, search |
| **order-service** | Order creation, checkout, event publishing |
| **review-service** | Reviews, ratings, feedback |
| **delivery-service** | Delivery methods and shipping |
| **gallery-service** | Images, videos, S3 integration |
| **price-service** | Pricing rules, discounts, calculations |
| **Lambda (order-confirmation)** | Async order confirmation email + analytics |

### Technology Stack

| Component | Technology |
|-----------|---|
| **Language** | Java 17 |
| **Framework** | Spring Boot 3.1+ |
| **Database** | MySQL 8 |
| **Messaging** | EventBridge, SNS, SQS (optional) |
| **Orchestration** | AWS ECS on EC2 |
| **Ingress** | Application Load Balancer (ALB) |
| **Service Mesh** | ECS Service Connect |
| **Logging** | CloudWatch |
| **Deployment** | Terraform + Jenkins |

## 📚 Documentation

- [SETUP.md](SETUP.md) - Local development environment setup
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Detailed architecture and design
- [terraform/README.md](terraform/README.md) - Provisioning and targeted apply guide
- [docs/SERVICE_CONTRACTS.md](docs/SERVICE_CONTRACTS.md) - API contracts between services
- [docs/AWS_CLI_EXAMPLES.md](docs/AWS_CLI_EXAMPLES.md) - Operational AWS CLI commands
- [docs/INTERVIEW_TALKING_POINTS.md](docs/INTERVIEW_TALKING_POINTS.md) - Key narratives for interviews
- [.github/copilot/README.md](.github/copilot/README.md) - GitHub Copilot agents for DevOps

## 🤖 AI-Assisted DevOps (GitHub Copilot)

Custom Copilot prompts for cost optimization and operational efficiency:

```bash
# Start Jenkins EC2 (if stopped) and open an SSH tunnel for local DB Connection trough this EC2, as RDS is on a private subnet for security reasons and cannot be publicly acessed
@ssh-tunnel

# Guide humans on how to switch the back-end from NodeJs on Render to Java on AWS ECS (and vice-versa)
/backend-switch

# Toggle ASG state (enable/disable) with confirmation and verification
/auto-scaling-toggle

# Start EC2 infrastructure for demo
/ec2-start

# Stop EC2 infrastructure to save costs
/ec2-stop

# Check service health
/ec2-health-check

# Analyze CloudWatch logs for issues
/log-analyzer

# Review Terraform plan before apply
/terraform-plan-reviewer
```

See [.github/copilot/README.md](.github/copilot/README.md) for usage details.

## 🔄 CI/CD Pipeline (Jenkins)

Jenkins pipeline automates:
1. Build & test all services
2. Build and push Docker images to ECR
3. Terraform plan/apply for infrastructure
4. Deploy to ECS with health checks
5. Automated rollback on failure

Trigger: Commit to `main` or `dev` branch

## 💰 Cost Optimization

| Component | Monthly Cost (Dev) |
|-----------|---|
| EC2 (2× t3.micro) | ~$20 (scales to $0 when stopped) |
| ALB | ~$16 |
| NAT Gateway | ~$32 |
| S3 (state) | ~$1 |
| Lambda | ~$0 (free tier) |
| **Total** | **~$70/month** (or ~$50 when EC2 stopped) |

Use Copilot agents to automatically start/stop EC2 for ~90% savings during development.

## 🚢 Deployment

### Local Development
```bash
mvn clean package
docker-compose up
```

### AWS Test Environment
```bash
cd terraform/test
terraform init
terraform plan
terraform apply
```

### Jenkins Pipeline
```bash
# Commit triggers pipeline
git push origin main

# Or manually trigger through Jenkins UI
```

✅ **Microservices Architecture**: 7 independent services with clear separation of concerns  
✅ **Infrastructure as Code**: Terraform modules for repeatability and disaster recovery  
✅ **CI/CD Automation**: Jenkins pipeline with automated testing and deployment  
✅ **Serverless Integration**: Lambda for event-driven processing  
✅ **Cost Optimization**: Automated EC2 lifecycle management via Copilot agents  
✅ **Observability**: CloudWatch dashboards, logs, and alarms  
✅ **AI Adoption**: GitHub Copilot integration for DevOps automation  

## 📋 Implementation Phases

- **Phase 0** ✅ Setup & Foundation
- **Phase 1** Platform Baseline (ALB + first service)
- **Phase 2** Service Mesh Pattern (service discovery)
- **Phase 3** Core Microservices (all 7 services)
- **Phase 4** Lambda Event Processing
- **Phase 5** Jenkins CI/CD
- **Phase 6** Hardening & Production Readiness
- **Phase 7** AI Adoption & Copilot Agents