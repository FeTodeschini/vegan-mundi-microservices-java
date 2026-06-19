# Architecture & Design Documentation

## System Overview

Vegan Mundi Java is a microservices-based platform migrated from Node.js to Java on AWS ECS EC2. The system consists of 7 independent microservices communicating through RESTful APIs, with event-driven async processing via Lambda.

This document describes the target architecture and the repository structure that currently supports it. Where the implementation is still scaffold-level, that is called out explicitly so the document remains accurate to the codebase.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Internet Users                               │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                ┌───────────▼──────────────┐
                │  External DNS Provider   │
                │  (GoDaddy)               │
                └───────────┬──────────────┘
                            │
         ┌──────────────────▼──────────────────────┐
         │  Application Load Balancer (ALB)        │
         │  - Port 80 (HTTP)                       │
         │  - Port 443 (HTTPS, optional)           │
         │  - Path-based routing                   │
         └──────────────────┬──────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   ┌────▼─────────┐  ┌────▼─────────┐  ┌────▼─────────┐
   │ Account Svc  │  │ Class Svc    │  │ Order Svc    │
   │ :8001        │  │ :8002        │  │ :8003        │
   └────┬─────────┘  └────┬─────────┘  └────┬─────────┘
        │                 │                  │ (publishes
        │                 │            OrderCreated event)
        └─────────────────┼──────────────────┘
                          │
         ECS Service Connect (service discovery)
                          │
        ┌─────────────────┼──────────────────┐
        │                 │                  │
   ┌────▼─────────┐  ┌────▼─────────┐  ┌────▼─────────┐
   │ Review Svc   │  │ Delivery Svc │  │ Gallery Svc  │
   │ :8004        │  │ :8005        │  │ :8006        │
   └────┬─────────┘  └────┬─────────┘  └────┬─────────┘
        │                 │                  │
        └─────────────────┼──────────────────┘
                          │
                    ┌─────▼──────────┐
                    │ Price Service  │
                    │ :8007          │
                    └────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                        Data Layer                                 │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────┐           ┌─────────────────────┐     │
