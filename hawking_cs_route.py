# -*- coding: utf-8 -*-
"""
hawking_cs_route.py -- third-pass computational investigation for the
"classical emulatability of Hawking-radiation dynamics" stream. Companion
note: NOTES-hawking-3.md. Read together with NOTES-hawking.md (first pass:
CHSH bridge) and NOTES-hawking-2.md (second pass, Sec. 2 of which already
gave a literature-grounded negative finding on this exact question -- this
script does NOT repeat that derivation, it independently deepens it with
new, checkable computation).

THE QUESTION (task-set, this session)
--------------------------------------
The actual analogue-Hawking-radiation literature's native quantum-vs-
classical witness is a Cauchy-Schwarz (CS) inequality on density-density
g^(2)-type correlators (de Nova, Sols, Zapata, Phys. Rev. A 89, 043808
(2014), arXiv:1211.1761; Leonhardt's reading of the Busch-Parentani/
Steinhauer nonseparability criterion as a first-moment CS-for-probabilities
sibling, arXiv:1609.03803). Does this CS bound have a reading in this
project's own graph-invariant language (alpha, theta, CF -- BlackBox.wl,
mbqc_blackbox_test.py, hawking_cf_bridge.py)?

WHAT THIS SCRIPT ADDS BEYOND NOTES-hawking-2.md Sec. 2
-------------------------------------------------------
NOTES-hawking-2.md already showed (i) the naive {H-click, P-click}
exclusivity graph is edgeless (vacuous, theta = alpha = 2, no gap) and
(ii) the de Nova-Sols-Zapata ratio theta_ud2(x) is a monotone, non-graded
on/off indicator, not a scale like CF(S) = (S-2)/2. This script:

  1. GENERALIZES finding (i) from "the one graph they tried" to "every
     finite discretization of this measurement, full stop": Sec. 1 proves
     and LP-verifies that ANY single-context empirical model (which is what
     a jointly-measured, never-incompatibly-chosen density correlator is,
     structurally) has contextual fraction CF = 0 IDENTICALLY, for every
     valid probability vector, independent of the outcome alphabet. This
     is why no cleverer binning of (n_H, n_P) can rescue the CF/theta
     reading -- not a property of one attempted graph, but of the
     single-context operational structure itself.
  2. Gives a NEW, from-scratch, closed-form derivation of CS violation for
     the idealized two-mode-squeezed-vacuum (TMSV) Hawking/partner pair
     (the same T=0 EPR-limit idealization NOTES-hawking.md Sec. 5 already
     uses for the CHSH bridge), independent of the de Nova-Sols-Zapata
     scattering-matrix formula -- and shows it reproduces the SAME
     qualitative shape (always > 1, diverges at the weak-pairing end,
     -> 1 from above at the strong-pairing end) from a completely
     different (state-vector, not S-matrix) starting point.
  3. Makes concrete, with actual numbers, the claim (already named but not
     built in NOTES-hawking-2.md Sec. 2.3) that the Cauchy-Schwarz bound
     IS an instance of a *different* semidefinite-positivity hierarchy
     (Shchukin-Vogel, Phys. Rev. A 72, 043808 (2005)) than Lovasz theta --
     both are "PSD matrix + linear constraints" in the abstract, but
     indexed by different objects (operator monomials vs. graph vertices)
     and posed as different problem types (feasibility vs. extremal).
  4. Verifies, both analytically and by Monte Carlo, this project's own
     Lovasz-theta convention (BlackBox.wl's SDP form) gives theta = n on
     the edgeless graph on n vertices (Knuth's cited fact, now checked
     against the actual SDP this repo uses, not just cited).
  5. Derives (Sec. 5) a delta-method sample-size (N*) scoping formula for
     a finite-sample Cauchy-Schwarz certificate, exactly as flagged (and
     left open) by NOTES-hawking-2.md Sec. 3.3's "delta-method... would
     need to become the primary tool, not a second opinion."

SANITY-FIRST RULE, as in every prior script in this stream: internal
consistency checks (symbolic vs. numeric; the thermal-variance identity
Var(n) = nbar(nbar+1); the CF=0 single-context fact on multiple outcome
counts) are run and must PASS before anything is reported as a finding.

Run:  python3 hawking_cs_route.py
Deps: numpy, scipy (linprog/HiGHS), sympy.
"""

