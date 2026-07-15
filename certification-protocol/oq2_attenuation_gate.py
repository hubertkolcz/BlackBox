# -*- coding: utf-8 -*-
"""
oq2_attenuation_gate.py -- OQ2 / gate G8: attenuation-series binomial-
consistency test (PROPOSITION-O3.md, OQ2; normative spec
OQ-PROBE-SPEC-2026-07-13.md Part II; pilot oq_probe_pilot_2026-07-13.py).

Standalone Phase-2 deliverable. `cert_g8` / `gate_g8` are structured so they
can later be merged into mbqc_blackbox_test.py unchanged (helpers below are
verbatim copies from that file, per spec Part III rule 3; that file is NOT
modified here).

WHAT G8 ADDS
------------
Proposition 1 (BBT-002): from per-context tables alone, the tuned intensity
emulator (iii-d) is exactly indistinguishable from the quantum box -- every
gate C1-C5 certifies it. G8 drops assumption A2 (unverified event semantics)
by statistics-only means, adding only A2': the tester inserts a calibrated
attenuator (transmission eta) in front of the box's detectors and draws eta
i.i.d. per trial from the pre-registered grid, recording eta per trial.
(Simulation note: sampling is realized as N_G8 trials per (context, eta) --
exactly the conditional law of the i.i.d.-eta experiment given the per-cell
trial counts; the per-trial randomization is the physical mechanism that
makes the forger's report map eta-blind, via data processing.)

Scaling laws (arXiv:2601.13869 setting): an on-off detector with input
photon-number distribution P(n) has no-click probability
Q(eta) = sum_n P(n)(1-eta)^n. Fock-1: Q = 1 - eta (exactly linear; binomial
thinning). Coherent mean mu: Q = e^(-eta mu) (strictly log-linear, click
rate concave). General classical light: Q completely monotone / log-convex.

TEST STATISTIC (loss-robust identity)
-------------------------------------
For contexts c = 0..4, outcomes s in {00, 01, 10, null}, grid points j >= 2:

    D[c,s,j] = | q_hat[c,s](eta_j) - eta_j q_hat[c,s](1) - (1-eta_j)*[s==null] |

Identity: a binomial (single-photon) device with ANY intrinsic efficiency
1 - z has q_s(eta) = eta (1-z) p_s and q_null(eta) = 1 - eta (1-z), so
D == 0 in expectation for EVERY z: quantum boxes at every visibility V pass
with no external anchor (the statistic is anchored to the box's OWN eta = 1
arm), and so does the classical NCHV box (legitimate single-photon
semantics). The Poissonian forger's rates 1 - e^(-eta mu) are concave in
eta and cannot be linearized by any eta-blind stochastic report map without
leaving the anchored operating window (pilot LP, below).

PRE-REGISTERED PARAMETERS (all fixed before sampling)
-----------------------------------------------------
  grid       J = 8, etas = (1.0, 0.85, 0.70, 0.55, 0.40, 0.25, 0.12, 0.05)
  samples    N_G8 = 10^6 per (context, eta)  => 4e7 trials per box per rep
  budget     alpha_G8 = 0.01 (new budget, separate from C1-C5's alpha);
             m = 5 x 4 x 7 = 140 comparisons, two empirical means each:
             a' = alpha_G8 / (2*140); eps = sqrt(ln(2/a') / (2 N_G8))
             = 2.338e-3; per-comparison threshold t[j] = eps (1 + eta_j);
             t_max = eps * 1.85 = 4.33e-3
  G8b flag   any D[c,s,j] > t[j]  (semantics violation)
  G8a range  min-over-contexts total reported click rate at eta = 1 must be
             >= 1 - z_max - eps, z_max = 0.20; else OUT-OF-RANGE (distinct
             outcome, not a pass)
  JOINT gate the eta = 1 arm (click outcomes, renormalized) of the SAME data
             is fed through the C1-C5 stack; an unanchored scaling test is
             exactly forgeable (pilot: Delta = 0, e.g. the all-null map)
  reps       R = 25; a row passes iff its expected outcome occurs in >= 95%
             of reps; UNDERMINED (G5-style) if any forger rep is in-range
             AND unflagged even once
  seeds      sampling rng 20260712 (single stream: headline pass first,
             then reps outer loop, boxes in matrix order, contexts 0..4,
             eta descending, one draw per (c, eta)); DE minimax seed
             20260712 (reproduction), 20260714 (global-anchor scan);
             F0's fsolve is deterministic (no seed)

ADVERSARY MODEL AND THE MINIMAX PILOT (runs before sampling, ships here)
------------------------------------------------------------------------
Forger: classical intensities mu_d >= 0 on the 3 detectors of a context,
independent Poissonian clicks 1 - e^(-eta mu_d), plus an eta-blind
stochastic report map g: {0,1}^3 -> {00, 01, 10, null} (8x4, rows sum to 1);
fabrication (clicks reported on raw pattern 000) is ALLOWED. Inner problem
(best g and declared loss z for fixed mu) is an LP; outer problem is
differential evolution over log mu. Reference values reproduced here before
any sampling (abort otherwise): Delta_min = 0.041309 (exact anchor,
z_max = 0.20), 0.026413 (anchor slack 0.005), 0.014881 (slack 0.01); all
>= 3 t_max = 0.0130. Remaining pilot item executed here: the GLOBAL anchor
scan over all certifiable quantum tables table_quantum(V), V in
[V_crit, 1] (9-point grid) with slack delta_a = 0.005 (the pre-registered
"delta_a ball"); kill criterion Delta_min_global < 0.015 => do NOT sample,
exit 2 and escalate (J = 16 grid, then z_max = 0.10, then no-fabrication).

EXECUTOR NOTES (resolutions of two spec under-determinations, both fixed
BEFORE any sampling; flagged as findings for the spec's author)
------------------------------------------------------------------------
1. F0 (iii-d physicalized, untuned): the spec's 3-dim root find "reported
   conditional-on-click table at eta = 1 equals the quantum row" is RANK-2
   (the three residuals sum to 0): solutions form a 1-parameter family
   parametrized by the eta = 1 null rate z in (0, 1). fsolve from
   x0 = -ln(1-p) lands at z = 0.311 > z_max -- that F0 would be
   OUT-OF-RANGE on G8a, contradicting the pre-registered matrix row
   "F0 in-range: yes". Pre-registered closure adopted here: pin the eta = 1
   reported table to (1 - z0) * p with z0 = 0.10 (mid operating range);
   the root find is then well-posed (fsolve, x0 = -ln(1-p), ier = 1) and
   F0 keeps conditional-on-click = quantum row exactly. Exact deviation
   D_max = 0.2419 ~ 56 t_max.
2. certificates() on the eta = 1 arm: click totals are stochastic per
   context, while mbqc_blackbox_test.certificates assumes equal N per
   context. The cert stack (cert_nd/cf/ce2/support/node-sum + verdict) is
   copied VERBATIM and consumed unchanged; only the empirical-table
   assembly differs: e_hat rows are normalized per context and the
   Hoeffding N is min over contexts of the click total (conservative).
3. Expected outcomes for FORGER rows are auto-derived from their EXACT
   constructions before any sampling (report law and eta = 1 arm table are
   analytic): expected G8a from the exact click rate, expected G8b from the
   exact deviation vs t_max, expected eta = 1-arm verdict from the verbatim
   cert stack evaluated on the exact table at the expected arm N. Finding
   surfaced by this derivation: the slack-0.005 minimax solution is NOT an
   admissible adversary -- its LP freedom is spent partly outside the joint
   gate's feasible set (exact click rate 0.785 < 1 - z_max - eps => OUT-OF-
   RANGE on G8a, and its exact table has node sum 2.2470 > sqrt(5) =>
   EMULATION-SUSPECT via C5). The effective floor for fully admissible
   forgers is therefore the exact-anchor value 0.0413, not 0.0264.

PRE-REGISTERED PASS/FAIL MATRIX (R = 25)
----------------------------------------
  box                        G8a        G8b expected     eta=1 arm C1-C5
  quantum V = 1.000          in-range   pass (no flag)   QUANTUM-CERTIFIED
  quantum V = 0.977          in-range   pass             QUANTUM-CERTIFIED
  quantum V = 0.550          in-range   pass             CLASSICAL
  quantum V = V_crit         in-range   pass             (edge, reported)
  classical NCHV             in-range   pass             CLASSICAL
  F0 forger (iii-d, untuned) in-range   FLAG every rep   QUANTUM-CERTIFIED
  F* minimax (exact anchor)  in-range   FLAG every rep   QUANTUM-CERTIFIED
  F* minimax (slack 0.005)   [auto-derived from exact construction: OUT-OF-
                              RANGE on G8a; arm EMULATION-SUSPECT via C5]

Run:  python3 oq2_attenuation_gate.py     (~10-15 min local; no cloud, no WL)
Deps: numpy, scipy. Exit 0 iff anchors + reproduction pass, global pilot
VALIDATED, and gate G8 SUPPORTED; exit 2 if the pilot kill criterion fires.
"""

