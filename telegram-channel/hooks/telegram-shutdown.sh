#!/bin/bash
set -e

PID_FILE="${CLAUDE_PROJECT_DIR}/.telegram/.bot.pid"

if [[ ! -f "$PID_FILE" ]]; then
  exit 0
fi

PID=$(<"$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
fi

rm -f "$PID_FILE"
