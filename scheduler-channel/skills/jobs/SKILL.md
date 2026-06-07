---
name: jobs
description: Create, edit, list, and delete scheduled jobs. Use to add a new scheduled task, change a job's schedule or instructions, see what jobs exist, or remove a job.
---

# /scheduler-channel:jobs — Scheduled Job Management

Manages job files in the `jobs/` directory. Each job is a Markdown file with
YAML frontmatter that the scheduler reads every 60 seconds.

Arguments passed: `$ARGUMENTS`

---

## Job file format

Every job file lives at `jobs/<name>.md` and must follow this structure:

```
---
schedule: "<cron expression>"
type: "<optional type string>"
---

<body — free-form markdown instructions>
```

- **`schedule`** (required) — A 5-field cron expression: `minute hour dom month dow`.
- **`type`** (optional) — Identifies the job's intent in channel notifications.
  Defaults to the filename stem (e.g. `check-weather.md` → `check-weather`).
- **Body** (required) — Markdown instructions sent verbatim as the channel
  notification content. This is what the agent receives and acts on.

### Cron syntax

The scheduler supports a subset of standard cron:

| Pattern | Meaning | Example |
|---------|---------|---------|
| `*` | Every value | `* * * * *` — every minute |
| `*/N` | Every N-th value | `*/15 * * * *` — every 15 minutes |
| `N-M` | Range inclusive | `*/10 7-21 * * *` — every 10 min, 7 AM–9 PM |
| `N` | Exact value | `0 9 * * *` — 9:00 AM daily |
| `A,B,C` | List | `0,30 * * * *` — on the hour and half-hour |

Combinations work: `*/10 7-21 * * 1-5` (every 10 min, 7–21, weekdays).

**Not supported:** named days/months (`MON`, `JAN`), `@yearly`/`@daily`
shorthands, `L`, `W`, `#`, or 6-field (seconds) expressions.

---

## Dispatch on arguments

Parse `$ARGUMENTS` (space-separated). If empty or unrecognized, show a brief
help summary listing the available subcommands.

### `list`

1. Read the `jobs/` directory.
2. For each `.md` file, read and parse the frontmatter.
3. Show a table: name, schedule, type (or "—" if defaulting to name).

### `show <name>`

1. Read `jobs/<name>.md` (append `.md` if the user omitted it).
2. Display the full contents: schedule, type, and body.
3. Describe in plain language when the job fires (e.g. "every 15 minutes").

### `create <name>`

1. Confirm `<name>` is a valid filename (lowercase alphanumeric, hyphens;
   no spaces or special characters). Append `.md` if not present.
2. If `jobs/<name>.md` already exists, tell the user and stop. Suggest
   `edit` instead.
3. Ask the user for:
   - **Schedule** — a cron expression. Validate it has exactly 5
     space-separated fields and each field uses only the supported syntax.
   - **Type** — optional. If not provided, omit the field (defaults to name).
   - **Body** — the instructions the agent should follow when the job fires.
4. Write `jobs/<name>.md` with the frontmatter and body.
5. Confirm creation and describe when the job will fire next.

### `edit <name>`

1. Read `jobs/<name>.md`. If it doesn't exist, tell the user and stop.
2. Show the current contents.
3. Ask what the user wants to change (schedule, type, body, or all).
4. Apply the changes, preserving any fields the user didn't mention.
5. Write the updated file. Confirm the change.

### `delete <name>`

1. Check `jobs/<name>.md` exists. If not, tell the user and stop.
2. Show the job's current schedule and body so the user can confirm.
3. **Ask for confirmation before deleting.**
4. Delete the file.
5. Confirm deletion.

---

## Implementation notes

- The scheduler re-reads `jobs/` every 60 seconds, so new or edited jobs
  take effect within a minute. No restart needed.
- The `schedule` value must be quoted in the YAML frontmatter (wrap in
  double quotes) because `*` is a YAML special character.
- The frontmatter block must start and end with `---` on its own line, with
  a blank line or content following the closing `---`.
- The `type` value, if provided, should also be quoted if it contains
  special characters — but plain alphanumeric-with-hyphens is fine unquoted.
- Filenames should use kebab-case: `check-weather.md`, not
  `checkWeather.md` or `check_weather.md`.
- Keep job bodies concise. The body is sent as-is in a channel notification
  and the receiving agent must be able to act on it.
