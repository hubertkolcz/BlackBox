# -*- coding: utf-8 -*-
"""oq1_interventional_dla.py -- PROBE OQ1: interventional DLA bounding.

Implements Part I of OQ-PROBE-SPEC-2026-07-13.md (normative; every free
choice below -- seeds, grids, tolerances, thresholds, print formats -- is
pre-registered there). Acceptance criteria are PROPOSITION-O3.md, OQ1.

Design (pre-registered):
  - Intervention family: U_theta = SO(3) wave-plate rotations on the
    preparation (Rodrigues, axis-angle, |theta| <= pi/2); the KCBS cascade
    (measurement side) is untouched.
  - Table map: exact Born 20-vector T(theta) in protocol section order
    (00, 01, 10, 11) per context c = (i, i+1 mod 5); no sampling anywhere.
  - Primary rank: central-difference Jacobian (h = 1e-5) + SVD,
    sigma_tol = 1e-7 (>= 60x the 1.6e-9 FD-noise ceiling, <= 1e-4 x the
    smallest true singular value seen in the pilot, 1.27); spectral-gap
    guard sigma_rank/sigma_rank+1 >= 1e3 for rank in {1, 2}, else the
    point is DEGENERATE and excluded from the tally.
  - Cross-check: two-radius local PCA (rho = 0.02, 0.01; K = 400 volumetric
    offsets each); dim_PCA = #{k : lambda_k(0.02) > 1e-7 and
    lambda_k(0.02)/lambda_k(0.01) in [3, 5]} (tangent directions scale as
    rho^2, ratio 4; curvature as rho^4, ratio ~16).
  - Analytic theta = 0 anchor (SANITY-FIRST): dT/dtheta_k =
    2 V (l . z)(l . (e_k x z)) per projector l; third column (z-rotations)
    vanishes identically; rank 2 with sigma_1 = sigma_2 (~2.4266 double).
    Abort if it fails.
  - Rig (B), theta-blind: fractions frozen at the adversarial point,
    T_B(theta) = table_intensity(1/sqrt(5), 0) = T_iii-d, constant; run
    through the IDENTICAL FD + SVD + PCA pipeline.
  - Rig (A), theta-aware: QP projection of T(theta) onto the
    no-disturbance polytope (cvxpy/OSQP, eps_abs = eps_rel = 1e-10).
    Executor trap, closed here: NEVER finite-difference through the QP
    (solver jitter ~1e-8 sits above the FD scale and fabricates rank).
    Since every T(theta) is itself a valid ND table, the projection must
    return it -- assert residual ||T_A - T||_2 < 1e-9 at every sampled
    theta, then T_A == T analytically and rank_aware = rank_Q BY IDENTITY.
    Only if some residual exceeds 1e-9 (a reportable finding falsifying
    polytope membership) fall back to FD on the QP path with h = 1e-3.
  - Sampling: single rng = default_rng(20260711); for each V in
    (1.0, 0.977): 30 base points (direction then radius,
    |theta| ~ U(0.05, pi/2)), then per base point the two PCA clouds
    (rho = 0.02 first). No other random draws anywhere.

Pre-registered readout (PROPOSITION-O3 OQ1; both outcomes publishable):
  OQ1-A (blind separation): rank_Q = 2 at >= 28/30 non-degenerate base
    points for each V, PCA agreeing, AND rank_blind = 0 at all 30.
  OQ1-B (aware matching):   T_A residual < 1e-9 at all theta (hence
    rank_aware = rank_Q by identity).
Exit code 0 iff the theta = 0 anchor passes and OQ1-A and OQ1-B are both
SUPPORTED.

Helpers kcbs_vectors / CTX / table_intensity / marginals-structure copied
verbatim from mbqc_blackbox_test.py (same folder) per spec Part III.3 --
do NOT re-derive.

Deps: numpy, scipy (svd only via numpy), cvxpy (OSQP). Runtime < 2 min.
"""
import json
import sys

import numpy as np
import cvxpy as cp

# ------------------------------------------------- protocol constants ------
SQRT5 = np.sqrt(5.0)
CTX = [(i, (i + 1) % 5) for i in range(5)]


def kcbs_vectors():
    """Exact pentagram: cyclically orthogonal unit vectors, cone axis z.
    (l_i . z)^2 = cos(pi/5)/(1+cos(pi/5)) = 1/sqrt(5) exactly.
    [verbatim from mbqc_blackbox_test.py]"""
    c2 = np.cos(np.pi / 5) / (1 + np.cos(np.pi / 5))
    ct, st = np.sqrt(c2), np.sqrt(1 - c2)
    return [np.array([st * np.cos(4 * np.pi * i / 5),
                      st * np.sin(4 * np.pi * i / 5), ct]) for i in range(5)]


