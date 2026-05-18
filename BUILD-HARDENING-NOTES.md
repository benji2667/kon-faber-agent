# Build Hardening v1 — Notes

_Branch: `build-hardening-v1` — opened 2026-05-18 by Craft Agent._

## TL;DR

- Phase 4's first deploy failed because the base image lacks both `pip` and `ensurepip`. We hotfixed `main` (commit `2eb177a`) by `apt`-installing `python3-pip` before running pip; deploy `a9016627` then went SUCCESS.
- This branch turns that incident into a durable improvement: pinned versions, real CI, and an autonomous recovery loop so the next surprise gets a PR opened automatically.
- **The PR is opened for review. Do not merge until the CI it introduces has gone green at least once.**

## What was fragile (audit findings)

| File | Problem | Risk |
|---|---|---|
| `Dockerfile` | `FROM nousresearch/hermes-agent:latest` | Base-image drift causes silent breakage (already bit us today: missing pip). |
| `Dockerfile` | `mcp`, `google-auth`, `google-api-python-client` unpinned | A breaking upstream release can fail builds or, worse, ship a runtime regression. |
| `Dockerfile` | No `apt-get clean` / `rm -rf /var/lib/apt/lists/*` | Image bloat. |
| `startup.sh` | `apply_config` swallowed errors with `>/dev/null 2>&1` | Bad config silently dropped; would not show up in logs. |
| `startup.sh` | Missing-env path printed a warn but Hermes booted without MCP servers | Silent functional degradation. |
| `startup.sh` | No guard against missing `gosu` / upstream entrypoint / hermes binary | If the base image rearranges, container loops forever on retry without an actionable log line. |
| `gmail_server.py` | `os.environ["..."]` on every `_service()` call | First Gmail tool call after a missing-env deploy would `KeyError`. We want fail-fast at MCP-server start. |
| `gmail_server.py` | No `HttpError` wrapping | Transient Google API errors propagated as uncaught exceptions to the MCP runtime. |
| Pre-deploy validation | None | A 2-minute `docker build` would have caught the venv & pip errors before Railway ever saw them. |
| `railway.json` | No healthcheck path | Restart-on-failure is the only failure signal. (Left as-is; Hermes does not yet expose a health endpoint.) |

## What changed in this branch

### `Dockerfile`
- Pinned base image to digest `sha256:b6e41c155d6bfce5ad83c5d0fec670086db8a43250e4511c9474134be5482d33` (verified from Docker Hub for `nousresearch/hermes-agent:latest` on 2026-05-18).
- Pinned pip deps: `mcp==1.27.1`, `google-auth==2.53.0`, `google-api-python-client==2.196.0` (latest stable per PyPI on 2026-05-18).
- `apt-get clean && rm -rf /var/lib/apt/lists/*` after install.

### `startup.sh`
- `set -euo pipefail` (was `set -e`).
- Sanity-checks `hermes` binary, upstream entrypoint, and `gosu` up front — emits `FATAL` and exits if any are missing.
- `apply_config` now captures stderr and surfaces it on failure instead of dropping silently.
- The `mcp_servers` skip path now enumerates *every* missing env var by name, and prints a loud `WARN: Hermes will boot WITHOUT Gmail/Supabase MCP. Set these in Railway and redeploy.` line.

### `mcp_servers/gmail_server.py`
- Validates `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN` at module import. Exits with code 2 and a clear stderr line if any are missing (rather than crashing on first tool call).
- Adds a `logging` config to stderr; the MCP runtime captures these per-server.
- Wraps every tool body in `try/except HttpError` and returns `{"error": ..., "status": ..., "operation": ...}` instead of letting exceptions escape.

### `.github/workflows/build.yml`
Four jobs on push & PR to `main`:
- `hadolint` — Dockerfile lint (warning threshold).
- `shellcheck` — `startup.sh` lint.
- `docker-build` — `docker build .` against the same Dockerfile Railway uses, with BuildKit cache (`type=gha`). **This is the load-bearing one** — it would have caught today's failure in ~2 min.
- `python-syntax` — `compileall` + best-effort `pyflakes` against `mcp_servers/`.

`concurrency` cancels superseded runs per ref so a fast-followed push doesn't waste minutes.

## Auto-recovery loop (Goal 2)

### Architecture

```
+--------------------+      every 12 min      +-----------------------------+
| automations.json   |----SchedulerTick------>| dispatcher Craft Agent      |
| SchedulerTick cron |                        | (.craft-agent/check-deploy) |
+--------------------+                        +-----------------------------+
                                                          |
                       Railway: list latest deploy        |
                       Supabase: dedup on commit_sha      |
                                                          | spawn_session
                                                          v
                                              +-----------------------------+
                                              | remediation Craft Agent     |
                                              | (.craft-agent/remediation-) |
                                              | branch  auto-fix/<sha>      |
                                              | open PR to main             |
                                              +-----------------------------+
```

### Files / state

