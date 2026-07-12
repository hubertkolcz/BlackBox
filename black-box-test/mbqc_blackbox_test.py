# -*- coding: utf-8 -*-
"""
mbqc_blackbox_test.py -- pre-registered black-box certification protocol for the
MBQC interface of the quantum-contextuality programme (module #9, gap analysis
of 10 July 2026; operationalizes Sec. 3 of lie_poisson_interface.wl and Sec. 4
of mbqc-fem-study-design-2026-07-10.md).

THE QUESTION
------------
Three devices emit finite-sample click statistics on the 5 KCBS contexts
(edges of the pentagon C5, measurements A0..A4, outcomes in {0,1}^2 with the
section order (00, 01, 10, 11) per context; the (1,1) outcome is structurally
absent -- one photon, one click). From the statistics ALONE, decide which
device holds a genuine quantum resource. The emulation boundary being probed
(lie_poisson_interface.wl Sec. 3):

    classical/NCHV node-sum cap        2
    quantum cap  theta(C5) = sqrt(5),  CF = 2 sqrt(5) - 4 ~ 0.4721360
    exclusivity-only cap  alpha* = 5/2 (reachable by intensity semantics,
                                        INCLUDING Wright-type tables)

The certifying difference is EVENT SEMANTICS: single-photon clicks versus
normalized intensity fractions of a divided classical beam. Intensity
fractions populate empirical tables that no quantum system can produce
(node sums beyond sqrt(5), Wright's strongly contextual box), because they
are not single-event probabilities. The protocol therefore certifies the
conjunction (table x semantics), and its emulation flags target exactly the
freedoms an intensity emulator has and a quantum device does not.

THE THREE BOXES
---------------
(i)   QUANTUM   qutrit Born-rule sampler on the exact KCBS pentagram
      projectors, state rho = V |psi><psi| + (1-V) I/3, psi = cone axis.
      Tested at V = 1.0, V = 0.977 (Lapkiewicz regime), V = 0.550 < V_crit,
      and at the threshold V_crit = (5+3 sqrt(5))/20 ~ 0.5854102 (edge case).
(ii)  CLASSICAL NCHV sampler: literal per-shot hidden variable. Each shot
      draws one of the five deterministic assignments 1_{k, k+2 mod 5}
      (the maximum-weight independent-set mixture, node sum = alpha = 2,
      the best classical model) and answers every context deterministically.
(iii) INTENSITY-SEMANTICS emulator: classical light divided per context;
      the box reports normalized intensity fractions AS IF they were click
      probabilities (pseudo-clicks: the integrated intensity of context
      (i, i+1) is binned into N quanta multinomially). Fractions per context:
      (f_10, f_01, f_00) = (t + delta, t - delta, 1 - 2t). The signaling knob
      delta models imperfect context-aware renormalization: measurement i is
      re-prepared between the two contexts that share it, so its marginal
      differs by 2 delta across contexts -- a semantics violation invisible
      to any single context. Configurations: t = 1/2 (Wright/alpha* point,
      delta = 0 and delta = 0.05) and t = 0.42 sub-quantum with delta = 0.05.

PRE-REGISTERED CERTIFICATE STACK (confidence budget alpha = 0.01, split
0.0025 to each of ND / CF / CE2 / node-sum; within a family, Bonferroni
over its components; N = clicks per context; all thresholds fixed BEFORE
sampling; master seed 20260710)
--------------------------------------------------------------------------
C1  NO-DISTURBANCE (HarmonicResidual analogue). For each measurement m, its
    marginal is estimated in both contexts containing it. Hoeffding: each
    estimate is within eps_m = sqrt(ln(2/a')/(2N)) of truth w.p. 1 - a',
    a' = 0.0025/(5*2). SIGNALING flag iff some |marginal difference|
    exceeds 2 eps_m. Also reported: the l2 residual ||delta . e_hat|| of the
    cellular-sheaf coboundary (CycleCoboundary[5] of BlackBox.wl).
C2  CONTEXTUAL FRACTION by the exact AB linear program (20 x 32 incidence).
    NCF(e) = max total weight of subprobability mixtures of the 32 global
    assignments dominated by e; CF = 1 - NCF. NCF is monotone in e, so with
    the Hoeffding envelope eps_H = sqrt(ln(2/a'')/(2N)), a'' = 0.0025/20:
        CF_lo = 1 - NCF(e_hat + eps_H)   (valid lower conf. bound, >= level)
        CF_hi = 1 - NCF(max(e_hat - eps_H, 0))
    hold w.p. >= 1 - 0.0025 jointly. Bootstrap percentile CI (B = 300) is
    reported as a descriptive second opinion, never as the gate.
C3  CONSISTENT EXCLUSIVITY at two copies (CE^2 / Local Orthogonality) under
    the factorization rule P(e, f) = p(e) p(f). Per-event p_hat_i pooled over
    the two contexts (2N samples); eps_p = sqrt(ln(2/a''')/(4N)),
    a''' = 0.0025/5. All 535 maximal cliques of the OR-product C5*C5
    (census 525 of size 4, 10 pentads of size 5 -- verified) are tested:
    CE2-VIOLATION flag iff some clique load lower bound
    sum_{(i,j) in K} max(p_i - eps_p, 0) max(p_j - eps_p, 0) > 1.
    The quantum table SATURATES the ten pentads at exactly 1, so saturation
    is quantum-consistent; only a certified excess flags emulation.
C4  POSSIBILISTIC SUPPORT / AB PARITY. Support = sections with count >=
    s_min = 5. The support is checked against the 32 global assignments;
    empty possibilistic support = strong contextuality (CF = 1, ABM). On C5
    the quantum maximum is CF = 2 sqrt(5) - 4 < 1, so a strong-contextuality
    support (e.g. Wright's exactly-one-per-edge pattern, impossible on an
    odd cycle by the parity argument: sum of (a_i + a_{i+1}) over edges is
    even, exactly-one-per-edge forces 5) exceeds quantum reach => flag.
C5  NODE SUM Sigma = sum_i p_hat_i against the boundary {2, sqrt(5), 5/2}
    with the interval +-5 eps_p. SUPRA-QUANTUM flag iff
    Sigma - 5 eps_p > sqrt(5).

PRE-REGISTERED VERDICT LOGIC (evaluated in this order)
------------------------------------------------------
V1  C1 signaling             -> EMULATION-SUSPECT (semantics violation:
                                context-dependent marginals; note that a
                                signaling table can carry spurious CF > 0,
                                which is why C1 precedes C2).
V2  C5 supra-quantum, or C3 CE2-violation, or C4 strong-contextuality
    support                  -> EMULATION-SUSPECT (exclusivity-only regime,
                                beyond the quantum C5 set).
V3  else if CF_lo > 0        -> QUANTUM-CERTIFIED.
V4  else if CF_hat <= 0.05   -> CLASSICAL (point classification; the
                                conservative claim of the protocol is V3,
                                and only V3, by design).
V5  else                     -> INCONCLUSIVE.

PRE-REGISTERED GATES (headline N = 10^4 clicks/context, R = 25 repetitions;
gate passes iff the expected verdict occurs in >= 95% of repetitions)
--------------------------------------------------------------------------
G1  box (i)  V = 1.000  -> QUANTUM-CERTIFIED.
G2  box (i)  V = 0.977  -> QUANTUM-CERTIFIED.
G3  box (i)  V = 0.550  -> NOT QUANTUM-CERTIFIED (expected CLASSICAL).
G4  box (ii)            -> CLASSICAL.
G5  box (iii) t = 0.5 delta = 0; t = 0.5 delta = 0.05; t = 0.42
    delta = 0.05        -> EMULATION-SUSPECT in every repetition and at
    every tested N >= 10^4. The module is UNDERMINED if any pre-registered
    emulator configuration is QUANTUM-CERTIFIED even once at N >= 10^4.
G6  MBQC back-end: the mbqc_c5.wl teleportation pattern (2-qubit wire) and
    the 5-qubit linear cluster admit causal flow; the C5 ring admits
    flow/gflow for some (I, O) with |O| = |I| + 1; expected: no gflow for
    any single-output ring pattern (odd-cycle obstruction) -- reported.
G7  DLA hook: the pentagram cascade generators have span 2 and one-step
    DLA dimension 3 (the 2 -> 3 anchor); a single-axis (leaf-confined)
    compilation has DLA < 3 and MUST be flagged intensity-emulable.

ADVERSARIAL CASE, OUTSIDE THE GATES (documented blind spot)
-----------------------------------------------------------
(iii-d) intensity emulator tuned to the exact quantum table t = 1/sqrt(5),
delta = 0. Table-level indistinguishable from box (i) BY CONSTRUCTION: every
certificate in C1-C5 passes and the verdict is QUANTUM-CERTIFIED. This is
the operational content of "the certifying difference is event semantics":
tables do not certify without the single-click premise. The residual
discriminators are (a) the DLA audit of the claimed mode compilation (an
intensity redistribution rig is leaf-confined, DLA < 3 -- flagged by G7's
hook), and (b) hardware-level event semantics (antibunching), outside this
protocol's scope and listed as an open item.

SANITY-FIRST RULE: the exact anchors (CF = 2 sqrt(5) - 4, CF_Wright = 1,
CF_classical = 0, V_crit bracketing, alpha* = 5/2, clique census, pentad
saturation, node sums, DLA 2 -> 3) are recomputed on exact tables before
any finite-sample run; the script ABORTS if any is off.

Run:  python3 mbqc_blackbox_test.py          (full protocol, ~1-2 min)
Deps: numpy, scipy (linprog/HiGHS). Exit code 0 iff anchors pass and every
gate is SUPPORTED.
"""