import sys
import numpy as np
import sympy as sp
from scipy.optimize import linprog
from scipy.stats import norm

SQRT2 = np.sqrt(2.0)


# ============================================================================
# 1. SINGLE-CONTEXT CF TRIVIALITY: generalizes the null-graph finding of
#    NOTES-hawking-2.md Sec 2.2 to EVERY finite discretization at once.
# ============================================================================
def single_context_ncf(e):
    """AB incidence matrix of a ONE-context scenario with len(e) outcomes:
    the only 'contexts' available are trivial (there is exactly one), so
    each deterministic global assignment IS one of the outcomes itself:
    M = Identity(K). NCF(e) = max sum(d) s.t. d <= e, d >= 0 -- since M is
    diagonal, the K constraints decouple and d = e is simultaneously
    feasible and optimal (cannot do better than sum(e) = 1 while staying
    <= e entrywise and using nonneg weights only). So NCF = 1 and CF = 0
    EXACTLY, for every valid probability vector e on every outcome count K
    -- not a fact about one particular graph, but about single-context
    scenarios as such."""
    K = len(e)
    M = np.eye(K)
    res = linprog(-np.ones(K), A_ub=M, b_ub=e, bounds=[(0, None)] * K, method="highs")
    if res.status != 0:
        raise RuntimeError(f"single-context LP failed: {res.message}")
    ncf = -res.fun
    return ncf, 1.0 - ncf


def run_single_context_checks():
    print("=" * 78)
    print("SEC 1. SINGLE-CONTEXT CF TRIVIALITY (generalizes NOTES-hawking-2 Sec 2.2)")
    print("=" * 78)
    print("  Claim: a density-density correlator (n_H, n_P) is ALWAYS jointly")
    print("  measured in one shot -- there is no experimenter-chosen incompatible")
    print("  'other way' to ask the same question, unlike CHSH's setting choice.")
    print("  Operationally this is a SINGLE-CONTEXT empirical model in the")
    print("  Abramsky-Brandenburger sense, whatever finite alphabet you bin the")
    print("  outcomes into. Claim: CF = 0 identically for such a model, always.")
    print()
    rng = np.random.default_rng(20260711)
    cases = []

    # K=2: the exact null-graph case NOTES-hawking-2 tried by hand
    e2 = np.array([0.3, 0.7])
    cases.append(("K=2 (NOTES-hawking-2's null-graph case)", e2))

    # K=4: a 2x2 truncated joint (n_H, n_P) in {0,1}^2, asymmetric
    e4 = np.array([0.55, 0.05, 0.05, 0.35])
    cases.append(("K=4 (2x2 truncated joint occupation table)", e4))

    # K=9: a 3x3 truncated joint (n_H, n_P) in {0,1,2}^2, random valid table
    raw9 = rng.dirichlet(np.ones(9))
    cases.append(("K=9 (3x3 truncated joint, random valid table)", raw9))

    # K=11: the ACTUAL TMSV joint distribution restricted to the diagonal
    # n_H = n_P (off-diagonal genuinely zero for TMSV -- perfect number
    # correlation), embedded as an 11x11=121-outcome space collapsed to its
    # 11 nonzero diagonal cells. This is not an artificial binning -- it is
    # literally the real joint quantum distribution of the idealized paired
    # state, truncated for a finite outcome count.
    lam = 0.6
    ns = np.arange(11)
    pdiag = (1 - lam ** 2) * lam ** (2 * ns)
    pdiag = pdiag / pdiag.sum()
    cases.append(("K=11 (actual TMSV diagonal joint dist., truncated)", pdiag))

    ok = True
    for label, e in cases:
        ncf, cf = single_context_ncf(e)
        passed = abs(cf) < 1e-9
        ok &= passed
        print(f"  [{'PASS' if passed else 'FAIL'}] {label:52s} CF = {cf:.3e}")
    if not ok:
        print("SINGLE-CONTEXT ANCHOR FAILURE -- aborting.")
        sys.exit(1)
    print()
    print("  Reading: CF = 0 for every case, INCLUDING the real TMSV joint")
    print("  distribution itself -- confirming this is not a defect of one naive")
    print("  graph choice, but a structural fact about single-context data: a")
    print("  Kochen-Specker/Bell-type gap requires >= 2 INCOMPATIBLE contexts")
    print("  whose marginals cannot be jointly reproduced by one global section.")
    print("  A density-density correlator, jointly measured in every single shot,")
    print("  never poses that question -- no matter how the outcome alphabet is")
    print("  chosen. This is why CHSH (Ciliberto et al. 2024's pseudospin route,")
    print("  NOTES-hawking.md Sec. 4) needs a GENUINELY NEW, incompatible")
    print("  dichotomized observable bolted onto the state to create a second")
    print("  context -- and why the g^(2)/CS route, which uses no such device,")
    print("  structurally cannot land in this framework by construction, not by")
    print("  a failure to find the right graph.")
    return ok


