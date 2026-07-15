# -*- coding: utf-8 -*-
"""
g9_antibunching_gate.py -- H4' PART A / gate G9: the antibunching (photon-
statistics) gate. Closes the PNR/heralded photon-statistics extension of the
O3 completeness result by a THEOREM, not an assumption.

Context: FRAMEWORK-2026-07-13.md, evening delta, H4' decomposition part (a);
PROPOSITION-O3.md Prop O3-C / Corollary 1 (semantics escape). Companion of
Part B, efficiency_threshold_kcbs.py.

WHAT G9 ADDS (and its provenance -- honesty mandate)
----------------------------------------------------
Prop O3-C proves {C1-C5, G7, G7-CV, G8} complete WITHIN the intensity-emulator
class A_IE: a single unmodified on-off detector fed classical light, fair-
sampled. H4' asks whether A_IE is the maximal classically-emulable class. The
photon-statistics part of that question is closed OUTRIGHT by an established
theorem of quantum optics (Glauber 1963; Mandel-Wolf; Loudon):

    THEOREM (Glauber classical bound). Any classical light field -- i.e. any
    state with a NON-NEGATIVE Glauber-Sudarshan P-representation, P(alpha) >= 0,
    equivalently any classical stochastic intensity I >= 0 -- satisfies the
    second-order coherence bound
                           g2(0) = <:n^2:> / <n>^2 >= 1
    under ANY detection scheme (on-off, PNR, or heralded). Sub-Poissonian /
    antibunched light, g2(0) < 1, is therefore impossible for every classical
    source under every detector.

The scientific contribution here is NOT the theorem (it is textbook physics --
attributed above). It is folding the theorem into the black-box protocol as a
pre-registered GATE: a device that exhibits g2(0) < 1 is certified OUTSIDE the
entire classical-optical-emulator family -- extending Prop O3-C's completeness
from "single on-off detector, fair-sampled" to "ANY classical-light source,
ANY detector". This closes H4' part (a). It does NOT close fair sampling: that
is the separate, irreducible-but-quantified Part B (see efficiency_threshold_
kcbs.py, eta* = 2/sqrt(5)).

THE ONE-LINE CLASSICAL-IMPOSSIBILITY PROOF (g9Verdict)
------------------------------------------------------
Normally-ordered variance is a genuine P-averaged variance:
    <:(Delta n)^2:> = <n(n-1)> - <n>^2
                    = INT P(alpha) (|alpha|^2 - <I>)^2 d^2 alpha   >= 0
whenever P(alpha) >= 0 (a bona-fide probability density). Dividing by <n>^2:
    g2(0) = 1 + <:(Delta n)^2:>/<n>^2 = 1 + Var_P(I)/<I>^2 >= 1.
So g2(0) < 1 <=> normally-ordered variance < 0 <=> P NOT a probability density
<=> the source is non-classical. QED (one line: P >= 0 => Var_P(I) >= 0 =>
g2 >= 1).

SYMBOLIC ANCHORS (proved, printed literally below)
--------------------------------------------------
  (i)   coherent |alpha>  : P(n) Poisson(mu)      -> g2(0) = 1     (boundary)
  (ii)  thermal (nbar)    : P(n) Bose-Einstein    -> g2(0) = 2     (bunched)
  (iii) Fock |1>          : P(1) = 1              -> g2(0) = 0     (antibunched)
  (iv)  classical P >= 0  : any mixture of coherent states -> g2(0) >= 1
        (numeric ILLUSTRATION, not independent evidence: g2_from_intensity
        returns 1 + Var(I)/<I>^2 >= 1 by construction for any real sample, which
        IS the theorem; the 100000-field sweep just exhibits the bound holding.
        The single-photon Fock state is the explicit g2 < 1 witness that the
        classical branch provably cannot produce).

THE GATE (pre-registered decision)
----------------------------------
Input: a photon-number distribution P(n) (n = 0..n_max), OR a sample of a
classical intensity variable I >= 0 (a P-function realized as samples).
Statistic: g2(0) = <n(n-1)>/<n>^2  (number form), or 1 + Var(I)/<I>^2 (P form).
Pre-registered threshold with a one-sided statistical margin eps_g9 for finite
samples (below); decision:
    g2_hat + eps_g9 <  1  ->  CERTIFIED-NONCLASSICAL   (outside every A_cl)
    g2_hat - eps_g9 >= 1  ->  CLASSICAL-COMPATIBLE     (g2 >= 1, forgeable)
    otherwise               ->  INCONCLUSIVE            (tighten statistics)
The asymmetry mirrors the C1-C5 / G8 style: a nonclassical verdict must clear
the whole confidence band below the classical floor g2 = 1.

Run:  python3 g9_antibunching_gate.py     (seconds; numpy + sympy, no cloud/WL)
Exit 0 iff all four anchors pass and the gate's pre-registered matrix holds.
Refs: R. J. Glauber, Phys. Rev. 131, 2766 (1963); L. Mandel & E. Wolf,
Optical Coherence and Quantum Optics (1995), Ch. 10-12; R. Loudon, The Quantum
Theory of Light (2000). In-project anchor for the single-detector on-off
forgeability premise: arXiv:2601.13869 (KBS).
"""