import json
import sys
from itertools import product

import numpy as np
from scipy.optimize import differential_evolution, fsolve, linprog

# ------------------------------------------------------- G8 pre-registration --
SEED_G8 = 20260712            # all G8 sampling
SEED_DE_MAIN = 20260712       # minimax reproduction (matches pilot)
SEED_DE_GLOBAL = 20260714     # global-anchor scan
ETAS = [1.0, 0.85, 0.70, 0.55, 0.40, 0.25, 0.12, 0.05]   # J = 8, descending
J = len(ETAS)
N_G8 = 1_000_000
ALPHA_G8 = 0.01
M_COMP = 5 * 4 * (J - 1)                                  # 140
A_PRIME = ALPHA_G8 / (2 * M_COMP)                         # 3.5714e-5
EPS_G8 = float(np.sqrt(np.log(2 / A_PRIME) / (2 * N_G8)))  # 2.338e-3
T_MAX = EPS_G8 * (1 + ETAS[1])                            # 4.33e-3
Z_MAX = 0.20
R_REPS = 25
Z0_F0 = 0.10                  # executor note 1: F0 closure (eta=1 null rate)
DELTA_A_FSTAR = 0.005         # F* slack instance (II.5 realistic anchor slack)
KILL_FLOOR = 0.015            # global-pilot kill criterion (II.6)
V_GRID_GLOBAL = 9             # anchor scan: linspace(V_crit, 1, 9)
DE_KW_MAIN = dict(maxiter=80, popsize=14, tol=1e-10, polish=True)
DE_KW_SCAN = dict(maxiter=40, popsize=14, tol=1e-10, polish=True)  # scan budget