│  │  MySQL (AWS RDS)     │           │  EventBridge        │     │
│  │  - Accounts          │           │  - OrderCreated     │     │
│  │  - Classes           │           │  - Events routing   │     │
│  │  - Orders            │           │                     │     │
│  │  - Reviews           │           └──────────┬──────────┘     │
│  │  - Gallery           │                      │                │
│  │  - Pricing           │                 ┌────▼──────────┐     │
│  │                      │                 │   Lambda      │     │
│  └──────────────────────┘                 │   Order Conf  │     │
│                                           │   Email + SES │     │
│                                           └──────────────┘      │
└──────────────────────────────────────────────────────────────────┘
```

Current repo note:
- The service decomposition, Terraform layout, and Jenkins pipeline are present in the repository.
- Several business endpoints are still stubbed, so this diagram should be read as the intended steady-state architecture rather than a claim that every service path is fully implemented today.

## Technology Stack

### Application Tier
- **Framework**: Spring Boot 3.1
- **Language**: Java 17
- **API Format**: REST + OpenAPI/Swagger
- **Communication**: HTTP/HTTPS between services
- **Service Mesh**: ECS Service Connect (built-in, simpler than App Mesh)

### Orchestration & Infrastructure
- **Container Orchestration**: AWS ECS (EC2 launch type)
- **Load Balancing**: Application Load Balancer (ALB)
- **DNS**: External DNS provider points domain or subdomain records to the ALB DNS name
- **Container Registry**: ECR (Elastic Container Registry)
- **Compute**: EC2 instances default to t3.micro in the current Terraform configuration
- **Scaling Strategy**: ASG-based capacity, ECS service-level autoscaling

### Data & Events
- **Primary Database**: MySQL 8.0
- **Schema Versioning**: Flyway migrations
- **Async Events**: EventBridge
- **Lambda Processing**: Order confirmation async handler

### Observability
- **Logging**: CloudWatch Logs (centralized)
- **Monitoring**: CloudWatch Metrics + Alarms
- **Tracing**: X-Ray (optional in future phases)
- **Dashboards**: CloudWatch dashboards per service

### Infrastructure as Code
- **IaC Tool**: Terraform
- **State Management**: S3 backend for remote state
- **Environment Separation**: dev/, test/, prod/, and jenkins/ directories

### CI/CD
- **Pipeline**: Jenkins with Jenkinsfile
- **Container Build**: Docker build → ECR push
- **Deployment**: ECS rolling updates
- **Testing**: Maven unit/integration tests
- **Runtime Assets**: Jenkins Docker image, docker-compose setup, JCasC baseline, and helper scripts live under `jenkins/`

## Implementation Status Snapshot

- **Implemented in repo today**: parent Maven build, seven service modules, shared library, Lambda module, Terraform module layout, environment folders, Jenkins pipeline assets, and baseline docs.
- **Partially implemented**: concrete controllers are present for account-service, class-service, and order-service; non-health behavior is still largely stubbed.
- **Planned by architecture**: full cross-service orchestration, hardened security, validated autoscaling behavior, and end-to-end production deployment workflows.

---

## Service Responsibilities

These responsibilities describe the intended ownership boundaries for each service. They should be read as architecture targets, not proof that each workflow is already implemented.

### Account Service (Port 8001)
- **Endpoints**: POST /api/account/register, POST /api/account/login, GET /api/account/profile
- **Dependencies**: MySQL
- **Responsibilities**: User authentication, JWT token generation, profile management
- **Scaling**: Replicas = 2 (default), scales based on CPU/memory

### Class Service (Port 8002)
- **Endpoints**: GET /api/classes, GET /api/classes/{id}, GET /api/classes?category={category}
- **Dependencies**: MySQL, Account Service (for auth checks)
- **Responsibilities**: Class catalog, filtering, search indexing
- **Scaling**: Replicas = 2, scales on request count

### Order Service (Port 8003)
- **Endpoints**: POST /api/orders, GET /api/orders/{id}, PUT /api/orders/{id}/status
- **Dependencies**: MySQL, Class Service, Price Service, Delivery Service
- **Responsibilities**: Order creation, checkout workflow, event publishing
- **Events**: Publishes OrderCreated → EventBridge → Lambda
- **Scaling**: Replicas = 2, scales on CPU/memory

### Review Service (Port 8004)
- **Endpoints**: POST /api/reviews, GET /api/classes/{id}/reviews, GET /api/reviews/star-rating
- **Dependencies**: MySQL, Class Service (for context)
- **Responsibilities**: Class reviews, user ratings, feedback
- **Scaling**: Replicas = 2

### Delivery Service (Port 8005)
- **Endpoints**: GET /api/delivery-methods, POST /api/shipments, GET /api/shipments/{id}
- **Dependencies**: MySQL
- **Responsibilities**: Delivery options, shipping info, cost calculation
- **Scaling**: Replicas = 2

### Gallery Service (Port 8006)
- **Endpoints**: GET /api/gallery, POST /api/gallery/upload, DELETE /api/gallery/{id}
- **Dependencies**: MySQL, S3 (for images/videos)
- **Responsibilities**: Media asset management, S3 integration
- **Scaling**: Replicas = 2

### Price Service (Port 8007)
- **Endpoints**: GET /api/prices/{class-id}, POST /api/discounts, GET /api/cost-estimate
- **Dependencies**: MySQL
- **Responsibilities**: Pricing rules, discount logic, cost calculations
- **Scaling**: Replicas = 2

### Lambda: Order Confirmation
- **Trigger**: OrderCreated event from EventBridge
- **Handler**: OrderConfirmationHandler.java
- **Actions**: Send confirmation email via SES
- **Timeout**: 30 seconds
- **Memory**: 256 MB
- **Concurrency**: Unreserved (auto-scale)

---

## Communication Patterns

### Synchronous (Within Request)
```
Client → ALB → Account Service → Class Service → MySQL → Response
         (via ECS Service Connect for service-to-service)
```

### Asynchronous (Event-Driven)
```
Order Service → EventBridge (OrderCreated event)
             → Lambda (order-confirmation)
             → SES (email)
