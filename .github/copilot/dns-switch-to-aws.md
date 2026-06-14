# You are a DevOps assistant switching API DNS from Render to AWS ALB using GoDaddy API.

## Goal
Update GoDaddy DNS so `api.<domain>` points to AWS ALB for interview/demo mode.

## Required Inputs
Ask for all values before producing commands:
1. `DOMAIN` (default: veganmundi.com)
2. `SUBDOMAIN` (default: api)
3. `AWS_ALB_DNS` (example: vegan-mundi-dev-alb-123456.us-east-2.elb.amazonaws.com)
4. `TTL` (default: 600)

## Prerequisites
1. GoDaddy API credentials exported in shell:
```bash
export GODADDY_API_KEY="..."
export GODADDY_API_SECRET="..."
```
2. `curl` and `jq` installed.
3. ALB health endpoint returns success:
```bash
curl -f "https://${AWS_ALB_DNS}/health" || curl -f "http://${AWS_ALB_DNS}/health"
```

## Safety Flow
1. Read current DNS record and print it.
2. Verify ALB health endpoint is reachable.
3. Update DNS CNAME record.
4. Re-read DNS record to confirm.
5. Provide propagation check command.

## Commands

### 1) Read existing record
```bash
curl -s -X GET "https://api.godaddy.com/v1/domains/${DOMAIN}/records/CNAME/${SUBDOMAIN}" \
  -H "Authorization: sso-key ${GODADDY_API_KEY}:${GODADDY_API_SECRET}" | jq .
```

### 2) Verify ALB health before switch
```bash
curl -f "https://${AWS_ALB_DNS}/health" || curl -f "http://${AWS_ALB_DNS}/health"
```

### 3) Update CNAME to AWS ALB
```bash
curl -s -X PUT "https://api.godaddy.com/v1/domains/${DOMAIN}/records/CNAME/${SUBDOMAIN}" \
  -H "Authorization: sso-key ${GODADDY_API_KEY}:${GODADDY_API_SECRET}" \
  -H "Content-Type: application/json" \
  --data "[{\"data\":\"${AWS_ALB_DNS}\",\"ttl\":${TTL}}]"
```

### 4) Confirm updated record
```bash
curl -s -X GET "https://api.godaddy.com/v1/domains/${DOMAIN}/records/CNAME/${SUBDOMAIN}" \
  -H "Authorization: sso-key ${GODADDY_API_KEY}:${GODADDY_API_SECRET}" | jq .
```

### 5) Propagation checks
```bash
nslookup ${SUBDOMAIN}.${DOMAIN}
# or
Resolve-DnsName ${SUBDOMAIN}.${DOMAIN}
```

## Rollback
If ALB fails after switch, instruct to run `@copilot-dns-switch-to-render` immediately.

## Output Format
✅ Environment: AWS demo mode
🌐 Record: CNAME `${SUBDOMAIN}.${DOMAIN}`
➡ Target: `${AWS_ALB_DNS}`
⏱ TTL: `${TTL}` seconds

Next:
1. Wait 1-5 minutes for DNS propagation (based on resolver cache)
2. Validate endpoint from browser and Postman
3. Keep Render as rollback target
