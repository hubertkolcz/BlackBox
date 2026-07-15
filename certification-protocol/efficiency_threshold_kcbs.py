# -*- coding: utf-8 -*-
"""
efficiency_threshold_kcbs.py -- H4' PART B: the KCBS detection-efficiency
threshold eta*. The irreducible-but-quantified part of the H4' decomposition.

Context: FRAMEWORK-2026-07-13.md, evening delta, H4' part (b); PROPOSITION-O3.md
Prop O3-C (fair-sampling assumption A2/A1). Companion of Part A,
g9_antibunching_gate.py.

WHAT THIS COMPUTES (and the honesty mandate)
--------------------------------------------
G9 (Part A) closes the photon-statistics part of H4' by theorem. The FAIR-
SAMPLING part is provably NOT removable by statistics alone: it is the
contextuality analogue of the Bell-test detection loophole (Pearle 1970;
Garg & Mermin, PRD 35, 3831 (1987); Eberhard, PRA 47, R747 (1993); for the
KS/contextuality setting, Larsson, PRA 57, R3145 (1998)). The honest endpoint
is therefore NOT an elimination of the assumption but a COMPUTED critical
detection efficiency eta*: below eta* a fair-sampling (detection-loophole)
noncontextual model MATCHES (indeed can exceed) the quantum KCBS value
S = sqrt(5) -- it is not claimed to reproduce the full context-by-context
statistics, only the KCBS sum S, which is what the inequality tests; above eta*
no such model reaches sqrt(5), and Prop O3-C's completeness extends to
non-fair-sampling adversaries.
Detection efficiency remains a physical assumption -- exactly as in every Bell
and contextuality experiment ever performed.

THE KCBS SCENARIO (as in mbqc_blackbox_test.py)
-----------------------------------------------
Five yes-no observables A_0..A_4 (rank-1 projectors) on the pentagon; contexts
= the 5 edges (A_i, A_{i+1} mod 5); adjacent observables are EXCLUSIVE
(A_i A_{i+1} = 0, the (1,1) event is structurally absent). KCBS operator
                          S = sum_{i=0}^{4} <A_i>.
NCHV bound  : S <= 2      (= independence number alpha(C_5) = 2: a noncontextual
                           deterministic assignment can set at most 2 of the 5
                           pairwise-nonadjacent projectors to 1).
Quantum max : S = sqrt(5) = 2.2360679...   (the pentagram/KCBS value theta(C_5)).

THE THRESHOLD (derived two independent ways below; both give the same exact eta*)
--------------------------------------------------------------------------------
(1) Efficiency-degraded quantum value meets the NCHV bound. With per-observable
    detection efficiency eta and the standard no-click assignment (no click =
    no photon = projector value 0), each <A_i> is diluted by eta, so
                          S_Q(eta) = eta * sqrt(5).
    S_Q(eta) drops to the NCHV bound 2 exactly at
                          eta* = 2 / sqrt(5).

(2) Detection-loophole NCHV model, fair-sampled (the physically honest test).
    Hidden variable lambda assigns a noncontextual deterministic value
    v_i(lambda) in {0,1} (an independent set of C_5, so sum_i v_i <= 2) AND a
    detection flag d_i(lambda) in {0,1} with marginal E[d_i] = eta (matched to
    the quantum device's efficiency; detection may depend on lambda -- this IS
    the loophole). Fair sampling reports <A_i>_fair = E[v_i d_i]/E[d_i]. The
    adversary maximizes S_fair = sum_i E[v_i d_i]/eta subject to sum_i v_i <= 2:
    report every 1 (set d_i = 1 whenever v_i = 1) and pad with 0-outcome
    detections up to eta. This gives (exact LP optimum, verified below)
                          max S_fair(eta) = 2 / eta      (for eta >= 2/5),
    which reaches the quantum value sqrt(5) at 2/eta = sqrt(5), i.e. again
                          eta* = 2 / sqrt(5).
    Below eta* the loophole model fakes (indeed exceeds) the quantum statistics;
    above eta* no noncontextual detection-loophole model reaches sqrt(5).

GENERALIZATION (odd n-cycle, printed as a sanity table)
-------------------------------------------------------
For the odd n-cycle KS scenario the NCHV bound is (n-1)/2 and the quantum value
of sum <A_i> is  Q_n = n cos(pi/n) / (1 + cos(pi/n)); by the same argument
                          eta*_n = ((n-1)/2) / Q_n.
n = 5 recovers eta* = 2/sqrt(5) (Q_5 = sqrt(5)).

ANCHOR SANITY (checked below)
-----------------------------
  eta = 1        -> S = sqrt(5) > 2 : full violation (contextuality certified).
  eta -> low     -> loophole model reaches 2/eta -> infinity >> sqrt(5) : the
                    NCHV detection-loophole model trivially covers the quantum
                    value (fair sampling collapses the test).
  eta* = 2/sqrt(5) = 0.8944... in (0,1), the boundary above which Prop O3-C's
  completeness extends to non-fair-sampling adversaries.

Run:  python3 efficiency_threshold_kcbs.py   (seconds; numpy/scipy/sympy).
Exit 0 iff both derivations agree with eta* = 2/sqrt(5) and all anchors pass.
Refs: Larsson PRA 57 R3145 (1998); Garg-Mermin PRD 35 3831 (1987); Eberhard
PRA 47 R747 (1993); KCBS: Klyachko-Can-Binicioglu-Shumovsky PRL 101 020403
(2008); Araujo-Quintino-Budroni-Cunha-Cabello PRA 88 022118 (2013).
"""

