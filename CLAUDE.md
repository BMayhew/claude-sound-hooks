# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Sound Hooks adds audio feedback to Claude Code by playing sounds on IDE events (SessionStart, UserPromptSubmit, Notification, Stop). It's macOS-only, using `afplay` for audio playback.

## Commands

```bash
bash install.sh      # Install to ~/.claude/
bash uninstall.sh    # Remove all installed files
```

No build step or tests - this is a pure bash/audio asset project.

## Architecture

**Installation Flow:**
- `install.sh` copies scripts and packs to `~/.claude/`, injects hooks into `~/.claude/settings.json`
- Uses `jq` for JSON manipulation with atomic temp-file-then-move pattern
- No-clobber copying preserves user's custom sound packs on reinstall

**Runtime State** (in `~/.claude/hooks/sound-packs/`):
- `.active` - current pack name
- `.volume` - float 0.0-1.0
- `.enabled` - "true" or "false"

**Hook Injection:**
The scripts modify `~/.claude/settings.json` to add/remove entries like:
```json
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "afplay -v 0.5 ~/.claude/hooks/sound-packs/wow-peasant/session-start.wav"}]}]
  }
}
```

**Key Files:**
- `scripts/sound-pack.sh` - Main CLI utility, handles all subcommands (list, set, volume, on, off, status)
- `skill/SKILL.md` - Claude Code skill definition that maps `/sound-pack` to the bash script
- `packs/*/` - Sound pack folders, each containing 4 WAV files

**Required WAV files per pack:**
`session-start.wav`, `prompt-submit.wav`, `notification.wav`, `stop.wav`

## Dependencies

- macOS (uses `afplay`)
- `jq` (`brew install jq`)
- Claude Code installed with `~/.claude/` existing
