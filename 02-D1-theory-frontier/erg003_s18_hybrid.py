# ERG-003 S=18 census, HYBRID driver: uses ALL 16 WCS cores instead of 10.
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
# set-equality + real ~4x throughput at 4 workers).
#
# Total worker allocation: 5 (cheap, 1 each) + 6 (medium, 2 each) + 5 (hard, 3+2) = 16.
import json, os, time, multiprocessing as mp
import erg003_elim2 as e2
import erg003_pentagram_search as ps
import erg003_s18_sweep as flat_sweep  # cheap-family checkpoint machinery (proven)

HERE = os.path.dirname(os.path.abspath(__file__))
RESULT_DIR_RANGED = os.path.join(HERE, "erg003_family_results_s18_ranged")

CHEAP = [0, 1, 2, 4, 5]
MEDIUM = [3, 7, 8]
HARD = [6, 9]
WORKERS_PER_FAMILY = {**{i: 1 for i in CHEAP}, **{i: 2 for i in MEDIUM}, 6: 3, 9: 2}
assert sum(WORKERS_PER_FAMILY.values()) == 16, sum(WORKERS_PER_FAMILY.values())


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


def initial_chunks(i, nworkers):
    """Static partition of family i's root range into nworkers disjoint,
    roughly-equal contiguous chunks (or reuse an existing checkpoint's own
    i_lo/i_hi if a chunk was already started -- resumes in place)."""
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
        out = {"i": i, "c": c, "family": list(vec), "status": r["status"],
               "nodes": r["nodes"] + prev_nodes, "i_lo": i_lo, "i_hi_orig": i_hi_init,
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
        return out
    except Exception as ex:
        return {"i": i, "c": c, "status": "ERROR", "err": repr(ex)}


def main(maxsec, migrate=True):
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
          f"= {len(tasks_cheap) + len(tasks_ranged)} total", flush=True)

    with mp.Pool(16) as pool:
        r_cheap_async = pool.map_async(flat_sweep._run_one, tasks_cheap)
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

    summary = {"S": 18, "cheap_results": r_cheap, "medium_hard_verdicts": family_verdicts,
               "worker_allocation": WORKERS_PER_FAMILY}
    with open(os.path.join(HERE, "erg003_s18_hybrid_summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    return json.dumps(summary)


if __name__ == "__main__":
    import sys
    maxsec = float(sys.argv[1]) if len(sys.argv) > 1 else 60
    print(main(maxsec))