import json
import sys
from itertools import product

import numpy as np
from scipy.optimize import linprog

SEED = 20260710
SQRT5 = np.sqrt(5.0)
CF_EXACT = 2 * SQRT5 - 4          # 0.4721359549995794
V_CRIT = (5 + 3 * SQRT5) / 20     # 0.5854101966249685
ALPHA = 0.01
ALPHA_ND = ALPHA / 4
ALPHA_CF = ALPHA / 4
ALPHA_CE = ALPHA / 4
ALPHA_NS = ALPHA / 4
S_MIN = 5                          # support threshold, counts
TAU_CLASSICAL = 0.05               # CF_hat threshold for the CLASSICAL call
N_HEADLINE = 10_000
N_REPS = 25
BOOT_B = 300

CTX = [(i, (i + 1) % 5) for i in range(5)]           # the 5 KCBS contexts
SECTIONS = [(0, 0), (0, 1), (1, 0), (1, 1)]          # section order per context


# ----------------------------------------------------------------- scenario --
def incidence_matrix():
    """AB incidence matrix, 20 sections x 32 global assignments."""
    glob = list(product([0, 1], repeat=5))
    M = np.zeros((20, 32))
    for c, (i, j) in enumerate(CTX):
        for s, sec in enumerate(SECTIONS):
            for g, t in enumerate(glob):
                if (t[i], t[j]) == sec:
                    M[4 * c + s, g] = 1.0
    return M, glob


M_INC, GLOBALS = incidence_matrix()


def cycle_coboundary():
    """CycleCoboundary[5] of BlackBox.wl: 10 x 20, ker = no-disturbance models."""
    m1st = np.array([[1, 1, 0, 0], [0, 0, 1, 1]], float)   # marginal of 1st observable
    m2nd = np.array([[1, 0, 1, 0], [0, 1, 0, 1]], float)   # marginal of 2nd observable
    delta = np.zeros((10, 20))
    for i in range(5):
        delta[2 * i:2 * i + 2, 4 * ((i - 1) % 5):4 * ((i - 1) % 5) + 4] += m2nd
        delta[2 * i:2 * i + 2, 4 * i:4 * i + 4] -= m1st
    return delta


DELTA_CB = cycle_coboundary()


