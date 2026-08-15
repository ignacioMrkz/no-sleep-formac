#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
USER_NAME="$(whoami)"
UID_NUM="$(id -u)"
NSF_HOME="${HOME}/.config/no-sleep-formac"
INSTALL_LIB="${NSF_HOME}/lib"
BIN="${HOME}/bin/no-sleep-formac"
PLIST_SRC="${REPO_ROOT}/launchd/com.ruralhackers.no-sleep-formac.plist"
PLIST_DST="${HOME}/Library/LaunchAgents/com.ruralhackers.no-sleep-formac.plist"
SUDOERS="/etc/sudoers.d/no-sleep-formac"

echo "==> no-sleep-formac install"

mkdir -p "${NSF_HOME}" "${HOME}/bin" "${HOME}/Library/LaunchAgents" "${HOME}/Library/Logs/no-sleep-formac"
rsync -a "${REPO_ROOT}/lib/" "${INSTALL_LIB}/"
chmod +x "${INSTALL_LIB}/"*.sh "${REPO_ROOT}/bin/no-sleep-formac"

# Wrapper resolves installed lib path
cat > "${BIN}" <<EOF
#!/bin/bash
export NSF_INSTALL_LIB="${INSTALL_LIB}"
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

launchctl bootout "gui/${UID_NUM}/com.ruralhackers.no-sleep-formac" 2>/dev/null || true
launchctl bootstrap "gui/${UID_NUM}" "${PLIST_DST}"
launchctl enable "gui/${UID_NUM}/com.ruralhackers.no-sleep-formac"
launchctl kickstart -k "gui/${UID_NUM}/com.ruralhackers.no-sleep-formac"

echo ""
echo "Installed. Ensure ~/bin is in PATH."
echo "  no-sleep-formac preflight"
echo "  no-sleep-formac away"
echo "When finished: no-sleep-formac disable"