# ============================================================================
# 2. TMSV EXACT CAUCHY-SCHWARZ VIOLATION (new, from-scratch derivation)
# ============================================================================
def tmsv_symbolic():
    """Two-mode squeezed vacuum |TMSV> = sqrt(1-lambda^2) sum_n lambda^n |n,n>,
    the idealized T=0 EPR-limit Hawking/partner pair (same idealization
    NOTES-hawking.md Sec. 5 uses for the CHSH bridge's S -> 2 sqrt(2) limit).
    Since n_H = n_P = n exactly on every term, the de Nova-Sols-Zapata
    correlators (their Eq. 5, this project's own notation Gamma_ij) reduce
    to ordinary thermal-marginal factorial moments: <n(n-1)...(n-k+1)> =
    k! nbar^k EXACTLY for a geometric/thermal photon-number distribution
    (standard chaotic-light factorial-moment identity)."""
    nbar = sp.symbols('nbar', positive=True)
    Gamma_HH = 2 * nbar ** 2          # <n(n-1)>
    Gamma_PP = 2 * nbar ** 2          # <n(n-1)>  (same marginal)
    Gamma_HP = 2 * nbar ** 2 + nbar   # <n_H n_P> = <n^2> = <n(n-1)> + <n>
    D_CS = sp.expand(Gamma_HP ** 2 - Gamma_HH * Gamma_PP)
    theta_ratio = sp.simplify(Gamma_HP / sp.sqrt(Gamma_HH * Gamma_PP))
    return nbar, Gamma_HH, Gamma_PP, Gamma_HP, D_CS, theta_ratio


def tmsv_moments_numeric(lam, ncutoff=20000):
    """Direct Fock-space cross-check: build the actual geometric Schmidt
    distribution to a large cutoff and sum the moments numerically --
    independent of the closed-form factorial-moment algebra above."""
    n = np.arange(ncutoff + 1, dtype=np.float64)
    logp = np.log(1 - lam ** 2) + 2 * n * np.log(lam) if lam > 0 else None
    p = np.exp(logp)
    p = p / p.sum()
    nbar_num = float(np.sum(n * p))
    Gamma_HH_num = float(np.sum(n * (n - 1) * p))
    Gamma_HP_num = float(np.sum(n * n * p))
    return nbar_num, Gamma_HH_num, Gamma_HP_num


