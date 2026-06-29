#!/bin/bash

OPENCODE_MODEL="example-openai-compatible/your-model-name"

WORK_DIR=$1
CURRENT_FILE_DIR="$(cd -- "$(dirname -- "$0")" && pwd -P)"

# ====================
# Initialize OpenCode HOME
# ====================
rm -rf "$HOME/.opencode" "$HOME/.config/opencode" "$HOME/.local/share/opencode"

cp -r "$CURRENT_FILE_DIR/opencode_home" "$HOME/.opencode"
cp "$CURRENT_FILE_DIR/opencode_home/opencode.json" "$WORK_DIR/opencode.json"

mkdir -p "$HOME/.opencode/bin"
cp "$CURRENT_FILE_DIR/opencode" "$HOME/.opencode/bin/opencode"
chmod +x "$HOME/.opencode/bin/opencode"

# ====================
# Prepare agent workspace instruction files
# ====================
if [ "$USE_CUSTOM_PROMPT" = "1" ]; then
    cp "$CURRENT_FILE_DIR/workspace_files/AGENTS.md" "$WORK_DIR/AGENTS.md"
else # Baseline evaluation mode
    cp "$CURRENT_FILE_DIR/workspace_files/AGENTS_baseline.md" "$WORK_DIR/AGENTS.md"
    rm -rf "$HOME/.opencode/skills"
fi
cp "$CURRENT_FILE_DIR/workspace_files/000_READ_BEFORE_ANY_ACTION.txt" "$WORK_DIR/000_READ_BEFORE_ANY_ACTION.txt" # Put this warning where OpenCode is likely to read it early.

# ====================
# Run local_opencode
# ====================
MIN_REMAINING_MINUTES=30
cd "$WORK_DIR"

"$HOME/.opencode/bin/opencode" run --model "$OPENCODE_MODEL" --format json "$PROMPT"

# Continue if the agent exits early and enough time remains.
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

    "$HOME/.opencode/bin/opencode" run --continue --model "$OPENCODE_MODEL" --format json "$CONTINUATION_PROMPT"
done
