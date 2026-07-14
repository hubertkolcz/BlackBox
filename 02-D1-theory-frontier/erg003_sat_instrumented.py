# Instrumented, staged SAT solve of the ERG-003 family0 calibration cell (S=17, [1,1,1,7,7]),
# known NO via elim2 in 43.5s/2,663,409 nodes. Uses conf_budget()+solve_limited()+accum_stats()
# for staged conflict-budget escalation so progress (conflicts/decisions/propagations/restarts,
# and their GROWTH RATE) is logged over time -- not just a single opaque pass/fail. No external
# wall-clock cap: run this under nohup/background with no `timeout` wrapper.
import sys, time, json
sys.path.insert(0, '.')
from erg003_sat import build_cnf
from pysat.solvers import Cadical153

FAMILY = [1, 1, 1, 7, 7]
LOG = "erg003_sat_instrumented.log"
JSONOUT = "erg003_sat_instrumented_progress.json"


def log(msg):
    line = f"[{time.strftime('%Y-%m-%dT%H:%M:%S')}] {msg}"
    print(line, flush=True)
    with open(LOG, "a") as f:
        f.write(line + "\n")


def main():
    open(LOG, "w").close()
    log(f"building CNF for family {FAMILY} (known NO via elim2: 43.5s / 2,663,409 nodes)")
    t0 = time.time()
    cnf, build_s = build_cnf(FAMILY)
    log(f"CNF built: vars={cnf.nv} clauses={len(cnf.clauses)} build_time={build_s:.1f}s")

    solver = Cadical153(bootstrap_with=cnf.clauses)
    history = []
    budget = 200_000  # initial conflict budget; doubles each stage
    stage = 0
    t_start = time.time()
    while True:
        stage += 1
        solver.conf_budget(budget)
        t_stage0 = time.time()
        result = solver.solve_limited(expect_interrupt=True)
        t_stage = time.time() - t_stage0
        stats = solver.accum_stats()
        elapsed = time.time() - t_start
        rec = {"stage": stage, "conf_budget_this_stage": budget, "stage_seconds": round(t_stage, 1),
               "elapsed_seconds": round(elapsed, 1), "result": result, "stats": stats}
        history.append(rec)
        json.dump({"family": FAMILY, "cnf_vars": cnf.nv, "cnf_clauses": len(cnf.clauses),
                   "build_seconds": build_s, "history": history,
                   "elim2_reference": {"status": "NO", "nodes": 2663409, "wall_seconds": 43.5}},
                  open(JSONOUT, "w"), indent=1)
        rate = stats.get("conflicts", 0) / max(elapsed, 1e-6)
        log(f"stage={stage} budget={budget} result={result} elapsed={elapsed/60:.1f}min "
            f"conflicts={stats.get('conflicts')} decisions={stats.get('decisions')} "
            f"propagations={stats.get('propagations')} restarts={stats.get('restarts')} "
            f"conflict_rate={rate:.0f}/s")
        if result is not None:
            log(f"*** DECIDED: {'SAT' if result else 'UNSAT'} after {elapsed/60:.1f} min, "
                f"{stats.get('conflicts')} conflicts ***")
            if result:
                model = solver.get_model()
                import erg003_helper as H
                clique = [v for v in range(H.N) if model[v] > 0]
                ok, bad = H.verify(clique)
                log(f"extracted clique size={len(clique)} independently_verified={ok}")
            break
        budget *= 2
    solver.delete()
    log("DONE")


if __name__ == "__main__":
    main()
