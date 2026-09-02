#!/bin/bash
# Self-check for hooks/play.sh resolution logic. Run: bash tests/test-play.sh
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PLAY="$REPO/hooks/play.sh"
FAILED=0

check() {
  # $1 = description, $2 = expected, $3 = actual
  if [ "$2" = "$3" ]; then
    echo "ok   - $1"
  else
    echo "FAIL - $1"
    echo "       expected: $2"
    echo "       actual:   $3"
    FAILED=1
  fi
}

FAKE_HOME=$(mktemp -d)
trap 'rm -rf "$FAKE_HOME"' EXIT
PACKS="$FAKE_HOME/.claude/hooks/sound-packs"
mkdir -p "$PACKS"

run() { HOME="$FAKE_HOME" SOUND_DRY_RUN=1 bash "$PLAY" "$@" 2>&1; }

# Defaults: no state files at all -> bundled wow-peasant at volume 0.5
check "default pack and volume" \
  "afplay -v 0.5 $REPO/packs/wow-peasant/stop.wav" \
  "$(run stop)"

# Disabled
echo false > "$PACKS/.enabled"
check "disabled plays nothing" "" "$(run stop)"
echo true > "$PACKS/.enabled"

# Volume is read at playback time
echo 0.1 > "$PACKS/.volume"
check "volume from state file" \
  "afplay -v 0.1 $REPO/packs/wow-peasant/stop.wav" \
  "$(run stop)"
echo 0.5 > "$PACKS/.volume"

# A user pack shadows the bundled pack of the same name
mkdir -p "$PACKS/wow-peasant"
touch "$PACKS/wow-peasant/stop.wav"
check "user pack shadows bundled" \
  "afplay -v 0.5 $PACKS/wow-peasant/stop.wav" \
  "$(run stop)"

# That shadowing pack has no notification file -> silence, exit 0
check "missing file is silent" "" "$(run notification)"
run notification
check "missing file exits 0" "0" "$?"
rm -rf "$PACKS/wow-peasant"

# MP3 packs resolve too
echo lightsaber > "$PACKS/.active"
check "mp3 pack resolves" \
  "afplay -v 0.5 $REPO/packs/lightsaber/stop.mp3" \
  "$(run stop)"
echo wow-peasant > "$PACKS/.active"

# An unrelated afplay hook of the user's own must NOT trip the legacy guard
mkdir -p "$FAKE_HOME/.claude"
echo '{"hooks":{"Notification":[{"hooks":[{"type":"command","command":"afplay /System/Library/Sounds/Glass.aiff"}]}]}}' \
  > "$FAKE_HOME/.claude/settings.json"
check "unrelated afplay hook is not legacy" \
  "afplay -v 0.5 $REPO/packs/sc-terran/stop.wav" \
  "$(echo sc-terran > "$PACKS/.active"; run stop)"
echo wow-peasant > "$PACKS/.active"

# Legacy install.sh hooks still in settings.json -> suppress, warn once
echo '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"afplay -v 0.5 /Users/x/.claude/hooks/sound-packs/wow-peon/stop.wav"}]}]}}' \
  > "$FAKE_HOME/.claude/settings.json"
check "legacy hooks suppress playback" "" "$(run stop)"
case "$(run session-start)" in
  *"/sound-hooks:sound-pack cleanup"*) echo "ok   - legacy hooks warn on session-start" ;;
  *) echo "FAIL - legacy hooks warn on session-start"; FAILED=1 ;;
esac

# An empty state file must fall back to the default, not produce `-v ""`
echo wow-peasant > "$PACKS/.active"
rm -f "$FAKE_HOME/.claude/settings.json"
: > "$PACKS/.volume"
check "empty .volume falls back to default" \
  "afplay -v 0.5 $REPO/packs/wow-peasant/stop.wav" \
  "$(run stop)"
echo 0.5 > "$PACKS/.volume"

# A corrupt audio file must not fail the hook
mkdir -p "$PACKS/broken"
for f in session-start prompt-submit notification stop; do : > "$PACKS/broken/$f.wav"; done
echo broken > "$PACKS/.active"
HOME="$FAKE_HOME" bash "$PLAY" stop >/dev/null 2>&1
check "corrupt audio file still exits 0" "0" "$?"
echo wow-peasant > "$PACKS/.active"

# --- sound-pack.sh cleanup ---

SP="$REPO/scripts/sound-pack.sh"
sp() { HOME="$FAKE_HOME" bash "$SP" "$@" 2>&1; }

check "volume rejects 1.5" "Volume must be between 0.0 and 1.0" "$(sp volume 1.5)"
check "volume accepts 1.0" "Volume set to 1.0" "$(sp volume 1.0)"
echo 0.5 > "$PACKS/.volume"

if command -v jq &>/dev/null; then
  # cleanup keeps a user command sharing a group with a legacy one
  cat > "$FAKE_HOME/.claude/settings.json" <<'EOF'
{"hooks":{"Stop":[{"hooks":[
  {"type":"command","command":"afplay -v 0.5 /Users/x/.claude/hooks/sound-packs/wow-peon/stop.wav"},
  {"type":"command","command":"echo mine"}]}]}}
EOF
  sp cleanup >/dev/null
  check "cleanup keeps a user command in a shared group" \
    "echo mine" \
    "$(HOME=$FAKE_HOME jq -r '.hooks.Stop[0].hooks[0].command' "$FAKE_HOME/.claude/settings.json")"

  # cleanup must not claim success when jq cannot parse the file
  echo '{"hooks":{"Stop":[{"hooks":[{"command":"afplay -v 0.5 /x/sound-packs/a.wav"},]}]}}' \
    > "$FAKE_HOME/.claude/settings.json"
  out=$(sp cleanup); rc=$?
  check "cleanup fails loudly on malformed settings.json" "1" "$rc"
  case "$out" in
    *"Sounds are live again"*) echo "FAIL - cleanup must not claim success on parse error"; FAILED=1 ;;
    *) echo "ok   - cleanup does not claim success on parse error" ;;
  esac

  # cleanup removes the legacy script and skill, not just settings.json
  rm -f "$FAKE_HOME/.claude/settings.json"
  mkdir -p "$FAKE_HOME/.claude/hooks" "$FAKE_HOME/.claude/skills/sound-pack"
  : > "$FAKE_HOME/.claude/hooks/sound-pack.sh"
  : > "$FAKE_HOME/.claude/skills/sound-pack/SKILL.md"
  sp cleanup >/dev/null
  check "cleanup removes legacy script" "gone" \
    "$([ -f "$FAKE_HOME/.claude/hooks/sound-pack.sh" ] || echo gone)"
  check "cleanup removes legacy skill" "gone" \
    "$([ -d "$FAKE_HOME/.claude/skills/sound-pack" ] || echo gone)"

  # A legacy entry cleanup cannot reach must be reported, not silently ignored
  echo '{"hooks":{"SubagentStop":[{"hooks":[{"type":"command","command":"afplay -v 0.5 /x/sound-packs/a.wav"}]}]}}' \
    > "$FAKE_HOME/.claude/settings.json"
  : > "$FAKE_HOME/.claude/hooks/sound-pack.sh"
  out=$(sp cleanup); rc=$?
  check "unreachable legacy entry is reported" "1" "$rc"
  case "$out" in
    *"still contains a legacy sound command"*) echo "ok   - unreachable legacy entry is explained" ;;
    *) echo "FAIL - unreachable legacy entry is explained"; FAILED=1 ;;
  esac
else
  echo "skip - cleanup tests (jq not installed)"
fi

exit $FAILED