```

### Service Mesh (ECS Service Connect)
- Automatic service discovery (no manual registration needed)
- Built-in load balancing across service instances
- Retries and timeouts at transport layer
- CloudMap for service registry

---

## Data Flow Example: Place Order

1. **User Action**: Click "Place Order"
2. **ALB Routes**: Request → Order Service (:8003)
3. **Order Service**:
   - Validates JWT token (Account Service context)
   - Calls Class Service to validate class exists
   - Calls Price Service to calculate total
   - Calls Delivery Service for shipping cost
   - Persists order in MySQL
   - Publishes `OrderCreated` event to EventBridge
4. **EventBridge**: Routes to Lambda
5. **Lambda** (async):
   - Sends confirmation email via SES
6. **Response**: Order ID + status returned to client

**Key Design**: Steps 1-4 are synchronous (fast, < 1 sec). Step 5 is asynchronous (fire-and-forget), so delays in email don't block user.

---

## Deployment Topology

The values in this section are planning assumptions for environment sizing. They are useful for architecture discussion, but they are not a substitute for validating the actual Terraform outputs and deployed capacity in AWS.

### Dev Environment
- **Cluster**: 1 ASG with 2 × t3.micro EC2 instances by default
- **Services**: All 7 deployed with 2 replicas each
- **Database**: Shared RDS MySQL (same DB can be consumed by Node and Java)
- **Cost**: ~$70/month ($2/month if EC2 stopped when not in use)

### Production Environment
- **Cluster**: 1 ASG with 3-6 × t3.micro EC2 instances in the current tfvars
- **Services**: All 7 deployed with 2-4 replicas each (depends on load)
- **Database**: RDS MySQL Multi-AZ (not on EC2)
- **Scaling**: CPU-based autoscaling, request-count based service scaling
- **Cost**: ~$300-500/month

---

## Resilience & High Availability

This section describes the intended operational posture once Phase 1 and later platform work is complete.

### Fault Tolerance
- **Multi-AZ**: Services spread across 2 availability zones
- **Health Checks**: ALB removes unhealthy targets automatically
- **Auto-Healing**: ASG replaces failed EC2 instances
- **Circuit Breaker**: Retry logic in shared-library for service calls
- **Graceful Shutdown**: ECS connection draining before task termination

### Scaling Strategy
1. **Horizontal**: Add more EC2 instances (ASG scales)
2. **Vertical**: Increase instance type later only if t3.micro is no longer sufficient
3. **Service-Level**: Increase replicas per service based on CPU/memory/requests

### Monitoring & Alerts
- ALB 4XX/5XX rates
- Service CPU > 80%
- Database connection pool > 95%
- Lambda error rate > 1%
- Order service latency > 500ms

---

## Security Architecture

Some of these controls are architectural targets rather than already-verified implementation details.

### Network Isolation
- **Public subnets**: ALB only
- **Private subnets**: ECS services, MySQL
- **NAT Gateway**: Outbound internet access for ECS (optional)
- **Security Groups**: Least privilege (ALB → ECS, ECS → MySQL)

### Authentication & Authorization
- **JWT tokens**: Issued by Account Service
- **Token validation**: All services validate signature (no token lookup)
- **Secrets**: RDS password + SES API key in AWS Secrets Manager
- **IAM roles**: ECS tasks have minimal permissions (S3 read for gallery, SES send for Lambda)

### Data Protection
- **Encryption**: MySQL at-rest (TDE), in-transit (TLS)
- **HTTPS**: ALB→client (when enabled)
- **Secrets**: Managed by AWS Secrets Manager, not in code

---

## Cost Optimization

### Current Costs
| Component | Dev | Prod |
|-----------|-----|------|
| EC2 (2-3 instances) | $20 | $100 |
| ALB | $16 | $16 |
| NAT Gateway | $32 | $32 |
| Data transfer | $5 | $20 |
| CloudWatch | $10 | $20 |
| **Total** | **~$83** | **~$188** |

### Cost Reduction Strategies
1. **Scale EC2 to 0 when not demoing**: -$52/month (dev)
2. **Use t3 instances**: 30% cheaper than m5
3. **Reserved instances** (prod): -40% on compute
4. **RDS single-AZ** (dev only): -50% vs Multi-AZ
5. **Data transfer**: Keep services in same AZ/region

---

**Last Updated**: June 2026