RAWS = list(product([0, 1], repeat=3))
I000 = RAWS.index((0, 0, 0))

# ================================================================ verbatim ====
# Helpers copied VERBATIM from mbqc_blackbox_test.py (spec Part III rule 3).
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

CTX = [(i, (i + 1) % 5) for i in range(5)]           # the 5 KCBS contexts
SECTIONS = [(0, 0), (0, 1), (1, 0), (1, 1)]          # section order per context


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


def verdict(cert):
    """Pre-registered order V1-V5 (see mbqc_blackbox_test.py docstring)."""
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
# ============================================================ end verbatim ====


P_QUANTUM = table_quantum(1.0)[0:3].copy()   # (p00, p01, p10) = (1-2/sqrt5, 1/sqrt5, 1/sqrt5)


def certificates_clicks(counts4):
    """C1-C5 on the eta=1 click arm (executor note 2): e_hat rows normalized
    per context, Hoeffding N = min over contexts of the click total; the
    verbatim cert stack + verdict are consumed unchanged."""
    counts4 = np.asarray(counts4)
    N = int(counts4.sum(axis=1).min())
    e_hat = np.zeros(20)
    for c in range(5):
        e_hat[4 * c:4 * c + 4] = counts4[c] / counts4[c].sum()
    return {"N": N, "e_hat": e_hat,
            "nd": cert_nd(e_hat, N), "cf": cert_cf(e_hat, N),
            "ce2": cert_ce2(e_hat, N), "support": cert_support(counts4),
            "ns": cert_node_sum(e_hat, N)}


# ------------------------------------------------------------ forger physics --
def raw_probs(mu, eta):
    """P_eta(r), r in {0,1}^3: independent Poissonian on-off clicks."""
    q = np.exp(-eta * np.asarray(mu))
    P = np.empty(8)
    for ri, r in enumerate(RAWS):
        pr = 1.0
        for d in range(3):
            pr *= (1 - q[d]) if r[d] else q[d]
        P[ri] = pr
    return P


def report_probs(mu, g, eta):
    """Exact reported-outcome law of a forger (mu, g) at attenuation eta."""
    return raw_probs(mu, eta) @ g


def lp_anchored(mu, etas, p_row=None, zmax=Z_MAX, delta_a=0.0, nofab=False,
                want_solution=False):
    """Best eta-blind stochastic report map for fixed mu (pilot II.6 LP):
    min over (g, z) of max_{j>=2, s} |q_s(eta_j) - eta_j q_s(1) - (1-eta_j)[s=null]|
    s.t. anchor |q_s(1) - (1-z) p_s| <= delta_a, 0 <= z <= zmax, g stochastic.
    Variables: g (8x4 = 32), z, t. Identical math to the pilot's lp_anchored,
    generalized to an arbitrary anchor row p_row and optional solution return."""
    if p_row is None:
        p_row = P_QUANTUM
    nv, IZ, IT = 34, 32, 33
    Pc = {e: raw_probs(mu, e) for e in etas}
    P1 = Pc[etas[0]]
    A_eq, b_eq = [], []
    for ri in range(8):
        c = np.zeros(nv)
        c[ri * 4:ri * 4 + 4] = 1.0
        A_eq.append(c)
        b_eq.append(1.0)
    A_ub, b_ub = [], []
    for s in range(3):  # anchor
        c = np.zeros(nv)
        for ri in range(8):
            c[ri * 4 + s] = P1[ri]
        c[IZ] = p_row[s]
        if delta_a == 0.0:
            A_eq.append(c)
            b_eq.append(p_row[s])
        else:
            A_ub.append(c.copy())
            b_ub.append(p_row[s] + delta_a)
            A_ub.append(-c)
            b_ub.append(-(p_row[s] - delta_a))
    for eta in etas[1:]:
        Pe = Pc[eta]
        for s in range(4):
            c = np.zeros(nv)
            if s == 3:
                for ri in range(8):
                    c[ri * 4 + 3] = Pe[ri]
                c[IZ] = -eta
                rhs = 1.0 - eta
            else:
                for ri in range(8):
                    c[ri * 4 + s] = Pe[ri] - eta * P1[ri]
                rhs = 0.0
            c1 = c.copy()
            c1[IT] = -1.0
            A_ub.append(c1)
            b_ub.append(rhs)
            c2 = -c.copy()
            c2[IT] = -1.0
            A_ub.append(c2)
            b_ub.append(-rhs)
    bounds = [(0, 1)] * 32 + [(0, zmax), (0, None)]
    if nofab:
        for s in range(3):
            bounds[I000 * 4 + s] = (0, 0)
    cv = np.zeros(nv)
    cv[IT] = 1.0
    res = linprog(cv, A_ub=np.array(A_ub), b_ub=np.array(b_ub),
                  A_eq=np.array(A_eq), b_eq=np.array(b_eq),
                  bounds=bounds, method="highs")
    if res.status != 0:
        return (np.inf, None, None) if want_solution else np.inf
    if not want_solution:
        return res.fun
    g = np.clip(res.x[:32].reshape(8, 4), 0, None)
    g /= g.sum(axis=1, keepdims=True)
    return res.fun, g, float(res.x[32])


