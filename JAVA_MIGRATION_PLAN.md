# Java Microservices Migration Plan: Vegan Mundi

## Executive Summary
Migrate Vegan Mundi from Node.js to Java microservices on AWS ECS (EC2), with ALB ingress, Terraform-first infrastructure, Jenkins CI/CD, and one Lambda feature. This is a cost-optimized learning/interview project with a clear path to production architecture.

---

## Architecture Decisions

### Data & Auth
- **Primary DB**: MySQL on RDS
- **Auth**: Stateless JWT with signature validation only
- **Event Bus**: EventBridge for domain events (optional; start without if scope is tight)

### Compute
- **Orchestration**: AWS ECS on EC2 (not Fargate)
- **Ingress**: Application Load Balancer (ALB) with path-based routing
- **Service Mesh**: Simple service discovery via ECS Service Connect (not App Mesh complexity)
- **Autoscaling**: ASG for capacity, ECS service autoscaling for load

### Deployment & IaC
- **Terraform**: All infrastructure as code (remote state in S3)
- **Jenkins**: CI/CD pipeline (build, test, deploy)
- **ECR**: Container registry for Java services
- **Environments**: dev is local. test and prod via Terraform workspaces or directories

### Lambda Feature
- **Trigger**: OrderCreated event (via EventBridge or simple SNS)
- **Function**: Send order confirmation email + write lightweight analytics record
- **Stack**: Java Spring Boot service publishes event → Lambda consumes → SES email
- **Interview Value**: Demonstrates hybrid container + serverless, event-driven patterns

### AWS CLI Opportunities
- Query ECS task health and logs
- Publish test events to EventBridge
- Trigger one-off ECS tasks for DB migrations
- Tail CloudWatch logs per service
- Validate ALB target group health

---

## Service Decomposition (Node.js → Java)

| Current Node.js Router | Java Service | Responsibility |
|---|---|---|
| `accountRouter.js` | account-service | User registration, login, profile, auth |
| `classRouter.js` | class-service | Class catalog, filtering, search |
| `orderRouter.js` | order-service | Order creation, status tracking, checkout |
| `reviewRouter.js` | review-service | Class reviews, ratings, user feedback |
| `deliveryMethodsRouter.js` | delivery-service | Delivery options, shipping methods |
| `galleryRouter.js` | gallery-service | Image/video assets, CDN routing |
| `priceRouter.js` | price-service | Pricing rules, discounts, cost calculations |
| `s3Controller.js` + `s3Router.js` | gallery-service | S3 integration for uploads |

**Service Communication**:
- Account Service: Validates user for all other services (via JWT)
- Order Service: Calls class-service, delivery-service, price-service synchronously
- Order Service: Publishes OrderCreated event (for Lambda confirmation)
- Review Service: Independent, calls class-service for context (optional)

---

## New Repository Structure (vegan-mundi-microservices-java)

