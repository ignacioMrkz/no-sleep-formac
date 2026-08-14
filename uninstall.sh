#!/bin/bash
set -euo pipefail

UID_NUM="$(id -u)"
PLIST_DST="${HOME}/Library/LaunchAgents/com.ruralhackers.no-sleep-formac.plist"

launchctl bootout "gui/${UID_NUM}/com.ruralhackers.no-sleep-formac" 2>/dev/null || true
rm -f "${PLIST_DST}"

if [[ -f "${HOME}/.config/no-sleep-formac/enabled.json" ]]; then
  rm -f "${HOME}/.config/no-sleep-formac/enabled.json"
  bash "${HOME}/.config/no-sleep-formac/lib/headless-manager.sh" 2>/dev/null || true
fi

echo "Uninstalled LaunchAgent. sudoers /etc/sudoers.d/no-sleep-formac not removed (remove manually if desired)."
