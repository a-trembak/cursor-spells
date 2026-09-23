#!/usr/bin/env python3
"""Hard-sensor score for engineer-review response quality (stdlib only).

Scores phase JSON and/or markdown reports against evidence-gate + clarify-options
rules. Kit Evaluation Layer — not a language-model judge, not product-code taste.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


EVIDENCE_FIELDS = ("path", "start_line", "end_line", "snippet", "context")


def kit_root_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def _as_items(phase: dict[str, Any]) -> list[tuple[str, dict[str, Any]]]:
    out: list[tuple[str, dict[str, Any]]] = []
    for key in ("fixed", "clarify"):
        raw = phase.get(key) or []
        if not isinstance(raw, list):
            continue
        for item in raw:
            if isinstance(item, dict):
                out.append((key, item))
    return out


def _options_ok(item: dict[str, Any]) -> bool:
    opts = item.get("options")
    if not isinstance(opts, list) or len(opts) < 2:
        return False
    for opt in opts:
        if isinstance(opt, str) and opt.strip():
            continue
        if isinstance(opt, dict) and opt.get("id") and opt.get("label"):
            continue
        return False
    return True


def _evidence_ok(item: dict[str, Any]) -> bool:
    path = item.get("path")
    if not path:
        # Philosophy-only residual without a file is allowed only outside fixed/clarify;
        # items in fixed/clarify without path fail the gate.
        return False
    try:
        start = int(item.get("start_line"))
        end = int(item.get("end_line"))
    except (TypeError, ValueError):
        return False
    if start < 1 or end < start or (end - start) > 15:
        return False
    snippet = item.get("snippet")
    context = item.get("context")
    if not isinstance(snippet, str) or not snippet.strip():
        return False
    if not isinstance(context, str) or not context.strip():
        return False
    return True


def _clarify_fields_ok(item: dict[str, Any]) -> bool:
    for key in ("question", "what", "when_shows"):
        val = item.get(key)
        if not isinstance(val, str) or not val.strip():
            return False
    return True


def score_phase_json(data: dict[str, Any]) -> dict[str, Any]:
    failures: list[str] = []
    if data.get("skipped") is True:
        return {
            "ok": True,
            "kind": "phase",
            "skipped": True,
            "item_count": 0,
            "evidence_complete_count": 0,
            "evidence_complete_rate": 1.0,
            "clarify_count": 0,
            "clarify_options_complete_count": 0,
            "clarify_options_rate": 1.0,
            "clarify_fields_complete_count": 0,
            "clarify_fields_rate": 1.0,
            "security_checklist_noted": None,
            "failures": [],
        }

    items = _as_items(data)
    evidence_ok = 0
    for bucket, item in items:
        if _evidence_ok(item):
            evidence_ok += 1
        else:
            label = item.get("id") or item.get("summary") or item.get("path") or "?"
            failures.append(f"{bucket}:{label}: missing evidence (path/lines/snippet/context)")

    clarify_items = [item for bucket, item in items if bucket == "clarify"]
    clarify_opts_ok = 0
    clarify_fields_ok = 0
    for item in clarify_items:
        if _options_ok(item):
            clarify_opts_ok += 1
        else:
            label = item.get("id") or item.get("path") or "?"
            failures.append(f"clarify:{label}: options must be 2–3 id+label choices")
        if _clarify_fields_ok(item):
            clarify_fields_ok += 1
        else:
            label = item.get("id") or item.get("path") or "?"
            failures.append(f"clarify:{label}: need full question/what/when_shows for parent handoff")

    evidence_rate = (evidence_ok / len(items)) if items else 1.0
    options_rate = (clarify_opts_ok / len(clarify_items)) if clarify_items else 1.0
    fields_rate = (clarify_fields_ok / len(clarify_items)) if clarify_items else 1.0

    security_noted: bool | None = None
    if data.get("phase") == "security":
        blob = json.dumps(data, ensure_ascii=False).lower()
        security_noted = (
            "security-hardening-checklist" in blob
            or "s1–s10" in blob
            or "s1-s10" in blob
            or '"s1"' in blob
        )
        if items and not security_noted:
            failures.append("security: non-skipped phase with findings must note security-hardening-checklist / S1–S10")

    ok = len(failures) == 0
    return {
        "ok": ok,
        "kind": "phase",
        "skipped": False,
        "item_count": len(items),
        "evidence_complete_count": evidence_ok,
        "evidence_complete_rate": round(evidence_rate, 4),
        "clarify_count": len(clarify_items),
        "clarify_options_complete_count": clarify_opts_ok,
        "clarify_options_rate": round(options_rate, 4),
        "clarify_fields_complete_count": clarify_fields_ok,
        "clarify_fields_rate": round(fields_rate, 4),
        "security_checklist_noted": security_noted,
        "failures": failures,
    }


def score_markdown_report(path: Path, kit_root: Path) -> dict[str, Any]:
    validator = kit_root / "scripts" / "validate-review-report.sh"
    failures: list[str] = []
    markdown_ok = False
    if not validator.is_file():
        failures.append(f"missing validator: {validator}")
    else:
        proc = subprocess.run(
            ["bash", str(validator), str(path)],
            capture_output=True,
            text=True,
        )
        markdown_ok = proc.returncode == 0
        if not markdown_ok:
            detail = (proc.stderr or proc.stdout or "").strip().splitlines()
            failures.append("markdown_validator_failed")
            failures.extend(detail[:8])

    text = path.read_text(encoding="utf-8", errors="replace")
    has_forbidden = bool(
        __import__("re").search(
            r"(?im)^#{1,3}\s*(blockers|блокери|verdict)\b|^Verdict:",
            text,
        )
    )
    if has_forbidden:
        failures.append("forbidden_digest_heading")

    ok = markdown_ok and not has_forbidden and len(failures) == 0
    # If validator failed we already have failures; if forbidden alone, ok false
    if has_forbidden:
        ok = False
    if not markdown_ok:
        ok = False

    return {
        "ok": ok,
        "kind": "markdown",
        "markdown_validator_ok": markdown_ok,
        "forbidden_digest": has_forbidden,
        "evidence_complete_rate": 1.0 if markdown_ok else 0.0,
        "clarify_options_rate": None,
        "security_checklist_noted": None,
        "failures": failures,
    }


def score_path(path: Path, kit_root: Path) -> dict[str, Any]:
    if path.suffix.lower() == ".json":
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            return {"ok": False, "kind": "phase", "failures": ["root must be object"], "item_count": 0}
        result = score_phase_json(data)
    elif path.suffix.lower() in {".md", ".markdown"}:
        result = score_markdown_report(path, kit_root)
    else:
        return {"ok": False, "kind": "unknown", "failures": [f"unsupported suffix: {path.suffix}"], "item_count": 0}
    result["path"] = str(path)
    return result


def score_fixtures(fixtures_dir: Path, kit_root: Path) -> dict[str, Any]:
    pass_dir = fixtures_dir / "pass"
    fail_dir = fixtures_dir / "fail"
    rows: list[dict[str, Any]] = []
    failures: list[str] = []

    for expected_ok, folder in ((True, pass_dir), (False, fail_dir)):
        if not folder.is_dir():
            continue
        for path in sorted(folder.iterdir()):
            if path.suffix.lower() not in {".json", ".md", ".markdown"}:
                continue
            if path.name.startswith("."):
                continue
            result = score_path(path, kit_root)
            actual_ok = bool(result.get("ok"))
            row = {
                "path": str(path.relative_to(fixtures_dir)),
                "expected_ok": expected_ok,
                "actual_ok": actual_ok,
                "match": actual_ok == expected_ok,
                "result": result,
            }
            rows.append(row)
            if not row["match"]:
                failures.append(
                    f"{row['path']}: expected ok={expected_ok} got ok={actual_ok}; "
                    f"{result.get('failures')}"
                )

    evidence_rates = [
        r["result"]["evidence_complete_rate"]
        for r in rows
        if r["expected_ok"] and isinstance(r["result"].get("evidence_complete_rate"), (int, float))
    ]
    options_rates = [
        r["result"]["clarify_options_rate"]
        for r in rows
        if r["expected_ok"]
        and isinstance(r["result"].get("clarify_options_rate"), (int, float))
    ]
    markdown_pass = [
        r
        for r in rows
        if r["expected_ok"] and r["result"].get("kind") == "markdown"
    ]
    markdown_ok_rate = (
        sum(1 for r in markdown_pass if r["result"].get("markdown_validator_ok")) / len(markdown_pass)
        if markdown_pass
        else None
    )

    def avg(vals: list[float]) -> float | None:
        if not vals:
            return None
        return round(sum(vals) / len(vals), 4)

    ok = len(failures) == 0 and len(rows) > 0
    if len(rows) == 0:
        failures.append(f"no fixtures under {fixtures_dir}/pass or fail")

    return {
        "ok": ok,
        "fixture_count": len(rows),
        "fixture_match_count": sum(1 for r in rows if r["match"]),
        "failures": failures,
        "rows": rows,
        "metrics": {
            "review_response_quality": {
                "fixture_pass_rate": round(
                    (sum(1 for r in rows if r["match"]) / len(rows)) if rows else 0.0,
                    4,
                ),
                "evidence_complete_rate_avg": avg(evidence_rates),
                "clarify_options_rate_avg": avg(options_rates),
                "markdown_validator_ok_rate": markdown_ok_rate,
            }
        },
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_one = sub.add_parser("score", help="Score one phase JSON or markdown report")
    p_one.add_argument("path", type=Path)
    p_one.add_argument("--kit-root", type=Path)

    p_fix = sub.add_parser("score-fixtures", help="Score pass/fail fixture directories")
    p_fix.add_argument(
        "--fixtures-dir",
        type=Path,
        default=None,
        help="Default: <kit>/evals/harness/fixtures/review-quality",
    )
    p_fix.add_argument("--kit-root", type=Path)
    p_fix.add_argument("--json", action="store_true")

    args = parser.parse_args(argv)
    kit_root = (args.kit_root or kit_root_from_script()).resolve()

    if args.cmd == "score":
        result = score_path(args.path.resolve(), kit_root)
        json.dump(result, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0 if result.get("ok") else 1

    fixtures = args.fixtures_dir or (kit_root / "evals" / "harness" / "fixtures" / "review-quality")
    fixtures = fixtures.resolve()
    summary = score_fixtures(fixtures, kit_root)
    if args.json:
        # Keep fixture row payloads compact for harness attach
        slim = {
            "ok": summary["ok"],
            "fixture_count": summary["fixture_count"],
            "fixture_match_count": summary["fixture_match_count"],
            "failures": summary["failures"],
            "metrics": summary["metrics"],
        }
        json.dump(slim, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        rq = summary["metrics"]["review_response_quality"]
        print(
            f"review-response-quality: ok={summary['ok']} "
            f"fixtures={summary['fixture_match_count']}/{summary['fixture_count']} "
            f"evidence_avg={rq.get('evidence_complete_rate_avg')} "
            f"clarify_options_avg={rq.get('clarify_options_rate_avg')} "
            f"markdown_ok_rate={rq.get('markdown_validator_ok_rate')}"
        )
        for line in summary["failures"]:
            print(f"FAIL {line}", file=sys.stderr)
    return 0 if summary["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
