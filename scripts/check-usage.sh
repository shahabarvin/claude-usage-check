#!/bin/sh
# Prints the current Claude plan usage by making one tiny headless Haiku call
# and reading the rate_limit_event from the stream output.

path_exe=$(command -v claude 2>/dev/null)
ext_exe=$(ls -t "$HOME"/.vscode/extensions/anthropic.claude-code-*/resources/native-binary/claude 2>/dev/null | head -n 1)
if [ -z "$path_exe" ] && [ -z "$ext_exe" ]; then
  echo "Claude Code binary not found."
  exit 1
fi

cd "${TMPDIR:-/tmp}" || exit 1

# A CLI on PATH can be too old to emit rate_limit_event, so fall back to the
# binary bundled with the VS Code extension when the first one returns nothing.
event=
for exe in "$path_exe" "$ext_exe"; do
  [ -n "$exe" ] || continue
  event=$("$exe" -p 'reply with just: ok' --model haiku --output-format stream-json --verbose 2>/dev/null | grep '"type":"rate_limit_event"' | tail -n 1)
  [ -n "$event" ] && break
done

if [ -z "$event" ]; then
  echo "No rate limit data returned."
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  printf '%s' "$event" | python3 -c '
import json, sys, time
info = json.load(sys.stdin)["rate_limit_info"]
print("status:", info.get("status"))
windows = info.get("unifiedWindows") or {info.get("rateLimitType"): {"utilization": info.get("utilization"), "resetsAt": info.get("resetsAt")}}
for name, w in windows.items():
    u, r = w.get("utilization"), w.get("resetsAt")
    pct = "n/a" if u is None else "%d%%" % round(u * 100)
    reset = "n/a" if not r else time.strftime("%Y-%m-%d %H:%M", time.localtime(r))
    print("%s: %s used, resets %s (local)" % (name, pct, reset))
'
else
  # No python3: print the raw event. utilization is a fraction, resetsAt is epoch seconds.
  echo "$event"
fi
