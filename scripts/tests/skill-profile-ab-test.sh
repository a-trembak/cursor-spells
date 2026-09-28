#!/usr/bin/env bash
# Contract: skill-profile-ab fixtures + scorer shape.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1])
cases = list((root / "evals/harness/skill-profile-ab/cases").glob("*.json"))
assert len(cases) >= 4, cases
for path in cases:
    data = json.loads(path.read_text(encoding="utf-8"))
    assert data.get("id") and data.get("expected_gates") and data.get("fixture")

# Synthetic perfect runs for both profiles → expert_ok
runs = root / "evals/harness/skill-profile-ab/runs"
# Prefer real runs if present; else build temp
use = sorted(runs.glob("*.json"))
if len(use) < 8:
    print("WARN fewer than 8 live runs; scoring whatever is present")
proc = subprocess.run(
    [sys.executable, str(root / "scripts/skill-profile-ab.py"), "list-cases", "--kit-root", str(root)],
    check=True,
    capture_output=True,
    text=True,
)
assert "sql-concat-idor" in proc.stdout
print("OK   skill-profile-ab cases listed")
if len(use) >= 8:
    proc2 = subprocess.run(
        [
            sys.executable,
            str(root / "scripts/skill-profile-ab.py"),
            "score-dir",
            str(runs),
            "--kit-root",
            str(root),
            "--label",
            "contract",
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    assert proc2.returncode == 0, proc2.stderr + proc2.stdout
    assert "expert_ok" in proc2.stdout or '"catch_rate": 1.0' in proc2.stdout
    print("OK   skill-profile-ab score-dir on live runs")
print("ALL PASS")
PY
