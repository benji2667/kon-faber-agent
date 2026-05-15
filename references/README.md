# references/

Source of truth for what the Kon Faber outreach agent knows and how it should write. Each file has a single concern.

The agent loads these from `/opt/agent/references/` inside its container (the Dockerfile bakes them in from this folder). Updates flow: edit markdown → git commit → push → Railway redeploys → new content live.

## Files

| File | Concern | Read by |
|---|---|---|
| [voice.md](voice.md) | **The Bible.** Tone, style, sacred lines, voice-level don'ts. | Every outreach run, every reply draft, the reviewer skill |
| [facts.md](facts.md) | **Knowledge base.** Tours, references, achievements, booking contacts. Updated when reality changes. | Outreach run when assembling proof |
| [release-calendar.md](release-calendar.md) | **Date-bound facts.** Release tempus rules with hard cut dates. | Outreach run when phrasing release mentions |
| [templates.md](templates.md) | **Exemplars, not scripts.** 2-3 example mails per touch as voice anchors. | Outreach run for tone calibration; reply skill for B1 starters |
| [replies.md](replies.md) | **Reply heuristics.** B1-B5 classification triggers (semantic anchors for the LLM). | Responder skill, outreach run's reply handling |

## Files that used to live in the Bible but moved

| Moved to | Why |
|---|---|
| `skills/outreach.py` | Cadence (5/16 days), anti-duplicate logic, CRM-sync, AI-pattern regex linter |
| `skills/responder.py` | Reply routing actions (auto-handle, manual review, CRM-only) |
| `../audit/bible-audits.md` | Audit log — operational, not voice |

## Why this split

The previous monolithic `bible-snapshot.md` mixed five concerns: voice, facts, templates, workflow logic, and audit log. The agent loaded everything every run, which:
- Wasted context (anti-duplicate logic doesn't help with *writing*)
- Pushed the agent toward template-following over voice-internalising
- Made the learning loop fuzzy — when a draft was bad, no clean target to fix

Now each concern has its own file. The agent loads only what's relevant per task. The Bible-evolver (Phase 6) proposes edits per file. Updates from Notion (also Phase 6) will sync per page rather than rewriting one giant blob.

## How updates flow

**Manually (now):**
1. Edit the relevant file
2. `git commit -am "voice: ..."` etc.
3. `git push` → Railway auto-rebuilds the container

**Via the Bible-evolver (Phase 6):**
1. Bible-evolver proposes diffs per file based on weekly performance data + voice notes
2. Proposal goes to Telegram with approve/reject
3. On approve: agent commits + pushes the diff
4. Container redeploys with the new content

## Hard rules

- **`voice.md` is the highest authority.** If the agent has to choose between violating a rule in voice.md and following a workflow step, voice wins.
- **Don't fabricate facts.** If `facts.md` or `release-calendar.md` doesn't have something, it doesn't exist as far as the agent is concerned.
- **Templates are anchors, not scripts.** Copy the rhythm and register, not the specific phrasing.
