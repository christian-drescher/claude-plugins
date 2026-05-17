# christian-drescher-claude-plugins

A plugin marketplace for [Claude Code](https://code.claude.com) that distributes custom plugins.

## Plugins

| Plugin | Description |
|--------|-------------|
| **scheduler-channel** | A one-way MCP channel that pushes scheduled job notifications into a Claude Code session. Jobs are markdown files with cron schedules defined in YAML frontmatter. |

## Installation

Add this marketplace:

```bash
claude plugin marketplace add christian-drescher/claude-plugins --scope local
```

## scheduler-channel plugin

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
