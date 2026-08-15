#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
USER_NAME="$(whoami)"
UID_NUM="$(id -u)"
NSF_HOME="${HOME}/.config/no-sleep-formac"
INSTALL_LIB="${NSF_HOME}/lib"
BIN="${HOME}/bin/no-sleep-formac"
PLIST_SRC="${REPO_ROOT}/launchd/com.nosleepformac.headless.plist"
PLIST_DST="${HOME}/Library/LaunchAgents/com.nosleepformac.headless.plist"
PLIST_LEGACY="${HOME}/Library/LaunchAgents/com.ruralhackers.no-sleep-formac.plist"
SUDOERS="/etc/sudoers.d/no-sleep-formac"
LABEL="com.nosleepformac.headless"
LABEL_LEGACY="com.ruralhackers.no-sleep-formac"

echo "==> no-sleep-formac install"

mkdir -p "${NSF_HOME}" "${HOME}/bin" "${HOME}/Library/LaunchAgents" "${HOME}/Library/Logs/no-sleep-formac"
rsync -a "${REPO_ROOT}/lib/" "${INSTALL_LIB}/"
chmod +x "${INSTALL_LIB}/"*.sh "${REPO_ROOT}/bin/no-sleep-formac"

# Default agent config (user-editable; never overwrite existing)
if [[ ! -f "${NSF_HOME}/config.json" ]]; then
  cp "${REPO_ROOT}/config.example.json" "${NSF_HOME}/config.json"
  chmod 600 "${NSF_HOME}/config.json"
  echo "    Wrote ${NSF_HOME}/config.json (edit to add/remove agents)"
fi

# Wrapper resolves installed lib path
cat > "${BIN}" <<EOF
#!/bin/bash
export NSF_INSTALL_LIB="${INSTALL_LIB}"
export NSF_REPO_ROOT="${REPO_ROOT}"
exec "${REPO_ROOT}/bin/no-sleep-formac" "\$@"
EOF
chmod +x "${BIN}"

# Patch manager plist paths
sed "s|__HOME__|${HOME}|g; s|__LIB__|${INSTALL_LIB}|g" "${PLIST_SRC}" > "${PLIST_DST}"

if [[ ! -f "${SUDOERS}" ]]; then
  echo "==> sudoers (one-time password required)"
  TMP="$(mktemp)"
  echo "${USER_NAME} ALL=(ALL) NOPASSWD: /usr/bin/pmset -c *, /usr/bin/pmset -b *" > "${TMP}"
  sudo visudo -cf "${TMP}"
  sudo cp "${TMP}" "${SUDOERS}"
  sudo chmod 440 "${SUDOERS}"
  rm -f "${TMP}"
  echo "    Created ${SUDOERS}"
else
  echo "    sudoers already exists: ${SUDOERS}"
fi

# Migrate away from legacy LaunchAgent label if present
launchctl bootout "gui/${UID_NUM}/${LABEL_LEGACY}" 2>/dev/null || true
rm -f "${PLIST_LEGACY}"

launchctl bootout "gui/${UID_NUM}/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/${UID_NUM}" "${PLIST_DST}"
launchctl enable "gui/${UID_NUM}/${LABEL}"
launchctl kickstart -k "gui/${UID_NUM}/${LABEL}"

echo ""
echo "Installed. Ensure ~/bin is in PATH."
echo "  no-sleep-formac preflight"
echo "  no-sleep-formac away"
echo "When finished: no-sleep-formac disable"
echo "Agents: edit ~/.config/no-sleep-formac/config.json"
