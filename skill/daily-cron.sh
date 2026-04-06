#!/bin/bash
# daily-cron.sh - 毎日自動でその日のFlipBookを生成する
#
# Supported agents:
#   - Claude Code (~/.claude/projects/)
#   - OpenAI Codex CLI (~/.codex/sessions/)
#   - GitHub Copilot CLI (~/.copilot/session-state/)
#
# Usage:
#   ./daily-cron.sh              # 今日分を生成
#   ./daily-cron.sh 2026-04-05   # 指定日を生成
#
# Setup (launchd):
#   cp skill/com.cc-books.daily.plist ~/Library/LaunchAgents/
#   launchctl load ~/Library/LaunchAgents/com.cc-books.daily.plist
#
# Setup (cron):
#   crontab -e
#   55 23 * * * /path/to/cc-books/skill/daily-cron.sh

set -euo pipefail

DATE="${1:-$(date +%Y-%m-%d)}"
YEAR=$(echo "$DATE" | cut -d'-' -f1)
MONTH=$(echo "$DATE" | cut -d'-' -f2)
DAY=$(echo "$DATE" | cut -d'-' -f3)
OUTPUT_DIR="/tmp/claude/daily-flipbook"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.html"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Skip if already generated today
if [ -f "$OUTPUT_FILE" ]; then
  echo "Already generated: $OUTPUT_FILE"
  exit 0
fi

mkdir -p "$OUTPUT_DIR"

touch -t "$(echo "$DATE" | tr -d '-')0000" /tmp/ccbooks_date_marker 2>/dev/null || true

SESSION_COUNT=0
SESSION_DATA=""

# ── 1. Claude Code sessions ──
CLAUDE_PATHS=(
  "$HOME/.claude/projects"
  "$HOME/claude-data/projects"
)

for search_path in "${CLAUDE_PATHS[@]}"; do
  [ ! -d "$search_path" ] && continue

  while IFS= read -r logfile; do
    [ -z "$logfile" ] && continue

    msgs=$(jq -r 'select(.type == "user") | .message.content | if type == "array" then map(select(.type == "text") | .text) | join(" ") elif type == "string" then . else empty end | .[0:200]' "$logfile" 2>/dev/null | grep -v "^$" | grep -v "^<" | head -8)

    if [ -n "$msgs" ]; then
      SESSION_COUNT=$((SESSION_COUNT + 1))
      SESSION_DATA="$SESSION_DATA
=== Session $SESSION_COUNT [Claude Code] ===
$msgs
"
    fi
  done < <(find "$search_path" -name "*.jsonl" -newer /tmp/ccbooks_date_marker -not -path "*/subagents/*" 2>/dev/null)
done

# ── 2. OpenAI Codex CLI sessions ──
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CODEX_SESSION_DIR="$CODEX_HOME/sessions/$YEAR/$MONTH/$DAY"

if [ -d "$CODEX_SESSION_DIR" ]; then
  while IFS= read -r logfile; do
    [ -z "$logfile" ] && continue

    msgs=$(jq -r 'select(.item.type == "event_msg") | .item.payload | select(.type == "user_message") | .message | .[0:200]' "$logfile" 2>/dev/null | grep -v "^$" | head -8)

    if [ -n "$msgs" ]; then
      SESSION_COUNT=$((SESSION_COUNT + 1))
      SESSION_DATA="$SESSION_DATA
=== Session $SESSION_COUNT [Codex CLI] ===
$msgs
"
    fi
  done < <(find "$CODEX_SESSION_DIR" -name "rollout-*.jsonl" 2>/dev/null)
fi

# ── 3. GitHub Copilot CLI sessions ──
COPILOT_STATE_DIR="$HOME/.copilot/session-state"

