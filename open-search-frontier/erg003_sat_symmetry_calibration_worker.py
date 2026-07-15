# Worker: build_symmetric_cnf(family) + Cadical153 solve for ONE calibration cell.
# Invoked as a subprocess by erg003_sat_symmetry_calibration_runner.py so the parent can
# enforce a hard wall-clock cap via subprocess timeout+kill (pysat's Cadical153 does not
# support solve_limited()/interrupt() -- both raise NotImplementedError for CaDiCaL -- so
# in-process interruption is not available; process-level kill is the only sound option).
import sys, os, json, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import erg003_helper as H
from erg003_sat_symmetry import build_symmetric_cnf
from pysat.solvers import Cadical153


def main():
    family = json.loads(sys.argv[1])
    out_path = sys.argv[2]
    name = sys.argv[3]

    t_start = time.time()
    cnf, top, info = build_symmetric_cnf(family)
    t_build_done = time.time()
    print(f"[{name}] built symmetric CNF: vars={info['vars']} clauses={info['clauses']} "
          f"generators_used={info['generators_used']} generators_skipped={info['generators_skipped']} "
          f"build_seconds={info['build_seconds']:.2f} (total build+aug wall={t_build_done - t_start:.2f}s)",
          flush=True)

    solver = Cadical153(bootstrap_with=cnf.clauses)
    t_solve_start = time.time()
    sat = solver.solve()
    t_solve_done = time.time()
    solve_seconds = t_solve_done - t_solve_start
    total_wall_seconds = t_solve_done - t_start
    print(f"[{name}] SAT-solve: {'SAT' if sat else 'UNSAT'}  solve_wall={solve_seconds:.2f}s  "
          f"total_wall={total_wall_seconds:.2f}s", flush=True)

    result = {
        "name": name,
        "family": family,
        "vars": cnf.nv,
        "clauses": len(cnf.clauses),
        "generators_used": info["generators_used"],
        "generators_skipped": info["generators_skipped"],
        "build_seconds": t_build_done - t_start,
        "solve_seconds": solve_seconds,
        "total_wall_seconds": total_wall_seconds,
        "sat": bool(sat),
        "completed": True,
    }

    if sat:
        model = solver.get_model()
        clique = [v for v in range(H.N) if model[v] > 0]
        result["clique_vertex_indices"] = clique
        result["clique_size"] = len(clique)

    solver.delete()

    with open(out_path, "w") as f:
        json.dump(result, f, indent=1)
    print(f"[{name}] result written to {out_path}", flush=True)


if __name__ == "__main__":
    main()
