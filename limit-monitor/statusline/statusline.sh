#!/bin/bash
#
# statusline.sh — Claude Code status-line hook
#
# Called by Claude Code on every turn via the "statusLine" hook. Receives a JSON
# payload on stdin containing model info, context-window usage, and rate-limit
# data. Produces two outputs:
#
#   1. A one-line string on stdout that Claude Code renders in the terminal UI.
#   2. A markdown file (.current_usage.md) in the project directory, consumed by
#      the "usage" skill so the agent can answer questions about current limits.
#
# Pacing formula:
#   pacing% = (quota_used% / time_elapsed_in_window%) × 100
#
#   Derives the window start from the known reset time minus the window duration
#   (5 h = 18 000 s, 7 d = 604 800 s). Values below 100% indicate sustainable
#   consumption; above 100% means usage is outpacing the budget.
#

# 1. Capture the JSON payload coming from Claude Code
PAYLOAD=$(cat)

# 2. Single jq pass: extract fields, compute countdowns, and derive pacing for
#    both the 5-hour and 7-day windows. Output is a single TSV row.
VARS=$(echo "$PAYLOAD" | jq -r '
  # Extract base values with fallbacks
  (.model.display_name // "Unknown") as $model |
  (.context_window.used_percentage // 0) as $ctx |
  (.rate_limits.five_hour.used_percentage // 0) as $f_used |
  (.rate_limits.seven_day.used_percentage // 0) as $s_used |
  (.rate_limits.five_hour.reset_time // "") as $f_reset_iso |
  (.rate_limits.seven_day.reset_time // "") as $s_reset_iso |
  
  # Parse ISO8601 dates to Unix Epochs (fallback to future times if missing)
  (if $f_reset_iso != "" then ($f_reset_iso | fromdateiso8601) else (now + 18000) end) as $f_reset |
  (if $s_reset_iso != "" then ($s_reset_iso | fromdateiso8601) else (now + 604800) end) as $s_reset |
  
  # Calculate remaining seconds (preventing negative values if already reset)
  ([0, $f_reset - now] | max) as $f_delta |
  ([0, $s_reset - now] | max) as $s_delta |
  
  # Round hours up using ceil (e.g., 61 minutes = 2 hours)
  ($f_delta / 3600 | ceil) as $f_total_hours |
  ($s_delta / 3600 | ceil) as $s_total_hours |
  
  # Split 7-day total hours into days and hours
  ($s_total_hours / 24 | floor) as $s_days |
  ($s_total_hours % 24) as $s_hours |
  
  # Format strings
  "\($f_total_hours)h" as $f_rem_str |
  (if $s_days > 0 then "\($s_days)d \($s_hours)h" else "\($s_hours)h" end) as $s_rem_str |
  
  # Calculate 7-day virtual pacing
  ($s_reset - 604800) as $s_start |
  (now - $s_start) as $s_elapsed |
  
  # Clamp elapsed time between 0 and 1 week (604800 seconds)
  (if $s_elapsed < 0 then 0 elif $s_elapsed > 604800 then 604800 else $s_elapsed end) as $s_elapsed_clamped |
  (($s_elapsed_clamped / 604800) * 100) as $s_elapsed_pct |
  
  # Virtual relative percentage = (Quota Used / Time Elapsed) * 100
  # Guard: require >= 1% elapsed to avoid division-by-near-zero at window start
  (if $s_elapsed_pct >= 1 then (($s_used / $s_elapsed_pct) * 100) else 0 end) as $s_virtual |
  
  # Calculate 5-hour virtual pacing
  ($f_reset - 18000) as $f_start |
  (now - $f_start) as $f_elapsed |
  
  # Clamp elapsed time between 0 and 5 hours (18000 seconds)
  (if $f_elapsed < 0 then 0 elif $f_elapsed > 18000 then 18000 else $f_elapsed end) as $f_elapsed_clamped |
  (($f_elapsed_clamped / 18000) * 100) as $f_elapsed_pct |
  
  # Virtual relative percentage = (Quota Used / Time Elapsed) * 100
  # Guard: require >= 1% elapsed to avoid division-by-near-zero at window start
  (if $f_elapsed_pct >= 1 then (($f_used / $f_elapsed_pct) * 100) else 0 end) as $f_virtual |
  
  # Output as tab-separated values (round percentages to integers)
  [ $model, ($ctx|round), ($f_used|round), ($s_used|round), $f_rem_str, $s_rem_str, ($s_virtual|round), ($f_virtual|round), $f_reset_iso ] | @tsv
')

# 3. Destructure the TSV row into named bash variables
IFS=$'\t' read -r MODEL CONTEXT FIVE_USED SEVEN_USED FIVE_REM SEVEN_REM SEVEN_VIRTUAL FIVE_VIRTUAL FIVE_RESET_ISO <<< "$VARS"

# 4. Format the virtual percentages to whole numbers
SEVEN_VIRTUAL_FMT=$(printf "%.0f" "$SEVEN_VIRTUAL")
FIVE_VIRTUAL_FMT=$(printf "%.0f" "$FIVE_VIRTUAL")

# 5. Write structured data for the "usage" skill to read via dynamic injection
cat <<EOF > ${CLAUDE_PROJECT_DIR}/.current_usage.md
Current Usage Limits
- 5-hour pacing: ${FIVE_VIRTUAL_FMT}%
- 5-hour quota used: ${FIVE_USED}% (Resets in: $FIVE_REM)
- 7-day pacing: ${SEVEN_VIRTUAL_FMT}%
- 7-day quota used: ${SEVEN_USED}% (Resets in: $SEVEN_REM)
- 5-hour reset time (raw): ${FIVE_RESET_ISO}
EOF

# 6. Emit the compact status line that Claude Code renders below the prompt
echo "[$MODEL] Ctx: ${CONTEXT}% | 5h: ${FIVE_USED}% Pace: ${FIVE_VIRTUAL_FMT}% (In $FIVE_REM) | 7d: ${SEVEN_USED}% Pace: ${SEVEN_VIRTUAL_FMT}% (In $SEVEN_REM)"