### Folder Layout
```
vegan-mundi-microservices-java/
├── README.md                          # Project overview, architecture diagram, interview talking points
├── SETUP.md                           # Local dev setup, requirements, troubleshooting
│
├── terraform/                         # Infrastructure as Code
│   ├── backend.tf                     # S3 remote state
│   ├── variables.tf                   # Global variables (region, env, instance types)
│   ├── outputs.tf                     # Outputs (ALB DNS, ECR repos, RDS endpoint)
│   │
│   ├── modules/                       # Reusable Terraform modules
│   │   ├── vpc/                       # VPC, subnets, NAT, IGW
│   │   ├── alb/                       # ALB, target groups, listeners, security groups
│   │   ├── ecs/                       # ECS cluster, ASG, launch template, capacity provider
│   │   ├── ecr/                       # ECR repositories per service
│   │   ├── rds/                       # RDS MySQL instance, security group
│   │   ├── iam/                       # IAM roles, task execution role, Jenkins role
│   │   ├── cloudwatch/                # Log groups, alarms, dashboards
│   │   ├── eventbridge/               # EventBridge rule, SNS topic for events
│   │   └── lambda/                    # Lambda function and IAM role
│   │
│   ├── dev/                           # Dev environment
│   │   ├── main.tf                    # Module instantiation for dev
│   │   ├── terraform.tfvars           # Dev-specific values
│   │   └── .gitignore                 # Exclude state files
│   │
│   └── prod/                          # Prod environment (future)
│       ├── main.tf
│       ├── terraform.tfvars
│       └── .gitignore
│
├── services/                          # Java microservices
│   ├── account-service/               # User authentication, profiles
│   │   ├── src/
│   │   │   ├── main/java/com/veganmundi/account/
│   │   │   │   ├── AccountApplication.java
│   │   │   │   ├── config/
│   │   │   │   ├── controller/
│   │   │   │   ├── service/
│   │   │   │   ├── repository/
│   │   │   │   ├── model/
│   │   │   │   ├── exception/
│   │   │   │   └── security/
│   │   │   └── test/
│   │   ├── pom.xml
│   │   └── Dockerfile
│   │
│   ├── class-service/                 # Classes, filtering, search
│   │   └── [same structure as account-service]
│   │
│   ├── order-service/                 # Orders, checkout, events
│   │   └── [same structure, includes EventBridge publishing]
│   │
│   ├── review-service/                # Reviews, ratings
│   │   └── [same structure]
│   │
│   ├── delivery-service/              # Delivery methods, shipping
│   │   └── [same structure]
│   │
│   ├── gallery-service/               # Images, S3 integration
│   │   └── [same structure]
│   │
│   ├── price-service/                 # Pricing, discounts
│   │   └── [same structure]
│   │
│   └── shared-library/                # Common code
│       ├── src/main/java/com/veganmundi/common/
│       │   ├── dto/                   # Shared DTOs
│       │   ├── exception/             # Common exceptions
│       │   ├── util/                  # Helper utilities
│       │   ├── security/              # JWT validation shared
│       │   └── client/                # Service-to-service HTTP client
│       ├── pom.xml
│       └── README.md
│
├── lambda/                            # Serverless event handlers
│   └── order-confirmation/            # Lambda for OrderCreated event
│       ├── src/
│       │   ├── main/java/com/veganmundi/lambda/
│       │   │   └── OrderConfirmationHandler.java
│       │   └── test/
│       ├── pom.xml
│       └── Dockerfile                 # Container image for Lambda
│
├── jenkins/                           # CI/CD pipeline
│   ├── Dockerfile                     # Jenkins image with Java, Maven, Terraform, AWS CLI
│   ├── Jenkinsfile                    # Multi-branch pipeline definition
│   ├── scripts/
│   │   ├── build.sh                   # Maven build + Docker push
│   │   ├── deploy.sh                  # Terraform apply + ECS update
│   │   ├── test.sh                    # Unit + integration tests
│   │   ├── smoke-test.sh              # Post-deploy health checks (ALB endpoint)
│   │   └── rollback.sh                # ECS rollback to previous task definition
│   └── docker-compose.yml             # Local Jenkins setup
│
├── docker/                            # Container configs
│   └── service-images/                # Service Dockerfiles (under each service folder)
│
├── docs/                              # Documentation & architecture
│   ├── ARCHITECTURE.md                # Detailed architecture diagrams & flow
│   ├── AWS_CLI_EXAMPLES.md            # AWS CLI commands for operational tasks
│   ├── TERRAFORM_GUIDE.md             # How to provision, plan, apply
│   ├── SERVICE_CONTRACTS.md           # API contracts between services
│   ├── DEPLOYMENT_RUNBOOK.md          # Manual deployment steps
│   ├── TROUBLESHOOTING.md             # Common issues & fixes
│   ├── INTERVIEW_TALKING_POINTS.md    # Key narrative for interviewers
│   └── diagrams/                      # Architecture diagrams (PNG/SVG)
│
├── .gitignore                         # Exclude secrets, state files, builds
├── .github/                           # GitHub configuration
│   ├── workflows/                     # GitHub Actions (optional alternative to Jenkins)
│   │   └── deploy.yml
│   │
│   └── copilot/                       # GitHub Copilot custom agents & prompts
│       ├── README.md                  # Index and quick-start guide for all agents
│       ├── ec2-start.md               # Agent: Start EC2 ASG for demo environment
│       ├── ec2-stop.md                # Agent: Stop EC2 ASG to minimize costs
│       ├── ec2-health-check.md        # Agent: Verify all services are healthy
│       ├── log-analyzer.md            # Agent: Triage issues from CloudWatch logs
│       └── terraform-plan-reviewer.md # Agent: Review infrastructure changes before apply
│
└── pom.xml (parent)                   # (Optional) Multi-module Maven root


### Key Files at Root
- **README.md**: Project overview, quick start, architecture summary
- **SETUP.md**: Prerequisites (Java 17, Maven, Terraform, AWS CLI), local dev environment
- **Makefile** (optional): Shortcuts for common commands (terraform, docker, deploy)
```

