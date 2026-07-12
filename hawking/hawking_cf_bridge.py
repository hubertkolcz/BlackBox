# -*- coding: utf-8 -*-
"""
hawking_cf_bridge.py -- first-pass computational bridge between this
project's contextual-fraction (CF) machinery and the CHSH-Bell-inequality
treatment of analogue-Hawking-radiation pair correlations. Written for the
"classical emulatability of Hawking-radiation dynamics" gap identified in
the project's research description (the one named application with zero
prior work as of 10 July 2026). Companion note: NOTES-hawking.md.

THE QUESTION
------------
Can the quantum/classical boundary for a Hawking-pair correlation
measurement be phrased as an LP/graph-invariant certificate the way the
contextual fraction CF is phrased for the KCBS pentagon (CF(C5, quantum)
= 2 sqrt(5) - 4 exactly)? See NOTES-hawking.md Sec. 3 for the full
discussion; the short answer this script operationalizes is: yes, but
through CHSH, not through KCBS-C5.

SCOPE, PRECISELY
----------------
KCBS/C5 contextuality (this repo's atomic block) is a SINGLE-SYSTEM,
MULTI-CONTEXT scenario: one wire, compatible sequential measurements
(kcbs_circuit.wl Sec. 4: "CHSH needs two wires because it is a two-party
test; KCBS deliberately does not"). Bell/CHSH nonlocality is a TWO-PARTY,
FACTORIZED-SETTING scenario. This repo's own machinery already places
both under one graph-invariant umbrella (kcbs_circuit.wl: "CHSH is the
same graph formalism with a different graph (8 events ... theta = 2 +
Sqrt[2])"; QUANTUM_CONTEXTUALITY.md Sec. 5: "CHSH exclusivity graph =
Ci(8;1,4), theta = 2+sqrt(2) (same SDP machinery covers nonlocality)"),
and, independently, an EXACT Abramsky-Brandenburger contextual-fraction
computation of CHSH itself already exists on branch
claude/signaling-taxonomy (signaling_taxonomy.py / NOTES-signaling.md):
    CF(CHSH Tsirelson)  = sqrt(2) - 1  ~= 0.4142135624   (exact)
    CF(CHSH PR box)     = 1                              (exact)
Hawking-pair correlations, as actually studied in the literature
(Steinhauer's BEC program; Ciliberto, Emig, Pavloff, Isoard, arXiv:
2404.16497), are BIPARTITE (Hawking mode vs. partner mode -- sometimes
tripartite, with a third "companion" mode that is a peculiarity of the
Lorentz-violating analogue platform, absent in a real black hole). CHSH,
not KCBS-C5, is therefore the structurally correct point of contact. This
script reuses the EXISTING CF-of-CHSH machinery (rebuilt here from
scratch, in the same LP style as mbqc_blackbox_test.py, and cross-checked
against the pinned values above) and asks: where does a literature-
reported Hawking-pair CHSH value land on this repo's own CF scale?

THE LITERATURE INPUT (external, cited, NOT recomputed here)
-------------------------------------------------------------
Ciliberto, Emig, Pavloff, Isoard, "Violation of Bell inequalities in an
analogue black hole," arXiv:2404.16497 (2024). They compute a discretized
(GKMR-pseudospin) CHSH Bell operator on the Gaussian 2/3-mode state of a
1D BEC analogue-black-hole horizon (Bogoliubov theory), for the
"waterfall" flow configuration matching the downstream Mach number m_d =
2.9 of the Technion 2019 experiment (de Nova, Golubkov, Kolobov,
Steinhauer, "Observation of thermal Hawking radiation at the Hawking
temperature in an analogue black hole," Nature 569, 688 (2019); arXiv:
1809.00913). Their Fig. 3/4: at zero temperature the maximal Hawking-
partner CHSH parameter is
    B^(0|2)_max = 2.25
(local-realist bound 2; Cirel'son/Tsirelson bound 2 sqrt(2) =
2.8284...; the companion-partner pair B^(1|2) peaks at exactly 2, i.e.
no violation, at this same m_d). Their Fig. 4 caption identifies
2 sqrt(2) itself as the bipartite ceiling, reached only in the idealized
EPR limit (upstream Mach number m_u -> 0 or 1). Finite temperature kills
the bipartite signal quickly: by T = 0.2 g n_u the CHSH parameters "no
longer show evidences of violation of Bell inequality" over most of the
configuration range (their Fig. 5) -- reported here as a qualitative
fact from the paper, NOT re-derived (no temperature-dependent scattering
calculation is performed in this script).

THE BRIDGE (mine -- a construction, not a claim of either cited paper)
-------------------------------------------------------------------------
A CHSH value S in [2, 4] is a single linear functional of a probability
table; it does not by itself determine the table. This script uses the
standard ISOTROPIC/unbiased-marginals table (three settings pairs at
correlation +S/4, one at -S/4 -- the same convention as chsh_corr_model()
in signaling_taxonomy.py) as the canonical representative and computes
its EXACT contextual fraction with the same Abramsky-Brandenburger LP
used throughout this repo (mbqc_blackbox_test.py's ncf_lp/cf_of pattern),
here on the native (2,2,2,2) Bell scenario: 4 contexts (one per settings
pair (x,y)), 4 outcome sections per context, 16 deterministic local
(noncontextual) assignments. This is a TRANSCRIPTION of a reported
expectation value into this repo's CF units -- it is not a re-derivation
of the Bogoliubov scattering physics behind S = 2.25, and it is not a
finite-sample black-box test: no such Bell measurement has been performed
on a real analogue-Hawking device, so there is nothing here resembling
mbqc_blackbox_test.py's sampling / certificate-stack / verdict layer.
That layer is exactly what is NOT yet possible to build for this
application; see NOTES-hawking.md Sec. 5 (open questions).

SANITY-FIRST RULE: the exact anchors -- CF at the local bound, at
Tsirelson (cross-checked against the independently-computed
signaling_taxonomy.py value), at the PR-box/algebraic bound, and this
repo's own pre-existing KCBS-pentagon CF (2 sqrt(5) - 4) recomputed here
as a self-consistency check of this script's OWN LP harness -- are all
verified before the literature point is evaluated. The script ABORTS if
any anchor is off.

Run:  python3 hawking_cf_bridge.py
Deps: numpy, scipy (linprog/HiGHS).
"""

