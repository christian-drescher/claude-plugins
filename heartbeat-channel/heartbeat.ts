#!/usr/bin/env bun
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { resolve, dirname } from "path";

const HEARTBEAT_PATH = resolve(dirname(import.meta.filename), "../HEARTBEAT.md");

// --- Frontmatter parsing ---

function parseFrontmatter(raw: string): { schedule: string; body: string } {
  const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!match) {
    throw new Error("HEARTBEAT.md is missing YAML frontmatter (---\\n...\\n---)");
  }
  const [, yaml, body] = match;
  const scheduleMatch = yaml.match(/^\s*schedule\s*:\s*["']?(.+?)["']?\s*$/m);
  if (!scheduleMatch) {
    throw new Error("HEARTBEAT.md frontmatter is missing a 'schedule' field");
  }
  return { schedule: scheduleMatch[1], body: body.trim() };
}

// --- Minimal cron matcher ---

function fieldMatches(field: string, value: number): boolean {
  // Handle comma-separated list (may contain ranges/steps)
  if (field.includes(",")) {
    return field.split(",").some((part) => fieldMatches(part, value));
  }
  // Wildcard with step: */N
  if (field.startsWith("*/")) {
    const step = parseInt(field.slice(2), 10);
    return value % step === 0;
  }
  // Wildcard
  if (field === "*") return true;
  // Range: N-M
  if (field.includes("-")) {
    const [lo, hi] = field.split("-").map(Number);
    return value >= lo && value <= hi;
  }
  // Exact number
  return parseInt(field, 10) === value;
}

function cronMatches(expr: string, date: Date): boolean {
  const parts = expr.trim().split(/\s+/);
  if (parts.length !== 5) {
    throw new Error(`Invalid cron expression (expected 5 fields): "${expr}"`);
  }
  const [minute, hour, dom, month, dow] = parts;
  return (
    fieldMatches(minute, date.getMinutes()) &&
    fieldMatches(hour, date.getHours()) &&
    fieldMatches(dom, date.getDate()) &&
    fieldMatches(month, date.getMonth() + 1) &&
    fieldMatches(dow, date.getDay())
  );
}

// --- MCP server setup ---

const mcp = new Server(
  { name: "heartbeat", version: "0.0.1" },
  {
    capabilities: { experimental: { "claude/channel": {} } },
    instructions:
      'Events from the heartbeat channel arrive as <channel source="heartbeat" type="heartbeat">. ' +
      "They contain the body of HEARTBEAT.md (frontmatter stripped) and are sent on a cron schedule " +
      "defined in the file's YAML frontmatter. " +
      "They are one-way: read them and act accordingly, no reply expected.",
  }
);

await mcp.connect(new StdioServerTransport());

// --- Validate on startup ---

try {
  const raw = await Bun.file(HEARTBEAT_PATH).text();
  const { schedule } = parseFrontmatter(raw);
  // Validate the expression parses without error
  cronMatches(schedule, new Date());
  console.error(`[heartbeat] Loaded schedule: ${schedule}`);
} catch (err) {
  console.error(`[heartbeat] Fatal:`, (err as Error).message);
  process.exit(1);
}

// --- Scheduling loop (checks every 60s) ---

let lastSentMinute = -1;

setInterval(async () => {
  try {
    const raw = await Bun.file(HEARTBEAT_PATH).text();
    const { schedule, body } = parseFrontmatter(raw);
    const now = new Date();

    // Dedup: only send once per matched minute
    const minuteStamp = Math.floor(now.getTime() / 60000);
    if (minuteStamp === lastSentMinute) return;

    if (cronMatches(schedule, now)) {
      lastSentMinute = minuteStamp;
      await mcp.notification({
        method: "notifications/claude/channel",
        params: {
          content: body,
          meta: { type: "heartbeat" },
        },
      });
      console.error(`[heartbeat] Sent at ${now.toISOString()}`);
    }
  } catch (err) {
    console.error(`[heartbeat] Error:`, (err as Error).message);
  }
}, 60_000);
