#!/usr/bin/env python3
"""Live pipeline metrics journal for consumer projects (stdlib only).

Records quality and speed from real pipeline stops into a JSONL history so
humans can graph regressions over time. Kit-owned tooling — agents call this
via $KIT; history lives under the consumer project.
"""

from __future__ import annotations

import argparse
import csv
import importlib.util
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = 1
DEFAULT_HISTORY = Path(".cursor/gates/pipeline-metrics/history.jsonl")
DEFAULT_ACTIVE_DIR = Path(".cursor/gates/pipeline-metrics/active")


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def kit_root_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def parse_iso(value: str) -> datetime:
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    return datetime.fromisoformat(text)


def duration_seconds(started_at: str | None, ended_at: str | None) -> float | None:
    if not started_at or not ended_at:
        return None
    try:
        delta = parse_iso(ended_at) - parse_iso(started_at)
    except ValueError:
        return None
    return round(max(delta.total_seconds(), 0.0), 3)


def mark_path_for_ledger(active_dir: Path, ledger: Path) -> Path:
    safe = re.sub(r"[^A-Za-z0-9._-]+", "_", str(ledger.resolve()))
    if len(safe) > 180:
        safe = safe[-180:]
    return active_dir / f"{safe}.json"


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def load_json_object(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise SystemExit(f"expected JSON object in {path}")
    return data


def write_json(path: Path, data: dict[str, Any]) -> None:
    ensure_parent(path)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def append_jsonl(history: Path, event: dict[str, Any]) -> None:
    ensure_parent(history)
    with history.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, ensure_ascii=False, sort_keys=True) + "\n")


def read_history(history: Path) -> list[dict[str, Any]]:
    if not history.is_file():
        return []
    rows: list[dict[str, Any]] = []
    for line_no, line in enumerate(history.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            data = json.loads(line)
        except json.JSONDecodeError as exc:
            raise SystemExit(f"invalid JSONL at {history}:{line_no}: {exc}") from exc
        if isinstance(data, dict):
            rows.append(data)
    return rows


def load_module(path: Path, module_name: str) -> Any:
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"cannot load module from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_case_meta(kit_root: Path, case_id: str) -> dict[str, Any]:
    path = kit_root / "evals" / "trajectories" / "cases" / f"{case_id}.json"
    if not path.is_file():
        return {}
    try:
        data = load_json_object(path)
    except (SystemExit, json.JSONDecodeError, OSError):
        return {}
    out: dict[str, Any] = {}
    if isinstance(data.get("pipeline"), str):
        out["pipeline"] = data["pipeline"]
    if isinstance(data.get("end_to_end"), bool):
        out["end_to_end"] = data["end_to_end"]
    return out


def score_trajectory(kit_root: Path, ledger: Path) -> tuple[int, list[str]]:
    scorer_path = kit_root / "scripts" / "trajectory-cases.py"
    if not scorer_path.is_file():
        return 1, [f"scorer missing: {scorer_path}"]
    module = load_module(scorer_path, "trajectory_cases_for_metrics")
    code, lines = module.score_run_file(ledger, kit_root, None)
    return int(code), list(lines)


def verdict_from_score_lines(lines: list[str], exit_code: int) -> str:
    for line in lines:
        if line.startswith("PASS "):
            return "PASS"
        if line.startswith("FAIL "):
            return "FAIL"
    return "PASS" if exit_code == 0 else "FAIL"


def cmd_mark_start(args: argparse.Namespace) -> int:
    ledger = args.ledger.resolve()
    if not ledger.is_file():
        print(f"ledger file does not exist: {ledger}", file=sys.stderr)
        return 1
    active_dir = args.active_dir.resolve()
    mark = mark_path_for_ledger(active_dir, ledger)
    payload: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "ledger": str(ledger),
        "started_at": utc_now(),
        "stages": [],
    }
    if args.ticket:
        payload["ticket"] = args.ticket
    write_json(mark, payload)
    print(f"OK   mark-start {mark}")
    return 0


def cmd_mark_stage(args: argparse.Namespace) -> int:
    ledger = args.ledger.resolve()
    active_dir = args.active_dir.resolve()
    mark = mark_path_for_ledger(active_dir, ledger)
    if not mark.is_file():
        code = cmd_mark_start(
            argparse.Namespace(ledger=ledger, active_dir=active_dir, ticket=args.ticket)
        )
        if code != 0:
            return code
    data = load_json_object(mark)
    stages = data.get("stages")
    if not isinstance(stages, list):
        stages = []
    stages.append({"stage": args.stage, "at": utc_now()})
    data["stages"] = stages
    if args.ticket:
        data["ticket"] = args.ticket
    write_json(mark, data)
    print(f"OK   mark-stage {args.stage}")
    return 0


