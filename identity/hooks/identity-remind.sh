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
if [[ ! -f "$COUNT_FILE" ]]; then
  echo "0" > "$COUNT_FILE"
fi

count=$(<"$COUNT_FILE")

count=$((count + 1))

echo "$count" > "$COUNT_FILE"

if (( count % 30 == 0 )); then
  echo "Reminder: $(head -n 1 "$IDENTITY_FILE")"
fi

exit 0