def minimax(etas, seed, p_row=None, de_kw=None, **kw):
    """Outer DE over log mu (pilot II.6); returns (Delta_min, mu*, g*, z*)."""
    de_kw = DE_KW_MAIN if de_kw is None else de_kw
    res = differential_evolution(
        lambda x: lp_anchored(np.exp(x), etas, p_row=p_row, **kw),
        [(-3, 3.5)] * 3, seed=seed, **de_kw)
    mu = np.exp(res.x)
    val, g, z = lp_anchored(mu, etas, p_row=p_row, want_solution=True, **kw)
    return res.fun, mu, g, z


def f0_construct():
    """F0 = iii-d physicalized, untuned (spec II.3b + executor note 1):
    deterministic report map 'null if no raw click, else lowest-index clicked
    detector' (detector order = section order: d0 -> 00, d1 -> 01, d2 -> 10);
    mu from fsolve, x0 = -ln(1-p), pinned so the eta = 1 reported table is
    (1 - z0) p with z0 = 0.10 (closure of the rank-2 conditional system)."""
    g = np.zeros((8, 4))
    for ri, r in enumerate(RAWS):
        g[ri, 3 if sum(r) == 0 else r.index(1)] = 1.0

    def rep1(mu):
        return raw_probs(mu, 1.0) @ g

    F = lambda mu: rep1(mu)[:3] - (1 - Z0_F0) * P_QUANTUM
    x0 = -np.log(1 - P_QUANTUM)
    sol, info, ier, msg = fsolve(F, x0, full_output=True)
    assert ier == 1 and np.max(np.abs(F(sol))) < 1e-10, f"F0 fsolve: {msg}"
    return np.asarray(sol), g


def exact_deviation(mu, g, etas=ETAS):
    """max_{j>=2,s} exact |q_s(eta_j) - eta_j q_s(1) - (1-eta_j)[s=null]|."""
    q1 = report_probs(mu, g, 1.0)
    dev, arg = 0.0, None
    for eta in etas[1:]:
        qe = report_probs(mu, g, eta)
        for s in range(4):
            d = abs(qe[s] - eta * q1[s] - (1 - eta) * (s == 3))
            if d > dev:
                dev, arg = float(d), (s, eta)
    return dev, arg


# ------------------------------------------------------------------- boxes --
def box_table_attenuated(row3, eta, N, rng):
    """Single-photon table box: q(eta) = (eta p00, eta p01, eta p10, 1-eta);
    one multinomial per (context, eta). Returns a 4-vector of counts."""
    p = np.array([eta * row3[0], eta * row3[1], eta * row3[2], 1 - eta])
    return rng.multinomial(N, p / p.sum())


def box_forger_attenuated(mu, g, eta, N, rng):
    """Coherent/intensity forger: raw pattern ~ P_eta (8-cell multinomial),
    then the eta-blind stochastic report map g (per-pattern multinomial split)."""
    raw = rng.multinomial(N, raw_probs(mu, eta))
    out = np.zeros(4, dtype=int)
    for ri in range(8):
        if raw[ri]:
            out += rng.multinomial(raw[ri], g[ri])
    return out


def sample_box(box, N, rng):
    """One G8 run: counts[c, j, s] for contexts 0..4, etas descending."""
    counts = np.zeros((5, J, 4), dtype=int)
    for c in range(5):
        for j, eta in enumerate(ETAS):
            if box["kind"] == "table":
                counts[c, j] = box_table_attenuated(box["row3"], eta, N, rng)
            else:
                counts[c, j] = box_forger_attenuated(box["mu"], box["g"],
                                                     eta, N, rng)
    return counts


