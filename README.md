# AutoTrainess

## Project Overview

[中文说明](README_zh.md)

## Quick Start

1. Check that the machine satisfies the [Resource Requirements](#resource-requirements).
2. Prepare a Python environment with CUDA-capable PyTorch and vLLM.
3. Create and edit the machine-local environment file:

```bash
cp local_env.example.sh local_env.sh
source local_env.sh
"$POSTTRAIN_PIP_BIN" install -r requirements.txt
```

4. Download shared HuggingFace resources:

```bash
"$POSTTRAIN_PYTHON_BIN" resources/download_resources.py
```

5. Configure one agent under `agents/`; see [Configure an Agent](#2-configure-an-agent) for `local_codex` and `local_opencode`.
6. Fill in the required parameters near the top of `run.sh`.
7. Start the run:

```bash
bash run.sh
```

## Usage

This repository is run locally through:

```bash
bash run.sh
```

`run.sh` sources `local_env.sh`, sets fixed run parameters, and calls:

```bash
bash src/run_task.sh "$EVAL_TASK" "$AGENT" "$MODEL_TO_TRAIN" "$NUM_HOURS" "$NUM_GPUS"
```

### 1. Configure the Local Environment

Prepare a Python environment with:

- CUDA-capable PyTorch.
- vLLM built for the CUDA version on the target machine.
- The shared Python packages in `requirements.txt`.

Create a local environment file:

```bash
cp local_env.example.sh local_env.sh
```

Edit `local_env.sh` for the current machine:

- `PYTHON_ROOT`: Python environment path.
- `WORK_BASE`: temporary workspace used by each run.
- `LINUX_USER`: Linux user that should own runtime files.
- `EVAL_OPENAI_AK`, `EVAL_OPENAI_ENDPOINT`: API settings for evaluation and judge calls.
- `HF_TOKEN_VALUE`: HuggingFace token.
- `PROXY_URL`, `NO_PROXY`: proxy settings. Leave `PROXY_URL` empty if the machine does not need a proxy.

`local_env.sh` creates `/usr/local/bin/python`, `/usr/local/bin/pip`, and `/usr/local/bin/vllm` symlinks with sudo. The local agents expect those commands to be available there.

Install the shared Python packages:

```bash
source local_env.sh
"$POSTTRAIN_PIP_BIN" install -r requirements.txt
```

Download the HuggingFace model and dataset cache before running:

```bash
"$POSTTRAIN_PYTHON_BIN" resources/download_resources.py
```

This downloads the official PostTrainBench resource list into:

```bash
resources/post_hf/
```

The runner links this directory into each task workspace as `post_hf/`.

### 2. Configure an Agent

For other agents, use the corresponding directory under `agents/` as the reference.

For `local_codex`:

Place the Codex CLI binary here:

```bash
agents/local_codex/codex
```

Configure the Codex model, provider, and agent credential settings here:

```bash
agents/local_codex/codex_home/config.toml
```

The checked-in `config.toml` is only a reference format. Adapt the provider, model, and credential settings to the actual Codex-compatible service you use.

`agents/local_codex/solve.sh` copies `codex_home` into the run-local `$HOME/.codex` before launching Codex.

For `local_opencode`:

Place the OpenCode binary here:

```bash
agents/local_opencode/opencode
```

Configure the OpenCode model and provider here:

```bash
agents/local_opencode/opencode_home/opencode.json
```

The checked-in `opencode.json` is only a reference format. Adapt the provider, model, endpoint, and credential settings to the actual OpenCode-compatible service you use.

Also update `OPENCODE_MODEL` in:

```bash
agents/local_opencode/solve.sh
```

Use the `provider/model` name that matches `opencode.json`.

Set OpenCode-specific API keys in the environment expected by `opencode.json`. For example, if `opencode.json` uses `{env:OPENCODE_API_KEY}`, set `OPENCODE_API_KEY`.

Agent-specific credentials belong to the corresponding agent configuration or to the environment variables required by that agent. `local_env.sh` is only for machine-level settings and evaluation/judge credentials.

### 3. Configure the Run

Fill in the required parameters near the top of `run.sh` before starting a run:

- `EVAL_TASK`: currently expected to be `all`.
- `AGENT`: usually `local_codex`; `local_opencode` is also available.
- `MODEL_TO_TRAIN`: base model path or HuggingFace model id.
- `NUM_HOURS`: solve time budget.
- `NUM_GPUS`: passed through for compatibility; local agents currently do not consume it.

The benchmark list is controlled in `src/run_task.sh` by `INSPECT_EVALS`. At the moment, `gsm8k` is enabled and the other benchmark names are present but commented out.

### 4. Start the Run

```bash
bash run.sh
```

## Resource Requirements

Each run is intended to use:

- GPU: one exclusive NVIDIA H20.
- Time budget: 10 hours.
- Disk: at least 200 GB of writable workspace storage.

Run the project in a platform-, container-, or scheduler-isolated environment with a GPU allocation of exactly one exclusive H20.

## Outputs

Run outputs are written under:

```bash
results/<agent_config>/<eval_task>/<timestamp>/
```

Important files include:

- `output.log`: main runner stdout.
- `error.log`: main runner stderr.
- `solve_out.txt`: raw agent output.
- `solve_parsed.txt`: parsed agent trace when a parser is available.
- `prompt.txt`: prompt sent to the agent.
- `time_taken.txt`: solve-stage runtime.
- `contamination_judge/`: judge outputs.
- `eval_results/`: final evaluation logs and metrics.
- `task/`: archived task workspace after model weights are removed.

## Runtime Risks

This repository assumes an isolated local run environment.

Be aware that:

- `local_env.sh` writes symlinks into `/usr/local/bin` with sudo.
- `src/run_task.sh` clears all existing contents under `POSTTRAIN_WORK_BASE` at the start of each run.
- Local agents run with broad permissions by default, such as Codex `--yolo` and OpenCode `permission: allow`.
- `src/run_task.sh` archives the task workspace after deleting large model weight files from the archived copy.

Verify `local_env.sh` before each run, especially `WORK_BASE` and `LINUX_USER`.

## Differences From Original PostTrainBench

This section compares AutoTrainess with the original PostTrainBench repository.

AutoTrainess is a local-run development version. It keeps the benchmark task flow, local agent execution, contamination judging, and final evaluation, but removes infrastructure that only made sense for the original containerized or cluster-based setup.

Key differences:

- Local-only execution: runs through `run.sh` and `src/run_task.sh`; no container build, apptainer runtime, or HTCondor submission flow.
- Simpler configuration: machine-level settings live in `local_env.sh`; agent-specific model/provider settings stay under each `agents/local_*` directory.
- Local agents only: the maintained local paths are `agents/local_codex/` and `agents/local_opencode/`.
- Smaller repository surface: old cluster helpers, container debugging utilities, baseline submission scripts, and unrelated post-processing scripts were removed.
- Same core benchmark shape: the run still prepares a task workspace, launches an agent, archives artifacts, runs the contamination judge, and evaluates the produced model.

The practical result is that users should treat this repository as a local training-and-evaluation harness, not as a full replacement for the original PostTrainBench infrastructure.

The Chinese version of the previous README is kept as `README_zh.md`.

## License

This project is released under the MIT License. See `LICENSE` for details.
