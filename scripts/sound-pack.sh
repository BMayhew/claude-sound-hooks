#!/bin/bash
# Manages sound pack state. Writes three files; hooks/play.sh reads them on the
# next event, so nothing here ever touches settings.json (except `cleanup`).

USER_DIR="$HOME/.claude/hooks/sound-packs"
BUNDLED_DIR="$(cd "$(dirname "$0")/.." && pwd)/packs"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Legacy artifacts written by the pre-2.0 install.sh.
LEGACY_RE='afplay -v [^"]*sound-packs/'
LEGACY_SCRIPT="$HOME/.claude/hooks/sound-pack.sh"
LEGACY_SKILL="$HOME/.claude/skills/sound-pack"

FILES=("session-start" "prompt-submit" "notification" "stop")

ACTION="${1:-list}"
ARG="$2"

# --- Helpers ---

read_state() {
  # An empty file falls back to the default, same as hooks/play.sh.
  local v=""
  [ -f "$USER_DIR/$1" ] && v=$(tr -d '[:space:]' < "$USER_DIR/$1")
  echo "${v:-$2}"
}

write_state() {
  mkdir -p "$USER_DIR"
  echo "$2" > "$USER_DIR/$1"
}

# User packs shadow bundled ones of the same name.
pack_path() {
  if [ -d "$USER_DIR/$1" ]; then
    echo "$USER_DIR/$1"
  elif [ -d "$BUNDLED_DIR/$1" ]; then
    echo "$BUNDLED_DIR/$1"
  fi
}

pack_names() {
  for dir in "$BUNDLED_DIR"/*/ "$USER_DIR"/*/; do
    [ -d "$dir" ] && basename "$dir"
  done | sort -u
}

state_word() {
  if [ "$(read_state .enabled true)" = "true" ]; then echo "on"; else echo "off"; fi
}

# --- Commands ---

case "$ACTION" in
  list)
    active=$(read_state .active wow-peasant)
    echo "Sound packs (volume: $(read_state .volume 0.5), sounds: $(state_word)):"
    while read -r name; do
      if [ "$name" = "$active" ]; then
        echo "  * $name (active)"
      else
        echo "    $name"
      fi
    done < <(pack_names)
    ;;

  set)
    if [ -z "$ARG" ]; then
      echo "Usage: sound-pack.sh set <pack-name>"
      exit 1
    fi

    path=$(pack_path "$ARG")
    if [ -z "$path" ]; then
      echo "Sound pack not found: $ARG"
      echo "Available packs:"
      pack_names | sed 's/^/  /'
      exit 1
    fi

    for base in "${FILES[@]}"; do
      if ! ls "$path/$base".* &>/dev/null; then
        echo "Missing file in pack: $base.*"
        exit 1
      fi
    done

    write_state .active "$ARG"
    echo "Switched to sound pack: $ARG"
    ;;

  current)
    echo "$(read_state .active wow-peasant)"
    ;;

  volume)
    if [ -z "$ARG" ]; then
      echo "$(read_state .volume 0.5)"
    else
      if ! echo "$ARG" | grep -qE '^(0(\.[0-9]+)?|1(\.0+)?)$'; then
        echo "Volume must be between 0.0 and 1.0"
        exit 1
      fi
      write_state .volume "$ARG"
      echo "Volume set to $ARG"
    fi
    ;;

  on)
    write_state .enabled true
    echo "Sounds enabled"
    ;;

  off)
    write_state .enabled false
    echo "Sounds disabled"
    ;;

  status)
    echo "Pack: $(read_state .active wow-peasant)"
    echo "Volume: $(read_state .volume 0.5)"
    echo "Sounds: $(state_word)"
    ;;

  cleanup)
    # Migration only. The pre-2.0 install.sh left three things behind: hook
    # entries in settings.json, a copy of the old script, and a user-level
    # `sound-pack` skill. All three have to go - the old script re-injects the
    # hook entries on its next set/volume/on, which would re-mute the plugin
    # straight after a cleanup that only touched settings.json.
    did_something=0

    if [ -f "$SETTINGS_FILE" ] && grep -q "$LEGACY_RE" "$SETTINGS_FILE"; then
      if ! command -v jq &>/dev/null; then
        echo "Error: jq is required to clean up legacy hooks. Install with: brew install jq"
        exit 1
      fi

      # Drop only the commands this project wrote. Filter inside each group so a
      # group where the user added their own command keeps that command, then
      # drop groups and events left empty.
      tmp=$(mktemp)
      if jq '
        reduce ("SessionStart", "UserPromptSubmit", "Notification", "Stop") as $e (.;
          if .hooks[$e] then
            .hooks[$e] |= (
              map(.hooks |= map(select((.command // "") | test("afplay -v .*sound-packs/") | not)))
              | map(select((.hooks | length) > 0))
            )
            | if (.hooks[$e] | length) == 0 then del(.hooks[$e]) else . end
          else . end)
      ' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"; then
        echo "Removed legacy sound hooks from settings.json"
        did_something=1
      else
        rm -f "$tmp"
        echo "Error: could not rewrite $SETTINGS_FILE (is it valid JSON?). Nothing was changed."
        exit 1
      fi
    fi

    if [ -f "$LEGACY_SCRIPT" ]; then
      rm -f "$LEGACY_SCRIPT" && echo "Removed old $LEGACY_SCRIPT"
      did_something=1
    fi

    if [ -d "$LEGACY_SKILL" ]; then
      rm -rf "$LEGACY_SKILL" && echo "Removed old skill at $LEGACY_SKILL"
      did_something=1
    fi

    if [ "$did_something" = "0" ]; then
      echo "Nothing to clean up."
      exit 0
    fi

    # Confirm rather than claim. play.sh greps the whole file, so something the
    # rewrite above does not reach - a stale entry under another event, say -
    # would leave playback muted with no explanation.
    if [ -f "$SETTINGS_FILE" ] && grep -q "$LEGACY_RE" "$SETTINGS_FILE"; then
      echo ""
      echo "Warning: settings.json still contains a legacy sound command, so sounds stay muted."
      echo "Remove the remaining entry by hand:"
      grep -n "$LEGACY_RE" "$SETTINGS_FILE"
      exit 1
    fi

    echo "Sounds are live again."
    ;;

  *)
    echo "Usage: sound-pack.sh <list|set|current|volume|on|off|status|cleanup> [arg]"
    exit 1
    ;;
esac
