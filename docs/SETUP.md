# One-Time Setup (Admins)

Do this once before the workshop. It takes about 30 minutes. Values in `<ANGLE_BRACKETS>` are yours to fill in.

## 1. GitHub

1. Create an empty repository, for example `ocsd/ocsd-circleci-poc`, and push this code to `main`.
2. Install the **CircleCI GitHub App** on the OCSD GitHub organization and give it access to that repository.

## 2. CircleCI project

1. In CircleCI, open the OCSD organization and create a project for the repository.
2. Copy two IDs. You need both for AWS:
    - **Organization ID:** Organization Settings → Overview
    - **Project ID:** Project Settings → Overview

## 3. AWS: OIDC trust, roles and state bucket (sandbox account)

An AWS admin runs this from a laptop or AWS CloudShell, signed in to the **sandbox account**:

```bash
cd bootstrap
terraform init
terraform apply \
  -var circleci_org_id=<ORG_ID> \
  -var circleci_project_id=<PROJECT_ID> \
  -var aws_region=<REGION>
```

Note the outputs: `tf_state_bucket` and `deploy_role_arns` (one role per environment). These roles can only be assumed by pipelines from this one CircleCI project. CircleCI never stores AWS keys.

> GovCloud: set `aws_region` to `us-gov-west-1` (or `us-gov-east-1`). Confirm CircleCI OIDC is allowed as an identity provider in the GovCloud account before the workshop.

Also set `aws_region` in each `infra/environments/*.tfvars` to the same region.

## 4. CircleCI contexts (where settings and secrets live)

Organization Settings → Contexts. Create these five:

| Context | Environment variables | Restrict to security group |
| --- | --- | --- |
| `ocsd-aws-dev` | `AWS_ROLE_ARN` = dev role ARN, `AWS_REGION`, `TF_STATE_BUCKET` | All members |
| `ocsd-aws-test` | same, with the test role ARN | All members |
| `ocsd-aws-stage` | same, with the stage role ARN | `<ocsd-release-approvers>` |
| `ocsd-aws-prod` | same, with the prod role ARN | `<ocsd-release-approvers>` |
| `ocsd-sonarqube` | `SONAR_HOST_URL`, `SONAR_TOKEN` | All members |

Restricting the stage and prod contexts to a GitHub team means only that team can approve the `approve-stage` and `approve-prod` jobs or run those deploys.

## 5. SonarQube

1. In SonarQube (or SonarQube Cloud), create a project with key `ocsd-circleci-poc` and generate a token.
2. Put the URL and token in the `ocsd-sonarqube` context.
3. SonarQube Cloud only: set `sonar.organization` in `sonar-project.properties`.

## 6. Deploy pipeline and environment hierarchy (one-click promotion)

1. **Deploy pipeline:** Project Settings → Deploys → Deploy Pipeline. Create a pipeline that uses `.circleci/deploy.yml` from this repository.
2. **Environments:** these are created automatically the first time a deploy runs. You can also create them up front in Deploys → Environments (custom integrations named `dev`, `test`, `stage`, `prod`).
3. **Hierarchy:** Org → Deploys → Environment Hierarchy → Create new hierarchy. Add the levels in order: dev, test, stage, prod. Set it as the organization default.

When someone clicks Deploy or Promote, CircleCI fills in two values for that pipeline:

- `pipeline.deploy.environment_name` is the environment they picked (`dev`, `test`, `stage`, or `prod`).
- `pipeline.deploy.target_version` is the version they picked.

CircleCI's setup guide still shows `pipeline.deploy.target_environment_name`. The config compiler rejects that name, so this repo uses `environment_name`.

## 7. Config policies

```bash
circleci policy push policies/ --org <ORG_ID>
circleci policy settings set --org <ORG_ID> --enabled
```

Check a config against the rules you just uploaded. The result is `PASS`, `SOFT_FAIL` (a warning, the pipeline still runs), or `HARD_FAIL` (the pipeline is blocked):

```bash
circleci policy decide --org <ORG_ID> --input policies/examples/blocked-no-sonarqube.yml    # HARD_FAIL
circleci policy decide --org <ORG_ID> --input policies/examples/soft-fail-large-machine.yml # SOFT_FAIL
circleci policy decide --org <ORG_ID> --input .circleci/config.yml                          # PASS
circleci policy decide --org <ORG_ID> --input .circleci/deploy.yml                          # PASS
```

To try the rules on a laptop before uploading them, use `circleci policy eval policies/ --input <file>`. A blocked file lists messages for `require_sonarqube_scan` and `no_static_aws_keys`. The large-machine example lists a message for `standard_resource_classes`. The two real configs list neither.

## 8. First run

Push to `main`. The `ci` workflow runs validate, the SonarQube scan and `deploy-dev`. When it finishes, the version appears on the Deploys page in **dev**, ready to promote.

**Backup promotion path:** if the deploy pipeline isn't set up yet, trigger a pipeline on `main` with the parameter `use-approval-promotion: true`. That runs dev → test → stage → prod with an approval before each step.
