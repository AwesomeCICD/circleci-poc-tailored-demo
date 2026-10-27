# Workshop Runbook: Tuesday Nov 3, 2 hours

**Driver:** Eric Lucas (OCSD). **Guide:** Moo Olaniyan (CircleCI).
**Goal:** a solid end-to-end demo that Eric can present to Joe, proving simplicity.

## Before the session (Moo)

- [ ] CircleCI trial turned on for the OCSD org
- [ ] From Eric: sandbox account ID + region, repo name, the existing module to reuse, SonarQube URL (or decide on SonarQube Cloud), attendee list
- [ ] Repo pushed, `docs/SETUP.md` steps 1–7 done or ready to do live
- [ ] Dry run of `circleci policy decide` against the examples

## Agenda

| Time | Block | Outcome |
| --- | --- | --- |
| 0:00–0:10 | Intro, goals, success criteria recap | Everyone knows what "done" looks like |
| 0:10–0:30 | Connect repo, run bootstrap (OIDC + roles + state), create contexts | No AWS keys anywhere |
| 0:30–0:50 | Push to main → validate, SonarQube, deploy dev (network + EC2) | First green deploy on the Deploys page |
| 0:50–1:05 | Create the environment hierarchy, promote dev → test → stage (approval) | Criterion 2: one click with authorization |
| 1:05–1:30 | Bring in Eric's existing module with `_template` + `platform-lookup` | Criterion 3: attaches to existing VPC, subnets, SG and tags, no copy-paste |
| 1:30–1:45 | Config policy demo: push a config without the scan → blocked | Criterion 6 |
| 1:45–1:55 | New-to-CI/CD engineer follows `ZERO_TO_HERO.md` alone, timed | Criterion 1 |
| 1:55–2:00 | Gaps, questions, plan for the presentation to Joe | Date for Joe's presentation |

## Talking points for Eric's open questions

- **"Do I need a branch per environment?"** No. One `main` branch. Environments are a tfvars file plus a state key, and promotion redeploys the same version to the next environment.
- **"How do new modules get existing tags, VPC and subnets?"** `platform-lookup` finds them by tag. Show the before/after comment in `_template/main.tf`.
- **"Cross-platform later (ServiceNow, Azure)?"** CircleCI is general compute. Same pattern with a different provider block and context.
- **"AI in the pipeline?"** A nice-to-have: an agent CLI (Claude Code or Copilot) runs as a job step with its key in a restricted context.

## Capture during the session

- Time taken for the zero-to-hero run: ______
- Pain points Eric hit: ______
- Anything not supported or needing a workaround (log in Canny): ______