def kcbs_vectors():
    """Exact pentagram: cyclically orthogonal unit vectors, cone axis z.
    (l_i . z)^2 = cos(pi/5)/(1+cos(pi/5)) = 1/sqrt(5) exactly."""
    c2 = np.cos(np.pi / 5) / (1 + np.cos(np.pi / 5))
    ct, st = np.sqrt(c2), np.sqrt(1 - c2)
    return [np.array([st * np.cos(4 * np.pi * i / 5),
                      st * np.sin(4 * np.pi * i / 5), ct]) for i in range(5)]


LVEC = kcbs_vectors()
PSI = np.array([0.0, 0.0, 1.0])


# ------------------------------------------------------------- exact tables --
def table_from_edge(p00, p01, p10):
    e = np.zeros(20)
    for c in range(5):
        e[4 * c:4 * c + 4] = [p00, p01, p10, 0.0]
    return e


def table_quantum(V=1.0):
    """rho = V psi + (1-V) I/3 on the exact pentagram contexts."""
    q = V / SQRT5 + (1 - V) / 3
    p00 = V * (1 - 2 / SQRT5) + (1 - V) / 3
    return table_from_edge(p00, q, q)


TABLE_CLASSICAL = table_from_edge(1 / 5, 2 / 5, 2 / 5)   # best NCHV, node sum 2
TABLE_WRIGHT = table_from_edge(0.0, 0.5, 0.5)            # alpha* point, CF = 1


def table_intensity(t, delta=0.0):
    """Divided-beam fractions per context: (f00, f01, f10) = (1-2t, t-delta, t+delta)."""
    return table_from_edge(1 - 2 * t, t - delta, t + delta)


# ------------------------------------------------------------------- boxes --
def sample_table(e, N, rng):
    """Multinomial N clicks per context on table e -> counts (5 x 4)."""
    counts = np.zeros((5, 4), dtype=int)
    for c in range(5):
        p = np.clip(e[4 * c:4 * c + 4], 0, None)
        counts[c] = rng.multinomial(N, p / p.sum())
    return counts


def box_quantum(V, N, rng):
    """Born-rule clicks: per context (i, i+1) a 3-detector measurement in the
    basis {l_i, l_{i+1}, l_i x l_{i+1}}; detector -> section 10 / 01 / 00."""
    counts = np.zeros((5, 4), dtype=int)
    for c, (i, j) in enumerate(CTX):
        a, b = LVEC[i], LVEC[j]
        n = np.cross(a, b)
        n /= np.linalg.norm(n)
        probs = np.array([(a @ PSI) ** 2, (b @ PSI) ** 2, (n @ PSI) ** 2])
        probs = V * probs + (1 - V) / 3
        det = rng.multinomial(N, probs / probs.sum())
        counts[c, 2], counts[c, 1], counts[c, 0] = det[0], det[1], det[2]
    return counts


def box_classical(N, rng):
    """Literal NCHV: each shot draws a hidden pair {k, k+2 mod 5} (weight 1/5
    each) and answers the context deterministically."""
    counts = np.zeros((5, 4), dtype=int)
    for c, (i, j) in enumerate(CTX):
        ks = rng.integers(0, 5, size=N)
        ai = (ks == i) | ((ks + 2) % 5 == i)
        aj = (ks == j) | ((ks + 2) % 5 == j)
        sec = 2 * ai.astype(int) + aj.astype(int)     # index into SECTIONS
        counts[c] = np.bincount(sec, minlength=4)
    return counts


def box_intensity(t, delta, N, rng):
    """Divided classical beam; integrated intensity binned into N pseudo-clicks."""
    return sample_table(table_intensity(t, delta), N, rng)


def box_quantum_misaligned(V, misalign_deg, N, rng):
    """Realistic Lapkiewicz imperfection: the closing context uses l1' rotated
    by misalign_deg from l0 in the plane orthogonal to l4 (kcbs_simulation.py)."""
    u = np.cross(LVEC[4], LVEC[0])
    u /= np.linalg.norm(u)
    d = np.deg2rad(misalign_deg)
    l1p = np.cos(d) * LVEC[0] + np.sin(d) * u
    counts = np.zeros((5, 4), dtype=int)
    for c, (i, j) in enumerate(CTX):
        a = LVEC[i]
        b = l1p if c == 4 else LVEC[j]
        n = np.cross(a, b)
        n /= np.linalg.norm(n)
        probs = np.array([(a @ PSI) ** 2, (b @ PSI) ** 2, (n @ PSI) ** 2])
        probs = V * probs + (1 - V) / 3
        det = rng.multinomial(N, probs / probs.sum())
        counts[c, 2], counts[c, 1], counts[c, 0] = det[0], det[1], det[2]
    return counts


# -------------------------------------------------------- certificate stack --
def ncf_lp(e):
    """Noncontextual fraction: max 1.d s.t. M d <= e, d >= 0 (exact AB LP)."""
    res = linprog(-np.ones(32), A_ub=M_INC, b_ub=e, method="highs")
    if res.status != 0:
        raise RuntimeError(f"NCF LP failed: {res.message}")
    return -res.fun


def cf_of(e):
    return 1.0 - ncf_lp(e)


def marginals(e_hat):
    """Per measurement m: (marginal in context (m-1,m) [2nd slot],
    marginal in context (m,m+1) [1st slot])."""
    out = []
    for m in range(5):
        left = e_hat[4 * ((m - 1) % 5) + 1] + e_hat[4 * ((m - 1) % 5) + 3]
        right = e_hat[4 * m + 2] + e_hat[4 * m + 3]
        out.append((left, right))
    return out


def cert_nd(e_hat, N):
    marg = marginals(e_hat)
    diffs = [abs(l - r) for l, r in marg]
    a1 = ALPHA_ND / 10                       # 5 measurements x 2 estimates
    eps_m = np.sqrt(np.log(2 / a1) / (2 * N))
    return {"max_diff": max(diffs), "threshold": 2 * eps_m,
            "signaling": max(diffs) > 2 * eps_m,
            "residual_l2": float(np.linalg.norm(DELTA_CB @ e_hat))}