---

## Terraform Module Details

Each module should be independently reusable and well-documented:

### VPC Module
- 2 AZs, public + private subnets, NAT Gateway, IGW
- Security groups for ALB, ECS, RDS
- Outputs: subnet IDs, security group IDs

### ALB Module
- Target group per Java service (account, class, order, etc.)
- Path-based routing: `/api/account/*` → account-service, `/api/classes/*` → class-service
- HTTPS listener (self-signed cert for dev, ACM for prod)
- Health check per target group

### ECS Module
- ECS cluster with EC2 launch type
- Auto Scaling Group (t3.micro instances by default; scale up later if needed)
- Capacity provider linking ASG to ECS
- Outputs: cluster name, capacity provider name

### ECR Module
- Repositories for each service + shared-library
- Lifecycle rules to clean old images
- Outputs: repository URLs

### IAM Module
- ECS task execution role (ECR pull, CloudWatch logs, secrets)
- ECS task role (S3, EventBridge, SES for Lambda)
- Jenkins EC2 instance role (ECR push, Terraform backend access, ECS describe/update)

### Lambda Module
- Lambda function for order confirmation
- IAM role (SES send, CloudWatch logs)
- EventBridge rule routing OrderCreated → Lambda
- Dead-letter queue for failed invocations

---

## Phase-by-Phase Implementation Plan

### Phase 0: Setup & Foundation (1 week)
**Goals**: Environment ready, decisions locked in, skeleton code.

- [ ] Create new `vegan-mundi-microservices-java` GitHub repo
- [ ] Set up local dev environment (Java 17, Maven, Docker, Terraform, AWS CLI)
- [ ] Define API contracts (OpenAPI/Swagger) for each service
- [ ] Scaffold Maven project structure (parent + modules)
- [ ] Set up shared-library with JWT validation, common exceptions, DTOs
- [ ] AWS account + IAM user with Terraform permissions
- [ ] Initialize Terraform backend (S3)
- [ ] Create `.github/copilot/` directory with custom instruction files (Phase 7, can defer)

**Deliverable**: Buildable empty services, Terraform backend ready, team can clone and run locally.

---

### Phase 1: Platform Baseline (1-2 weeks)
**Goals**: AWS infrastructure running, one service deployed, ALB working.

- [ ] Implement Terraform modules (VPC, ALB, ECS, ECR, IAM)
- [ ] Provision dev environment: `terraform apply`
- [ ] Implement account-service in Spring Boot (login, register endpoints only)
- [ ] Build Docker image, push to ECR
- [ ] Create ECS task definition + service
- [ ] Route `/api/account/*` through ALB
- [ ] Set up CloudWatch logs + basic alarms
- [ ] Manual deployment walkthrough (no Jenkins yet)

**Deliverable**: ALB → account-service working end-to-end, logs visible in CloudWatch.

---

### Phase 2: Service Mesh Pattern (1 week)
**Goals**: Services discover each other reliably, demonstrate resilience.

- [ ] Implement ECS Service Connect for inter-service discovery
- [ ] Add simple HTTP client to shared-library for service-to-service calls
- [ ] Deploy class-service, price-service (no business logic yet, just stubs)
- [ ] Account-service calls class-service to get class details
- [ ] Add retry logic and basic circuit breaker pattern
- [ ] Showcase in CloudWatch: trace calls between services
- [ ] AWS CLI demo: query service health, running tasks

**Deliverable**: Services calling each other reliably, AWS CLI operational commands demonstrated.

---

### Phase 3: Core Microservices (2-4 weeks)
**Goals**: All services deployed, core workflows working, strangler pattern in place.

