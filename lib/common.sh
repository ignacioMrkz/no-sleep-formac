#!/bin/bash
# shellcheck shell=bash
set -euo pipefail

NSF_VERSION="1.0.0"
NSF_HOME="${NSF_HOME:-${HOME}/.config/no-sleep-formac}"
NSF_FLAG="${NSF_HOME}/enabled.json"
NSF_STATE="${NSF_HOME}/state.json"
NSF_PMSET_BACKUP="${NSF_HOME}/pmset-backup-c.txt"
NSF_LOG_DIR="${HOME}/Library/Logs/no-sleep-formac"

mkdir -p "${NSF_HOME}" "${NSF_LOG_DIR}"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${NSF_LOG_DIR}/manager.log"
}

notify() {
  local title="$1" msg="$2"
  /usr/bin/osascript -e "display notification \"${msg}\" with title \"${title}\"" 2>/dev/null || true
}

is_flag_on() {
  [[ -f "${NSF_FLAG}" ]] && python3 -c "import json,sys; d=json.load(open('${NSF_FLAG}')); sys.exit(0 if d.get('enabled') else 1)" 2>/dev/null
}

write_flag_on() {
  local mode="${1:-eco}"
  python3 - <<PY
import json, datetime, pathlib
p = pathlib.Path("${NSF_FLAG}")
p.write_text(json.dumps({
    "enabled": True,
    "enabled_at": datetime.datetime.now().isoformat(),
    "mode": "${mode}",
}, indent=2))
PY
  chmod 600 "${NSF_FLAG}"
}

write_flag_off() {
  rm -f "${NSF_FLAG}"
}

read_mode() {
  if [[ -f "${NSF_FLAG}" ]]; then
    python3 -c "import json; print(json.load(open('${NSF_FLAG}')).get('mode','eco'))" 2>/dev/null || echo "eco"
  else
    echo "eco"
  fi
}

on_ac_power() {
  pmset -g batt 2>/dev/null | grep -q "AC Power"
}
