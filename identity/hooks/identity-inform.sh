#!/bin/bash
# identity-inform.sh — Injects assistant's identity at the start of a session.
#
# Triggered on: SessionStart, PostCompact
#
# Outputs the contents of IDENTITY.md so the assistant knows its identity. On a
# resumed session (SessionStart with an existing count file), exits silently
# to avoid repeating the identity. Resets the prompt count to 0 on each run.
# If no IDENTITY.md exists, exits silently.
set -e

IDENTITY_FILE="${CLAUDE_PROJECT_DIR}/IDENTITY.md"

if [[ ! -f "$IDENTITY_FILE" ]]; then
  exit 0
fi

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
HOOK_EVENT_NAME=$(echo "$INPUT" | jq -r '.hook_event_name')

# Per-session state directory for tracking prompt counts
IDENTITY_DIR="${CLAUDE_PROJECT_DIR}/.identity"
mkdir -p "$IDENTITY_DIR"

COUNT_FILE="${IDENTITY_DIR}/${SESSION_ID}"

# If the hook event is SessionStart and the count file already exists, then this is a session resume, so we should not output the identity again.
if [[ "$HOOK_EVENT_NAME" == "SessionStart" && -f "$COUNT_FILE" ]]; then
  exit 0
fi

# Reset prompt count (used by identity-remind.sh)
echo "0" > "$COUNT_FILE"

cat "$IDENTITY_FILE"

exit 0
