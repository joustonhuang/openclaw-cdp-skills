---
name: cdp-gmail-delivery
description: Send files reliably from an operator-controlled Chrome debug session using Gmail CDP automation with Google Drive share-link fallback. Use when direct channel file delivery fails and the user asks for email delivery. Workflow: restart debug Chrome with restart_debug_chrome.sh, let user sign in, connect over CDP (9222), validate To/Subject/attachment, send, verify in Sent, and if attachment is blocked switch to Google Drive share link as default delivery method.
---

# Gmail CDP Delivery

Use this workflow when a user asks to deliver a file by Gmail and normal chat delivery fails.

Default policy: for skill bundles or executable-looking archives, prefer Google Drive share links over direct attachments.

## Required Inputs

- Recipient email
- File path
- Optional body text

## Environment Assumptions

- Chrome debug launcher exists at:
  - `/home/little7/.openclaw/workspace/scripts/restart_debug_chrome.sh`
- Chrome DevTools endpoint is `http://127.0.0.1:9222`
- Node is available
- `puppeteer-core` can be installed in `/tmp/pupp-mail`

## Workflow

1. Restart the visible debug Chrome session:
   - Run `/home/little7/.openclaw/workspace/scripts/restart_debug_chrome.sh`
2. Ask user to complete Gmail login in that visible window.
3. Send mail over CDP with `scripts/send_via_cdp.js`.
4. Verify send in Sent folder by a unique subject.
5. If Gmail blocks attachment for security reasons, upload to Google Drive and send a share link instead (this is the default fallback).

## Non-negotiable Validation

Before clicking Send, validate all of the following in the live compose draft:

- To field contains intended recipient
- Subject is non-empty and unique
- Attachment count is exactly 1 and filename matches requested file

If any check fails, stop and repair draft fields before send.

## Install (one-time)

```bash
mkdir -p /tmp/pupp-mail
cd /tmp/pupp-mail
npm init -y
npm install puppeteer-core@24
```

## Send Command

```bash
node /home/little7/.openclaw/workspace/skills/cdp-gmail-delivery/scripts/send_via_cdp.js \
  --to "recipient@example.com" \
  --file "/absolute/path/to/file.txt" \
  --body "Optional message"
```

## Success Output

The script prints:

- `EMAIL_SENT_OK`
- `SUBJECT=<unique-subject>`
- `TO=<recipient>`
- `FILE=<file-path>`

Report success only after these outputs and Sent verification succeed.

If recipient reports blocked attachment, do not claim delivered content. Immediately switch to Drive link delivery and report the new share link.

## References

- Agent-browser skill used in the same recovery context:
  - `skills/agent-browser-clawdbot/SKILL.md`
- Shell script source reference (repo context from your environment):
  - `scripts/xrdp_chrome_debug_setup.sh` and `scripts/restart_debug_chrome.sh`
  - Git repo context: `https://github.com/joustonhuang/unifai`
- Incident receipts:
  - `references/receipts.md`
