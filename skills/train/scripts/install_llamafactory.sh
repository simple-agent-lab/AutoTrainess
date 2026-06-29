#!/usr/bin/env bash
set -euo pipefail

# Reuse an existing installation if the CLI is already available.
if command -v llamafactory-cli >/dev/null 2>&1; then
  echo "LlamaFactory already available: $(command -v llamafactory-cli)"
  exit 0
fi

# Require the default python environment prepared by solve.sh.
if ! command -v python >/dev/null 2>&1; then
  echo "No python interpreter found for installing llamafactory" >&2
  exit 1
fi

# Install LlamaFactory into the current default environment.
python -m pip install -U llamafactory

if ! command -v llamafactory-cli >/dev/null 2>&1; then
  echo 'llamafactory-cli is still unavailable after installation.' >&2
  exit 1
fi

llamafactory-cli version >/dev/null
