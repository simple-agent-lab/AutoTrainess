---
name: log
description: Use when appending an experiment log entry after a completed iteration.
metadata:
  short-description: Append experiment log
---

# log

## Task
After each completed iteration, append one new entry to `task/experiment_log.md`.

## Rules
- If `task/experiment_log.md` does not exist, create it. If it already exists, append a new entry at the end.
- Each call should record only the iteration that has just finished.
- Organize the log by stage, and record the work done in the current iteration under the relevant stage.

## Entry Format
Organize entries by stage when a stage is available. If the relevant stage heading does not exist, create it.

Use this Markdown format for each new entry:

### Iteration <id>: <short title>

- Context: <stage, objective, or current focus>
- Status: completed | failed | blocked
- Motivation: <what prompted this iteration>
- References: <papers, docs, repos, datasets, blogs, or notes consulted; write "None" if not used>
- Starting checkpoint: <base model, previous checkpoint, or final_model path used as training start>
- Training data: <datasets/files used, sizes, filters, construction method, validation notes>
- Method: <training method, recipe, prompt/data strategy, or implementation changes>
- Training config: <key hyperparameters, command, epochs, lr, batch size, LoRA/full fine-tune, etc.>
- Evaluation: <evaluation command, benchmark split, limit/full setting, metric>
- Result: <exact score, failure, or observed behavior>
- Analysis: <what changed, what likely caused it, whether the hypothesis was supported>
- Artifacts: <model path, logs, data files, checkpoints>
- Next action: <the justified next step>

Rules:
- Fill every field. Use `None` or `N/A` only when the field truly does not apply.
- Record concrete evidence, not vague summaries.
- Include exact metrics, commands, paths, and dataset sizes when available.
- If references were consulted, record enough detail to identify them later.
- If the iteration failed or was blocked, record the specific cause.
- The next action must follow from the recorded result and analysis.
