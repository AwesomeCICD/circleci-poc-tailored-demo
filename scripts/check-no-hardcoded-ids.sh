#!/usr/bin/env bash
# Fail if a Terraform file under infra/ pastes a real VPC, subnet, or security group ID.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PATTERN='\b(vpc|subnet|sg)-[0-9a-f]{8,17}\b'
found=0

while IFS= read -r hit; do
  [ -z "$hit" ] && continue
  echo "$hit"
  echo "Use module.platform.* instead of hard-coded IDs. See docs/ADD_A_MODULE.md."
  found=1
done < <(grep -RInE "$PATTERN" "$ROOT/infra" --include='*.tf' --include='*.tfvars' || true)

if [ "$found" -ne 0 ]; then
  exit 1
fi
