---
name: setup
description: Install, update, or remove the limit-monitor statusline hook in the current project's settings.
allowed-tools:
  - Read
  - Write
  - Bash(mkdir *)
  - Bash(cat *)
---

# /limit-monitor:setup

Install, update, or remove the statusline hook for this plugin in the current project.

## Determine intent

- **Install or update** (default): set or overwrite the `"statusLine"` key in project settings.
- **Remove**: only if the user explicitly asks to remove/uninstall the statusline. Delete the `"statusLine"` key.

## Install / Update

1. Resolve the plugin root path: `${CLAUDE_PLUGIN_ROOT}`
2. Target file: `${CLAUDE_PROJECT_DIR}/.claude/settings.local.json`
3. Ensure the `.claude/` directory exists.
4. Read the target file (create `{}` if missing).
5. Set the `"statusLine"` key to the following, replacing `PLUGIN_ROOT` with the resolved absolute path from step 1:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "PLUGIN_ROOT/statusline/statusline.sh"
     }
   }
   ```
   This overwrites any previous `"statusLine"` value, which ensures the command path stays current when the plugin location or version changes.
6. Write the merged JSON back to the target file.
7. Confirm to the user that the statusline hook was installed (or updated if one was already present).

## Remove

Only perform these steps if the user explicitly asks to remove/uninstall the statusline hook.

1. Target file: `${CLAUDE_PROJECT_DIR}/.claude/settings.local.json`
2. Read the target file. If it does not exist, inform the user there is nothing to remove.
3. Delete the `"statusLine"` key from the JSON (leave other keys intact).
4. If the resulting object is empty (`{}`), delete the file.
5. Confirm to the user that the statusline hook was removed.