- [ ] Implement all 7 Java services with full business logic
- [ ] Use strangler pattern: ALB routes old Node.js paths to legacy, new paths to Java services
- [ ] Database: MySQL connection pooling, schema migrations via Flyway/Liquibase
- [ ] Service-to-service communication patterns established
- [ ] Integration tests per service
- [ ] Load testing against ALB to understand baseline

**Deliverable**: Core workflows (search, add to cart, checkout) working in Java with MySQL.

---

### Phase 4: Lambda Event Processing (1 week)
**Goals**: Lambda integrated, event-driven pattern demonstrated, interview story complete.

- [ ] Order-service publishes OrderCreated event to EventBridge
- [ ] Implement order-confirmation Lambda (Java + Spring Cloud Function)
- [ ] Lambda sends confirmation email via SES
- [ ] EventBridge rule with retry policy and DLQ
- [ ] Manual test: `aws events put-events` to trigger Lambda
- [ ] CloudWatch alarms for Lambda errors

**Deliverable**: End-to-end event flow working; interview demo: "Here's a serverless function triggered by a microservice event."

---

### Phase 5: Jenkins CI/CD (1 week)
**Goals**: Fully automated pipeline, from commit to production ready.

- [ ] Jenkins Dockerfile: Java, Maven, Terraform, AWS CLI, Docker CLI
- [ ] Jenkinsfile: stages for build, test, push, plan, apply, deploy, smoke test
- [ ] Git webhook to trigger on commit
- [ ] Automated tests run before deploy
- [ ] Terraform plan stage (human review point)
- [ ] Blue/green or canary deployment strategy (ECS rolling update)
- [ ] Automated rollback on health check failure
- [ ] Pipeline dashboard visible, build history logged

**Deliverable**: Commit code → Jenkins automatically builds, tests, deploys to ECS, validates health.

---

### Phase 6: Hardening & Interview Readiness (1 week)
**Goals**: Production-grade security, observability, documentation, narrative.

- [ ] Security groups: least privilege, ALB → ECS only, ECS → RDS only
- [ ] Secrets management: RDS password, SES API key in AWS Secrets Manager (Terraform provisioned)
- [ ] CloudWatch dashboards: service latency, error rates, ALB target health
- [ ] Centralized logging aggregation (optional: CloudWatch Insights)
- [ ] Load test and chaos engineering: terminate tasks, observe recovery
- [ ] Write ARCHITECTURE.md, INTERVIEW_TALKING_POINTS.md
- [ ] Create architecture diagram (tools: Lucidchart, draw.io, or Mermaid)
- [ ] Prepare AWS CLI demo script: 5 key operational commands
- [ ] Document cost breakdown (EC2 instances, NAT, RDS if applicable, Lambda)

**Deliverable**: Production-ready system, compelling interview narrative, demo scripts ready.

---

## Phase 7: AI Adoption & Copilot Agents (1 week, integrated into Phase 6)
**Goals**: Showcase GitHub Copilot integration for DevOps, cost optimization, and operational efficiency.

- [ ] Create `.github/copilot/` directory with custom instruction files
- [ ] Implement EC2 start/stop agents (cost control, lifecycle management)
- [ ] Implement log analyzer agent (triage and issue detection)
- [ ] Implement Terraform plan reviewer agent (infrastructure safety)
- [ ] Write `.github/copilot/README.md` with usage guide
- [ ] Document AI adoption narrative for interviews
- [ ] Create demo script: show agents in action (start EC2 → check health → stop EC2)

**Deliverable**: Working Copilot agents in repo, demo video/script, AI adoption talking points.

---

---

## GitHub Copilot Agents for DevOps & Cost Optimization

### Overview
Custom GitHub Copilot instruction files in `.github/copilot/` provide templated workflows for common DevOps tasks. This showcases AI integration across the engineering lifecycle beyond just code generation.

### Cost Control via EC2 Lifecycle
Since the project uses EC2 instances, cost optimization is critical:
- Running 2× t3.micro 24/7: ~$20/month
- Scale to 0 when not demoing: save ~$18/month
- **Interview talking point**: "I automated infrastructure cost control with AI-assisted DevOps prompts"

### Copilot Agents to Implement