def build_score_event(
    *,
    kit_root: Path,
    ledger: Path,
    score_code: int,
    score_lines: list[str],
    mark: dict[str, Any] | None,
    ticket: str | None,
    duration_s: float | None,
    recorded_at: str,
) -> dict[str, Any]:
    run_data: dict[str, Any] = {}
    if ledger.is_file():
        try:
            run_data = load_json_object(ledger)
        except (SystemExit, json.JSONDecodeError, OSError):
            run_data = {}

    case_id = run_data.get("case_id") if isinstance(run_data.get("case_id"), str) else None
    invocation = None
    input_obj = run_data.get("input")
    if isinstance(input_obj, dict) and isinstance(input_obj.get("invocation"), str):
        invocation = input_obj["invocation"]

    stages = run_data.get("stages_entered")
    gates = run_data.get("human_gates_asked")
    stage_count = len(stages) if isinstance(stages, list) else 0
    gate_count = len(gates) if isinstance(gates, list) else 0

    started_at = None
    if isinstance(mark, dict) and isinstance(mark.get("started_at"), str):
        started_at = mark["started_at"]
    if duration_s is None:
        duration_s = duration_seconds(started_at, recorded_at)

    if ticket is None and isinstance(mark, dict) and isinstance(mark.get("ticket"), str):
        ticket = mark["ticket"]

    case_meta = load_case_meta(kit_root, case_id) if case_id else {}
    verdict = verdict_from_score_lines(score_lines, score_code)

    event: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "kind": "trajectory_score",
        "recorded_at": recorded_at,
        "case_id": case_id,
        "pipeline": case_meta.get("pipeline"),
        "end_to_end": case_meta.get("end_to_end"),
        "invocation": invocation,
        "verdict": verdict,
        "exit_code": score_code,
        "duration_s": duration_s,
        "stage_count": stage_count,
        "gate_count": gate_count,
        "score_lines": score_lines,
        "source": {
            "ledger": str(ledger),
            "started_at": started_at,
        },
    }
    if ticket:
        event["ticket"] = ticket
    if isinstance(mark, dict) and isinstance(mark.get("stages"), list) and mark["stages"]:
        event["source"]["stage_marks"] = mark["stages"]
    return event


def cmd_append_score(args: argparse.Namespace) -> int:
    kit_root = (args.kit_root or kit_root_from_script()).resolve()
    ledger = args.run.resolve()
    history = args.history.resolve()
    active_dir = args.active_dir.resolve()
    mark_file = mark_path_for_ledger(active_dir, ledger)
    mark = load_json_object(mark_file) if mark_file.is_file() else None

    if not ledger.is_file():
        print(f"ledger file does not exist: {ledger}", file=sys.stderr)
        return 1

    score_code, score_lines = score_trajectory(kit_root, ledger)
    for line in score_lines:
        stream = sys.stdout if line.startswith(("PASS ", "FAIL ")) else sys.stderr
        print(line, file=stream)

    recorded_at = utc_now()
    event = build_score_event(
        kit_root=kit_root,
        ledger=ledger,
        score_code=score_code,
        score_lines=score_lines,
        mark=mark,
        ticket=args.ticket,
        duration_s=args.duration_s,
        recorded_at=recorded_at,
    )
    append_jsonl(history, event)
    print(
        f"OK   metrics-append {history} verdict={event['verdict']} "
        f"duration_s={event['duration_s']}"
    )

    if mark_file.is_file() and not args.keep_mark:
        mark_file.unlink()
    return score_code