# ------------------------------------------------------------------ gate G8 --
def cert_g8(counts_by_eta, N):
    """G8 certificate on one run. counts_by_eta: (5, J, 4) int array in the
    pre-registered eta order (descending, eta = 1 first). Returns the spec's
    dict: D_max, argmax (c, s-label, eta), threshold_max = t at the argmax,
    g8a_click1 = min-over-contexts click rate at eta = 1, flag_b, in_range_a
    (plus the full deviation tensor for reporting)."""
    q = counts_by_eta / N
    labels = ["00", "01", "10", "null"]
    D = np.zeros((5, 4, J - 1))
    T = np.zeros(J - 1)
    for j in range(1, J):
        eta = ETAS[j]
        T[j - 1] = EPS_G8 * (1 + eta)
        for s in range(4):
            ref = eta * q[:, 0, s] + (1 - eta) * (s == 3)
            D[:, s, j - 1] = np.abs(q[:, j, s] - ref)
    exc = D > T[None, None, :]
    c_m, s_m, j_m = np.unravel_index(np.argmax(D), D.shape)
    click1 = float(np.min(q[:, 0, :3].sum(axis=1)))
    return {"D_max": float(D[c_m, s_m, j_m]),
            "argmax": (int(c_m), labels[s_m], ETAS[j_m + 1]),
            "threshold_max": float(T[j_m]),
            "g8a_click1": click1,
            "flag_b": bool(exc.any()),
            "in_range_a": bool(click1 >= 1 - Z_MAX - EPS_G8),
            "n_exceed": int(exc.sum()), "D": D, "T": T}


def g8_outcome(c8):
    if not c8["in_range_a"]:
        return "OUT-OF-RANGE"
    return "FLAG" if c8["flag_b"] else "pass"


def eta1_arm_verdict(counts):
    """Joint-gate arm: eta = 1 click outcomes -> C1-C5 -> verdict."""
    clicks = counts[:, 0, :3]
    counts4 = np.concatenate([clicks, np.zeros((5, 1), dtype=int)], axis=1)
    cert = certificates_clicks(counts4)
    v, reasons = verdict(cert)
    return v, cert


def run_box(box, rng):
    counts = sample_box(box, N_G8, rng)
    c8 = cert_g8(counts, N_G8)
    v, cert = eta1_arm_verdict(counts)
    return c8, v, cert


# ------------------------------------------------------------ exact anchors --
def run_anchors():
    print("=" * 78)
    print("EXACT ANCHORS (sanity first -- abort if any is off)")
    print("=" * 78)
    checks = []
    cfq = cf_of(table_quantum(1.0))
    checks.append(("CF(quantum V=1) = 2 sqrt(5) - 4", abs(cfq - CF_EXACT) < 1e-7,
                   f"{cfq:.10f}"))
    cfc = cf_of(TABLE_CLASSICAL)
    checks.append(("CF(classical) = 0", abs(cfc) < 1e-8, f"{cfc:.2e}"))
    census = {}
    for K in OR_CLIQUES:
        census[len(K)] = census.get(len(K), 0) + 1
    checks.append(("CE2 clique census {4: 525, 5: 10}",
                   census == {4: 525, 5: 10}, str(census)))
    checks.append(("eps_G8 = 2.338e-3", abs(EPS_G8 - 2.338e-3) < 2e-6,
                   f"{EPS_G8:.6e}"))
    checks.append(("t_max = 4.33e-3", abs(T_MAX - 4.325e-3) < 1e-5,
                   f"{T_MAX:.6e}"))
    # binomial identity: table boxes have EXACT D = 0 at every eta, any z
    dev = 0.0
    for z in (0.0, 0.1, 0.2):
        for eta in ETAS[1:]:
            q1 = np.array([(1 - z) * p for p in P_QUANTUM] + [z])
            qe = np.array([eta * (1 - z) * p for p in P_QUANTUM] + [1 - eta * (1 - z)])
            for s in range(4):
                dev = max(dev, abs(qe[s] - eta * q1[s] - (1 - eta) * (s == 3)))
    checks.append(("binomial identity: exact D = 0 for all z", dev < 1e-15,
                   f"max = {dev:.1e}"))
    d0 = lp_anchored(np.array([1.0, 1.0, 1.0]), ETAS, zmax=1.0, delta_a=1.0)
    checks.append(("UNANCHORED scaling test exactly forgeable", abs(d0) < 1e-9,
                   f"Delta = {d0:.2e} (joint gate is mandatory)"))
    ok = True
    for name, passed, detail in checks:
        print(f"  [{'PASS' if passed else 'FAIL'}] {name:52s} {detail}")
        ok &= passed
    if not ok:
        print("ANCHOR FAILURE -- aborting before any pilot/sampling work.")
        sys.exit(1)
    print(f"  all {len(checks)} anchors pass.")