def cert_cf(e_hat, N):
    a1 = ALPHA_CF / 20
    eps_h = np.sqrt(np.log(2 / a1) / (2 * N))
    cf_hat = cf_of(e_hat)
    cf_lo = max(0.0, 1.0 - ncf_lp(e_hat + eps_h))
    cf_hi = min(1.0, 1.0 - ncf_lp(np.clip(e_hat - eps_h, 0, None)))
    return {"cf_hat": cf_hat, "cf_lo": cf_lo, "cf_hi": cf_hi, "eps_h": eps_h}


def bootstrap_cf(counts, B, rng):
    N = counts[0].sum()
    vals = np.empty(B)
    for b in range(B):
        e_b = np.zeros(20)
        for c in range(5):
            e_b[4 * c:4 * c + 4] = rng.multinomial(N, counts[c] / N) / N
        vals[b] = cf_of(e_b)
    return {"boot_lo": float(np.percentile(vals, 2.5)),
            "boot_hi": float(np.percentile(vals, 97.5)),
            "boot_mean": float(vals.mean())}


def maximal_cliques(adj_sets):
    """Bron-Kerbosch with pivoting."""
    cliques = []

    def bk(R, P, X):
        if not P and not X:
            cliques.append(sorted(R))
            return
        pivot = max(P | X, key=lambda u: len(P & adj_sets[u]))
        for v in list(P - adj_sets[pivot]):
            bk(R | {v}, P & adj_sets[v], X & adj_sets[v])
            P.remove(v)
            X.add(v)

    bk(set(), set(range(len(adj_sets))), set())
    return cliques


def or_product_cliques():
    """All maximal cliques of C5 OR C5 (vertices (i,j), 0..24)."""
    def adj5(a, b):
        return (a - b) % 5 in (1, 4)

    verts = [(i, j) for i in range(5) for j in range(5)]
    idx = {v: k for k, v in enumerate(verts)}
    adj = [set() for _ in verts]
    for u in verts:
        for v in verts:
            if u != v and (adj5(u[0], v[0]) or adj5(u[1], v[1])):
                adj[idx[u]].add(idx[v])
    cl = maximal_cliques(adj)
    return verts, cl


OR_VERTS, OR_CLIQUES = or_product_cliques()


def event_probs(e_hat):
    """Per-event p_i pooled over the two contexts containing event i."""
    p = np.zeros(5)
    for m in range(5):
        left = e_hat[4 * ((m - 1) % 5) + 1] + e_hat[4 * ((m - 1) % 5) + 3]
        right = e_hat[4 * m + 2] + e_hat[4 * m + 3]
        p[m] = 0.5 * (left + right)
    return p


def cert_ce2(e_hat, N):
    p = event_probs(e_hat)
    a1 = ALPHA_CE / 5
    eps_p = np.sqrt(np.log(2 / a1) / (4 * N))          # pooled over 2N samples
    p_lo, p_hi = np.clip(p - eps_p, 0, None), p + eps_p
    load = lambda q: max(sum(q[i] * q[j] for i, j in (OR_VERTS[k] for k in K))
                         for K in OR_CLIQUES)
    max_load = load(p)
    max_load_lo = load(p_lo)
    max_load_hi = load(p_hi)
    pentads = [K for K in OR_CLIQUES if len(K) == 5]
    pentad_loads = [sum(p[OR_VERTS[k][0]] * p[OR_VERTS[k][1]] for k in K)
                    for K in pentads]
    return {"max_load": max_load, "max_load_lo": max_load_lo,
            "max_load_hi": max_load_hi, "violation": max_load_lo > 1.0,
            "pentad_loads": pentad_loads, "eps_p": eps_p, "p_hat": p.tolist()}


def cert_support(counts):
    """Possibilistic support at threshold S_MIN; AB parity / global-assignment check."""
    supp = [set() for _ in range(5)]
    for c in range(5):
        for s in range(4):
            if counts[c][s] >= S_MIN:
                supp[c].add(SECTIONS[s])
    consistent = 0
    for t in GLOBALS:
        if all((t[i], t[j]) in supp[c] for c, (i, j) in enumerate(CTX)):
            consistent += 1
    one_per_edge = all(s <= {(0, 1), (1, 0)} and s for s in supp)
    return {"support_sizes": [len(s) for s in supp],
            "global_consistent": consistent, "strong": consistent == 0,
            "parity_pattern": one_per_edge}


def cert_node_sum(e_hat, N):
    p = event_probs(e_hat)
    a1 = ALPHA_NS / 5
    eps_p = np.sqrt(np.log(2 / a1) / (4 * N))
    sigma = float(p.sum())
    return {"sigma": sigma, "sigma_lo": sigma - 5 * eps_p,
            "sigma_hi": sigma + 5 * eps_p,
            "supra_quantum": sigma - 5 * eps_p > SQRT5,
            "S_kcbs": 5 - 4 * sigma}


def certificates(counts):
    N = int(counts[0].sum())
    e_hat = np.zeros(20)
    for c in range(5):
        e_hat[4 * c:4 * c + 4] = counts[c] / N
    return {"N": N, "e_hat": e_hat,
            "nd": cert_nd(e_hat, N), "cf": cert_cf(e_hat, N),
            "ce2": cert_ce2(e_hat, N), "support": cert_support(counts),
            "ns": cert_node_sum(e_hat, N)}


