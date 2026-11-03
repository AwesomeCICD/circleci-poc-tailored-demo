# OCSD CircleCI Proof of Concept

## Start here

- New to all of this → [docs/ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md)
- Setting it up with an AI agent → Point the agent at this repo. It reads [AGENTS.md](AGENTS.md). Claude Code reads [CLAUDE.md](CLAUDE.md), which imports that file.
- Setting it up by hand → [docs/SETUP.md](docs/SETUP.md)
- Adding a new workload or module → [docs/ADD_A_MODULE.md](docs/ADD_A_MODULE.md)

Infrastructure for the Orange County Sheriff's Department (OCSD) CircleCI proof of concept (POC). It deploys a small Amazon Web Services (AWS) environment (a virtual private cloud, public and private subnets, a security group, and an Elastic Compute Cloud server) to **dev, test, stage, and prod**. Everything comes from **one branch**, and you promote between environments with **one click** on the CircleCI Deploys page.

## How this maps to the POC success criteria

| # | Success criterion | Where it lives |
| --- | --- | --- |
| 1 | Zero to hero deployment | [docs/ZERO_TO_HERO.md](docs/ZERO_TO_HERO.md): log in, pick a version, pick an environment, click Deploy |
| 2 | One-click promotion dev → test → stage → prod, with authorization | [.circleci/deploy.yml](.circleci/deploy.yml) and the environment hierarchy in [docs/SETUP.md](docs/SETUP.md). Stage and prod require approval from a restricted group. A Teams message is optional and needs no extra CircleCI context. |
| 3 | Templates and modules without copy-paste | [infra/modules/platform-lookup](infra/modules/platform-lookup/main.tf) finds the network, tags, and name prefix. Walkthrough: [docs/ADD_A_MODULE.md](docs/ADD_A_MODULE.md) |
| 4 | Migrate a critical GitHub Actions pipeline | Use this repo's pattern. The workshop covers mapping the selected workflow |
| 5 | AWS deploys with IAM roles via OIDC (OpenID Connect) | [bootstrap/main.tf](bootstrap/main.tf) creates the trust and roles. Pipelines call `aws-cli/setup` with `role_arn`. No AWS keys are stored in CircleCI |
| 6 | Config policies (optional) | [policies/ocsd_guardrails.rego](policies/ocsd_guardrails.rego). Not part of the core workshop |

## How it works

```
push to any branch ──► validate + plan (dev)
push to main       ──► validate + deploy to dev  ──► version shows on Deploys page
Deploys page       ──► Promote ──► test ──► Promote ──► stage (approval) ──► Promote ──► prod (approval)
```

- **One branch, many environments.** You never create a branch per environment. An environment is just a settings file in `infra/environments/<env>.tfvars` plus a separate state file.
- **New modules attach to what exists.** A module calls `platform-lookup` and gets back the network, the tags, and `name_prefix`. A pasted VPC, subnet, or security group ID fails `scripts/check-no-hardcoded-ids.sh` on every push.
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
    ec2-linux/        One server. Linux by default, or Windows with os = "windows"
    _template/        Copy this to bring an existing OCSD module into the pipeline
  stacks/
    network/          Deploys modules/network
    compute/          Deploys modules/ec2-linux
policies/             Optional config policies (Rego) + example configs that get blocked
scripts/
  tf.sh               Runs Terraform for <stack> <env> <plan|apply|validate>
  stacks.txt          Which stacks deploy, in order
  check-no-hardcoded-ids.sh   Fails if infra/ contains a pasted network ID
  notify-teams.sh     Optional Teams post. Skips when TEAMS_WEBHOOK_URL is unset
docs/
  ZERO_TO_HERO.md     Deploy and promote in the browser, no commands
  SETUP.md            One-time setup
  ADD_A_MODULE.md     Add a workload or a new module
  WORKSHOP_RUNBOOK.md Two-hour workshop plan
```

## Adding a new module

Follow [docs/ADD_A_MODULE.md](docs/ADD_A_MODULE.md). An agent reads `AGENTS.md` (Claude Code reads `CLAUDE.md`, which imports it) and uses that same page.
