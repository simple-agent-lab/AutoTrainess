# AutoTrainess

<p align="center">
  <img src="figs/overview.png" alt="AutoTrainess 工作流概览" width="100%">
</p>

<p align="center">
  <strong>Teaching Language Models to Improve Language Models Autonomously</strong><br>
  一套面向自主 LLM post-training 任务的 training-specialized Agent-Computer Interface。
</p>

<p align="center">
  <a href="docs/autotrainess_paper.pdf">Paper</a> ·
  <a href="README.md">English</a> ·
  <a href="#结果">结果</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#完整代码分支">完整代码分支</a>
</p>

## 概述

AutoTrainess 是一个用于自主 LLM post-training 的 LM-agent 框架。它不是让 agent 在原始 CLI 里自由摸索训练流程，而是通过 **AutoTrainHub** 把训练任务拆成结构化、可复用的 Agent-Computer Interfaces。

核心思路是把人类训练工程师积累的流程经验显式交给 agent：如何规划实验、构造和验证数据、稳定训练、运行真实评测，以及跨多轮迭代保存实验状态。整体闭环如下：

```text
iteration_plan -> data -> train -> eval -> log
```

当前分支保留 AutoTrainess 中可复用的指令和 skills。完整 benchmark runner 和端到端 pipeline 在 `full-code` 分支。

## 结果

<p align="center">
  <img src="figs/autotrainess_vs_cli_avg.png" alt="AutoTrainess 与 CLI-only 在 PostTrainBench 上的对比" width="82%">
</p>

在 PostTrainBench 上，AutoTrainess 在相同的 10 小时 H20 GPU 预算下稳定优于 CLI-only agent。论文中的评测覆盖 Qwen3-1.7B、Qwen3-4B、SmolLM3-3B、Gemma-3-4B 四个 base model，以及数学、代码、函数调用、知识、健康和通用指令跟随等七类 benchmark。

| Harness | CLI-only | AutoTrainess | 提升 |
| --- | ---: | ---: | ---: |
| GPT-5.4 + Codex | 23.21 | **26.94** | +3.73 |
| GPT-5.4 + OpenCode | 19.71 | **23.35** | +3.64 |
| DeepSeek-V4-Flash + OpenCode | 12.13 | **19.58** | +7.45 |

消融实验说明了 interface 的作用。在 Qwen3-4B subset 和 GPT-5.4 Codex 设置下，完整 AutoTrainess 得分为 32.6；去掉 data processing 后降到 29.1，去掉 training 后降到 20.2，去掉 evaluation 后降到 24.0，去掉 logging and planning 后降到 24.1。

## 工作方式

| Interface | 给 agent 提供什么 |
| --- | --- |
| `iteration_plan` | 为下一轮实验定义清晰假设、干预方式和成功标准。 |
| `data` | 数据选择、构造和验证，使训练样本对齐 benchmark-facing interface，同时规避泄漏、格式错误和低质样本。 |
| `train` | 基于 LlamaFactory 的稳定训练入口，支持小规模 validation run，并导出可评测的 `final_model/`。 |
| `eval` | 运行真实 benchmark evaluation，保存原始输出、样本摘要，并诊断主要失败模式。 |
| `log` | 跨长时间、多轮训练保存结构化实验记忆。 |

这些 interfaces 主要用来降低自主训练中的常见失败：数据 schema 不匹配、chat template 错误、训练产物交接不稳定、评测命令不一致，以及多轮迭代中实验状态丢失。

## 快速开始

### Codex

把 AutoTrainess 指令和 skills 复制到目标配置：

```bash
cp AGENTS.md /path/to/your/workspace/AGENTS.md
mkdir -p ~/.codex/skills
cp -r autotrainhub/* ~/.codex/skills/
```

使用 baseline prompt 时：

```bash
cp AGENTS_baseline.md /path/to/your/workspace/AGENTS.md
```

### OpenCode

同一套可复用文件也可以用于 OpenCode：

```bash
cp AGENTS.md /path/to/your/workspace/AGENTS.md
mkdir -p ~/.opencode/skills
cp -r autotrainhub/* ~/.opencode/skills/
```

使用 baseline prompt 时：

```bash
cp AGENTS_baseline.md /path/to/your/workspace/AGENTS.md
```

## 仓库结构

| 路径 | 作用 |
| --- | --- |
| `AGENTS.md` | 主 AutoTrainess 指令文件，包含阶段化训练和评测规则。 |
| `AGENTS_baseline.md` | 不带 AutoTrainess 阶段结构的 CLI-only baseline prompt。 |
| `autotrainhub/` | 用于 planning、data processing、training、evaluation、logging 的可复用 skills。 |
| `docs/autotrainess_paper.pdf` | 介绍方法、实验和分析的论文草稿。 |
| `figs/` | README 中使用的展示图。 |

## 完整代码分支

如果你想运行完整 benchmark pipeline，而不是只复用这里的指令和 skills，请使用 `full-code` 分支：

```bash
git checkout full-code
```

该分支包含 runner 脚本、agent wrapper、评测任务、资源下载脚本，以及完整 quick-start 文档。
