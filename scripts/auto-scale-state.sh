#!/usr/bin/env bash

set -euo pipefail

ACTION="${1:-}"

if [[ "$ACTION" != "down" && "$ACTION" != "up" ]]; then
	echo "Usage: $0 <down|up>"
	exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
	echo "Error: aws CLI not found in PATH."
	exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "Error: jq not found in PATH."
	exit 1
fi

REGION="${REGION:-${AWS_REGION:-us-east-2}}"
CLUSTER="${CLUSTER:-vegan-mundi-prod-cluster}"

# Fixed ASG baseline restored on 'up'. Override with env vars if needed.
RESTORE_FIXED_MIN="${ASG_RESTORE_MIN:-2}"
RESTORE_FIXED_DESIRED="${ASG_RESTORE_DESIRED:-2}"
RESTORE_FIXED_MAX="${ASG_RESTORE_MAX:-6}"

SERVICES=(
	vegan-mundi-account-service
	vegan-mundi-class-service
	vegan-mundi-order-service
	vegan-mundi-review-service
	vegan-mundi-delivery-service
	vegan-mundi-gallery-service
	vegan-mundi-price-service
	vegan-mundi-gateway
)

# Processes that can cause unexpected relaunch/rebalance during down state.
LOCK_PROCESSES=(
	Launch
	AlarmNotification
	ScheduledActions
	ReplaceUnhealthy
	AZRebalance
	InstanceRefresh
)

VALID_SUSPEND_PROCESSES=(
	AZRebalance
	AddToLoadBalancer
	AlarmNotification
	HealthCheck
	InstanceRefresh
	Launch
	ReplaceUnhealthy
	ScheduledActions
	Terminate
)

