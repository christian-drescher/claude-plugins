#!/bin/bash
set -e

IDENTITY_FILE="${CLAUDE_PROJECT_DIR}/IDENTITY.md"

if [[ ! -f "$IDENTITY_FILE" ]]; then
  exit 0
fi

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
HOOK_EVENT_NAME=$(echo "$INPUT" | jq -r '.hook_event_name')

IDENTITY_DIR="${CLAUDE_PROJECT_DIR}/.identity"
mkdir -p "$IDENTITY_DIR"

COUNT_FILE="${IDENTITY_DIR}/${SESSION_ID}"
if [[ ! -f "$COUNT_FILE" ]]; then
  echo "0" > "$COUNT_FILE"
fi

count=$(<"$COUNT_FILE")

if [[ "$HOOK_EVENT_NAME" == "SessionStart" ]]; then
  count=0
elif [[ "$HOOK_EVENT_NAME" == "PostCompact" ]]; then
  count=-1
else
  count=$((count + 1))
fi

echo "$count" > "$COUNT_FILE"

if (( count % 100 == 0 )); then
  jq -n --arg hookEventName "$HOOK_EVENT_NAME" --rawfile additionalContext "$IDENTITY_FILE" \
    '{hookEventName: $hookEventName, additionalContext: $additionalContext}'
fi

exit 0
