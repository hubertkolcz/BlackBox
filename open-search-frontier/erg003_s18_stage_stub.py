# Lightweight, multiprocessing-FREE stand-in for hy.main(), used only to validate
# the WL-side staged-loop orchestration (persistent ExternalSession, repeated
# calls, dashboard/manifest file read-back, CloudObject sync, loop termination)
# in isolation from the Windows-specific ExternalEvaluate+multiprocessing handle-
# duplication issue seen in LOCAL testing (nested subprocess spawn fails with
# PermissionError/WinError5 on this dev machine specifically). The real
# multiprocessing.Pool path is independently proven on the actual remote WCS
# machine already, by this session's successful 438-credit S=18 detection sweep
# (which used the identical ExternalEvaluate["Python", "...mp.Pool..."] pattern).
import json, os, time, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
STAGE_COUNTER_PATH = os.path.join(HERE, "erg003_s18_STUB_stage_counter.json")


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def main(maxsec):
    time.sleep(min(maxsec, 2))  # simulate a bit of work, capped so tests are fast
    n = 0
    if os.path.exists(STAGE_COUNTER_PATH):
        n = json.load(open(STAGE_COUNTER_PATH)).get("n", 0)
    n += 1
    json.dump({"n": n}, open(STAGE_COUNTER_PATH, "w"))

    manifest_path = os.path.join(HERE, "erg003_s18_run_manifest.json")
    if not os.path.exists(manifest_path):
        json.dump({"run_id": now_iso(), "note": "STUB manifest for orchestration test"},
                   open(manifest_path, "w"))

    overall_status = "NO" if n >= 5 else "IN_PROGRESS"  # force termination after 5 stages
    dashboard = {"ts": now_iso(), "stage": n, "overall_status": overall_status,
                 "note": "STUB dashboard -- validates WL orchestration only, not real search"}
    json.dump(dashboard, open(os.path.join(HERE, "erg003_s18_dashboard.json"), "w"))
    return json.dumps({"stage": n, "overall_status": overall_status})


def checkpoint_bundle():
    """STUB: mirrors the real hy.checkpoint_bundle() interface so the WL-side
    bundle export/resume logic can be tested without multiprocessing."""
    n = json.load(open(STAGE_COUNTER_PATH)).get("n", 0) if os.path.exists(STAGE_COUNTER_PATH) else 0
    return {"cheap": {"0": {"anchors_done": n * 7, "status": "PARTIAL"}}, "ranged": {},
            "bundled_at": now_iso(), "stub_stage_at_bundle_time": n}


def load_checkpoint_bundle(bundle):
    """STUB: writes the stage counter forward to match a resumed bundle's implied
    progress, so a 'second run' picks up where the bundle left off (mirrors the
    real anti-regression behavior: never go backwards)."""
    implied_n = bundle.get("stub_stage_at_bundle_time", 0)
    current_n = 0
    if os.path.exists(STAGE_COUNTER_PATH):
        current_n = json.load(open(STAGE_COUNTER_PATH)).get("n", 0)
    new_n = max(implied_n, current_n)
    json.dump({"n": new_n}, open(STAGE_COUNTER_PATH, "w"))
    return 1 if new_n > current_n else 0