# ------------------------------------------------------------------ verdict --
def verdict(cert):
    """Pre-registered order V1-V5 (see module docstring)."""
    reasons = []
    if cert["nd"]["signaling"]:
        reasons.append(f"signaling: max marginal diff {cert['nd']['max_diff']:.4f}"
                       f" > {cert['nd']['threshold']:.4f}")
    if cert["ns"]["supra_quantum"]:
        reasons.append(f"node sum {cert['ns']['sigma']:.4f} - err > sqrt(5)")
    if cert["ce2"]["violation"]:
        reasons.append(f"CE2 violated: clique load >= {cert['ce2']['max_load_lo']:.4f} > 1")
    if cert["support"]["strong"]:
        reasons.append("support admits no global assignment (CF = 1 > quantum max)")
    if reasons:
        return "EMULATION-SUSPECT", reasons
    if cert["cf"]["cf_lo"] > 0:
        return "QUANTUM-CERTIFIED", [f"CF_lo = {cert['cf']['cf_lo']:.4f} > 0, "
                                     "no-disturbance and CE2 clean"]
    if cert["cf"]["cf_hat"] <= TAU_CLASSICAL:
        return "CLASSICAL", [f"CF_hat = {cert['cf']['cf_hat']:.4f} <= {TAU_CLASSICAL}"]
    return "INCONCLUSIVE", [f"CF_hat = {cert['cf']['cf_hat']:.4f}, "
                            f"CF_lo = 0, no flag fired"]


# ------------------------------------------------- MBQC back-end: flow/gflow --
def gf2_solve(A, b):
    """One solution of A x = b over GF(2), or None."""
    A = A.copy().astype(np.int8) % 2
    b = b.copy().astype(np.int8) % 2
    rows, cols = A.shape
    piv = []
    r = 0
    for c in range(cols):
        rr = next((k for k in range(r, rows) if A[k, c]), None)
        if rr is None:
            continue
        A[[r, rr]] = A[[rr, r]]
        b[[r, rr]] = b[[rr, r]]
        for k in range(rows):
            if k != r and A[k, c]:
                A[k] ^= A[r]
                b[k] ^= b[r]
        piv.append(c)
        r += 1
    if any(b[k] and not A[k].any() for k in range(rows)):
        return None
    x = np.zeros(cols, dtype=np.int8)
    for k, c in enumerate(piv):
        x[c] = b[k]
    return x


def gflow(n, adj_sets, inputs, outputs):
    """Mhalla-Perdrix gflow (X-Y plane): correction sets in (corrected set)\\I,
    Odd(g(v)) meets the uncorrected set exactly in {v}. Returns (exists, layers, g)."""
    V = set(range(n))
    O = set(outputs)
    I = set(inputs)
    layers = {v: 0 for v in O}
    k = 1
    g = {}
    while True:
        C = {}
        pool = sorted(O - I)
        rest = sorted(V - O)
        if not rest:
            return True, layers, g
        A = np.array([[1 if u in adj_sets[w] else 0 for w in pool] for u in rest],
                     dtype=np.int8)
        for v in rest:
            bvec = np.array([1 if u == v else 0 for u in rest], dtype=np.int8)
            x = gf2_solve(A, bvec) if pool else None
            if x is not None:
                C[v] = {pool[i] for i in range(len(pool)) if x[i]}
        if not C:
            return False, layers, g
        for v, gv in C.items():
            layers[v] = k
            g[v] = gv
        O |= set(C)
        k += 1


def is_dag(n, edges):
    indeg = {v: 0 for v in range(n)}
    adj = {v: [] for v in range(n)}
    for u, v in edges:
        adj[u].append(v)
        indeg[v] += 1
    stack = [v for v in range(n) if indeg[v] == 0]
    seen = 0
    while stack:
        u = stack.pop()
        seen += 1
        for v in adj[u]:
            indeg[v] -= 1
            if indeg[v] == 0:
                stack.append(v)
    return seen == n


def causal_flow(n, adj_sets, inputs, outputs):
    """Danos-Kashefi causal flow by exhaustive search (tiny graphs):
    f: O^c -> I^c with f(v) ~ v, v < f(v), and v < w for w in N(f(v))\\{v}."""
    measured = [v for v in range(n) if v not in set(outputs)]
    cand = [sorted(adj_sets[v] - set(inputs)) for v in measured]
    for choice in (product(*cand) if measured else [()]):
        f = dict(zip(measured, choice))
        edges = set()
        ok = True
        for v in measured:
            if f[v] == v:
                ok = False
                break
            edges.add((v, f[v]))
            for w in adj_sets[f[v]] - {v}:
                edges.add((v, w))
        if ok and is_dag(n, edges):
            return f
    return None


def graph_adj(n, edge_list):
    adj = [set() for _ in range(n)]
    for u, v in edge_list:
        adj[u].add(v)
        adj[v].add(u)
    return adj


def backend_flow_report():
    rows = []
    # mbqc_c5.wl elementary pattern: 2-qubit wire, measure qubit 0 in X
    adj = graph_adj(2, [(0, 1)])
    f = causal_flow(2, adj, [0], [1])
    gf, _, _ = gflow(2, adj, [0], [1])
    rows.append(("P2 wire (mbqc_c5.wl pattern), I={0}, O={1}", f is not None, gf))
    # 5-qubit linear cluster
    adj = graph_adj(5, [(0, 1), (1, 2), (2, 3), (3, 4)])
    f = causal_flow(5, adj, [0], [4])
    gf, _, _ = gflow(5, adj, [0], [4])
    rows.append(("P5 linear cluster, I={0}, O={4}", f is not None, gf))
    # C5 ring configurations
    ring = graph_adj(5, [(i, (i + 1) % 5) for i in range(5)])
    for I, O, label in [([0], [4], "C5 ring, I={0}, O={4}"),
                        ([0], [2], "C5 ring, I={0}, O={2}"),
                        ([0], [3, 4], "C5 ring, I={0}, O={3,4}"),
                        ([], [3, 4], "C5 ring, I={}, O={3,4}")]:
        f = causal_flow(5, ring, I, O)
        gf, _, _ = gflow(5, ring, I, O)
        rows.append((label, f is not None, gf))
    return rows


# --------------------------------------------------- MBQC back-end: DLA hook --
def rot_log(R):
    """Principal log of a 3x3 rotation (Rodrigues); antisymmetric result."""
    theta = np.arccos(np.clip((np.trace(R) - 1) / 2, -1.0, 1.0))
    if theta < 1e-12:
        return np.zeros((3, 3))
    return (R - R.T) * (theta / (2 * np.sin(theta)))


def vee(A):
    return np.array([A[2, 1], A[0, 2], A[1, 0]])


