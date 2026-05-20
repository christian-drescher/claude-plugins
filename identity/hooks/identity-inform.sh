#!/bin/bash
set -e

IDENTITY_FILE="${CLAUDE_PROJECT_DIR}/IDENTITY.md"

if [[ ! -f "$IDENTITY_FILE" ]]; then
  exit 0
fi

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

IDENTITY_DIR="${CLAUDE_PROJECT_DIR}/.identity"
mkdir -p "$IDENTITY_DIR"

COUNT_FILE="${IDENTITY_DIR}/${SESSION_ID}"
echo "0" > "$COUNT_FILE"

# jq -n --arg hookEventName "$HOOK_EVENT_NAME" --rawfile additionalContext "$IDENTITY_FILE" \
#   '{hookEventName: $hookEventName, additionalContext: $additionalContext}'
cat "$IDENTITY_FILE"

exit 0
