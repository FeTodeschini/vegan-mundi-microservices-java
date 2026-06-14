# AWS CLI Examples & Operational Commands

Quick reference for AWS CLI commands used in production operations and demos.

## Prerequisites

```bash
# Configure AWS CLI
aws configure

# Set default region
export AWS_REGION=us-east-2
export ENVIRONMENT=dev
```

## ECS Management

### List Running Tasks
```bash
aws ecs list-tasks \
  --cluster vegan-mundi-${ENVIRONMENT}-cluster \
  --service-name vegan-mundi-account-service \
  --desired-status RUNNING \
  --region $AWS_REGION
```

### Describe Service Status
```bash
aws ecs describe-services \
  --cluster vegan-mundi-${ENVIRONMENT}-cluster \
  --services vegan-mundi-account-service \
  --region $AWS_REGION \
  --query 'services[0].[serviceName,runningCount,desiredCount,deployments[0].status]' \
  --output table
```

### Get Task Details
```bash
TASK_ARN="arn:aws:ecs:${AWS_REGION}:123456789:task/vegan-mundi-${ENVIRONMENT}-cluster/abc123xyz"

aws ecs describe-tasks \
  --cluster vegan-mundi-${ENVIRONMENT}-cluster \
  --tasks $TASK_ARN \
  --region $AWS_REGION
```

### Execute Command in Running Task
```bash
aws ecs execute-command \
  --cluster vegan-mundi-${ENVIRONMENT}-cluster \
  --task $TASK_ARN \
  --container vegan-mundi-account-service \
  --interactive \
  --command "/bin/sh"
```

### Scale Service Replicas
```bash
# Increase replicas to 4
aws ecs update-service \
  --cluster vegan-mundi-${ENVIRONMENT}-cluster \
  --service vegan-mundi-account-service \
  --desired-count 4 \
  --region $AWS_REGION
```

### Deploy New Image Version
```bash
aws ecs update-service \
  --cluster vegan-mundi-${ENVIRONMENT}-cluster \
  --service vegan-mundi-account-service \
  --force-new-deployment \
  --region $AWS_REGION
```

## ALB & Health Checks

### List Load Balancers
```bash
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `vegan-mundi`)].{Name:LoadBalancerName,DNS:DNSName}' \
  --region $AWS_REGION \
  --output table
```

### Check Target Group Health
```bash
# Get target group ARN first
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
  --load-balancer-arn arn:aws:elasticloadbalancing:${AWS_REGION}:123456789:loadbalancer/app/vegan-mundi-${ENVIRONMENT}-alb/abc123xyz \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Check health
aws elbv2 describe-target-health \
  --target-group-arn $TARGET_GROUP_ARN \
  --region $AWS_REGION \
  --query 'TargetHealthDescriptions[].{Target:Target.Id,Status:TargetHealth.State,Description:TargetHealth.Description}' \
  --output table
```

### Deregister Unhealthy Target
```bash
aws elbv2 deregister-targets \
  --target-group-arn $TARGET_GROUP_ARN \
  --targets Id=i-1234567890abcdef0 \
  --region $AWS_REGION
```

## CloudWatch Logs

### List Log Groups
```bash
aws logs describe-log-groups \
  --log-group-name-prefix /ecs/vegan-mundi \
  --region $AWS_REGION \
  --query 'logGroups[].logGroupName'
```

### Filter Logs for Errors (Last Hour)
```bash
aws logs filter-log-events \
  --log-group-name /ecs/vegan-mundi-account-service \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region $AWS_REGION \
  --query 'events[].[timestamp,message]' \
  --output text
```

### Tail Live Logs
```bash
aws logs tail /ecs/vegan-mundi-account-service \
  --follow \
  --filter-pattern "ERROR OR WARN"
```

### Get Log Statistics
```bash
aws logs describe-log-streams \
  --log-group-name /ecs/vegan-mundi-account-service \
  --region $AWS_REGION \
  --query 'logStreams[].{StreamName:logStreamName,LastEvent:lastEventTimestamp,Size:storedBytes}' \
  --output table
```

## CloudWatch Metrics & Alarms

### Describe Alarms
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix vegan-mundi \
  --region $AWS_REGION \
  --query 'MetricAlarms[].[AlarmName,StateValue,StateReason]' \
  --output table
```

### Set Alarm State (for testing)
```bash
aws cloudwatch set-alarm-state \
  --alarm-name vegan-mundi-account-service-cpu \
  --state-value ALARM \
  --state-reason "Testing alert" \
  --region $AWS_REGION
```

### Get Metric Statistics
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=vegan-mundi-account-service \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average Maximum \
  --region $AWS_REGION
```

## Auto Scaling Groups

### Describe ASG
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names vegan-mundi-${ENVIRONMENT}-ecs-asg \
  --region $AWS_REGION \
  --query 'AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize,Instances[].{InstanceId:InstanceId,HealthStatus:HealthStatus,LifecycleState:LifecycleState}]'