# -------------------------------------------------------------------- pilot --
PILOT_REFERENCE = [  # (delta_a, reference Delta_min from the spec/pilot)
    (0.0, 0.041309), (0.005, 0.026413), (0.010, 0.014881)]


def run_pilot():
    print()
    print("=" * 78)
    print("MINIMAX PILOT (reproduce spec II.6 reference values, then the global"
          " anchor scan)")
    print("=" * 78)
    repro = {}
    ok = True
    for da, ref in PILOT_REFERENCE:
        val, mu, g, z = minimax(ETAS, SEED_DE_MAIN, delta_a=da)
        hit = abs(val - ref) < 5e-5
        ok &= hit
        repro[da] = {"delta_min": float(val), "mu": mu.tolist(), "z": z,
                     "reference": ref, "reproduced": bool(hit)}
        print(f"  z_max=0.20 delta_a={da:.3f}: Delta_min = {val:.6f} "
              f"(ref {ref:.6f}) mu* = {np.round(mu, 3)} z* = {z:.4f} "
              f"[{'OK' if hit else 'MISMATCH'}]")
    if not ok:
        print("PILOT REPRODUCTION FAILURE -- aborting (spec Part III rule 1).")
        sys.exit(1)

    print()
    print(f"  GLOBAL ANCHOR SCAN: table_quantum(V), V in linspace(V_crit, 1, "
          f"{V_GRID_GLOBAL}), delta_a = 0.005 ball, z_max = 0.20, "
          f"DE seed {SEED_DE_GLOBAL} (maxiter {DE_KW_SCAN['maxiter']})")
    n_arm = int((1 - Z_MAX) * N_G8)          # conservative eta=1-arm clicks
    eps_h = np.sqrt(np.log(2 / (ALPHA_CF / 20)) / (2 * n_arm))
    scan = []
    for V in np.linspace(V_CRIT, 1.0, V_GRID_GLOBAL):
        e = table_quantum(V)
        certifiable = (1.0 - ncf_lp(e + eps_h)) > 0
        p_row = e[0:3].copy()
        val, mu, g, z = minimax(ETAS, SEED_DE_GLOBAL, p_row=p_row,
                                de_kw=DE_KW_SCAN, delta_a=0.005)
        scan.append({"V": float(V), "delta_min": float(val),
                     "certifiable_at_arm_N": bool(certifiable),
                     "mu": mu.tolist(), "z": z})
        print(f"    V = {V:.6f}  Delta_min = {val:.6f}  z* = {z:.3f}  "
              f"{'certifiable' if certifiable else 'NOT certifiable at arm N'}")
    cert_vals = [s["delta_min"] for s in scan if s["certifiable_at_arm_N"]]
    all_vals = [s["delta_min"] for s in scan]
    dmin_global = min(cert_vals) if cert_vals else min(all_vals)
    validated = dmin_global >= KILL_FLOOR
    print(f"  Delta_min(global anchor, certifiable tables) = {dmin_global:.6f} "
          f"(over all grid tables: {min(all_vals):.6f})")
    print(f"  kill criterion {KILL_FLOOR}: "
          f"[{'VALIDATED -- freeze spec and sample' if validated else 'KILLED'}]")
    if not validated:
        print("  ESCALATION LADDER (pre-registered, II.6): (1) widen grid to "
              "J = 16 adding (0.95, 0.775, 0.625, 0.475, 0.325, 0.185, 0.085, "
              "0.02); (2) tighten z_max to 0.10; (3) only then consider a "
              "no-fabrication assumption.  NOT sampling under a killed spec.")
        sys.exit(2)
    return repro, scan, dmin_global


