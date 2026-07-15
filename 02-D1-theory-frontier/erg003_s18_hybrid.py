# ERG-003 S=18 census, HYBRID driver: uses 64 cores (Compute64x128), not 10-16.
#
# The 10 S=18 families split by X-layer size (sX, hence anchor count):
#   CHEAP  = {0,1,2,4,5} sX=2, 386 anchors      -- 1 core each (proven fast enough)
#   MEDIUM = {3,7,8}     sX=3, 37,464 anchors   -- multiple cores each, ranged-split
#   HARD   = {6,9}       sX=4, 1,202,564 anchors -- multiple cores each, ranged-split
#
# CHEAP families use the existing single-threaded checkpoint mechanism (proven,
# migrated from the real 438-credit detection sweep -- erg003_s18_sweep.py).
# MEDIUM/HARD families use the NEW root-range-split parallelism (validated in
# erg003_ranged_selftest.py / erg003_ranged_e2e_selftest.py / erg003_ranged_mp_test.py):
# splitting the anchor search at the top-level recursion branch point across
# multiple worker PROCESSES, each independently exhausting a disjoint contiguous
# index range and reporting a resumable checkpoint. No redundant work (validated
# exact set-equality across nchunks in {1,2,3,5,7} on the real anchor spaces, plus
# real ~4x throughput at 4 concurrent workers -- scaling the SAME proven mechanism
# to more chunks per family is not new logic, just more of it).
#
# Machine: Compute64x128 (64 vCPU, official rate 1970 cr/hr = 32.83 cr/min, ~1.95
# cores per cr/min -- same compute-per-credit as Compute192x384 but a much smaller
# 492.5cr commitment floor vs 1477.5cr, and closer to the concurrency scale already
# validated locally (4 workers) than a 192-way jump would be).
#
# Total worker allocation: 5 (cheap, 1 each) + 29 (medium, ~10/10/9) + 30 (hard, 15/15) = 64.
#
# ------------------------------- OBSERVABILITY -------------------------------
# Designed to run in STAGES (call main(maxsec=<stage length>) repeatedly -- the
# outer WCS submission script loops this, syncing a live dashboard to CloudObject
# between calls, since ExternalEvaluate is blocking and can't interleave with a
# single long call). Each stage:
#  - run_manifest.json: written once (reproducibility card -- machine specs, code
#    fingerprint, family definitions, worker allocation, start time).
#  - erg003_s18_telemetry/worker_*.jsonl: ONE append-only file PER WORKER (never
#    shared across processes -- no write races), one JSON line per stage this
#    worker ran: timestamp, elapsed, nodes this stage, cumulative nodes, position
#    reached, rate. This is the full observable trajectory, not just endpoints.
#  - erg003_s18_dashboard.json: overwritten after every stage by the MAIN process
#    only (after all workers of that stage have returned -- no race), aggregating
#    current status/coverage/rate per family plus overall progress, for live
#    viewing and as the base artifact for write-up.
import json, os, time, datetime, hashlib, platform, multiprocessing as mp
import erg003_elim2 as e2
import erg003_pentagram_search as ps
import erg003_s18_sweep as flat_sweep  # cheap-family checkpoint machinery (proven)

HERE = os.path.dirname(os.path.abspath(__file__))
RESULT_DIR_RANGED = os.path.join(HERE, "erg003_family_results_s18_ranged")
TELEMETRY_DIR = os.path.join(HERE, "erg003_s18_telemetry")
MANIFEST_PATH = os.path.join(HERE, "erg003_s18_run_manifest.json")
DASHBOARD_PATH = os.path.join(HERE, "erg003_s18_dashboard.json")

CHEAP = [0, 1, 2, 4, 5]
MEDIUM = [3, 7, 8]
HARD = [6, 9]
ANCHOR_TOTALS = {0: 386, 1: 386, 2: 386, 4: 386, 5: 386, 3: 37464, 7: 37464, 8: 37464,
                 6: 1202564, 9: 1202564}
