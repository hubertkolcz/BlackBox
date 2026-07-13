# -*- coding: utf-8 -*-
"""oq_probe_pilot_2026-07-13.py -- design-validation pilot for the OQ1/OQ2
probe specs (OQ-PROBE-SPEC-2026-07-13.md, same folder). Run this FIRST;
Phase-2 implementation starts only after every printed number matches the
values quoted in the spec (FD singular values to 3 significant digits,
Delta_min to 1e-5).

Reproduces (run 2026-07-13):
  OQ1: quantum table-orbit Jacobian sigma_1,sigma_2 in [1.27, 2.43],
       sigma_3 <= 4e-11 at all sampled theta (rank 2, ~10-decade gap);
       PCA eigen-ratios ~(4.2, 3.7 | 14.9) at rho 0.02 vs 0.01.
  OQ2: unanchored eta-scaling statistic exactly forgeable (Delta = 0);
       anchored minimax Delta_min: J=3 -> 0.000000 at z_max=0.5 (forgeable),
       0.004000 at z_max=0.2 (sub-threshold); J=6 z_max=0.2 -> 0.038824;
       J=8 z_max=0.20: 0.041309 (delta_a=0), 0.026413 (0.005), 0.014881 (0.01);
       z_max scan at J=8: 0.05 -> 0.191565, 0.10 -> 0.111839, 0.20 -> 0.041309,
       0.50 -> 0.002425; no-fabrication changes nothing (to 6 decimals);
       F0 fixed-map forger deviation ~0.071.

Deps: numpy, scipy. Runtime ~5 min local. Seeds fixed in the calls below.
"""
import numpy as np
from itertools import product
from scipy.optimize import linprog, differential_evolution

SQRT5 = np.sqrt(5.0)
CTX = [(i, (i + 1) % 5) for i in range(5)]


def kcbs_vectors():
    c2 = np.cos(np.pi / 5) / (1 + np.cos(np.pi / 5))
    ct, st = np.sqrt(c2), np.sqrt(1 - c2)
    return [np.array([st * np.cos(4 * np.pi * i / 5),
                      st * np.sin(4 * np.pi * i / 5), ct]) for i in range(5)]


LVEC = kcbs_vectors()
PSI = np.array([0.0, 0.0, 1.0])


# ============================================================== OQ1 pilot ==
def rot(theta):
    """Axis-angle -> SO(3) (Rodrigues)."""
    th = np.linalg.norm(theta)
    if th < 1e-300:
        return np.eye(3)
    k = theta / th
    K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
    return np.eye(3) + np.sin(th) * K + (1 - np.cos(th)) * (K @ K)


def table_theta(theta, V=1.0):
    """Exact Born table (20-vector, protocol section order) of U_theta psi."""
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


def jac_fd(theta, V=1.0, h=1e-5):
    J = np.zeros((20, 3))
    for k in range(3):
        dp = np.zeros(3)
        dp[k] = h
        J[:, k] = (table_theta(theta + dp, V) - table_theta(theta - dp, V)) / (2 * h)
    return J


def oq1_pilot():
    print("=" * 70)
    print("OQ1 pilot: FD Jacobian singular values at random theta (V=1, 0.977)")
    rng = np.random.default_rng(20260711)
    for V in (1.0, 0.977):
        for _ in range(5):
            v = rng.normal(size=3)
            v /= np.linalg.norm(v)
            theta = v * rng.uniform(0.05, np.pi / 2)
            s = np.linalg.svd(jac_fd(theta, V), compute_uv=False)
            print(f"  V={V:5.3f} |theta|={np.linalg.norm(theta):.3f}  "
                  f"sv = {s[0]:.4e} {s[1]:.4e} {s[2]:.4e}")
    s0 = np.linalg.svd(jac_fd(np.array([1e-9, 0, 0])), compute_uv=False)
    print(f"  theta ~ 0 anchor: sv = {s0[0]:.4e} {s0[1]:.4e} {s0[2]:.4e} "
          f"(expect double ~2.4266, third ~0)")
    theta0 = np.array([0.3, -0.2, 0.4])
    for rho in (0.02, 0.01):
        cloud = []
        for _ in range(400):
            d = rng.normal(size=3)
            d /= np.linalg.norm(d)
            d *= rho * rng.uniform() ** (1 / 3)
            cloud.append(table_theta(theta0 + d))
        X = np.array(cloud) - np.mean(cloud, axis=0)
        lam = np.linalg.svd(X, compute_uv=False) ** 2 / len(cloud)
        print(f"  PCA rho={rho}: top eigs = "
              f"{lam[0]:.3e} {lam[1]:.3e} {lam[2]:.3e} {lam[3]:.3e}")


# ============================================================== OQ2 pilot ==
p_QUANTUM = np.array([1 - 2 / SQRT5, 1 / SQRT5, 1 / SQRT5])  # (p00, p01, p10)
RAWS = list(product([0, 1], repeat=3))
I000 = RAWS.index((0, 0, 0))
ETAS8 = [1.0, 0.85, 0.70, 0.55, 0.40, 0.25, 0.12, 0.05]
ETAS3 = [1.0, 0.5, 0.25]
ETAS12 = [1.0, 0.95, 0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.25, 0.15, 0.08, 0.04]


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


