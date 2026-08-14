#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

issues=()
ok=()

on_ac_power && ok+=("AC power") || issues+=("Not on AC power")

if /usr/sbin/networksetup -getairportnetwork en0 2>/dev/null | grep -q "Current Wi-Fi Network"; then
  ssid="$(/usr/sbin/networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //')"
  ok+=("Wi-Fi: ${ssid}")
else
  issues+=("Wi-Fi not connected")
fi

if pgrep -x "Cursor" >/dev/null 2>&1 || pgrep -f "/Applications/Cursor.app" >/dev/null 2>&1; then
  ok+=("Cursor running")
else
  issues+=("Cursor not running")
fi

if [[ -f "${HOME}/.google-workspace-mcp/token.json" ]]; then
  ok+=("Google MCP token present")
else
  issues+=("Google MCP token missing")
fi

if ping -c 1 -t 2 1.1.1.1 >/dev/null 2>&1; then
  ok+=("Internet reachable")
else
  issues+=("No internet")
fi

printf '%s\n' "${ok[@]}"
[[ ${#issues[@]} -gt 0 ]] && printf 'ISSUE:%s\n' "${issues[@]}"
exit 0
