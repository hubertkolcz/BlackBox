# SAT (CDCL) encoding of the ERG-003 per-family clique-decision question, for direct
# head-to-head comparison against the custom elim2 CSP-elimination solver.
#
# Family (n0,n1,n2,n3,n4) with sum(n)=S asks: does G=C9vC9vC9vC5 have an S-clique with
# exactly n_c vertices in C5-layer c?  Encoding:
#   - one boolean x_v per vertex v of G (3645 vars)
#   - a binary clause (-x_u OR -x_v) for every NON-edge {u,v} of G (forces any satisfying
#     assignment's true-set to be a clique) -- 1,873,530 clauses (= edges of Xbar)
#   - an exact-cardinality constraint sum_{v in layer c} x_v == n_c for c=0..4, via
#     pysat.card sequential-counter encoding
# SAT  = a clique of that exact profile exists (extract witness, independently verify).
# UNSAT = provably no such clique exists (this IS the rigorous non-existence proof --
#         a resolution refutation the solver can in principle emit).
import sys, time, json
sys.path.insert(0, '.')
import erg003_helper as H
from pysat.formula import CNF
from pysat.card import CardEnc, EncType
from pysat.solvers import Cadical153


def build_cnf(family):
    cnf = CNF()
    nv = H.N  # var v+1 <-> vertex v
    # non-edge clauses: for u<v, if NOT adjG(u,v) and u!=v: clause (-u-1,-v-1)
    t0 = time.time()
    for u in range(H.N):
        nonadj_mask = H.FULL & ~H.adj[u] & ~(1 << u)
        v = 0
        m = nonadj_mask >> (u + 1) << (u + 1)  # only v>u to avoid duplicate clauses
        for v in H.bitlist(m):
            if v > u:
                cnf.append([-(u + 1), -(v + 1)])
    layers = {c: [v for v, t in enumerate(H.verts) if t[3] == c] for c in range(5)}
    top = nv
    for c in range(5):
        lits = [v + 1 for v in layers[c]]
        enc = CardEnc.equals(lits=lits, bound=family[c], top_id=top, encoding=EncType.seqcounter)
        cnf.extend(enc.clauses)
        top = max([abs(l) for cl in enc.clauses for l in cl] + [top])
    return cnf, time.time() - t0


def solve_family(name, family, expect=None, time_budget=None):
    cnf, build_s = build_cnf(family)
    print(f"[{name}] family={family}  vars={cnf.nv}  clauses={len(cnf.clauses)}  build={build_s:.1f}s", flush=True)
    solver = Cadical153(bootstrap_with=cnf.clauses)
    t0 = time.time()
    sat = solver.solve()
    dt = time.time() - t0
    print(f"[{name}] SAT-solve: {'SAT' if sat else 'UNSAT'}  wall={dt:.2f}s"
          f"  (cadical stats: {solver.accum_stats() if hasattr(solver,'accum_stats') else 'n/a'})", flush=True)
    result = {"name": name, "family": family, "vars": cnf.nv, "clauses": len(cnf.clauses),
              "build_seconds": build_s, "solve_seconds": dt, "sat": bool(sat)}
    if sat:
        model = solver.get_model()
        clique = [v for v in range(H.N) if model[v] > 0]
        ok, bad = H.verify(clique)
        result["clique_size"] = len(clique)
        result["independently_verified"] = ok
        print(f"[{name}] extracted clique size={len(clique)}  verify={ok}  bad={bad[:2]}", flush=True)
    solver.delete()
    return result


if __name__ == "__main__":
    results = []
    results.append(solve_family("family0_S17_knownNO", [1, 1, 1, 7, 7]))
    results.append(solve_family("family11_S17_knownYES", [1, 3, 5, 5, 3]))
    json.dump(results, open("erg003_sat_calibration.json", "w"), indent=1)
    print("=== CALIBRATION DONE ===")
    for r in results:
        print(r)
