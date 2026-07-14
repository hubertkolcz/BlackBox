# ERG-003 parallel family sweep -- runs S=17 families concurrently via multiprocessing,
# each worker calling the tested run17(only={i}) per family (writes family_NN.json).
# Pure stdlib; reuses erg003_elim2 verbatim. Called from Wolfram via ExternalEvaluate.
import json, multiprocessing as mp
import erg003_elim2 as e2


def _run_one(args):
    i, maxsec = args
    try:
        e2.run17(only={i}, maxsec=maxsec, cache_fn=None)
        with open(f"erg003_family_results/family_{i:02d}.json") as f:
            r = json.load(f)
        return {"i": i, "status": r.get("status"), "nodes": r.get("nodes"),
                "anchors_done": r.get("anchors_done"), "wall_seconds": r.get("wall_seconds")}
    except Exception as e:
        return {"i": i, "status": "ERROR", "err": repr(e)}


def main(indices, maxsec, nworkers):
    with mp.Pool(nworkers) as pool:
        res = pool.map(_run_one, [(i, maxsec) for i in indices])
    counts = {}
    for r in res:
        counts[r["status"]] = counts.get(r["status"], 0) + 1
    summary = json.dumps({"counts": counts, "results": res})
    with open("erg003_sweep_summary.json", "w") as f:
        f.write(summary)
    return summary
