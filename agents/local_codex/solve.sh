#!/bin/bash

WORK_DIR=$1
CURRENT_FILE_DIR="$(cd -- "$(dirname -- "$0")" && pwd -P)"

# ====================
# Initialize Codex HOME
# ====================
rm -rf "$HOME/.codex"
cp -r "$CURRENT_FILE_DIR/codex_home" "$HOME/.codex" 
mkdir -p "$HOME/.local/bin"
cp "$CURRENT_FILE_DIR/codex" "$HOME/.local/bin/codex"
chmod +x "$HOME/.local/bin/codex"

# ====================
# Prepare agent workspace instruction files
# ====================
if [ "$USE_CUSTOM_PROMPT" = "1" ]; then
    cp "$CURRENT_FILE_DIR/workspace_files/AGENTS.md" "$WORK_DIR/AGENTS.md"
else # Baseline evaluation mode
    cp "$CURRENT_FILE_DIR/workspace_files/AGENTS_baseline.md" "$WORK_DIR/AGENTS.md"
    rm -rf "$HOME/.codex/skills"
fi

# ====================
# Run local_codex
# ====================
MIN_REMAINING_MINUTES=30
cd "$WORK_DIR"

"$HOME/.local/bin/codex" --search exec --json -c model_reasoning_summary=detailed --skip-git-repo-check --yolo "$PROMPT"

# Resume if the agent exits early and enough time remains.
while true; do
    TIMER_OUTPUT=$(bash timer.sh 2>/dev/null)
    if echo "$TIMER_OUTPUT" | grep -q "expired"; then
        break
    fi

    REMAINING_HOURS=$(echo "$TIMER_OUTPUT" | grep -oP '^\d+(?=:)')
    REMAINING_MINS=$(echo "$TIMER_OUTPUT" | grep -oP '(?<=:)\d+')
    REMAINING_HOURS=${REMAINING_HOURS:-0}
    REMAINING_MINS=${REMAINING_MINS:-0}
    TOTAL_REMAINING_MINS=$(( 10#$REMAINING_HOURS * 60 + 10#$REMAINING_MINS )) # Force base-10 so 08 and 09 do not break arithmetic.
    echo "remaining time: ${REMAINING_HOURS}h ${REMAINING_MINS}m"

    if [ "$TOTAL_REMAINING_MINS" -lt "$MIN_REMAINING_MINUTES" ]; then # Stop when less than 30 minutes remain.
        break
    fi

    CONTINUATION_PROMPT="You still have ${REMAINING_HOURS}h ${REMAINING_MINS}m remaining. Please continue improving your result and maximize performance."

    "$HOME/.local/bin/codex" --search exec resume --last --json -c model_reasoning_summary=detailed --skip-git-repo-check --yolo "$CONTINUATION_PROMPT"
done
