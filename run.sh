#!/bin/bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BENCH_DIR/local_env.sh"

INSPECT_EVALS="gsm8k" # TODO: comma-separated benchmark ids, example: `gsm8k` or `gsm8k,aime2025`
AGENT="" # TODO: set to agent you want to use, example: `codex`, `local_codex`, `local_opencode`
MODEL_TO_TRAIN="" # TODO: set to a HuggingFace model id or local model path, example: Qwen/Qwen3-1.7B-Base; Qwen/Qwen3-4B-Base; HuggingFaceTB/SmolLM3-3B-Base; google/gemma-3-4b-pt
NUM_HOURS="10" # TODO: set the solve time budget in hours, default: 10
NUM_GPUS="1" # TODO: set to 1; currently passed through but not used by local_codex, default: 1

for required_var in INSPECT_EVALS AGENT MODEL_TO_TRAIN NUM_HOURS NUM_GPUS; do
    if [ -z "${!required_var}" ]; then
        echo "Set $required_var near the top of run.sh before running."
        exit 1
    fi
done

echo "Starting task"
echo "  inspect_evals: $INSPECT_EVALS"
echo "  agent: $AGENT"
echo "  model_to_train: $MODEL_TO_TRAIN"
echo "  num_hours: $NUM_HOURS"
echo "  num_gpus: $NUM_GPUS"

cd "$BENCH_DIR"

CHILD_PID=""
cleanup_all() {
    local exit_code=$?
    trap - EXIT INT TERM

    if [[ -n "${CHILD_PID}" ]]; then
        pkill -TERM -s "${CHILD_PID}" 2>/dev/null || true
        kill -TERM -"${CHILD_PID}" 2>/dev/null || true
        sleep 5
        pkill -KILL -s "${CHILD_PID}" 2>/dev/null || true
        kill -KILL -"${CHILD_PID}" 2>/dev/null || true
    fi

    exit "$exit_code"
}
trap cleanup_all EXIT INT TERM

setsid bash src/run_task.sh "$INSPECT_EVALS" "$AGENT" "$MODEL_TO_TRAIN" "$NUM_HOURS" "$NUM_GPUS" &
CHILD_PID=$!
wait "$CHILD_PID"
CHILD_PID=""
