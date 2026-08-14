#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

if [[ -f "${NSF_HOME}/caffeinate.pid" ]]; then
  pid="$(cat "${NSF_HOME}/caffeinate.pid" 2>/dev/null || true)"
  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    kill "${pid}" 2>/dev/null || true
  fi
  rm -f "${NSF_HOME}/caffeinate.pid"
fi

if [[ -f "${NSF_PMSET_BACKUP}" ]]; then
  while IFS= read -r line; do
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    profile="$(echo "${line}" | awk '{print $1}')"
    key="$(echo "${line}" | awk '{print $2}')"
    val="$(echo "${line}" | awk '{print $3}')"
    [[ "${profile}" == "Battery" || "${profile}" == "AC" ]] || continue
    flag="-c"
    [[ "${profile}" == "Battery" ]] && flag="-b"
    /usr/bin/sudo /usr/bin/pmset "${flag}" "${key}" "${val}" 2>/dev/null || true
  done < "${NSF_PMSET_BACKUP}"
else
  /usr/bin/sudo /usr/bin/pmset -c sleep 10 2>/dev/null || true
  /usr/bin/sudo /usr/bin/pmset -c disablesleep 0 2>/dev/null || true
fi

python3 - <<PY
import json, datetime, pathlib
pathlib.Path("${NSF_STATE}").write_text(json.dumps({
    "active": False,
    "disabled_at": datetime.datetime.now().isoformat(),
}, indent=2))
PY

log "headless OFF pmset restored"