is_valid_suspend_process() {
	local p="$1"
	for valid in "${VALID_SUSPEND_PROCESSES[@]}"; do
		if [[ "$p" == "$valid" ]]; then
			return 0
		fi
	done
	return 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${SCRIPT_DIR}/.state"
mkdir -p "$STATE_DIR"

CLUSTER_KEY="$(echo "$CLUSTER" | tr -c 'a-zA-Z0-9._-' '_')"
STATE_FILE="${STATE_DIR}/auto-scale-state-${CLUSTER_KEY}.json"

echo "Region: $REGION"
echo "Cluster: $CLUSTER"

CP_NAME="$(aws --no-cli-pager ecs describe-clusters \
	--region "$REGION" \
	--clusters "$CLUSTER" \
	--query "clusters[0].defaultCapacityProviderStrategy[0].capacityProvider" \
	--output text)"

if [[ -z "$CP_NAME" || "$CP_NAME" == "None" ]]; then
	echo "Error: Could not resolve default capacity provider for cluster $CLUSTER"
	exit 1
fi

ASG_ARN="$(aws --no-cli-pager ecs describe-capacity-providers \
	--region "$REGION" \
	--capacity-providers "$CP_NAME" \
	--query "capacityProviders[0].autoScalingGroupProvider.autoScalingGroupArn" \
	--output text)"

ASG_NAME="${ASG_ARN##*/}"

if [[ -z "$ASG_NAME" || "$ASG_NAME" == "None" ]]; then
	echo "Error: Could not resolve Auto Scaling Group from capacity provider $CP_NAME"
	exit 1
fi

echo "Capacity Provider: $CP_NAME"
echo "ASG: $ASG_NAME"

if [[ "$ACTION" == "down" ]]; then
	ASG_MIN="$(aws --no-cli-pager autoscaling describe-auto-scaling-groups \
		--region "$REGION" \
		--auto-scaling-group-names "$ASG_NAME" \
		--query "AutoScalingGroups[0].MinSize" \
		--output text)"
	ASG_DESIRED="$(aws --no-cli-pager autoscaling describe-auto-scaling-groups \
		--region "$REGION" \
		--auto-scaling-group-names "$ASG_NAME" \
		--query "AutoScalingGroups[0].DesiredCapacity" \
		--output text)"
	ASG_MAX="$(aws --no-cli-pager autoscaling describe-auto-scaling-groups \
		--region "$REGION" \
		--auto-scaling-group-names "$ASG_NAME" \
		--query "AutoScalingGroups[0].MaxSize" \
		--output text)"
	PRE_SUSPENDED_JSON="$(aws --no-cli-pager autoscaling describe-auto-scaling-groups \
		--region "$REGION" \
		--auto-scaling-group-names "$ASG_NAME" \
		--query "AutoScalingGroups[0].SuspendedProcesses[].ProcessName" \
		--output json)"

	desired_json="{}"
	for service in "${SERVICES[@]}"; do
			service_status="$(aws --no-cli-pager ecs describe-services \
				--region "$REGION" \
				--cluster "$CLUSTER" \
				--services "$service" \
				--query "services[0].status" \
				--output text 2>/dev/null || echo "MISSING")"

			if [[ "$service_status" == "MISSING" || "$service_status" == "None" || "$service_status" == "INACTIVE" ]]; then
				echo "Service $service not found or inactive in cluster; recording desired=0"
				desired_json="$(jq --arg name "$service" --argjson count 0 '. + {($name): $count}' <<< "$desired_json")"
				continue
			fi

		current_desired="$(aws --no-cli-pager ecs describe-services \
			--region "$REGION" \
			--cluster "$CLUSTER" \
			--services "$service" \
			--query "services[0].desiredCount" \
			--output text 2>/dev/null || echo "0")"

		if [[ "$current_desired" == "None" ]]; then
			current_desired="0"
		fi

		desired_json="$(jq --arg name "$service" --argjson count "$current_desired" '. + {($name): $count}' <<< "$desired_json")"
	done

	jq -n \
		--arg cluster "$CLUSTER" \
		--arg region "$REGION" \
		--arg asg_name "$ASG_NAME" \
		--arg cp_name "$CP_NAME" \
		--argjson asg_min "$ASG_MIN" \
		--argjson asg_desired "$ASG_DESIRED" \
		--argjson asg_max "$ASG_MAX" \
		--argjson asg_pre_suspended "$PRE_SUSPENDED_JSON" \
		--argjson lock_processes "$(printf '%s\n' "${LOCK_PROCESSES[@]}" | jq -R . | jq -s .)" \
		--argjson services "$desired_json" \
		--arg saved_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		'{
			savedAt: $saved_at,
			cluster: $cluster,
			region: $region,
			capacityProvider: $cp_name,
			asgName: $asg_name,
			asg: {
				min: $asg_min,
				desired: $asg_desired,
				max: $asg_max,
				preSuspended: $asg_pre_suspended,
				lockProcesses: $lock_processes
			},
			services: $services
		}' > "$STATE_FILE"

	echo "Saved current state to $STATE_FILE"

	for service in "${SERVICES[@]}"; do
		service_status="$(aws --no-cli-pager ecs describe-services \
			--region "$REGION" \
			--cluster "$CLUSTER" \
			--services "$service" \
			--query "services[0].status" \
			--output text 2>/dev/null || echo "MISSING")"

		if [[ "$service_status" == "MISSING" || "$service_status" == "None" || "$service_status" == "INACTIVE" ]]; then
			echo "Skipping missing/inactive service $service"
			continue
		fi

		echo "Scaling service $service to desired-count=0"
		aws --no-cli-pager ecs update-service \
			--region "$REGION" \
			--cluster "$CLUSTER" \
			--service "$service" \
			--desired-count 0 >/dev/null
	done

	echo "Canceling active instance refresh (if any)"
	aws --no-cli-pager autoscaling cancel-instance-refresh \
		--region "$REGION" \
		--auto-scaling-group-name "$ASG_NAME" >/dev/null 2>&1 || true

	echo "Scaling ASG $ASG_NAME to min=0 desired=0 max=0"
	aws --no-cli-pager autoscaling update-auto-scaling-group \
		--region "$REGION" \
		--auto-scaling-group-name "$ASG_NAME" \
		--min-size 0 \
		--desired-capacity 0 \
		--max-size 0 >/dev/null

	echo "Suspending relaunch-related ASG processes"
	aws --no-cli-pager autoscaling suspend-processes \
		--region "$REGION" \
		--auto-scaling-group-name "$ASG_NAME" \
		--scaling-processes "${LOCK_PROCESSES[@]}" >/dev/null

	echo "Done: environment scaled down."
	exit 0
