#!/usr/bin/env python3
"""Gmail stdio MCP server for Hermes.

Exposes the five tools the outreach-drafts skill expects:
  - search_threads(query)
  - get_thread(threadId)
  - list_drafts(query)
  - create_draft(to, subject, body, threadId?)
  - delete_draft(draftId)

OAuth credentials are read from env at process start:
  GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET, GMAIL_REFRESH_TOKEN

The refresh token is exchanged for short-lived access tokens on demand by the
google-auth library — no on-disk token cache, no browser flow.

Fail-fast: env vars are validated on import. If any are missing the process
exits with a clear log line rather than KeyError'ing on the first tool call
(which would leave Hermes looking like it has a flaky MCP).
"""

import base64
import logging
import os
import sys
from email.mime.text import MIMEText
from typing import Optional

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from mcp.server.fastmcp import FastMCP

logging.basicConfig(
    level=os.environ.get("GMAIL_MCP_LOG_LEVEL", "INFO"),
    format="%(asctime)s gmail-mcp %(levelname)s %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("gmail-mcp")

REQUIRED_ENV = ("GMAIL_CLIENT_ID", "GMAIL_CLIENT_SECRET", "GMAIL_REFRESH_TOKEN")
_missing = [k for k in REQUIRED_ENV if not os.environ.get(k)]
if _missing:
    log.error("missing required env vars: %s — refusing to start", ", ".join(_missing))
    sys.exit(2)


def _service():
    creds = Credentials(
        token=None,
        refresh_token=os.environ["GMAIL_REFRESH_TOKEN"],
        client_id=os.environ["GMAIL_CLIENT_ID"],
        client_secret=os.environ["GMAIL_CLIENT_SECRET"],
        token_uri="https://oauth2.googleapis.com/token",
    )
    return build("gmail", "v1", credentials=creds, cache_discovery=False)


def _decode(data: str) -> str:
    return base64.urlsafe_b64decode(data + "==").decode("utf-8", errors="replace")


def _extract_body(payload: dict) -> str:
    body_data = payload.get("body", {}).get("data")
    if body_data:
        return _decode(body_data)
    for part in payload.get("parts", []) or []:
        if part.get("mimeType") == "text/plain" and part.get("body", {}).get("data"):
            return _decode(part["body"]["data"])
    for part in payload.get("parts", []) or []:
        nested = _extract_body(part)
        if nested:
            return nested
    return ""


def _api_error(op: str, err: HttpError) -> dict:
    status = getattr(err, "status_code", None) or getattr(err.resp, "status", None)
    log.warning("gmail api %s failed: status=%s reason=%s", op, status, err)
    return {"error": str(err), "status": status, "operation": op}


mcp = FastMCP("gmail")


@mcp.tool()
def search_threads(query: str) -> dict:
    """Search Gmail threads. `query` is a Gmail search expression
    (e.g. 'in:inbox is:unread newer_than:7d', 'to:foo@bar.com OR from:foo@bar.com').
    Returns up to 20 threads with metadata (subject, from, to, date, snippet).
    """
    try:
        svc = _service()
        res = svc.users().threads().list(userId="me", q=query, maxResults=20).execute()
        out = []
        for t in res.get("threads", []):
            full = svc.users().threads().get(
                userId="me", id=t["id"], format="metadata",
                metadataHeaders=["Subject", "From", "To", "Date"],
            ).execute()
            msgs = full.get("messages", [])
            first = msgs[0] if msgs else {}
            hdrs = {h["name"]: h["value"] for h in first.get("payload", {}).get("headers", [])}
            out.append({
                "threadId": t["id"],
                "messageCount": len(msgs),
                "subject": hdrs.get("Subject", ""),
                "from": hdrs.get("From", ""),
                "to": hdrs.get("To", ""),
                "date": hdrs.get("Date", ""),
                "snippet": first.get("snippet", ""),
            })
        return {"threads": out, "count": len(out)}
    except HttpError as err:
        return _api_error("search_threads", err)


@mcp.tool()
def get_thread(threadId: str) -> dict:
    """Fetch a full Gmail thread by ID, including the plain-text body of each message."""
    try:
        svc = _service()
        full = svc.users().threads().get(userId="me", id=threadId, format="full").execute()
        msgs = []
        for m in full.get("messages", []):
            hdrs = {h["name"]: h["value"] for h in m.get("payload", {}).get("headers", [])}
            msgs.append({
                "id": m["id"],
                "from": hdrs.get("From", ""),
                "to": hdrs.get("To", ""),
                "subject": hdrs.get("Subject", ""),
                "date": hdrs.get("Date", ""),
                "labelIds": m.get("labelIds", []),
                "body": _extract_body(m.get("payload", {})),
                "snippet": m.get("snippet", ""),
            })
        return {"threadId": threadId, "messages": msgs}
    except HttpError as err:
        return _api_error("get_thread", err)


@mcp.tool()
def list_drafts(query: Optional[str] = None) -> dict:
    """List Gmail drafts. Optional `query` filters by Gmail search expression
    (e.g. 'to:foo@bar.com'). Returns up to 50 drafts with To, Subject, snippet.
    """
    try:
        svc = _service()
        kwargs = {"userId": "me", "maxResults": 50}
        if query:
            kwargs["q"] = query
        res = svc.users().drafts().list(**kwargs).execute()
        out = []
        for d in res.get("drafts", []):
            m = svc.users().drafts().get(
                userId="me", id=d["id"], format="metadata",
                metadataHeaders=["Subject", "To"],
            ).execute()
            msg = m.get("message", {})
            hdrs = {h["name"]: h["value"] for h in msg.get("payload", {}).get("headers", [])}
            out.append({
                "draftId": d["id"],
                "messageId": msg.get("id"),
                "threadId": msg.get("threadId"),
                "to": hdrs.get("To", ""),
                "subject": hdrs.get("Subject", ""),
                "snippet": msg.get("snippet", ""),
            })
        return {"drafts": out, "count": len(out)}
    except HttpError as err:
        return _api_error("list_drafts", err)


@mcp.tool()
def create_draft(to: str, subject: str, body: str, threadId: Optional[str] = None) -> dict:
    """Create a Gmail draft. Pass `threadId` to thread the draft as a reply."""
    try:
        svc = _service()
        msg = MIMEText(body, _charset="utf-8")
        msg["To"] = to
        msg["Subject"] = subject
        raw = base64.urlsafe_b64encode(msg.as_bytes()).decode("ascii")
        payload = {"message": {"raw": raw}}
        if threadId:
            payload["message"]["threadId"] = threadId
        res = svc.users().drafts().create(userId="me", body=payload).execute()
        return {
            "draftId": res["id"],
            "messageId": res["message"]["id"],
            "threadId": res["message"]["threadId"],
        }
    except HttpError as err:
        return _api_error("create_draft", err)


@mcp.tool()
def delete_draft(draftId: str) -> dict:
    """Delete a Gmail draft by ID."""
    try:
        svc = _service()
        svc.users().drafts().delete(userId="me", id=draftId).execute()
        return {"deletedDraftId": draftId, "ok": True}
    except HttpError as err:
        return _api_error("delete_draft", err)


if __name__ == "__main__":
    log.info("gmail mcp server starting (deps: mcp, google-auth, google-api-python-client)")
    mcp.run()