import json
import sys
from itertools import product

import numpy as np
from scipy.optimize import linprog

SQRT2 = np.sqrt(2.0)
SQRT5 = np.sqrt(5.0)
CF_KCBS_EXACT = 2 * SQRT5 - 4                # this repo's KCBS-pentagon CF anchor
CF_CHSH_TSIRELSON_EXACT = SQRT2 - 1          # signaling_taxonomy.py / NOTES-signaling.md anchor
S_HAWKING_LIT = 2.25                         # Ciliberto et al 2024, Fig. 3/4, m_d = 2.9, T = 0

SECTIONS = [(0, 0), (0, 1), (1, 0), (1, 1)]  # (Alice outcome, Bob outcome)


# --------------------------------------------------------- CHSH scenario ---
def chsh_incidence():
    """4 contexts (x,y in {0,1}, Alice/Bob settings) x 4 sections, 16
    deterministic local assignments (a(0),a(1),b(0),b(1)) each in {0,1}:
    the standard Abramsky-Brandenburger scenario for the (2,2,2,2) Bell
    test. Combinatorially isomorphic to the 4-cycle relabeling used by
    cycle_incidence(4)/chsh_corr_model in signaling_taxonomy.py (branch
    claude/signaling-taxonomy); verified independently here via the exact
    anchors below rather than assumed."""
    ctx = [(x, y) for x in range(2) for y in range(2)]
    glob = list(product([0, 1], repeat=4))       # (a0, a1, b0, b1)
    M = np.zeros((16, 16))
    for c, (x, y) in enumerate(ctx):
        for s, (a, b) in enumerate(SECTIONS):
            for g, t in enumerate(glob):
                ax, by = t[x], t[2 + y]
                if (ax, by) == (a, b):
                    M[4 * c + s, g] = 1.0
    return M, ctx, glob


M_CHSH, CHSH_CTX, CHSH_GLOBALS = chsh_incidence()


def chsh_isotropic_table(S):
    """Unbiased-marginals table: 3 settings pairs at correlation +S/4, the
    (x,y)=(1,1) pair at -S/4 (standard CHSH sign convention, S = E00 + E01
    + E10 - E11); S in [2,4] <-> correlation magnitude c = S/4 in
    [0.5, 1]. Matches chsh_corr_model([c,c,c,-c]) in signaling_taxonomy.py."""
    c = S / 4.0
    e = np.zeros(16)
    for k, (x, y) in enumerate(CHSH_CTX):
        corr = -c if (x, y) == (1, 1) else c
        e[4 * k:4 * k + 4] = [(1 + corr) / 4, (1 - corr) / 4,
                               (1 - corr) / 4, (1 + corr) / 4]
    return e


def ncf_lp(e):
    """Noncontextual fraction: max 1.d s.t. M d <= e, d >= 0 (exact AB LP,
    same form as mbqc_blackbox_test.py's ncf_lp)."""
    res = linprog(-np.ones(16), A_ub=M_CHSH, b_ub=e, method="highs")
    if res.status != 0:
        raise RuntimeError(f"CHSH NCF LP failed: {res.message}")
    return -res.fun


def cf_of(e):
    return 1.0 - ncf_lp(e)


