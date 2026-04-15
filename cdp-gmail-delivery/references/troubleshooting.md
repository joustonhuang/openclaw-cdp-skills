# Troubleshooting

## Runtime dependency missing (`Unable to load puppeteer-core`)

Symptoms:
- send script exits before connecting to Chrome

Actions:
1. Run `bash skills/cdp-gmail-delivery/scripts/install_runtime.sh`
2. Confirm `skills/cdp-gmail-delivery/.runtime/pupp-mail/node_modules/puppeteer-core` exists
3. Retry the send command

## CDP endpoint unreachable (`ECONNREFUSED 127.0.0.1:9222`)

Symptoms:
- send script fails before opening Gmail

Actions:
1. Run `scripts/restart_debug_chrome.sh`
2. Confirm endpoint:
   - `curl -fsS http://127.0.0.1:9222/json/version`
3. If the endpoint is still unavailable, ask the human operator to help restore the visible debug Chrome session
4. Retry send command

## Gmail still opens Sign-in page in automation

Symptoms:
- browser automation sees Google login page

Actions:
1. Use visible desktop Chrome session started by `restart_debug_chrome.sh`
2. Ask user to log in manually there
3. Re-run send script after login

## Validation failed: duplicate attachment

Symptoms:
- error includes `attachmentOk:false` / occurrence > 1

Actions:
1. Discard existing draft in Gmail
2. Re-open fresh compose
3. Attach only once and retry

## Send toast not shown but maybe sent

Symptoms:
- script times out waiting for "Message sent"

Actions:
1. Search Sent folder by unique subject
2. If found in Sent, treat as sent
3. If not found, retry from fresh compose
