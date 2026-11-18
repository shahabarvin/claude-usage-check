---
name: usage-check
description: Check the current Claude plan usage (weekly limit percent used and reset time) from inside a session. Use when the user asks how much usage is left, or gives a usage budget for a task such as "keep working until usage reaches 98%".
---

# Usage check

You cannot run `/usage` yourself, but a headless Claude Code call reports the plan usage in its stream output. The bundled script makes one tiny Haiku call and prints the result.

## Run it

Windows:

    pwsh -NoProfile -File "<skill-dir>/scripts/check-usage.ps1"

macOS / Linux:

    sh "<skill-dir>/scripts/check-usage.sh"

`<skill-dir>` is the folder this SKILL.md is in.

Output:

    status: allowed_warning
    seven_day: 87% used, resets 2026-11-18 04:00 (local)

- `seven_day` is the weekly limit, `five_hour` is the session limit.
- Usually only the weekly window is returned. A missing `five_hour` line is normal, so say that you could not read it instead of guessing.
- `status` is `allowed`, `allowed_warning` (past 75%), or a rejected state when the limit is hit.

## Working under a usage budget

When the user sets a limit such as "continue until 98%":

1. Check once before starting. If usage is already at or over the limit, stop and say so.
2. Check again at natural checkpoints: after each finished unit of work, and before starting anything large. Check more often as usage gets close to the limit, because one long step can add several percent.
3. Each check costs one small Haiku message, so do not check after every tool call.
4. When usage reaches the limit, stop at the next safe point: leave the work in a consistent state, then report what is done, what is left, the current percent, and the reset time.
5. If a check fails or returns no data, tell the user. Do not assume there is budget left.

## If the script fails

Run the underlying command from a temporary directory and read the line with `"type":"rate_limit_event"`:

    claude -p "reply with just: ok" --model haiku --output-format stream-json --verbose

- `rate_limit_info.unifiedWindows.<window>.utilization` is a fraction (0.87 means 87%).
- `rate_limit_info.unifiedWindows.<window>.resetsAt` is the reset time in Unix epoch seconds.
- Old Claude Code versions (for example 2.0.62) do not emit this event. 2.1.306 does. If `claude` on PATH is old or missing, use the binary bundled with the VS Code extension: `~/.vscode/extensions/anthropic.claude-code-*/resources/native-binary/claude` (`claude.exe` on Windows).
- The number is for the account logged in on this machine.
