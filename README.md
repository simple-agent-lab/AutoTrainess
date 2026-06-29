# AutoTrainess

[中文说明](README_zh.md)

This branch contains the reusable agent instructions and skills from AutoTrainess.

## Full Code Branch

Use the `full-code` branch when you want to run the full benchmark pipeline instead of only reusing the instructions and skills. That branch contains the complete runner scripts, agent wrappers, evaluation tasks, resource download scripts, and full quick-start documentation.

```bash
git checkout full-code
```

## Files

- `AGENTS.md`: the main agent instruction file.
- `AGENTS_baseline.md`: the baseline instruction file.
- `skills/`: reusable Codex/OpenCode skills.

## Use With Codex

Copy the files into your target setup:

```bash
cp AGENTS.md /path/to/your/workspace/AGENTS.md
cp -r skills/* ~/.codex/skills/
```

For the baseline setting:

```bash
cp AGENTS_baseline.md /path/to/your/workspace/AGENTS.md
```

## Use With OpenCode

Copy the files into your target setup:

```bash
cp AGENTS.md /path/to/your/workspace/AGENTS.md
cp -r skills/* ~/.opencode/skills/
```

For the baseline setting:

```bash
cp AGENTS_baseline.md /path/to/your/workspace/AGENTS.md
```

## Notes

Use `AGENTS.md` for the full AutoTrainess instruction setup. Use `AGENTS_baseline.md` when you want the baseline prompt without the added instruction structure.