# ---------------------------------------------------------------- main runs --
def build_boxes(repro):
    """Boxes in the pre-registered matrix order (II.7, extended with the two
    F* instances). Expected G8 outcome and expected eta=1-arm verdict fixed
    here, before any sampling."""
    # recover LP solutions at the reproduced mu* (deterministic re-solve)
    d_ex, g_ex, z_ex = lp_anchored(np.array(repro[0.0]["mu"]), ETAS,
                                   delta_a=0.0, want_solution=True)
    d_sl, g_sl, z_sl = lp_anchored(np.array(repro[0.005]["mu"]), ETAS,
                                   delta_a=DELTA_A_FSTAR, want_solution=True)
    mu_f0, g_f0 = f0_construct()
    boxes = [
        dict(name="quantum V=1.000", kind="table",
             row3=table_quantum(1.0)[0:3], exp_g8="pass",
             exp_arm="QUANTUM-CERTIFIED"),
        dict(name="quantum V=0.977", kind="table",
             row3=table_quantum(0.977)[0:3], exp_g8="pass",
             exp_arm="QUANTUM-CERTIFIED"),
        dict(name="quantum V=0.550", kind="table",
             row3=table_quantum(0.550)[0:3], exp_g8="pass",
             exp_arm="CLASSICAL"),
        dict(name="quantum V=V_crit", kind="table",
             row3=table_quantum(V_CRIT)[0:3], exp_g8="pass",
             exp_arm=None),                      # edge case, reported only
        dict(name="classical NCHV", kind="table",
             row3=TABLE_CLASSICAL[0:3], exp_g8="pass", exp_arm="CLASSICAL"),
        dict(name="F0 forger (iii-d untuned)", kind="forger",
             mu=mu_f0, g=g_f0, exp_g8="FLAG", exp_arm="QUANTUM-CERTIFIED"),
        dict(name="F* minimax (exact anchor)", kind="forger",
             mu=np.array(repro[0.0]["mu"]), g=g_ex, exp_g8="FLAG",
             exp_arm="QUANTUM-CERTIFIED"),
        dict(name="F* minimax (slack 0.005)", kind="forger",
             mu=np.array(repro[0.005]["mu"]), g=g_sl, exp_g8="FLAG",
             exp_arm="QUANTUM-CERTIFIED"),
    ]
    print()
    print("=" * 78)
    print("FORGER CONSTRUCTIONS (exact, pre-sampling)")
    print("=" * 78)
    for b in boxes:
        if b["kind"] != "forger":
            continue
        # executor note 3: ALL expectations for forger rows are auto-derived
        # here from the exact construction, before any sampling.
        dev, arg = exact_deviation(b["mu"], b["g"])
        q1 = report_probs(b["mu"], b["g"], 1.0)
        z1 = float(q1[3])
        cond = q1[:3] / (1 - z1)
        in_rng = (1 - z1) >= 1 - Z_MAX - EPS_G8
        b["exact_dev"], b["z_eta1"], b["exp_in_range"] = dev, z1, bool(in_rng)
        if not in_rng:                       # cannot pass while out of range
            b["exp_g8"] = "OUT-OF-RANGE"
        # expected eta=1-arm verdict: verbatim cert stack on the EXACT table
        # at the expected arm click count (deterministic, no sampling)
        n_arm = int(round((1 - z1) * N_G8))
        counts_exact = np.tile(np.round(n_arm * np.append(cond, 0.0)), (5, 1))
        v_exp, _ = verdict(certificates_clicks(counts_exact.astype(int)))
        b["exp_arm"] = v_exp
        print(f"  {b['name']:28s} mu = {np.round(b['mu'], 4)}  z(eta=1) = "
              f"{z1:.4f}  exact D_max = {dev:.6f} (~{dev / T_MAX:.0f} t_max) "
              f"at (s,eta) = {arg}")
        print(f"    {'':28s} cond-on-click table = {np.round(cond, 6)} "
              f"(quantum row {np.round(P_QUANTUM, 6)})")
        print(f"    {'':28s} derived expectations: G8a "
              f"{'in-range' if in_rng else 'OUT-OF-RANGE'}, G8b "
              f"{b['exp_g8']}, eta1-arm {v_exp}")
    return boxes


def headline(boxes, rng):
    print()
    print("=" * 78)
    print(f"HEADLINE RUNS  (N = {N_G8:.0e} per (context, eta), J = {J}, "
          f"single run per box)")
    print("=" * 78)
    print(f"  thresholds: eps = {EPS_G8:.6f}, t_max = {T_MAX:.6f}")
    print(f"  {'box':30s} {'G8a':5s} {'D_max':9s} {'@(c,s,eta)':16s} "
          f"{'t@arg':8s} {'G8b':6s} eta1-arm")
    rows = {}
    for b in boxes:
        c8, v, cert = run_box(b, rng)
        out = g8_outcome(c8)
        rows[b["name"]] = {"g8": c8, "outcome": out, "eta1": v,
                           "cf_lo": cert["cf"]["cf_lo"],
                           "cf_hat": cert["cf"]["cf_hat"]}
        print(f"  {b['name']:30s} {'ok' if c8['in_range_a'] else 'OUT':5s} "
              f"{c8['D_max']:.6f}  ({c8['argmax'][0]},{c8['argmax'][1]},"
              f"{c8['argmax'][2]:.2f})".ljust(56) +
              f" {c8['threshold_max']:.5f} "
              f"{'FLAG' if c8['flag_b'] else 'pass':6s} {v}")
    return rows


