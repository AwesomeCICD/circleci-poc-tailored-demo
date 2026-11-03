# OCSD POC config policies (Open Policy Agent / Rego).
# CircleCI checks every pipeline's config against these BEFORE it runs.
#
#   HARD fail = pipeline is blocked and never starts.
#   SOFT fail = pipeline runs, a warning is shown and logged.
#
# Upload:  circleci policy push policies/ --org <ORG_ID>
# Test:    circleci policy eval policies/ --input .circleci/config.yml
package org

import future.keywords

policy_name["ocsd_guardrails"]

# ---------------------------------------------------------------------------
# 1. HARD: no static AWS keys in config. Use OIDC (aws-cli/setup role_arn).
# ---------------------------------------------------------------------------
enable_hard["no_static_aws_keys"]

static_key_names := {
	"AWS_ACCESS_KEY_ID",
	"AWS_SECRET_ACCESS_KEY",
	"aws_access_key_id",
	"aws_secret_access_key",
}

no_static_aws_keys[key] = reason if {
	walk(input, [path, _])
	count(path) > 0
	path[0] != "_compiled_"
	key := path[count(path) - 1]
	key in static_key_names
	reason := sprintf("Static AWS key setting '%s' found in config. Deploy with OIDC roles instead.", [key])
}

# ---------------------------------------------------------------------------
# 2. SOFT: warn on large machines (cost control). Pipeline still runs.
# ---------------------------------------------------------------------------
enable_rule["standard_resource_classes"]

allowed_resource_classes := {"small", "medium", "medium+"}

standard_resource_classes[job_name] = reason if {
	some job_name, job in input._compiled_.jobs
	rc := job.resource_class
	not rc in allowed_resource_classes
	reason := sprintf("Job '%s' uses resource_class '%s'. Standard sizes are small, medium, medium+. Ask the platform team if you need more.", [job_name, rc])
}
