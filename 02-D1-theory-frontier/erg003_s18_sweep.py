# ERG-003 S=18 census: does an 18-clique exist in C9vC9vC9vC5 (=> omega>=18 => the
# (3,1) cell ACTIVATES)? Runs the 10 S=18 families in parallel via multiprocessing,
# each via the tested solver. RETURNS the witness for any YES (unlike the S=17 driver).
import json, multiprocessing as mp
import erg003_elim2 as e2
import erg003_pentagram_search as ps


def _run_one(args):
    i, maxsec = args
    try:
        sol = e2.make_solver(9, 3)
        vec = ps.families(18, cap=8)[i]
        r = sol.decide(vec, maxsec=maxsec, start_anchor=0)
        out = e2.verify_and_report(sol, vec, r, 18)
        return {"i": i, "family": list(vec), "status": out["status"], "nodes": out["nodes"],
                "anchors_done": out.get("anchors_done"),
                "witness": out.get("witness"), "witness_verified": out.get("witness_verified"),
                "witness_detail": out.get("witness_detail")}
    except Exception as e:
        return {"i": i, "status": "ERROR", "err": repr(e)}


def main(maxsec, nworkers):
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