# 64-core allocation (Compute64x128): cheap families need only 1 core each (proven
# sufficient at Memory16x128 scale); the freed-up cores go where they matter --
# medium families (~10/10/9) and hard families (15/15), a 5-7x jump in per-family
# parallelism over the prior 16-core hybrid plan (was 2 for medium, 2-3 for hard).
WORKERS_PER_FAMILY = {**{i: 1 for i in CHEAP}, 3: 10, 7: 10, 8: 9, 6: 15, 9: 15}
assert sum(WORKERS_PER_FAMILY.values()) == 64, sum(WORKERS_PER_FAMILY.values())


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def sha256_of(path):
    if not os.path.exists(path):
        return None
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()[:16]


def write_run_manifest():
    if os.path.exists(MANIFEST_PATH):
        return False
    fams = ps.families(18, cap=8)
    manifest = {
        "run_id": now_iso(),
        "target": "omega(C9vC9vC9vC5) >= 18 ? (S=18 census, activation question for the (3,1) cell)",
        "families": {i: list(fams[i]) for i in range(10)},
        "anchor_totals": ANCHOR_TOTALS,
        "worker_allocation": WORKERS_PER_FAMILY,
        "total_workers": sum(WORKERS_PER_FAMILY.values()),
        "machine": {"hostname": platform.node(), "cpu_count_reported": os.cpu_count(),
                    "platform": platform.platform(), "python": platform.python_version()},
        "code_fingerprint": {
            "erg003_elim2.py": sha256_of(os.path.join(HERE, "erg003_elim2.py")),
            "erg003_pentagram_search.py": sha256_of(os.path.join(HERE, "erg003_pentagram_search.py")),
            "erg003_s18_hybrid.py": sha256_of(os.path.join(HERE, "erg003_s18_hybrid.py")),
        },
        "method_notes": [
            "elim2 two-layer CSP-elimination solver (pentagram-layer reduction over H=C9^v3, "
            "729 vertices); anchors = X-layer candidate cliques enumerated via a Tomita "
            "greedy-coloring-bounded backtracker (erg003_pentagram_search.enum_size_cliques).",
            "MEDIUM/HARD families parallelized via root-range-split: the anchor enumerator's "
            "top-level recursion branch is partitioned into disjoint contiguous index ranges "
            "across worker processes -- validated exact set-equality (unit tests vs the "
            "coloring-bound enumerator AND an independent count-only reference) and end-to-end "
            "status agreement against the 3 ground-truth S=17 families (2 NO, 1 YES verified).",
            "Any status=YES witness is independently re-verified against raw G adjacency "
            "(erg003_pentagram_search.verify_G_clique) before being trusted -- never taken on "
            "the solver's own word."
        ],
    }
    os.makedirs(os.path.dirname(MANIFEST_PATH), exist_ok=True)
    with open(MANIFEST_PATH, "w") as f:
        json.dump(manifest, f, indent=1)
    return True


def _worker_telemetry_path(label):
    os.makedirs(TELEMETRY_DIR, exist_ok=True)
    return os.path.join(TELEMETRY_DIR, f"worker_{label}.jsonl")


def _append_telemetry(label, record):
    with open(_worker_telemetry_path(label), "a") as f:
        f.write(json.dumps(record) + "\n")


def chunk_checkpoint_path(i, c):
    return os.path.join(RESULT_DIR_RANGED, f"family_{i:02d}_chunk_{c:02d}.json")


def load_chunk_checkpoint(i, c):
    fn = chunk_checkpoint_path(i, c)
    if os.path.exists(fn):
        with open(fn) as f:
            return json.load(f)
    return None


def save_chunk_checkpoint(i, c, out):
    os.makedirs(RESULT_DIR_RANGED, exist_ok=True)
    with open(chunk_checkpoint_path(i, c), "w") as f:
        json.dump(out, f, indent=1)


CHEAP_RESULT_DIR = os.path.join(HERE, "erg003_family_results_s18")


