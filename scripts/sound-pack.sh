#!/bin/bash

HOOKS_DIR="$HOME/.claude/hooks"
PACKS_DIR="$HOOKS_DIR/sound-packs"
ACTIVE_FILE="$PACKS_DIR/.active"
VOLUME_FILE="$PACKS_DIR/.volume"
ENABLED_FILE="$PACKS_DIR/.enabled"
SETTINGS_FILE="$HOME/.claude/settings.json"

EVENTS=("SessionStart" "UserPromptSubmit" "Notification" "Stop")
FILES=("session-start.wav" "prompt-submit.wav" "notification.wav" "stop.wav")

ACTION="${1:-list}"
ARG="$2"

# --- Helper functions ---

get_active() {
  if [ -f "$ACTIVE_FILE" ]; then
    tr -d '[:space:]' < "$ACTIVE_FILE"
  else
    echo ""
  fi
}

get_volume() {
  if [ -f "$VOLUME_FILE" ]; then
    tr -d '[:space:]' < "$VOLUME_FILE"
  else
    echo "0.5"
  fi
}

is_enabled() {
  if [ -f "$ENABLED_FILE" ]; then
    val=$(tr -d '[:space:]' < "$ENABLED_FILE")
    [ "$val" = "true" ]
  else
    return 0
  fi
}

inject_hooks() {
  local pack=$(get_active)
  local vol=$(get_volume)
  local pack_path="$PACKS_DIR/$pack"

  if [ ! -d "$pack_path" ]; then
    echo "Error: active pack '$pack' not found"
    return 1
  fi

  local tmp=$(mktemp)
  local jq_expr=""
  for i in "${!EVENTS[@]}"; do
    local event="${EVENTS[$i]}"
    local file="${FILES[$i]}"
    local cmd="afplay -v $vol $pack_path/$file"
    if [ -n "$jq_expr" ]; then
      jq_expr="$jq_expr | "
    fi
    jq_expr="$jq_expr.hooks.${event} = [{\"hooks\": [{\"type\": \"command\", \"command\": \"$cmd\"}]}]"
  done

  jq "$jq_expr" "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
}

remove_hooks() {
  local tmp=$(mktemp)
  local jq_expr=""
  for event in "${EVENTS[@]}"; do
    if [ -n "$jq_expr" ]; then
      jq_expr="$jq_expr | "
    fi
    jq_expr="${jq_expr}del(.hooks.${event})"
  done

  jq "$jq_expr" "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
}

# --- Commands ---

case "$ACTION" in
  list)
    active=$(get_active)
    vol=$(get_volume)
    if is_enabled; then
      state="on"
    else
      state="off"
    fi

    echo "Sound packs (volume: $vol, sounds: $state):"
    for dir in "$PACKS_DIR"/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      if [ "$name" = "$active" ]; then
        echo "  * $name (active)"
      else
        echo "    $name"
      fi
    done
    ;;

  set)
    if [ -z "$ARG" ]; then
      echo "Usage: sound-pack.sh set <pack-name>"
      exit 1
    fi

    pack_path="$PACKS_DIR/$ARG"
    if [ ! -d "$pack_path" ]; then
      echo "Sound pack not found: $ARG"
      echo "Available packs:"
      for dir in "$PACKS_DIR"/*/; do
        [ -d "$dir" ] || continue
        echo "  $(basename "$dir")"
      done
      exit 1
    fi

    for file in "${FILES[@]}"; do
      if [ ! -f "$pack_path/$file" ]; then
        echo "Missing file in pack: $file"
        exit 1
      fi
    done

    echo "$ARG" > "$ACTIVE_FILE"

    if is_enabled; then
      inject_hooks
    fi

    echo "Switched to sound pack: $ARG"
    ;;

  current)
    active=$(get_active)
    if [ -n "$active" ]; then
      echo "$active"
    else
      echo "No active sound pack"
      exit 1
    fi
    ;;

  volume)
    if [ -z "$ARG" ]; then
      echo "$(get_volume)"
    else
      if ! echo "$ARG" | grep -qE '^[01](\.[0-9]+)?$'; then
        echo "Volume must be between 0.0 and 1.0"
        exit 1
      fi
      echo "$ARG" > "$VOLUME_FILE"

      if is_enabled; then
        inject_hooks
      fi

      echo "Volume set to $ARG"
    fi
    ;;

  on)
    echo "true" > "$ENABLED_FILE"
    inject_hooks
    echo "Sounds enabled"
    ;;

  off)
    echo "false" > "$ENABLED_FILE"
    remove_hooks
    echo "Sounds disabled"
    ;;

  status)
    active=$(get_active)
    vol=$(get_volume)
    if is_enabled; then
      state="on"
    else
      state="off"
    fi
    echo "Pack: $active"
    echo "Volume: $vol"
    echo "Sounds: $state"
    ;;

  *)
    echo "Usage: sound-pack.sh <list|set|current|volume|on|off|status> [arg]"
    exit 1
    ;;
esac
