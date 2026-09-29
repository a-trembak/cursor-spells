# Partial null-hardening fixture: one caller fixed, sibling still unsafe (N1).

def map_device(row):
    # Nullable association — callers must filter None before grouping.
    return row.get("device")


def list_org_devices_safe(rows):
    # Hardened path: drop null devices before grouping.
    devices = [map_device(r) for r in rows]
    return [d for d in devices if d is not None]


def list_fleet_devices_unsafe(rows):
    # Sibling endpoint still groups nullable keys → NPE / 500 risk remains.
    from collections import defaultdict

    out = defaultdict(list)
    for row in rows:
        device = map_device(row)
        out[device["org_id"]].append(device)  # crashes when device is None
    return out
