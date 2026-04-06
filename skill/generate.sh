#!/bin/bash
# generate.sh - Extract today's AI coding agent session logs and generate a FlipBook HTML
#
# Supported agents:
#   - Claude Code (~/.claude/projects/)
#   - OpenAI Codex CLI (~/.codex/sessions/)
#   - GitHub Copilot CLI (~/.copilot/session-state/)
#
# Usage: ./generate.sh [YYYY-MM-DD]
# If no date provided, defaults to today.
#
# Output: /tmp/claude/daily-flipbook/YYYY-MM-DD.html

set -euo pipefail

DATE="${1:-$(date +%Y-%m-%d)}"
YEAR=$(echo "$DATE" | cut -d'-' -f1)
MONTH=$(echo "$DATE" | cut -d'-' -f2)
DAY=$(echo "$DATE" | cut -d'-' -f3)
DISPLAY_DATE="${YEAR}年${MONTH}月${DAY}日"

OUTPUT_DIR="/tmp/claude/daily-flipbook"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.html"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="$SCRIPT_DIR/template.html"

mkdir -p "$OUTPUT_DIR"

touch -t "${YEAR}${MONTH}${DAY}0000" /tmp/flipbook_date_marker 2>/dev/null || true

SESSIONS_FILE="/tmp/flipbook_sessions_$DATE.txt"
rm -f "$SESSIONS_FILE"

SESSION_COUNT=0

# ══════════════════════════════════════════════
# 1. Claude Code sessions
# ══════════════════════════════════════════════
CLAUDE_PATHS=(
  "$HOME/.claude/projects"
  "$HOME/claude-data/projects"
)

