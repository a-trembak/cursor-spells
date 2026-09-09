#!/usr/bin/env python3
"""Validate and score agent code-quality golden-set cases (stdlib only)."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

STATUSES = frozenset({"active", "draft"})
MODES = frozenset({"fast", "full", "issue", "slice"})

TOP_KEYS = frozenset(
    {
        "id",
        "title",
        "source",
        "status",
        "mode",
        "fixture",
        "expected_files",
        "forbidden_paths",
        "required_substrings",
        "forbidden_substrings",
        "test_commands",
    }
)
REQUIRED_TOP = TOP_KEYS
RUN_KEYS = frozenset({"case_id", "workspace"})


def kit_root_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def err(path: Path | None, message: str) -> str:
    prefix = f"{path}: " if path else ""
    return f"{prefix}{message}"


def is_nonempty_str(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def is_str_list(value: Any) -> bool:
    return isinstance(value, list) and all(is_nonempty_str(x) for x in value)


def validate_substring_map(value: Any, path: Path, field: str) -> list[str]:
    errors: list[str] = []
    if not isinstance(value, dict):
        return [err(path, f"{field} must be an object")]
    for key, items in value.items():
        if not is_nonempty_str(key):
            errors.append(err(path, f"{field} keys must be non-empty strings"))
            continue
        if not is_str_list(items):
            errors.append(err(path, f"{field}[{key!r}] must be a list of non-empty strings"))
    return errors


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
        errors.append(err(path, "source must be a non-empty string"))
    else:
        source_path = kit_root / source
        if not source_path.is_file():
            errors.append(err(path, f"source file missing: {source}"))

    if data["status"] not in STATUSES:
        errors.append(err(path, f"status must be one of {sorted(STATUSES)}"))
    if data["mode"] not in MODES:
        errors.append(err(path, f"mode must be one of {sorted(MODES)}"))

    fixture = data["fixture"]
    if not is_nonempty_str(fixture):
        errors.append(err(path, "fixture must be a non-empty string"))
    else:
        fixture_path = kit_root / fixture
        if not fixture_path.is_dir():
            errors.append(err(path, f"fixture directory missing: {fixture}"))

    for field in ("expected_files", "forbidden_paths", "test_commands"):
        if not is_str_list(data[field]):
            errors.append(err(path, f"{field} must be a list of non-empty strings"))

    errors.extend(validate_substring_map(data["required_substrings"], path, "required_substrings"))
    errors.extend(validate_substring_map(data["forbidden_substrings"], path, "forbidden_substrings"))
    return errors


def validate_run(data: Any, path: Path) -> list[str]:
    errors: list[str] = []
    if not isinstance(data, dict):
        return [err(path, "run must be a JSON object")]
    extra = set(data) - RUN_KEYS
    if extra:
        errors.append(err(path, f"unknown keys: {sorted(extra)}"))
    if "case_id" not in data or not is_nonempty_str(data["case_id"]):
        errors.append(err(path, "case_id must be a non-empty string"))
    if "workspace" in data and data["workspace"] is not None and not is_nonempty_str(data["workspace"]):
        errors.append(err(path, "workspace must be a non-empty string when set"))
    return errors


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def resolve_workspace(case: dict[str, Any], run: dict[str, Any], kit_root: Path) -> Path:
    raw = run.get("workspace") or case["fixture"]
    path = Path(raw)
    if not path.is_absolute():
        path = kit_root / path
    return path.resolve()


def score_workspace(case: dict[str, Any], workspace: Path) -> list[tuple[str, str]]:
    findings: list[tuple[str, str]] = []
    if not workspace.is_dir():
        return [("FAIL", f"workspace missing: {workspace}")]

    for rel in case["expected_files"]:
        target = workspace / rel
        if not target.is_file():
            findings.append(("FAIL", f"expected file missing: {rel}"))

    for rel in case["forbidden_paths"]:
        target = workspace / rel
        if target.exists():
            findings.append(("FAIL", f"forbidden path present: {rel}"))

    for rel, needles in case["required_substrings"].items():
        target = workspace / rel
        if not target.is_file():
            findings.append(("FAIL", f"required_substrings target missing: {rel}"))
            continue
        text = target.read_text(encoding="utf-8", errors="replace")
        for needle in needles:
            if needle not in text:
                findings.append(("FAIL", f"required substring absent in {rel}: {needle!r}"))

    for rel, needles in case["forbidden_substrings"].items():
        target = workspace / rel
        if not target.is_file():
            # Absent file cannot contain forbidden text — skip (expected_files covers must-exist).
            continue
        text = target.read_text(encoding="utf-8", errors="replace")
        for needle in needles:
            if needle in text:
                findings.append(("FAIL", f"forbidden substring present in {rel}: {needle!r}"))

    for cmd in case["test_commands"]:
        try:
            completed = subprocess.run(
                cmd,
                shell=True,
                cwd=str(workspace),
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError as exc:
            findings.append(("FAIL", f"test_command error {cmd!r}: {exc}"))
            continue
        if completed.returncode != 0:
            detail = (completed.stderr or completed.stdout or "").strip().splitlines()
            tail = detail[-3:] if detail else []
            suffix = f" :: {' | '.join(tail)}" if tail else ""
            findings.append(("FAIL", f"test_command exit {completed.returncode}: {cmd!r}{suffix}"))

    return findings


def validate_dir(cases_dir: Path, kit_root: Path) -> list[str]:
    errors: list[str] = []
    if not cases_dir.is_dir():
        return [err(None, f"cases directory missing: {cases_dir}")]
    seen: dict[str, Path] = {}
    paths = sorted(cases_dir.glob("*.json"))
    if not paths:
        errors.append(err(cases_dir, "no case JSON files found"))
    for path in paths:
        try:
            data = load_json(path)
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(err(path, f"invalid JSON: {exc}"))
            continue
        case_errors = validate_case(data, path, kit_root)
        errors.extend(case_errors)
        if isinstance(data, dict) and is_nonempty_str(data.get("id")):
            case_id = data["id"]
            if case_id in seen:
                errors.append(err(path, f"duplicate id {case_id!r} (also {seen[case_id]})"))
            else:
                seen[case_id] = path
    return errors


def score_run_file(run_path: Path, kit_root: Path, case_path: Path | None) -> tuple[int, list[str]]:
    lines: list[str] = []
    try:
        data = load_json(run_path)
    except (OSError, json.JSONDecodeError) as exc:
        return 1, [err(run_path, f"invalid JSON: {exc}")]

    run_errors = validate_run(data, run_path)
    if run_errors:
        return 1, run_errors

    case_id = data["case_id"]
    resolved_case = case_path or (kit_root / "evals" / "code-quality" / "cases" / f"{case_id}.json")
    if not resolved_case.is_file():
        return 1, [err(run_path, f"case file missing: {resolved_case}")]

    try:
        case = load_json(resolved_case)
    except (OSError, json.JSONDecodeError) as exc:
        return 1, [err(resolved_case, f"invalid JSON: {exc}")]

    case_errors = validate_case(case, resolved_case, kit_root)
    if case_errors:
        return 1, case_errors
    if case["id"] != case_id:
        return 1, [err(run_path, f"case_id {case_id!r} does not match case id {case['id']!r}")]

    workspace = resolve_workspace(case, data, kit_root)
    findings = score_workspace(case, workspace)
    if not findings:
        lines.append(f"PASS {case_id}")
        return 0, lines

    for level, message in findings:
        lines.append(f"{level} {case_id}: {message}")
    return 1, lines


def score_paths(run_paths: list[Path], kit_root: Path, case_path: Path | None) -> tuple[int, list[str]]:
    code = 0
    out: list[str] = []
    for run_path in run_paths:
        c, lines = score_run_file(run_path, kit_root, case_path)
        code = max(code, c)
        out.extend(lines)
    return code, out


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_val = sub.add_parser("validate", help="Validate code-quality case files")
    p_val.add_argument("--kit-root", type=Path, help="Kit root")
    p_val.add_argument("--cases-dir", type=Path, help="Override cases directory")

    p_score = sub.add_parser("score", help="Score a workspace run against a case")
    p_score.add_argument("--run", type=Path, help="One run JSON file")
    p_score.add_argument("--runs-dir", type=Path, help="Directory of run JSON files")
    p_score.add_argument("--case", type=Path, help="Override case file")
    p_score.add_argument("--kit-root", type=Path, help="Kit root")
    p_score.add_argument("--workspace", type=Path, help="Score this workspace against --case")

    args = parser.parse_args(argv)
    kit_root = (args.kit_root or kit_root_from_script()).resolve()

    if args.command == "validate":
        cases_dir = (args.cases_dir or (kit_root / "evals" / "code-quality" / "cases")).resolve()
        errors = validate_dir(cases_dir, kit_root)
        if errors:
            for line in errors:
                print(line, file=sys.stderr)
            return 1
        print(f"OK {cases_dir} ({len(list(cases_dir.glob('*.json')))} cases)")
        return 0

    if args.command == "score":
        if args.workspace is not None:
            if args.case is None:
                parser.error("--workspace requires --case")
            try:
                case = load_json(args.case)
            except (OSError, json.JSONDecodeError) as exc:
                print(err(args.case, f"invalid JSON: {exc}"), file=sys.stderr)
                return 1
            case_errors = validate_case(case, args.case, kit_root)
            if case_errors:
                for line in case_errors:
                    print(line, file=sys.stderr)
                return 1
            workspace = args.workspace if args.workspace.is_absolute() else (kit_root / args.workspace)
            findings = score_workspace(case, workspace.resolve())
            if not findings:
                print(f"PASS {case['id']}")
                return 0
            for level, message in findings:
                print(f"{level} {case['id']}: {message}")
            return 1

        if bool(args.run) == bool(args.runs_dir):
            if args.run and args.runs_dir:
                parser.error("use either --run or --runs-dir, not both")
            parser.error("provide --run, --runs-dir, or --workspace with --case")

        if args.run:
            run_paths = [args.run.resolve()]
        else:
            runs_dir = args.runs_dir.resolve()
            run_paths = sorted(runs_dir.glob("*.json"))
            if not run_paths:
                print(err(runs_dir, "no run JSON files found"), file=sys.stderr)
                return 1

        code, lines = score_paths(run_paths, kit_root, args.case.resolve() if args.case else None)
        for line in lines:
            print(line)
        return code

    parser.error(f"unknown command {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
