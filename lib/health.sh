#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

issues=()
ok=()

on_ac_power && ok+=("AC power") || issues+=("Not on AC power")

# Wi-Fi: networksetup often fails on recent macOS even when connected; use IP + reachability
wifi_ok=false
ssid=""
if out="$(/usr/sbin/networksetup -getairportnetwork en0 2>/dev/null)" && [[ "${out}" == *"Current Wi-Fi Network:"* ]]; then
  ssid="${out#Current Wi-Fi Network: }"
  wifi_ok=true
elif ip="$(ipconfig getifaddr en0 2>/dev/null)" && [[ -n "${ip}" ]]; then
  ssid="en0 (${ip})"
  wifi_ok=true
elif scutil --nwi 2>/dev/null | grep -q "en0.*Reachable"; then
  ssid="en0 (reachable)"
  wifi_ok=true
fi

if ${wifi_ok}; then
  ok+=("Network: ${ssid}")
else
  issues+=("No network on en0")
fi

running_agents="$(list_running_agents 2>/dev/null || true)"
if [[ -n "${running_agents}" ]]; then
  while IFS= read -r agent; do
    [[ -z "${agent}" ]] && continue
    ok+=("Agent: ${agent}")
  done <<< "${running_agents}"
else
  issues+=("No configured agent running (see config.json)")
fi

if ping -c 1 -t 2 1.1.1.1 >/dev/null 2>&1; then
  ok+=("Internet reachable")
else
  issues+=("No internet")
fi

printf '%s\n' "${ok[@]}"
[[ ${#issues[@]} -gt 0 ]] && printf 'ISSUE:%s\n' "${issues[@]}"
exit 0