import sys

import numpy as np
import sympy as sp

# ---------------------------------------------------------- pre-registration --
SEED_G9 = 20260713
ALPHA_G9 = 0.01                       # gate confidence budget (separate stream)
G2_FLOOR = 1.0                        # Glauber classical bound
N_MAX_DEFAULT = 200                   # photon-number truncation for gate inputs


# =============================================================== statistics ===
def g2_from_pn(pn):
    """g2(0) = <n(n-1)>/<n>^2 for a photon-number distribution P(n), n=0..len-1.
    Returns np.inf if <n> = 0 (vacuum: g2 undefined)."""
    pn = np.asarray(pn, float)
    pn = pn / pn.sum()
    n = np.arange(len(pn))
    m1 = float((n * pn).sum())
    if m1 <= 0:
        return float("inf")
    m2fac = float((n * (n - 1) * pn).sum())            # <n(n-1)> = <:n^2:>
    return m2fac / m1**2


def g2_from_intensity(I):
    """g2(0) = 1 + Var(I)/<I>^2 from samples of a classical intensity I >= 0
    (a P-function realized as samples). Always >= 1 for real samples -- this is
    the classical branch; used to demonstrate anchor (iv)."""
    I = np.asarray(I, float)
    mI = I.mean()
    if mI <= 0:
        return float("inf")
    return 1.0 + I.var() / mI**2


def eps_g9(n_samples, alpha=ALPHA_G9):
    """One-sided Hoeffding-STYLE margin on g2 for finite photon-record samples.
    HONESTY NOTE: this is a heuristic decision band, NOT a rigorous confidence
    bound. g2 is a ratio of sample moments of n(n-1), so a unit-scale Hoeffding
    inequality does not literally apply; a rigorous gate would need a bound on
    the moment ratio (e.g. delta-method / empirical-Bernstein on <n(n-1)> and
    <n>). The exact-input anchors and the gate matrix (n_samples large) do not
    hinge on the exact band width -- it only sets the INCONCLUSIVE collar around
    the classical floor g2 = 1. n_samples counts detection records."""
    return float(np.sqrt(np.log(2.0 / alpha) / (2.0 * max(n_samples, 1))))


def gate_g9(pn=None, intensity=None, n_samples=None, alpha=ALPHA_G9):
    """Pre-registered G9 decision. Provide EITHER a photon-number distribution
    pn OR classical-intensity samples. n_samples (record count) sets the
    statistical band; if None the input is treated as exact (eps = 0)."""
    if (pn is None) == (intensity is None):
        raise ValueError("provide exactly one of pn / intensity")
    if pn is not None:
        g2 = g2_from_pn(pn)
    else:
        g2 = g2_from_intensity(intensity)
        n_samples = len(intensity) if n_samples is None else n_samples
    eps = 0.0 if n_samples is None else eps_g9(n_samples, alpha)
    if g2 + eps < G2_FLOOR:
        verdict = "CERTIFIED-NONCLASSICAL"
    elif g2 - eps >= G2_FLOOR:
        verdict = "CLASSICAL-COMPATIBLE"
    else:
        verdict = "INCONCLUSIVE"
    return {"g2": g2, "eps": eps, "verdict": verdict,
            "margin_to_floor": G2_FLOOR - g2}


