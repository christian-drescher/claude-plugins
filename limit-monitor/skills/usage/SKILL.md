---
name: usage
description: Check current usage quotas, rate-limit pacing, and reset times. Use for information about usage, limits, quota, pacing, rate limits, or when limit resets happen.
---

## Current usage data

!`cat ${CLAUDE_PROJECT_DIR}/.current_usage.md`

## How to read this data

- **Quota used** — percentage of the allowance consumed in the current window (5-hour or 7-day).
- **Pacing** — `(quota_used% / time_elapsed_in_window%) × 100`. Below 100% means usage is on track to stay within the window; above 100% means usage is outpacing the available budget.
- **Reset time** — countdown until the window's quota replenishes.

If the file above is missing or empty, no usage data has been recorded yet.