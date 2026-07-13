"""ERG-003: pair-neighborhood clique oracles for H = C9^v3.

fvec_s[u] := (exists s-clique inside N(0) cap N(u)),  s in {4,5,6,7}, u in V.
By translation, "exists s-clique in N(a) cap N(b)" = fvec_s[b (-) a]
(coordinatewise difference mod 9).  Constant on Stab(0)-orbits (35 orbits).

These are exact necessary/sufficient one-vertex-pair projections of the
pentagram pair predicates used by the elimination solver (erg003_elim2.py).
Each orbit test is find-first (YES) or full exhaustion (NO) with the
selftest-validated coloring-bounded enumerator.  Orbits that exceed the
per-orbit budget are recorded UNKNOWN (treated as True by consumers: sound).

Writes erg003_fvec.json: {s: {orbit_rep: true/false/null}, orbit_of: [...]}
Resumable.
"""
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import erg003_pentagram_search as ps
from erg003_fam00_eliminate import stab0_orbits

OUT = os.path.join(HERE, "erg003_fvec.json")
PER_ORBIT_CAP = 120.0
BUDGET = float(sys.argv[1]) if len(sys.argv) > 1 else 540.0


def main():
    N, coords, adj, FULL = ps.build_H(9, 3)
    reps, orbit_of = stab0_orbits(N, coords)
    data = {"orbit_reps": reps, "orbit_of": orbit_of, "tables": {}}
    if os.path.exists(OUT):
        with open(OUT) as f:
            data = json.load(f)
    tables = data["tables"]
    deadline = time.time() + BUDGET
    for s in (7, 6, 5, 4):
        tab = tables.setdefault(str(s), {})
        for rep in reps:
            key = str(rep)
            if key in tab and tab[key] is not None:
                continue
            if time.time() > deadline:
                break
            cand = adj[0] & adj[rep] if rep != 0 else adj[0]
            stats = [0, time.time() + PER_ORBIT_CAP]
            t1 = time.time()
            val = None
            try:
                val = False
                for _ in ps.enum_size_cliques(cand, s, adj, stats):
                    val = True
                    break
            except ps.Deadline:
                val = None  # UNKNOWN
            tab[key] = val
            with open(OUT, "w") as f:
                json.dump(data, f)
            print(f"  s={s} rep={rep} {coords[rep]}: {val} "
                  f"nodes={stats[0]} {time.time()-t1:.2f}s", flush=True)
        ntrue = sum(1 for r in reps if tab.get(str(r)) is True)
        nfalse = sum(1 for r in reps if tab.get(str(r)) is False)
        nunk = len(reps) - ntrue - nfalse
        # vertex-level density
    for s in (7, 6, 5, 4):
        tab = tables.get(str(s), {})
        dens = sum(1 for u in range(N)
                   if tab.get(str(reps[orbit_of[u]])) is not False)
        print(f"[fvec] s={s}: vertices with (possible) s-clique in "
              f"N(0)&N(u): {dens}/{N}", flush=True)


if __name__ == "__main__":
    main()
