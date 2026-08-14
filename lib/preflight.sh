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

if ! pgrep -x "Cursor" >/dev/null 2>&1 && ! pgrep -f "/Applications/Cursor.app" >/dev/null 2>&1; then
  echo "WARN: Cursor not running. Open Cursor + /remote-control before closing lid."
fi

[[ ${fail} -eq 0 ]] && echo "OK: preflight passed"
exit "${fail}"
