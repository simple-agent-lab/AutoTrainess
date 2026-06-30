---
name: eval
description: Use when evaluating a model on the current benchmark(s).
metadata:
  short-description: Run benchmark evaluation
---

# eval

## Purpose
Run the benchmark's real evaluation on `final_model/` and record reproducible evidence needed for the next stage decision.

## Inputs
- Workspace repository (current working directory).
- `final_model/`.

## Required outputs
- `eval_results/` with raw outputs or logs.
- The exact evaluation command or config used.
- A concise metrics summary.
- `eval_results/sample_summary.md` with 15 randomly selected evaluation samples, including score, input, target, and model output.
- A brief note on the main 1-3 observed failure modes and whether each one looks more like a data problem, a training problem, or an inference/template problem.

## Rules
- Use the benchmark's real evaluation entrypoint.
- If evaluation fails, stay in the benchmark's real evaluation workflow, debug the failure, and retry.
- For any evaluation used to compare checkpoints, judge model quality, or choose the next iteration, use at least `max(32, ceil(5% of the benchmark))` samples. If the benchmark has fewer than 32 samples, evaluate the full benchmark.
- Runs below that sample floor are allowed only as smoke tests for command or runtime validity; do not use them as evidence that one checkpoint or approach is better.
- Always produce `eval_results/sample_summary.md` with 15 random evaluation samples.
- Use `skills/eval/scripts/summarize_eval_samples.py` when the benchmark outputs compatible `inspect_ai` logs; otherwise, add the minimum benchmark-specific script or logging needed to generate the sample summary from the real evaluation run.
- Keep the output focused on evidence needed for the next decision.

## Procedure
1) Locate the canonical evaluation entrypoint.
2) If using a limited evaluation, determine the benchmark sample count and choose a limit that satisfies the sample-floor rule.
3) Run evaluation on `final_model/`.
4) Save raw outputs, commands, the sample count or limit used, and a concise metrics summary under `eval_results/`.
5) If evaluation fails, debug it inside the benchmark's real evaluation workflow, then retry with the minimum necessary fix.
6) Generate `eval_results/sample_summary.md` with 15 random samples including score, input, target, and model output. Use `skills/eval/scripts/summarize_eval_samples.py` when compatible `inspect_ai` logs are available; otherwise, add the minimum benchmark-specific script or logging needed.
7) Verify that `eval_results/sample_summary.md` was generated and contains 15 samples.
8) Summarize the main 1-3 observed failure modes and whether each one looks more like a data problem, a training problem, or an inference/template problem.
