#!/usr/bin/env bash
set -euo pipefail

CHROME_BIN="${CHROME_BIN:-/opt/google/chrome/chrome}"
DEBUG_PORT="${DEBUG_PORT:-9222}"
USER_DATA_DIR="${USER_DATA_DIR:-/tmp/chrome-little7}"
START_URL="${START_URL:-https://mail.google.com/mail/u/0/#inbox}"
WAIT_SECS="${WAIT_SECS:-5}"
KILL_WAIT_SECS="${KILL_WAIT_SECS:-3}"
DEBUG_LOG="${DEBUG_LOG:-/tmp/chrome-little7-debug.log}"
DEVTOOLS_INFO="${DEVTOOLS_INFO:-/tmp/chrome-little7-devtools.json}"

if [ ! -x "$CHROME_BIN" ]; then
  echo "ERROR: Chrome binary not found or not executable: $CHROME_BIN" >&2
  exit 1
fi

pick_display() {
  local candidates=()
  local d

  if [ -n "${DISPLAY:-}" ]; then
    candidates+=("$DISPLAY")
  fi

  if [ -S /tmp/.X11-unix/X10 ]; then
    candidates+=(":10.0" ":10")
  fi

  if [ -S /tmp/.X11-unix/X0 ]; then
    candidates+=(":0.0" ":0")
  fi

  while IFS= read -r d; do
    candidates+=(":${d}.0" ":${d}")
  done < <(find /tmp/.X11-unix -maxdepth 1 -type s -name 'X*' 2>/dev/null | sed 's#.*/X##' | sort -u)

  local seen="|"
  for d in "${candidates[@]}"; do
    [ -n "$d" ] || continue
    case "$seen" in
      *"|$d|"*) continue ;;
    esac
    seen="${seen}${d}|"
    if DISPLAY="$d" xdpyinfo >/dev/null 2>&1; then
      echo "$d"
      return 0
    fi
  done

  return 1
}

SELECTED_DISPLAY="${DISPLAY:-}"
if ! DISPLAY="$SELECTED_DISPLAY" xdpyinfo >/dev/null 2>&1; then
  if ! SELECTED_DISPLAY="$(pick_display)"; then
    echo "ERROR: Could not find a usable X display." >&2
    echo "Hint: run this from XRDP/local desktop, or set DISPLAY explicitly, e.g." >&2
    echo "  DISPLAY=:10.0 $0" >&2
    exit 3
  fi
fi

echo "==> Restarting Chrome debug session"
echo "    CHROME_BIN=$CHROME_BIN"
echo "    DEBUG_PORT=$DEBUG_PORT"
echo "    USER_DATA_DIR=$USER_DATA_DIR"
echo "    START_URL=$START_URL"
echo "    DISPLAY=$SELECTED_DISPLAY"

echo "==> Stopping existing Chrome processes"
CHROME_KILL_PATTERNS=(
  '^/opt/google/chrome/chrome($| )'
  '^/home/little7/.agent-browser/browsers/.*/chrome($| )'
  '^/opt/google/chrome/chrome_crashpad_handler($| )'
  '^/home/little7/.agent-browser/browsers/.*/chrome_crashpad_handler($| )'
)

for pattern in "${CHROME_KILL_PATTERNS[@]}"; do
  pkill -f "$pattern" 2>/dev/null || true
done
sleep "$KILL_WAIT_SECS"

leftover=0
for pattern in "${CHROME_KILL_PATTERNS[@]}"; do
  if pgrep -f "$pattern" >/dev/null 2>&1; then
    leftover=1
    break
  fi
done

if [ "$leftover" -eq 1 ]; then
  echo "==> Some Chrome processes still alive; sending SIGKILL"
  for pattern in "${CHROME_KILL_PATTERNS[@]}"; do
    pkill -9 -f "$pattern" 2>/dev/null || true
  done
  sleep 1
fi

mkdir -p "$USER_DATA_DIR"

echo "==> Starting Chrome in debug mode"
DISPLAY="$SELECTED_DISPLAY" nohup "$CHROME_BIN" \
  --remote-debugging-port="$DEBUG_PORT" \
  --user-data-dir="$USER_DATA_DIR" \
  --no-first-run \
  --no-default-browser-check \
  "$START_URL" \
  >"$DEBUG_LOG" 2>&1 &

CHROME_PID=$!
echo "==> Chrome launched with PID $CHROME_PID"

echo "==> Waiting ${WAIT_SECS}s for DevTools endpoint"
sleep "$WAIT_SECS"

if command -v curl >/dev/null 2>&1; then
  if curl -fsS "http://127.0.0.1:${DEBUG_PORT}/json/version" >"$DEVTOOLS_INFO" 2>/dev/null; then
    echo "==> DevTools is up"
    echo "    Endpoint: http://127.0.0.1:${DEBUG_PORT}/json/version"
    echo "    Browser URL: http://127.0.0.1:${DEBUG_PORT}"
    echo "    Saved version info: $DEVTOOLS_INFO"
  else
    echo "WARNING: DevTools endpoint did not answer yet on port ${DEBUG_PORT}" >&2
    echo "         Check: $DEBUG_LOG" >&2
    exit 2
  fi
else
  echo "WARNING: curl not found; skipped endpoint verification"
fi

echo "==> Done"