| Where | What |
|---|---|
| `~/.craft-agent/workspaces/kon-faber-1/automations.json` | `SchedulerTick` cron `7,19,31,43,55 * * * *` (~every 12 min, off-the-zero) that spawns the dispatcher in `allow-all` with labels `[auto-recovery, scheduled]`. |
| `.craft-agent/check-deploy.md` (repo) | Dispatcher prompt template. Lists Railway deploys, dedups against Supabase, spawns remediation. |
| `.craft-agent/remediation-prompt.md` (repo) | Remediation prompt template. Diagnoses, fixes, opens a PR, never merges. |
| Supabase `public.deploy_remediations` | PK on `commit_sha`. One row per failed commit we have handled. Statuses: `spawned → pr_opened → done` (or `transient`/`needs-human`). |

### Why this shape

- **Persistence**: workspace `automations.json` outlives a single Claude session. `CronCreate` is session-only, so I deliberately did not use it — the loop would die when this session does.
- **State in Supabase, not in the repo**: a repo file would (a) churn commits every tick and (b) race between concurrent dispatchers. A PK + `ON CONFLICT DO NOTHING` is a one-line idempotency primitive and we already have Supabase wired up.
- **Dispatcher / remediator split**: the dispatcher is small, frequent, and read-mostly; the remediator is heavy, infrequent, and write-heavy. Splitting them means the dispatcher never holds a long-lived context and never accidentally pushes code.
- **No mid-tick retry**: if Railway or Supabase MCP errors, the dispatcher sets its own status to `error` and returns. Next tick handles it. Avoids retry loops inside the cron.

### Idempotency invariants

1. The dispatcher inserts the dedup row **before** spawning, so a double-tick can't double-spawn.
2. The remediation session checks for an existing `commit_sha` row at the very start of its prompt; if status is in (`spawned`, `pr_opened`, `done`), it aborts.
3. Branches are named `auto-fix/<short_sha>`; pushing twice for the same SHA would noop or be caught by GitHub's branch-already-exists.

### What the human still has to do

- Review and merge the PR a remediation session opens. (Hard rule in the prompt: it never merges.)
- For transient classes (5xx, runner exhaustion), confirm by comment, then the remediation session calls `deployment_trigger`.

## Verification log

| Check | Result |
|---|---|
| Emergency hotfix commit `2eb177a` on `main` | pushed |
| Railway deploy `a9016627-464e-4779-901f-c988fa7aeb22` from `2eb177a` | ✅ SUCCESS |
| Supabase table `public.deploy_remediations` exists | ✅ created via migration `create_deploy_remediations` |
| `automations.json` validates | ✅ (one expected warning: `allow-all` for the dispatcher — intentional) |
| Labels `auto-recovery`, `auto-remediation`, `build-hardening`, `scheduled` defined | ✅ added under `development > automation` |

## Open issues / known limitations

- **`public.contacts` has RLS disabled.** The Supabase advisor flagged this when I touched the project; it predates this branch. Surfacing it explicitly: anyone with the anon key can read/write the CRM. Outside the scope of this hardening pass — flag for the human.
- **`public.deploy_remediations` also has RLS disabled.** Intentional for now: the cron uses a service-role PAT and an RLS policy without a backing role would lock it out. If RLS gets enabled on the project broadly, add a policy: `USING (auth.role() = 'service_role')`.
- **No retention on `deploy_remediations`.** Will accumulate one row per failed commit forever. Add a monthly cleanup automation if it grows past a few hundred rows.
- **No notification when the dispatcher gives up.** A failed dispatcher tick sets its status to `error` but doesn't page anyone. Wire a `SessionStatusChange` → Slack webhook if/when a Slack URL is available.
- **No CI gate on PR merging.** The new workflow runs on PRs but I did not enable a branch protection rule (would need a different scope on the PAT). Add `Settings → Branches → main → Require status checks` after the workflow has run once.
- **Base image is still floating-tag-ish in CI.** The Dockerfile pins a digest, but if the digest ages and is GC'd from Docker Hub, the build will start failing. Add a quarterly re-pin to the calendar (or automate it — but that's a future iteration).
- **Hermes restart-policy may mask transient failures.** Railway will retry the deploy up to 5 times before the dispatcher sees a `FAILED`. That's fine, but if `restartPolicyMaxRetries` is raised, the dispatcher will see failures later than it could.

## How to operate this

```
# Manually check the auto-recovery state
psql ... -c "select * from deploy_remediations order by created_at desc limit 10;"

# Manually disable the cron temporarily
craft-agent automation list
craft-agent automation disable <id>

# Pause for a maintenance window
craft-agent automation disable <id>   # before
craft-agent automation enable  <id>   # after
```

## Files this branch touches

- `Dockerfile` (hardened)
- `startup.sh` (hardened)
- `mcp_servers/gmail_server.py` (hardened)
- `.github/workflows/build.yml` (new)
- `.craft-agent/check-deploy.md` (new)
- `.craft-agent/remediation-prompt.md` (new)
- `BUILD-HARDENING-NOTES.md` (this file)

Plus, **outside the repo**, in the workspace:
- `~/.craft-agent/workspaces/kon-faber-1/automations.json` — `SchedulerTick` registered.
- `~/.craft-agent/workspaces/kon-faber-1/labels/config.json` — four new label IDs added.
- Supabase `qjkqcycdyeekacygihac` — table `public.deploy_remediations`.
