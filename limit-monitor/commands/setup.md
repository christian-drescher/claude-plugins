---
name: setup
description: Toggle the limit-monitor statusline hook in the current project's settings.
allowed-tools:
  - Read
  - Write
  - Bash(mkdir *)
  - Bash(cat *)
---

# /limit-monitor:setup

Toggle the statusline hook for this plugin in the current project.

## What to do

1. Resolve the plugin root path: `${CLAUDE_PLUGIN_ROOT}`
2. Target file: `${CLAUDE_PROJECT_DIR}/.claude/settings.local.json`
3. If the file does not exist or does not contain a `"statusLine"` key, **add** the hook:
   - Ensure the `.claude/` directory exists.
   - Merge into the existing JSON (or create a new object) the following, replacing `PLUGIN_ROOT` with the resolved absolute path from step 1:
     ```json
     {
       "statusLine": {
         "type": "command",
         "command": "\"PLUGIN_ROOT/statusline/statusline.sh\""
       }
     }
     ```
   - Confirm to the user that the statusline hook was enabled.
4. If the file already contains a `"statusLine"` key whose `"command"` references this plugin's `statusline.sh`, **remove** the `"statusLine"` key (leave other keys intact; delete the file if it becomes `{}`).
   - Confirm to the user that the statusline hook was disabled.
