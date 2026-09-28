#!/usr/bin/env python3
"""Estimate skill/context load budgets for kit pipeline scenarios (stdlib only).

Token estimate: ceil(bytes / 4). This is a harness proxy for prompt size, not a
live Cursor billing meter. Use --label baseline|after for before/after reports.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def kit_root_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def file_bytes(path: Path) -> int:
    if not path.is_file():
        return 0
    return len(path.read_bytes())


def tokens_from_bytes(n: int) -> int:
    return math.ceil(n / 4) if n else 0


def extract_heading_section(text: str, heading: str) -> str:
    """Return markdown from a ### heading through the next ### or ## at same/higher level."""
    pattern = re.compile(rf"^(### {re.escape(heading)}\s*)$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        # try ## level
        pattern2 = re.compile(rf"^(## {re.escape(heading)}\s*)$", re.MULTILINE)
        match = pattern2.search(text)
        if not match:
            return ""
        start = match.start()
        rest = text[match.end() :]
        next_h = re.search(r"^## ", rest, re.MULTILINE)
        end = match.end() + (next_h.start() if next_h else len(rest))
        return text[start:end]
    start = match.start()
    rest = text[match.end() :]
    next_h = re.search(r"^### |^## ", rest, re.MULTILINE)
    end = match.end() + (next_h.start() if next_h else len(rest))
    return text[start:end]


def always_on_rules(kit: Path) -> list[Path]:
    rules = kit / "rules"
    if not rules.is_dir():
        return []
    out: list[Path] = []
    for path in sorted(rules.glob("*.mdc")):
        text = path.read_text(encoding="utf-8", errors="replace")
        if re.search(r"^alwaysApply:\s*true\b", text, re.MULTILINE):
            out.append(path)
    return out


def orch_always_on(kit: Path) -> list[Path]:
    base = kit / "skills" / "engineer-review"
    refs = base / "references"
    return [
        base / "SKILL.md",
        kit / "agents" / "csp-engineer-reviewer.md",
        refs / "phase-protocol.md",
        refs / "review-learn-protocol.md",
        refs / "graphify-protocol.md",
        refs / "skill-map-orch.md",
        refs / "auto-fix-eligibility.md",
    ]


def sum_paths(paths: list[Path]) -> dict[str, Any]:
    files = []
    total = 0
    for path in paths:
        b = file_bytes(path)
        total += b
        files.append(
            {
                "path": str(path),
                "bytes": b,
                "est_tokens": tokens_from_bytes(b),
            }
        )
    return {
        "bytes": total,
        "est_tokens": tokens_from_bytes(total),
        "files": files,
    }


def hitl_loads(kit: Path) -> dict[str, Any]:
    skill = kit / "skills" / "hitl-choice" / "SKILL.md"
    presets = kit / "skills" / "hitl-choice" / "references" / "presets.md"
    skill_text = skill.read_text(encoding="utf-8") if skill.is_file() else ""
    presets_text = presets.read_text(encoding="utf-8") if presets.is_file() else ""

    # Prefer split presets file when present; else extract from SKILL.md
    catalog_source = presets_text if presets_text.strip() else skill_text
    sample_preset = extract_heading_section(catalog_source, "Propose commit")
    if not sample_preset:
        sample_preset = extract_heading_section(catalog_source, "Approve-plan gate")

    # Protocol-only: SKILL without Gate presets section when still inline
    protocol_text = skill_text
    if "## Gate presets" in skill_text and not presets_text.strip():
        protocol_text = skill_text.split("## Gate presets", 1)[0]
    elif presets.is_file():
        protocol_text = skill_text

    full_bytes = file_bytes(skill) + file_bytes(presets)
    protocol_bytes = len(protocol_text.encode("utf-8"))
    one_preset_bytes = protocol_bytes + len(sample_preset.encode("utf-8"))

    return {
        "full_skill_plus_presets": {
            "bytes": full_bytes,
            "est_tokens": tokens_from_bytes(full_bytes),
            "presets_split": presets.is_file(),
        },
        "protocol_plus_one_preset": {
            "bytes": one_preset_bytes,
            "est_tokens": tokens_from_bytes(one_preset_bytes),
            "preset_heading": "Propose commit" if sample_preset else None,
            "preset_bytes": len(sample_preset.encode("utf-8")),
        },
        "savings_vs_full": {
            "bytes": max(0, full_bytes - one_preset_bytes),
            "est_tokens": tokens_from_bytes(max(0, full_bytes - one_preset_bytes)),
        },
    }


def third_party_placeholder_bytes() -> dict[str, int]:
    """Conservative stand-ins when third-party skills are not installed in the kit tree."""
    return {
        "vercel-react-best-practices": 12_000,
        "architecture-review": 8_000,
        "performance-optimization": 8_000,
        "dead-code-eliminator": 6_000,
        "ce-simplify-code": 18_000,
        "database-migration-stack": 20_000,
    }


def phase_logic_scenario(kit: Path, *, load_l2: bool, migration: bool) -> dict[str, Any]:
    refs = kit / "skills" / "engineer-review" / "references"
    paths = [
        kit / "agents" / "csp-review-logic.md",
        refs / "skill-map.md",
        refs / "phase-protocol.md",
        refs / "phase-protocol-detail.md",
    ]
    # L1 on a common trigger pair (interaction + null) as representative review weight
    l1 = [
        refs / "interaction-replay-checklist.md",
        refs / "null-safety-checklist.md",
        refs / "business-logic-tests-checklist.md",
    ]
    paths.extend(l1)
    kit_part = sum_paths(paths)
    placeholders = third_party_placeholder_bytes()
    l2_bytes = 0
    l2_ids: list[str] = []
    if load_l2:
        l2_ids.append("vercel-react-best-practices")
        l2_bytes += placeholders["vercel-react-best-practices"]
        if migration:
            l2_ids.append("database-migration-stack")
            l2_bytes += placeholders["database-migration-stack"]
    total_bytes = kit_part["bytes"] + l2_bytes
    return {
        "load_l2": load_l2,
        "migration": migration,
        "kit": kit_part,
        "l2_placeholder_ids": l2_ids,
        "l2_placeholder_bytes": l2_bytes,
        "l2_placeholder_est_tokens": tokens_from_bytes(l2_bytes),
        "bytes": total_bytes,
        "est_tokens": tokens_from_bytes(total_bytes),
    }


def writer_scenario(kit: Path, *, load_l2: bool) -> dict[str, Any]:
    paths = [
        kit / "skills" / "software-developer" / "SKILL.md",
        kit / "skills" / "software-developer" / "references" / "branch-setup.md",
        kit / "skills" / "code-comments" / "SKILL.md",
        kit / "skills" / "engineer-review" / "references" / "skill-map.md",
        kit / "skills" / "engineer-review" / "references" / "business-logic-tests-checklist.md",
    ]
    kit_part = sum_paths(paths)
    placeholders = third_party_placeholder_bytes()
    l2_bytes = placeholders["vercel-react-best-practices"] if load_l2 else 0
    l2_ids = ["vercel-react-best-practices"] if load_l2 else []
    total = kit_part["bytes"] + l2_bytes
    return {
        "load_l2": load_l2,
        "kit": kit_part,
        "l2_placeholder_ids": l2_ids,
        "l2_placeholder_bytes": l2_bytes,
        "bytes": total,
        "est_tokens": tokens_from_bytes(total),
    }


def tiny_diff_phase_set(*, skip_enabled: bool) -> dict[str, Any]:
    """Count heuristic phases dispatched on a tiny non-risky diff."""
    full = [
        "lint",
        "patterns",
        "deadcode",
        "simplify",
        "logic",
        "architecture",
        "performance",
    ]
    if skip_enabled:
        kept = ["lint", "patterns", "logic"]
        skipped = ["deadcode", "simplify", "architecture", "performance"]
    else:
        kept = list(full)
        skipped = []
    # Rough per-phase kit overhead (agent + protocol detail) — constant proxy
    per_phase_tokens = 2_500
    return {
        "skip_enabled": skip_enabled,
        "phases_run": kept,
        "phases_skipped": skipped,
        "est_phase_dispatch_tokens": len(kept) * per_phase_tokens,
        "est_tokens_saved_vs_full": len(skipped) * per_phase_tokens,
    }


def build_report(kit: Path, label: str) -> dict[str, Any]:
    rules = always_on_rules(kit)
    orch = orch_always_on(kit)
    hitl = hitl_loads(kit)
    presets_split = (kit / "skills" / "hitl-choice" / "references" / "presets.md").is_file()
    profile_doc = "Skill profile" in (kit / "skills" / "engineer-review" / "references" / "skill-map.md").read_text(
        encoding="utf-8", errors="replace"
    )
    tiny_skip_doc = "tiny-diff" in (kit / "skills" / "engineer-review" / "references" / "phase-protocol.md").read_text(
        encoding="utf-8", errors="replace"
    )

    # Optimized lean uses L2 off + lazy hitl + tiny-diff skip when those features exist
    lean_l2 = False if profile_doc else True
    scenarios = {
        "always_on_rules": sum_paths(rules),
        "orchestrator_always_on": sum_paths(orch),
        "hitl_choice": hitl,
        "phase_logic_strict_l2_on": phase_logic_scenario(kit, load_l2=True, migration=False),
        "phase_logic_lean_l2_off": phase_logic_scenario(kit, load_l2=False, migration=False)
        if profile_doc
        else phase_logic_scenario(kit, load_l2=True, migration=False),
        "phase_logic_migration_l2_on": phase_logic_scenario(kit, load_l2=True, migration=True),
        "writer_strict_l2_on": writer_scenario(kit, load_l2=True),
        "writer_lean_l2_off": writer_scenario(kit, load_l2=False)
        if profile_doc
        else writer_scenario(kit, load_l2=True),
        "tiny_diff_phases": tiny_diff_phase_set(skip_enabled=tiny_skip_doc),
    }

    # Composite "one review turn" proxy: orch + rules + logic phase + one hitl gate
    hitl_strict = hitl["full_skill_plus_presets"]["est_tokens"]
    hitl_lean = hitl["protocol_plus_one_preset"]["est_tokens"] if presets_split else hitl_strict
    logic_strict = scenarios["phase_logic_strict_l2_on"]["est_tokens"]
    logic_lean = scenarios["phase_logic_lean_l2_off"]["est_tokens"]
    tiny = scenarios["tiny_diff_phases"]

    composite_strict = (
        scenarios["always_on_rules"]["est_tokens"]
        + scenarios["orchestrator_always_on"]["est_tokens"]
        + logic_strict
        + hitl_strict
        + tiny_diff_phase_set(skip_enabled=False)["est_phase_dispatch_tokens"]
    )
    composite_lean = (
        scenarios["always_on_rules"]["est_tokens"]
        + scenarios["orchestrator_always_on"]["est_tokens"]
        + logic_lean
        + hitl_lean
        + tiny["est_phase_dispatch_tokens"]
    )

    return {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "label": label,
        "kit_root": str(kit),
        "token_estimate_rule": "ceil(bytes/4)",
        "features_detected": {
            "hitl_presets_split": presets_split,
            "skill_profile_documented": profile_doc,
            "tiny_diff_phase_skip_documented": tiny_skip_doc,
        },
        "scenarios": scenarios,
        "totals": {
            "composite_review_turn_strict_est_tokens": composite_strict,
            "composite_review_turn_lean_est_tokens": composite_lean,
            "composite_savings_est_tokens": max(0, composite_strict - composite_lean),
            "composite_savings_ratio": round(
                (composite_strict - composite_lean) / composite_strict, 4
            )
            if composite_strict
            else 0.0,
        },
    }


def write_report(kit: Path, report: dict[str, Any]) -> Path:
    out_dir = kit / "evals" / "harness" / "skill-load"
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    path = out_dir / f"{stamp}-{report['label']}.json"
    path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def print_summary(report: dict[str, Any], path: Path) -> None:
    t = report["totals"]
    f = report["features_detected"]
    print(f"skill-load-budget label={report['label']} → {path}")
    print(
        f"  features: presets_split={f['hitl_presets_split']} "
        f"profile={f['skill_profile_documented']} "
        f"tiny_diff_skip={f['tiny_diff_phase_skip_documented']}"
    )
    print(
        f"  composite strict≈{t['composite_review_turn_strict_est_tokens']} tokens "
        f"lean≈{t['composite_review_turn_lean_est_tokens']} tokens "
        f"savings≈{t['composite_savings_est_tokens']} "
        f"({t['composite_savings_ratio']:.1%})"
    )
    hitl = report["scenarios"]["hitl_choice"]
    print(
        f"  hitl full≈{hitl['full_skill_plus_presets']['est_tokens']} "
        f"one_preset≈{hitl['protocol_plus_one_preset']['est_tokens']}"
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kit-root", type=Path, default=None)
    parser.add_argument("--label", default="snapshot", help="baseline|after|snapshot")
    parser.add_argument("--json", action="store_true", help="print full JSON to stdout")
    args = parser.parse_args(argv)
    kit = args.kit_root.resolve() if args.kit_root else kit_root_from_script()
    report = build_report(kit, args.label)
    path = write_report(kit, report)
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print_summary(report, path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
