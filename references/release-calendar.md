# Release calendar

Date-bound facts that drive how the agent phrases ongoing and upcoming releases. The skill reads this and chooses the right tense based on the current date.

These are **rules of fact, not rules of style**. They live here, not in `voice.md`, because they age automatically.

---

## Stil Vor Talent — Koletzki remix

| Window | Tense | DE phrasing | EN phrasing |
|---|---|---|---|
| Until **2026-06-30** | Future | "kommt im Juli auf Stil Vor Talent" | "out in July on Stil Vor Talent" |
| **2026-07-01** to **2026-09-30** | Past | "ist gerade auf Stil Vor Talent erschienen" | "just came out on Stil Vor Talent" |
| From **2026-10-01** | Past | (same as above, or generic "released on Stil Vor Talent") | (same as above) |

## Kotori EP — with Oliver Koletzki Remix

| Window | Mention? | Tense | DE phrasing | EN phrasing |
|---|---|---|---|---|
| Until **2026-06-30** | **Do NOT mention** | — | — | — |
| **2026-07-01** to **2026-09-30** | Yes | Future | "im Herbst auf Kotori mit Koletzki Remix" | "this autumn we release an EP on Kotori with an Oliver Koletzki Remix" |
| From **2026-10-01** | Yes | Past | "ist auf Kotori mit Koletzki Remix erschienen" | "out on Kotori with Oliver Koletzki Remix" |

## Updating this file

When a release date firms up:
1. Replace the placeholder date with the actual one
2. Add the release as a fact in `facts.md` once it has happened
3. Audit log entry in `../audit/bible-audits.md`

## Hard rules

- **Never mention Kotori EP before 2026-07-01.** Even if asked.
- **Never invent release timing.** If the date isn't here, the release isn't real to the agent.