#### 1. **EC2 Start Agent** (`ec2-start.md`)
**Purpose**: Scale up ECS ASG to run microservices  
**Use Case**: Before demoing the app  
**Workflow**:
- User asks Copilot: "Start the demo environment"
- Agent provides AWS CLI command with parameters pre-filled
- Monitors instance startup and confirms readiness
- Provides next command to check ALB health

**Key Command**:
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name vegan-mundi-dev-ecs-asg \
  --desired-capacity 2 \
  --region us-east-2
```

**Interview Value**: Reduces manual errors, consistent deployments, cost-aware automation

---

#### 2. **EC2 Stop Agent** (`ec2-stop.md`)
**Purpose**: Scale down ECS ASG to 0 to minimize costs  
**Use Case**: After demo session ends  
**Workflow**:
- User asks: "Stop the demo environment"
- Agent gracefully drains tasks, then scales to 0
- Confirms shutdown and calculates daily/monthly savings
- Provides resume command for next session

**Key Command**:
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name vegan-mundi-dev-ecs-asg \
  --desired-capacity 0 \
  --region us-east-2
```

**Interview Value**: Demonstrates financial responsibility and infrastructure automation maturity

---

#### 3. **EC2 Health Check Agent** (`ec2-health-check.md`)
**Purpose**: Query infrastructure and service health  
**Use Case**: Verify all services are running after startup  
**Workflow**:
- User asks: "Is everything healthy?"
- Agent runs multiple checks in parallel:
  - ECS tasks running count per service
  - ALB target group health (healthy/unhealthy targets)
  - CloudWatch alarms (critical/warning states)
- Summarizes: "All systems operational" or lists issues

**Key Commands**:
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn <arn> --region us-east-2

# List running tasks
aws ecs list-tasks --cluster dev-ecs-cluster --region us-east-2

# Check alarms
aws cloudwatch describe-alarms --state-values ALARM --region us-east-2
```

**Interview Value**: Demonstrates observability maturity and operational discipline

---

#### 4. **Log Analyzer Agent** (`log-analyzer.md`)
**Purpose**: Triage production issues from CloudWatch logs  
**Use Case**: Debugging service failures or anomalies  
**Workflow**:
- User asks: "Why is order-service failing?"
- Agent queries CloudWatch Logs for the service
- Filters for ERROR and WARN levels in past hour
- Summarizes:
  - Error frequency and types
  - Affected instances/tasks
  - Suggested remediation steps

**Key Commands**:
```bash
# Fetch error logs
aws logs filter-log-events \
  --log-group-name /ecs/order-service \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region us-east-2

