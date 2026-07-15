# ERG-003 S=18 census: does an 18-clique exist in C9vC9vC9vC5 (=> omega>=18 => the
# (3,1) cell ACTIVATES)? Runs the 10 S=18 families in parallel via multiprocessing,
# each via the tested solver. RETURNS the witness for any YES.
#
# CHECKPOINT/RESUME (fixed 2026-07-14): mirrors erg003_elim2.py's run17() pattern -- a
# per-family result file records anchors_done; a rerun reads it back as start_anchor
# instead of always starting at 0, so a rerun does NOT silently discard prior paid-for
# WCS progress. Family results live in RESULT_DIR_S18 (separate from run17()'s S=17
# directory, since family indices are unrelated between S and S+1 censuses).
import json, os, multiprocessing as mp
import erg003_elim2 as e2
import erg003_pentagram_search as ps

HERE = os.path.dirname(os.path.abspath(__file__))
RESULT_DIR_S18 = os.path.join(HERE, "erg003_family_results_s18")


def checkpoint_path(i):
    return os.path.join(RESULT_DIR_S18, f"family_{i:02d}.json")


def load_checkpoint(i):
    fn = checkpoint_path(i)
    if os.path.exists(fn):
        with open(fn) as f:
            return json.load(f)
    return None


def save_checkpoint(i, out):
    os.makedirs(RESULT_DIR_S18, exist_ok=True)
    with open(checkpoint_path(i), "w") as f:
        json.dump(out, f, indent=1)


def migrate_from_detection_summary(summary_path=None):
    """One-time migration: seed checkpoint files from an already-run detection sweep's
    summary JSON (e.g. erg003_s18_detection_summary.json), so a resumed run picks up
    from the REAL anchors_done already paid for on WCS, instead of restarting at 0."""
    summary_path = summary_path or os.path.join(HERE, "erg003_s18_detection_summary.json")
    if not os.path.exists(summary_path):
        return 0
    with open(summary_path) as f:
        summary = json.load(f)
    n = 0
    for r in summary.get("results", []):
        i = r["i"]
        if load_checkpoint(i) is not None:
            continue  # don't clobber a more advanced local checkpoint
        out = {"family": r["family"], "S": 18, "method": "elim2",
               "status": r["status"], "nodes": r["nodes"],
               "anchors_done": r.get("anchors_done", 0), "wall_seconds": r.get("wall_seconds", 0),
               "witness": r.get("witness"), "witness_verified": r.get("witness_verified")}
        save_checkpoint(i, out)
        n += 1
    return n


def _run_one(args):
    i, maxsec = args
    try:
        prev = load_checkpoint(i)
        if prev is not None and prev.get("status") in ("NO", "YES"):
            return {"i": i, "family": prev["family"], "status": prev["status"],
                    "nodes": prev.get("nodes"), "anchors_done": prev.get("anchors_done"),
                    "witness": prev.get("witness"), "witness_verified": prev.get("witness_verified"),
                    "resumed_from_checkpoint": True, "already_terminal": True}
        start_anchor = prev.get("anchors_done", 0) if prev and prev.get("method") == "elim2" else 0
        prev_wall = prev.get("wall_seconds", 0) if prev else 0

        sol = e2.make_solver(9, 3)
        vec = ps.families(18, cap=8)[i]
        import time
        t0 = time.time()
        r = sol.decide(vec, maxsec=maxsec, start_anchor=start_anchor)
        dt = time.time() - t0
        out = e2.verify_and_report(sol, vec, r, 18)
        out["wall_seconds"] = round(dt + prev_wall, 1)
        save_checkpoint(i, out)
        return {"i": i, "family": list(vec), "status": out["status"], "nodes": out["nodes"],
                "anchors_done": out.get("anchors_done"), "wall_seconds": out["wall_seconds"],
                "witness": out.get("witness"), "witness_verified": out.get("witness_verified"),
                "witness_detail": out.get("witness_detail"),
                "resumed_from_checkpoint": start_anchor > 0}
    except Exception as e:
        return {"i": i, "status": "ERROR", "err": repr(e)}


def main(maxsec, nworkers, migrate=True):
    if migrate:
        n = migrate_from_detection_summary()
        if n:
            print(f"[checkpoint] migrated {n} families from detection summary", flush=True)
    fams = ps.families(18, cap=8)
    with mp.Pool(nworkers) as pool:
        res = pool.map(_run_one, [(i, maxsec) for i in range(len(fams))])
    counts = {}
    for r in res:
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    summary = {"S": 18, "n_families": len(fams), "families": [list(f) for f in fams],
               "counts": counts, "results": res}
    with open("erg003_s18_summary.json", "w") as f:
        json.dump(summary, f)
    return json.dumps(summary)
