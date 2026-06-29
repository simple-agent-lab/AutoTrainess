#!/usr/bin/env python3
"""Extract representative inspect_ai samples into a compact Markdown summary.

Input:
- an `eval_results/` directory
- inspect_ai JSON logs under `eval_results/outputs/`

Output:
- `sample_summary.md` under `eval_results/`

Each summarized sample keeps only the fields needed for inspection:
- `id`
- `input`
- `target`
- `messages`
- `output`
- `scores` (only `value`, `answer`, `explanation` when present)
"""

from __future__ import annotations

import argparse
import json
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class SampleSummary:
    sample_id: Any
    input_text: str
    target_text: str
    messages_text: str
    output_text: str
    scores_text: str


def normalize_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, (int, float, bool)):
        return str(value)
    return json.dumps(value, ensure_ascii=False, indent=2)


def truncate_text(value: Any, limit: int) -> str:
    text = normalize_text(value)
    if len(text) <= limit:
        return text
    return text[:limit] + "\n...[truncated]"


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def iter_log_files(outputs_dir: Path) -> list[Path]:
    if not outputs_dir.exists():
        return []
    return sorted(path for path in outputs_dir.rglob("*.json") if path.is_file())


def trim_scores(scores: Any) -> dict[str, Any] | None:
    if not isinstance(scores, dict):
        return None

    trimmed: dict[str, Any] = {}
    for scorer_name, scorer_result in scores.items():
        if not isinstance(scorer_result, dict):
            continue

        trimmed_result: dict[str, Any] = {}
        for key in ["value", "answer", "explanation"]:
            if key in scorer_result:
                trimmed_result[key] = scorer_result[key]

        if trimmed_result:
            trimmed[scorer_name] = trimmed_result

    return trimmed or None


def extract_output_text(output: Any, max_text_length: int) -> str:
    if isinstance(output, dict):
        if "completion" in output and normalize_text(output["completion"]):
            return truncate_text(output["completion"], max_text_length)
        if "choices" in output and output["choices"]:
            return truncate_text(output["choices"], max_text_length)
    return truncate_text(output, max_text_length)


def extract_sample(sample: dict[str, Any], max_text_length: int) -> SampleSummary:
    trimmed_scores = trim_scores(sample.get("scores"))
    return SampleSummary(
        sample_id=sample.get("id"),
        input_text=truncate_text(sample.get("input"), max_text_length),
        target_text=truncate_text(sample.get("target"), max_text_length),
        messages_text=truncate_text(sample.get("messages"), max_text_length),
        output_text=extract_output_text(sample.get("output"), max_text_length),
        scores_text=truncate_text(trimmed_scores, max_text_length) if trimmed_scores is not None else "",
    )


def collect_samples(outputs_dir: Path, max_text_length: int) -> list[SampleSummary]:
    summaries: list[SampleSummary] = []
    for path in iter_log_files(outputs_dir):
        try:
            payload = load_json(path)
        except Exception:
            continue

        samples = payload.get("samples")
        if not isinstance(samples, list):
            continue

        for sample in samples:
            if isinstance(sample, dict):
                summaries.append(extract_sample(sample, max_text_length))
    return summaries


def choose_samples(samples: list[SampleSummary], rng: random.Random, sample_count: int) -> tuple[list[SampleSummary], str]:
    if len(samples) <= sample_count:
        shuffled = list(samples)
        rng.shuffle(shuffled)
        return shuffled, "random"
    return rng.sample(samples, sample_count), "random"


def render_summary(
    samples: list[SampleSummary],
    total_available_samples: int,
    source_log_count: int,
    sampling_mode: str,
    requested_count: int,
) -> str:
    lines = [
        "# Evaluation Sample Summary",
        "",
        f"- source_logs: {source_log_count}",
        f"- total_available_samples: {total_available_samples}",
        f"- sampling_mode: {sampling_mode}",
        f"- requested_samples: {requested_count}",
        f"- actual_samples: {len(samples)}",
        "",
    ]

    for index, sample in enumerate(samples, start=1):
        lines.extend([
            f"## Sample {index}",
            f"- id: {sample.sample_id}",
            "- input:",
            "```text",
            sample.input_text,
            "```",
            "- target:",
            "```text",
            sample.target_text,
            "```",
            "- messages:",
            "```json",
            sample.messages_text or "null",
            "```",
            "- output:",
            "```text",
            sample.output_text,
            "```",
            "- scores:",
            "```json",
            sample.scores_text or "null",
            "```",
            "",
        ])

    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Extract representative samples from inspect_ai logs under an eval_results directory "
            "and write eval_results/sample_summary.md by default."
        )
    )
    parser.add_argument(
        "--eval-results-dir",
        required=True,
        help=(
            "Path to the eval_results directory, not a single JSON log file. "
            "The script reads logs from <eval_results>/outputs/ and writes the summary under <eval_results>/."
        ),
    )
    parser.add_argument(
        "--output-file",
        default="sample_summary.md",
        help="Output filename written under --eval-results-dir. Default: sample_summary.md",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed used for sampling. Default: 42",
    )
    parser.add_argument(
        "--sample-count",
        type=int,
        default=15,
        help="Number of samples to include in the summary. Default: 15",
    )
    parser.add_argument(
        "--max-text-length",
        type=int,
        default=3000,
        help="Maximum stored length for each summary field. Default: 3000",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    eval_results_dir = Path(args.eval_results_dir)
    outputs_dir = eval_results_dir / "outputs"

    samples = collect_samples(outputs_dir, args.max_text_length)
    rng = random.Random(args.seed)
    selected_samples, sampling_mode = choose_samples(samples, rng, args.sample_count)

    summary_text = render_summary(
        samples=selected_samples,
        total_available_samples=len(samples),
        source_log_count=len(iter_log_files(outputs_dir)),
        sampling_mode=sampling_mode,
        requested_count=args.sample_count,
    )

    output_path = eval_results_dir / args.output_file
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(summary_text, encoding="utf-8")

    print(f"Wrote {output_path}")
    print(f"Available samples: {len(samples)}")
    print(f"Selected samples: {len(selected_samples)}")
    print(f"Sampling mode: {sampling_mode}")


if __name__ == "__main__":
    main()
