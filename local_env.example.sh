#!/usr/bin/env bash
# Machine-local settings for PostTrainBench. Do not commit real credentials.

# Usually you only need to edit this block when moving to another machine.
PYTHON_ROOT="/path/to/python/env" # TODO: example: /path/to/python-3.12

WORK_BASE="/path/to/posttrain/workspace" # TODO: example: /path/to/PostTrainSpace
LINUX_USER="your_linux_user" # TODO: example: ubuntu

EVAL_OPENAI_AK="your_eval_api_key" # TODO: judge model api key
EVAL_OPENAI_ENDPOINT="https://your-eval-endpoint.example.com" # TODO
HF_TOKEN_VALUE="your_huggingface_token" # TODO: example: hf_...

PROXY_URL="" # TODO: set only if this machine needs an HTTP/HTTPS proxy
NO_PROXY="localhost,127.0.0.1,::1,.local" # TODO: add machine/internal domains if needed

# Variables consumed by the benchmark scripts.
BENCH_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$BENCH_DIR/.." && pwd -P)"

export POSTTRAIN_BENCH_DIR="$BENCH_DIR"
export POSTTRAIN_REPO_ROOT="$REPO_ROOT"
export POSTTRAIN_PYTHON_BIN="$PYTHON_ROOT/bin/python"
export POSTTRAIN_PIP_BIN="$PYTHON_ROOT/bin/pip"
export POSTTRAIN_VLLM_BIN="$PYTHON_ROOT/bin/vllm"
export PATH="$PYTHON_ROOT/bin:$PATH" # Make python, pip, and vllm available to the parent process.
sudo ln -sf "$POSTTRAIN_PYTHON_BIN" /usr/local/bin/python # Agents look up tools in /usr/local/bin, so expose these binaries there.
sudo ln -sf "$POSTTRAIN_PIP_BIN" /usr/local/bin/pip
sudo ln -sf "$POSTTRAIN_VLLM_BIN" /usr/local/bin/vllm

export POSTTRAIN_WORK_BASE="$WORK_BASE"
export POSTTRAIN_CHOWN_TARGET="$PYTHON_ROOT"
export POSTTRAIN_CHOWN_USER="$LINUX_USER"

export OPENAI_API_KEY="$EVAL_OPENAI_AK"
export OPENAI_AZURE_ENDPOINT="$EVAL_OPENAI_ENDPOINT"
export HF_TOKEN="$HF_TOKEN_VALUE"

if [ -n "$PROXY_URL" ]; then
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"
    export no_proxy="$NO_PROXY"
    export NO_PROXY="$NO_PROXY"
fi