def run_tmsv_section():
    print()
    print("=" * 78)
    print("SEC 2. TMSV EXACT CAUCHY-SCHWARZ VIOLATION (new derivation, not de Nova")
    print("        et al.'s S-matrix formula -- an independent state-vector check)")
    print("=" * 78)
    nbar, Gamma_HH, Gamma_PP, Gamma_HP, D_CS, theta_ratio = tmsv_symbolic()
    print(f"  Gamma_HH = Gamma_PP = {Gamma_HH}")
    print(f"  Gamma_HP             = {Gamma_HP}")
    print(f"  D_CS = Gamma_HP^2 - Gamma_HH Gamma_PP = {D_CS}   (> 0 for all nbar > 0)")
    print(f"  theta = Gamma_HP / sqrt(Gamma_HH Gamma_PP) = {theta_ratio}")
    print()

    # symbolic sanity: D_CS > 0 for all nbar > 0 (SOS-style check via a grid
    # plus the exact factored form)
    D_CS_factored = sp.factor(D_CS)
    print(f"  D_CS factored: {D_CS_factored}  (manifestly positive for nbar > 0)")

    lims = {
        "nbar -> 0+ (weak pairing)": sp.limit(theta_ratio, nbar, 0, dir="+"),
        "nbar -> oo (strong pairing)": sp.limit(theta_ratio, nbar, sp.oo),
    }
    for k, v in lims.items():
        print(f"  lim theta, {k:28s} = {v}")

    # numeric cross-check against direct Fock-space truncation, several nbar
    print()
    print("  Numeric Fock-space cross-check (independent of the algebra above):")
    ok = True
    for lam in (0.05, 0.2, 0.4, 0.6, 0.8):
        nbar_n, GHH_n, GHP_n = tmsv_moments_numeric(lam)
        GHH_closed = float(Gamma_HH.subs(nbar, nbar_n))
        GHP_closed = float(Gamma_HP.subs(nbar, nbar_n))
        d1 = abs(GHH_n - GHH_closed)
        d2 = abs(GHP_n - GHP_closed)
        passed = d1 < 1e-6 and d2 < 1e-6
        ok &= passed
        print(f"    [{'PASS' if passed else 'FAIL'}] lam={lam:.2f} nbar={nbar_n:.6f}  "
              f"Gamma_HH: closed={GHH_closed:.6e} numeric={GHH_n:.6e} (diff {d1:.1e})  "
              f"Gamma_HP: closed={GHP_closed:.6e} numeric={GHP_n:.6e} (diff {d2:.1e})")
    if not ok:
        print("TMSV NUMERIC CROSS-CHECK FAILURE -- aborting.")
        sys.exit(1)

    print()
    print("  Reading: CS is violated (theta > 1, D_CS > 0) for EVERY nbar > 0 -- an")
    print("  on/off, not graded, indicator, confirming (via an independent, from-")
    print("  scratch Fock-space route rather than the cited S-matrix formula) the")
    print("  qualitative shape NOTES-hawking-2.md Sec. 2.2 already found: theta")
    print("  diverges as the pairing weakens (nbar -> 0) and -> 1 from above as it")
    print("  strengthens (nbar -> infinity) -- the OPPOSITE of a graded scale like")
    print("  CF(S) = (S-2)/2 (hawking_cf_bridge.py), where more violation reads as")
    print("  a strictly larger number on a fixed [0,1] scale.")
    return nbar, Gamma_HH, Gamma_PP, Gamma_HP, D_CS


