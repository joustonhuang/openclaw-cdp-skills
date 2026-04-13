---
name: cdp-gmail-delivery
description: "Send files reliably from an operator-controlled Chrome debug session using Gmail CDP automation with Google Drive share-link fallback. Use when direct channel file delivery fails and the user asks for email delivery. Workflow: restart local debug Chrome, have the operator sign in if needed, connect to 127.0.0.1:9222, validate To/Subject/attachment, send, verify in Sent, and if attachment is blocked switch to Google Drive share link as the default delivery method."
metadata: {"openclaw":{"requires":{"bins":["node","npm"]}}}
---

# Gmail CDP Delivery

Use this workflow when a user asks to deliver a file by Gmail and normal chat delivery fails.

Default policy: for skill bundles or executable-looking archives, prefer Google Drive share links over direct attachments.

UI baseline for this workflow: Google Drive web UI in English (`New` -> `File upload`).

## Required Inputs

- Recipient email
- File path
- Optional body text

## Environment Assumptions

- Chrome debug launcher exists in your repo/workspace:
  - `scripts/restart_debug_chrome.sh`
- Chrome DevTools endpoint is `http://127.0.0.1:9222`
- Node and npm are available
- This skill's runtime dependency is installed once with the bundled installer into `skills/cdp-gmail-delivery/.runtime/pupp-mail`

## Preflight Checklist

- Confirm target file exists and is readable
- Confirm recipient email is explicit
- Confirm CDP endpoint responds (`http://127.0.0.1:9222/json/version`)
- Confirm user login state in visible debug Chrome session

## Workflow

1. Restart the visible debug Chrome session:
   - Run `scripts/restart_debug_chrome.sh` from repo/workspace root
2. If Gmail is not already authenticated in that visible Chrome window, ask the Human operator to sign in manually. So AI Agent will never know what is the login secrets(password / MFA)
3. Send mail over CDP with `scripts/send_via_cdp.js`.
4. Verify send in Sent folder by a unique subject.
5. If Gmail blocks attachment for security reasons, switch immediately to Drive-link delivery (default fallback) using Drive UI path `New` -> `File upload`.

## Non-negotiable Validation

Before clicking Send, validate all of the following in the live compose draft:

- To field contains intended recipient
- Subject is non-empty and unique
- Attachment count is exactly 1 and filename matches requested file

If any check fails, stop and repair draft fields before send.

## Install (one-time)

From the workspace root, run:

```bash
bash skills/cdp-gmail-delivery/scripts/install_runtime.sh
```

What it does:
- Creates `skills/cdp-gmail-delivery/.runtime/pupp-mail`
- Initializes a minimal npm runtime there
- Installs pinned `puppeteer-core@24`

This keeps the runtime local to the skill instead of using an ad hoc `/tmp` path.

## Send Command

```bash
node skills/cdp-gmail-delivery/scripts/send_via_cdp.js \
  --to "recipient@example.com" \
  --file "/absolute/path/to/file.txt" \
  --body "Optional message"
```

## Success Output

The script prints:

- `EMAIL_SENT_OK`
- `SUBJECT=<unique-subject>`
- `TO=<recipient>`
- `FILE_NAME=<basename-only>`

Report success only after these outputs and Sent verification succeed. Do not expose absolute local filesystem paths in success messages.

If recipient reports blocked attachment, do not claim delivered content. Immediately switch to Drive link delivery and report the new share link.

## When to read extra references

- If send flow fails or behaves unexpectedly: read `references/troubleshooting.md`
- If attachments are blocked: read `references/drive-fallback.md`
- If you need incident evidence/context: read `references/receipts.md`

## References

- Runtime model:
  - This workflow uses direct Chrome CDP automation (Puppeteer), not agent-browser.
- Browser runtime/bootstrap foundation:
  - `https://github.com/joustonhuang/chrome_for_openclaw`
  - Script references: `chrome_for_openclaw.sh`, `scripts/restart_debug_chrome.sh`
- Historical script context:
  - `scripts/xrdp_chrome_debug_setup.sh`
  - Git repo context: `https://github.com/joustonhuang/unifai`
- Incident receipts:
  - `references/receipts.md`
- Troubleshooting:
  - `references/troubleshooting.md`
- Drive fallback:
  - `references/drive-fallback.md`
