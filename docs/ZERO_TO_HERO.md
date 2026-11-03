# Zero to Hero: Deploying with CircleCI

This guide is for someone who has never used CI/CD (continuous integration and continuous delivery) or Git. By the end you will have deployed infrastructure to an environment and promoted it to the next one. You will not write any code or type any commands.

**Time:** about 15 minutes.
**You need:** a GitHub account that OCSD has added to the organization, and a web browser.

## Words you will see

| Word | What it means |
| --- | --- |
| **CircleCI** | The tool that runs our automated checks and deployments. |
| **Git / GitHub** | Where the code is stored, with a history of every change. |
| **Repository (repo)** | One project's folder of code in GitHub. Ours is `ocsd-circleci-poc`. |
| **Pipeline** | One automated run: check the code, then deploy it. |
| **Deploy** | Build or update the real infrastructure in AWS (Amazon Web Services). |
| **Environment** | A separate copy of the infrastructure: **dev** (development), **test**, **stage** (staging, a final rehearsal) and **prod** (production, the real thing). |
| **Version** | A specific saved state of the code, shown as a short code like `a1b2c3d`. |
| **Promote** | Take the version already running in one environment and deploy it to the next one. |
| **Approval** | A person with permission must click Approve before stage or prod changes. |

## Part 1: Log in (2 minutes)

1. Go to **https://app.circleci.com**.
2. Click **Log in with GitHub** and sign in with your GitHub account.
3. If asked, pick the **OCSD** organization.

## Part 2: See what is deployed (2 minutes)

1. In the left sidebar, click **Deploys**.
2. Find the component **ocsd-poc-infra**. Each row is a version, and you can see which environments it is running in.
3. A green check means the deploy succeeded. Red means it failed. You can click any row to see details.

## Part 3: Deploy or promote a version (5 minutes)

1. On the Deploys page, find the version you want. Usually that's the newest one running in **dev**.
2. Click the **Promote** icon next to it.
3. The promotion page shows the environments in order: dev → test → stage → prod. Click **Promote** to move the version to the next environment.
4. A window opens with the version and target environment already filled in. Check them, then click **Deploy**.
5. That's it. CircleCI now:
    - logs in to AWS with a short-lived permission (no passwords or keys are stored),
    - builds or updates the infrastructure,
    - and marks the deploy green or red on the Deploys page.

## Part 4: Stage and prod need an approval (3 minutes)

Promoting to **stage** or **prod** pauses for approval.

1. After clicking Deploy, open the pipeline from the link on the Deploys page.
2. You'll see a job named **approve-stage** or **approve-prod** with a **Hold** status.
3. Someone in the authorized group clicks it, then clicks **Approve**. If you're not in that group, the button won't work for you. That's expected, and it's how OCSD controls who changes production.
4. After approval, the deploy runs and the result shows on the Deploys page.

## Part 5: If something goes wrong

- **Red deploy:** click it, then click the failed step to read the message. Send the link to the platform team.
- **"Pipeline blocked by policy":** the change broke an OCSD rule, for example by storing AWS keys in the config. Nothing was deployed. Send the message to whoever made the change.
- **Need to go back:** on the Deploys page, pick the previous green version and deploy it to the same environment.

## What you just did

You deployed infrastructure through four environments without copying files, creating branches or typing commands. Every step was checked, authorized and recorded.
