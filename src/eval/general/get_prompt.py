#!/usr/bin/env python3
import argparse
import os
import subprocess
from pathlib import Path

INSPECT_EVALS = [
    "aime2025",
    "arenahardwriting",
    "bfcl",
    "gpqamain",
    "gsm8k",
    "healthbench",
    "humaneval",
]

def read_benchmark_name(benchmark_id: str) -> str:
    """Resolve the human-readable benchmark name from the benchmark_id."""
    bench_file = Path("src/eval/tasks") / benchmark_id / "benchmark.txt"
    if not bench_file.is_file():
        raise FileNotFoundError(f"Benchmark file not found for id '{benchmark_id}': {bench_file}")
    return bench_file.read_text(encoding="utf-8").strip()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--agent', type=str, required=True)
    parser.add_argument('--model-to-train', type=str, required=True)
    parser.add_argument('--num-hours', type=str, required=True)
    parser.add_argument('--eval-tasks', type=str, default='')

    args = parser.parse_args()

    eval_tasks = [item for item in args.eval_tasks.replace(',', ' ').split() if item] or INSPECT_EVALS

    all_benchmarks = []
    for bid in eval_tasks:
        try:
            name = read_benchmark_name(bid)
            all_benchmarks.append(f"- {name}")
        except FileNotFoundError:
            all_benchmarks.append(f"- (id: {bid}) — file not found")

    benchmarks_text = "\n" + "\n".join(all_benchmarks)

    base_prompt = os.environ.get('POST_TRAIN_BENCH_PROMPT', 'prompt')
    template_path = f'src/eval/general/{base_prompt}.txt'

    with open(template_path, 'r') as f:
        template = f.read()

    datetime = subprocess.run(['date', '-u'], capture_output=True, text=True).stdout.strip()

    result = template.replace('{model}', args.model_to_train)
    result = result.replace('{benchmark}', benchmarks_text)
    result = result.replace('{num_hours}', args.num_hours)

    result = result.replace('{setup_other}', 
        "- A final note: the evaluate.py script sometimes outputs ERROR warnings. "
        "Do not be alarmed by this, this is normal behavior for inspect-ai. "
        "Also if you run into issues with the evaluate.py script, this is likely "
        "due to memory constraints on the GPU. In this case please decrease "
        "--max-connections or --max-tokens.\n")

    result = result.replace('{datetime}', datetime)

    if args.agent == 'claude':
        result += """You are running in a non-interactive mode. So make sure every process you are running finishes before you write your last message.
"""

    print(result)

if __name__ == '__main__':
    main()
