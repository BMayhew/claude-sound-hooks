#!/bin/bash
set -e

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
PACKS_DIR="$HOOKS_DIR/sound-packs"
SKILLS_DIR="$CLAUDE_DIR/skills/sound-pack"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# --- Remove hooks from settings.json ---

if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
  EVENTS=("SessionStart" "UserPromptSubmit" "Notification" "Stop")
  jq_expr=""
  for event in "${EVENTS[@]}"; do
    if [ -n "$jq_expr" ]; then
      jq_expr="$jq_expr | "
    fi
    jq_expr="${jq_expr}del(.hooks.${event})"
  done

  tmp=$(mktemp)
  jq "$jq_expr" "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
  echo "Removed sound hooks from settings.json"
fi

# --- Remove installed files ---

if [ -f "$HOOKS_DIR/sound-pack.sh" ]; then
  rm "$HOOKS_DIR/sound-pack.sh"
  echo "Removed sound-pack.sh"
fi

# Remove old script if still present
if [ -f "$HOOKS_DIR/switch-sound-pack.sh" ]; then
  rm "$HOOKS_DIR/switch-sound-pack.sh"
  echo "Removed old switch-sound-pack.sh"
fi

if [ -d "$SKILLS_DIR" ]; then
  rm -rf "$SKILLS_DIR"
  echo "Removed skill"
fi

if [ -d "$PACKS_DIR" ]; then
  rm -rf "$PACKS_DIR"
  echo "Removed sound packs"
fi

echo ""
echo "Sound pack uninstalled."
