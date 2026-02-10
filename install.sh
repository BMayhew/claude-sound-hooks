#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
PACKS_DIR="$HOOKS_DIR/sound-packs"
SKILLS_DIR="$CLAUDE_DIR/skills/sound-pack"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Guards ---

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

if [ ! -d "$CLAUDE_DIR" ]; then
  echo "Error: ~/.claude/ not found. Run Claude Code at least once first."
  exit 1
fi

# --- Copy files ---

mkdir -p "$HOOKS_DIR" "$PACKS_DIR" "$SKILLS_DIR"

# Copy script
cp "$SCRIPT_DIR/scripts/sound-pack.sh" "$HOOKS_DIR/sound-pack.sh"
chmod +x "$HOOKS_DIR/sound-pack.sh"
echo "Installed sound-pack.sh"

# Copy skill
cp "$SCRIPT_DIR/skill/SKILL.md" "$SKILLS_DIR/SKILL.md"
echo "Installed SKILL.md"

# Copy packs (no-clobber - don't overwrite existing packs)
for pack_dir in "$SCRIPT_DIR"/packs/*/; do
  [ -d "$pack_dir" ] || continue
  pack_name=$(basename "$pack_dir")
  dest="$PACKS_DIR/$pack_name"
  if [ -d "$dest" ]; then
    echo "Pack '$pack_name' already exists, skipping"
  else
    cp -r "$pack_dir" "$dest"
    echo "Installed pack: $pack_name"
  fi
done

# --- Init state files ---

if [ ! -f "$PACKS_DIR/.active" ]; then
  echo "wow-peasant" > "$PACKS_DIR/.active"
fi

if [ ! -f "$PACKS_DIR/.volume" ]; then
  echo "0.5" > "$PACKS_DIR/.volume"
fi

if [ ! -f "$PACKS_DIR/.enabled" ]; then
  echo "true" > "$PACKS_DIR/.enabled"
fi

# --- Inject hooks into settings.json ---

if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# Read current state
ACTIVE=$(tr -d '[:space:]' < "$PACKS_DIR/.active")
VOLUME=$(tr -d '[:space:]' < "$PACKS_DIR/.volume")
ENABLED=$(tr -d '[:space:]' < "$PACKS_DIR/.enabled")
PACK_PATH="$PACKS_DIR/$ACTIVE"

if [ "$ENABLED" = "true" ]; then
  EVENTS=("SessionStart" "UserPromptSubmit" "Notification" "Stop")
  WAV_FILES=("session-start.wav" "prompt-submit.wav" "notification.wav" "stop.wav")

  jq_expr=""
  for i in "${!EVENTS[@]}"; do
    event="${EVENTS[$i]}"
    file="${WAV_FILES[$i]}"
    cmd="afplay -v $VOLUME $PACK_PATH/$file"
    if [ -n "$jq_expr" ]; then
      jq_expr="$jq_expr | "
    fi
    jq_expr="$jq_expr.hooks.${event} = [{\"hooks\": [{\"type\": \"command\", \"command\": \"$cmd\"}]}]"
  done

  tmp=$(mktemp)
  # Ensure .hooks exists
  jq '.hooks //= {}' "$SETTINGS_FILE" | jq "$jq_expr" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
  echo "Injected sound hooks into settings.json"
fi

# --- Migration: remove old script ---

OLD_SCRIPT="$HOOKS_DIR/switch-sound-pack.sh"
if [ -f "$OLD_SCRIPT" ]; then
  rm "$OLD_SCRIPT"
  echo "Removed old switch-sound-pack.sh"
fi

echo ""
echo "Sound pack installed successfully!"
echo "Use /sound-pack to manage your sounds."
