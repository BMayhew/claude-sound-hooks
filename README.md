# Claude Code Sound Hooks

Sound packs for Claude Code - play sounds on session start, prompt submit, notification, and stop events.

Inspired by [@delba_oliveira](https://x.com/delba_oliveira/status/2020515010985005255?s=20) on X. I'm just trying to make it easy to install.

## Requirements

- macOS (uses `afplay`)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## Install

No clone, no install script. In Claude Code:

```
/plugin marketplace add BMayhew/claude-sound-hooks
/plugin install sound-hooks@claude-sound-hooks
```

That's it. Sounds start on the next session with the `wow-peasant` pack at volume 0.5.

To update later: `/plugin marketplace update` then `/plugin update sound-hooks@claude-sound-hooks`.

## Uninstall

```
/plugin uninstall sound-hooks@claude-sound-hooks
```

Your own packs and settings in `~/.claude/hooks/sound-packs/` are left alone. Delete that
folder too if you want them gone.

## Usage

| Command | Action |
|---|---|
| `/sound-hooks:sound-pack` | List packs, show volume and status |
| `/sound-hooks:sound-pack set <name>` | Switch to a different sound pack |
| `/sound-hooks:sound-pack current` | Print active pack name |
| `/sound-hooks:sound-pack volume` | Print current volume |
| `/sound-hooks:sound-pack volume 0.3` | Set volume (0.0 - 1.0) |
| `/sound-hooks:sound-pack on` | Enable sounds |
| `/sound-hooks:sound-pack off` | Disable sounds |
| `/sound-hooks:sound-pack status` | Show pack, volume, and enabled state |
| `/sound-hooks:sound-pack cleanup` | Remove leftover hooks from the old `install.sh` |

Changes apply on the next sound - no restart needed.

## Adding Custom Sound Packs

Create a folder in `~/.claude/hooks/sound-packs/` with 4 audio files (WAV or MP3) named
`session-start`, `prompt-submit`, `notification`, `stop`:

```bash
mkdir -p ~/.claude/hooks/sound-packs/my-pack
# copy your 4 files in, then:
```

```
/sound-hooks:sound-pack set my-pack
```

A pack there with the same name as a bundled one takes priority, so you can override
`wow-peasant` without editing the plugin. Your packs survive plugin updates and uninstalls.

To contribute a pack upstream instead, add it to `packs/` in this repo and open a PR.

## Upgrading from the `install.sh` version

The old installer wrote `afplay` commands straight into `~/.claude/settings.json`. Those
would double every sound now, so the plugin detects them and stays silent. Install the
plugin, then run once:

```
/sound-hooks:sound-pack cleanup
```

That removes all three things the old installer left behind:

- the `afplay` hook entries in `settings.json` — only those; your own hooks, including your
  own `afplay` ones, are left alone
- `~/.claude/hooks/sound-pack.sh`, the old script, which would otherwise write those hook
  entries straight back the next time it ran
- `~/.claude/skills/sound-pack/`, the old user-level skill, which still answers to the
  unprefixed `/sound-pack` and calls that script

Your pack, volume and on/off settings carry over as they are. If anything is left that
`cleanup` can't reach, it says so and points at the line instead of claiming success.
(`cleanup` needs `jq`; nothing else does.)

## Included Packs

- **claude-created** - AI-generated sound effects
- **lightsaber** - Lightsaber sounds
- **nintendo-like** - Nintendo-inspired sounds
- **office-michael** - The Office Michael Scott sounds
- **sc-terran** - StarCraft Terran sounds
- **wow-peasant** - World of Warcraft peasant sounds
- **wow-peon** - World of Warcraft peon sounds

## Development

```bash
claude --plugin-dir .          # load this checkout without installing
claude plugin validate .       # check the manifests
bash tests/test-play.sh        # check sound resolution logic
```