# ============================================================================
# 3. SHCHUKIN-VOGEL 2x2 MINIMAL CASE: CS violation AS moment-matrix
#    positivity failure (a different SDP species than Lovasz theta)
# ============================================================================
def run_moment_matrix_section(nbar_sym, Gamma_HH, Gamma_PP, Gamma_HP):
    print()
    print("=" * 78)
    print("SEC 3. CS AS SHCHUKIN-VOGEL 2x2 MOMENT-MATRIX POSITIVITY (Class A)")
    print("=" * 78)
    print("  de Nova-Sols-Zapata's own words (arXiv:1211.1761, quoted in")
    print("  NOTES-hawking-2.md Sec 2.1): 'the proof of (4) requires the system")
    print("  to be described by a positive (Glauber-Sudarshan) P function.' The")
    print("  2x2 Gram/moment matrix M = [[Gamma_HH, Gamma_HP],[Gamma_HP, Gamma_PP]]")
    print("  is literally the smallest nontrivial case of the Shchukin-Vogel")
    print("  moment-matrix hierarchy (Phys. Rev. A 72, 043808 (2005)): P >= 0")
    print("  implies M is PSD; CS violation (Gamma_HP^2 > Gamma_HH Gamma_PP) IS")
    print("  exactly 'M is not PSD' (2x2 PSD test = nonneg diagonal + nonneg det).")
    print()
    for nbar_val in (0.05, 0.2, 1.0):
        ghh = float(Gamma_HH.subs(nbar_sym, nbar_val))
        gpp = float(Gamma_PP.subs(nbar_sym, nbar_val))
        ghp = float(Gamma_HP.subs(nbar_sym, nbar_val))
        M = np.array([[ghh, ghp], [ghp, gpp]])
        eigs = np.linalg.eigvalsh(M)
        psd = eigs.min() >= -1e-9
        print(f"    nbar={nbar_val:.2f}: TMSV moment matrix eigs = "
              f"[{eigs[0]:.6f}, {eigs[1]:.6f}]  -> {'PSD (classical-consistent)' if psd else 'NOT PSD (CS violated)'}")
        # classical boundary case: same marginals, cross term capped at the
        # CS bound exactly (a legitimate P-representable, classically-
        # correlated Gaussian model matched to the same Gamma_HH, Gamma_PP)
        ghp_classical = np.sqrt(ghh * gpp)
        M_cl = np.array([[ghh, ghp_classical], [ghp_classical, gpp]])
        eigs_cl = np.linalg.eigvalsh(M_cl)
        psd_cl = eigs_cl.min() >= -1e-9
        print(f"              classical boundary (Gamma_HP = sqrt(Gamma_HH Gamma_PP)"
              f" = {ghp_classical:.6f}): eigs = [{eigs_cl[0]:.6f}, {eigs_cl[1]:.6f}]"
              f"  -> {'PSD (boundary, as expected)' if psd_cl else 'NOT PSD (unexpected!)'}")
    print()
    print("  Reading: TWO different 'PSD matrix subject to linear constraints'")
    print("  problems are both in play in this project's wider toolkit, but they")
    print("  are DIFFERENT SPECIES: Lovasz theta (Sec. 4 below) is an EXTREMAL SDP")
    print("  (max a linear functional over PSD X, indexed by GRAPH VERTICES,")
    print("  subject to orthogonality on the graph's edges) with no analogue here;")
    print("  the CS/Shchukin-Vogel object is a FEASIBILITY SDP (does a PSD")
    print("  completion of these observed moments exist), indexed by OPERATOR")
    print("  MONOMIALS on an infinite-dimensional bosonic algebra, truncated. Both")
    print("  are 'SDP-flavored' in the abstract; there is no known dictionary")
    print("  translating one into the other for this system.")