def f0_deviation(etas):
    """Untuned fixed-map forger F0 (identity-style report, iii-d fractions):
    max binomial-scaling deviation over the grid (closed form, no sampling)."""
    mu0 = -np.log(1 - p_QUANTUM)

    def report(eta):
        P = raw_probs(mu0, eta)
        q = np.zeros(4)
        for ri, r in enumerate(RAWS):
            if sum(r) == 0:
                q[3] += P[ri]
            else:
                q[r.index(1)] += P[ri]
        return q

    q1 = report(1.0)
    dev = 0.0
    for eta in etas[1:]:
        qe = report(eta)
        dev = max(dev, float(np.max(np.abs(qe[:3] - eta * q1[:3]))))
    return dev


def lp_anchored(mu, etas, zmax=0.20, delta_a=0.0, nofab=False):
    """Best eta-blind stochastic report map for fixed mu:
    min over (g, z) of max_{j>=2, s} |q_s(eta_j) - eta_j q_s(1) - (1-eta_j)[s=null]|
    s.t. anchor |q_s(1) - (1-z) p_s| <= delta_a, 0 <= z <= zmax, g stochastic.
    Variables: g (8x4 = 32), z, t. LP solved with HiGHS."""
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
        c[IZ] = p_QUANTUM[s]
        if delta_a == 0.0:
            A_eq.append(c)
            b_eq.append(p_QUANTUM[s])
        else:
            A_ub.append(c.copy())
            b_ub.append(p_QUANTUM[s] + delta_a)
            A_ub.append(-c)
            b_ub.append(-(p_QUANTUM[s] - delta_a))
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
    return res.fun if res.status == 0 else np.inf


def lp_unanchored(mu, etas):
    """Same LP without the anchor: demonstrates exact forgeability (Delta=0)."""
    return lp_anchored(mu, etas, zmax=1.0, delta_a=1.0)


def minimax(etas, seed, **kw):
    res = differential_evolution(lambda x: lp_anchored(np.exp(x), etas, **kw),
                                 [(-3, 3.5)] * 3, seed=seed, maxiter=80,
                                 popsize=14, tol=1e-10, polish=True)
    return res.fun, np.exp(res.x)


def oq2_pilot():
    print()
    print("=" * 70)
    print("OQ2 pilot: F0 fixed-map forger deviation (closed form)")
    print(f"  Delta_F0 (J=8 grid)  = {f0_deviation(ETAS8):.4f}   (spec: ~0.071)")

    print()
    print("OQ2 pilot: UNANCHORED scaling statistic is exactly forgeable")
    d = lp_unanchored(np.array([1.0, 1.0, 1.0]), ETAS8)
    print(f"  best-g deviation, no anchor, mu=(1,1,1): {d:.6f}  (must be 0.000000)")

    print()
    print("OQ2 pilot: anchored minimax Delta_min = min_mu min_(g,z) max deviation")
    ETAS6 = [1.0, 0.8, 0.6, 0.4, 0.2, 0.1]
    for label, etas, kw, seed in [
            ("J=3  z_max=0.50 da=0.000", ETAS3, dict(zmax=0.50), 20260712),
            ("J=3  z_max=0.20 da=0.000", ETAS3, dict(zmax=0.20), 20260712),
            ("J=6  z_max=0.20 da=0.000", ETAS6, dict(zmax=0.20), 20260712),
            ("J=8  z_max=0.05 da=0.000", ETAS8, dict(zmax=0.05), 20260712),
            ("J=8  z_max=0.10 da=0.000", ETAS8, dict(zmax=0.10), 20260712),
            ("J=8  z_max=0.20 da=0.000", ETAS8, dict(zmax=0.20), 20260712),
            ("J=8  z_max=0.20 da=0.005", ETAS8, dict(zmax=0.20, delta_a=0.005), 20260712),
            ("J=8  z_max=0.20 da=0.010", ETAS8, dict(zmax=0.20, delta_a=0.010), 20260712),
            ("J=8  z_max=0.50 da=0.000", ETAS8, dict(zmax=0.50), 20260712),
            ("J=12 z_max=0.50 NOFAB   ", ETAS12, dict(zmax=0.50, nofab=True), 20260713),
    ]:
        val, mu = minimax(etas, seed, **kw)
        print(f"  {label}: Delta_min = {val:.6f}  mu* = {np.round(mu, 4)}")
    print()
    print("  spec reference: J=3 -> 0.000000 (z_max 0.5) / 0.004000 (z_max 0.2) |")
    print("  J=6 z_max 0.2 -> 0.038824 | z_max scan 0.05/0.10/0.20/0.50 at J=8 ->")
    print("  0.191565 / 0.111839 / 0.041309 / 0.002425 | slack 0.005/0.01 ->")
    print("  0.026413 / 0.014881 | no-fabrication identical to fabricating case.")


if __name__ == "__main__":
    oq1_pilot()
    oq2_pilot()