```

### Scale Up
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name vegan-mundi-${ENVIRONMENT}-ecs-asg \
  --desired-capacity 4 \
  --region $AWS_REGION
```

### Scale Down (to $0)
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name vegan-mundi-${ENVIRONMENT}-ecs-asg \
  --desired-capacity 0 \
  --region $AWS_REGION
```

### List Instances in ASG
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names vegan-mundi-${ENVIRONMENT}-ecs-asg \
  --region $AWS_REGION \
  --query 'AutoScalingGroups[0].Instances[].InstanceId' \
  --output text | xargs -I {} aws ec2 describe-instances --instance-ids {} --query 'Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]' --output table
```

## EC2 Instance Management

### SSH into Instance
```bash
# Get instance ID from ASG
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names vegan-mundi-${ENVIRONMENT}-ecs-asg \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

# Get instance details
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].[PublicIpAddress,PrivateIpAddress,State.Name]'

# SSH into bastion if private
ssh -i your-key.pem ec2-user@<instance-ip>
```

## EventBridge & Lambda

### List EventBridge Rules
```bash
aws events list-rules \
  --name-prefix vegan-mundi \
  --region $AWS_REGION \
  --query 'Rules[].[Name,State,EventPattern]'
```

### Publish Test Event to EventBridge
```bash
aws events put-events \
  --entries '[
    {
      "Source": "vegan-mundi.order-service",
      "DetailType": "OrderCreated",
      "Detail": "{\"orderId\":\"12345\",\"userId\":\"user-1\",\"amount\":25.99}"
    }
  ]' \
  --region $AWS_REGION
```

### Get Lambda Function Details
```bash
aws lambda get-function \
  --function-name vegan-mundi-order-confirmation \
  --region $AWS_REGION
```

### Invoke Lambda Function
```bash
aws lambda invoke \
  --function-name vegan-mundi-order-confirmation \
  --payload '{"orderId":"12345"}' \
  --log-type Tail \
  response.json \
  --region $AWS_REGION

cat response.json
```

### Check Lambda Logs
```bash
aws logs tail /aws/lambda/vegan-mundi-order-confirmation \
  --follow \
  --region $AWS_REGION
```

## ECR (Container Registry)

### List Repositories
```bash
aws ecr describe-repositories \
  --region $AWS_REGION \
  --query 'repositories[].repositoryName'
```

### List Images in Repository
```bash
aws ecr describe-images \
  --repository-name vegan-mundi-account-service \
  --region $AWS_REGION \
  --query 'imageDetails[].[imageTags,imagePushedAt,imageSizeBytes]' \
  --output table
```

### Login to ECR
```bash
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin 123456789.dkr.ecr.${AWS_REGION}.amazonaws.com
```

### Push Image to ECR
```bash
docker build -t vegan-mundi-account-service:latest .
docker tag vegan-mundi-account-service:latest 123456789.dkr.ecr.${AWS_REGION}.amazonaws.com/vegan-mundi-account-service:latest
docker push 123456789.dkr.ecr.${AWS_REGION}.amazonaws.com/vegan-mundi-account-service:latest
```

## RDS / MySQL

### Describe DB Instance
```bash
aws rds describe-db-instances \
  --db-instance-identifier vegan-mundi-mysql-${ENVIRONMENT} \
  --region $AWS_REGION \
  --query 'DBInstances[0].[DBInstanceStatus,DBInstanceClass,Engine,AllocatedStorage]'
```

### Get RDS Endpoint
```bash
aws rds describe-db-instances \
  --db-instance-identifier vegan-mundi-mysql-${ENVIRONMENT} \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text \
  --region $AWS_REGION
```

### Connect to MySQL
```bash
ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier vegan-mundi-mysql-${ENVIRONMENT} \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

mysql -h $ENDPOINT -u admin -p vegan_mundi_dev
```

## Useful Bash Scripts

### Health Check Loop
```bash
while true; do
  echo "=== ECS Services Health ==="
  aws ecs describe-services \
    --cluster vegan-mundi-${ENVIRONMENT}-cluster \
    --services $(aws ecs list-services --cluster vegan-mundi-${ENVIRONMENT}-cluster --query 'serviceArns[]' --output text) \
    --query 'services[].[serviceName,runningCount,desiredCount,deployments[0].status]' \
    --output table
  sleep 10
done
```

### Monitor Logs for Errors
```bash
watch -n 5 'aws logs filter-log-events \
  --log-group-name /ecs/vegan-mundi-account-service \
  --filter-pattern "ERROR" \
  --start-time $(date -d "5 minutes ago" +%s)000 \
  --query "length(events[])" \
  --output text | xargs echo "Errors in last 5 min:"'
```

---

**Interview Talking Point**: "I demonstrate operational fluency with AWS CLI—not just Terraform for infrastructure, but hands-on debugging and real-time monitoring."

**Last Updated**: June 2026
