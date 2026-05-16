#!/usr/bin/env bun
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { resolve, dirname } from "path";

const HEARTBEAT_PATH = resolve(dirname(import.meta.filename), "../HEARTBEAT.md");
const INTERVAL_MS = 30 * 60 * 1000; // 30 minutes

const mcp = new Server(
  { name: "heartbeat", version: "0.0.1" },
  {
    capabilities: { experimental: { "claude/channel": {} } },
    instructions:
      'Events from the heartbeat channel arrive as <channel source="heartbeat" type="heartbeat">. ' +
      "They contain the current contents of HEARTBEAT.md and are sent every 30 minutes. " +
      "They are one-way: read them and act accordingly, no reply expected.",
  }
);

await mcp.connect(new StdioServerTransport());

async function sendHeartbeat() {
  try {
    const content = await Bun.file(HEARTBEAT_PATH).text();
    await mcp.notification({
      method: "notifications/claude/channel",
      params: {
        content,
        meta: { type: "heartbeat" },
      },
    });
  } catch (err) {
    console.error(`[heartbeat] Failed to read ${HEARTBEAT_PATH}:`, err);
  }
}

// Fire immediately on startup, then every 30 minutes
await sendHeartbeat();
setInterval(sendHeartbeat, INTERVAL_MS);
