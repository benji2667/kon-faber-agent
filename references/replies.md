# Reply classification heuristics

When the responder skill (or outreach skill in the cron run) sees an inbound reply on a thread we initiated, it classifies the reply into one of five buckets: **B1-B5**. Classification is **semantic**, performed by the LLM — but it uses the trigger phrases below as anchors.

The **routing actions** (auto-handle vs manual review vs CRM-only) live in `skills/outreach.py` and `skills/responder.py`. This file only specifies how to *recognise* the bucket.

---

## B1 — Positive interest

The booker shows real interest: asks for more info, proposes a date, asks for fee or tech rider, or says yes.

**DE triggers:**
> "klingt gut", "interessant", "sehr gerne", "was sind eure Konditionen", "habt ihr [Datum] frei", "schickt mir mal", "sendet uns Tech-Rider", "können wir telefonieren"

**EN triggers:**
> "sounds great", "let's talk", "could you send", "what's your fee", "do you have [date]", "call me", "interested", "happy to discuss"

**Classification confidence threshold:** High. The reply must clearly express interest. If ambiguous, classify as B5 instead.

## B2 — Re-Route

The booker passes us to a different person.

**DE triggers:**
> "wende dich an", "sprich mit", "für Booking ist [Name] zuständig", "bitte schreibt [Person]", "leite ich weiter an"

**EN triggers:**
> "please contact", "reach out to", "[Name] handles bookings", "forwarded to", "talk to"

**Classification note:** Pull out the new contact name + ideally email. Surface it in the agent's summary so the human can decide whether to create a new CRM entry.

## B3 — Negative / Decline

A clear no. Polite or terse, but unmistakable.

**DE triggers:**
> "passt aktuell nicht", "kein Slot frei", "ausgebucht", "momentan keine Bewerbungen", "wir buchen nicht selbst", "leider nein", "bei uns sehe ich nichts"

**EN triggers:**
> "no slots available", "fully booked", "not a fit", "we're not taking submissions", "we don't book directly", "unfortunately no"

**Classification note:** "Maybe later" without a concrete window is B5, not B3. B3 must be unambiguous.

## B4 — Out-of-Office / Auto-reply

Automated response. Vacation, parental leave, mailbox closed, etc.

**DE triggers:**
> "abwesend", "Urlaub", "wieder erreichbar ab", "Mutterschutz", "automatische Antwort"

**EN triggers:**
> "out of office", "on vacation", "will be back on", "automatic reply", "away from email"

**Classification note:** If the auto-reply includes a return date, extract it. The skill uses it to set `naechste_aktion` to that date + 1.

## B5 — Unclear

Default bucket when nothing else fits cleanly. Includes:

- Ironic or sarcastic replies that read like a no but aren't certain
- Vague mentions ("interesting…") without commitment
- Counter-questions without signal
- Reply addressing only part of the email
- Anything where classification confidence is low

The skill produces **no draft** for B5. It surfaces the thread for human review with a short summary of what the reply said.

## What this file is NOT

- **Routing rules** — what to do per bucket (auto-draft, CRM update, Telegram card, etc.) lives in the skill code
- **Reply templates** — exemplar drafts for B1 live in `templates.md`
- **The Telegram approval pattern** — that's a separate reusable skill (Phase 7+)
