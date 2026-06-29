---
name: iteration_plan
description: Use when defining the goal and action plan for the next experiment iteration.
metadata:
  short-description: Plan the next experiment iteration
---

# iteration_plan

## Purpose
Define a clear goal and concrete action plan for the current experiment iteration based on real evidence from previous experiments.

## Inputs
- Results from previous experiments.
- Prior evaluation evidence and analysis.
- The current training and data context available in the workspace.

## Required outputs
- The main problems observed in previous experiments.
- The main objective of the current iteration.
- The changes planned for the current iteration.
- Whether this iteration mainly changes data, training, or both.
- The outcome that will count as success.
- Concise guidance for downstream data or training work.

## Rules
- Base the plan on real evidence from previous experiments rather than speculation.
- Focus on the main objective of the current iteration rather than trying to address every issue at once.
- Separate previous problems, current objective, planned changes, and success criteria clearly.
- Define the direction for the current iteration, but do not directly execute data construction or training in this skill.
- Keep the plan concrete enough that downstream skills can act on it.

## Procedure
1. Review previous experiment results and identify the main problems.
2. Decide what the current iteration is mainly trying to improve.
3. Define the main changes to make in this iteration.
4. State what outcome will count as success for this iteration.
5. Provide concise guidance for downstream data and training work.
