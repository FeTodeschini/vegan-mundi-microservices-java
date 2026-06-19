# GitHub Copilot DevOps Agents

Custom GitHub Copilot instruction files for automating DevOps tasks and cost optimization.

## Quick Reference

| Agent | Prompt | Use Case |
|---|---|---|
| **EC2 Start** | `@copilot-ec2-start` | Scale up ECS infrastructure for demo |
| **EC2 Stop** | `@copilot-ec2-stop` | Scale down to $0 to save costs |
| **Health Check** | `@copilot-ec2-health-check` | Verify all services operational |
| **Log Analyzer** | `@copilot-log-analyzer` | Triage CloudWatch issues |
| **Terraform Reviewer** | `@copilot-terraform-plan-reviewer` | Review infrastructure changes safely |
| **DNS Switch to AWS** | `@copilot-dns-switch-to-aws` | Point `api` CNAME to AWS ALB for demo mode |
| **DNS Switch to Render** | `@copilot-dns-switch-to-render` | Point `api` CNAME back to Render for normal mode |
| **Backend Switch** | `@copilot-backend-switch` | Ask AWS or Render and produce full human runbook with rollback |

## Prerequisites

1. **GitHub Copilot Chat** installed in VS Code
2. **AWS CLI** configured with credentials
3. **Terraform** (if using plan reviewer)
4. **GoDaddy API credentials** for DNS switching

## Usage Examples

### Start Demo Environment
```
User: @copilot-ec2-start

Copilot: Which environment? (dev/test/prod)
> dev

Copilot: Starting 2 t3.micro instances in dev cluster...
[provides exact AWS CLI command]
[monitors startup status]
[confirms readiness]
```

### Stop to Save Costs
```
User: @copilot-ec2-stop

Copilot: Scaling dev cluster to 0 to save ~$0.67/day...
[checks for active connections]
[gracefully drains tasks]
[confirms scale-down]
[displays monthly savings]
```

### Check Service Health
```
User: @copilot-ec2-health-check

Copilot: Checking infrastructure health...
- ALB: Healthy (7 healthy targets, 0 unhealthy)
- Account Service: Running (2/2 tasks)
- Order Service: Running (2/2 tasks)
[etc]

✓ All systems operational
```

### Analyze Recent Errors
```
User: @copilot-log-analyzer

Copilot: Which service? (account/class/order/etc)
> order

Copilot: Analyzing order-service logs (last hour)...
- 3 ERROR entries found
- Root cause: Database timeout after 30s
- Affected tasks: 1
- Recommended action: Increase connection pool or check RDS load

Show detailed logs? (yes/no)
```

### Review Infrastructure Plan
```
User: @copilot-terraform-plan-reviewer

Copilot: Parsing terraform plan...

Changes summary:
- Create: 5 resources
- Modify: 2 resources  
- Destroy: 0 resources

⚠ Security changes:
- ALB security group: Allowing 0.0.0.0/0 on port 80 (expected)

💰 Cost impact: +$15/month

Approve changes? (yes/no)
```

## Cost Savings Example

**Dev Environment Costs**
- Running 24/7: ~$20/month (2× t3.micro)
- With EC2 start/stop: ~$2-3/month

**Usage Pattern**
- Start in morning: `@copilot-ec2-start` → 2 min startup
- Work for 8 hours: Services running
- Stop at end of day: `@copilot-ec2-stop` → 1 min cleanup
- **Monthly savings: ~$18 (90% reduction)**

## Integration with Workflows

These agents work best in:
- **Local development**: Quick health checks and debugging
- **Demo preparation**: Start infrastructure 5 minutes before demo
- **Post-demo cleanup**: Stop instances to control costs
- **Incident response**: Fast log analysis and triage
- **Deployment reviews**: Safe Terraform plan review before apply

## Security Considerations

- Agents use AWS CLI with existing credentials (no hardcoding)
- Commands are displayed before execution (approval step)
- Sensitive output (passwords, tokens) is masked
- Actions are logged in your AWS CloudTrail

## Advanced Usage

### Chain Multiple Commands
```
User: Start the demo, check health, and show logs

@copilot-ec2-start → wait 2 min → @copilot-ec2-health-check → @copilot-log-analyzer
```

### CI/CD Integration (Future)
These agents can be triggered from GitHub Actions or Jenkins:
```bash
# Example: Stop infrastructure after test run
aws-cli ec2 scale-to-zero --environment dev
```

## Interview Talking Points

✅ **Cost Optimization**: 90% savings through automated lifecycle management  
✅ **Operational Efficiency**: Reduced manual toil and human error  
✅ **AI Integration**: Copilot as productivity multiplier across DevOps  
✅ **Safety**: Commands reviewed before execution  
✅ **Scalability**: Same pattern works for prod with different configs  

---

**Last Updated**: June 2026
