# no-sleep-formac

Keep a MacBook **awake with the lid closed** (clamshell / headless) so you can use **[Cursor](https://cursor.com) Remote Control** from your phone or another machine.

macOS normally sleeps when you close the lid. This tool temporarily changes power settings so the Mac stays on while you work remotely, then restores normal sleep when you turn it off.

**No API keys, tokens, or accounts are stored by this project.** Runtime state lives only on your Mac under `~/.config/no-sleep-formac/`.

---

## What problem it solves

| Without this tool | With this tool |
|-------------------|----------------|
| Close lid → Mac sleeps → Remote Control dies | Close lid on AC power → Mac stays awake → agents keep running |

Typical workflow: leave the Mac at home, plugged in, lid closed, and drive Cursor from your iPhone.

---

## How it works

```
no-sleep-formac away
        │
        ▼
 ~/.config/no-sleep-formac/enabled.json   ← flag "ON"
        │
        ▼
 LaunchAgent (every 60s + on flag change)
        │
        ▼
 headless-on.sh
   • backups current pmset AC profile
   • pmset -c sleep 0 / disablesleep 1 / …
   • (optional) caffeinate in "full" mode
```

When you run `disable`, the flag is removed and `pmset` is restored from the backup.

### Pieces

| Piece | Role |
|-------|------|
| `bin/no-sleep-formac` | CLI (`away`, `enable`, `disable`, `status`, …) |
| `lib/headless-manager.sh` | Applies ON/OFF based on the flag |
| `lib/headless-on.sh` / `headless-off.sh` | Changes / restores `pmset` |
| `lib/preflight.sh` / `health.sh` | Checks AC power, network, Cursor |
| `launchd/…plist` | Background watcher (installed into `~/Library/LaunchAgents`) |
| `/etc/sudoers.d/no-sleep-formac` | Passwordless `pmset` for AC/battery only (created at install) |

### Modes

| Mode | Behavior |
|------|----------|
| **eco** (default) | Only `pmset` on AC: no sleep, short display sleep |
| **full** | eco + `caffeinate -i -s` if you still get lid-closed sleep |

---

## Requirements

- macOS (Apple Silicon or Intel)
- Mac **plugged into power** to enable headless mode
- [Cursor](https://cursor.com) with Remote Control (recent versions)
- Optional but recommended in Cursor: **Settings → Agents → Keep this computer awake**

---

## Install

```bash
git clone https://github.com/ignacioMrkz/no-sleep-formac.git
cd no-sleep-formac
./install.sh
```

What install does:

1. Copies scripts to `~/.config/no-sleep-formac/lib/`
2. Puts a wrapper at `~/bin/no-sleep-formac` (add `~/bin` to your `PATH` if needed)
3. Installs a LaunchAgent
4. Creates a **narrow** sudoers rule so `pmset` can run without a password prompt (asks for your password **once**)

```bash
# Ensure PATH includes ~/bin (zsh example)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

---

## Usage

```bash
# Before you leave: checks + enable headless
no-sleep-formac preflight
no-sleep-formac away          # eco mode
# or: no-sleep-formac away --mode full

# Close the lid. Use Cursor Remote Control from your phone.

# When you are done (from the Mac or via Cursor agent):
no-sleep-formac disable
```

| Command | Description |
|---------|-------------|
| `install` | LaunchAgent + sudoers + `~/bin` wrapper |
| `preflight` | AC power, network, Cursor running |
| `away [--mode eco\|full]` | preflight + enable |
| `enable [--mode eco\|full]` | Turn headless on (no preflight) |
| `disable` | Restore normal sleep — **manual only** |
| `status [--json]` | Flag, active state, health |
| `self-test` | Short enable → disable smoke test |
| `version` | Print version |

### After a reboot

Headless does **not** auto-enable on boot (by design). Plug in, open Cursor, run `away` again.

---

## Security & privacy

- **No secrets in this repo.** Do not commit tokens, passwords, or MCP credentials.
- Local flag/state files (`enabled.json`, `state.json`, `pmset-backup-*.txt`) stay in `~/.config/no-sleep-formac/` and are gitignored conceptually (never ship them).
- Sudoers only allows:
  ```
  pmset -c *
  pmset -b *
  ```
  Nothing else.
- Disabling is intentional: only `no-sleep-formac disable` turns it off (so a flaky network does not put the Mac to sleep mid-session).

---

## Uninstall

```bash
./uninstall.sh
# Optional: remove sudoers
sudo rm -f /etc/sudoers.d/no-sleep-formac
# Optional: remove config + logs
rm -rf ~/.config/no-sleep-formac ~/Library/Logs/no-sleep-formac ~/bin/no-sleep-formac
```

---

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| `Not on AC power` | Plug in the charger; headless enable requires AC |
| Mac still sleeps with lid closed | Try `away --mode full`; confirm `status` shows Active |
| Remote Control disconnects | Wi‑Fi + Cursor running before closing lid; check `preflight` |
| `pmset` asks for password | Re-run `./install.sh` so sudoers is created |
| Forgot it was on | `no-sleep-formac status` then `disable` |

Logs: `~/Library/Logs/no-sleep-formac/manager.log`

---

## Project layout

```
no-sleep-formac/
├── bin/no-sleep-formac      # CLI entrypoint
├── lib/                     # Scripts used by CLI + LaunchAgent
├── launchd/                 # LaunchAgent template (__HOME__/__LIB__ placeholders)
├── install.sh / uninstall.sh
├── LICENSE
└── README.md
```

---

## License

MIT — Asociación Rural Hackers / Ignacio Márquez
