# usage-check

A Claude Code skill that lets Claude check the current plan usage (weekly limit percent and reset time) from inside a session.

It makes it possible to give Claude a usage budget for a task, for example: "keep working until usage reaches 98%, then stop".

## Install

Clone into your personal skills folder:

    git clone https://github.com/shahabarvin/claude-usage-check ~/.claude/skills/usage-check

Windows (PowerShell):

    git clone https://github.com/shahabarvin/claude-usage-check "$HOME\.claude\skills\usage-check"

Start a new Claude Code session, then ask "how much usage is left?" or set a budget in your task.

## How it works

Claude Code in headless mode (`claude -p --output-format stream-json --verbose`) emits a `rate_limit_event` line that contains the plan usage. The script makes one tiny Haiku call and prints that value.

- Needs a recent Claude Code version. 2.1.306 works, 2.0.62 is too old.
- Each check costs one small Haiku message.
- Usually only the weekly window is reported.
- The number is for the account logged in on the machine where it runs.

## Author

Shahab Avin
