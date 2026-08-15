#!/bin/bash
# Agent detection / optional relaunch — driven by config.json (no hardcoded single IDE).
# shellcheck shell=bash

NSF_CONFIG="${NSF_HOME}/config.json"
NSF_CONFIG_EXAMPLE="${NSF_REPO_ROOT:-}/config.example.json"

ensure_config() {
  if [[ ! -f "${NSF_CONFIG}" ]]; then
    local src=""
    if [[ -n "${NSF_REPO_ROOT:-}" && -f "${NSF_REPO_ROOT}/config.example.json" ]]; then
      src="${NSF_REPO_ROOT}/config.example.json"
    elif [[ -f "${SCRIPT_DIR:-}/../../config.example.json" ]]; then
      src="${SCRIPT_DIR}/../../config.example.json"
    fi
    if [[ -n "${src}" && -f "${src}" ]]; then
      cp "${src}" "${NSF_CONFIG}"
      chmod 600 "${NSF_CONFIG}"
    else
      # Minimal built-in default if example is missing
      cat > "${NSF_CONFIG}" <<'JSON'
{
  "relaunch": true,
  "relaunch_cooldown_seconds": 600,
  "agents": [
    {"id": "cursor", "label": "Cursor", "match": ["Cursor"], "open": "Cursor", "relaunch": true},
    {"id": "codex", "label": "Codex (ChatGPT app)", "match": ["ChatGPT", "Codex"], "open": "ChatGPT", "relaunch": true}
  ]
}
JSON
      chmod 600 "${NSF_CONFIG}"
    fi
  fi
}

# Returns JSON array of agent objects via stdout
agents_json() {
  ensure_config
  python3 - <<'PY'
import json, pathlib, os
p = pathlib.Path(os.environ["NSF_CONFIG"])
data = json.loads(p.read_text())
print(json.dumps(data.get("agents") or []))
PY
}

config_relaunch_enabled() {
  ensure_config
  python3 - <<'PY'
import json, pathlib, os, sys
data = json.loads(pathlib.Path(os.environ["NSF_CONFIG"]).read_text())
sys.exit(0 if data.get("relaunch", True) else 1)
PY
}

config_relaunch_cooldown() {
  ensure_config
  python3 - <<'PY'
import json, pathlib, os
data = json.loads(pathlib.Path(os.environ["NSF_CONFIG"]).read_text())
print(int(data.get("relaunch_cooldown_seconds") or 600))
PY
}

agent_match_running() {
  local pattern="$1"
  pgrep -x "${pattern}" >/dev/null 2>&1 && return 0
  pgrep -if "${pattern}" >/dev/null 2>&1 && return 0
  return 1
}

# Echo "label" lines for each running agent; exit 0 if any running
list_running_agents() {
  ensure_config
  export NSF_CONFIG
  python3 - <<'PY'
import json, pathlib, os, subprocess, sys

def running(pattern: str) -> bool:
    for args in (
        ["pgrep", "-x", pattern],
        ["pgrep", "-if", pattern],
    ):
        if subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            return True
    return False

data = json.loads(pathlib.Path(os.environ["NSF_CONFIG"]).read_text())
found = []
for agent in data.get("agents") or []:
    label = agent.get("label") or agent.get("id") or "agent"
    for pat in agent.get("match") or []:
        if running(str(pat)):
            found.append(label)
            break
for f in found:
    print(f)
sys.exit(0 if found else 1)
PY
}

any_agent_running() {
  list_running_agents >/dev/null 2>&1
}

relaunch_agents_if_needed() {
  ensure_config
  config_relaunch_enabled || return 0
  if any_agent_running; then
    return 0
  fi

  local cooldown stamp now last
  cooldown="$(config_relaunch_cooldown)"
  stamp="${NSF_HOME}/last_agent_relaunch"
  now=$(date +%s)
  last=0
  [[ -f "${stamp}" ]] && last=$(cat "${stamp}" 2>/dev/null || echo 0)
  if (( now - last <= cooldown )); then
    return 0
  fi

  export NSF_CONFIG
  local opens
  opens="$(python3 - <<'PY'
import json, pathlib, os
data = json.loads(pathlib.Path(os.environ["NSF_CONFIG"]).read_text())
global_on = data.get("relaunch", True)
seen = set()
for agent in data.get("agents") or []:
    if not global_on:
        break
    if agent.get("relaunch", True) is False:
        continue
    open_name = (agent.get("open") or "").strip()
    if open_name and open_name not in seen:
        seen.add(open_name)
        print(open_name)
PY
)"

  if [[ -z "${opens}" ]]; then
    return 0
  fi

  log "No configured agents running — relaunch attempt: ${opens//$'\n'/, }"
  while IFS= read -r app; do
    [[ -z "${app}" ]] && continue
    open -a "${app}" 2>/dev/null || true
  done <<< "${opens}"
  echo "${now}" > "${stamp}"
}
