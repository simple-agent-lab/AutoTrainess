# AGENTS.md

## Objective
- Improve the target task or benchmark through real training and evaluation.
- Base important decisions on verifiable evidence.

## Hard Constraints
- APIs may be used only for benchmark evaluation, never for data construction or any other non-evaluation purpose.
- Do not use benchmark examples, the values of any fields or components of benchmark examples, or any data whose overlap with the benchmark cannot be ruled out for training or to create training data.
- Fine-tune only from the exact target base model provided by the task or checkpoints you fine-tuned from it; do not use an instruction-tuned, chat-tuned, larger, or different model as the training start point, merge source, fallback, or final submission.
- Never tune, search, or modify generation config to improve benchmark scores.
- If `CUDA_VISIBLE_DEVICES` is set, it defines the only GPU devices assigned to this run; do not override it or use any GPU outside that set.
- A run being blocked by environment, permissions, dependencies, shared resources, or turn-level execution limits does not mean the task is complete.

## Experiment Guidance
- Prefer the simplest valid approach first.
- Record the concrete reason for each failure, improvement, and strategy change.
- State which stage you are currently in.
- Do not spend iterations repeatedly tuning low-level settings unless there is clear evidence that doing so targets the current bottleneck.

## Stage Rules
- Stages are sequential and mandatory.
- If the current stage fails because of an engineering or environment issue, fix it and retry that stage.
- If the current stage has been explored enough to justify moving on, enter the next stage instead of ending the task.
- If no explicit target is provided, do not decide on your own that the task is complete.

## Iteration Execution
- For Stage 2/3, each stage is executed through one or more full iterations.
- Skills define how to execute one iteration locally. If a skill's default options conflict with the current stage rules, follow the stage rules in this file.
- A full iteration should use the skill chain: `iteration_plan -> data -> train -> eval -> log`.
- `iteration_plan` defines the goal and planned changes for the current iteration.
- `data` handles data selection, construction, and validation before training.
- `train` runs training and exports `final_model/`.
- `eval` runs the benchmark's real evaluation on `final_model/`.
- `log` records the completed iteration and its outcome.

## Procedure

### Stage 0: Task Definition
Define the target, evaluation method, and active resource constraints before training begins.
Once they are clear enough to support fair evaluation, proceed to Stage 1.

### Stage 1: Base Model Evaluation
Run the real benchmark evaluation on the current base model to establish the baseline result for later iterations.

Steps:
1. Prepare the current base model for evaluation.
2. Run the real benchmark evaluation.
3. Record the evaluation setup and result.

Decision rules:
- If an explicit target exists and the base model already reaches the target, stop.
- If evaluation fails because of an engineering or environment issue, fix the issue and repeat Stage 1. Otherwise, enter Stage 2.

### Stage 2: Local Diagnosis and Optimization
Run local iterations to establish a reliable training/evaluation loop, identify concrete failure modes, and test simple improvements before expanding the search space.

Iteration rules:
- Each iteration must target a specific observed weakness or opportunity from the latest valid evaluation.
- Prefer simple local changes with an explicit hypothesis.
- If an explicit target exists and the result reaches the target, stop.
- Continue Stage 2 while local iterations produce meaningful improvements, reveal new actionable evidence, or leave clear local hypotheses to test.
- Enter Stage 3 when local optimization has stalled, no clear local hypothesis remains, or the next likely improvement requires external methods, datasets, or training ideas.

### Stage 3: Evidence-Guided Exploration
Expand the search space beyond local optimization by using Stage 2 evidence to guide external search for methods, datasets, and training strategies.

Exploration routes:
- Problem-driven routes: target concrete failure modes, bottlenecks, or open hypotheses discovered in Stage 2.
- Open-ended routes: explore broader methods, datasets, or training ideas that may improve the benchmark even if they are not tied to one specific Stage 2 failure.

Iteration rules:
- Prioritize problem-driven routes when Stage 2 provides clear actionable evidence.
- Use open-ended routes when Stage 2 evidence is weak, local optimization has stalled, or broader benchmark knowledge suggests a promising direction.
- Each selected route must be tested through a full local iteration with an explicit hypothesis.
- If a route fails, record the reason and continue with the next concrete Stage 3 route unless a stop condition is met.

## Logging
- After each completed iteration, call the `log` skill to append the latest evidence to `task/experiment_log.md`.

## File Organization
- Cross-iteration summaries and decisions belong in `task/experiment_log.md`.
- Per-iteration files belong under `task/iterations/<iteration-id>/`, using the same iteration id as the experiment log.
- The iteration plan belongs in `task/iterations/<iteration-id>/iteration_plan.md`.
- Training data, data manifests, filtering notes, and validation notes for the iteration belong under `task/iterations/<iteration-id>/data/`.
- Training configs, commands, helper scripts, and training notes for the iteration belong under `task/iterations/<iteration-id>/train/`.
- Evaluation outputs, metrics, error traces, and evaluation notes for the iteration belong under `task/iterations/<iteration-id>/eval/`.
- Large checkpoints, copied datasets, caches, and temporary artifacts may be used when necessary, but their paths should be recorded and unnecessary copies should be removed promptly.
- The root `final_model/` directory is reserved for the current final submission model.

## Stop Conditions
- If an explicit target exists, the target is reached. Otherwise, no stop condition is available to the agent.

## Completion Criteria
- The task is complete only if a stop condition is met. Otherwise, you must not stop for any reason.
