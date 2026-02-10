---
name: sound-pack
description: "Manage sound packs for Claude Code hooks. Use when the user wants to list, switch, check status, adjust volume, or toggle sounds on/off."
---

# Sound Pack

Manage sound packs for Claude Code hooks. Sound packs are folders under `~/.claude/hooks/sound-packs/` containing 4 wav files (`session-start.wav`, `prompt-submit.wav`, `notification.wav`, `stop.wav`).

## Commands

| Command | Action |
|---|---|
| `list` (default) | List packs, mark active, show volume and enabled state |
| `set <name>` | Switch to a different sound pack |
| `current` | Print active pack name |
| `volume` | Print current volume |
| `volume <0.0-1.0>` | Set volume level |
| `on` | Enable sounds (injects hooks into settings.json) |
| `off` | Disable sounds (removes hooks from settings.json) |
| `status` | Show pack name, volume, and enabled state |

## Instructions

1. Parse `$ARGUMENTS` to determine the command. If empty, default to `list`.
2. Run the script using Bash:

```
bash ~/.claude/hooks/sound-pack.sh <command> [arg]
```

Examples:
- `/sound-pack` -> `bash ~/.claude/hooks/sound-pack.sh list`
- `/sound-pack set wow-peasant` -> `bash ~/.claude/hooks/sound-pack.sh set wow-peasant`
- `/sound-pack volume 0.3` -> `bash ~/.claude/hooks/sound-pack.sh volume 0.3`
- `/sound-pack off` -> `bash ~/.claude/hooks/sound-pack.sh off`

3. Report the result to the user.
