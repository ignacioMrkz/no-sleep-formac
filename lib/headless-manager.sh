#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

relaunch_cursor_if_needed() {
  if pgrep -x "Cursor" >/dev/null 2>&1 || pgrep -f "/Applications/Cursor.app" >/dev/null 2>&1; then
    return 0
  fi
  local stamp="${NSF_HOME}/last_cursor_relaunch"
  local now last=0
  now=$(date +%s)
  [[ -f "${stamp}" ]] && last=$(cat "${stamp}")
  if (( now - last > 600 )); then
    log "Cursor not running — relaunch attempt"
    open -a "Cursor" 2>/dev/null || true
    echo "${now}" > "${stamp}"
  fi
}

if is_flag_on; then
  if ! python3 -c "import json; s=json.load(open('${NSF_STATE}')); exit(0 if s.get('active') else 1)" 2>/dev/null; then
    if ! "${SCRIPT_DIR}/headless-on.sh"; then
      log "headless-on failed — rollback"
      "${SCRIPT_DIR}/headless-off.sh" || true
      write_flag_off
      notify "no-sleep-formac" "Enable failed — rolled back"
      exit 1
    fi
    notify "no-sleep-formac" "Headless ON — lid may close"
  fi
  relaunch_cursor_if_needed
else
  if [[ -f "${NSF_STATE}" ]] && python3 -c "import json; s=json.load(open('${NSF_STATE}')); exit(0 if s.get('active') else 1)" 2>/dev/null; then
    "${SCRIPT_DIR}/headless-off.sh"
    notify "no-sleep-formac" "Headless OFF"
  fi
fi

exit 0
