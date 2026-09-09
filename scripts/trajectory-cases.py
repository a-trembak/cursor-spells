#!/usr/bin/env python3
"""Validate and score agent-trajectory golden-set cases (stdlib only)."""

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
        "csp-tech-spec",
        "writing-plans",
        "approve-plan",
        "csp-implementation-critic",
        "issue-fix-plan",
        "start-build",
        "csp-software-developer",
        "csp-bug-fixer",
        "review-gate",
        "engineer-review",
        "csp-multi-repo-supervisor",
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
    "csp-tech-spec",
    "writing-plans",
    "approve-plan",
    "csp-implementation-critic",
    "start-build",
    "csp-software-developer",
    "review-gate",
    "engineer-review",
    "update-docs",
    "create-pr",
)
FAST_REQUIRED = ("bootstrap", "csp-software-developer", "engineer-review", "create-pr")
FAST_FORBIDDEN_STAGES = frozenset(
    {
        "csp-tech-spec",
        "writing-plans",
        "approve-plan",
        "csp-implementation-critic",
        "start-build",
        "review-gate",
        "update-docs",
        "csp-bug-fixer",
        "issue-fix-plan",
    }
)
ISSUE_REQUIRED = (
    "bootstrap",
    "issue-fix-plan",
    "csp-implementation-critic",
    "csp-bug-fixer",
    "engineer-review",
    "create-pr",
)
ISSUE_FORBIDDEN_STAGES = frozenset(
    {
        "csp-tech-spec",
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
    if not isinstance(fetch, str) or fetch not in FETCH_VALUES:
        errors.append(err(path, f"input.fetch must be one of {sorted(FETCH_VALUES)}"))
    jira_class = value.get("jira_class")
    if fetch == "ok":
        if not isinstance(jira_class, str) or jira_class not in JIRA_CLASSES:
            errors.append(err(path, "input.jira_class required when fetch is ok"))
    elif "jira_class" in value and jira_class is not None:
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


ANY_TOKEN_SENTINEL = "*"


def human_gate_any_tokens(item: dict[str, Any]) -> bool:
    if "tokens" not in item:
        return True
    return item.get("tokens") == [ANY_TOKEN_SENTINEL]


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
        if "tokens" not in item:
            continue
        tokens = item.get("tokens")
        if tokens == [ANY_TOKEN_SENTINEL]:
            continue
        if not isinstance(tokens, list) or not tokens or any(not is_nonempty_str(t) for t in tokens):
            errors.append(err(path, f"{loc}.tokens must be a non-empty list of strings"))
        elif isinstance(tokens, list) and ANY_TOKEN_SENTINEL in tokens:
            errors.append(
                err(path, f"{loc}.tokens '*' must be the only token when used as any-token")
            )
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


RUN_TOP_KEYS = frozenset(
    {
        "case_id",
        "input",
        "stages_entered",
        "artifacts_present",
        "actions_taken",
        "human_gates_asked",
        "end",
    }
)
RUN_ARTIFACT_KEYS = frozenset({"kind", "name", "path"})
RUN_GATE_KEYS = frozenset({"gate", "tokens_offered"})


def ordered_subsequence(required: list[str], actual: list[str]) -> bool:
    index = 0
    for stage in actual:
        if index < len(required) and stage == required[index]:
            index += 1
    return index == len(required)


def validate_run(data: Any, path: Path) -> list[str]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return [err(path, "run must be a JSON object")]
    extra = set(data) - RUN_TOP_KEYS
    missing = RUN_TOP_KEYS - set(data)
    if extra:
        errors.append(err(path, f"unknown keys: {sorted(extra)}"))
    if missing:
        errors.append(err(path, f"missing keys: {sorted(missing)}"))
        return errors
    if not is_nonempty_str(data["case_id"]):
        errors.append(err(path, "case_id must be a non-empty string"))
    errors.extend(validate_input(data["input"], path))
    stages = data["stages_entered"]
    if not isinstance(stages, list):
        errors.append(err(path, "stages_entered must be a list"))
    else:
        if any(not isinstance(item, str) for item in stages):
            errors.append(err(path, "stages_entered must be strings"))
        else:
            unknown = [item for item in stages if item not in STAGES]
            if unknown:
                errors.append(err(path, f"unknown stages: {unknown}"))
    artifacts = data["artifacts_present"]
    if not isinstance(artifacts, list):
        errors.append(err(path, "artifacts_present must be a list"))
    else:
        for index, item in enumerate(artifacts):
            loc = f"artifacts_present[{index}]"
            if not isinstance(item, dict):
                errors.append(err(path, f"{loc} must be an object"))
                continue
            extra_art = set(item) - RUN_ARTIFACT_KEYS
            if extra_art:
                errors.append(err(path, f"{loc} unknown keys: {sorted(extra_art)}"))
            if item.get("kind") not in ARTIFACT_KINDS:
                errors.append(err(path, f"{loc} unknown kind {item.get('kind')!r}"))
            if not is_nonempty_str(item.get("name")):
                errors.append(err(path, f"{loc}.name must be a non-empty string"))
    actions = data["actions_taken"]
    if not isinstance(actions, list):
        errors.append(err(path, "actions_taken must be a list"))
    else:
        unknown_act = [item for item in actions if item not in FORBIDDEN]
        if unknown_act:
            errors.append(err(path, f"unknown actions_taken: {unknown_act}"))
    asked = data["human_gates_asked"]
    if not isinstance(asked, list):
        errors.append(err(path, "human_gates_asked must be a list"))
    else:
        for index, item in enumerate(asked):
            loc = f"human_gates_asked[{index}]"
            if not isinstance(item, dict):
                errors.append(err(path, f"{loc} must be an object"))
                continue
            extra_g = set(item) - RUN_GATE_KEYS
            if extra_g:
                errors.append(err(path, f"{loc} unknown keys: {sorted(extra_g)}"))
            if item.get("gate") not in HUMAN_GATES:
                errors.append(err(path, f"{loc} unknown gate {item.get('gate')!r}"))
            tokens = item.get("tokens_offered")
            if not isinstance(tokens, list) or any(not is_nonempty_str(t) for t in tokens):
                errors.append(err(path, f"{loc}.tokens_offered must be a list of strings"))
    errors.extend(validate_expected_end(data["end"], path))
    return errors


def asked_map(run: dict[str, Any]) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {}
    for item in run.get("human_gates_asked") or []:
        if not isinstance(item, dict):
            continue
        gate = item.get("gate")
        tokens = item.get("tokens_offered") or []
        if isinstance(gate, str):
            result[gate] = set(tokens)
    return result


def artifact_keys(items: list[Any]) -> set[tuple[str, str]]:
    keys: set[tuple[str, str]] = set()
    for item in items:
        if isinstance(item, dict) and item.get("kind") and item.get("name"):
            keys.add((item["kind"], item["name"]))
    return keys


def inferred_forbidden(case: dict[str, Any], run: dict[str, Any]) -> dict[str, str]:
    fired: dict[str, str] = {}
    forbidden = set(case.get("forbidden") or [])
    stages: list[str] = list(run.get("stages_entered") or [])
    asked = asked_map(run)
    end = run.get("end") or {}
    fetch = (run.get("input") or {}).get("fetch")

    if "open-ready-before-finale" in forbidden:
        if end.get("pull_request") == "ready" and "pipeline-finale" not in asked:
            fired["open-ready-before-finale"] = "pull_request is ready but pipeline-finale was not asked"
    if "start-build-without-critique-clear" in forbidden:
        if "start-build" in stages and ("gate", "plan-critique-clear") not in artifact_keys(
            run.get("artifacts_present") or []
        ):
            fired["start-build-without-critique-clear"] = "start-build without (gate, plan-critique-clear)"
    if "fixes-returns-to-writing-plans" in forbidden:
        if "review-gate" in stages and "writing-plans" in stages:
            review_indexes = [i for i, stage in enumerate(stages) if stage == "review-gate"]
            plan_indexes = [i for i, stage in enumerate(stages) if stage == "writing-plans"]
            if review_indexes and plan_indexes and max(plan_indexes) > min(review_indexes):
                fired["fixes-returns-to-writing-plans"] = "writing-plans occurs after review-gate"
    if "url-only-stub-on-fetch-failure" in forbidden:
        extra = [stage for stage in stages if stage != "jira-fetch"]
        if fetch == "fail" and extra:
            fired["url-only-stub-on-fetch-failure"] = f"fetch failed but continued into {extra}"
    return fired


def score_run(case: dict[str, Any], run: dict[str, Any]) -> list[tuple[str, str]]:
    findings: list[tuple[str, str]] = []
    case_input = case.get("input") or {}
    run_input = run.get("input") or {}
    input_bits: list[str] = []
    for key in ("invocation", "fetch", "jira_class"):
        case_val = case_input.get(key)
        run_val = run_input.get(key)
        if case_val != run_val:
            input_bits.append(f"{key} case={case_val!r} run={run_val!r}")
    if input_bits:
        findings.append(("input", "; ".join(input_bits)))

    required_stages = list(case.get("required_stages") or [])
    actual_stages = list(run.get("stages_entered") or [])
    if not ordered_subsequence(required_stages, actual_stages):
        missing = [stage for stage in required_stages if stage not in actual_stages]
        if missing:
            findings.append(("required_stages", f"missing {missing}"))
        else:
            findings.append(("required_stages", f"out of order {required_stages}"))

    required_arts = artifact_keys(case.get("required_artifacts") or [])
    present_arts = artifact_keys(run.get("artifacts_present") or [])
    missing_arts = sorted(required_arts - present_arts)
    if missing_arts:
        findings.append(("required_artifacts", f"missing {missing_arts}"))

    case_end = case.get("expected_end") or {}
    run_end = run.get("end") or {}
    end_bits: list[str] = []
    for key in ("jira_status", "pull_request", "review_report"):
        if case_end.get(key) != run_end.get(key):
            end_bits.append(f"{key} case={case_end.get(key)!r} run={run_end.get(key)!r}")
    if end_bits:
        findings.append(("expected_end", "; ".join(end_bits)))

    asked = asked_map(run)
    human_bits: list[str] = []
    for item in case.get("human_must_appear") or []:
        gate = item["gate"]
        if gate not in asked:
            human_bits.append(f"{gate} not asked")
        elif human_gate_any_tokens(item):
            if not asked[gate]:
                human_bits.append(f"{gate} asked with empty tokens")
        else:
            expected_tokens = set(item["tokens"])
            if asked[gate] != expected_tokens:
                human_bits.append(
                    f"{gate} tokens {sorted(asked[gate])} != {sorted(expected_tokens)}"
                )
    if human_bits:
        findings.append(("human_must_appear", "; ".join(human_bits)))

    asked_forbidden = [gate for gate in (case.get("agent_must_not_ask") or []) if gate in asked]
    if asked_forbidden:
        findings.append(("agent_must_not_ask", f"asked {asked_forbidden}"))

    taken = set(run.get("actions_taken") or [])
    inferred = inferred_forbidden(case, run)
    for action in case.get("forbidden") or []:
        if action in taken:
            findings.append((f"forbidden:{action}", "observed in actions_taken"))
        elif action in inferred:
            findings.append((f"forbidden:{action}", inferred[action]))
    return findings


def load_case_for_run(
    run: dict[str, Any], kit_root: Path, case_path: Path | None
) -> tuple[dict[str, Any] | None, Path | None, str | None]:
    case_id = run.get("case_id")
    if not is_nonempty_str(case_id):
        return None, None, "case_id missing"
    path = case_path or (kit_root / "evals/trajectories/cases" / f"{case_id}.json")
    if not path.is_file():
        return None, path, f"case file not found: {path}"
    data, load_error = load_json(path)
    if load_error:
        return None, path, load_error
    if not isinstance(data, dict):
        return None, path, err(path, "case must be an object")
    if data.get("id") != case_id:
        return None, path, err(path, f"case id {data.get('id')!r} does not match run case_id {case_id!r}")
    case_errors = validate_case(data, path, kit_root)
    if case_errors:
        return None, path, case_errors[0]
    return data, path, None


def score_run_file(run_path: Path, kit_root: Path, case_path: Path | None) -> tuple[int, list[str]]:
    data, load_error = load_json(run_path)
    if load_error:
        return 1, [load_error]
    if not isinstance(data, dict):
        return 1, [err(run_path, "run must be a JSON object")]
    run_errors = validate_run(data, run_path)
    if run_errors:
        return 1, run_errors
    case, _, case_error = load_case_for_run(data, kit_root, case_path)
    if case_error or case is None:
        return 1, [str(case_error)]
    findings = score_run(case, data)
    case_id = data["case_id"]
    if not findings:
        return 0, [f"PASS {case_id}"]
    lines = [f"FAIL {case_id}: {sensor} {detail}" for sensor, detail in findings]
    return 1, lines


def score_paths(run_paths: list[Path], kit_root: Path, case_path: Path | None) -> tuple[int, list[str]]:
    exit_code = 0
    lines: list[str] = []
    for run_path in run_paths:
        code, out = score_run_file(run_path, kit_root, case_path)
        if code != 0:
            exit_code = 1
        lines.extend(out)
    return exit_code, lines


def empty_run(
    case_id: str, invocation: str, fetch: str, jira_class: str | None
) -> dict[str, Any]:
    payload: dict[str, Any] = {"invocation": invocation, "fetch": fetch}
    if jira_class is not None:
        payload["jira_class"] = jira_class
    return {
        "case_id": case_id,
        "input": payload,
        "stages_entered": [],
        "artifacts_present": [],
        "actions_taken": [],
        "human_gates_asked": [],
        "end": {
            "jira_status": None,
            "pull_request": "absent",
            "review_report": "absent",
        },
    }


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def load_ledger(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise SystemExit(err(path, "ledger file does not exist"))
    data, load_error = load_json(path)
    if load_error:
        raise SystemExit(load_error)
    if not isinstance(data, dict):
        raise SystemExit(err(path, "run must be a JSON object"))
    errors = validate_run(data, path)
    if errors:
        raise SystemExit("\n".join(errors))
    return data


def record_init(args: argparse.Namespace) -> int:
    if args.fetch == "ok" and args.jira_class is None:
        print("jira_class is required when fetch is ok", file=sys.stderr)
        return 1
    if args.fetch != "ok" and args.jira_class is not None:
        print("jira_class is only allowed when fetch is ok", file=sys.stderr)
        return 1
    write_json(
        args.ledger,
        empty_run(args.case_id, args.invocation, args.fetch, args.jira_class),
    )
    print(f"OK   {args.ledger.resolve()}")
    return 0


def record_stage(args: argparse.Namespace) -> int:
    if args.stage not in STAGES:
        print(f"unknown stage {args.stage!r}", file=sys.stderr)
        return 1
    data = load_ledger(args.ledger)
    data["stages_entered"].append(args.stage)
    write_json(args.ledger, data)
    print(f"OK   {args.ledger.resolve()}")
    return 0


def record_artifact(args: argparse.Namespace) -> int:
    if args.kind not in ARTIFACT_KINDS:
        print(f"unknown kind {args.kind!r}", file=sys.stderr)
        return 1
    if not is_nonempty_str(args.name):
        print("name must be a non-empty string", file=sys.stderr)
        return 1
    data = load_ledger(args.ledger)
    keys = artifact_keys(data["artifacts_present"])
    if (args.kind, args.name) not in keys:
        item: dict[str, Any] = {"kind": args.kind, "name": args.name}
        if args.path:
            item["path"] = str(args.path)
        data["artifacts_present"].append(item)
    write_json(args.ledger, data)
    print(f"OK   {args.ledger.resolve()}")
    return 0


def record_gate(args: argparse.Namespace) -> int:
    if args.gate not in HUMAN_GATES:
        print(f"unknown gate {args.gate!r}", file=sys.stderr)
        return 1
    tokens = [part.strip() for part in args.tokens.split(",") if part.strip()]
    if not tokens:
        print("tokens must be a non-empty comma-separated list", file=sys.stderr)
        return 1
    data = load_ledger(args.ledger)
    asked = [item for item in data["human_gates_asked"] if item.get("gate") != args.gate]
    asked.append({"gate": args.gate, "tokens_offered": tokens})
    data["human_gates_asked"] = asked
    write_json(args.ledger, data)
    print(f"OK   {args.ledger.resolve()}")
    return 0


def record_action(args: argparse.Namespace) -> int:
    if args.action not in FORBIDDEN:
        print(f"unknown action {args.action!r}", file=sys.stderr)
        return 1
    data = load_ledger(args.ledger)
    if args.action not in data["actions_taken"]:
        data["actions_taken"].append(args.action)
    write_json(args.ledger, data)
    print(f"OK   {args.ledger.resolve()}")
    return 0


def record_end(args: argparse.Namespace) -> int:
    data = load_ledger(args.ledger)
    if args.pull_request is not None:
        data["end"]["pull_request"] = args.pull_request
    if args.review_report is not None:
        data["end"]["review_report"] = args.review_report
    if args.jira_status is not None:
        data["end"]["jira_status"] = None if args.jira_status == "null" else args.jira_status
    errors = validate_run(data, args.ledger)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    write_json(args.ledger, data)
    print(f"OK   {args.ledger.resolve()}")
    return 0


def record_dump(args: argparse.Namespace) -> int:
    data = load_ledger(args.ledger)
    dest = args.out or args.ledger
    write_json(dest, data)
    print(f"OK   {dest.resolve()}")
    return 0


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
    sub = parser.add_subparsers(dest="command", required=True)

    p_val = sub.add_parser("validate", help="Validate golden-set case files")
    p_val.add_argument("--dir", type=Path, help="Directory of case JSON files")
    p_val.add_argument("--kit-root", type=Path, help="Kit root for resolving source paths")

    p_score = sub.add_parser("score", help="Score a recorded run against a case")
    p_score.add_argument("--run", type=Path, help="One run JSON file")
    p_score.add_argument("--runs-dir", type=Path, help="Directory of run JSON files")
    p_score.add_argument("--case", type=Path, help="Override case file (default: cases/<case_id>.json)")
    p_score.add_argument("--kit-root", type=Path, help="Kit root for resolving cases")

    p_rec = sub.add_parser("record", help="Assemble a run ledger for score")
    rec_sub = p_rec.add_subparsers(dest="record_command", required=True)

    def add_ledger_arg(parser: argparse.ArgumentParser) -> None:
        parser.add_argument("--ledger", type=Path, required=True)

    p_init = rec_sub.add_parser("init", help="Create an empty run ledger")
    add_ledger_arg(p_init)
    p_init.add_argument("--case-id", required=True)
    p_init.add_argument("--invocation", required=True)
    p_init.add_argument("--fetch", required=True, choices=sorted(FETCH_VALUES))
    p_init.add_argument("--jira-class", choices=sorted(JIRA_CLASSES))

    p_stage = rec_sub.add_parser("stage", help="Append a stage id")
    add_ledger_arg(p_stage)
    p_stage.add_argument("stage")

    p_art = rec_sub.add_parser("artifact", help="Append a present artifact")
    add_ledger_arg(p_art)
    p_art.add_argument("--kind", required=True)
    p_art.add_argument("--name", required=True)
    p_art.add_argument("--path", type=Path)

    p_gate = rec_sub.add_parser("gate", help="Record a human gate that was asked")
    add_ledger_arg(p_gate)
    p_gate.add_argument("--gate", required=True)
    p_gate.add_argument("--tokens", required=True)

    p_act = rec_sub.add_parser("action", help="Record an observed forbidden id")
    add_ledger_arg(p_act)
    p_act.add_argument("action")

    p_end = rec_sub.add_parser("end", help="Patch end-state fields")
    add_ledger_arg(p_end)
    p_end.add_argument("--pull-request", choices=sorted(PULL_REQUEST_STATES))
    p_end.add_argument("--review-report", choices=sorted(REVIEW_REPORT_STATES))
    p_end.add_argument(
        "--jira-status",
        choices=["null", *sorted(s for s in JIRA_STATUSES if s != "unchanged")],
    )

    p_dump = rec_sub.add_parser("dump", help="Validate and write the run JSON")
    add_ledger_arg(p_dump)
    p_dump.add_argument("--out", type=Path)

    args = parser.parse_args(argv)

    if args.command == "record":
        handlers = {
            "init": record_init,
            "stage": record_stage,
            "artifact": record_artifact,
            "gate": record_gate,
            "action": record_action,
            "end": record_end,
            "dump": record_dump,
        }
        handler = handlers.get(args.record_command)
        if handler is None:
            parser.error("record requires a subcommand")
        return handler(args)

    kit_root = (args.kit_root or kit_root_from_script()).resolve()

    if args.command == "validate":
        cases_dir = (args.dir or (kit_root / "evals/trajectories/cases")).resolve()
        errors = validate_dir(cases_dir, kit_root)
        if errors:
            for message in errors:
                print(message, file=sys.stderr)
            return 1
        print(f"OK   {cases_dir} ({len(list(cases_dir.glob('*.json')))} cases)")
        return 0

    if args.runs_dir and args.run:
        parser.error("use either --run or --runs-dir, not both")
    if args.runs_dir:
        runs_dir = args.runs_dir.resolve()
        if not runs_dir.is_dir():
            print(f"runs directory does not exist: {runs_dir}", file=sys.stderr)
            return 1
        run_paths = sorted(runs_dir.glob("*.json"))
        if not run_paths:
            print(f"no JSON runs in {runs_dir}", file=sys.stderr)
            return 1
    elif args.run:
        run_paths = [args.run.resolve()]
    else:
        parser.error("score requires --run or --runs-dir")

    case_path = args.case.resolve() if args.case else None
    code, lines = score_paths(run_paths, kit_root, case_path)
    for line in lines:
        stream = sys.stdout if line.startswith(("PASS ", "FAIL ")) else sys.stderr
        print(line, file=stream)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
