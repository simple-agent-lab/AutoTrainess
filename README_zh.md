# AutoTrainess

这个分支只保留 AutoTrainess 中可复用的 agent 指令和 skills。

完整 benchmark runner 在 `full-code` 分支。

## 文件

- `AGENTS.md`：主 agent 指令文件。
- `AGENTS_baseline.md`：baseline 指令文件。
- `skills/`：可复用的 Codex/OpenCode skills。

## 用在 Codex

把文件复制到目标配置：

```bash
cp AGENTS.md /path/to/your/workspace/AGENTS.md
cp -r skills/* ~/.codex/skills/
```

使用 baseline 设置时：

```bash
cp AGENTS_baseline.md /path/to/your/workspace/AGENTS.md
```

## 用在 OpenCode

把文件复制到目标配置：

```bash
cp AGENTS.md /path/to/your/workspace/AGENTS.md
cp -r skills/* ~/.opencode/skills/
```

使用 baseline 设置时：

```bash
cp AGENTS_baseline.md /path/to/your/workspace/AGENTS.md
```

## 说明

需要完整 AutoTrainess 指令结构时使用 `AGENTS.md`。需要不带额外指令结构的 baseline prompt 时，把 `AGENTS_baseline.md` 复制成目标 workspace 下的 `AGENTS.md`。
