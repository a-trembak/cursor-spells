#!/usr/bin/env bash
# Contract: skill-load-budget.py emits JSON with scenarios + totals.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1])
proc = subprocess.run(
    [
        sys.executable,
        str(root / "scripts" / "skill-load-budget.py"),
        "--kit-root",
        str(root),
        "--label",
        "test-contract",
        "--json",
    ],
    check=True,
    capture_output=True,
    text=True,
)
data = json.loads(proc.stdout)
assert "scenarios" in data and isinstance(data["scenarios"], dict), data.keys()
assert "totals" in data
assert data["totals"]["composite_review_turn_strict_est_tokens"] > 0
assert "hitl_choice" in data["scenarios"]
assert "always_on_rules" in data["scenarios"]
print("OK   skill-load-budget JSON shape")
print(f"OK   strict_tokens={data['totals']['composite_review_turn_strict_est_tokens']}")
PY
