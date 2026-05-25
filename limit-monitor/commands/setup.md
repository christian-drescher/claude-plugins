---
name: setup
description: Install or update the limit-monitor statusline hook in the current project's settings.
allowed-tools:
  - Read
  - Write
  - Bash(mkdir *)
  - Bash(cat *)
---

# /limit-monitor:setup

Install or update the statusline hook for this plugin in the current project.

## What to do

1. Resolve the plugin root path: `${CLAUDE_PLUGIN_ROOT}`
2. Target file: `${CLAUDE_PROJECT_DIR}/.claude/settings.local.json`
3. Ensure the `.claude/` directory exists.
4. Read the target file (create `{}` if missing).
5. Set the `"statusLine"` key to the following, replacing `PLUGIN_ROOT` with the resolved absolute path from step 1:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "\"PLUGIN_ROOT/statusline/statusline.sh\""
     }
   }
   ```
   This overwrites any previous `"statusLine"` value, which ensures the command path stays current when the plugin location or version changes.
6. Write the merged JSON back to the target file.
7. Confirm to the user that the statusline hook was installed (or updated if one was already present).
8. If the user explicitly asks to **remove** the hook, delete the `"statusLine"` key from the file (leave other keys intact; delete the file if it becomes `{}`).