# Tail live logs
aws logs tail /ecs/order-service --follow
```

**Interview Value**: Shows understanding of observability, faster MTTR (mean time to resolution), AI as operational assistant

---

#### 5. **Terraform Plan Reviewer Agent** (`terraform-plan-reviewer.md`)
**Purpose**: Translate Terraform plans to plain English before apply  
**Use Case**: Ensure infrastructure changes are intentional and safe  
**Workflow**:
- User runs: `terraform plan -out=plan.tfplan`
- User asks Copilot: "What changes will this make?"
- Agent parses plan.tfplan and summarizes:
  - Resources created/destroyed/modified
  - Security implications (e.g., security group rules opened/closed)
  - Cost impact estimation
  - Approval gate: "Proceed with terraform apply? (yes/no)"

**Interview Value**: Demonstrates governance, safety culture, and infrastructure-as-code maturity

---

### Folder Structure for `.github/copilot/`

```
vegan-mundi-microservices-java/
├── .github/
│   ├── workflows/          # GitHub Actions (optional, alternative to Jenkins)
│   │   └── deploy.yml
│   │
│   └── copilot/            # GitHub Copilot custom agents & prompts
│       ├── README.md                  # Index and quick-start guide
│       ├── ec2-start.md               # Start EC2 ASG for demo
│       ├── ec2-stop.md                # Stop EC2 ASG to save costs
│       ├── ec2-health-check.md        # Verify all services healthy
│       ├── log-analyzer.md            # Triage issues from CloudWatch
│       └── terraform-plan-reviewer.md # Review infrastructure changes
```

### `.github/copilot/README.md` Contents

Should include:
- Quick reference for all agents
- Example prompts for each agent
- Prerequisites (AWS CLI configured, credentials available)
- Cost savings summary
- Interview talking points

---

### Other AI Adoption Opportunities (Future)

If you want to expand beyond Phase 7:

| Agent | Purpose | Interview Story |
|---|---|---|
| **API Contract Generator** | Auto-generate OpenAPI specs from Java annotations | "Automated API documentation stays in sync with code" |
| **Test Generator** | Scaffold unit + integration test templates | "AI-assisted TDD: write test outlines, focus on assertions" |
| **Service Boilerplate** | Generate Java service layers (controller/service/repo) | "10x faster microservice scaffolding using AI" |
| **Performance Profiler** | Interpret JVM metrics and suggest bottlenecks | "AI helps translate performance data into actionable insights" |
| **Docker Optimizer** | Suggest image size reductions and layer consolidation | "Reduce container size by 30% with AI guidance" |
| **Documentation Generator** | Auto-generate ARCHITECTURE.md from code + comments | "Living documentation that stays in sync with implementation" |

---

### Interview Narrative: AI Adoption Strategy

> "I integrated GitHub Copilot as a strategic tool across the engineering lifecycle:
>
> **Cost Optimization**: Custom agents automate EC2 lifecycle management (start/stop). This reduces monthly costs from $20 to ~$2 when the demo isn't running—a 90% savings during development.
>
> **Operational Efficiency**: Log analyzer and health check agents reduce manual toil and mean-time-to-resolution. Instead of copy-pasting AWS CLI commands, I describe what I need in natural language, and Copilot provides the exact command with context.
>
> **Safety & Governance**: Terraform plan reviewer agent ensures infrastructure changes are reviewed before apply, preventing accidental deletions or security misconfigurations.
>
> **Faster Development**: Service boilerplate and test generation agents let me scaffold microservices in minutes, focusing my effort on business logic and architectural decisions.
>
> This demonstrates I view AI as a productivity multiplier across the entire engineering lifecycle—not just for coding, but for DevOps, cost management, and team safety."

---

## Jenkins Pipeline Design (High Level)

```
Trigger: Git commit to main/dev branch

Stage 1: Checkout & Build
  - Clone repo
  - Maven clean package (all services)
  - Unit tests
  - Code quality checks (SonarQube optional)

Stage 2: Build & Push Images
  - Docker build each service
  - Push to ECR

Stage 3: Terraform Plan
  - Terraform init
  - Terraform plan (dev workspace)
  - Show plan in build log (human review)

Stage 4: Terraform Apply (Approval Gate)
  - Manual approval
  - Terraform apply
  - Extract outputs (ALB DNS, ECS cluster name, etc.)

Stage 5: Deploy to ECS
  - Generate new ECS task definition from latest images
  - Update ECS service (rolling deployment)
  - Monitor deployment health

Stage 6: Smoke Tests
  - Hit ALB health endpoint
  - Query service endpoints via AWS CLI
  - Validate key workflows (login, search, order)

Stage 7: Rollback (on failure)
  - Revert to previous task definition
  - Alert team
```

---

## AWS CLI Showcase Commands

```bash
# 1. Query ECS task health
aws ecs list-tasks --cluster dev-ecs-cluster --service-name account-service
aws ecs describe-tasks --cluster dev-ecs-cluster --tasks <task-arn>

# 2. Tail CloudWatch logs
aws logs tail /ecs/account-service --follow

# 3. Publish test event to EventBridge
aws events put-events --entries '[{
  "Source": "vegan-mundi.order-service",
  "DetailType": "OrderCreated",
  "Detail": "{\"orderId\": \"123\", \"userId\": \"user-1\"}"
}]'

# 4. Check ALB target health
aws elbv2 describe-target-health --target-group-arn <arn>