def cascade_generators():
    """The four so(3) stage generators of the Lapkiewicz cascade
    (CascadeGenerators[] of BlackBox.wl): logs of stage-frame transitions."""
    def frame(a, b):
        return np.stack([a, b, np.cross(a, b)])

    v = LVEC
    sf = [frame(v[0], v[1]), frame(v[2], v[1]), frame(v[2], v[3]),
          frame(v[4], v[3]), frame(v[4], v[0])]
    return [rot_log(sf[k + 1] @ sf[k].T) for k in range(4)]


def dla_dimension(gens):
    """Rank of generator axes + all pairwise commutator axes (one step)."""
    axes = [vee(g) for g in gens]
    comms = [vee(gens[i] @ gens[j] - gens[j] @ gens[i])
             for i in range(len(gens)) for j in range(i + 1, len(gens))]
    span = np.linalg.matrix_rank(np.array(axes), tol=1e-8)
    dla = np.linalg.matrix_rank(np.array(axes + comms), tol=1e-8)
    return int(span), int(dla)


def dla_hook(gens):
    """Audit of a claimed mode compilation: DLA < 3 => leaf-confined =>
    intensity-emulable flag (in so(3) the only proper subalgebras are
    1-dimensional: leaf-confined <=> a single common rotation axis)."""
    span, dla = dla_dimension(gens)
    return {"span": span, "dla": dla, "leaf_confined": dla < 3,
            "intensity_emulable_flag": dla < 3}


# ------------------------------------------------------------ exact anchors --
def run_exact_anchors():
    print("=" * 78)
    print("EXACT ANCHORS (sanity first -- abort if any is off)")
    print("=" * 78)
    checks = []

    cfq = cf_of(table_quantum(1.0))
    checks.append(("CF(quantum V=1) = 2 sqrt(5) - 4", abs(cfq - CF_EXACT) < 1e-7,
                   f"{cfq:.10f} vs {CF_EXACT:.10f}"))
    cfc = cf_of(TABLE_CLASSICAL)
    checks.append(("CF(classical) = 0", abs(cfc) < 1e-8, f"{cfc:.2e}"))
    cfw = cf_of(TABLE_WRIGHT)
    checks.append(("CF(Wright) = 1", abs(cfw - 1) < 1e-8, f"{cfw:.10f}"))

    cf_above = cf_of(table_quantum(V_CRIT + 1e-4))
    cf_below = cf_of(table_quantum(V_CRIT - 1e-4))
    checks.append(("V_crit brackets CF = 0", cf_above > 1e-6 and cf_below < 1e-8,
                   f"CF(V_crit+1e-4) = {cf_above:.2e}, CF(V_crit-1e-4) = {cf_below:.2e}"))
    cfr = cf_of(table_quantum(0.977))
    cf977 = 1 - 5 * (0.977 * (1 - 2 / SQRT5) + 0.023 / 3)
    checks.append(("CF(V=0.977) = 1 - 5 p00(V) (primal/dual form)",
                   abs(cfr - cf977) < 1e-8, f"{cfr:.7f} vs {cf977:.7f}"))

    res = linprog(-np.ones(5), A_ub=np.array([[1 if k in e else 0 for k in range(5)]
                                              for e in CTX], float),
                  b_ub=np.ones(5), bounds=[(0, 1)] * 5, method="highs")
    checks.append(("alpha*(C5) = 5/2", abs(-res.fun - 2.5) < 1e-9, f"{-res.fun:.6f}"))

    census = {}
    for K in OR_CLIQUES:
        census[len(K)] = census.get(len(K), 0) + 1
    checks.append(("CE2 clique census {4: 525, 5: 10}",
                   census == {4: 525, 5: 10}, str(census)))

    q = np.full(5, 1 / SQRT5)
    pl = [sum(q[OR_VERTS[k][0]] * q[OR_VERTS[k][1]] for k in K)
          for K in OR_CLIQUES if len(K) == 5]
    checks.append(("quantum saturates all ten pentads at 1",
                   len(pl) == 10 and all(abs(x - 1) < 1e-12 for x in pl),
                   f"loads = {sorted(set(round(float(x), 12) for x in pl))}"))
    wl = max(sum(0.25 for _ in K) for K in OR_CLIQUES if len(K) == 5)
    checks.append(("Wright pentad load = 5/4", abs(wl - 1.25) < 1e-12, f"{wl}"))

    sig_q = float(event_probs(table_quantum(1.0)).sum())
    sig_c = float(event_probs(TABLE_CLASSICAL).sum())
    sig_w = float(event_probs(TABLE_WRIGHT).sum())
    checks.append(("node sums (sqrt5, 2, 5/2)",
                   abs(sig_q - SQRT5) < 1e-9 and abs(sig_c - 2) < 1e-12
                   and abs(sig_w - 2.5) < 1e-12,
                   f"{sig_q:.6f}, {sig_c:.6f}, {sig_w:.6f}"))

    span, dla = dla_dimension(cascade_generators())
    checks.append(("cascade DLA anchor: span 2 -> dim 3", (span, dla) == (2, 3),
                   f"span = {span}, DLA = {dla}"))

    nd_exact = cert_nd(table_quantum(0.977), 10 ** 9)
    checks.append(("exact tables are no-disturbance (residual 0)",
                   nd_exact["residual_l2"] < 1e-12,
                   f"residual = {nd_exact['residual_l2']:.2e}"))

    ok = True
    for name, passed, detail in checks:
        print(f"  [{'PASS' if passed else 'FAIL'}] {name:52s} {detail}")
        ok &= passed
    if not ok:
        print("ANCHOR FAILURE -- aborting before any finite-sample run.")
        sys.exit(1)
    print(f"  all {len(checks)} anchors pass.")
    return {"cf_exact": cfq, "cf_977": cfr, "v_crit": V_CRIT}


