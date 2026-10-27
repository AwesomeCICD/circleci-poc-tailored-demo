# OCSD CircleCI Proof of Concept

Infrastructure for the Orange County Sheriff's Department (OCSD) CircleCI proof of concept (POC). It deploys a small AWS environment (a VPC, public and private subnets, a security group and an EC2 Linux server) to **dev, test, stage and prod**. Everything comes from **one branch**, and you promote between environments with **one click** on the CircleCI Deploys page.

New to CI/CD? Start with **[docs/ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md)**. You don't need to read the rest of this page.

## How this maps to the POC success criteria

| # | Success criterion | Where it lives |
| --- | --- | --- |
| 1 | Zero to hero deployment | [docs/ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md): log in, pick a version, pick an environment, click Deploy |
| 2 | One-click promotion dev → test → stage → prod, with authorization | [.circleci/deploy.yml](.circleci/deploy.yml) + an environment hierarchy ([docs/SETUP.md](docs/SETUP.md) step 6). Stage and prod require approval from a restricted group |
| 3 | Templates and modules without copy-paste | [infra/modules/platform-lookup](infra/modules/platform-lookup/main.tf) finds the VPC, subnets, security group and tags by lookup. [infra/modules/_template](infra/modules/_template/main.tf) is the starting point for bringing in an existing module |
| 4 | Migrate a critical GitHub Actions pipeline | Use this repo's pattern. The workshop covers mapping the selected workflow |
| 5 | AWS deploys with IAM roles via OIDC (OpenID Connect) | [bootstrap/main.tf](bootstrap/main.tf) creates the trust and roles. Pipelines call `aws-cli/setup` with `role_arn`. No AWS keys are stored in CircleCI |
| 6 | SonarQube scan + config policies | `sonarqube-scan` job in [.circleci/config.yml](.circleci/config.yml), quality-gate check in deploy.yml, rules in [policies/ocsd_guardrails.rego](policies/ocsd_guardrails.rego) |

## How it works

```
push to any branch ──► validate + SonarQube scan + plan (dev)
push to main       ──► validate + SonarQube scan + deploy to dev  ──► version shows on Deploys page
Deploys page       ──► Promote ──► test ──► Promote ──► stage (approval) ──► Promote ──► prod (approval)
```

- **One branch, many environments.** You never create a branch per environment. An environment is just a settings file in `infra/environments/<env>.tfvars` plus a separate state file.
- **New modules attach to what exists.** A module calls `platform-lookup` with the environment name and gets back the VPC ID, subnet IDs, security group ID and the standard tags.
- **Everything is recorded.** Every deploy appears on the Deploys page with its version, environment, who ran it and whether it succeeded.

## Repository layout

```
.circleci/
  config.yml          CI: checks on every push, auto-deploy main to dev
  deploy.yml          Deploy pipeline used by the Deploys page (Promote / Deploy buttons)
bootstrap/            One-time AWS setup: OIDC trust, deploy roles, state bucket
infra/
  environments/       dev.tfvars, test.tfvars, stage.tfvars, prod.tfvars (the only per-env differences)
  modules/
    network/          VPC, public + private subnets, route tables, app security group
    platform-lookup/  Finds an environment's network by tag (no copy-paste of IDs)
    ec2-linux/        Amazon Linux 2023 server that attaches to the environment automatically
    _template/        Copy this to bring an existing OCSD module into the pipeline
  stacks/
    network/          Deploys modules/network
    compute/          Deploys modules/ec2-linux
policies/             Config policies (Rego) + example configs that get blocked
scripts/
  tf.sh               Runs Terraform for <stack> <env> <plan|apply|validate>
  stacks.txt          Which stacks deploy, in order
docs/
  ZERO_TO_HERO.md     Step-by-step guide for people with no CI/CD background
  SETUP.md            One-time setup for admins
  WORKSHOP_RUNBOOK.md Two-hour workshop plan
```

## Adding a new module

1. Copy `infra/modules/_template` to `infra/modules/<name>` and paste in your existing module.
2. Replace hard-coded IDs and tags with `module.platform.*`.
3. Copy `infra/stacks/compute` to `infra/stacks/<name>` and point it at the new module.
4. Add `<name>` to `scripts/stacks.txt`.
5. Open a pull request. CircleCI checks it, and once merged it deploys to dev and can be promoted like everything else.