LVEC = kcbs_vectors()
PSI = np.array([0.0, 0.0, 1.0])


def table_from_edge(p00, p01, p10):
    e = np.zeros(20)
    for c in range(5):
        e[4 * c:4 * c + 4] = [p00, p01, p10, 0.0]
    return e


def table_intensity(t, delta=0.0):
    """Divided-beam fractions per context: (f00, f01, f10) = (1-2t, t-delta, t+delta).
    [verbatim from mbqc_blackbox_test.py]"""
    return table_from_edge(1 - 2 * t, t - delta, t + delta)


T_IIID = table_intensity(1 / SQRT5, 0.0)      # the adversarial iii-d table

# ---------------------------------------------- intervention + table map ---
H_FD = 1e-5
SIGMA_TOL = 1e-7
GAP_MIN = 1e3
PCA_K = 400
PCA_RHOS = (0.02, 0.01)
PCA_LAMBDA_TOL = 1e-7
PCA_RATIO_LO, PCA_RATIO_HI = 3.0, 5.0
SEED = 20260711
M_BASE = 30
VS = (1.0, 0.977)
AWARE_RES_TOL = 1e-9


def rot(theta):
    """Axis-angle -> SO(3) (Rodrigues). R = I when |theta| < 1e-300."""
    th = np.linalg.norm(theta)
    if th < 1e-300:
        return np.eye(3)
    k = theta / th
    K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
    return np.eye(3) + np.sin(th) * K + (1 - np.cos(th)) * (K @ K)


def table_theta(theta, V=1.0):
    """Exact Born table (20-vector, protocol section order) of R(theta) PSI
    through the fixed KCBS cascade."""
    psi = rot(theta) @ PSI
    e = np.zeros(20)
    for c, (i, j) in enumerate(CTX):
        a, b = LVEC[i], LVEC[j]
        n = np.cross(a, b)
        n /= np.linalg.norm(n)
        p10 = V * (a @ psi) ** 2 + (1 - V) / 3
        p01 = V * (b @ psi) ** 2 + (1 - V) / 3
        p00 = V * (n @ psi) ** 2 + (1 - V) / 3
        e[4 * c:4 * c + 4] = [p00, p01, p10, 0.0]
    return e


def table_blind(theta, V=1.0):
    """(B) theta-blind rig: fractions frozen at the adversarial point."""
    return T_IIID


# --------------------------------------------------- rank machinery --------
def jac_fd(table_fn, theta, V, h=H_FD):
    """Central-difference Jacobian, 20 x 3.
    Error budget (spec I.3): truncation <= (h^2/6)*8 ~ 1.3e-10, rounding
    ~ eps_mach/(2h) ~ 6e-12, ||E||_2 <= sqrt(60)*2e-10 ~ 1.6e-9."""
    J = np.zeros((20, 3))
    for k in range(3):
        dp = np.zeros(3)
        dp[k] = h
        J[:, k] = (table_fn(theta + dp, V) - table_fn(theta - dp, V)) / (2 * h)
    return J


def rank_of(J):
    """Pre-registered decision: rank = #{sigma_k > SIGMA_TOL}; spectral-gap
    guard for rank in {1, 2}; rank 0 skips the gap test (theta-blind path,
    same pipeline, no special case). Returns (rank, sv, degenerate)."""
    sv = np.linalg.svd(J, compute_uv=False)
    r = int(np.sum(sv > SIGMA_TOL))
    degenerate = False
    if 1 <= r <= 2:
        nxt = sv[r] if r < len(sv) else 0.0
        if nxt > 0 and sv[r - 1] / nxt < GAP_MIN:
            degenerate = True
        elif nxt == 0.0:
            pass                          # infinite gap: guard satisfied
    return r, sv, degenerate


def pca_dim(table_fn, theta_m, V, offsets_by_rho):
    """Two-radius local PCA (spec I.4). offsets_by_rho: {rho: (K,3) array}.
    dim_PCA = #{k : lambda_k(0.02) > 1e-7 and ratio(0.02/0.01) in [3, 5]}."""
    lam = {}
    for rho in PCA_RHOS:
        cloud = np.array([table_fn(theta_m + d, V) for d in offsets_by_rho[rho]])
        X = cloud - cloud.mean(axis=0)
        lam[rho] = np.linalg.svd(X, compute_uv=False) ** 2 / len(cloud)
    dim = 0
    for k in range(min(len(lam[0.02]), len(lam[0.01]))):
        l2, l1 = lam[0.02][k], lam[0.01][k]
        if l2 > PCA_LAMBDA_TOL and l1 > 0 and PCA_RATIO_LO <= l2 / l1 <= PCA_RATIO_HI:
            dim += 1
    return dim