# ============================================================================
# 4. LOVASZ THETA OF THE EDGELESS GRAPH = n (this repo's own SDP convention)
# ============================================================================
def run_lovasz_edgeless_section():
    print()
    print("=" * 78)
    print("SEC 4. LOVASZ THETA OF THE EDGELESS GRAPH (BlackBox.wl's own SDP form)")
    print("=" * 78)
    print("  BlackBox.wl's LovaszTheta[g] SDP: maximize Total[X,2] (sum of all")
    print("  entries) over PSD X, Tr[X] = 1, with X[i,j] = 0 forced only on EDGES")
    print("  of g. On the edgeless graph there are no such constraints at all, so")
    print("  the SDP is: max 1^T X 1 s.t. X PSD, Tr X = 1.")
    print()
    print("  Analytic solution: 1^T X 1 <= n * lambda_max(X) <= n * Tr(X) = n for")
    print("  any PSD X (lambda_max <= Tr for PSD matrices), with equality iff")
    print("  X = J/n (J = all-ones matrix). So theta(edgeless, n) = n EXACTLY --")
    print("  this project's own SDP convention reproduces Knuth's cited fact")
    print("  (Electron. J. Combin. 1 (1994), A1), not merely by citation.")
    print()
    rng = np.random.default_rng(20260711)
    print("  (a) upper-bound sanity: random PSD trace-1 matrices never exceed n")
    for n in (2, 3, 5, 9):
        best = 0.0
        for _ in range(20000):
            A = rng.standard_normal((n, n))
            X = A @ A.T
            X = X / np.trace(X)
            best = max(best, float(np.sum(X)))
        print(f"      n={n}: max sum(X) over 20000 random PSD trace-1 samples = "
              f"{best:.6f}  (<= n={n}, as required)")
    print("      NOTE: random search undershoots the true supremum badly for")
    print("      larger n -- a fixed direction (1,...,1)/sqrt(n) has exponentially")
    print("      small overlap with a generic random matrix's dominant eigenvector")
    print("      as n grows (concentration of measure), so blind random sampling")
    print("      is the WRONG tool to locate the maximizer; it only sanity-checks")
    print("      the upper bound. Part (b) confirms tightness by direct")
    print("      construction instead of search.")
    print()
    print("  (b) tightness: DIRECT construction of the maximizer X = J/n")
    for n in (2, 3, 5, 9):
        Jn = np.ones((n, n)) / n
        eigs = np.linalg.eigvalsh(Jn)
        is_psd = bool(eigs.min() >= -1e-12)
        trace_ok = bool(abs(np.trace(Jn) - 1.0) < 1e-12)
        exact_val = float(np.sum(Jn))
        print(f"      n={n}: X=J/n is PSD: {is_psd}, Tr(X)=1: {trace_ok}, "
              f"sum(X) = {exact_val:.6f} = n exactly  -> theta(edgeless_{n}) = {n}")
    print()
    print("  Reading: the K=2 case is exactly NOTES-hawking-2.md Sec 2.2's null-")
    print("  graph finding (theta = alpha = 2, no classical/quantum gap); this")
    print("  confirms it against the project's own SDP convention and shows the")
    print("  same degeneracy for any n, i.e. for any number of mutually-non-")
    print("  exclusive 'outcomes' one might try to hang on the H/P correlator.")


