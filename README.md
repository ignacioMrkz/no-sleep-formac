# no-sleep-formac

Keep a MacBook **awake with the lid closed** so local AI agents and remote sessions keep running.

Works with **OpenAI Codex** (ChatGPT macOS app / Codex CLI), **Cursor** (Remote Control), SSH, Tailscale, or any other tool that needs the Mac online while the lid is shut.

macOS normally sleeps when you close the lid. This tool temporarily changes power settings, then restores them when you turn it off.

**No API keys or tokens are stored or required by this project.** All runtime state stays on your machine under `~/.config/no-sleep-formac/`.

---

## What problem it solves

| Without this tool | With this tool |
|-------------------|----------------|
| Close lid → Mac sleeps → agents / remote sessions die | Close lid on AC power → Mac stays awake |

Typical workflow: leave the Mac at home, **plugged in**, lid closed, and keep using Codex or Cursor from elsewhere.

---

## Quick start

```bash
git clone https://github.com/ignacioMrkz/no-sleep-formac.git
cd no-sleep-formac
./install.sh

# Ensure ~/bin is on your PATH
export PATH="$HOME/bin:$PATH"

no-sleep-formac preflight
no-sleep-formac away          # enable headless (eco mode)
# … close the lid, work remotely …
no-sleep-formac disable       # restore normal sleep
```

---

## Using with Codex (OpenAI)

Codex on macOS often runs inside the **ChatGPT** app (or as the `codex` CLI). The Mac must stay awake for local tools, computer-use, and long agent runs.

### Recommended flow

1. Plug in the charger (required to enable).
2. Open **ChatGPT / Codex** (or start your `codex` session / app-server).
3. Run:
   ```bash
   no-sleep-formac away
   ```
4. Close the lid.
5. Continue from the Codex / ChatGPT client on another device, or leave a long local job running.
6. When finished:
   ```bash
   no-sleep-formac disable
   ```
   You can also ask the agent: *run `no-sleep-formac disable`*.

### If your ChatGPT app has a custom name

On some Macs the app is `ChatGPT`, on others `ChatGPT 2`, etc. Edit:

`~/.config/no-sleep-formac/config.json`

```json
{
  "relaunch": true,
  "agents": [
    {
      "id": "codex",
      "label": "Codex (ChatGPT app)",
      "match": ["ChatGPT", "Codex"],
      "open": "ChatGPT 2",
      "relaunch": true
    }
  ]
}
```

- `match` — process/path substrings used to detect that Codex is running  
- `open` — passed to `open -a "…"` if relaunch is enabled and nothing is running  

### Codex CLI only

If you only use the CLI (`codex`) and do not want GUI relaunch:

```json
{
  "relaunch": false,
  "agents": [
    {
      "id": "codex-cli",
      "label": "Codex CLI",
      "match": ["codex"],
      "open": "",
      "relaunch": false
    }
  ]
}
```

Start your CLI session **before** closing the lid. Headless mode only keeps the Mac awake; it does not start `codex` for you unless `relaunch` + `open` are set.

### Remote access tips (Codex)

- Prefer the Mac on **Wi‑Fi + AC power**.
- For shell access from outside: **Tailscale**, **SSH**, or your usual tunnel — independent of this tool.
- Cloud-only Codex jobs do not need this tool; it is for **local** Mac workloads with the lid closed.

---

## Using with Cursor

1. Plug in the charger.
2. Open Cursor and start **Remote Control** (`/remote-control`).
3. Optional in Cursor: **Settings → Agents → Keep this computer awake**.
4. Run `no-sleep-formac away`, then close the lid.
5. Drive the machine from the Cursor mobile / remote client.
6. Run `no-sleep-formac disable` when done (or ask the agent to).

Default `config.json` already includes a Cursor agent entry.

---

## How it works

```
no-sleep-formac away
        │
        ▼
 ~/.config/no-sleep-formac/enabled.json   ← flag ON
        │
        ▼
 LaunchAgent (every 60s + on flag change)
        │
        ▼
 headless-on.sh
   • backup current pmset AC profile
   • pmset -c sleep 0 / disablesleep 1 / …
   • optional caffeinate in "full" mode
   • optional relaunch of agents from config.json
```

`disable` removes the flag and restores `pmset` from the backup.

### Modes

| Mode | Behavior |
|------|----------|
| **eco** (default) | `pmset` on AC only: no system sleep |
| **full** | eco + `caffeinate -i -s` if lid-closed sleep still happens |

### Commands

| Command | Description |
|---------|-------------|
| `install` | LaunchAgent + sudoers + `~/bin` wrapper + default `config.json` |
| `preflight` | AC power, network, configured agents |
| `away [--mode eco\|full]` | preflight + enable |
| `enable [--mode eco\|full]` | Turn headless on |
| `disable` | Restore normal sleep (manual only) |
| `status [--json]` | Flag, active state, health |
| `self-test` | Short enable → disable smoke test |

After a **reboot**, headless is off by design. Plug in and run `away` again.

---

## Configuration (no hardcoding)

Install copies `config.example.json` → `~/.config/no-sleep-formac/config.json` **once** (never overwrites your edits).

| Key | Meaning |
|-----|---------|
| `relaunch` | If true, try `open -a` when no agent is detected |
| `relaunch_cooldown_seconds` | Min seconds between relaunch attempts |
| `agents[].match` | Patterns to detect the process |
| `agents[].open` | App name for `open -a` |
| `agents[].relaunch` | Per-agent relaunch toggle |

Paths like your home directory are filled in at **install time** into the LaunchAgent plist; they are not committed to the repo (`__HOME__` / `__LIB__` placeholders only).

---

## Security & privacy

- No secrets in the repository.
- Do not commit `~/.config/no-sleep-formac/*` (local state).
- Sudoers rule is narrow: passwordless `pmset -c *` and `pmset -b *` only.
- Disable is intentional and manual so a flaky network does not put the Mac to sleep mid-job.

---

## Uninstall

```bash
./uninstall.sh
sudo rm -f /etc/sudoers.d/no-sleep-formac   # optional
rm -rf ~/.config/no-sleep-formac ~/Library/Logs/no-sleep-formac ~/bin/no-sleep-formac
```

---

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| `Not on AC power` | Plug in the charger |
| Mac still sleeps lid-closed | `away --mode full` |
| Agent not detected | Edit `match` / `open` in `config.json`; run `status` |
| ChatGPT app name differs | Set `"open": "ChatGPT 2"` (or your exact app name) |
| `pmset` asks for password | Re-run `./install.sh` |

Logs: `~/Library/Logs/no-sleep-formac/manager.log`

---

## Project layout

```
no-sleep-formac/
├── bin/no-sleep-formac
├── lib/                 # manager, pmset on/off, health, agents
├── launchd/             # LaunchAgent template (__HOME__/__LIB__)
├── config.example.json  # default Codex + Cursor agents
├── install.sh / uninstall.sh
├── LICENSE
└── README.md
```

---

## License

MIT — Asociación Rural Hackers / Ignacio Márquez
