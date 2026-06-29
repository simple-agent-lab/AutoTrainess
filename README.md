# AutoTrainess

This branch contains the reusable agent instructions and skills from AutoTrainess.

For the full benchmark runner, use the `full-code` branch.

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