# ============================================================ number states ===
def pn_coherent(mu, n_max=N_MAX_DEFAULT):
    n = np.arange(n_max + 1)
    logp = -mu + n * np.log(mu) - np.array([sp.log(sp.factorial(int(k)))
                                            for k in n], float)
    p = np.exp(logp)
    return p / p.sum()


def pn_thermal(nbar, n_max=N_MAX_DEFAULT):
    n = np.arange(n_max + 1)
    p = nbar**n / (1 + nbar)**(n + 1)
    return p / p.sum()


def pn_fock(k, n_max=N_MAX_DEFAULT):
    p = np.zeros(n_max + 1)
    p[k] = 1.0
    return p


# =============================================================== anchors ======
def symbolic_anchors():
    """Prove (i) coherent g2 = 1 and (ii) thermal g2 = 2 in closed form."""
    n, mu, nb = sp.symbols("n mu nbar", nonnegative=True)
    Pc = sp.exp(-mu) * mu**n / sp.factorial(n)
    m1c = sp.summation(n * Pc, (n, 0, sp.oo))
    m2c = sp.summation(n * (n - 1) * Pc, (n, 0, sp.oo))
    g2_coh = sp.simplify(m2c / m1c**2)

    Pt = nb**n / (1 + nb)**(n + 1)
    m1t = sp.simplify(sp.summation(n * Pt, (n, 0, sp.oo)))
    m2t = sp.simplify(sp.summation(n * (n - 1) * Pt, (n, 0, sp.oo)))
    g2_th = sp.simplify(m2t / m1t**2)
    return g2_coh, g2_th, m1c, m1t


def run_anchors():
    print("=" * 78)
    print("G9 EXACT ANCHORS (sanity first -- abort if any is off)")
    print("=" * 78)
    g2_coh, g2_th, m1c, m1t = symbolic_anchors()
    print(f"  [symbolic] coherent |alpha>: <n> = {m1c},  "
          f"g2(0) = {g2_coh}   (Poissonian boundary)")
    print(f"  [symbolic] thermal (nbar) : <n> = {m1t},  "
          f"g2(0) = {g2_th}   (bunched)")

    checks = []
    checks.append(("coherent g2(0) = 1 (symbolic)", g2_coh == 1, str(g2_coh)))
    checks.append(("thermal  g2(0) = 2 (symbolic)", g2_th == 2, str(g2_th)))

    # numeric cross-checks of the truncated distributions
    g2c_num = g2_from_pn(pn_coherent(3.7))
    g2t_num = g2_from_pn(pn_thermal(2.3))
    g2f_num = g2_from_pn(pn_fock(1))
    checks.append(("coherent g2(0) = 1 (numeric mu=3.7)",
                   abs(g2c_num - 1) < 1e-9, f"{g2c_num:.12f}"))
    checks.append(("thermal  g2(0) = 2 (numeric nbar=2.3)",
                   abs(g2t_num - 2) < 1e-9, f"{g2t_num:.12f}"))
    checks.append(("Fock |1> g2(0) = 0 (antibunched)",
                   abs(g2f_num) < 1e-15, f"{g2f_num:.12f}"))

    # anchor (iv): any classical P >= 0 mixture has g2 >= 1 (mixtures of
    # coherent states = classical light). Draw 100000 random classical fields.
    rng = np.random.default_rng(SEED_G9)
    n_trials, worst = 100_000, np.inf
    for _ in range(n_trials):
        # a random classical intensity distribution (nonneg samples => P >= 0)
        I = rng.gamma(shape=rng.uniform(0.2, 5.0),
                      scale=rng.uniform(0.1, 4.0), size=64)
        worst = min(worst, g2_from_intensity(I))
    checks.append((f"classical P>=0: g2 >= 1 over {n_trials} random fields",
                   worst >= 1.0 - 1e-12, f"min g2 = {worst:.10f}"))

    ok = True
    for name, passed, detail in checks:
        print(f"  [{'PASS' if passed else 'FAIL'}] {name:48s} {detail}")
        ok &= passed
    if not ok:
        print("ANCHOR FAILURE -- aborting.")
        sys.exit(1)
    print(f"  all {len(checks)} anchors pass.")
    return {"g2_coherent": str(g2_coh), "g2_thermal": str(g2_th),
            "g2_fock1": g2f_num, "classical_min_g2": float(worst)}