def checkpoint_bundle():
    """Read EVERY currently-known checkpoint (cheap + ranged) into one JSON-able
    dict -- small (tens of KB), meant to be pushed to durable storage (CloudObject)
    every stage so progress survives the ephemeral remote machine being torn down.
    This is the artifact a LATER job resumes from -- not just the original
    438-credit sweep's checkpoints, but wherever THIS run actually got to."""
    bundle = {"cheap": {}, "ranged": {}, "bundled_at": now_iso()}
    for i in CHEAP:
        fn = os.path.join(CHEAP_RESULT_DIR, f"family_{i:02d}.json")
        if os.path.exists(fn):
            bundle["cheap"][str(i)] = json.load(open(fn))
    for i in (MEDIUM + HARD):
        for c in range(WORKERS_PER_FAMILY[i]):
            cp = load_chunk_checkpoint(i, c)
            if cp is not None:
                bundle["ranged"][f"{i}_{c}"] = cp
    return bundle


def load_checkpoint_bundle(bundle):
    """Inverse of checkpoint_bundle(): write a bundle (e.g. downloaded from a prior
    run's CloudObject) back out to the individual checkpoint file paths, so THIS
    job resumes from it. Never overwrites a checkpoint that's already MORE advanced
    locally (defends against an accidental stale-bundle download clobbering
    same-run progress -- compares nodes/anchors_done, keeps whichever is larger)."""
    n_loaded = 0
    os.makedirs(CHEAP_RESULT_DIR, exist_ok=True)
    for i_str, cp in bundle.get("cheap", {}).items():
        fn = os.path.join(CHEAP_RESULT_DIR, f"family_{int(i_str):02d}.json")
        existing = json.load(open(fn)) if os.path.exists(fn) else None
        if existing is None or cp.get("anchors_done", 0) >= existing.get("anchors_done", 0):
            json.dump(cp, open(fn, "w"), indent=1)
            n_loaded += 1
    os.makedirs(RESULT_DIR_RANGED, exist_ok=True)
    for key, cp in bundle.get("ranged", {}).items():
        i_str, c_str = key.split("_")
        i, c = int(i_str), int(c_str)
        existing = load_chunk_checkpoint(i, c)
        if existing is None or cp.get("nodes", 0) >= existing.get("nodes", 0):
            save_chunk_checkpoint(i, c, cp)
            n_loaded += 1
    return n_loaded


def initial_chunks(i, nworkers):
    """Static partition of family i's root range into nworkers disjoint,
    roughly-equal contiguous chunks."""
    sol = e2.make_solver(9, 3)
    vec = ps.families(18, cap=8)[i]
    order, colornum = ps.greedy_color(sol.adj[0], sol.adj)
    L = len(order)
    base, rem = divmod(L, nworkers)
    chunks = []
    lo = 0
    for c in range(nworkers):
        sz = base + (1 if c < rem else 0)
        hi = lo + sz
        if sz > 0:
            chunks.append((lo, hi))
        lo = hi
    return chunks, order, colornum, vec