for search_path in "${CLAUDE_PATHS[@]}"; do
  [ ! -d "$search_path" ] && continue

  while IFS= read -r logfile; do
    [ -z "$logfile" ] && continue

    project_dir=$(basename "$(dirname "$logfile")")

    if command -v jq &>/dev/null; then
      user_msgs=$(jq -r '
        select(.type == "user")
        | .message.content
        | if type == "array" then
            map(select(.type == "text") | .text) | join(" ")
          elif type == "string" then .
          else empty
          end
        | .[0:200]
      ' "$logfile" 2>/dev/null | head -20)

      tool_actions=$(jq -r '
        select(.type == "assistant")
        | .message.content[]?
        | select(.type == "tool_use")
        | "\(.name): \(.input.file_path // .input.command // .input.pattern // "" | .[0:100])"
      ' "$logfile" 2>/dev/null | head -30)

      if [ -n "$user_msgs" ]; then
        SESSION_COUNT=$((SESSION_COUNT + 1))
        echo "--- Session $SESSION_COUNT [Claude Code]: $project_dir ---" >> "$SESSIONS_FILE"
        echo "$user_msgs" >> "$SESSIONS_FILE"
        echo "" >> "$SESSIONS_FILE"
        if [ -n "$tool_actions" ]; then
          echo "Tools used:" >> "$SESSIONS_FILE"
          echo "$tool_actions" >> "$SESSIONS_FILE"
          echo "" >> "$SESSIONS_FILE"
        fi
      fi
    fi
  done < <(find "$search_path" -name "*.jsonl" -newer /tmp/flipbook_date_marker -not -path "*/subagents/*" 2>/dev/null)
done

# ══════════════════════════════════════════════
# 2. OpenAI Codex CLI sessions
# ══════════════════════════════════════════════
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CODEX_SESSION_DIR="$CODEX_HOME/sessions/$YEAR/$MONTH/$DAY"

if [ -d "$CODEX_SESSION_DIR" ]; then
  while IFS= read -r logfile; do
    [ -z "$logfile" ] && continue

    if command -v jq &>/dev/null; then
      # Extract user messages from Codex rollout JSONL
      user_msgs=$(jq -r '
        select(.item.type == "event_msg")
        | .item.payload
        | select(.type == "user_message")
        | .message
        | .[0:200]
      ' "$logfile" 2>/dev/null | head -20)

      # Extract command executions
      tool_actions=$(jq -r '
        select(.item.type == "event_msg")
        | .item.payload
        | select(.type == "exec_command_begin")
        | "exec: \(.command | .[0:100])"
      ' "$logfile" 2>/dev/null | head -30)

      # Also extract function calls
      func_calls=$(jq -r '
        select(.item.type == "response_item")
        | .item
        | select(.type == "function_call")
        | "\(.name): \(.arguments | .[0:100])"
      ' "$logfile" 2>/dev/null | head -20)

      if [ -n "$user_msgs" ]; then
        SESSION_COUNT=$((SESSION_COUNT + 1))
        echo "--- Session $SESSION_COUNT [Codex CLI]: $(basename "$logfile" .jsonl) ---" >> "$SESSIONS_FILE"
        echo "$user_msgs" >> "$SESSIONS_FILE"
        echo "" >> "$SESSIONS_FILE"
        all_actions=""
        [ -n "$tool_actions" ] && all_actions="$tool_actions"
        [ -n "$func_calls" ] && all_actions="${all_actions:+$all_actions
}$func_calls"
        if [ -n "$all_actions" ]; then
          echo "Tools used:" >> "$SESSIONS_FILE"
          echo "$all_actions" >> "$SESSIONS_FILE"
          echo "" >> "$SESSIONS_FILE"
        fi
      fi
    fi
  done < <(find "$CODEX_SESSION_DIR" -name "rollout-*.jsonl" 2>/dev/null)
fi

# ══════════════════════════════════════════════
# 3. GitHub Copilot CLI sessions
# ══════════════════════════════════════════════
COPILOT_STATE_DIR="$HOME/.copilot/session-state"

if [ -d "$COPILOT_STATE_DIR" ]; then
  while IFS= read -r logfile; do
    [ -z "$logfile" ] && continue

    session_id=$(basename "$(dirname "$logfile")")

    if command -v jq &>/dev/null; then
      # Extract user messages from Copilot events.jsonl
      user_msgs=$(jq -r '
        select(.role == "user" or .type == "user")
        | (.content // .message // .text // empty)
        | if type == "array" then
            map(select(.type == "text") | .text) | join(" ")
          elif type == "string" then .
          else empty
          end
        | .[0:200]
      ' "$logfile" 2>/dev/null | head -20)

      # Extract tool calls
      tool_actions=$(jq -r '
        select(.type == "tool_call" or .type == "call_tool" or .name != null)
        | "\(.name // .tool // "action"): \(.arguments // .input // "" | tostring | .[0:100])"
      ' "$logfile" 2>/dev/null | head -30)

      if [ -n "$user_msgs" ]; then
        SESSION_COUNT=$((SESSION_COUNT + 1))
        echo "--- Session $SESSION_COUNT [Copilot CLI]: $session_id ---" >> "$SESSIONS_FILE"
        echo "$user_msgs" >> "$SESSIONS_FILE"
        echo "" >> "$SESSIONS_FILE"
        if [ -n "$tool_actions" ]; then
          echo "Tools used:" >> "$SESSIONS_FILE"
          echo "$tool_actions" >> "$SESSIONS_FILE"
          echo "" >> "$SESSIONS_FILE"
        fi
      fi
    fi
  done < <(find "$COPILOT_STATE_DIR" -name "events.jsonl" -newer /tmp/flipbook_date_marker 2>/dev/null)
fi

# ══════════════════════════════════════════════
# Output results
# ══════════════════════════════════════════════

if [ ! -f "$SESSIONS_FILE" ] || [ ! -s "$SESSIONS_FILE" ]; then
  echo "No session logs found for $DATE"
  echo "Searched paths:"
  for p in "${CLAUDE_PATHS[@]}"; do
    echo "  - $p (Claude Code)"
  done
  echo "  - $CODEX_SESSION_DIR (Codex CLI)"
  echo "  - $COPILOT_STATE_DIR (Copilot CLI)"
  exit 1
fi

echo "Found $SESSION_COUNT sessions for $DATE"
echo "Session data saved to: $SESSIONS_FILE"
echo ""
echo "To generate the FlipBook, run this in Claude Code:"
echo ""
echo "  /daily-flipbook"
echo ""
echo "Or ask your AI coding agent:"
echo "  \"$SESSIONS_FILE を読んで、template.html をベースに FlipBook を生成して\""
echo ""
echo "Template: $TEMPLATE"
echo "Output will be: $OUTPUT_FILE"
