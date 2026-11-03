# Add a workload or a new module

Use this page when a new server or a new kind of AWS resource should deploy the same way as the app server. The running environments stay `dev`, `test`, `stage`, and `prod` from branch `main`. You do not copy the network, and you do not find-and-replace names per environment.

`module.platform.name_prefix` is the naming convention. It is `project` plus `environment`, for example `ocsd-poc-dev` or `ocsd-poc-prod`.

## (a) A new workload from the existing server module

A Windows CCTV server is not a new module. It is `infra/modules/ec2-linux` with a name and an operating system. `os` is `linux` (Amazon Linux 2023) or `windows` (Windows Server 2022). The Windows image comes from the public parameter `/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base`. The disk stays encrypted, and the instance still requires IMDSv2 (the instance metadata service, version 2 only).

This example is not on `main`. Copy it in only when you want this server to deploy.

1. Copy `infra/stacks/compute` to `infra/stacks/cctv`.
2. Replace the module block in `infra/stacks/cctv/main.tf` with:

```hcl
module "cctv" {
  source = "../../modules/ec2-linux"

  project     = var.project
  environment = var.environment
  name        = "cctv01"
  os          = "windows"
}
```

3. Add a line `cctv` to `scripts/stacks.txt`.
4. Open a pull request. Do not apply from a laptop. After merge, CircleCI deploys `dev`. Promote with the Deploys page.

The Name tag uses `name_prefix` plus `cctv01`:

- dev: `ocsd-poc-dev-cctv01`
- prod: `ocsd-poc-prod-cctv01`

Windows Server 2022 uses a root disk of at least 30 GB. The module raises the size when `os` is `windows`. The deploy role may already read that Windows image parameter. It may not create anything except EC2, the state files, and those image lookups. If the apply says access denied for a new action, use section (b).

## (b) A brand-new module type

Use this for something `ec2-linux` cannot express, for example Amazon Bedrock AgentCore.

1. Copy `infra/modules/_template` to `infra/modules/<name>`.
2. Paste the resources under the `module "platform"` block.
3. For the network, tags, and name, use only:
   - `module.platform.vpc_id`
   - `module.platform.private_subnet_ids`
   - `module.platform.public_subnet_ids`
   - `module.platform.app_security_group_id`
   - `module.platform.common_tags`
   - `module.platform.name_prefix`
4. Do not paste an ID that starts with `vpc-`, `subnet-`, or `sg-`. `scripts/check-no-hardcoded-ids.sh` fails the pipeline if you do.
5. Copy `infra/stacks/compute` to `infra/stacks/<name>`. Point the module `source` at `../../modules/<name>`. Pass `project` and `environment` only, unless the module needs a short name.
6. Add `<name>` on its own line in `scripts/stacks.txt`.
7. From the repo root, run `terraform fmt -recursive`, `scripts/check-no-hardcoded-ids.sh`, and `scripts/tf.sh <name> dev validate`.
8. Open a pull request.

The deploy roles only allow EC2 actions, AMI parameter reads, and this project's state files. Bedrock, S3, Lambda, API Gateway, and anything like them need their actions added to the `deploy` policy in `bootstrap/main.tf`. **Ask the user first.** An AWS admin re-runs the bootstrap apply or the new permission does not exist, and the CircleCI deploy fails.

Do not run `terraform apply` in `infra/stacks/`. Merge to `main` to deploy `dev`. Promote the rest from the Deploys page ([docs/ZERO_TO_HERO.md](ZERO_TO_HERO.md)).
