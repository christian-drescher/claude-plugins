# christian-drescher-claude-plugins

A plugin marketplace for [Claude Code](https://code.claude.com) that turns it into a **personal assistant that never sleeps**.

## Overview

This marketplace provides the building blocks to assemble a highly-customizable personal assistant from scratch, with minimal dependencies. Think of it as an extremely bare OpenClaw variant built directly into Claude Code.

**Key properties:**

- **Telegram integration** — receives and replies to Telegram messages, including images and attachments — lets you talk to your assistant from anywhere.
- **Scheduled tasks** — fires recurring jobs on schedules, including heartbeats.
- **Time-aware** — message time prefixes help the assistant understand daily patterns.
- **Always-on** — run in a terminal multiplexer (`screen`, `tmux`) and it stays active 24/7.
- **No API pricing** — uses your existing Claude Code subscription directly. No Agents SDK, no separate billing. Including Claude subscription changes from June 15, 2026.
- **Built-in memory** — leverages Claude Code's auto-memory for persistent context across sessions.
- **Identity & personality** — create an `IDENTITY.md` to give the assistant a name, tone, and behavioral guidelines that persist across compactions.
- **Modular** — each plugin works independently or in combination. Install only what you need.
- **Extensible** — integrate with any other skill that works with Claude Code.

## Platform & Dependencies

This collection is developed and tested on **Linux**.

| Dependency | Purpose |
|------------|---------|
| [Claude Code](https://code.claude.com) | Host environment |
| [Bun](https://bun.sh) | JavaScript/TypeScript runtime (scheduler-channel, telegram-channel) |
| `bash` | Hook scripts |
| `jq` | JSON parsing in hook scripts (identity) |
| `screen` or `tmux` | Terminal multiplexer for always-on operation (recommended) |

## How it works

| Layer | Plugin | Role |
|-------|--------|------|
| Identity | **identity** | Maintains the assistants's identity in the context window. Ensures the assistant never forgets who it is.  |
| Proactive | **scheduler-channel** | Fires recurring jobs on cron schedules — heartbeats, reminders, data pulls, integrations. |
| Interactive | **telegram-channel** | Receives and replies to Telegram messages — lets you talk to your assistant from anywhere. |

When combined, these plugins form a full-loop assistant: it acts on its own schedule *and* responds to you on demand, with its own personality.

### Giving the assistant an identity

Create an `IDENTITY.md` file in your project root:

```markdown
You are Jarvis, a calm and concise personal assistant.
Respond in English. Keep messages short unless asked for detail.
When reporting weather, include a one-word emoji summary.
```

The `identity` plugin automatically injects this into the context window and keeps it there across compactions and long sessions.

### Defining recurring jobs

Drop `.md` files into the `jobs/` directory. Each file specifies a cron schedule in YAML frontmatter and a task description in the body:

```yaml
---
schedule: "*/10 7-21 * * *"
type: "weather-report"
---

Check the current weather and report it to the user on Telegram.
```

### Running permanently

Start the assistant inside a terminal multiplexer so it survives disconnects:

```bash
screen -S assistant
claude --dangerously-load-development-channels \
  plugin:scheduler-channel@christian-drescher-claude-plugins \
  --dangerously-load-development-channels \
  plugin:telegram-channel@christian-drescher-claude-plugins
```

Detach with `Ctrl-a d`. Reattach anytime with `screen -r assistant`.

## Plugins

| Plugin | Description |
|--------|-------------|
| **identity** | Uses [hooks](https://code.claude.com/docs/en/hooks) to inject the contents of `IDENTITY.md` into the assistants's context window at session start, after context compaction, and a reminder every 30 user messages. |
| **scheduler-channel** | A one-way MCP [channel](https://code.claude.com/docs/en/channels) that pushes scheduled job notifications into a Claude Code session. Jobs are markdown files with cron schedules defined in YAML frontmatter. |
| **telegram-channel** | Fork of [Claude's official Telegram plugin](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/telegram) that bridges a Telegram bot to Claude Code. Forwards messages, including images and attachments, as channel notifications and exposes reply, react, and edit tools. Includes pairing-based access control. |

## Installation

Add this marketplace:

```bash
claude plugin marketplace add christian-drescher/claude-plugins --scope local
```

Each plugin can be installed and used independently — see the sections below. Use both if you want the full-loop assistant.


## identity plugin

Install the plugin:

```bash
claude plugin install identity@christian-drescher-claude-plugins --scope local
```

Create an `IDENTITY.md` in your project root with the assistants's personality and behavioral guidelines:

```markdown
You are Jarvis, a calm and concise personal assistant.
Respond in English. Keep messages short unless asked for detail.
When reporting weather, include a one-word emoji summary.
```

> **Important:** The **first line** of `IDENTITY.md` serves as the assistants's condensed identity. During periodic reminders and after context compaction, only the first line is re-injected to keep context usage minimal while preventing identity drift. Make it a concise, self-contained statement.

The plugin uses hooks to automatically inject this identity into the context window:

- **On session start** — immediately loaded
- **After compaction** — re-injected so the identity survives context trimming
- **Every 30 messages** — periodic reminder (first line only) to prevent drift in long sessions

No configuration needed beyond creating `IDENTITY.md`. The plugin is a no-op if the file doesn't exist.


## scheduler-channel plugin

Create a `jobs/` directory in your project home. This is where the `scheduler-channel` will pick up your scheduled tasks:

```bash
mkdir jobs
```

Install the plugin:

```bash
claude plugin install scheduler-channel@christian-drescher-claude-plugins --scope local
```

Start Claude Code with the development channel flag (required during the research preview for custom channels), if you want :

```bash
claude --dangerously-load-development-channels plugin:scheduler-channel@christian-drescher-claude-plugin
```

### Usage

Drop `.md` files into the `jobs/` directory. Each file needs YAML frontmatter with a `schedule` field (cron expression) and an optional `type` field:

```yaml
---
schedule: "*/30 * * * *"
type: "heartbeat"
---

Your task description here. This body is delivered to Claude as the notification content.
```

If `type` is omitted it defaults to the filename without the `.md` extension.

Events arrive in Claude's context as:

```xml
<channel source="scheduler" type="heartbeat">
Your task description here.
</channel>
```

### Example

This requests the current time.

```yaml
---
schedule: "*/15 * * * *"
type: "heartbeat"
---

Send the current time formatted as HH:MM to the user.
```

## telegram-channel plugin

### 1. Create a Telegram bot

Open [@BotFather](https://t.me/BotFather) on Telegram, send `/newbot`, and follow the prompts. Copy the token (looks like `123456789:AAH...`).

### 2. Install the plugin

```bash
claude plugin install telegram-channel@christian-drescher-claude-plugins --scope local
```

### 3. Save the token

```bash
/telegram-channel:configure 123456789:AAHfiqksKZ8...
```

This writes `TELEGRAM_BOT_TOKEN=...` to `.telegram/.env` in your project root. Restart claude.

### 4. Launch with the channel

```bash
claude --dangerously-load-development-channels plugin:telegram-channel@christian-drescher-claude-plugins
```

Or combined with other channels:

```bash
claude --dangerously-load-development-channels plugin:scheduler-channel@christian-drescher-claude-plugins --dangerously-load-development-channels plugin:telegram-channel@christian-drescher-claude-plugins
```

### 5. Pair

DM your bot on Telegram — it replies with a 6-character code. In your Claude Code session:

```bash
/telegram-channel:access pair <code>
```

### 6. Lock down

Once paired, switch to allowlist mode so strangers can't trigger pairing codes:

```bash
/telegram-channel:access policy allowlist
```

## Recommended but dangerous settings

Add the following settings to `.claude/settings.local.json` if you trust the system and you do not want to approve every single command.

```json
{
  "skipDangerousModePermissionPrompt": true,
  "permissions": {
    "defaultMode": "bypassPermissions"
  }
}
```

## Related projects

- [moazbuilds/claudeclaw](https://github.com/moazbuilds/claudeclaw)
- [aerolalit/claudeclaw](https://github.com/aerolalit/claudeclaw)
- [TerrysPOV/ClaudeClaw-Plus](https://github.com/TerrysPOV/ClaudeClaw-Plus)