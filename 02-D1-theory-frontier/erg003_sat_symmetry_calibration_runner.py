# Runner: launches erg003_sat_symmetry_calibration_worker.py as a subprocess per family,
# enforcing a HARD wall-clock cap (default 1200s) via subprocess timeout+kill. If the cap
# is hit, reports NO VERDICT honestly (does not extend the cap unilaterally, per task
# instructions). Records precise wall-clock time to verdict (or to cap) for each cell.
import sys, os, json, time, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
CAP_SECONDS = 1200

CELLS = [
    ("family0_S17_knownNO", [1, 1, 1, 7, 7]),
    ("family11_S17_knownYES", [1, 3, 5, 5, 3]),
]


def run_cell(name, family):
    out_path = os.path.join(HERE, f"erg003_sat_symmetry_result_{name}.json")
    if os.path.exists(out_path):
        os.remove(out_path)
    cmd = [sys.executable, os.path.join(HERE, "erg003_sat_symmetry_calibration_worker.py"),
           json.dumps(family), out_path, name]
    print(f"=== starting {name} family={family} cap={CAP_SECONDS}s ===", flush=True)
    t0 = time.time()
    try:
        proc = subprocess.run(cmd, cwd=HERE, timeout=CAP_SECONDS,
                               capture_output=True, text=True)
        elapsed = time.time() - t0
        print(proc.stdout, flush=True)
        if proc.stderr:
            print("STDERR:", proc.stderr, flush=True)
        if os.path.exists(out_path):
            with open(out_path) as f:
                result = json.load(f)
            result["wallclock_to_verdict_seconds"] = elapsed
            result["hit_cap"] = False
            print(f"=== {name}: VERDICT={'SAT' if result['sat'] else 'UNSAT'} "
                  f"wallclock_to_verdict={elapsed:.2f}s ===", flush=True)
        else:
            result = {"name": name, "family": family, "completed": False,
                      "sat": None, "hit_cap": False,
                      "wallclock_to_verdict_seconds": elapsed,
                      "note": "process exited without writing result file "
                              f"(returncode={proc.returncode})"}
            print(f"=== {name}: NO VERDICT (process exited abnormally, "
                  f"returncode={proc.returncode}) after {elapsed:.2f}s ===", flush=True)
    except subprocess.TimeoutExpired as e:
        elapsed = time.time() - t0
        # subprocess.run with timeout already killed the child process tree on timeout.
        result = {"name": name, "family": family, "completed": False,
                  "sat": None, "hit_cap": True,
                  "wallclock_to_verdict_seconds": elapsed,
                  "cap_seconds": CAP_SECONDS,
                  "note": f"NO VERDICT: exceeded {CAP_SECONDS}s hard wall-clock cap"}
        if e.stdout:
            print(e.stdout.decode(errors="replace") if isinstance(e.stdout, bytes) else e.stdout, flush=True)
        print(f"=== {name}: NO VERDICT -- hit {CAP_SECONDS}s cap (elapsed={elapsed:.2f}s) ===", flush=True)
    return result


def main():
    all_results = []
    for name, family in CELLS:
        r = run_cell(name, family)
        all_results.append(r)
        summary_path = os.path.join(HERE, "erg003_sat_symmetry_calibration_summary.json")
        with open(summary_path, "w") as f:
            json.dump(all_results, f, indent=1)
    print("=" * 70, flush=True)
    print("FINAL SUMMARY", flush=True)
    for r in all_results:
        verdict = "NO VERDICT" if r.get("sat") is None else ("SAT" if r["sat"] else "UNSAT")
        print(f"  {r['name']}: family={r['family']} verdict={verdict} "
              f"wallclock_to_verdict={r['wallclock_to_verdict_seconds']:.2f}s "
              f"hit_cap={r.get('hit_cap')}", flush=True)


if __name__ == "__main__":
    main()