def cmd_append_review(args: argparse.Namespace) -> int:
    kit_root = (args.kit_root or kit_root_from_script()).resolve()
    report = args.path.resolve()
    history = args.history.resolve()
    scorer = kit_root / "scripts" / "review-response-quality.py"
    if not scorer.is_file():
        print(f"review scorer missing: {scorer}", file=sys.stderr)
        return 1
    if not report.is_file():
        print(f"report file does not exist: {report}", file=sys.stderr)
        return 1

    proc = subprocess.run(
        [sys.executable, str(scorer), "score", str(report), "--kit-root", str(kit_root)],
        capture_output=True,
        text=True,
        check=False,
    )
    try:
        result = json.loads(proc.stdout or "{}")
    except json.JSONDecodeError:
        result = {
            "ok": False,
            "failures": ["review-response-quality produced non-JSON stdout"],
        }
    if not isinstance(result, dict):
        result = {"ok": False, "failures": ["review-response-quality stdout was not an object"]}

    ok = bool(result.get("ok"))
    recorded_at = utc_now()
    event: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "kind": "review_response_quality",
        "recorded_at": recorded_at,
        "verdict": "PASS" if ok else "FAIL",
        "exit_code": 0 if ok else 1,
        "duration_s": args.duration_s,
        "quality": {
            "ok": ok,
            "kind": result.get("kind"),
            "item_count": result.get("item_count"),
            "evidence_complete_count": result.get("evidence_complete_count"),
            "evidence_complete_rate": result.get("evidence_complete_rate"),
            "clarify_options_rate": result.get("clarify_options_rate"),
            "markdown_validator_ok": result.get("markdown_validator_ok"),
            "failures": result.get("failures") or [],
        },
        "source": {"report": str(report)},
    }
    if args.ticket:
        event["ticket"] = args.ticket
    if args.case_id:
        event["case_id"] = args.case_id

    append_jsonl(history, event)
    if proc.stdout:
        sys.stdout.write(proc.stdout if proc.stdout.endswith("\n") else proc.stdout + "\n")
    if proc.stderr:
        sys.stderr.write(proc.stderr)
    print(f"OK   metrics-append {history} verdict={event['verdict']}")
    return 0 if ok else 1


def cmd_append_raw(args: argparse.Namespace) -> int:
    history = args.history.resolve()
    event: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "kind": args.kind,
        "recorded_at": utc_now(),
        "verdict": args.verdict,
        "duration_s": args.duration_s,
        "case_id": args.case_id,
        "pipeline": args.pipeline,
        "ticket": args.ticket,
        "note": args.note,
    }
    event = {key: value for key, value in event.items() if value is not None}
    append_jsonl(history, event)
    print(f"OK   metrics-append {history}")
    return 0


def cmd_summary(args: argparse.Namespace) -> int:
    history = args.history.resolve()
    rows = read_history(history)
    if args.last and args.last > 0:
        rows = rows[-args.last :]
    if not rows:
        print(f"pipeline-metrics: no events in {history}")
        return 0

    by_kind: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        kind = str(row.get("kind") or "unknown")
        by_kind.setdefault(kind, []).append(row)

    print(f"pipeline-metrics summary ({len(rows)} events) ← {history}")
    for kind, items in sorted(by_kind.items()):
        passes = sum(1 for item in items if item.get("verdict") == "PASS")
        fails = sum(1 for item in items if item.get("verdict") == "FAIL")
        durations = [
            float(item["duration_s"])
            for item in items
            if isinstance(item.get("duration_s"), (int, float))
        ]
        avg_d = round(sum(durations) / len(durations), 3) if durations else None
        rate = round(passes / len(items), 4) if items else 0.0
        print(
            f"  {kind}: n={len(items)} PASS={passes} FAIL={fails} "
            f"pass_rate={rate} avg_duration_s={avg_d}"
        )

    print("recent:")
    for item in rows[-min(10, len(rows)) :]:
        label = item.get("case_id")
        if not label and isinstance(item.get("source"), dict):
            label = item["source"].get("report") or item["source"].get("ledger")
        print(
            f"  {item.get('recorded_at')} {item.get('kind')} {label} "
            f"verdict={item.get('verdict')} duration_s={item.get('duration_s')}"
        )
    return 0


