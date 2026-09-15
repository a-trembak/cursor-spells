#!/usr/bin/env python3
"""Inventory kit harness health (stdlib only). Orientation — does not advance gates."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

CONTEXT_BUDGET_SKILLS = (
    "tech-spec",
    "implementation-critic",
    "engineer-review",
    "system-design",
)

DEFAULT_TOP_N = 10

WIRED_RE = re.compile(r"`([a-z0-9]+(?:-[a-z0-9]+)*)`")
RETIRED_LINE_RE = re.compile(
    r"\|\s*`([a-z0-9]+(?:-[a-z0-9]+)*)`\s*\|[^|]*\b[Rr]etired\b",
    re.MULTILINE,
)


def kit_root_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def count_bytes_lines(path: Path) -> dict[str, int]:
    raw = path.read_bytes()
    text = raw.decode("utf-8", errors="replace")
    return {"bytes": len(raw), "lines": text.count("\n") + (0 if text.endswith("\n") or not text else 1)}


def dir_bytes_lines(root: Path) -> dict[str, int]:
    total_b = 0
    total_l = 0
    if not root.is_dir():
        return {"bytes": 0, "lines": 0}
    for path in sorted(root.rglob("*")):
        if path.is_file():
            stats = count_bytes_lines(path)
            total_b += stats["bytes"]
            total_l += stats["lines"]
    return {"bytes": total_b, "lines": total_l}


def list_named_dirs(parent: Path) -> list[str]:
    if not parent.is_dir():
        return []
    return sorted(p.name for p in parent.iterdir() if p.is_dir() and not p.name.startswith("."))


def list_md_stems(parent: Path, suffix: str = ".md") -> list[str]:
    if not parent.is_dir():
        return []
    return sorted(p.stem for p in parent.glob(f"*{suffix}") if p.is_file())


def load_trajectory_cases(kit_root: Path) -> list[dict[str, Any]]:
    cases_dir = kit_root / "evals" / "trajectories" / "cases"
    out: list[dict[str, Any]] = []
    if not cases_dir.is_dir():
        return out
    for path in sorted(cases_dir.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if not isinstance(data, dict):
            continue
        case_id = data.get("id") or path.stem
        out.append(
            {
                "id": case_id,
                "status": data.get("status", "unknown"),
                "pipeline": data.get("pipeline"),
                "end_to_end": data.get("end_to_end"),
                "path": str(path.relative_to(kit_root)),
            }
        )
    return out


def wiring_matrix(kit_root: Path, cases: list[dict[str, Any]]) -> list[dict[str, str]]:
    skill_path = kit_root / "skills" / "trajectory-score" / "SKILL.md"
    text = skill_path.read_text(encoding="utf-8") if skill_path.is_file() else ""
    retired_ids = {m.group(1) for m in RETIRED_LINE_RE.finditer(text)}
    mentioned = set(WIRED_RE.findall(text))
    rows: list[dict[str, str]] = []
    for case in cases:
        if case.get("status") != "active":
            continue
        case_id = str(case["id"])
        if case_id in retired_ids:
            state = "retired"
        elif case_id in mentioned:
            state = "wired"
        else:
            state = "unwired"
        rows.append({"id": case_id, "wiring": state})
    return rows


def context_proxies(kit_root: Path, top_n: int) -> dict[str, Any]:
    rules: list[dict[str, Any]] = []
    rules_dir = kit_root / "rules"
    if rules_dir.is_dir():
        for path in sorted(rules_dir.glob("*.mdc")):
            stats = count_bytes_lines(path)
            rules.append({"path": str(path.relative_to(kit_root)), **stats})

    agents_md: dict[str, Any] | None = None
    agents_path = kit_root / "AGENTS.md"
    if agents_path.is_file():
        agents_md = {"path": "AGENTS.md", **count_bytes_lines(agents_path)}

    skill_sizes: list[dict[str, Any]] = []
    skills_dir = kit_root / "skills"
    if skills_dir.is_dir():
        for skill_dir in sorted(p for p in skills_dir.iterdir() if p.is_dir()):
            skill_md = skill_dir / "SKILL.md"
            if not skill_md.is_file():
                continue
            skill_stats = count_bytes_lines(skill_md)
            refs = dir_bytes_lines(skill_dir / "references")
            total_b = skill_stats["bytes"] + refs["bytes"]
            total_l = skill_stats["lines"] + refs["lines"]
            skill_sizes.append(
                {
                    "skill": skill_dir.name,
                    "skill_md": {"path": str(skill_md.relative_to(kit_root)), **skill_stats},
                    "references": refs,
                    "total_bytes": total_b,
                    "total_lines": total_l,
                }
            )
    skill_sizes.sort(key=lambda row: row["total_bytes"], reverse=True)
    return {
        "rules": rules,
        "agents_md": agents_md,
        "top_skills": skill_sizes[:top_n],
        "top_n": top_n,
    }


def context_budget_flags(kit_root: Path) -> dict[str, bool]:
    flags: dict[str, bool] = {}
    for name in CONTEXT_BUDGET_SKILLS:
        path = kit_root / "skills" / name / "SKILL.md"
        text = path.read_text(encoding="utf-8") if path.is_file() else ""
        # Presence of an explicit context / budget section heading or phrase.
        has = bool(
            re.search(
                r"(?im)^(#{1,3}\s+.*\bcontext\b.*\bbudget\b|#{1,3}\s+.*\bbudget\b.*\bcontext\b|"
                r".*\bcontext budget\b|\bContext budget\b)",
                text,
            )
        )
        flags[name] = has
    return flags


def find_latest_bench_report(kit_root: Path) -> Path | None:
    reports = kit_root / "evals" / "harness" / "reports"
    if not reports.is_dir():
        return None
    candidates = sorted(
        (p for p in reports.glob("*.json") if p.is_file()),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    return candidates[0] if candidates else None


def load_bench_report(path: Path | None) -> dict[str, Any] | None:
    if path is None or not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    if not isinstance(data, dict):
        return None
    return data


def build_inventory(kit_root: Path, top_n: int, bench_path: Path | None) -> dict[str, Any]:
    cases = load_trajectory_cases(kit_root)
    resolved_bench = bench_path
    if resolved_bench is None:
        resolved_bench = find_latest_bench_report(kit_root)
    bench = load_bench_report(resolved_bench)
    return {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "kit_root": str(kit_root),
        "inventory": {
            "skills": list_named_dirs(kit_root / "skills"),
            "commands": list_md_stems(kit_root / "commands"),
            "agents": list_md_stems(kit_root / "agents"),
            "rules": list_md_stems(kit_root / "rules", suffix=".mdc"),
            "trajectory_cases": cases,
            "trajectory_active_count": sum(1 for c in cases if c.get("status") == "active"),
            "trajectory_draft_count": sum(1 for c in cases if c.get("status") == "draft"),
        },
        "wiring": wiring_matrix(kit_root, cases),
        "context_proxies": context_proxies(kit_root, top_n),
        "context_budget": context_budget_flags(kit_root),
        "bench_report_path": str(resolved_bench.relative_to(kit_root))
        if resolved_bench and resolved_bench.is_file() and resolved_bench.is_relative_to(kit_root)
        else (str(resolved_bench) if resolved_bench else None),
        "bench": bench,
    }


def format_human(data: dict[str, Any]) -> str:
    lines: list[str] = []
    inv = data["inventory"]
    lines.append("Harness health (orientation only — does not advance gates)")
    lines.append(f"generated_at={data['generated_at']}")
    lines.append(
        f"skills={len(inv['skills'])} commands={len(inv['commands'])} "
        f"agents={len(inv['agents'])} rules={len(inv['rules'])}"
    )
    lines.append(
        f"trajectory_cases active={inv['trajectory_active_count']} "
        f"draft={inv['trajectory_draft_count']}"
    )
    lines.append("")
    lines.append("Wiring matrix (active cases vs skills/trajectory-score/SKILL.md)")
    for row in data["wiring"]:
        lines.append(f"  {row['id']}: {row['wiring']}")
    lines.append("")
    lines.append("Context proxies")
    for rule in data["context_proxies"]["rules"]:
        lines.append(f"  {rule['path']}: {rule['bytes']} bytes / {rule['lines']} lines")
    agents_md = data["context_proxies"].get("agents_md")
    if agents_md:
        lines.append(f"  {agents_md['path']}: {agents_md['bytes']} bytes / {agents_md['lines']} lines")
    lines.append(f"  top skills (n={data['context_proxies']['top_n']})")
    for skill in data["context_proxies"]["top_skills"]:
        lines.append(
            f"    {skill['skill']}: {skill['total_bytes']} bytes / {skill['total_lines']} lines "
            f"(SKILL.md {skill['skill_md']['bytes']}+refs {skill['references']['bytes']})"
        )
    lines.append("")
    lines.append("Context budget flags")
    for name, present in data["context_budget"].items():
        lines.append(f"  {name}: {'present' if present else 'missing'}")
    lines.append("")
    if data.get("bench_report_path"):
        lines.append(f"Bench report: {data['bench_report_path']}")
        bench = data.get("bench") or {}
        lines.append(
            f"  ok={bench.get('ok')} tests={bench.get('test_count')} "
            f"failed={bench.get('failed_count')} duration_s={bench.get('duration_s')}"
        )
        metrics = bench.get("metrics") or {}
        quality = metrics.get("quality") or {}
        speed = metrics.get("speed") or {}
        if quality:
            lines.append(
                f"  quality: pass_rate={quality.get('pass_rate')} "
                f"contract_pass_rate={quality.get('contract_pass_rate')} "
                f"trajectory_validate={quality.get('trajectory_validate')} "
                f"trajectory_score_fixtures={quality.get('trajectory_score_fixtures')}"
            )
        if speed:
            lines.append(
                f"  speed: total_s={speed.get('total_duration_s')} "
                f"p50_s={speed.get('p50_duration_s')} "
                f"p95_s={speed.get('p95_duration_s')} "
                f"max_s={speed.get('max_duration_s')}"
            )
            slowest = speed.get("slowest") or []
            if slowest:
                top = ", ".join(
                    f"{row.get('name')}={row.get('duration_s')}s" for row in slowest[:3]
                )
                lines.append(f"  slowest: {top}")
        review_q = metrics.get("review_response_quality") or {}
        if review_q:
            lines.append(
                f"  review_response_quality: ok={review_q.get('ok')} "
                f"fixture_pass_rate={review_q.get('fixture_pass_rate')} "
                f"evidence_avg={review_q.get('evidence_complete_rate_avg')} "
                f"clarify_options_avg={review_q.get('clarify_options_rate_avg')}"
            )
    else:
        lines.append("Bench report: none (run bash scripts/harness-bench.sh)")
    lines.append("")
    lines.append(
        "Cursor context ring (IDE) vs kit proxies: the Cursor UI ring is live model "
        "context for the open chat. Kit proxies above are static file sizes only — "
        "use them to spot oversized skills/rules before a change, not as a substitute "
        "for the ring."
    )
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kit-root", type=Path, help="Kit root (default: parent of scripts/)")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of human text")
    parser.add_argument(
        "--bench-report",
        type=Path,
        help="Attach this bench JSON (default: newest under evals/harness/reports/)",
    )
    parser.add_argument("--top-n", type=int, default=DEFAULT_TOP_N, help="Top-N skills by size")
    args = parser.parse_args(argv)

    kit_root = (args.kit_root or kit_root_from_script()).resolve()
    data = build_inventory(kit_root, args.top_n, args.bench_report.resolve() if args.bench_report else None)
    if args.json:
        json.dump(data, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        sys.stdout.write(format_human(data))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
