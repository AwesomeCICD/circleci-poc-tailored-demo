# Agent guide for this repository

This file is for a coding agent helping someone who may be new to continuous integration and continuous delivery (CI/CD). Follow the hard rules below. If the user asks you to break one, explain the rule and do not do it.

## What this repo is

Terraform for a small Amazon Web Services (AWS) environment: a virtual private cloud (VPC), public and private subnets, a security group, and one Amazon Linux Elastic Compute Cloud (EC2) instance.

CircleCI deploys that environment to four places: `dev`, `test`, `stage`, and `prod`. All four come from one Git branch, `main`. There is no branch per environment.

## Hard rules

- Never deploy from a laptop. Deploys happen only through CircleCI. A push to `main` deploys `dev`. `test`, `stage`, and `prod` are promoted from the CircleCI Deploys page. `stage` and `prod` need an approval from the approver group before anything changes.
- Never create a branch per environment. An environment is a settings file, `infra/environments/<env>.tfvars`, plus its own Terraform state file.
- Never hard-code a VPC ID, subnet ID, or security group ID. Never copy-paste a tag block. A new module calls `../platform-lookup` and uses `module.platform.vpc_id`, `module.platform.private_subnet_ids`, `module.platform.public_subnet_ids`, `module.platform.app_security_group_id`, and `module.platform.common_tags`.
- Never add AWS access keys. Not in code, not in CircleCI config, not in a `.env` file. AWS access is OpenID Connect (OIDC) roles only. CircleCI proves which project is running, and AWS returns short-lived credentials.
- Do not rename the CircleCI contexts `ocsd-aws-dev`, `ocsd-aws-test`, `ocsd-aws-stage`, or `ocsd-aws-prod`. Do not rename the environments. The pipelines look these names up exactly.
- Do not edit `bootstrap/` unless the user explicitly asks to change AWS permissions. If they do, tell them an AWS admin has to run the bootstrap again. A laptop edit does not change the live roles.

## Repo map

- `.circleci/config.yml` checks every push, and on `main` it deploys `dev`.
- `.circleci/deploy.yml` is what the CircleCI Deploys page runs for Deploy and Promote.
- `bootstrap/` is the one-time AWS setup: the OIDC trust, the deploy roles, and the Terraform state bucket.
- `infra/environments/` holds `dev.tfvars`, `test.tfvars`, `stage.tfvars`, and `prod.tfvars`.
- `infra/modules/network` builds the VPC, subnets, and security group.
- `infra/modules/platform-lookup` finds that network and the shared tags by name. Modules use this instead of pasted IDs.
- `infra/modules/ec2-linux` is the Amazon Linux instance.
- `infra/modules/_template` is the copy-this starting point for a new module.
- `infra/stacks/` is one deployable unit per module. Today those are `network` and `compute`.
- `scripts/tf.sh` runs Terraform for one stack, one environment, and one action: `plan`, `apply`, or `validate`.
- `scripts/stacks.txt` lists the stacks that deploy, in order. A stack not listed here does not ship.
- `policies/` holds optional config policies. They are not part of the core workshop.
- `docs/` holds the human guides: `ZERO_TO_HERO.md`, `SETUP.md`, and `WORKSHOP_RUNBOOK.md`.

## Common tasks

### 1. Add a new module, or bring in an existing one

1. Copy `infra/modules/_template` to `infra/modules/<name>`.
2. Paste the resources into that copy.
3. Replace hard-coded IDs and tags with `module.platform.*` (see Hard rules).
4. Copy `infra/stacks/compute` to `infra/stacks/<name>` and point the module block at `../../modules/<name>`.
5. Add `<name>` on its own line in `scripts/stacks.txt`.
6. Run the local checks in task 5.
7. Open a pull request. Do not merge it, and do not deploy it, unless the user asks.

The deploy roles can create EC2 resources only. If the module needs anything else, do task 6 before expecting a deploy to succeed.

### 2. Change a value for one environment

Edit only `infra/environments/<env>.tfvars`. That is where instance size and the network address range (CIDR) live. Do not copy the change into the other three files unless the user wants it everywhere.

### 3. Add or change tags on everything

Edit `extra_tags` in all four files under `infra/environments/`. The stacks apply that block to the resources they create.

### 4. Deploy or promote

You do not do this. Tell the user the steps, then stop:

1. Merge the change to `main`. CircleCI deploys `dev`.
2. Open CircleCI, then Deploys.
3. Pick the version, then Promote, then Deploy.
4. For `stage` and `prod`, someone in the approver group has to approve first.

The click-by-click version is [docs/ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md).

### 5. Check work locally before a pull request

These commands do not need AWS credentials and do not change the cloud.

1. From the repo root, run `terraform fmt -recursive`.
2. For each stack you changed, run `terraform init -backend=false && terraform validate` inside that stack directory, or from the repo root run `scripts/tf.sh <stack> dev validate`.

`validate` checks that the configuration is readable. It does not deploy.

### 6. The new resource needs more AWS permissions

The deploy roles only allow EC2 actions today. If the user adds something else, such as S3, Lambda, or API Gateway, the CircleCI deploy will fail until the role allows it.

Tell the user which actions to add to the `deploy` policy in `bootstrap/main.tf`. Then tell them an AWS admin must re-run the bootstrap. Do not run that apply yourself.

## When a CircleCI job fails

Start with [docs/SETUP.md](docs/SETUP.md). Common causes:

- A context name is misspelled. The names are exactly `ocsd-aws-dev`, `ocsd-aws-test`, `ocsd-aws-stage`, and `ocsd-aws-prod`.
- `AWS_REGION` in the context does not match `aws_region` in that environment's tfvars file.
- Terraform is not formatted. Run `terraform fmt -recursive` and push again.
- The deploy role is missing permission for the new resource type. See task 6.
- The region is already at its VPC limit, so creating another VPC fails.