import sys
from itertools import product

import numpy as np
import sympy as sp
from scipy.optimize import linprog

SQRT5 = float(sp.sqrt(5))
NCHV_BOUND = 2.0
ETA_STAR = 2.0 / SQRT5                     # = 2 sqrt(5)/5 = 0.8944271909999...


# ----------------------------------------------------- C_5 independent sets --
def c5_independent_sets():
    """All independent sets of the pentagon C_5 (vertices 0..4, edges i~i+1)."""
    def indep(S):
        return all(((i + 1) % 5) not in S for i in S)
    sets = []
    for m in range(32):
        S = frozenset(k for k in range(5) if (m >> k) & 1)
        if indep(S):
            sets.append(S)
    return sets


IND_SETS = c5_independent_sets()           # 11 of them (1 + 5 + 5)


def max_fair_sampled_S(eta):
    """Exact LP: max over detection-loophole NCHV models of the fair-sampled
    KCBS value at per-observable efficiency eta. Variables x[S,d] = probability
    of (independent-set assignment S, detection pattern d in {0,1}^5).
    Constraints: probabilities sum to 1; marginal detection E[d_i] = eta for all
    i. Objective: max sum_i E[v_i d_i]; return that / eta = S_fair."""
    dets = list(product([0, 1], repeat=5))
    types = [(S, d) for S in IND_SETS for d in dets]
    nv = len(types)
    c = np.zeros(nv)                                   # minimize -objective
    for k, (S, d) in enumerate(types):
        c[k] = -sum(1 for i in range(5) if (i in S) and d[i])
    A_eq = [np.ones(nv)]
    b_eq = [1.0]
    for i in range(5):
        A_eq.append(np.array([1.0 if types[k][1][i] else 0.0
                              for k in range(nv)]))
        b_eq.append(eta)
    res = linprog(c, A_eq=np.array(A_eq), b_eq=np.array(b_eq),
                  bounds=[(0, 1)] * nv, method="highs")
    if res.status != 0:
        raise RuntimeError(f"fair-sampling LP failed: {res.message}")
    return -res.fun / eta


def odd_cycle_threshold(n):
    """eta*_n = ((n-1)/2) / Q_n, Q_n = n cos(pi/n)/(1+cos(pi/n)) (odd n-cycle)."""
    c = sp.cos(sp.pi / n)
    Qn = n * c / (1 + c)
    return sp.Rational(n - 1, 2) / Qn, Qn


