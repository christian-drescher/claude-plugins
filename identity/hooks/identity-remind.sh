#!/bin/bash
# identity-remind.sh — Periodically reminds the assistant of its identity.
#
# Triggered on: UserPromptSubmit
#
# Tracks a per-session prompt count in .identity/<session_id>. Every 30
# prompts, outputs the first line of IDENTITY.md as a reminder. If no
# IDENTITY.md exists, exits silently.
set -e

IDENTITY_FILE="${CLAUDE_PROJECT_DIR}/IDENTITY.md"

if [[ ! -f "$IDENTITY_FILE" ]]; then
  exit 0
fi

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

# Per-session state directory for tracking prompt counts
IDENTITY_DIR="${CLAUDE_PROJECT_DIR}/.identity"
mkdir -p "$IDENTITY_DIR"

# Initialize count file if this is the first prompt in the session. Shouldn't happen since identity-inform should have already created it, but just in case.
COUNT_FILE="${IDENTITY_DIR}/${SESSION_ID}"
if [[ ! -f "$COUNT_FILE" ]]; then
  echo "0" > "$COUNT_FILE"
fi

count=$(<"$COUNT_FILE")

count=$((count + 1))

echo "$count" > "$COUNT_FILE"

# Remind every 30 prompts to reinforce identity after context drift
if (( count % 30 == 0 )); then
  echo "Reminder: $(head -n 1 "$IDENTITY_FILE")"
fi

exit 0