# ============================================================ gate matrix =====
def run_gate_matrix():
    """Pre-registered pass/fail matrix: which sources G9 certifies non-classical
    and which it (correctly) passes as classical-compatible."""
    print()
    print("=" * 78)
    print("G9 GATE -- PRE-REGISTERED SOURCE MATRIX (n_samples = 1e6 records)")
    print("=" * 78)
    N = 1_000_000
    # single-photon-added thermal / attenuated single photon give g2 in (0,1);
    # here we use clean canonical sources plus a two-Fock antibunched mix.
    p_sps = 0.98 * pn_fock(1) + 0.02 * pn_coherent(0.5)   # realistic SPS
    # NOTE: the coherent state sits EXACTLY on the classical boundary g2 = 1
    # (its P-function is a delta => Var_P(I) = 0). A one-sided finite-sample
    # gate that requires g2 - eps >= 1 therefore returns INCONCLUSIVE at the
    # boundary -- the honest verdict: you cannot statistically certify the
    # extremal classical point as strictly classical. Bunched sources
    # (g2 > 1) clear the band; antibunched (g2 < 1) are certified nonclassical.
    sources = [
        ("coherent |alpha> (mu=2)", pn_coherent(2.0), "INCONCLUSIVE"),
        ("thermal (nbar=1.5)", pn_thermal(1.5), "CLASSICAL-COMPATIBLE"),
        ("coherent+thermal mix", 0.5 * pn_coherent(2.0) + 0.5 * pn_thermal(1.5),
         "CLASSICAL-COMPATIBLE"),
        ("Fock |1> (ideal SPS)", pn_fock(1), "CERTIFIED-NONCLASSICAL"),
        ("realistic SPS (98% |1>)", p_sps, "CERTIFIED-NONCLASSICAL"),
        ("Fock |2>", pn_fock(2), "CERTIFIED-NONCLASSICAL"),
    ]
    print(f"  {'source':30s} {'g2(0)':>12s}  {'verdict':22s} expected")
    ok = True
    rows = []
    for name, pn, expect in sources:
        r = gate_g9(pn=pn, n_samples=N)
        hit = r["verdict"] == expect
        ok &= hit
        rows.append((name, r["g2"], r["verdict"], expect, hit))
        print(f"  {name:30s} {r['g2']:12.8f}  {r['verdict']:22s} "
              f"{expect:22s} [{'OK' if hit else 'MISMATCH'}]")
    if not ok:
        print("GATE MATRIX FAILURE.")
        sys.exit(1)
    print(f"  gate matrix: all {len(sources)} rows as pre-registered.")
    return rows


def main():
    anchors = run_anchors()
    run_gate_matrix()
    print()
    print("=" * 78)
    print("G9 VERDICT (one-line classical-impossibility proof)")
    print("=" * 78)
    print("  P(alpha) >= 0  =>  <:(Delta n)^2:> = INT P (|alpha|^2 - <I>)^2 >= 0")
    print("                 =>  g2(0) = 1 + Var_P(I)/<I>^2 >= 1.")
    print("  Hence g2(0) < 1 is impossible for every classical-light source under")
    print("  every detector; a device with g2(0) < 1 lies OUTSIDE the entire")
    print("  classical-optical-emulator family. This closes H4' part (a) by")
    print("  theorem (Glauber 1963), extending Prop O3-C beyond the single on-off")
    print("  detector to ANY classical source, ANY detection. Fair sampling")
    print("  remains -- see Part B, eta* = 2/sqrt(5).")
    print()
    print(f"  anchors: coherent g2={anchors['g2_coherent']}, "
          f"thermal g2={anchors['g2_thermal']}, "
          f"Fock|1> g2={anchors['g2_fock1']:.1f}, "
          f"classical min g2={anchors['classical_min_g2']:.6f}")
    sys.exit(0)


if __name__ == "__main__":
    main()
