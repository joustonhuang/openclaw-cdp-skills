# openclaw-cdp-skills

A collection of CDP-based automation skills for OpenClaw.

This repo is the skill layer. Runtime/browser bootstrap lives in:
- https://github.com/joustonhuang/chrome_for_openclaw

## Skills

- `cdp-gmail-delivery` — Gmail delivery workflow with strict compose validation and Google Drive fallback policy.

## Cross-references

- Browser runtime/bootstrap: https://github.com/joustonhuang/chrome_for_openclaw
- Agent browser skill (ClawHub): https://clawhub.ai/hsyhph/openclaw-agent-browser-clawdbot

## Naming convention

- `cdp-<app>-<purpose>`
  - Example: `cdp-gmail-delivery`, `cdp-gdrive-share`, `cdp-gemini-search`