def cmd_export(args: argparse.Namespace) -> int:
    history = args.history.resolve()
    rows = read_history(history)
    out = args.out
    fmt = args.format

    if fmt == "jsonl":
        text = "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in rows)
        if out:
            ensure_parent(out)
            out.write_text(text, encoding="utf-8")
            print(f"OK   exported {len(rows)} rows → {out.resolve()}")
        else:
            sys.stdout.write(text)
        return 0

    if fmt == "json":
        payload = json.dumps(rows, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
        if out:
            ensure_parent(out)
            out.write_text(payload, encoding="utf-8")
            print(f"OK   exported {len(rows)} rows → {out.resolve()}")
        else:
            sys.stdout.write(payload)
        return 0

    fieldnames = [
        "recorded_at",
        "kind",
        "case_id",
        "pipeline",
        "ticket",
        "verdict",
        "exit_code",
        "duration_s",
        "stage_count",
        "gate_count",
        "evidence_complete_rate",
        "clarify_options_rate",
        "markdown_validator_ok",
    ]
    buffer_lines: list[dict[str, Any]] = []
    for row in rows:
        quality = row.get("quality") if isinstance(row.get("quality"), dict) else {}
        buffer_lines.append(
            {
                "recorded_at": row.get("recorded_at"),
                "kind": row.get("kind"),
                "case_id": row.get("case_id"),
                "pipeline": row.get("pipeline"),
                "ticket": row.get("ticket"),
                "verdict": row.get("verdict"),
                "exit_code": row.get("exit_code"),
                "duration_s": row.get("duration_s"),
                "stage_count": row.get("stage_count"),
                "gate_count": row.get("gate_count"),
                "evidence_complete_rate": quality.get("evidence_complete_rate"),
                "clarify_options_rate": quality.get("clarify_options_rate"),
                "markdown_validator_ok": quality.get("markdown_validator_ok"),
            }
        )

    if out:
        ensure_parent(out)
        with out.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(buffer_lines)
        print(f"OK   exported {len(buffer_lines)} rows → {out.resolve()}")
    else:
        writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(buffer_lines)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    def add_history(p: argparse.ArgumentParser) -> None:
        p.add_argument(
            "--history",
            type=Path,
            default=DEFAULT_HISTORY,
            help=f"JSONL history path (default: {DEFAULT_HISTORY})",
        )

    def add_active(p: argparse.ArgumentParser) -> None:
        p.add_argument(
            "--active-dir",
            type=Path,
            default=DEFAULT_ACTIVE_DIR,
            help=f"Active mark directory (default: {DEFAULT_ACTIVE_DIR})",
        )

    p_ms = sub.add_parser("mark-start", help="Start timing for a trajectory ledger")
    p_ms.add_argument("--ledger", type=Path, required=True)
    p_ms.add_argument("--ticket")
    add_active(p_ms)
    p_ms.set_defaults(func=cmd_mark_start)

    p_mst = sub.add_parser("mark-stage", help="Append a stage timestamp to the active mark")
    p_mst.add_argument("--ledger", type=Path, required=True)
    p_mst.add_argument("--stage", required=True)
    p_mst.add_argument("--ticket")
    add_active(p_mst)
    p_mst.set_defaults(func=cmd_mark_stage)

    p_as = sub.add_parser(
        "append-score",
        help="Score a ledger and append one history event (wraps trajectory score)",
    )
    p_as.add_argument("--run", type=Path, required=True, help="Trajectory ledger JSON")
    p_as.add_argument("--kit-root", type=Path)
    p_as.add_argument("--ticket")
    p_as.add_argument("--duration-s", type=float, help="Override measured duration")
    p_as.add_argument(
        "--keep-mark",
        action="store_true",
        help="Keep the active mark file after append (default: delete)",
    )
    add_history(p_as)
    add_active(p_as)
    p_as.set_defaults(func=cmd_append_score)

    p_ar = sub.add_parser(
        "append-review",
        help="Score a review report and append a quality event",
    )
    p_ar.add_argument("--path", type=Path, required=True)
    p_ar.add_argument("--kit-root", type=Path)
    p_ar.add_argument("--ticket")
    p_ar.add_argument("--case-id")
    p_ar.add_argument("--duration-s", type=float)
    add_history(p_ar)
    p_ar.set_defaults(func=cmd_append_review)

    p_raw = sub.add_parser("append", help="Append a manually shaped event")
    p_raw.add_argument("--kind", required=True)
    p_raw.add_argument("--verdict", choices=["PASS", "FAIL", "skip", "error"])
    p_raw.add_argument("--duration-s", type=float)
    p_raw.add_argument("--case-id")
    p_raw.add_argument("--pipeline")
    p_raw.add_argument("--ticket")
    p_raw.add_argument("--note")
    add_history(p_raw)
    p_raw.set_defaults(func=cmd_append_raw)

    p_sum = sub.add_parser("summary", help="Print pass rates and recent events")
    p_sum.add_argument("--last", type=int, default=0, help="Only the last N events (0 = all)")
    add_history(p_sum)
    p_sum.set_defaults(func=cmd_summary)

    p_ex = sub.add_parser("export", help="Export history for graphing (csv/json/jsonl)")
    p_ex.add_argument("--format", choices=["csv", "json", "jsonl"], default="csv")
    p_ex.add_argument("--out", type=Path, help="Output path (default: stdout)")
    add_history(p_ex)
    p_ex.set_defaults(func=cmd_export)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
