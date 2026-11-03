# One-time setup

Do this once. It takes about 30 minutes. An AI agent follows this page during [guided setup](../AGENTS.md). A person can follow it alone.

Words used here:

- **CI/CD** means continuous integration and continuous delivery: CircleCI checks the code, then deploys it.
- **AWS** is Amazon Web Services, the cloud account where the servers run.
- **VPC** is a virtual private cloud, a private network inside AWS.
- **OIDC** is OpenID Connect. CircleCI proves which project is running, and AWS returns a short-lived login. No AWS access keys are stored.
- **IAM** is AWS Identity and Access Management, the permission system. A **role** is a permission set a pipeline can borrow.
- **ARN** is an Amazon Resource Name, the ID AWS prints for a role. It looks like `arn:aws:iam::123456789012:role/name`.

## What you need before you start

Collect these. Do not guess.

| Input | Where it is |
| --- | --- |
| AWS account ID | AWS console, account menu, top right. |
| AWS region | You choose it. `us-west-2` is a fine default. A new account allows 5 VPCs per region. In VPC → Your VPCs, count them. If you already have 5, pick another region. |
| GitHub repository | This code, pushed to branch `main`. |
| CircleCI organization ID | Organization Settings → Overview. |
| CircleCI project ID | Project Settings → Overview. Create the project first (step 2). |
| Approver GitHub team | The GitHub team that may approve `stage` and `prod`. |
| Tags | Any tags that must appear on every resource. |
| Teams webhook URL | Optional. Section "Optional: Teams notifications". |

## 1. GitHub

1. Create a repository and push this code to `main`.
2. Install the **CircleCI GitHub App** on the GitHub organization, and give it access to this repository.
3. You should see the repository listed when you add a project in CircleCI.

## 2. CircleCI project

1. In CircleCI, open your organization.
2. Click **Projects**, then set up this repository.
3. Copy the organization ID from **Organization Settings → Overview**.
4. Copy the project ID from **Project Settings → Overview**.
5. You should see both IDs on those Overview pages. You need them for the next step.

## 3. Region, tags, then bootstrap

**Ask the user first** if you are an agent. This apply changes the AWS account. It is the only apply that runs from a laptop. Deploys of `dev`, `test`, `stage`, and `prod` happen in CircleCI, not here.

1. Set `aws_region` in `infra/environments/dev.tfvars`, `test.tfvars`, `stage.tfvars`, and `prod.tfvars` to the same region.
2. Put the required tags in `extra_tags` in those same four files.
3. Sign in to the sandbox AWS account.
4. From the repo root, run:

```bash
cd bootstrap
terraform init
terraform apply \
  -var circleci_org_id=ORG_ID \
  -var circleci_project_id=PROJECT_ID \
  -var aws_region=REGION
```

5. You should see `Apply complete` and two outputs: `tf_state_bucket` and `deploy_role_arns` with one ARN for `dev`, `test`, `stage`, and `prod`. Save them. The next steps paste them into CircleCI.

## CircleCI in the browser

Do these in order. After each one you should see the check written at the end of the step.

### 4. Two pipelines

1. Open **Project Settings → Project Setup**.
2. Pipelines must be **GitHub App** type. If you also see an **OAuth** pipeline, open it and remove every trigger. You should see **0 triggers** on the OAuth pipeline.
3. Open the GitHub App pipeline. This is pipeline 1, the main pipeline. Set the config file to `.circleci/config.yml`. Set the checkout source to this repository. Leave one trigger: **all pushes**. You should see that single trigger and that config path.
4. Click **Add Pipeline**. Name it `deploy`. Set the config file to `.circleci/deploy.yml`. Set the checkout source to this repository. Add **no trigger**. The Deploys page starts this pipeline. You should see `deploy` in the pipeline list with no triggers.

### 5. Choose the deploy pipeline

1. In the left sidebar, click **Deploys**.
2. Open **Deploy Pipeline**.
3. Select **deploy**. Do not select the main pipeline.
4. You should see **deploy** saved as the deploy pipeline.

### 6. Environments

1. Still under **Deploys**, open **Environments**.
2. Click **Create environment integration**.
3. Choose **Custom**.
4. Create four integrations, one at a time, named exactly `dev`, `test`, `stage`, and `prod`.
5. You should see all four names. `dev` may already be there after the first deploy. That is fine. Do not create a second `dev`.

### 7. Environment hierarchy

1. Open **Deploys → Environment Hierarchy**.
2. Create a hierarchy with the levels in this order: `dev`, then `test`, then `stage`, then `prod`.
3. Set that hierarchy as the default.
4. You should see `dev → test → stage → prod` marked as the default. Promote on the Deploys page uses this order.

### 8. Contexts