# ============================================================================
# 5. FINITE-SAMPLE N* SCOPING (delta method; exact under a stated toy model,
#    explicitly flagged as a modeling simplification standing in for the
#    unpublished real per-shot statistics -- see NOTES-hawking-2.md Sec 1)
# ============================================================================
def run_sample_complexity_section():
    print()
    print("=" * 78)
    print("SEC 5. DELTA-METHOD N* SCOPING FOR A FINITE-SAMPLE CS CERTIFICATE")
    print("=" * 78)
    print("  Builds the piece NOTES-hawking-2.md Sec 3.3 flagged and left open:")
    print("  'a delta-method... would need to become the primary tool here.'")
    print("  Model: N iid shots; per shot the SAME idealized TMSV-toy joint")
    print("  photon-number n (n_H = n_P = n exactly) is drawn from the thermal/")
    print("  geometric distribution p(n) = (1-x) x^n, x = nbar/(1+nbar). This is")
    print("  an explicit, named MODELING CHOICE standing in for the real per-shot")
    print("  statistics, which NOTES-hawking-2.md Sec 1 established are not")
    print("  publicly available for any Steinhauer-program experiment -- flagged")
    print("  here again, not fabricated as if it were measured data.")
    print()

    nbar = sp.symbols('nbar', positive=True)
    # exact ordinary moments of a thermal/geometric distribution via
    # factorial moments <n(n-1)...(n-k+1)> = k! nbar^k and Stirling numbers
    # of the second kind (n^k = sum_j S(k,j) n_falling_j):
    n1 = nbar
    n2 = 2 * nbar ** 2 + nbar
    n3 = 6 * nbar ** 3 + 6 * nbar ** 2 + nbar
    n4 = 24 * nbar ** 4 + 36 * nbar ** 3 + 14 * nbar ** 2 + nbar
    Var_n = sp.expand(n2 - n1 ** 2)
    check_thermal = sp.simplify(Var_n - nbar * (nbar + 1))
    print(f"  Var(n) = {Var_n}  (thermal-variance identity check, should be 0: "
          f"{check_thermal})")

    m2_mean = 2 * nbar ** 2                       # E[n(n-1)]
    Em2sq = sp.expand(n4 - 2 * n3 + n2)            # E[(n(n-1))^2] = E[n^4-2n^3+n^2]
    Var_m2 = sp.expand(Em2sq - m2_mean ** 2)
    Cov_n_m2 = sp.expand((n3 - n2) - n1 * m2_mean)  # E[n * n(n-1)] - E[n]E[m2]

    print(f"  Var(n(n-1))        = {Var_m2}")
    print(f"  Cov(n, n(n-1))     = {Cov_n_m2}")

    # D_CS as a function of the two underlying sample means (nbar_hat, m2_hat):
    # D_hat = nbar_hat * (2*m2_hat + nbar_hat)   [derived in NOTES-hawking-3.md]
    m2s = sp.symbols('m2', positive=True)
    D_of = nbar * (2 * m2s + nbar)
    dD_dnbar = sp.diff(D_of, nbar).subs(m2s, m2_mean)
    dD_dm2 = sp.diff(D_of, m2s)

    Var_D_per_shot = sp.expand(
        dD_dnbar ** 2 * Var_n + dD_dm2 ** 2 * Var_m2 + 2 * dD_dnbar * dD_dm2 * Cov_n_m2
    )
    D_CS_pop = sp.expand((2 * nbar ** 2 + nbar) ** 2 - (2 * nbar ** 2) ** 2)
    print(f"  D_CS (population, exact)         = {D_CS_pop}")
    print(f"  Var(D_hat_CS) * N (per-shot term) = {sp.factor(Var_D_per_shot)}")
    print()

    Var_D_per_shot_f = sp.lambdify(nbar, Var_D_per_shot, "numpy")
    D_CS_pop_f = sp.lambdify(nbar, D_CS_pop, "numpy")

    ALPHA_TOTAL = 0.01
    ALPHA_C1 = ALPHA_TOTAL / 2       # mirrors mbqc_blackbox_test.py's Bonferroni split
    z = norm.ppf(1 - ALPHA_C1)      # one-sided gate: D_CS_lo = D_hat - z*sigma/sqrt(N) > 0
    print(f"  Pre-registered budget: alpha_total = {ALPHA_TOTAL}, alpha_C1 = "
          f"{ALPHA_C1} (one-sided), z = {z:.4f}")
    print()

    print(f"  {'nbar':>8s}  {'D_CS(pop)':>12s}  {'Var(D_hat)*N':>14s}  {'N*':>12s}")
    grid_nbar = [0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0]
    nstars = {}
    for nb in grid_nbar:
        d = D_CS_pop_f(nb)
        v1 = Var_D_per_shot_f(nb)
        nstar = (z ** 2) * v1 / (d ** 2)
        nstars[nb] = nstar
        print(f"  {nb:8.3f}  {d:12.6e}  {v1:14.6e}  {nstar:12.1f}")

    print()
    N_STEINHAUER_2016 = 4600
    print(f"  Cross-check against the ONE real number available (NOTES-hawking-2.md")
    print(f"  Sec 1.3): N = {N_STEINHAUER_2016} independent runs, Steinhauer 2016.")
    print(f"  Inverting N*(nbar) = {N_STEINHAUER_2016} under this SAME toy model:")
    from scipy.optimize import brentq

    def f(nb):
        return (z ** 2) * Var_D_per_shot_f(nb) / (D_CS_pop_f(nb) ** 2) - N_STEINHAUER_2016

    nbar_reach = brentq(f, 1e-6, 5.0)
    print(f"    nbar* (smallest illustrative-model population signal that "
          f"{N_STEINHAUER_2016} shots would certify) = {nbar_reach:.5f}")
    print()
    print("  CAVEATS (read before citing any number in this section):")
    print("  - nbar is NOT a measured quantity from any published Steinhauer-")
    print("    program run; no run-by-run occupation-number data are public")
    print("    (NOTES-hawking-2.md Sec 1.2). Every number in the table above is")
    print("    illustrative, generated from the STATED toy per-shot model, not a")
    print("    citation of measured statistics.")
    print("  - N = 4600 IS the real, cited repetition count of Steinhauer 2016 --")
    print("    the ONLY real number in this section. Everything downstream of it")
    print("    (nbar*) is conditional on the illustrative toy model, and would")
    print("    need to be redone against the actual per-shot noise once/if such")
    print("    data become available.")
    print("  - Hoeffding (used throughout mbqc_blackbox_test.py) requires BOUNDED")
    print("    outcomes; photon number is not naturally bounded. This delta-")
    print("    method/CLT normal-approximation route is used here instead, as")
    print("    NOTES-hawking-2.md Sec 3.3 anticipated; a fully rigorous version")
    print("    would replace it with a Bernstein/Bennett-type sub-exponential")
    print("    concentration bound (Boucheron-Lugosi-Massart, 'Concentration")
    print("    Inequalities', 2013) or a bootstrap CI, not asserted exact here.")
    return nstars, nbar_reach