# --------------------------------------------- KCBS pentagon cross-check ---
def kcbs_incidence():
    """5-context / 32-assignment pentagon incidence, structurally identical
    to mbqc_blackbox_test.py's incidence_matrix(); rebuilt here (not
    imported -- this worktree does not share that module) purely as an
    independent self-consistency anchor for THIS script's own LP harness,
    so the CHSH result below is checked by a harness proven, in the same
    run, to reproduce this repo's headline KCBS number."""
    ctx = [(i, (i + 1) % 5) for i in range(5)]
    glob = list(product([0, 1], repeat=5))
    M = np.zeros((20, 32))
    for c, (i, j) in enumerate(ctx):
        for s, sec in enumerate(SECTIONS):
            for g, t in enumerate(glob):
                if (t[i], t[j]) == sec:
                    M[4 * c + s, g] = 1.0
    return M


M_KCBS = kcbs_incidence()


def kcbs_quantum_table():
    """Exact KCBS pentagram Born-rule table (cone-axis state, V=1), same
    numbers as mbqc_blackbox_test.py's table_quantum(1.0)."""
    q = 1 / SQRT5
    p00 = 1 - 2 / SQRT5
    e = np.zeros(20)
    for c in range(5):
        e[4 * c:4 * c + 4] = [p00, q, q, 0.0]
    return e


def cf_kcbs(e):
    res = linprog(-np.ones(32), A_ub=M_KCBS, b_ub=e, method="highs")
    if res.status != 0:
        raise RuntimeError(f"KCBS NCF LP failed: {res.message}")
    return 1.0 - (-res.fun)


# ------------------------------------------------------------ exact anchors --
def run_exact_anchors():
    print("=" * 78)
    print("EXACT ANCHORS (sanity first -- abort if any is off)")
    print("=" * 78)
    checks = []

    cf_local = cf_of(chsh_isotropic_table(2.0))
    checks.append(("CF(CHSH local/classical bound, S=2) = 0",
                    abs(cf_local) < 1e-7, f"{cf_local:.10f}"))

    cf_ts = cf_of(chsh_isotropic_table(2 * SQRT2))
    checks.append(("CF(CHSH Tsirelson, S=2sqrt2) = sqrt(2)-1  [signaling_taxonomy.py anchor]",
                    abs(cf_ts - CF_CHSH_TSIRELSON_EXACT) < 1e-6,
                    f"{cf_ts:.10f} vs {CF_CHSH_TSIRELSON_EXACT:.10f}"))

    cf_pr = cf_of(chsh_isotropic_table(4.0))
    checks.append(("CF(CHSH PR box / algebraic max, S=4) = 1",
                    abs(cf_pr - 1.0) < 1e-7, f"{cf_pr:.10f}"))

    cf_k = cf_kcbs(kcbs_quantum_table())
    checks.append(("CF(KCBS quantum pentagon) = 2 sqrt(5) - 4  [this repo's own anchor]",
                    abs(cf_k - CF_KCBS_EXACT) < 1e-7,
                    f"{cf_k:.10f} vs {CF_KCBS_EXACT:.10f}"))

    # monotonicity sanity: CF must be nondecreasing in S over [2,4]
    grid = np.linspace(2.0, 4.0, 21)
    cfs = [cf_of(chsh_isotropic_table(S)) for S in grid]
    mono = all(cfs[i + 1] >= cfs[i] - 1e-9 for i in range(len(cfs) - 1))
    checks.append(("CF(S) monotone nondecreasing on [2,4] (21-pt grid)",
                    mono, f"min step = {min(np.diff(cfs)):.2e}"))

    # closed-form check: does CF(S) = (S-2)/2 on this isotropic family?
    lin_ok = all(abs(cfs[i] - (grid[i] - 2) / 2) < 1e-6 for i in range(len(grid)))
    checks.append(("CF(S) matches closed form (S-2)/2 on the isotropic family (21-pt grid)",
                    lin_ok, f"max dev = {max(abs(cfs[i]-(grid[i]-2)/2) for i in range(len(grid))):.2e}"))

    ok = True
    for name, passed, detail in checks:
        print(f"  [{'PASS' if passed else 'FAIL'}] {name}")
        print(f"        {detail}")
        ok &= passed
    if not ok:
        print("ANCHOR FAILURE -- aborting before evaluating the literature point.")
        sys.exit(1)
    print(f"  all {len(checks)} anchors pass.")
    return {"cf_local": cf_local, "cf_tsirelson": cf_ts, "cf_pr": cf_pr, "cf_kcbs": cf_k}