def draw_offsets(rng, rho, K=PCA_K):
    """Volumetric ball sampling: direction rng.normal(3)/norm, radius
    rho * u^(1/3). Consumed in declared order (rho = 0.02 first)."""
    out = np.zeros((K, 3))
    for i in range(K):
        d = rng.normal(size=3)
        d /= np.linalg.norm(d)
        out[i] = d * rho * rng.uniform() ** (1 / 3)
    return out


# ------------------------------------------- theta = 0 analytic anchor -----
def anchor_theta0(V=1.0):
    """Analytic Jacobian at theta = 0: dT/dtheta_k = 2V (l.z)(l.(e_k x z))
    per projector l (slots: p00 <- n, p01 <- l_j, p10 <- l_i). Third column
    (k = 3, rotation about the preparation axis z) vanishes identically.
    SANITY-FIRST anchor: assert rank 2, sigma_1 = sigma_2 (~2.4266 double),
    kernel = z-rotations; abort on failure."""
    E = np.eye(3)
    J = np.zeros((20, 3))
    for c, (i, j) in enumerate(CTX):
        a, b = LVEC[i], LVEC[j]
        n = np.cross(a, b)
        n /= np.linalg.norm(n)
        for slot, l in ((0, n), (1, b), (2, a)):
            for k in range(3):
                J[4 * c + slot, k] = 2 * V * (l @ PSI) * (l @ np.cross(E[k], PSI))
    sv = np.linalg.svd(J, compute_uv=False)
    col3 = float(np.max(np.abs(J[:, 2])))
    J_fd = jac_fd(table_theta, np.zeros(3), V)
    fd_err = float(np.max(np.abs(J_fd - J)))
    ok = (sv[0] > SIGMA_TOL and sv[1] > SIGMA_TOL and sv[2] <= SIGMA_TOL
          and abs(sv[0] - sv[1]) < 1e-9 and col3 < 1e-12 and fd_err < 1e-8)
    return ok, sv, col3, fd_err


# -------------------------------------- (A) theta-aware rig: QP projection -
def _nd_projection_problem():
    """Projection onto the ND polytope (spec I.5): x >= 0 (20 vars);
    x[4c+3] = 0 (structural (1,1) zero); per-context normalization;
    no-disturbance marginal equalities exactly as marginals() of
    mbqc_blackbox_test.py. Parametrized in the target table."""
    x = cp.Variable(20)
    tgt = cp.Parameter(20)
    cons = [x >= 0]
    for c in range(5):
        cons.append(x[4 * c + 3] == 0)
        cons.append(cp.sum(x[4 * c:4 * c + 4]) == 1)
    for m in range(5):
        lm = (m - 1) % 5
        cons.append(x[4 * lm + 1] + x[4 * lm + 3] == x[4 * m + 2] + x[4 * m + 3])
    prob = cp.Problem(cp.Minimize(cp.sum_squares(x - tgt)), cons)
    return prob, x, tgt


def aware_residual(prob, x, tgt, T):
    tgt.value = T
    prob.solve(solver=cp.OSQP, eps_abs=1e-10, eps_rel=1e-10,
               max_iter=200000, verbose=False)
    return float(np.linalg.norm(x.value - T))


