#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

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
  relaunch_agents_if_needed
else
  if [[ -f "${NSF_STATE}" ]] && python3 -c "import json; s=json.load(open('${NSF_STATE}')); exit(0 if s.get('active') else 1)" 2>/dev/null; then
    "${SCRIPT_DIR}/headless-off.sh"
    notify "no-sleep-formac" "Headless OFF"
  fi
fi

exit 0