def main():
    ok1 = run_single_context_checks()
    nbar_sym, GHH, GPP, GHP, D_CS = run_tmsv_section()
    run_moment_matrix_section(nbar_sym, GHH, GPP, GHP)
    run_lovasz_edgeless_section()
    nstars, nbar_reach = run_sample_complexity_section()

    print()
    print("=" * 78)
    print("SUMMARY")
    print("=" * 78)
    print("  1. Single-context CF triviality: CONFIRMED (LP), generalizes the")
    print("     null-graph finding of NOTES-hawking-2.md to every finite")
    print("     discretization of a jointly-measured density correlator.")
    print("  2. TMSV closed-form CS violation: theta(nbar) = 1 + 1/(2 nbar) > 1")
    print("     for all nbar > 0 -- independent re-derivation, same qualitative")
    print("     on/off shape as the S-matrix-based finding already in this repo.")
    print("  3. CS violation = failure of a 2x2 Shchukin-Vogel moment matrix to")
    print("     be PSD -- a genuine SDP-type object, but indexed by operator")
    print("     monomials (feasibility problem), not graph vertices (extremal")
    print("     problem) -- no known dictionary to Lovasz theta.")
    print("  4. theta(edgeless graph, n vertices) = n, confirmed against this")
    print("     repo's own SDP convention analytically and by direct construction")
    print("     (Monte Carlo random search alone underestimates it -- expected,")
    print("     concentration of measure, not a contradiction; see Sec 4).")
    print("  5. A delta-method N* scoping table was produced; every specific")
    print("     number beyond the formula itself and N=4600 is illustrative,")
    print("     not measured (flagged throughout).")
    print()
    print("BOTTOM LINE: the Cauchy-Schwarz route does NOT reduce to this")
    print("project's alpha/theta/CF machinery. This is a structural fact (single-")
    print("context data cannot pose a Kochen-Specker/Bell-type question, Sec 1),")
    print("not a failure to find the right graph. It DOES sit inside a different,")
    print("legitimate SDP-type hierarchy (Shchukin-Vogel/PPT), named but not")
    print("built out in full here (Sec 3).")
    sys.exit(0)


if __name__ == "__main__":
    main()
