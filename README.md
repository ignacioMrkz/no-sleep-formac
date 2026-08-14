# no-sleep-formac

Keep your Mac awake (lid closed, on AC power) for **Cursor Remote Control** with local MCPs.

No auto-disable. Stays on until **you** run `disable` — typically from Cursor on your iPhone:

> *desactiva headless* / *modo normal*

## Quick start

```bash
git clone https://github.com/ignacioMrkz/no-sleep-formac.git
cd no-sleep-formac
./install.sh

no-sleep-formac preflight
# Cursor: /remote-control
no-sleep-formac away
# close lid, use Cursor iOS
```

## Commands

| Command | Description |
|---------|-------------|
| `install` | LaunchAgent + sudoers + `~/bin` wrapper |
| `preflight` | AC power, Wi‑Fi, Cursor, MCP token |
| `away` | preflight + enable (main command before leaving) |
| `enable [--mode eco\|full]` | Turn on headless |
| `disable` | Restore normal sleep — **only manual** |
| `status [--json]` | Current state |
| `self-test` | Brief enable/disable test |

## Modes

- **eco** (default): `pmset -c` only — sleep 0, disablesleep 1
- **full**: eco + `caffeinate -i -s` if lid-closed needs extra assertion

## Requirements

- macOS, **charger connected** to enable
- Cursor 3.9.8+ with Remote Control
- Settings → Agents → Keep this computer awake (recommended)

## After reboot

Headless is off. Go home, boot Mac, run `away` again. No auto-start on boot (by design).

## Rural Hackers

Used with [ruralhackers-harness](https://github.com/ignacioMrkz/ruralhackers-harness) skill `no-sleep-formac`.

## License

MIT — Asociación Rural Hackers / Ignacio Márquez
