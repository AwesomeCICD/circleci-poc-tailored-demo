# Workshop Runbook: Tuesday Nov 3, 2 hours

**Driver:** Eric Lucas (OCSD). **Guide:** Moo Olaniyan (CircleCI).
**Goal:** a solid end-to-end demo that Eric can present to Joe, proving simplicity.

## Before the session (Moo)

- [ ] CircleCI trial turned on for the OCSD org
- [ ] From Eric: sandbox account ID + region, repo name, the existing module to reuse, attendee list
- [ ] Repo pushed, `docs/SETUP.md` steps 1–6 done or ready to do live
- [ ] Optional: dry run of `circleci policy decide` against the examples

## Agenda

| Time | Block |
| --- | --- |
| 0:00–0:10 | Goals and the three things we're proving |
| 0:10–0:35 | Follow [docs/SETUP.md](SETUP.md): bootstrap, two pipelines, contexts `ocsd-aws-*`, environments, hierarchy. Teams webhook is optional. |
| 0:35–0:55 | Push to main → validate → deploy dev (network and one server). First green deploy on the Deploys page |
| 0:55–1:15 | Promote dev → test → stage (approval) → prod (approval). Approvers get a Teams message when that webhook is set. |
| 1:15–1:35 | Merge `demo/attach-module`, or follow [docs/ADD_A_MODULE.md](ADD_A_MODULE.md). The new module uses `module.platform.name_prefix` and lookup, then promote it |
| 1:35–1:50 | Someone new to CI/CD follows ZERO_TO_HERO alone, timed |
| 1:50–2:00 | Questions, next steps, trial start date |

## Talking points for Eric's open questions

- **"Do I need a branch per environment?"** No. One `main` branch. Environments are a tfvars file plus a state key, and promotion redeploys the same version to the next environment.
- **"How do new modules get existing tags, VPC and subnets?"** `platform-lookup` finds them by tag and exposes `name_prefix`. Show [docs/ADD_A_MODULE.md](ADD_A_MODULE.md). A pasted network ID fails `scripts/check-no-hardcoded-ids.sh`.
- **"Cross-platform later (ServiceNow, Azure)?"** CircleCI is general compute. Same pattern with a different provider block and context.
- **"AI in the pipeline?"** A nice-to-have: an agent CLI (Claude Code or Copilot) runs as a job step with its key in a restricted context.

## Capture during the session

- Time taken for the zero-to-hero run: ______
- Pain points Eric hit: ______
- Anything not supported or needing a workaround (log in Canny): ______