# 5. Run one-off ECS task (DB migration)
aws ecs run-task --cluster dev-ecs-cluster --task-definition migration-task --launch-type EC2
```

---

## Interview Talking Points

### "Why Java over Node.js?"
- Stronger typing, compiler catches errors early
- Spring Boot ecosystem mature for enterprise patterns
- Thread-based concurrency vs async/callbacks complexity
- Interview prep, shows full-stack flexibility

### "Why ECS EC2 instead of Fargate?"
- Cost control: use existing instances efficiently
- Shows operational understanding of infrastructure
- Demonstrates comfort with container orchestration concepts
- Production-ready; ECS EC2 is still widely used (Fargate is not always cheaper)

### "How do services communicate?"
- ECS Service Connect for service discovery (no shared credentials needed)
- Resilience patterns: retries, timeouts, circuit breaker in shared library
- Demonstrates understanding of distributed systems

### "Tell me about the Lambda feature."
- OrderCreated event triggers Lambda via EventBridge
- Asynchronous email confirmation, decoupled from order service
- Shows hybrid container + serverless architecture
- Demonstrates event-driven patterns

### "How did you handle the database?"
- MySQL on EC2 for this practice environment (cost optimization)
- Designed Terraform so migration to RDS is a one-module-change
- Connection pooling, migrations via Flyway
- Shows pragmatic tradeoff thinking

### "Why Terraform?"
- Infrastructure as code, repeatable and version-controlled
- Team collaboration: plan before apply
- Disaster recovery: re-provision entire environment from code
- IaC best practice in industry

### "How is your CI/CD automated?"
- Jenkins pipeline: commit triggers build, test, deploy
- Terraform plan as approval gate (human review infrastructure changes)
- Automated smoke tests post-deploy
- Rollback on health check failure

### "What would you do differently for production?"
- RDS instead of MySQL on EC2 (managed backups, HA)
- Multi-AZ RDS setup with read replicas
- VPN or private endpoint for Jenkins
- Separate dev/staging/prod Terraform environments
- CloudFront CDN in front of ALB
- WAF on ALB for DDoS/attack mitigation
- Secrets Manager instead of env vars
- Cost monitoring + budget alerts

---

## Cost Optimization Notes

| Component | Dev Cost | Production Note |
|---|---|---|
| EC2 (2× t3.micro) | ~$20/month | Scale up instance size only when workload proves it is needed; reserved instances save 40% |
| RDS MySQL (when added) | $30/month (single AZ) | Multi-AZ ~$60/month |
| ALB | ~$16/month | Always needed; cost per GB processed |
| NAT Gateway | ~$32/month | Only if private subnets access internet |
| S3 (state + images) | ~$1/month | Negligible for small projects |
| Lambda (order-confirmation) | ~$0.20/month | 1M requests free tier; rarely exceeded |
| **Total Dev** | **~$100/month** | — |

---

## Decision Log

| Decision | Choice | Rationale |
|---|---|---|
| Database | MySQL EC2, not RDS | Cost; can migrate to RDS with Terraform change |
| Auth | Stateless JWT | Scalable; no token revocation needed for MVP |
| Orchestration | ECS EC2 | Shows operational understanding; cost-efficient |
| IaC | Terraform | Industry standard; works with Jenkins; repeatable |
| CI/CD | Jenkins | Integrates with Terraform; good for learning DevOps |
| Lambda Feature | Order confirmation | Demonstrates serverless + event-driven patterns |
| Repo Strategy | New repo | Cleaner interview story; separate lifecycle from legacy Node |
| AI Adoption | GitHub Copilot agents | Cost optimization + operational efficiency showcases |

---

## Success Criteria

✅ **Code Complete**
- All 7 Java services deployed and healthy
- ALB routing traffic correctly
- ECS autoscaling functional

✅ **Infrastructure Complete**
- Terraform code in Git, tested against dev + prod
- Remote state + locking configured
- AWS CLI operational commands documented

✅ **Automation Complete**
- Jenkins pipeline triggers on commit
- Automated tests run before deploy
- Smoke tests pass post-deployment

✅ **Interview Ready**
- Architecture diagram + talking points documented
- AWS CLI demo script recorded/scripted
- Lambda feature explained clearly
- Cost breakdown understood
- GitHub Copilot agents working and documented
- AI adoption narrative prepared and rehearsed

---

## Next Steps

1. **Create the new repo** on GitHub: `vegan-mundi-microservices-java`
2. **Clone and set up** local environment per SETUP.md
3. **Start Phase 0**: Scaffold Maven, define API contracts, initialize Terraform backend
4. Once plan review is complete, begin Phase 1 implementation

---

**Document Version**: 1.0  
**Last Updated**: June 2026  
**Status**: Plan (Ready for Implementation)
