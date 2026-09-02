# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Sound Hooks is a Claude Code plugin that adds audio feedback on IDE events
(SessionStart, UserPromptSubmit, Notification, Stop). macOS-only, using `afplay`.

The repo is both the plugin and its own marketplace (`"source": "./"`), so it installs with
`/plugin marketplace add BMayhew/claude-sound-hooks` + `/plugin install sound-hooks@claude-sound-hooks`.

## Commands

```bash
claude --plugin-dir .        # load this checkout for one session, no install
claude plugin validate .     # validate plugin.json + marketplace.json
bash tests/test-play.sh      # self-check for the sound resolution logic
```

No build step.

## Architecture

The central design rule: **plugin hooks are static.** `hooks/hooks.json` is fixed at install
time, and `${CLAUDE_PLUGIN_ROOT}` changes on every plugin update, so the audio path and
volume can never be baked into the hook command. The four hooks all call one indirection
script instead:

```
"command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/play.sh stop"
```

`hooks/play.sh` resolves everything at playback time. Switching packs is therefore a single
file write - nothing regenerates hook config, and no restart or `/reload-plugins` is needed.

Three of the four hooks set `"async": true` so audio never blocks a turn. `SessionStart` is
deliberately synchronous: it is the one event whose exit-0 stdout reaches Claude's context,
which the legacy-migration notice relies on. To keep that from costing a ~3s stall,
`play.sh` backgrounds `afplay` and returns in ~10ms rather than `exec`-ing it. Its matcher
excludes `compact`, so an auto-compact mid-task stays quiet.

**Runtime state** lives in `~/.claude/hooks/sound-packs/` - `.active`, `.volume`, `.enabled`.
Deliberately *not* `${CLAUDE_PLUGIN_DATA}`, which is deleted on uninstall and would take
user-authored packs with it.

**Pack resolution** in `play.sh`: `~/.claude/hooks/sound-packs/<name>/` first, then the
bundled `packs/<name>/`. A user pack shadows a bundled one of the same name. Missing files
exit 0 silently - a sound must never fail a hook.

**Legacy guard:** versions before 2.0.0 injected `afplay` commands into
`~/.claude/settings.json`. If `play.sh` still finds one it suppresses playback (otherwise
every sound doubles) and prints a notice on session start.

Three constraints on that guard, each of which was a bug once:

- The pattern is `afplay -v [^"]*sound-packs/`, not a bare `afplay` - users have their own
  `afplay` hooks (`afplay /System/Library/Sounds/Glass.aiff` is common) and a broad match
  mutes them out of their own plugin.
- `play.sh` and `sound-pack.sh` must grep for the *same* pattern. If the guard matches
  something `cleanup` doesn't remove, the plugin is muted with no way out, so `cleanup`
  re-checks the guard afterwards and reports rather than claiming success.
- `cleanup` must also delete `~/.claude/hooks/sound-pack.sh` and
  `~/.claude/skills/sound-pack/`. The old script re-injects the hook entries on its next
  `set`/`volume`/`on`, and the old skill still answers to an unprefixed `/sound-pack`.

`cleanup` is the only remaining `jq` usage in the project.

**Key files:**
- `.claude-plugin/plugin.json` - plugin manifest. Bump `version` on every release or users get no update. Never set `version` in the marketplace entry too; `plugin.json` wins silently.
- `.claude-plugin/marketplace.json` - self-hosting marketplace entry
- `hooks/hooks.json` - the four static hook declarations
- `hooks/play.sh` - runtime resolution + `afplay`. Honours `SOUND_DRY_RUN=1` for tests.
- `scripts/sound-pack.sh` - CLI: list, set, current, volume, on, off, status, cleanup
- `skills/sound-pack/SKILL.md` - maps `/sound-hooks:sound-pack` to the script
- `packs/*/` - bundled packs, read-only at runtime

**Required audio files per pack (WAV or MP3):**
`session-start`, `prompt-submit`, `notification`, `stop`

## Dependencies

- macOS (uses `afplay`)
- `jq` - only for the legacy `cleanup` path, not for normal operation
