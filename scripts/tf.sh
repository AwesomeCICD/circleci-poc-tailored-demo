#!/usr/bin/env bash
# Run Terraform for one stack in one environment.
#
#   scripts/tf.sh <stack> <environment> <plan|apply|validate>
#
# Same code, same branch, every environment. The environment only changes
# which tfvars file is used and where state is stored.
set -euo pipefail

STACK="${1:?stack (network|compute|...)}"
ENVIRONMENT="${2:?environment (dev|test|stage|prod)}"
ACTION="${3:?action (plan|apply|validate)}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STACK_DIR="${ROOT}/infra/stacks/${STACK}"
VAR_FILE="${ROOT}/infra/environments/${ENVIRONMENT}.tfvars"

[ -d "$STACK_DIR" ] || { echo "No such stack: ${STACK}"; exit 1; }
[ -f "$VAR_FILE" ]  || { echo "No such environment file: ${VAR_FILE}"; exit 1; }

cd "$STACK_DIR"

if [ "$ACTION" = "validate" ]; then
  terraform init -backend=false -input=false
  terraform validate
  exit 0
fi

: "${TF_STATE_BUCKET:?TF_STATE_BUCKET must be set (from the CircleCI context)}"
REGION="$(awk -F'"' '/^aws_region/ {print $2}' "$VAR_FILE")"

terraform init -input=false -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=${ENVIRONMENT}/${STACK}.tfstate" \
  -backend-config="region=${REGION}" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

case "$ACTION" in
  plan)
    terraform plan -input=false -var-file="$VAR_FILE" -out="${ENVIRONMENT}.tfplan"
    ;;
  apply)
    terraform apply -input=false -auto-approve -var-file="$VAR_FILE"
    ;;
  *)
    echo "Unknown action: ${ACTION}"; exit 1
    ;;
esac
