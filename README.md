# Claude Code Sound Hooks

Sound packs for Claude Code - play sounds on session start, prompt submit, notification, and stop events.

Inspired by [@delba_oliveira](https://x.com/delba_oliveira/status/2020515010985005255?s=20) on X. I'm just trying to make it easy to install.

## Requirements

- macOS (uses `afplay`)
- [jq](https://jqlang.github.io/jq/) - `brew install jq`
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and run at least once

## Install

```bash
git clone https://github.com/butchmayhew/claude-sound-hooks.git
cd claude-sound-hooks
bash install.sh
```

This will:
- Copy the sound-pack script and skill to `~/.claude/`
- Copy included sound packs (won't overwrite existing ones)
- Inject hook entries into `~/.claude/settings.json`
- Initialize default settings (wow-peasant pack, volume 0.5, sounds on)

## Uninstall

```bash
bash uninstall.sh
```

Removes all installed files and hook entries from settings.json.

## Usage

Use the `/sound-pack` skill command in Claude Code:

| Command | Action |
|---|---|
| `/sound-pack` | List packs, show volume and status |
| `/sound-pack set <name>` | Switch to a different sound pack |
| `/sound-pack current` | Print active pack name |
| `/sound-pack volume` | Print current volume |
| `/sound-pack volume 0.3` | Set volume (0.0 - 1.0) |
| `/sound-pack on` | Enable sounds |
| `/sound-pack off` | Disable sounds |
| `/sound-pack status` | Show pack, volume, and enabled state |

## Adding Custom Sound Packs

1. Create a folder in `packs/` with your pack name
2. Add 4 audio files (WAV or MP3): `session-start`, `prompt-submit`, `notification`, `stop`
3. Re-run `bash install.sh` to copy the new pack

Or manually copy your pack folder to `~/.claude/hooks/sound-packs/`.

## Included Packs

- **claude-created** - AI-generated sound effects
- **nintendo-like** - Nintendo-inspired sounds
- **office-michael** - The Office Michael Scott sounds
- **sc-terran** - StarCraft Terran sounds
- **wow-peasant** - World of Warcraft peasant sounds
- **wow-peon** - World of Warcraft peon sounds
