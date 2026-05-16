# Agent Instructions

## Overview

This workspace implements proactive MCP (Model Context Protocol) channels — servers that push periodic notifications to Claude rather than responding to tool calls.

## Runtime & Conventions

**Bun only.** See [heartbeat-channel/CLAUDE.md](heartbeat-channel/CLAUDE.md) for the full Bun convention reference (no Node.js, no npm, no express, etc.).

## Project Structure

- `HEARTBEAT.md` — Defines the task the heartbeat channel should relay to Claude. Requires YAML frontmatter with a `schedule` field containing a cron expression (e.g., `schedule: "0 8 * * *"`).
- `heartbeat-channel/` — MCP server that reads `HEARTBEAT.md` and sends its body (frontmatter stripped) as a `notifications/claude/channel` event on the configured cron schedule.

## Common Commands

```bash
cd heartbeat-channel && bun install   # install deps
bun run heartbeat-channel/heartbeat.ts  # run the heartbeat MCP server (stdio transport)
```

## Adding New Channels

Each channel is a standalone MCP server in its own directory. Follow the pattern in `heartbeat-channel/`:
1. Create a directory with `package.json`, `tsconfig.json`, and a main entrypoint.
2. Use `@modelcontextprotocol/sdk` with `StdioServerTransport`.
3. Declare the `claude/channel` experimental capability.
4. Provide clear `instructions` in the Server constructor so Claude knows how to interpret incoming events.
5. Add a `CLAUDE.md` in the channel directory for channel-specific agent conventions.
