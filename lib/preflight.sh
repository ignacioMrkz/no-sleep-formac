#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

fail=0

if ! on_ac_power; then
  echo "FAIL: Mac must be on AC power to enable headless mode."
  fail=1
fi

while IFS= read -r line; do
  [[ "${line}" == ISSUE:* ]] && echo "WARN: ${line#ISSUE:}"
done < <("${SCRIPT_DIR}/health.sh")

if ! any_agent_running; then
  echo "WARN: No configured agent is running (Cursor / Codex / custom in config.json)."
  echo "      Start your agent app or CLI before closing the lid."
fi

[[ ${fail} -eq 0 ]] && echo "OK: preflight passed"
exit "${fail}"
