"""Assemble the consolidated ERG-003 S=17 verdict from per-family records.

Reads erg003_family_results/family_NN.json (canonical records; method field
distinguishes 'elim2'/'elimination' exhaustive decisions from chain-search
PARTIALs) and writes 02-D1-theory-frontier/erg003_verdict.json:
  {omega17exists, familiesExhausted, families, witnesses, totalNodes,
   totalWallHours, remaining, method_notes}
omega17exists: true if any YES; false only if ALL 26 exhausted NO; else null.
"""
import json
import os

import erg003_pentagram_search as ps

HERE = os.path.dirname(os.path.abspath(__file__))
RD = os.path.join(HERE, "erg003_family_results")


def main():
    fams = ps.families(17, cap=8)
    rows = []
    witnesses = []
    total_nodes = 0
    total_wall = 0.0
    n_no = n_yes = n_partial = 0
    for i, vec in enumerate(fams):
        fn = os.path.join(RD, f"family_{i:02d}.json")
        d = json.load(open(fn)) if os.path.exists(fn) else {}
        st = d.get("status", "MISSING")
        method = d.get("method", "chain")
        total_nodes += d.get("nodes", 0)
        total_wall += d.get("wall_seconds", 0)
        cp = d.get("chain_partial") or {}
        total_nodes += cp.get("nodes", 0)
        total_wall += cp.get("wall_seconds", 0)
        if st == "NO":
            n_no += 1
        elif st == "YES":
            n_yes += 1
            witnesses.append(d.get("witness"))
        else:
            n_partial += 1
        rows.append({"idx": i, "family": list(vec), "status": st,
                     "method": method, "nodes": d.get("nodes", 0),
                     "wall_seconds": d.get("wall_seconds", 0)})
    if n_yes > 0:
        exists = True
    elif n_no == len(fams):
        exists = False
    else:
        exists = None
    out = {
        "target": "omega(C9^v3 v C5) >= 17 ?",
        "omega17exists": exists,
        "familiesExhausted": f"{n_no + n_yes}/{len(fams)}",
        "counts": {"NO": n_no, "YES": n_yes, "PARTIAL": n_partial},
        "witnesses": witnesses,
        "totalNodes": total_nodes,
        "totalWallHours": round(total_wall / 3600.0, 3),
        "families": rows,
        "method_notes": [
            "exhaustive decisions by exact two-layer CSP elimination "
            "(erg003_elim2.py / erg003_fam00_eliminate.py), validated by "
            "ELIM2 gates: exact per-family agreement with the chain searcher "
            "on C9^v2 (S=8,9) and C7^v2 (S=9,10) including exhaustive NOs",
            "PARTIAL rows carry chain-search and/or elim2 partial progress; "
            "no 17-clique witness found anywhere",
            "family list completeness: cap 8 = omega(H), proven via Lovasz "
            "theta multiplicativity (theta(C9-bar)^3 = 8.796 < 9)",
        ],
    }
    with open(os.path.join(HERE, "erg003_verdict.json"), "w") as f:
        json.dump(out, f, indent=1)
    print(f"verdict: omega17exists={exists} exhausted={n_no + n_yes}/26 "
          f"nodes={total_nodes} wall={out['totalWallHours']}h")
    for r in rows:
        print(f"  fam {r['idx']:02d} {r['family']}: {r['status']} "
              f"({r['method']})")


if __name__ == "__main__":
    main()