def _run_ranged_worker(args):
    i, c, i_lo, i_hi_init, maxsec = args
    label = f"f{i:02d}_c{c:02d}"
    t_stage0 = time.time()
    try:
        prev = load_chunk_checkpoint(i, c)
        if prev is not None and prev.get("status") in ("NO", "YES"):
            return {"i": i, "c": c, **prev, "already_terminal": True}
        i_hi = prev.get("resume_i_hi", i_hi_init) if prev else i_hi_init
        prev_wall = prev.get("wall_seconds", 0) if prev else 0
        prev_nodes = prev.get("nodes", 0) if prev else 0

        sol = e2.make_solver(9, 3)
        vec = ps.families(18, cap=8)[i]
        order, colornum = ps.greedy_color(sol.adj[0], sol.adj)
        t0 = time.time()
        r = sol.decide_ranged(vec, maxsec=maxsec, i_lo=i_lo, i_hi=i_hi, order=order, colornum=colornum)
        dt = time.time() - t0
        nodes_this_stage = r["nodes"]
        out = {"i": i, "c": c, "family": list(vec), "status": r["status"],
               "nodes": nodes_this_stage + prev_nodes, "i_lo": i_lo, "i_hi_orig": i_hi_init,
               "chunk_exhausted": r.get("chunk_exhausted"), "resume_i_hi": r.get("resume_i_hi"),
               "wall_seconds": round(dt + prev_wall, 1)}
        if r["status"] == "YES":
            out["witness"] = r["witness"]
            tup = ps.witness_to_tuples(r["witness"], sol.coords)
            okv, det = ps.verify_G_clique(tup, sol.n, sol.k)
            out["witness_tuples"] = [list(t) for t in tup]
            out["witness_verified"] = okv
            out["witness_detail"] = det
        save_chunk_checkpoint(i, c, out)
        _append_telemetry(label, {
            "ts": now_iso(), "family": i, "chunk": c, "stage_seconds": round(dt, 2),
            "nodes_this_stage": nodes_this_stage, "nodes_cumulative": out["nodes"],
            "i_lo": i_lo, "i_hi_orig": i_hi_init, "i_position_now": r.get("resume_i_hi", i_hi),
            "range_span": i_hi_init - i_lo,
            "rate_nodes_per_sec": round(nodes_this_stage / max(dt, 1e-6), 1),
            "status": r["status"], "chunk_exhausted": r.get("chunk_exhausted")})
        return out
    except Exception as ex:
        _append_telemetry(label, {"ts": now_iso(), "family": i, "chunk": c, "status": "ERROR",
                                   "err": repr(ex), "stage_seconds": round(time.time() - t_stage0, 2)})
        return {"i": i, "c": c, "status": "ERROR", "err": repr(ex)}


def _run_cheap_worker_with_telemetry(args):
    i, maxsec = args
    label = f"cheap_f{i:02d}"
    t0 = time.time()
    r = flat_sweep._run_one(args)
    dt = time.time() - t0
    _append_telemetry(label, {
        "ts": now_iso(), "family": i, "chunk": None, "stage_seconds": round(dt, 2),
        "nodes_this_stage": r.get("nodes"), "anchors_done": r.get("anchors_done"),
        "anchor_total": ANCHOR_TOTALS[i], "status": r.get("status"),
        "rate_anchors_per_min": None})
    return r


def build_dashboard(t_run_start):
    """Read EVERY currently-known checkpoint (cheap + ranged) and aggregate into a
    single live-status snapshot. Safe to call any time -- only reads, and is only
    ever called by the MAIN process after a stage's workers have all returned."""
    fams = ps.families(18, cap=8)
    families_status = {}
    for i in CHEAP:
        fn = os.path.join(HERE, "erg003_family_results_s18", f"family_{i:02d}.json")
        if os.path.exists(fn):
            d = json.load(open(fn))
            total = ANCHOR_TOTALS[i]
            done = d.get("anchors_done", 0)
            families_status[i] = {"family": list(fams[i]), "status": d.get("status"),
                                   "nodes": d.get("nodes"), "coverage_frac": round(done / total, 4),
                                   "anchors_done": done, "anchor_total": total, "n_workers": 1}
    for i in (MEDIUM + HARD):
        chunk_results = []
        for c in range(WORKERS_PER_FAMILY[i]):
            cp = load_chunk_checkpoint(i, c)
            if cp:
                chunk_results.append(cp)
        if not chunk_results:
            continue
        total = ANCHOR_TOTALS[i]
        covered = sum((c.get("i_hi_orig", 0) - c.get("resume_i_hi", c.get("i_lo", 0)))
                       if not c.get("chunk_exhausted") else
                       (c.get("i_hi_orig", 0) - c.get("i_lo", 0))
                       for c in chunk_results)
        any_yes = [c for c in chunk_results if c.get("status") == "YES"]
        if any_yes:
            status = "YES"
        elif all(c.get("chunk_exhausted") for c in chunk_results) and len(chunk_results) == WORKERS_PER_FAMILY[i]:
            status = "NO"
        else:
            status = "PARTIAL"
        families_status[i] = {"family": list(fams[i]), "status": status,
                               "nodes": sum(c.get("nodes", 0) for c in chunk_results),
                               "coverage_frac": round(min(covered / total, 1.0), 4),
                               "n_workers": WORKERS_PER_FAMILY[i], "n_chunks_reported": len(chunk_results),
                               "witness": any_yes[0].get("witness_tuples") if any_yes else None,
                               "witness_verified": any_yes[0].get("witness_verified") if any_yes else None}

    total_nodes = sum(f.get("nodes") or 0 for f in families_status.values())
    overall_status = ("YES" if any(f["status"] == "YES" for f in families_status.values()) else
                       "NO" if all(f["status"] == "NO" for f in families_status.values()) and len(families_status) == 10 else
                       "IN_PROGRESS")
    dashboard = {
        "ts": now_iso(), "elapsed_seconds": round(time.time() - t_run_start, 1),
        "overall_status": overall_status, "total_nodes_all_families": total_nodes,
        "families": families_status,
        "n_families_terminal": sum(1 for f in families_status.values() if f["status"] in ("NO", "YES")),
        "n_families_reporting": len(families_status),
    }
    with open(DASHBOARD_PATH, "w") as f:
        json.dump(dashboard, f, indent=1)
    return dashboard