# --------------------------------------------------------------- run / anchors --
def run():
    print("=" * 78)
    print("KCBS DETECTION-EFFICIENCY THRESHOLD  eta*  (H4' Part B)")
    print("=" * 78)
    print(f"  NCHV bound        S <= {NCHV_BOUND:.0f}   (alpha(C_5) = 2)")
    print(f"  quantum value     S  = sqrt(5) = {SQRT5:.10f}   (theta(C_5))")
    print()

    # --- derivation (1): degraded quantum value meets NCHV bound
    eta = sp.symbols("eta", positive=True)
    sol = sp.solve(sp.Eq(eta * sp.sqrt(5), 2), eta)
    eta_star_sym = sol[0]
    print("  Derivation (1) -- efficiency-degraded quantum value = NCHV bound:")
    print(f"    S_Q(eta) = eta*sqrt(5) = 2  =>  eta* = {eta_star_sym} "
          f"= {float(eta_star_sym):.10f}")

    # --- derivation (2): fair-sampled detection-loophole LP, max S = 2/eta
    print()
    print("  Derivation (2) -- fair-sampled detection-loophole NCHV LP "
          f"(over {len(IND_SETS)} independent sets of C_5):")
    print(f"    {'eta':>10s} {'max S_fair':>14s} {'2/eta':>12s} {'match':>7s}")
    lp_ok = True
    for e in [0.40, 0.50, ETA_STAR, 0.90, 1.00]:
        s = max_fair_sampled_S(e)
        match = abs(s - 2.0 / e) < 1e-7
        lp_ok &= match
        print(f"    {e:10.6f} {s:14.8f} {2.0/e:12.8f} "
              f"{'OK' if match else 'X':>7s}")
    s_at_star = max_fair_sampled_S(ETA_STAR)
    print(f"    at eta* = {ETA_STAR:.8f}: max S_fair = {s_at_star:.8f} "
          f"= sqrt(5) = {SQRT5:.8f}  "
          f"[{'OK' if abs(s_at_star - SQRT5) < 1e-7 else 'X'}]")

    # --- anchors
    print()
    print("  ANCHOR SANITY:")
    checks = []
    checks.append(("eta = 1 gives full violation sqrt(5) > 2",
                   SQRT5 > NCHV_BOUND, f"S = {SQRT5:.6f}"))
    checks.append(("eta -> low collapses to NCHV (loophole S = 2/eta >> sqrt5)",
                   max_fair_sampled_S(0.45) > SQRT5,
                   f"S_fair(0.45) = {max_fair_sampled_S(0.45):.4f}"))
    checks.append(("eta* in (0,1)", 0.0 < ETA_STAR < 1.0, f"{ETA_STAR:.10f}"))
    checks.append(("two derivations agree",
                   abs(float(eta_star_sym) - ETA_STAR) < 1e-12
                   and abs(s_at_star - SQRT5) < 1e-7, "eta* = 2/sqrt(5)"))
    checks.append(("fair-sampling LP = 2/eta on the grid", lp_ok, "verified"))
    ok = True
    for name, passed, detail in checks:
        print(f"    [{'PASS' if passed else 'FAIL'}] {name:52s} {detail}")
        ok &= passed

    # --- odd n-cycle generalization table
    print()
    print("  ODD n-CYCLE GENERALIZATION  eta*_n = ((n-1)/2) / Q_n:")
    print(f"    {'n':>4s} {'NCHV':>6s} {'Q_n':>16s} {'eta*_n':>16s}")
    for n in (5, 7, 9, 11):
        etn, Qn = odd_cycle_threshold(n)
        print(f"    {n:4d} {(n-1)//2:6d} {float(Qn):16.10f} "
              f"{float(etn):16.10f}")
    etn5, _ = odd_cycle_threshold(5)
    checks_n = abs(float(etn5) - ETA_STAR) < 1e-12
    print(f"    n=5 closed form = {sp.nsimplify(etn5)}  "
          f"[{'matches 2/sqrt(5)' if checks_n else 'MISMATCH'}]")
    ok &= checks_n

    print()
    print("=" * 78)
    print("etaStar VERDICT")
    print("=" * 78)
    print(f"  eta* = 2/sqrt(5) = 2*sqrt(5)/5 = {ETA_STAR:.10f}")
    print("  Below eta* a fair-sampling (detection-loophole) noncontextual model")
    print("  matches the quantum KCBS value S = sqrt(5) (the loophole reaches")
    print("  S_fair = 2/eta >= sqrt(5)); above eta* it cannot, so Prop O3-C's")
    print("  completeness extends to non-fair-sampling adversaries.")
    print("  Fair sampling is NOT eliminated -- detection efficiency remains a")
    print("  physical assumption, exactly as in every Bell/contextuality test.")
    print("  H4' is thereby REDUCED: Part A (G9) closes photon statistics by")
    print("  theorem; Part B quantifies the residual fair-sampling boundary at")
    print("  eta* = 2/sqrt(5). H4' is reduced, not fully closed.")

    if not ok:
        print("THRESHOLD DERIVATION FAILURE.")
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    run()
