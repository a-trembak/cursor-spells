#!/usr/bin/env python3
"""Score skill-profile A/B review runs against miss-class fixtures (stdlib only)."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def kit_root_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def load_cases(kit: Path) -> list[dict[str, Any]]:
    cases_dir = kit / "evals" / "harness" / "skill-profile-ab" / "cases"
    rows = []
    for path in sorted(cases_dir.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        data["_path"] = str(path.relative_to(kit))
        rows.append(data)
    return rows


def score_run(case: dict[str, Any], run: dict[str, Any]) -> dict[str, Any]:
    blob = json.dumps(run, ensure_ascii=False).lower()
    gates = run.get("gates_fired") or []
    if isinstance(gates, str):
        gates = [gates]
    gates_l = [str(g).upper() for g in gates]
    expected = [str(g).upper() for g in case.get("expected_gates", [])]
    gates_hit = [g for g in expected if g in gates_l or g.lower() in blob]
    checklist = str(run.get("checklist_opened") or run.get("checklists_opened") or "")
    if isinstance(run.get("checklists_opened"), list):
        checklist = " ".join(str(x) for x in run["checklists_opened"])
    expected_cl = case.get("expected_checklist", "")
    checklist_ok = expected_cl.replace(".md", "") in checklist.replace(".md", "") or expected_cl.lower() in blob
    must = case.get("must_mention") or []
    mentions_hit = [m for m in must if m.lower() in blob]
    catch = len(gates_hit) == len(expected) and checklist_ok and len(mentions_hit) >= max(1, len(must) // 2)
    return {
        "case_id": case["id"],
        "profile": run.get("profile"),
        "catch": catch,
        "gates_expected": expected,
        "gates_hit": gates_hit,
        "checklist_ok": checklist_ok,
        "mentions_hit": mentions_hit,
        "mentions_expected": must,
        "l2_loaded": bool(run.get("l2_loaded")),
        "notes": run.get("notes"),
    }


def summarize(rows: list[dict[str, Any]]) -> dict[str, Any]:
    by_profile: dict[str, list[dict[str, Any]]] = {}
    for row in rows:
        by_profile.setdefault(str(row.get("profile") or "unknown"), []).append(row)
    profiles = {}
    for name, items in sorted(by_profile.items()):
        caught = sum(1 for i in items if i.get("catch"))
        profiles[name] = {
            "runs": len(items),
            "caught": caught,
            "catch_rate": round(caught / len(items), 4) if items else 0.0,
            "l2_loaded_count": sum(1 for i in items if i.get("l2_loaded")),
        }
    strict = profiles.get("strict", {}).get("catch_rate")
    expert = profiles.get("expert", {}).get("catch_rate")
    verdict = "inconclusive"
    if strict is not None and expert is not None:
        if expert >= strict - 0.01 and expert >= 0.75:
            verdict = "expert_ok"
        elif expert + 0.25 < (strict or 0):
            verdict = "expert_regressed"
        else:
            verdict = "mixed"
    return {"profiles": profiles, "verdict": verdict}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kit-root", type=Path, default=None)
    parser.add_argument("command", choices=["list-cases", "score-dir", "score-files"])
    parser.add_argument("paths", nargs="*", help="run JSON files or a runs directory")
    parser.add_argument("--label", default="ab")
    args = parser.parse_args(argv)
    kit = args.kit_root.resolve() if args.kit_root else kit_root_from_script()
    cases = {c["id"]: c for c in load_cases(kit)}

    if args.command == "list-cases":
        print(json.dumps(list(cases.values()), indent=2))
        return 0

    run_paths: list[Path] = []
    if args.command == "score-dir":
        if not args.paths:
            print("score-dir needs a directory", file=sys.stderr)
            return 2
        d = Path(args.paths[0])
        run_paths = sorted(d.glob("*.json"))
    else:
        run_paths = [Path(p) for p in args.paths]

    scored = []
    for path in run_paths:
        run = json.loads(path.read_text(encoding="utf-8"))
        case_id = run.get("case_id")
        if case_id not in cases:
            print(f"FAIL unknown case_id={case_id} in {path}", file=sys.stderr)
            return 1
        row = score_run(cases[case_id], run)
        row["run_path"] = str(path)
        scored.append(row)

    summary = summarize(scored)
    report = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "label": args.label,
        "results": scored,
        "summary": summary,
    }
    out_dir = kit / "evals" / "harness" / "skill-profile-ab" / "reports"
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{report['generated_at'].replace(':','')}-{args.label}.json"
    # filename safe
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out = out_dir / f"{stamp}-{args.label}.json"
    out.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report["summary"], indent=2))
    print(f"Wrote {out}")
    if summary["verdict"] == "expert_regressed":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