# ------------------------------------------------------- literature point --
def evaluate_literature_point():
    print()
    print("=" * 78)
    print("LITERATURE POINT (external input, NOT an anchor -- see caveats below)")
    print("=" * 78)
    cf_lit = cf_of(chsh_isotropic_table(S_HAWKING_LIT))
    cf_epr_limit = cf_of(chsh_isotropic_table(2 * SQRT2))  # same as Tsirelson anchor
    print(f"  S_hawking (Ciliberto et al 2024, waterfall m_d=2.9, T=0, "
          f"Hawking/partner pair) = {S_HAWKING_LIT}")
    print(f"    -> CF_hawking (isotropic-table transcription)     = {cf_lit:.6f}")
    print(f"  S_hawking, idealized EPR limit (m_u -> 0 or 1, same paper's Fig. 4)"
          f" = 2 sqrt(2) = {2*SQRT2:.6f}")
    print(f"    -> CF (same ceiling as the generic CHSH Tsirelson anchor) "
          f"= {cf_epr_limit:.6f}")
    print()
    print("  Comparison table (this repo's CF units):")
    print(f"    CF(KCBS quantum pentagon, the atomic block)   = {CF_KCBS_EXACT:.6f}")
    print(f"    CF(CHSH Tsirelson bound, generic)             = {CF_CHSH_TSIRELSON_EXACT:.6f}")
    print(f"    CF(Hawking/partner pair, Ciliberto et al 2024) = {cf_lit:.6f}")
    print(f"    CF(CHSH PR box / algebraic max, generic)      = 1.000000")
    print()
    print("  Reading: taken at face value and transcribed through the isotropic-table")
    print("  bridge above, the reported zero-temperature Hawking/partner CHSH violation")
    print(f"  sits at CF = {cf_lit:.4f}, about {100*cf_lit/CF_CHSH_TSIRELSON_EXACT:.0f}% of the way")
    print("  from the classical bound to the generic CHSH/Tsirelson ceiling, and about")
    print(f"  {100*cf_lit/CF_KCBS_EXACT:.0f}% of the KCBS pentagon's own CF -- a modest but nonzero")
    print("  certificate at T=0, BEFORE the reported temperature fragility (Fig. 5 of")
    print("  the same paper: no certified violation by T = 0.2 g n_u) is taken into account.")
    return {"cf_lit": cf_lit, "cf_epr_limit": cf_epr_limit}


def main():
    anchors = run_exact_anchors()
    lit = evaluate_literature_point()

    print()
    print("=" * 78)
    print("SCOPE AND CAVEATS (read before citing any number above)")
    print("=" * 78)
    caveats = [
        "S = 2.25 is copied from Ciliberto, Emig, Pavloff, Isoard, arXiv:2404.16497,"
        " Fig. 3/4 (waterfall config, m_d=2.9, T=0) -- NOT recomputed from the"
        " underlying Bogoliubov/scattering-matrix theory in this script.",
        "The isotropic-table map S -> e(S) is THIS script's bridging construction,"
        " not a claim of the cited paper: a single CHSH expectation value does not"
        " determine a unique probability table, and no experiment has yet measured"
        " a full (2,2,2,2) outcome table on a real analogue-Hawking device.",
        "No finite-sample statistics are simulated here (contrast"
        " mbqc_blackbox_test.py's sampling/certificate-stack/verdict layer, which"
        " has no counterpart for this application yet -- see NOTES-hawking.md Sec. 5).",
        "KCBS-C5 and CHSH are DIFFERENT scenarios (one wire / multi-context vs. two"
        " wires / factorized settings); this script does not claim Hawking pairs are"
        " KCBS-like, only that CHSH -- already inside this repo's graph-invariant"
        " umbrella -- is the structurally correct point of contact, and reuses the"
        " pre-existing CF-of-CHSH numbers from claude/signaling-taxonomy as anchors.",
    ]
    for c in caveats:
        print(f"  - {c}")

    summary = {
        "anchors": {k: round(v, 10) for k, v in anchors.items()},
        "S_hawking_lit": S_HAWKING_LIT,
        "cf_hawking_lit": round(lit["cf_lit"], 6),
        "cf_hawking_epr_limit": round(lit["cf_epr_limit"], 6),
        "cf_kcbs_quantum": round(CF_KCBS_EXACT, 6),
        "cf_chsh_tsirelson": round(CF_CHSH_TSIRELSON_EXACT, 6),
        "sources": {
            "S_hawking": "Ciliberto, Emig, Pavloff, Isoard, arXiv:2404.16497, Fig. 3/4 (m_d=2.9, T=0)",
            "cf_chsh_tsirelson_anchor": "signaling_taxonomy.py / NOTES-signaling.md, branch claude/signaling-taxonomy",
            "cf_kcbs_anchor": "mbqc_blackbox_test.py CF_EXACT, this repo",
        },
    }
    print()
    print("MACHINE-READABLE SUMMARY")
    print(json.dumps(summary, indent=1))
    sys.exit(0)


if __name__ == "__main__":
    main()
