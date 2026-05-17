#!/usr/bin/env bun
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { resolve } from "path";
import { readdir } from "fs/promises";

const JOBS_DIR = resolve(process.env.CLAUDE_PROJECT_DIR ?? process.cwd(), "jobs");

// --- Frontmatter parsing ---

interface Job {
  name: string;
  schedule: string;
  type: string;
  body: string;
}

function parseFrontmatter(raw: string, filename: string): { schedule: string; type?: string; body: string } {
  const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!match) {
    throw new Error(`${filename} is missing YAML frontmatter (---\\n...\\n---)`);
  }
  const [, yaml, body] = match;
  const scheduleMatch = yaml.match(/^\s*schedule\s*:\s*["']?(.+?)["']?\s*$/m);
  if (!scheduleMatch) {
    throw new Error(`${filename} frontmatter is missing a 'schedule' field`);
  }
  const typeMatch = yaml.match(/^\s*type\s*:\s*["']?(.+?)["']?\s*$/m);
  return { schedule: scheduleMatch[1], type: typeMatch?.[1], body: body.trim() };
}

async function loadJobs(): Promise<Job[]> {
  const entries = await readdir(JOBS_DIR);
  const mdFiles = entries.filter((f) => f.endsWith(".md"));
  const jobs: Job[] = [];
  for (const file of mdFiles) {
    const raw = await Bun.file(resolve(JOBS_DIR, file)).text();
    const { schedule, type, body } = parseFrontmatter(raw, file);
    const name = file.replace(/\.md$/, "");
    jobs.push({ name, schedule, type: type ?? name, body });
  }
  return jobs;
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
  { name: "scheduler", version: "0.0.1" },
  {
    capabilities: { experimental: { "claude/channel": {} } },
    instructions:
      'Scheduled job events arrive as <channel source="scheduler" type="...">. ' +
      "The `type` attribute reflects the job's intent. " +
      "They are one-way: read them and act accordingly, no reply expected unless specified.",
  }
);

await mcp.connect(new StdioServerTransport());

// --- Validate on startup ---

try {
  const jobs = await loadJobs();
  if (jobs.length === 0) {
    throw new Error("No .md job files found in jobs/ directory");
  }
  for (const job of jobs) {
    cronMatches(job.schedule, new Date()); // validate expression parses
    console.error(`[scheduler] Loaded job "${job.name}" (type=${job.type}) with schedule: ${job.schedule}`);
  }
} catch (err) {
  console.error(`[scheduler] Fatal:`, (err as Error).message);
  process.exit(1);
}

// --- Scheduling loop (checks every 60s) ---

const lastSentMinute = new Map<string, number>();

setInterval(async () => {
  try {
    const jobs = await loadJobs();
    const now = new Date();
    const minuteStamp = Math.floor(now.getTime() / 60000);

    for (const job of jobs) {
      if (lastSentMinute.get(job.name) === minuteStamp) continue;

      if (cronMatches(job.schedule, now)) {
        lastSentMinute.set(job.name, minuteStamp);
        await mcp.notification({
          method: "notifications/claude/channel",
          params: {
            content: job.body,
            meta: { type: job.type },
          },
        });
        console.error(`[scheduler] Sent job "${job.name}" at ${now.toISOString()}`);
      }
    }
  } catch (err) {
    console.error(`[scheduler] Error:`, (err as Error).message);
  }
}, 60_000);
