# AutoTrainess

## 快速开始

1. 检查当前机器满足[运行资源限制](#运行资源限制)。
2. 准备包含 CUDA 版 PyTorch 和 vLLM 的 Python 环境。
3. 创建并修改机器本地环境配置：

```bash
cp local_env.example.sh local_env.sh
source local_env.sh
"$POSTTRAIN_PIP_BIN" install -r requirements.txt
```

4. 下载共享 HuggingFace 资源：

```bash
"$POSTTRAIN_PYTHON_BIN" resources/download_resources.py
```

5. 在 `agents/` 下配置一个 agent；`local_codex` 和 `local_opencode` 的配置方式见[配置 agent](#2-配置-agent)。
6. 填写 `run.sh` 开头的必填参数。
7. 启动运行：

```bash
bash run.sh
```

## 使用方式

本仓库通过本地脚本运行：

```bash
bash run.sh
```

`run.sh` 会 source `local_env.sh`，设置固定运行参数，然后调用：

```bash
bash src/run_task.sh "$EVAL_TASK" "$AGENT" "$MODEL_TO_TRAIN" "$NUM_HOURS" "$NUM_GPUS"
```

### 1. 配置本地环境

先准备一个 Python 环境，里面需要包含：

- 可用的 CUDA 版 PyTorch。
- 按目标机器 CUDA 版本安装的 vLLM。
- `requirements.txt` 中的共享 Python 依赖。

先创建本地环境配置文件：

```bash
cp local_env.example.sh local_env.sh
```

按当前机器修改 `local_env.sh`：

- `PYTHON_ROOT`：Python 环境路径。
- `WORK_BASE`：每次运行使用的临时 workspace。
- `LINUX_USER`：运行产物应该归属的 Linux 用户。
- `EVAL_OPENAI_AK`、`EVAL_OPENAI_ENDPOINT`：评测和 judge 调用的接口配置。
- `HF_TOKEN_VALUE`：HuggingFace token。
- `PROXY_URL`、`NO_PROXY`：代理配置；如果当前机器不需要代理，`PROXY_URL` 留空。

`local_env.sh` 会用 sudo 创建 `/usr/local/bin/python`、`/usr/local/bin/pip`、`/usr/local/bin/vllm` 软链接；local agent 会从这些路径找命令。

安装共享 Python 依赖：

```bash
source local_env.sh
"$POSTTRAIN_PIP_BIN" install -r requirements.txt
```

运行前下载 HuggingFace 模型和数据 cache：

```bash
"$POSTTRAIN_PYTHON_BIN" resources/download_resources.py
```

这个命令会把官方 PostTrainBench 的资源列表下载到：

```bash
resources/post_hf/
```

runner 会把这个目录软链接到每个任务 workspace 中的 `post_hf/`。

### 2. 配置 agent

使用其它 agent 时，请参考 `agents/` 下对应目录中的配置和脚本。

使用 `local_codex` 时：

把 Codex CLI 二进制放到：

```bash
agents/local_codex/codex
```

Codex 的 model、provider 和 agent credential 配置写在：

```bash
agents/local_codex/codex_home/config.toml
```

仓库中的 `config.toml` 只作为参考格式；实际 provider、model 和 credential 配置需要按你使用的 Codex 兼容服务适配。

`agents/local_codex/solve.sh` 会在运行前把 `codex_home` 复制到本次运行隔离出来的 `$HOME/.codex`。

使用 `local_opencode` 时：

把 OpenCode 二进制放到：

```bash
agents/local_opencode/opencode
```

OpenCode 的 model/provider 配置写在：

```bash
agents/local_opencode/opencode_home/opencode.json
```

仓库中的 `opencode.json` 只作为参考格式；实际 provider、model、endpoint 和 credential 配置需要按你使用的 OpenCode 兼容服务适配。

同时修改：

```bash
agents/local_opencode/solve.sh
```

里面的 `OPENCODE_MODEL` 应该和 `opencode.json` 中的 `provider/model` 对应。

OpenCode 专用的 API key 应写在 `opencode.json` 所要求的环境变量里；例如配置里使用 `{env:OPENCODE_API_KEY}` 时，就设置 `OPENCODE_API_KEY`。

agent 私有 credential 应放在对应 agent 的配置里，或放在该 agent 配置要求的环境变量里。`local_env.sh` 只放机器级配置和评测/judge credential。

### 3. 配置运行参数

运行前填写 `run.sh` 开头的必填参数：

- `EVAL_TASK`：当前预期为 `all`。
- `AGENT`：通常是 `local_codex`；也可以使用 `local_opencode`。
- `MODEL_TO_TRAIN`：基础模型路径或 HuggingFace model id。
- `NUM_HOURS`：agent solve 阶段的时间预算。
- `NUM_GPUS`：保留为兼容参数；当前 local agent 不实际消费它。

benchmark 列表由 `src/run_task.sh` 里的 `INSPECT_EVALS` 控制。目前启用的是 `gsm8k`，其它 benchmark 名称保留但处于注释状态。

### 4. 开始运行

```bash
bash run.sh
```

## 运行资源限制

每次运行按以下资源设计：

- GPU：一张独占的 NVIDIA H20。
- 时间预算：10 小时。
- 磁盘：至少 200 GB 可写 workspace 存储。

本项目应运行在平台、容器或调度层面隔离的环境中，且该环境的 GPU 配额为一张独占 H20。

## 输出

运行结果会写到：

```bash
results/<agent_config>/<eval_task>/<timestamp>/
```

重要文件包括：

- `output.log`：主 runner 的 stdout。
- `error.log`：主 runner 的 stderr。
- `solve_out.txt`：agent 原始输出。
- `solve_parsed.txt`：可用时生成的 agent trace 解析结果。
- `prompt.txt`：发送给 agent 的 prompt。
- `time_taken.txt`：solve 阶段耗时。
- `contamination_judge/`：judge 输出。
- `eval_results/`：最终评测日志和指标。
- `task/`：归档后的任务 workspace；归档前会删除大模型权重文件。

## 运行风险

本仓库默认用于隔离的本地运行环境。

需要注意：

- `local_env.sh` 会用 sudo 向 `/usr/local/bin` 写软链接。
- `src/run_task.sh` 每次运行开始都会清空 `POSTTRAIN_WORK_BASE` 下已有内容。
- local agent 默认以宽权限模式运行，例如 Codex `--yolo` 和 OpenCode `permission: allow`。
- `src/run_task.sh` 会在归档 task workspace 前删除大模型权重文件，避免归档占用过多空间。

每次运行前都应该检查 `local_env.sh`，尤其是 `WORK_BASE` 和 `LINUX_USER`。

## 相比原始 PostTrainBench 的差异

本节说明 AutoTrainess 相比原始 PostTrainBench 的差异。

AutoTrainess 是从 PostTrainBench 派生出来的本地运行开发版本。它保留 benchmark 任务流程、local agent 执行、污染判断和最终评测，但删除了只适用于原始容器化或集群运行环境的基础设施。

核心差异：

- 只支持本地运行：通过 `run.sh` 和 `src/run_task.sh` 运行；不再保留容器构建、apptainer runtime 或 HTCondor 提交流程。
- 配置更直接：机器级配置放在 `local_env.sh`；agent 独有的 model/provider 配置保留在各自的 `agents/local_*` 目录。
- 维护 local agent 路径：当前维护的是 `agents/local_codex/` 和 `agents/local_opencode/`。
- 仓库表面积更小：删除了旧集群辅助脚本、容器调试工具、baseline 提交脚本和无关后处理脚本。
- 核心 benchmark 形态不变：仍然会准备任务 workspace、启动 agent、归档产物、运行污染判断，并评测生成的模型。

实际使用时，应把本仓库理解成本地训练和评测 harness，而不是原始 PostTrainBench 全量基础设施的替代品。

## 许可证

本项目使用 MIT License，详见 `LICENSE`。
