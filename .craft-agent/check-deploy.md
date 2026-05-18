# Cron: Check Latest Deploy

You are the dispatcher tick of the auto-recovery loop. Triggered every 12
minutes by the workspace `SchedulerTick` automation.

## Steps

1. **List recent deploys** via Railway MCP `deployment_list` for service
   `a0ffa020-9ea4-4143-86ea-ef88929f355b` in environment
   `a0aab1ec-fd32-484e-b2f2-af4939bee71d`, project
   `29eb22ed-d272-4b83-bab2-863c95d16452`. Limit 3.
2. **Inspect the most recent deploy.** If status is anything other than
   `FAILED`, STOP — set your status to `done` and exit. No remediation
   needed.
3. **Resolve commit SHA.** Call Railway `deployment_status` for the failed
   deploy and extract the commit SHA. (If unavailable, query GitHub for the
   tip of `main` at the timestamp of the failed deploy.)
4. **Check Supabase for idempotency.** Query
   `public.deploy_remediations` where `commit_sha = '<SHA>'`. If a row
   exists with status in (`spawned`, `pr_opened`, `done`), STOP — already
   handled. Set your status to `done` and exit.
5. **Capture build logs.** Call Railway `deployment_logs` with
   `limit: 80`. Trim to the last 80 lines.
6. **Insert dedup row FIRST** (before spawning, to avoid double-spawn races):
   ```sql
   INSERT INTO public.deploy_remediations (commit_sha, deploy_id, service_id, status)
   VALUES ('<SHA>', '<DEPLOY_ID>', '<SERVICE_ID>', 'spawned')
   ON CONFLICT (commit_sha) DO NOTHING
   RETURNING commit_sha;
   ```
   If the row was NOT returned (conflict), another tick beat us — STOP.
7. **Spawn remediation session.** Use `spawn_session` with:
   - `name`: `auto-fix-<SHORT_SHA>`
   - `labels`: `["auto-remediation", "build-hardening"]`
   - `permissionMode`: `allow-all`
   - `enabledSourceSlugs`: `["github", "railway", "supabase"]`
   - `prompt`: contents of `.craft-agent/remediation-prompt.md` from the
     repo (fetch via GitHub MCP `get_file_contents`), prefixed with a
     block of injected variable values:
     ```
     DEPLOY_ID=<...>
     COMMIT_SHA=<...>
     SERVICE_ID=a0ffa020-9ea4-4143-86ea-ef88929f355b
     PROJECT_ID=29eb22ed-d272-4b83-bab2-863c95d16452
     ENV_ID=a0aab1ec-fd32-484e-b2f2-af4939bee71d
     ---
     BUILD_LOG_TAIL:
     <80 lines>
     ---
     <full template body>
     ```
8. **Record the spawned session id** back into the Supabase row
   (`UPDATE deploy_remediations SET spawned_session_id=$1 WHERE commit_sha=$2`).
9. Set your status to `done`.

## Hard rules

- Be silent unless something fails. The cron fires every 12 min; chatty
  output is noise.
- If Railway MCP / Supabase MCP / GitHub MCP returns an error, set your
  status to `error` and leave a one-line note. Don't retry inline — next
  tick will handle it.
- Never spawn more than one session per tick.
- Never modify the Dockerfile / startup.sh / gmail_server.py yourself.
  Only the spawned remediation session is authorised to push code.
