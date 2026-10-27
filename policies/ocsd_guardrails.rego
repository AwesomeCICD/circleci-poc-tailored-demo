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
# 1. HARD: every pipeline must include a SonarQube job.
# ---------------------------------------------------------------------------
enable_hard["require_sonarqube_scan"]

# Compiled jobs are what a triggered pipeline actually runs. Deploy pipelines
# also declare the scan on every workflow in the source config: until CircleCI
# fills in pipeline.deploy.environment_name, local compilation treats every
# when: branch as false and leaves _compiled_.jobs empty.
job_names[name] if {
	some name, _ in input._compiled_.jobs
}

job_names[name] if {
	some _, workflow in input.workflows
	some job in workflow.jobs
	name := workflow_job_name(job)
}

workflow_job_name(job) := job if {
	is_string(job)
}

workflow_job_name(job) := name if {
	is_object(job)
	some name, _ in job
}

has_sonarqube_job if {
	some job_name
	job_names[job_name]
	indexof(lower(job_name), "sonarqube") >= 0
}

require_sonarqube_scan = reason if {
	not has_sonarqube_job
	reason := "Every pipeline must run a SonarQube job (sonarqube-scan or sonarqube-quality-gate). Add it back to .circleci/config.yml."
}

# ---------------------------------------------------------------------------
# 2. HARD: no static AWS keys in config. Use OIDC (aws-cli/setup role_arn).
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
# 3. SOFT: warn on large machines (cost control). Pipeline still runs.
# ---------------------------------------------------------------------------
enable_rule["standard_resource_classes"]

allowed_resource_classes := {"small", "medium", "medium+"}

standard_resource_classes[job_name] = reason if {
	some job_name, job in input._compiled_.jobs
	rc := job.resource_class
	not rc in allowed_resource_classes
	reason := sprintf("Job '%s' uses resource_class '%s'. Standard sizes are small, medium, medium+. Ask the platform team if you need more.", [job_name, rc])
}
