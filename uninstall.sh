#!/bin/bash
set -euo pipefail

UID_NUM="$(id -u)"
LABEL="com.nosleepformac.headless"
LABEL_LEGACY="com.ruralhackers.no-sleep-formac"
PLIST_DST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
PLIST_LEGACY="${HOME}/Library/LaunchAgents/${LABEL_LEGACY}.plist"

launchctl bootout "gui/${UID_NUM}/${LABEL}" 2>/dev/null || true
launchctl bootout "gui/${UID_NUM}/${LABEL_LEGACY}" 2>/dev/null || true
rm -f "${PLIST_DST}" "${PLIST_LEGACY}"

if [[ -f "${HOME}/.config/no-sleep-formac/enabled.json" ]]; then
  rm -f "${HOME}/.config/no-sleep-formac/enabled.json"
  bash "${HOME}/.config/no-sleep-formac/lib/headless-manager.sh" 2>/dev/null || true
fi

echo "Uninstalled LaunchAgent. sudoers /etc/sudoers.d/no-sleep-formac not removed (remove manually if desired)."