if [ -d "$COPILOT_STATE_DIR" ]; then
  while IFS= read -r logfile; do
    [ -z "$logfile" ] && continue

    msgs=$(jq -r 'select(.role == "user" or .type == "user") | (.content // .message // .text // empty) | if type == "array" then map(select(.type == "text") | .text) | join(" ") elif type == "string" then . else empty end | .[0:200]' "$logfile" 2>/dev/null | grep -v "^$" | grep -v "^<" | head -8)

    if [ -n "$msgs" ]; then
      SESSION_COUNT=$((SESSION_COUNT + 1))
      SESSION_DATA="$SESSION_DATA
=== Session $SESSION_COUNT [Copilot CLI] ===
$msgs
"
    fi
  done < <(find "$COPILOT_STATE_DIR" -name "events.jsonl" -newer /tmp/ccbooks_date_marker 2>/dev/null)
fi

# ── Generate ──

if [ "$SESSION_COUNT" -eq 0 ]; then
  echo "No sessions found for $DATE"
  exit 0
fi

# Save session data for processing
echo "$SESSION_DATA" > "$OUTPUT_DIR/.pending-$DATE.txt"

# Try to generate via Claude Code (if available)
if command -v claude &>/dev/null; then
  claude -p "$(cat <<EOF
$OUTPUT_DIR/.pending-$DATE.txt を読んで、$DATE のFlipBookを生成してください。

テンプレートは $SCRIPT_DIR/template.html を参考に。
出力先: $OUTPUT_FILE

セッション数: $SESSION_COUNT
日付: $DATE

セッションの内容を3-5章にまとめて、各章にタイトルをつけて、
FlipBookのpages配列としてHTMLを生成してください。
セッションのソース（Claude Code / Codex CLI / Copilot CLI）も章に反映してください。

また、$OUTPUT_DIR/books.json にこの本のエントリを追加してください。
books.jsonが存在しない場合は新規作成。
既に同じ日付のエントリがあれば上書き。
EOF
  )" 2>/dev/null

  if [ -f "$OUTPUT_FILE" ]; then
    rm -f "$OUTPUT_DIR/.pending-$DATE.txt"
    echo "Generated: $OUTPUT_FILE ($SESSION_COUNT sessions)"

    # macOS notification
    osascript -e "display notification \"$DATE の本を生成しました ($SESSION_COUNT sessions)\" with title \"CC Books\" sound name \"Tink\"" 2>/dev/null || true
    # Linux notification
    notify-send "CC Books" "$DATE の本を生成しました ($SESSION_COUNT sessions)" 2>/dev/null || true
  else
    echo "Claude generation failed. Session data saved to: $OUTPUT_DIR/.pending-$DATE.txt"
    echo "Run '/daily-flipbook' manually in Claude Code to generate."
  fi
# Try Codex CLI
elif command -v codex &>/dev/null; then
  codex -q "$(cat <<EOF
Read $OUTPUT_DIR/.pending-$DATE.txt and generate a FlipBook HTML for $DATE.
Use $SCRIPT_DIR/template.html as reference.
Output to: $OUTPUT_FILE
Sessions: $SESSION_COUNT, Date: $DATE
Group sessions into 3-5 chapters. Include the source agent (Claude Code / Codex CLI / Copilot CLI) in each chapter.
Also update $OUTPUT_DIR/books.json.
EOF
  )" 2>/dev/null

  if [ -f "$OUTPUT_FILE" ]; then
    rm -f "$OUTPUT_DIR/.pending-$DATE.txt"
    echo "Generated: $OUTPUT_FILE ($SESSION_COUNT sessions)"
  else
    echo "Codex generation failed. Session data saved to: $OUTPUT_DIR/.pending-$DATE.txt"
  fi
# Try Copilot CLI
elif command -v copilot &>/dev/null; then
  echo "Session data saved to: $OUTPUT_DIR/.pending-$DATE.txt"
  echo "Run 'copilot' and ask it to generate the FlipBook from the session data."
else
  echo "No AI CLI found. Session data saved to: $OUTPUT_DIR/.pending-$DATE.txt"
  echo "Install claude, codex, or copilot CLI and run '/daily-flipbook' to generate."
fi
