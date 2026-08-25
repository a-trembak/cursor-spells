#!/usr/bin/env python3
"""Validate agent-trajectory golden-set cases (stdlib only)."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

PIPELINES = frozenset({"full", "fast", "issue", "slice"})
STATUSES = frozenset({"active", "draft"})
FETCH_VALUES = frozenset({"ok", "fail", "skip"})
JIRA_CLASSES = frozenset({"feature", "bug", "unknown"})
PULL_REQUEST_STATES = frozenset({"draft", "ready", "absent"})
REVIEW_REPORT_STATES = frozenset({"evidence-gated", "absent"})
JIRA_STATUSES = frozenset({"In Progress", "Review", "unchanged"})

STAGES = frozenset(
    {
        "jira-fetch",
        "jira-transition-in-progress",
        "pipeline-route-hitl",
        "fast-vs-issue-hitl",
        "bootstrap",
        "tech-spec",
        "writing-plans",
        "approve-plan",
        "implementation-critic",
        "issue-fix-plan",
        "start-build",
        "software-developer",
        "bug-fixer",
        "review-gate",
        "engineer-review",
        "multi-repo-supervisor",
        "update-docs",
        "create-pr",
        "pipeline-finale-hitl",
        "capture-escape",
        "review-learn-capture",
        "teach-review",
        "clean-decision-docs",
    }
)

ARTIFACT_KINDS = frozenset({"file", "gate", "git", "github", "jira", "report"})
GATE_ARTIFACT_NAMES = frozenset(
    {
        "plan-gate",
        "critique-gate",
        "plan-critique-clear",
        "review-gate",
        "docs-gate",
    }
)

FORBIDDEN = frozenset(
    {
        "merge-pull-request",
        "invent-business-facts",
        "invent-acceptance-criteria",
        "auto-select-fast",
        "fixes-returns-to-writing-plans",
        "auto-fix-migration",
        "open-ready-before-finale",
        "url-only-stub-on-fetch-failure",
        "re-fetch-after-start-issue-handoff",
        "edit-plan-during-critic",
        "archaeology-in-decision-docs",
        "auto-apply-cross-repo-drift",
        "write-acceptance-criteria",
        "transition-from-write-tech-spec",
        "silent-auto-fix-failing-eligibility",
        "skip-critic-on-full-path",
        "start-build-without-critique-clear",
    }
)

HUMAN_GATES = frozenset(
    {
        "tech-spec-entry",
        "tech-spec-depth",
        "tech-spec-gate",
        "approve-plan",
        "review-gate",
        "figma-ask",
        "docs-update",
        "critic-blocked",
        "engineer-review-clarify",
        "force-clear-foreign-gate",
        "review-learn-promote",
        "teach-review-miss",
        "pipeline-route",
        "fast-vs-issue",
        "pipeline-finale",
        "decision-blocker",
    }
)

TOP_KEYS = frozenset(
    {
        "id",
        "title",
        "source",
        "pipeline",
        "end_to_end",
        "status",
        "input",
        "required_stages",
        "required_artifacts",
        "forbidden",
        "human_must_appear",
        "agent_must_not_ask",
        "expected_end",
    }
)
REQUIRED_TOP = TOP_KEYS
INPUT_KEYS = frozenset({"invocation", "fetch", "jira_class", "acceptance_criteria"})
END_KEYS = frozenset({"jira_status", "pull_request", "review_report", "notes"})

FULL_REQUIRED = (
    "bootstrap",
    "tech-spec",
    "writing-plans",
    "approve-plan",
    "implementation-critic",
    "start-build",
    "software-developer",
    "review-gate",
    "engineer-review",
    "update-docs",
    "create-pr",
)
FAST_REQUIRED = ("bootstrap", "software-developer", "engineer-review", "create-pr")
FAST_FORBIDDEN_STAGES = frozenset(
    {
        "tech-spec",
        "writing-plans",
        "approve-plan",
        "implementation-critic",
        "start-build",
        "review-gate",
        "update-docs",
        "bug-fixer",
        "issue-fix-plan",
    }
)
ISSUE_REQUIRED = (
    "bootstrap",
    "issue-fix-plan",
    "implementation-critic",
    "bug-fixer",
    "engineer-review",
    "create-pr",
)
ISSUE_FORBIDDEN_STAGES = frozenset(
    {
        "tech-spec",
        "writing-plans",
        "approve-plan",
        "review-gate",
        "update-docs",
    }
)


def kit_root_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def err(path: Path | None, message: str) -> str:
    prefix = f"{path}: " if path else ""
    return f"{prefix}{message}"


def is_nonempty_str(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def validate_case(data: Any, path: Path, kit_root: Path) -> list[str]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return [err(path, "case must be a JSON object")]

    extra = set(data) - TOP_KEYS
    missing = REQUIRED_TOP - set(data)
    if extra:
        errors.append(err(path, f"unknown keys: {sorted(extra)}"))
    if missing:
        errors.append(err(path, f"missing keys: {sorted(missing)}"))
        return errors

    case_id = data["id"]
    if not is_nonempty_str(case_id):
        errors.append(err(path, "id must be a non-empty string"))
    elif path.stem != case_id:
        errors.append(err(path, f"id {case_id!r} must match filename stem {path.stem!r}"))

    if not is_nonempty_str(data["title"]):
        errors.append(err(path, "title must be a non-empty string"))

    source = data["source"]
    if not is_nonempty_str(source):
        errors.append(err(path, "source must be a non-empty kit-relative path"))
    else:
        source_path = kit_root / source
        if not source_path.is_file():
            errors.append(err(path, f"source file does not exist: {source}"))

    pipeline = data["pipeline"]
    if pipeline not in PIPELINES:
        errors.append(err(path, f"unknown pipeline {pipeline!r}"))

    if not isinstance(data["end_to_end"], bool):
        errors.append(err(path, "end_to_end must be a boolean"))
    elif data["end_to_end"] and pipeline == "slice":
        errors.append(err(path, "slice cases cannot be end_to_end"))

    if data["status"] not in STATUSES:
        errors.append(err(path, f"unknown status {data['status']!r}"))

    errors.extend(validate_input(data["input"], path))
    errors.extend(validate_stages(data, path))
    errors.extend(validate_artifacts(data["required_artifacts"], path))
    errors.extend(validate_forbidden(data, path))
    errors.extend(validate_human_gates(data["human_must_appear"], path))
    errors.extend(validate_agent_must_not_ask(data["agent_must_not_ask"], path))
    errors.extend(validate_expected_end(data["expected_end"], path))
    return errors


def validate_input(value: Any, path: Path) -> list[str]:
    errors: list[str] = []
    if not isinstance(value, dict):
        return [err(path, "input must be an object")]
    extra = set(value) - INPUT_KEYS
    if extra:
        errors.append(err(path, f"unknown input keys: {sorted(extra)}"))
    if not is_nonempty_str(value.get("invocation")):
        errors.append(err(path, "input.invocation must be a non-empty string"))
    fetch = value.get("fetch")
    if fetch not in FETCH_VALUES:
        errors.append(err(path, f"input.fetch must be one of {sorted(FETCH_VALUES)}"))
    jira_class = value.get("jira_class")
    if fetch == "ok":
        if jira_class not in JIRA_CLASSES:
            errors.append(err(path, "input.jira_class required when fetch is ok"))
    elif jira_class not in (None,):
        if "jira_class" in value and jira_class is not None:
            errors.append(err(path, "input.jira_class must be omitted or null unless fetch is ok"))
    if "acceptance_criteria" in value and value["acceptance_criteria"] is not None:
        if not is_nonempty_str(value["acceptance_criteria"]):
            errors.append(err(path, "input.acceptance_criteria must be a non-empty string or null"))
    return errors


def validate_stages(data: dict[str, Any], path: Path) -> list[str]:
    errors: list[str] = []
    stages = data.get("required_stages")
    if not isinstance(stages, list) or not stages:
        return [err(path, "required_stages must be a non-empty list")]
    if any(not isinstance(item, str) for item in stages):
        return [err(path, "required_stages must be strings")]
    unknown = [item for item in stages if item not in STAGES]
    if unknown:
        errors.append(err(path, f"unknown stages: {unknown}"))
    if len(stages) != len(set(stages)):
        errors.append(err(path, "required_stages must not contain duplicates"))

    if data.get("end_to_end") is True:
        pipeline = data.get("pipeline")
        present = set(stages)
        if pipeline == "full":
            missing = [item for item in FULL_REQUIRED if item not in present]
            if missing:
                errors.append(err(path, f"full end-to-end missing stages: {missing}"))
        elif pipeline == "fast":
            missing = [item for item in FAST_REQUIRED if item not in present]
            if missing:
                errors.append(err(path, f"fast end-to-end missing stages: {missing}"))
            banned = sorted(present & FAST_FORBIDDEN_STAGES)
            if banned:
                errors.append(err(path, f"fast end-to-end forbids stages: {banned}"))
        elif pipeline == "issue":
            missing = [item for item in ISSUE_REQUIRED if item not in present]
            if missing:
                errors.append(err(path, f"issue end-to-end missing stages: {missing}"))
            banned = sorted(present & ISSUE_FORBIDDEN_STAGES)
            if banned:
                errors.append(err(path, f"issue end-to-end forbids stages: {banned}"))
    return errors


def validate_artifacts(value: Any, path: Path) -> list[str]:
    if not isinstance(value, list) or not value:
        return [err(path, "required_artifacts must be a non-empty list")]
    errors: list[str] = []
    for index, item in enumerate(value):
        loc = f"required_artifacts[{index}]"
        if not isinstance(item, dict):
            errors.append(err(path, f"{loc} must be an object"))
            continue
        extra = set(item) - {"kind", "name", "pattern"}
        if extra:
            errors.append(err(path, f"{loc} unknown keys: {sorted(extra)}"))
        kind = item.get("kind")
        if kind not in ARTIFACT_KINDS:
            errors.append(err(path, f"{loc} unknown kind {kind!r}"))
        if not is_nonempty_str(item.get("name")):
            errors.append(err(path, f"{loc}.name must be a non-empty string"))
        elif kind == "gate" and item["name"] not in GATE_ARTIFACT_NAMES:
            errors.append(err(path, f"{loc}.name unknown gate {item['name']!r}"))
        if "pattern" in item and item["pattern"] is not None and not is_nonempty_str(item["pattern"]):
            errors.append(err(path, f"{loc}.pattern must be a non-empty string or omitted"))
        if kind == "file" and not is_nonempty_str(item.get("pattern")):
            errors.append(err(path, f"{loc}.pattern required for file artifacts"))
    return errors


def validate_forbidden(data: dict[str, Any], path: Path) -> list[str]:
    value = data.get("forbidden")
    if not isinstance(value, list) or not value:
        return [err(path, "forbidden must be a non-empty list")]
    errors: list[str] = []
    unknown = [item for item in value if item not in FORBIDDEN]
    if unknown:
        errors.append(err(path, f"unknown forbidden actions: {unknown}"))
    if len(value) != len(set(value)):
        errors.append(err(path, "forbidden must not contain duplicates"))
    stages = data.get("required_stages") or []
    if "create-pr" in stages and "merge-pull-request" not in value:
        errors.append(err(path, "cases that include create-pr must forbid merge-pull-request"))
    return errors


def validate_human_gates(value: Any, path: Path) -> list[str]:
    if not isinstance(value, list):
        return [err(path, "human_must_appear must be a list")]
    errors: list[str] = []
    for index, item in enumerate(value):
        loc = f"human_must_appear[{index}]"
        if not isinstance(item, dict):
            errors.append(err(path, f"{loc} must be an object"))
            continue
        extra = set(item) - {"gate", "tokens"}
        if extra:
            errors.append(err(path, f"{loc} unknown keys: {sorted(extra)}"))
        gate = item.get("gate")
        if gate not in HUMAN_GATES:
            errors.append(err(path, f"{loc} unknown gate {gate!r}"))
        tokens = item.get("tokens")
        if not isinstance(tokens, list) or not tokens or any(not is_nonempty_str(t) for t in tokens):
            errors.append(err(path, f"{loc}.tokens must be a non-empty list of strings"))
    return errors


def validate_agent_must_not_ask(value: Any, path: Path) -> list[str]:
    if not isinstance(value, list):
        return [err(path, "agent_must_not_ask must be a list")]
    errors: list[str] = []
    for item in value:
        if item not in HUMAN_GATES:
            errors.append(err(path, f"unknown agent_must_not_ask gate {item!r}"))
    if len(value) != len(set(value)):
        errors.append(err(path, "agent_must_not_ask must not contain duplicates"))
    return errors


def validate_expected_end(value: Any, path: Path) -> list[str]:
    if not isinstance(value, dict):
        return [err(path, "expected_end must be an object")]
    errors: list[str] = []
    extra = set(value) - END_KEYS
    if extra:
        errors.append(err(path, f"unknown expected_end keys: {sorted(extra)}"))
    for key in ("jira_status", "pull_request", "review_report"):
        if key not in value:
            errors.append(err(path, f"expected_end.{key} is required"))
    jira_status = value.get("jira_status")
    if jira_status is not None and jira_status not in JIRA_STATUSES:
        errors.append(err(path, f"unknown expected_end.jira_status {jira_status!r}"))
    pull_request = value.get("pull_request")
    if pull_request not in PULL_REQUEST_STATES:
        errors.append(err(path, f"unknown expected_end.pull_request {pull_request!r}"))
    review_report = value.get("review_report")
    if review_report not in REVIEW_REPORT_STATES:
        errors.append(err(path, f"unknown expected_end.review_report {review_report!r}"))
    if "notes" in value and value["notes"] is not None and not is_nonempty_str(value["notes"]):
        errors.append(err(path, "expected_end.notes must be a non-empty string or omitted"))
    return errors


def load_json(path: Path) -> tuple[Any | None, str | None]:
    try:
        return json.loads(path.read_text(encoding="utf-8")), None
    except json.JSONDecodeError as exc:
        return None, err(path, f"invalid JSON: {exc}")


def validate_dir(cases_dir: Path, kit_root: Path) -> list[str]:
    errors: list[str] = []
    if not cases_dir.is_dir():
        return [err(None, f"cases directory does not exist: {cases_dir}")]
    files = sorted(cases_dir.glob("*.json"))
    if not files:
        return [err(cases_dir, "no JSON cases found")]
    seen_ids: dict[str, Path] = {}
    for path in files:
        data, load_error = load_json(path)
        if load_error:
            errors.append(load_error)
            continue
        case_errors = validate_case(data, path, kit_root)
        errors.extend(case_errors)
        case_id = data.get("id") if isinstance(data, dict) else None
        if isinstance(case_id, str):
            prior = seen_ids.get(case_id)
            if prior is not None:
                errors.append(err(path, f"duplicate id {case_id!r} (also {prior.name})"))
            else:
                seen_ids[case_id] = path
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["validate"])
    parser.add_argument("--dir", type=Path, help="Directory of case JSON files")
    parser.add_argument("--kit-root", type=Path, help="Kit root for resolving source paths")
    args = parser.parse_args(argv)

    kit_root = (args.kit_root or kit_root_from_script()).resolve()
    cases_dir = (args.dir or (kit_root / "evals/trajectories/cases")).resolve()
    errors = validate_dir(cases_dir, kit_root)
    if errors:
        for message in errors:
            print(message, file=sys.stderr)
        return 1
    print(f"OK   {cases_dir} ({len(list(cases_dir.glob('*.json')))} cases)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
