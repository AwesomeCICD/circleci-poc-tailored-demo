# Agent guide for this repository

This file is for a coding agent helping someone who may be new to continuous integration and continuous delivery (CI/CD). If the user says they do not know CircleCI, start with **Guided setup** and do not skip ahead.

Human click paths live in [docs/SETUP.md](docs/SETUP.md). Deploy and promote clicks live in [docs/ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md). New workloads live in [docs/ADD_A_MODULE.md](docs/ADD_A_MODULE.md). Do not invent a second procedure.

## Guided setup (start here if the user is new)

Explain each step in plain words before you do it. Ask for one input at a time. **Ask the user first** before any command that changes Amazon Web Services (AWS), GitHub, or CircleCI.

If this checkout is not already their GitHub repository, do [docs/SETUP.md](docs/SETUP.md) sections 1 and 2 first. **Ask the user first** before `git push`. The CircleCI project ID does not exist until that project exists.

The laptop needs Terraform 1.10 or newer. Run `terraform version`. If it is older, stop and tell the user. Do not apply with an older Terraform. Bootstrap writes `bootstrap/terraform.tfstate` on this machine. Do not commit that file.

Collect these inputs. Do not guess them.

| Input | Where the user finds it |
| --- | --- |
| AWS account ID | AWS console, the account menu at the top right. A 12-digit number. |
| AWS region | Ask. If they have no preference, suggest `us-west-2`. A new account can hold 5 virtual private clouds (VPCs) per region. Before bootstrap, ask to run `aws ec2 describe-vpcs --region REGION --query 'length(Vpcs)'` and `aws service-quotas get-service-quota --service-code vpc --quota-code L-F678F1CE --region REGION --query 'Quota.Value'`. If the count is already at the quota, pick another region. |
| CircleCI organization ID | CircleCI → Organization Settings → Overview. |
| CircleCI project ID | CircleCI → Project Settings → Overview. The project must already exist. |
| Approver GitHub team | The user names the team. It restricts who can approve `stage` and `prod`. |
| Required tags | The user lists every tag key and value. You will write them in `extra_tags`. |
| Teams webhook URL | Optional. Blank is fine. How to create it is [docs/SETUP.md](docs/SETUP.md), section "Optional: Teams notifications". |

Then do these steps, in this order. Wait for the user to say the browser step is done before the next one.

1. **Ask the user first.** Set `aws_region` in `infra/environments/dev.tfvars`, `test.tfvars`, `stage.tfvars`, and `prod.tfvars` to the region they chose. Replace `extra_tags` in those four files with the tags they listed. If they have no required tags, leave the current `extra_tags` and read it back to them. Do not leave a different region in one file. The VPC count command needs the AWS command line already signed in. If it is not, use the console path in [docs/SETUP.md](docs/SETUP.md) instead of guessing a count.
2. **Ask the user first.** This is the only `terraform apply` you ever run, and only in `bootstrap/`. From the repo root:

```bash
cd bootstrap
terraform init
terraform apply \
  -var circleci_org_id=ORG_ID \
  -var circleci_project_id=PROJECT_ID \
  -var aws_region=REGION
```

Read the outputs `tf_state_bucket` and `deploy_role_arns` back to the user. Stop if they say no.

3. Walk [docs/SETUP.md](docs/SETUP.md) from "CircleCI in the browser" through "Contexts", one numbered step at a time. Wait until the user says "done". Always create the context `ocsd-notify`, even with no webhook yet. If they have a URL, add `TEAMS_WEBHOOK_URL`. If they do not, leave that variable unset so the job prints `Teams notification skipped`.
4. **Ask the user first.** Push `main`. Then open the CircleCI pipeline. You should see workflow `ci` with `validate` and `deploy-dev` both green. That is the dev deploy. Do not run `scripts/tf.sh` with `apply`.
5. Walk [docs/ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md) Part 3 so they promote that version to `test`. You should see workflow `deploy-test` and job `deploy-from-ui` green. Do not click for them.

## What this repo is

Terraform for a small AWS environment: a virtual private cloud (VPC), public and private subnets, a security group, and one Amazon Linux Elastic Compute Cloud (EC2) instance.

CircleCI deploys that environment to `dev`, `test`, `stage`, and `prod` from one Git branch, `main`.

## Hard rules

