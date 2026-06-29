#!/bin/bash
# Local runner: no apptainer, no fuse-overlayfs.
# NUM_GPUS is still passed through, but local agents do not currently consume it.

INSPECT_EVALS_ARG="$1"
AGENT="$2"
MODEL_TO_TRAIN="$3"
NUM_HOURS="$4"
NUM_GPUS="${5:-1}"

IFS=',' read -r -a INSPECT_EVALS <<< "$INSPECT_EVALS_ARG"
export EVALUATION_TASK="${INSPECT_EVALS_ARG//,/_}"
export USE_CUSTOM_PROMPT="${USE_CUSTOM_PROMPT:-1}" # 0 means baseline; 1 uses workspace_files/AGENTS.md and skills.

AGENT_CONFIG_LABEL="${AGENT}_default"
AGENT_CONFIG_SAFE=$(echo "$AGENT_CONFIG_LABEL" | tr '/:[]' '____')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

export EVAL_DIR="results/${AGENT_CONFIG_SAFE}/${EVALUATION_TASK}/${TIMESTAMP}"
sudo mkdir -p "$POSTTRAIN_WORK_BASE"
sudo chown "$POSTTRAIN_CHOWN_USER:$POSTTRAIN_CHOWN_USER" "$POSTTRAIN_WORK_BASE"
rm -rf "$POSTTRAIN_WORK_BASE"/* # Clear the shared workspace to avoid stale task files.
export TMP_SUBDIR="${POSTTRAIN_WORK_BASE}/posttrain_local_${EVALUATION_TASK}_${TIMESTAMP}"

JOB_DIR="${TMP_SUBDIR}/job_dir"
SOLVE_OUT="${EVAL_DIR}/solve_out.txt"
POST_HF_DIR="$POSTTRAIN_BENCH_DIR/resources/post_hf"

export HOME="${JOB_DIR}" # Isolate agent config and cache.
export HF_HOME="$POST_HF_DIR"
source src/commit_utils/set_env_vars.sh

export PIP_USER=1 # Install pip user packages under the current job directory by default.
unset PYTHONNOUSERSITE # Re-enable the current job's user site after set_env_vars.sh disables it.
export PYTHONUSERBASE="$HOME/.local" # Keep agent-installed packages out of the shared Python environment.
export PATH="$PYTHONUSERBASE/bin:$PATH" # Prefer job-local console scripts.
hash -r # Refresh shell command lookup cache.

print_section() {
    echo "================================"
    echo "$1"
    echo "================================"
}

prepare_workspace() {
    mkdir -p "${EVAL_DIR}"
    exec 1>"${EVAL_DIR}/output.log" # Redirect stdout to the run log.
    exec 2>"${EVAL_DIR}/error.log" # Redirect stderr to the error log.

    echo "$@"

    mkdir -p "${JOB_DIR}/task"

    echo "Preparing local job directory..."

    cp -r src/eval/templates "${JOB_DIR}/task/"
    mkdir -p "${JOB_DIR}/task/evaluate"

    local eval_task
    for eval_task in "${INSPECT_EVALS[@]}"; do
        rm -rf "src/eval/tasks/${eval_task}/results" # Hide stale evaluation outputs from the agent workspace.
        cp -r "src/eval/tasks/${eval_task}" "${JOB_DIR}/task/evaluate/"
    done
    cp src/utils/check_cuda.py "${JOB_DIR}/check_cuda.py"
    cp src/utils/check_cuda_writing.py "${JOB_DIR}/check_cuda_writing.py"
    cp src/utils/system_monitor.sh "${JOB_DIR}/system_monitor.sh"
    cp src/utils/timestamp_lines.py "${JOB_DIR}/timestamp_lines.py"
    mkdir -p "${JOB_DIR}/agents"
    cp -r "agents/${AGENT}" "${JOB_DIR}/agents/"
    if [ ! -d "$POST_HF_DIR" ]; then
        echo "Missing post_hf directory: $POST_HF_DIR"
        exit 1
    fi
    ln -s "$POST_HF_DIR" "${JOB_DIR}/task/post_hf"

    PROMPT=$(python src/eval/general/get_prompt.py --model-to-train "$MODEL_TO_TRAIN" --num-hours "$NUM_HOURS" --agent "${AGENT}" --eval-tasks "$(IFS=,; echo "${INSPECT_EVALS[*]}")")
    echo "$PROMPT" > "${EVAL_DIR}/prompt.txt"
    bash src/utils/create_timer.sh "$NUM_HOURS" "${JOB_DIR}/task/timer.sh"
}

with_record_the_time() {
    local begin=$(date --iso-8601=seconds)
    "$@"
    local exit_code=$?
    local end=$(date --iso-8601=seconds)
    local time_taken=$(( $(date --date="$end" +%s) - $(date --date="$begin" +%s) ))
    printf '%02d:%02d:%02d\n' \
        $(( time_taken / 3600 )) \
        $(( (time_taken % 3600) / 60 )) \
        $(( time_taken % 60 )) > "${EVAL_DIR}/time_taken.txt"
    return $exit_code
}

solve_task() {
    WORK_DIR=$1
    export PROMPT="${PROMPT}"
    timeout --signal=TERM --kill-after=30s "$((NUM_HOURS * 60 + 5))m" \
        bash "${JOB_DIR}/agents/${AGENT}/solve.sh" "$WORK_DIR" > "${SOLVE_OUT}" 2>&1
}

post_solve_artifacts() {
    echo "--- SOLVE DIAGNOSTICS ---"
    echo "exit_code: $SOLVE_EXIT"
    if [ "$SOLVE_EXIT" -eq 0 ]; then
        echo "status: exited normally"
    elif [ "$SOLVE_EXIT" -eq 124 ]; then
        echo "status: killed by timeout (reached ${NUM_HOURS}h limit)"
    elif [ "$SOLVE_EXIT" -gt 128 ]; then
        echo "status: killed by signal $((SOLVE_EXIT - 128)) ($(kill -l $((SOLVE_EXIT - 128)) 2>/dev/null || echo unknown))"
    else
        echo "status: exited with error code $SOLVE_EXIT"
    fi
    echo "final_model_files: $(ls "${JOB_DIR}/task/final_model/" 2>/dev/null | wc -l)"
    echo "hostname: $(hostname)"
    echo "disk_job_dir: $(du -sh "${JOB_DIR}" 2>/dev/null | cut -f1)"
    echo "--- END SOLVE DIAGNOSTICS ---"

    print_section "=== TASK COMPLETE, PARSING AGENT TRACE ==="

    TRACE_PARSER="${JOB_DIR}/agents/${AGENT}/human_readable_trace.py"
    if [ -f "$TRACE_PARSER" ]; then
        python "$TRACE_PARSER" "${SOLVE_OUT}" -o "${EVAL_DIR}/solve_parsed.txt"
    else
        cp "${SOLVE_OUT}" "${EVAL_DIR}/solve_parsed.txt"
    fi

    if [ -d "${JOB_DIR}/task/final_model" ]; then
        cp -r "${JOB_DIR}/task/final_model" "$EVAL_DIR/final_model"
    fi

    if [ -f "${JOB_DIR}/task/system_monitor.log" ]; then
        cp "${JOB_DIR}/task/system_monitor.log" "$EVAL_DIR/system_monitor.log"
    fi
}

run_disallowed_usage_judge() {
    print_section "=== RUNNING CONTAMINATION JUDGE ==="

    mkdir -p "${EVAL_DIR}/contamination_judge"

    local eval_task
    local benchmark
    local judge_task

    for eval_task in "${INSPECT_EVALS[@]}"; do
        benchmark=$(cat "src/eval/tasks/${eval_task}/benchmark.txt")
        judge_task=$(python src/disallowed_usage_judge/get_judge_prompt.py \
            --benchmark "${benchmark}" \
            --model "${MODEL_TO_TRAIN}")

        (
            export HOME="/home/$POSTTRAIN_CHOWN_USER" # Use the real home so the judge can read its Codex config.
            unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME
            cd "${JOB_DIR}/task" || exit 1
            "${JOB_DIR}/agents/${AGENT}/codex" --search -a never exec --json \
                -m "gpt-5.1-codex-2025-11-13" \
                -c model_reasoning_effort=medium \
                -c model_reasoning_summary=detailed \
                --skip-git-repo-check \
                --yolo \
                "$judge_task"
        ) 2>&1 | tee "${EVAL_DIR}/contamination_judge/judge_output_${eval_task}.json"

        python "${JOB_DIR}/agents/${AGENT}/human_readable_trace.py" \
            "${EVAL_DIR}/contamination_judge/judge_output_${eval_task}.json" \
            -o "${EVAL_DIR}/contamination_judge/judge_output_${eval_task}.txt"

        if [ -f "${JOB_DIR}/task/contamination_judgement.txt" ]; then
            cp "${JOB_DIR}/task/contamination_judgement.txt" \
                "${EVAL_DIR}/contamination_judge/contamination_judgement_${eval_task}.txt"
        fi

        if [ -f "${JOB_DIR}/task/disallowed_model_judgement.txt" ]; then
            cp "${JOB_DIR}/task/disallowed_model_judgement.txt" \
                "${EVAL_DIR}/contamination_judge/disallowed_model_judgement_${eval_task}.txt"
        fi
    done
}

evaluate_task(){
    mkdir -p "$EVAL_DIR/eval_results"
    export INSPECT_LOG_DIR="$EVAL_DIR/eval_results/outputs" # inspect_ai reads this env var for its log directory.
    local eval_task
    local REPO_ROOT

    REPO_ROOT=$(pwd)
    for eval_task in "${INSPECT_EVALS[@]}"; do
        cd "src/eval/tasks/${eval_task}" || exit 1 # Some evaluation scripts rely on relative paths.
        python "evaluate.py" \
            --model-path "$REPO_ROOT/$EVAL_DIR/final_model" \
            --templates-dir "../../templates" \
            --limit -1 \
            --json-output-file "$REPO_ROOT/$EVAL_DIR/eval_results/metrics_${eval_task}.json" \
            > "$REPO_ROOT/$EVAL_DIR/eval_results/final_eval_${eval_task}.txt" 2>&1
        cd "$REPO_ROOT"
    done
}

archive() {
    print_section "======= ARCHIVING RUN ======="
    find "${JOB_DIR}/task" -type f \( -name "*.safetensors" -o -name "pytorch_model*.bin" -o -name "optimizer.pt" -o -name "scheduler.pt" -o -name "rng_state.pth" -o -name "*.ckpt" \) -print -delete # Drop model weights before archiving the workspace.
    cp -r "${JOB_DIR}/task" "$EVAL_DIR/task/"
    if [ -d "${JOB_DIR}/.codex" ]; then
        cp -r "${JOB_DIR}/.codex" "$EVAL_DIR/.codex"
    fi
}

main() {
    prepare_workspace "$@"

    print_section "========= RUNNING TASK ========="

    with_record_the_time solve_task "${JOB_DIR}/task"
    SOLVE_EXIT=$?

    post_solve_artifacts
    run_disallowed_usage_judge
    archive
    evaluate_task

    print_section "===== LOCAL RUN COMPLETE ======"
    echo "results_dir: ${EVAL_DIR}"
}

main "$@"
