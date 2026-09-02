---
name: sound-pack
description: "Manage sound packs for Claude Code hooks. Use when the user wants to list, switch, check status, adjust volume, or toggle sounds on/off."
---

# Sound Pack

Manage sound packs for Claude Code hooks. A pack is a folder with 4 audio files (WAV or
MP3): `session-start`, `prompt-submit`, `notification`, `stop`.

Packs are read from two places, user first:

- `~/.claude/hooks/sound-packs/<name>/` — your own packs. A pack here shadows a bundled
  one with the same name.
- the plugin's bundled `packs/` directory.

State lives in `~/.claude/hooks/sound-packs/` as `.active`, `.volume` and `.enabled`.
Changes take effect on the next hook event — no restart, no `/reload-plugins`.

## Commands

| Command | Action |
|---|---|
| `list` (default) | List packs, mark active, show volume and enabled state |
| `set <name>` | Switch to a different sound pack |
| `current` | Print active pack name |
| `volume` | Print current volume |
| `volume <0.0-1.0>` | Set volume level |
| `on` | Enable sounds |
| `off` | Disable sounds |
| `status` | Show pack name, volume, and enabled state |
| `cleanup` | Remove leftover `afplay` hooks written by the old `install.sh` |

## Instructions

1. Parse `$ARGUMENTS` to determine the command. If empty, default to `list`.
2. Run the script using Bash:

```
bash "${CLAUDE_PLUGIN_ROOT}"/scripts/sound-pack.sh <command> [arg]
```

Examples:
- `/sound-hooks:sound-pack` -> `bash "${CLAUDE_PLUGIN_ROOT}"/scripts/sound-pack.sh list`
- `/sound-hooks:sound-pack set wow-peasant` -> `bash "${CLAUDE_PLUGIN_ROOT}"/scripts/sound-pack.sh set wow-peasant`
- `/sound-hooks:sound-pack volume 0.3` -> `bash "${CLAUDE_PLUGIN_ROOT}"/scripts/sound-pack.sh volume 0.3`
- `/sound-hooks:sound-pack off` -> `bash "${CLAUDE_PLUGIN_ROOT}"/scripts/sound-pack.sh off`

3. Report the result to the user.

If sounds are silent and the session reported legacy hooks in `settings.json`, run
`cleanup` — that is a leftover from the pre-plugin `install.sh` and it is suppressing
playback to avoid doubled sounds.
