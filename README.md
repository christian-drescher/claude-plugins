# christian-drescher-claude-plugins

A plugin marketplace for [Claude Code](https://code.claude.com) that distributes custom plugins.

## Plugins

| Plugin | Description |
|--------|-------------|
| **scheduler-channel** | A one-way MCP channel that pushes scheduled job notifications into a Claude Code session. Jobs are markdown files with cron schedules defined in YAML frontmatter. |
| **telegram-channel** | Bridges a Telegram bot to Claude Code. Forwards messages as channel notifications and exposes reply, react, and edit tools. Includes pairing-based access control. |

## Installation

Add this marketplace:

```bash
claude plugin marketplace add christian-drescher/claude-plugins --scope local
```

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

Always list all channels, e.g., fakechat from  claude-plugins-official:

```bash
claude --channels plugin:fakechat@claude-plugins-official --dangerously-load-development-channels plugin:scheduler-channel@christian-drescher-claude-plugin
```

## Usage

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

## Example

This sends the current time to the fakechat channel.

```yaml
---
schedule: "*/15 * * * *"
type: "heartbeat"
---

Send the current time formatted as HH:MM to the fakechat user.
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
/telegram-channel:access pair <code>/tele
```

### 6. Lock down

Once paired, switch to allowlist mode so strangers can't trigger pairing codes:

```bash
/telegram-channel:access policy allowlist
```
