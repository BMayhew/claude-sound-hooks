#!/bin/bash
# Plays one sound for a Claude Code hook event.
# Resolves pack, volume and enabled state at playback time, so switching packs
# never has to touch the hook configuration.
# Always exits 0 - a broken or missing sound must never fail a hook.

USER_DIR="$HOME/.claude/hooks/sound-packs"
BUNDLED_DIR="$(cd "$(dirname "$0")/../packs" 2>/dev/null && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Same pattern sound-pack.sh cleanup removes - keep the two in sync, or cleanup
# can report success while playback stays muted.
LEGACY_RE='afplay -v [^"]*sound-packs/'

BASE="$1"
[ -n "$BASE" ] || exit 0
[ -n "$BUNDLED_DIR" ] || exit 0

read_state() {
  # $1 = file name, $2 = default. An empty file falls back to the default too:
  # a truncated .volume would otherwise become `afplay -v ""`, which fails.
  local v=""
  [ -f "$USER_DIR/$1" ] && v=$(tr -d '[:space:]' < "$USER_DIR/$1")
  echo "${v:-$2}"
}

# Legacy guard: a pre-plugin install.sh still has its hooks in settings.json,
# so playing here would double every sound. Match the command shape it wrote
# so an unrelated afplay hook of the user's own doesn't trip this.
if [ -f "$SETTINGS_FILE" ] && grep -q "$LEGACY_RE" "$SETTINGS_FILE"; then
  if [ "$BASE" = "session-start" ]; then
    echo "Legacy sound hooks found in settings.json from a pre-plugin install. Sounds are paused until they are removed - run /sound-hooks:sound-pack cleanup."
  fi
  exit 0
fi

[ "$(read_state .enabled true)" = "true" ] || exit 0

ACTIVE=$(read_state .active wow-peasant)
VOLUME=$(read_state .volume 0.5)

if [ -d "$USER_DIR/$ACTIVE" ]; then
  PACK="$USER_DIR/$ACTIVE"
else
  PACK="$BUNDLED_DIR/$ACTIVE"
fi

FILE=$(ls "$PACK/$BASE".* 2>/dev/null | head -1)
[ -n "$FILE" ] || exit 0

if [ -n "$SOUND_DRY_RUN" ]; then
  echo "afplay -v $VOLUME $FILE"
  exit 0
fi

# Backgrounded so the hook returns immediately: SessionStart is synchronous (its
# stdout is what carries the legacy notice above) and clips run up to ~3s.
# Output and exit code are discarded - a corrupt audio file must not fail a hook.
afplay -v "$VOLUME" "$FILE" >/dev/null 2>&1 &
exit 0
