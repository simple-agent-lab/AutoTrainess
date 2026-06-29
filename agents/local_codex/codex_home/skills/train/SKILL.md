---
name: train
description: Use when running benchmark-oriented training with LlamaFactory, including SFT and RL.
metadata:
  short-description: Run training with LlamaFactory
---

# train

## Purpose
Run the simplest valid benchmark-oriented training workflow with LlamaFactory, choose the training mode that matches the current stage and evidence, and export a model ready for evaluation.

## When to use
- When training data is ready and the next step is to run model training.
- When the current stage requires supervised fine-tuning.
- When current evidence supports reinforcement learning.

## Core rules
- Use `hiyouga/LlamaFactory` for all training work.
- Read [shared/llamafactory.md](./shared/llamafactory.md) before running training.
- Choose the training mode that matches the current stage and evidence.
- Keep the workflow minimal and reproducible.
- Export `final_model/` for downstream evaluation.
- Do not switch to another framework or a custom training loop.

## Run caution
Long training jobs are allowed, but should be started deliberately. Prefer a short validation run first unless there is already clear evidence that a long run is necessary.

## Workflow
1. Read [shared/llamafactory.md](./shared/llamafactory.md).
2. Decide whether the current stage requires [sft/stage.md](./sft/stage.md) or [rl/stage.md](./rl/stage.md).
3. Follow the selected stage document.
4. Run training through the provided script in `scripts/`.
5. Export `final_model/` for evaluation.