A context is a named bag of settings for jobs. The names must match the config exactly.

1. Open **Organization Settings → Contexts**.
2. Create `ocsd-aws-dev`, `ocsd-aws-test`, `ocsd-aws-stage`, and `ocsd-aws-prod`.
3. In each one, add these three environment variables. Use that environment's role ARN from the bootstrap output.

| Context | `AWS_ROLE_ARN` | `AWS_REGION` | `TF_STATE_BUCKET` | Who can use it |
| --- | --- | --- | --- | --- |
| `ocsd-aws-dev` | dev role ARN | the region from the tfvars | `tf_state_bucket` | everyone on the project |
| `ocsd-aws-test` | test role ARN | same region | same bucket | everyone on the project |
| `ocsd-aws-stage` | stage role ARN | same region | same bucket | the approver GitHub team only |
| `ocsd-aws-prod` | prod role ARN | same region | same bucket | the approver GitHub team only |

4. On `ocsd-aws-stage` and `ocsd-aws-prod`, open **Security** and add the approver GitHub team. You should see that team listed, and other people should not be able to approve those jobs.
5. `AWS_REGION` must be the same text as `aws_region` in the tfvars files. A mismatch makes the deploy look in the wrong region.

## Optional: Teams notifications

OCSD uses Microsoft Teams, not Slack. When a `stage` or `prod` deploy is waiting, CircleCI can post a message to a channel. The notification never blocks a deploy. Create the context `ocsd-notify` even when you do not have a URL yet. If the variable is unset, the job prints `Teams notification skipped` and stays green. If the context does not exist, that job fails to start, and the approval still proceeds.

The old Office 365 connector webhooks are retired. Use a Teams **Workflows** webhook (Power Automate).

1. In Teams, open the approver channel.
2. Select the channel menu (**...**) → **Workflows**.
3. Choose the template **Post to a channel when a webhook request is received**. If you do not see it, create a flow whose trigger is **When a Teams webhook request is received**, and whose action posts the adaptive card attachments to this channel.
4. Pick this team and this channel. Save the flow.
5. Copy the HTTP URL the flow shows. You should see a long URL that starts with `https://`.
6. In CircleCI, **Organization Settings → Contexts**, create a context named `ocsd-notify`. Do not restrict it to the approver team. The notification job has to read it.
7. Add one environment variable: name `TEAMS_WEBHOOK_URL`, value the URL you copied.
8. Do not paste the URL into Git, into a pull request, or into chat.

The pipeline sends the Adaptive Card envelope documented by Microsoft for that trigger: `type` is `message`, and `attachments` holds one card. See [When a Teams webhook request is received](https://learn.microsoft.com/en-us/connectors/teams/).

The message says which version is waiting, the environment (`stage` or `prod`), and links to `https://app.circleci.com/pipelines/workflows/<workflow id>`. If `TEAMS_WEBHOOK_URL` is missing, the job prints `Teams notification skipped` and exits successfully.

## 9. First deploy, then promote to test

1. Push to `main` if you have not already. **Ask the user first** if you are an agent.
2. Open the project pipelines. You should see workflow `ci` with jobs `validate` and `deploy-dev` green.
3. Open **Deploys**. You should see component `ocsd-poc-infra` with that version in `dev`.
4. Promote it to `test` using [docs/ZERO_TO_HERO.md](ZERO_TO_HERO.md) Part 3. You should see workflow `deploy-test` and job `deploy-from-ui` green.

`stage` and `prod` wait for an approver. That path is [docs/ZERO_TO_HERO.md](ZERO_TO_HERO.md), "Deploying to prod when you're not an approver".

If the deploy pipeline is not set up yet, a backup path exists. Trigger a pipeline on `main` with parameter `use-approval-promotion` set to true. It deploys `dev`, then waits for an approval before `test`, `stage`, and `prod`. Prefer the Deploys page once step 5 is done.

## Optional: config policies

Not part of setup. These rules block static AWS keys and warn on oversized resource classes.

```bash
circleci policy push policies/ --org ORG_ID
circleci policy settings set --org ORG_ID --enabled
```

Check a config against the rules you just uploaded. The result is `PASS`, `SOFT_FAIL` (a warning, the pipeline still runs), or `HARD_FAIL` (the pipeline is blocked):

```bash
circleci policy decide --org ORG_ID --input policies/examples/blocked-static-keys.yml
circleci policy decide --org ORG_ID --input policies/examples/soft-fail-large-machine.yml
circleci policy decide --org ORG_ID --input .circleci/config.yml
circleci policy decide --org ORG_ID --input .circleci/deploy.yml
```

The blocked file fails on `no_static_aws_keys`. The large-machine example warns on `standard_resource_classes`. The two real configs pass both.