# -------------------------------------------------------------- experiments --
BOXES = {
    "(i-a)  quantum V=1.000": lambda N, rng: box_quantum(1.0, N, rng),
    "(i-b)  quantum V=0.977": lambda N, rng: box_quantum(0.977, N, rng),
    "(i-c)  quantum V=0.550": lambda N, rng: box_quantum(0.550, N, rng),
    "(i-d)  quantum V=V_crit": lambda N, rng: box_quantum(V_CRIT, N, rng),
    "(ii)   classical NCHV": lambda N, rng: box_classical(N, rng),
    "(iii-a) intensity t=0.50 d=0.00": lambda N, rng: box_intensity(0.5, 0.0, N, rng),
    "(iii-b) intensity t=0.50 d=0.05": lambda N, rng: box_intensity(0.5, 0.05, N, rng),
    "(iii-c) intensity t=0.42 d=0.05": lambda N, rng: box_intensity(0.42, 0.05, N, rng),
    "(iii-d) intensity t=1/sqrt5 d=0 [ADVERSARIAL]":
        lambda N, rng: box_intensity(1 / SQRT5, 0.0, N, rng),
}

EXPECTED = {
    "(i-a)  quantum V=1.000": "QUANTUM-CERTIFIED",
    "(i-b)  quantum V=0.977": "QUANTUM-CERTIFIED",
    "(i-c)  quantum V=0.550": "NOT-QUANTUM",
    "(ii)   classical NCHV": "CLASSICAL",
    "(iii-a) intensity t=0.50 d=0.00": "EMULATION-SUSPECT",
    "(iii-b) intensity t=0.50 d=0.05": "EMULATION-SUSPECT",
    "(iii-c) intensity t=0.42 d=0.05": "EMULATION-SUSPECT",
}


def headline_runs(rng):
    print()
    print("=" * 78)
    print(f"HEADLINE RUNS  (N = {N_HEADLINE} clicks/context, single run + bootstrap)")
    print("=" * 78)
    results = {}
    for name, box in BOXES.items():
        counts = box(N_HEADLINE, rng)
        cert = certificates(counts)
        v, reasons = verdict(cert)
        boot = bootstrap_cf(counts, BOOT_B, rng)
        results[name] = {"verdict": v, "cert": cert, "boot": boot}
        cf, nd, ce, ns, sup = (cert["cf"], cert["nd"], cert["ce2"],
                               cert["ns"], cert["support"])
        print(f"\n  {name}")
        print(f"    node sum Sigma = {ns['sigma']:.4f}  in [{ns['sigma_lo']:.4f}, "
              f"{ns['sigma_hi']:.4f}]   bounds: 2 | {SQRT5:.4f} | 2.5   "
              f"S_KCBS = {ns['S_kcbs']:.4f}")
        print(f"    ND: max marginal diff = {nd['max_diff']:.4f} "
              f"(thr {nd['threshold']:.4f}), residual = {nd['residual_l2']:.4f}"
              f"  -> {'SIGNALING' if nd['signaling'] else 'ok'}")
        print(f"    CF_hat = {cf['cf_hat']:.4f}   Hoeffding [{cf['cf_lo']:.4f}, "
              f"{cf['cf_hi']:.4f}]   bootstrap 95% [{boot['boot_lo']:.4f}, "
              f"{boot['boot_hi']:.4f}]")
        print(f"    CE2: max clique load = {ce['max_load']:.4f} "
              f"[{ce['max_load_lo']:.4f}, {ce['max_load_hi']:.4f}]"
              f"  -> {'VIOLATION' if ce['violation'] else 'no certified violation'}")
        print(f"    support sizes = {sup['support_sizes']}, "
              f"consistent globals = {sup['global_consistent']}"
              f"{' (parity pattern!)' if sup['parity_pattern'] else ''}"
              f"  -> {'STRONG' if sup['strong'] else 'ok'}")
        print(f"    VERDICT: {v}   ({'; '.join(reasons)})")
    return results


def repetition_study(rng):
    print()
    print("=" * 78)
    print(f"REPETITION STABILITY  (R = {N_REPS} at N = {N_HEADLINE}; "
          f"gate = expected verdict in >= 95% of reps)")
    print("=" * 78)
    gate_rows = []
    for name, box in BOXES.items():
        if name not in EXPECTED:
            continue
        tally = {}
        for _ in range(N_REPS):
            v, _ = verdict(certificates(box(N_HEADLINE, rng)))
            tally[v] = tally.get(v, 0) + 1
        exp = EXPECTED[name]
        if exp == "NOT-QUANTUM":
            hits = N_REPS - tally.get("QUANTUM-CERTIFIED", 0)
        else:
            hits = tally.get(exp, 0)
        rate = hits / N_REPS
        gate_rows.append((name, exp, tally, rate, rate >= 0.95))
        print(f"  {name:36s} expect {exp:18s} got {tally}   rate {rate:.2f} "
              f"{'PASS' if rate >= 0.95 else 'FAIL'}")
    return gate_rows


def emulator_large_n(rng):
    """G5 UNDERMINED clause: emulator configs must never certify at N >= 10^4."""
    print()
    print("=" * 78)
    print("EMULATOR AT LARGER N (UNDERMINED clause: any QUANTUM-CERTIFIED fails G5)")
    print("=" * 78)
    ok = True
    for name in ["(iii-a) intensity t=0.50 d=0.00", "(iii-b) intensity t=0.50 d=0.05",
                 "(iii-c) intensity t=0.42 d=0.05"]:
        for N in (10_000, 100_000):
            v, _ = verdict(certificates(BOXES[name](N, rng)))
            print(f"  {name:36s} N = {N:7d} -> {v}")
            ok &= (v != "QUANTUM-CERTIFIED")
    return ok