# ------------------------------------------------------------- main --------
def main():
    ok0, sv0, col3, fd_err = anchor_theta0(V=1.0)
    print("=" * 78)
    print("OQ1  INTERVENTIONAL DLA PROBE  "
          "(M=30 theta/V, h=1e-5, sigma_tol=1e-7, seed 20260711)")
    print("=" * 78)
    print(f"  theta=0 analytic anchor: sigma = {sv0[0]:.4f} {sv0[1]:.4f} "
          f"{sv0[2]:.2e}, |J[:,z-axis]|_max = {col3:.1e}, "
          f"max|J_FD - J_analytic| = {fd_err:.1e}  -> "
          f"{'PASS' if ok0 else 'FAIL (SANITY-FIRST ABORT)'}")
    if not ok0:
        print("  ABORT: theta=0 anchor failed; no tally is trustworthy.")
        sys.exit(2)

    rng = np.random.default_rng(SEED)
    prob, xvar, tgt = _nd_projection_problem()

    summary = {"seed": SEED, "h": H_FD, "sigma_tol": SIGMA_TOL, "per_V": {}}
    all_A, all_B = True, True
    aware_fallback_used = False

    for V in VS:
        # -- declared rng order: 30 base points (direction then radius) ...
        thetas = []
        for _ in range(M_BASE):
            v = rng.normal(size=3)
            v /= np.linalg.norm(v)
            thetas.append(v * rng.uniform(0.05, np.pi / 2))
        print(f"  V={V:.3f}")
        print("   m  |theta|   sigma1     sigma2     sigma3      "
              "rankJ dimPCA blind awareR      verdict")
        n_rank2 = n_degen = n_blind0 = n_aware = n_pca_agree = 0
        max_aware_res = 0.0
        for m, th in enumerate(thetas, 1):
            # ... then per base point the two PCA clouds (rho = 0.02 first)
            offsets = {rho: draw_offsets(rng, rho) for rho in PCA_RHOS}

            J, JB = jac_fd(table_theta, th, V), jac_fd(table_blind, th, V)
            rQ, sv, degQ = rank_of(J)
            rB, svB, _ = rank_of(JB)
            dimQ = pca_dim(table_theta, th, V, offsets)
            dimB = pca_dim(table_blind, th, V, offsets)

            T = table_theta(th, V)
            res = aware_residual(prob, xvar, tgt, T)
            max_aware_res = max(max_aware_res, res)
            aware_ok = res < AWARE_RES_TOL
            if not aware_ok:
                aware_fallback_used = True   # reportable finding (spec I.5)

            if degQ:
                n_degen += 1
            else:
                if rQ == 2:
                    n_rank2 += 1
                if dimQ == rQ:
                    n_pca_agree += 1
            if rB == 0 and dimB == 0:
                n_blind0 += 1
            if aware_ok:
                n_aware += 1

            verdict = ("DEGENERATE" if degQ else
                       "OK" if (rQ == 2 and dimQ == 2 and rB == 0
                                and dimB == 0 and aware_ok) else "CHECK")
            print(f"   {m:02d}  {np.linalg.norm(th):.4f}  "
                  f"{sv[0]:.4e} {sv[1]:.4e} {sv[2]:.4e}    {rQ}     "
                  f"{dimQ}      {rB}    "
                  f"{'<1e-9' if aware_ok else f'{res:.1e}':<11} {verdict}")
        n_nondeg = M_BASE - n_degen
        print(f"  summary V={V:.3f}: rank2 {n_rank2}/{n_nondeg}, "
              f"degenerate {n_degen}, blind rank0 {n_blind0}/{M_BASE}, "
              f"aware match {n_aware}/{M_BASE}")
        okA_V = (n_rank2 >= 28 and n_pca_agree == n_nondeg
                 and n_blind0 == M_BASE)
        okB_V = n_aware == M_BASE
        all_A &= okA_V
        all_B &= okB_V
        summary["per_V"][f"{V:.3f}"] = {
            "rank2": n_rank2, "nondegenerate": n_nondeg,
            "degenerate": n_degen, "pca_agree": n_pca_agree,
            "blind_rank0": n_blind0, "aware_match": n_aware,
            "max_aware_residual": max_aware_res}

    print(f"  OQ1-A (blind separation):  "
          f"{'SUPPORTED' if all_A else 'UNDERMINED'}")
    print(f"  OQ1-B (aware matching):    "
          f"{'SUPPORTED' if all_B else 'UNDERMINED'}")
    if all_A:
        print('  OQ1-A statement: "Interventional table access strictly '
              'separates the DLA-3 cascade from every fraction-frozen '
              'intensity rig: orbit rank 2 vs 0. Under the assumption that '
              "the rig's fraction-setting is decoupled from theta, the "
              'interventional protocol closes BBT-002 without trusting any '
              'compilation declaration (Corollary-2 trust assumption '
              'discharged)."')
    if all_B:
        print('  OQ1-B statement: "A theta-aware rig that re-tunes within '
              'the ND polytope reproduces the full quantum orbit exactly: '
              'interventions alone do not certify the DLA without a '
              'theta-decoupling, timing, or semantics assumption - '
              'Proposition 1 extends from static to interventional table '
              'access."')
    if aware_fallback_used:
        print("  FINDING: some QP residual exceeded 1e-9 - polytope "
              "membership falsified at those points; FD-on-QP fallback "
              "(h=1e-3, gap guard) applies. Report upstream.")
    print("  Orbit rank 2 = dim SO(3)/stabilizer, implied by DLA 3; it "
          "lower-bounds the DLA of any rig whose response factors through "
          "its own internal dynamics (leaf-confined so(3) subalgebras are "
          "1-dimensional, orbit rank <= 1). The theta-aware fitter evades "
          "because its response does not factor through a dynamics at all.")
    summary["OQ1_A"] = bool(all_A)
    summary["OQ1_B"] = bool(all_B)
    summary["anchor_theta0"] = {"pass": bool(ok0),
                                "sigma": [float(s) for s in sv0],
                                "fd_vs_analytic": fd_err}
    print("MACHINE-READABLE SUMMARY")
    print(json.dumps(summary))
    sys.exit(0 if (ok0 and all_A and all_B) else 1)


if __name__ == "__main__":
    main()
