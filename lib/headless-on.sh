#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

mode="$(read_mode)"

pmset -g custom > "${NSF_PMSET_BACKUP}" 2>/dev/null || true

/usr/bin/sudo /usr/bin/pmset -c sleep 0
/usr/bin/sudo /usr/bin/pmset -c disablesleep 1
/usr/bin/sudo /usr/bin/pmset -c disksleep 0
/usr/bin/sudo /usr/bin/pmset -c displaysleep 1

caffeinate_pid=""
if [[ "${mode}" == "full" ]]; then
  if [[ ! -f "${NSF_HOME}/caffeinate.pid" ]] || ! kill -0 "$(cat "${NSF_HOME}/caffeinate.pid" 2>/dev/null)" 2>/dev/null; then
    /usr/bin/caffeinate -i -s &
    caffeinate_pid=$!
    echo "${caffeinate_pid}" > "${NSF_HOME}/caffeinate.pid"
  else
    caffeinate_pid="$(cat "${NSF_HOME}/caffeinate.pid")"
  fi
fi

python3 - <<PY
import json, datetime, pathlib
pathlib.Path("${NSF_STATE}").write_text(json.dumps({
    "active": True,
    "mode": "${mode}",
    "caffeinate_pid": "${caffeinate_pid}",
    "applied_at": datetime.datetime.now().isoformat(),
    "version": "${NSF_VERSION}",
}, indent=2))
PY

log "headless ON mode=${mode} caffeinate=${caffeinate_pid:-none}"