def sample_complexity(rng):
    print()
    print("=" * 78)
    print(f"SAMPLE COMPLEXITY  (R = {N_REPS} reps/point; certification = "
          f"QUANTUM-CERTIFIED; N* = min N with rate >= 0.95)")
    print("=" * 78)
    grid = [100, 250, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000,
            8000, 16000, 32000]
    out = {}
    for V, label in [(1.0, "V=1.000"), (0.977, "V=0.977")]:
        rates = []
        for N in grid:
            hits = 0
            for _ in range(N_REPS):
                v, _ = verdict(certificates(box_quantum(V, N, rng)))
                hits += (v == "QUANTUM-CERTIFIED")
            rates.append(hits / N_REPS)
        nstar = next((N for N, r in zip(grid, rates) if r >= 0.95), None)
        out[label] = {"grid": grid, "rates": rates, "N_star": nstar}
        print(f"  {label}:  " + "  ".join(f"{N}:{r:.2f}" for N, r in zip(grid, rates)))
        print(f"           N* = {nstar}")
    return out


def misalignment_demo(rng):
    print()
    print("=" * 78)
    print("NON-GATING DEMO: realistic Lapkiewicz imperfection (V = 0.977, "
          "closing context misaligned 1 deg)")
    print("=" * 78)
    for N in (10_000, 1_000_000):
        cert = certificates(box_quantum_misaligned(0.977, 1.0, N, rng))
        v, reasons = verdict(cert)
        nd = cert["nd"]
        print(f"  N = {N:8d}: max marginal diff = {nd['max_diff']:.4f} "
              f"(thr {nd['threshold']:.4f})  S = {cert['ns']['S_kcbs']:.4f}  -> {v}")
    print("  Reading: at N = 10^6 the protocol detects the A1/A1' mismatch as a")
    print("  signaling artifact -- precisely the imperfection the Lapkiewicz")
    print("  epsilon-corrected bound (eps ~ 0.013) exists to absorb. The black-box")
    print("  gate stays honest: such data must be analyzed with the corrected")
    print("  bound, outside this protocol's no-disturbance regime.")


def backend_report():
    print()
    print("=" * 78)
    print("MBQC BACK-END: causal flow / gflow (Danos-Kashefi; Browne et al.)")
    print("=" * 78)
    rows = backend_flow_report()
    for label, has_flow, has_gflow in rows:
        print(f"  {label:44s} flow: {'YES' if has_flow else 'no ':4s} "
              f"gflow: {'YES' if has_gflow else 'no'}")
    print()
    print("  DLA hook (claimed mode compilations, so(3) stage generators):")
    pent = dla_hook(cascade_generators())
    print(f"    pentagram cascade: span = {pent['span']}, DLA = {pent['dla']}"
          f"  -> {'LEAF-CONFINED' if pent['leaf_confined'] else 'not leaf-confined'}"
          f" (2 -> 3 anchor)")
    Lz = np.array([[0., -1, 0], [1, 0, 0], [0, 0, 0]])
    single = dla_hook([0.3 * Lz, 0.7 * Lz, 1.1 * Lz, 0.5 * Lz])
    print(f"    single-axis compilation: span = {single['span']}, DLA = {single['dla']}"
          f"  -> {'INTENSITY-EMULABLE flag' if single['intensity_emulable_flag'] else 'ok'}")
    return rows, pent, single


# --------------------------------------------------------------------- main --
def main():
    rng = np.random.default_rng(SEED)
    anchors = run_exact_anchors()
    headline = headline_runs(rng)
    gate_rows = repetition_study(rng)
    g5_large_ok = emulator_large_n(rng)
    sc = sample_complexity(rng)
    misalignment_demo(rng)
    flow_rows, dla_pent, dla_single = backend_report()

    print()
    print("=" * 78)
    print("PRE-REGISTERED GATE OUTCOMES")
    print("=" * 78)
    gates = {}
    for name, exp, tally, rate, passed in gate_rows:
        key = {"(i-a)": "G1", "(i-b)": "G2", "(i-c)": "G3", "(ii) ": "G4"}.get(
            name[:5], "G5")
        gates.setdefault(key, []).append(passed)
    g_results = {
        "G1 quantum V=1.000 certifies": all(gates.get("G1", [False])),
        "G2 quantum V=0.977 certifies": all(gates.get("G2", [False])),
        "G3 quantum V=0.550 not certified": all(gates.get("G3", [False])),
        "G4 classical box lands CLASSICAL": all(gates.get("G4", [False])),
        "G5 emulator configs all EMULATION-SUSPECT (incl. N=10^5)":
            all(gates.get("G5", [False])) and g5_large_ok,
        "G6 wire+P5 flow exist; ring 1-in/2-out usable; ring |O|=1 has no gflow":
            (flow_rows[0][1] and flow_rows[1][1] and flow_rows[4][1]
             and flow_rows[4][2] and not flow_rows[2][2] and not flow_rows[3][2]),
        "G7 DLA anchor 2->3 and leaf-confined flag":
            (dla_pent["span"], dla_pent["dla"]) == (2, 3)
            and dla_single["intensity_emulable_flag"],
    }
    all_ok = True
    for k, v in g_results.items():
        print(f"  [{'SUPPORTED' if v else 'UNDERMINED'}] {k}")
        all_ok &= v

    summary = {
        "seed": SEED, "N_headline": N_HEADLINE, "reps": N_REPS,
        "anchors": {"CF_exact": anchors["cf_exact"], "CF_0.977": anchors["cf_977"],
                    "V_crit": anchors["v_crit"]},
        "verdicts": {k: v["verdict"] for k, v in headline.items()},
        "cf_headline": {k: {"hat": round(v["cert"]["cf"]["cf_hat"], 6),
                            "lo": round(v["cert"]["cf"]["cf_lo"], 6),
                            "hi": round(v["cert"]["cf"]["cf_hi"], 6),
                            "boot": [round(v["boot"]["boot_lo"], 6),
                                     round(v["boot"]["boot_hi"], 6)]}
                        for k, v in headline.items()},
        "sample_complexity": {k: v["N_star"] for k, v in sc.items()},
        "gates": {k: bool(v) for k, v in g_results.items()},
        "flow": [(r[0], r[1], r[2]) for r in flow_rows],
        "dla": {"cascade": dla_pent, "single_axis": dla_single},
        "all_gates_supported": bool(all_ok),
    }
    print()
    print("MACHINE-READABLE SUMMARY")
    print(json.dumps(summary, indent=1, default=str))
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