- Do not deploy an environment from a laptop. If the user asks you to run `terraform apply` or `scripts/tf.sh <stack> <env> apply` inside `infra/stacks/`, refuse. Tell them to push `main` for `dev`, or to use the CircleCI Deploys page for `test`, `stage`, and `prod`. `stage` and `prod` need an approver. See [docs/ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md).
- The only `terraform apply` you may run is `bootstrap/`, and only after the user confirms, during guided setup or when they explicitly ask to change AWS permissions.
- Never create a branch per environment. An environment is `infra/environments/<env>.tfvars` plus its own Terraform state file.
- Never hard-code a VPC ID, subnet ID, or security group ID. Never copy-paste a tag block. A new module calls `../platform-lookup` and uses `module.platform.vpc_id`, `module.platform.private_subnet_ids`, `module.platform.public_subnet_ids`, `module.platform.app_security_group_id`, `module.platform.common_tags`, and `module.platform.name_prefix`.
- Never add AWS access keys. Not in code, not in CircleCI config, not in a `.env` file. AWS access is OpenID Connect (OIDC) roles only.
- Do not rename the contexts `ocsd-aws-dev`, `ocsd-aws-test`, `ocsd-aws-stage`, `ocsd-aws-prod`, or `ocsd-notify`. Do not rename the environments `dev`, `test`, `stage`, or `prod`.
- Do not edit `bootstrap/` unless the user explicitly asks to change AWS permissions. A laptop edit does not change the live roles until bootstrap is applied again. **Ask the user first.**

## Repo map

- `.circleci/config.yml` checks every push. On `main` it deploys `dev`. The backup approval workflow is off unless someone sets pipeline parameter `use-approval-promotion` to true.
- `.circleci/deploy.yml` is the pipeline named `deploy`. The Deploys page runs it.
- `bootstrap/` is the one-time AWS setup: the OIDC trust, the deploy roles, and the Terraform state bucket.
- `infra/environments/` holds `dev.tfvars`, `test.tfvars`, `stage.tfvars`, and `prod.tfvars`.
- `infra/modules/network` builds the VPC, subnets, and security group.
- `infra/modules/platform-lookup` finds that network, the shared tags, and `name_prefix`.
- `infra/modules/ec2-linux` is one server. `os` is `linux` (default) or `windows`.
- `infra/modules/_template` is the copy-this starting point for a new kind of module.
- `infra/stacks/` is one deployable unit per module. Today those are `network` and `compute`.
- `scripts/tf.sh` runs Terraform for one stack, one environment, and one action: `plan`, `apply`, or `validate`.
- `scripts/stacks.txt` lists the stacks that deploy, in order.
- `scripts/check-no-hardcoded-ids.sh` fails the build if a VPC, subnet, or security group ID is pasted under `infra/`.
- `policies/` holds optional config policies. They are not part of setup.
- `docs/ZERO_TO_HERO.md`, `docs/SETUP.md`, `docs/ADD_A_MODULE.md`, and `docs/WORKSHOP_RUNBOOK.md`.

## Common tasks

### 1. Add a workload or a new module

Follow [docs/ADD_A_MODULE.md](docs/ADD_A_MODULE.md). Do not add the CCTV example to `main` unless the user asks for that workload. A Windows server is a parameter on `ec2-linux`, not a copied module.

### 2. Change a value for one environment

Edit only `infra/environments/<env>.tfvars`. Instance size is `instance_type`. The network address range is `vpc_cidr`. Do not copy the change into the other three files unless the user wants it everywhere.

### 3. Add or change tags on everything

Edit `extra_tags` in all four files under `infra/environments/`. The stacks apply that block to the resources they create.

### 4. Deploy or promote after setup

You do not apply `infra/stacks/` yourself. Tell the user:

1. Merge to `main`. CircleCI deploys `dev`.
2. Open CircleCI → Deploys → pick the version → Promote → Deploy.
3. For `stage` and `prod`, an approver clicks Approve. If Teams is set up, the `notify-approvers` job posts to the channel and does not block the deploy.

Clicks: [docs/ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md).

### 5. Check work locally before a pull request

These commands do not need AWS credentials and do not change the cloud.

1. From the repo root, run `terraform fmt -recursive`.
2. Run `scripts/check-no-hardcoded-ids.sh`.
3. For each stack you changed, run `terraform init -backend=false && terraform validate` inside that stack directory, or `scripts/tf.sh <stack> dev validate`.

`validate` does not deploy.

### 6. The new resource needs more AWS permissions

The deploy roles allow EC2 actions, reading the Amazon Linux and Windows AMI parameters, and this project's state files. Anything else, such as S3, Lambda, API Gateway, or Amazon Bedrock, needs new actions in the `deploy` policy in `bootstrap/main.tf`.

Tell the user which actions to add. **Ask the user first**, then re-run the bootstrap apply. An edit that is not applied does not change the live role.

## When a CircleCI job fails

Start with [docs/SETUP.md](docs/SETUP.md). Common causes:

- A context name is misspelled. The names are exactly `ocsd-aws-dev`, `ocsd-aws-test`, `ocsd-aws-stage`, `ocsd-aws-prod`, and optionally `ocsd-notify`.
- `AWS_REGION` in the context does not match `aws_region` in that environment's tfvars file.
- Terraform is not formatted, or `scripts/check-no-hardcoded-ids.sh` found a pasted ID.
- The deploy role is missing permission for the new resource type. See task 6.
- The region is already at its VPC limit, so creating another VPC fails.
