# Vegan Mundi - Java Microservices on AWS ECS

A complete migration of Vegan Mundi from Node.js to Java microservices, deployed on AWS ECS (EC2) with Terraform infrastructure-as-code, Jenkins CI/CD, and event-driven serverless components.

## Quick Overview

- **Architecture**: Microservices (Spring Boot) on ECS EC2 behind ALB
- **Infrastructure**: AWS (VPC, ALB, ECS, ECR, RDS/MySQL, Lambda, EventBridge)
- **IaC**: Terraform with modular structure
- **CI/CD**: Jenkins with automated testing and deployment
- **Database**: MySQL (EC2 hosted for dev cost control; RDS recommended for production)
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
└── .github/copilot/      # GitHub Copilot AI agents
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
- [docs/TERRAFORM_GUIDE.md](docs/TERRAFORM_GUIDE.md) - Provisioning infrastructure
- [docs/SERVICE_CONTRACTS.md](docs/SERVICE_CONTRACTS.md) - API contracts between services
- [docs/AWS_CLI_EXAMPLES.md](docs/AWS_CLI_EXAMPLES.md) - Operational AWS CLI commands
- [docs/INTERVIEW_TALKING_POINTS.md](docs/INTERVIEW_TALKING_POINTS.md) - Key narratives for interviews
- [.github/copilot/README.md](.github/copilot/README.md) - GitHub Copilot agents for DevOps

## 🤖 AI-Assisted DevOps (GitHub Copilot)

Custom Copilot agents for cost optimization and operational efficiency:

```bash
# Start EC2 infrastructure for demo
@copilot-ec2-start

# Stop EC2 infrastructure to save costs
@copilot-ec2-stop

# Check service health
@copilot-ec2-health-check

# Analyze CloudWatch logs for issues
@copilot-log-analyzer

# Review Terraform plan before apply
@copilot-terraform-plan-reviewer
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
| EC2 (2× t3.small) | ~$20 (scales to $0 when stopped) |
| ALB | ~$16 |
| NAT Gateway | ~$32 |
| S3 + DynamoDB (state) | ~$1 |
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

## 🔑 Interview Highlights

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

## 🤝 Contributing

For development guidelines, see [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)

## 📝 License

This project is for educational and interview portfolio purposes.

---

**Created**: June 2026  
**Status**: Phase 0 Complete - Ready for Phase 1 Implementation