def repetition_study(boxes, rng):
    print()
    print("=" * 78)
    print(f"REPETITION STABILITY  (R = {R_REPS}; row passes iff expected "
          f"outcome in >= 95% of reps;")
    print("   UNDERMINED if any forger rep is in-range AND unflagged)")
    print("=" * 78)
    tallies = {b["name"]: {"g8": {}, "arm": {}} for b in boxes}
    undermined_events = 0
    for rep in range(R_REPS):
        for b in boxes:
            c8, v, _ = run_box(b, rng)
            out = g8_outcome(c8)
            t = tallies[b["name"]]
            t["g8"][out] = t["g8"].get(out, 0) + 1
            t["arm"][v] = t["arm"].get(v, 0) + 1
            if b["kind"] == "forger" and c8["in_range_a"] and not c8["flag_b"]:
                undermined_events += 1
    rows = []
    for b in boxes:
        t = tallies[b["name"]]
        g8_rate = t["g8"].get(b["exp_g8"], 0) / R_REPS
        if b["exp_arm"] is None:
            arm_rate, arm_txt = None, f"(reported: {t['arm']})"
        else:
            arm_rate = t["arm"].get(b["exp_arm"], 0) / R_REPS
            arm_txt = f"arm rate {arm_rate:.2f}"
        row_pass = g8_rate >= 0.95 and (arm_rate is None or arm_rate >= 0.95)
        rows.append((b["name"], b["exp_g8"], t["g8"], g8_rate, t["arm"],
                     arm_rate, row_pass))
        print(f"  {b['name']:30s} expect {b['exp_g8']:12s} got {t['g8']}   "
              f"rate {g8_rate:.2f}  {arm_txt}  "
              f"{'PASS' if row_pass else 'FAIL'}")
    return rows, undermined_events


def main():
    run_anchors()
    repro, scan, dmin_global = run_pilot()
    boxes = build_boxes(repro)
    rng = np.random.default_rng(SEED_G8)
    print()
    print("=" * 78)
    print(f"OQ2  ATTENUATION-SERIES GATE G8  (J={J}, N=1e6/(ctx,eta), "
          f"alpha_G8={ALPHA_G8}, z_max={Z_MAX}, seed {SEED_G8})")
    print("=" * 78)
    print(f"  PILOT: Delta_min(exact anchor) = {repro[0.0]['delta_min']:.6f}   "
          f"Delta_min(slack 0.005) = {repro[0.005]['delta_min']:.6f}")
    print(f"         Delta_min(global anchor) = {dmin_global:.6f}   [VALIDATED]")
    head = headline(boxes, rng)
    rep_rows, undermined_events = repetition_study(boxes, rng)

    gate_supported = all(r[6] for r in rep_rows) and undermined_events == 0
    print()
    print("=" * 78)
    print("PRE-REGISTERED GATE OUTCOME")
    print("=" * 78)
    print(f"  forger in-range-and-unflagged events (must be 0): "
          f"{undermined_events}")
    print(f"  G8 GATE: [{'SUPPORTED' if gate_supported else 'UNDERMINED'}]")
    print()
    print("  Reading: G8 closes the iii-d blind spot of BBT-002 under A2' "
          "(tester-calibrated")
    print("  attenuator, per-trial randomized eta) -- the semantics escape of "
          "Corollary 1")
    print("  without heralding/antibunching hardware. The joint requirement "
          "(eta=1 arm")
    print("  QUANTUM-CERTIFIED by C1-C5 + binomial consistency) is essential: "
          "unanchored,")
    print("  the scaling test is exactly forgeable. Sharp lemma: J = 3 grids "
          "are forgeable")
    print("  (Delta_min = 0 at z_max = 0.5); the J >= 6 anchored grid is not.")

    summary = {
        "seed_sampling": SEED_G8, "etas": ETAS, "N_G8": N_G8,
        "alpha_G8": ALPHA_G8, "eps": EPS_G8, "t_max": T_MAX, "z_max": Z_MAX,
        "comparisons": M_COMP, "reps": R_REPS,
        "pilot_reproduction": {str(k): v for k, v in repro.items()},
        "global_anchor_scan": scan,
        "delta_min_global": dmin_global,
        "pilot_validated": True,
        "forgers": {b["name"]: {"mu": b["mu"].tolist(),
                                "z_eta1": b["z_eta1"],
                                "exact_D_max": b["exact_dev"]}
                    for b in boxes if b["kind"] == "forger"},
        "headline": {k: {"outcome": v["outcome"], "eta1_arm": v["eta1"],
                         "D_max": v["g8"]["D_max"],
                         "argmax": list(v["g8"]["argmax"]),
                         "g8a_click1": v["g8"]["g8a_click1"],
                         "cf_lo_arm": round(v["cf_lo"], 6)}
                     for k, v in head.items()},
        "repetitions": [{"box": r[0], "expected_g8": r[1], "g8_tally": r[2],
                         "g8_rate": r[3], "arm_tally": r[4],
                         "arm_rate": r[5], "row_pass": r[6]}
                        for r in rep_rows],
        "undermined_events": undermined_events,
        "gate_G8_supported": bool(gate_supported),
    }
    print()
    print("MACHINE-READABLE SUMMARY")
    print(json.dumps(summary, indent=1, default=str))
    sys.exit(0 if gate_supported else 1)


if __name__ == "__main__":
    main()