fi

if [[ ! -f "$STATE_FILE" ]]; then
	echo "Error: No saved state file found at $STATE_FILE"
	echo "Run '$0 down' once before running '$0 up'."
	exit 1
fi

STATE_CLUSTER="$(jq -r '.cluster' "$STATE_FILE")"
STATE_REGION="$(jq -r '.region' "$STATE_FILE")"
STATE_ASG_NAME="$(jq -r '.asgName' "$STATE_FILE")"

if [[ "$STATE_CLUSTER" != "$CLUSTER" || "$STATE_REGION" != "$REGION" || "$STATE_ASG_NAME" != "$ASG_NAME" ]]; then
	echo "Error: Saved state does not match current target."
	echo "Saved: cluster=$STATE_CLUSTER region=$STATE_REGION asg=$STATE_ASG_NAME"
	echo "Current: cluster=$CLUSTER region=$REGION asg=$ASG_NAME"
	exit 1
fi

echo "Restoring ASG $ASG_NAME to fixed baseline min=$RESTORE_FIXED_MIN desired=$RESTORE_FIXED_DESIRED max=$RESTORE_FIXED_MAX"
aws --no-cli-pager autoscaling update-auto-scaling-group \
	--region "$REGION" \
	--auto-scaling-group-name "$ASG_NAME" \
	--min-size "$RESTORE_FIXED_MIN" \
	--desired-capacity "$RESTORE_FIXED_DESIRED" \
	--max-size "$RESTORE_FIXED_MAX" >/dev/null

RESUME_PROCESSES=()
while IFS= read -r proc; do
	proc="${proc//$'\r'/}"

	if [[ -z "$proc" ]]; then
		continue
	fi

	if ! is_valid_suspend_process "$proc"; then
		echo "Skipping unsupported process in saved state: $proc"
		continue
	fi

	if ! jq -e --arg p "$proc" '.asg.preSuspended // [] | index($p)' "$STATE_FILE" >/dev/null; then
		RESUME_PROCESSES+=("$proc")
	fi
done < <(jq -r '.asg.lockProcesses[]? // empty' "$STATE_FILE")

if [[ ${#RESUME_PROCESSES[@]} -gt 0 ]]; then
	echo "Resuming ASG processes: ${RESUME_PROCESSES[*]}"
	aws --no-cli-pager autoscaling resume-processes \
		--region "$REGION" \
		--auto-scaling-group-name "$ASG_NAME" \
		--scaling-processes "${RESUME_PROCESSES[@]}" >/dev/null
fi

for service in "${SERVICES[@]}"; do
	service_status="$(aws --no-cli-pager ecs describe-services \
		--region "$REGION" \
		--cluster "$CLUSTER" \
		--services "$service" \
		--query "services[0].status" \
		--output text 2>/dev/null || echo "MISSING")"

	if [[ "$service_status" == "MISSING" || "$service_status" == "None" || "$service_status" == "INACTIVE" ]]; then
		echo "Skipping missing/inactive service $service"
		continue
	fi

	target_count="$(jq -r --arg svc "$service" '.services[$svc] // 0' "$STATE_FILE")"
	echo "Restoring service $service to desired-count=$target_count"
	aws --no-cli-pager ecs update-service \
		--region "$REGION" \
		--cluster "$CLUSTER" \
		--service "$service" \
		--desired-count "$target_count" >/dev/null
done

echo "Done: environment restored from saved state."