def main(maxsec, migrate=True):
    t_run_start = time.time()
    wrote_manifest = write_run_manifest()
    if migrate:
        n = flat_sweep.migrate_from_detection_summary()
        if n:
            print(f"[checkpoint] migrated {n} cheap-family checkpoints", flush=True)

    tasks_cheap = [(i, maxsec) for i in CHEAP]
    tasks_ranged = []
    for i in (MEDIUM + HARD):
        nworkers = WORKERS_PER_FAMILY[i]
        chunks, order, colornum, vec = initial_chunks(i, nworkers)
        for c, (lo, hi) in enumerate(chunks):
            tasks_ranged.append((i, c, lo, hi, maxsec))

    print(f"[plan] cheap={len(tasks_cheap)} single-threaded workers, "
          f"ranged={len(tasks_ranged)} chunk workers (medium+hard) "
          f"= {len(tasks_cheap) + len(tasks_ranged)} total  (manifest {'written' if wrote_manifest else 'exists'})",
          flush=True)

    with mp.Pool(sum(WORKERS_PER_FAMILY.values())) as pool:
        r_cheap_async = pool.map_async(_run_cheap_worker_with_telemetry, tasks_cheap)
        r_ranged_async = pool.map_async(_run_ranged_worker, tasks_ranged)
        r_cheap = r_cheap_async.get()
        r_ranged = r_ranged_async.get()

    # aggregate medium/hard families' chunk results into a per-family verdict
    ranged_by_family = {}
    for r in r_ranged:
        ranged_by_family.setdefault(r["i"], []).append(r)
    family_verdicts = []
    for i, chunks in sorted(ranged_by_family.items()):
        yes = [c for c in chunks if c.get("status") == "YES"]
        if yes:
            status = "YES"
        elif all(c.get("chunk_exhausted") for c in chunks):
            status = "NO"
        else:
            status = "PARTIAL"
        total_nodes = sum(c.get("nodes", 0) for c in chunks)
        family_verdicts.append({"i": i, "family": chunks[0].get("family"), "status": status,
                                 "total_nodes": total_nodes, "n_chunks": len(chunks),
                                 "witness": yes[0].get("witness_tuples") if yes else None,
                                 "witness_verified": yes[0].get("witness_verified") if yes else None})

    dashboard = build_dashboard(t_run_start)

    summary = {"S": 18, "cheap_results": r_cheap, "medium_hard_verdicts": family_verdicts,
               "worker_allocation": WORKERS_PER_FAMILY, "dashboard": dashboard}
    with open(os.path.join(HERE, "erg003_s18_hybrid_summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    return json.dumps(summary)


if __name__ == "__main__":
    import sys
    maxsec = float(sys.argv[1]) if len(sys.argv) > 1 else 60
    print(main(maxsec))
