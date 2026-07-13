# -*- coding: utf-8 -*-
"""
Simulation of "Experimental non-classicality of an indivisible quantum system"
R. Lapkiewicz et al., Nature 474, 490 (2011)  --  the KCBS test on a single qutrit.

Physical model
--------------
A single photon in 3 optical modes = a qutrit.  Each KCBS direction l_i defines
a dichotomic observable  A_i = 2|l_i><l_i| - 1  (click in the l_i mode -> +1).
Neighbouring directions are orthogonal, so (A_i, A_{i+1}) are compatible and are
measured together in one "context": a 3-output interferometer performing a
projective measurement in the orthonormal basis {l_i, l_{i+1}, l_i x l_{i+1}}.

KCBS inequality (correlation form used in the experiment):
    S = <A1A2> + <A2A3> + <A3A4> + <A4A5> + <A5A1>  >=  -3      (NCHV)
    quantum minimum: 5 - 4*sqrt(5) = -3.944...

As in the experiment, the A1 appearing in the last context cannot be guaranteed
to be the *same* physical measurement as in the first context, so a sixth
observable A1' (aligned to be exactly orthogonal to l5, but possibly slightly
misaligned w.r.t. l1) is used, and the bound is corrected:
    <A1A2> + ... + <A5A1'>  >=  -3 - eps,   eps = 2 P(A1 != A1')
(in an NCHV model all values are predefined, so |<A5 A1> - <A5 A1'>| <= 2 P(A1 != A1');
P(A1 != A1') is estimated by measuring A1 and A1' in sequence, which is possible
because l1' is nearly parallel to l1 -- this mirrors the paper's analysis.)
"""

import numpy as np

rng = np.random.default_rng(20260709)

# ---------------------------------------------------------------- geometry ---
def kcbs_vectors():
    """Five real unit vectors in R^3, consecutive ones orthogonal (indices mod 5).
    They lie on a cone around the z-axis with cos^2(theta) = cos(pi/5)/(1+cos(pi/5)),
    at azimuths phi_i = 4*pi*i/5 (the 'pentagram' ordering)."""
    c2 = np.cos(np.pi / 5) / (1 + np.cos(np.pi / 5))
    ct, st = np.sqrt(c2), np.sqrt(1 - c2)
    return [np.array([st * np.cos(4 * np.pi * i / 5),
                      st * np.sin(4 * np.pi * i / 5), ct]) for i in range(5)]

L = kcbs_vectors()
PSI = np.array([0.0, 0.0, 1.0])          # state maximally violating KCBS: cone axis

for i in range(5):                        # sanity check: pentagon orthogonality
    assert abs(L[i] @ L[(i + 1) % 5]) < 1e-12, f"l{i} not orthogonal to l{i+1}"

def context_basis(a, b):
    """Orthonormal basis {a, b, a x b} for the context in which A_a, A_b are
    measured jointly (one interferometer, three output detectors)."""
    c = np.cross(a, b)
    return np.stack([a, b, c / np.linalg.norm(c)])

# ------------------------------------------------------- exact QM predictions ---
def exact_report():
    p = np.array([(l @ PSI) ** 2 for l in L])          # <P_i> = 1/sqrt(5) each
    proj_sum = p.sum()
    corr = [1 - 2 * (p[i] + p[(i + 1) % 5]) for i in range(5)]
    return p, proj_sum, sum(corr)

# ---------------------------------------------------------- NCHV brute force ---
def nchv_bounds():
    """Minimum of sum a_i a_{i+1} over all deterministic +-1 assignments (C5 cycle),
    and max of sum of projector values respecting exclusivity."""
    best_corr, best_proj = +5, 0
    for m in range(32):
        a = [1 if m >> i & 1 else -1 for i in range(5)]
        best_corr = min(best_corr, sum(a[i] * a[(i + 1) % 5] for i in range(5)))
        if all(not (a[i] == 1 and a[(i + 1) % 5] == 1) for i in range(5)):
            best_proj = max(best_proj, sum(1 for x in a if x == 1))
    return best_corr, best_proj

# --------------------------------------------------------------- experiment ---
def measure_context(a, b, state_vec, visibility, n_photons):
    """Send n_photons (Poissonian) through the interferometer of context (a, b).
    Noise model: rho = V |psi><psi| + (1-V) I/3.
    Returns the estimate of <A_a A_b> and the raw counts."""
    B = context_basis(a, b)
    probs = visibility * (B @ state_vec) ** 2 + (1 - visibility) / 3
    n = rng.poisson(n_photons)                         # Poissonian source
    counts = rng.multinomial(n, probs / probs.sum())
    # outcomes: detector 0 -> (A_a,A_b)=(+1,-1); 1 -> (-1,+1); 2 -> (-1,-1)
    corr = (-counts[0] - counts[1] + counts[2]) / n
    err = np.sqrt((1 - corr ** 2) / n)                 # binomial std error
    return corr, err, counts

def sequential_disagreement(l1, l1p, state_vec, visibility, n_photons):
    """Measure A1 then A1' in sequence (possible: l1' nearly parallel to l1).
    Returns estimate of P(A1 != A1')."""
    p1 = visibility * (l1 @ state_vec) ** 2 + (1 - visibility) / 3
    # branch A1=+1: state collapses onto l1
    q_pp = (l1p @ l1) ** 2                             # then P(A1'=+1)
    # branch A1=-1: collapse onto the orthogonal complement component of psi
    perp = state_vec - (l1 @ state_vec) * l1
    nrm = np.linalg.norm(perp)
    q_mp = (l1p @ (perp / nrm)) ** 2 if nrm > 1e-12 else 0.0
    q_mp = visibility * q_mp + (1 - visibility) * 0.5  # crude noise on branch
    p_diff = p1 * (1 - q_pp) + (1 - p1) * q_mp
    n = rng.poisson(n_photons)
    k = rng.binomial(n, min(max(p_diff, 0.0), 1.0))
    return k / n, np.sqrt(p_diff * (1 - p_diff) / n)

def run_experiment(n_photons=10 ** 6, visibility=1.0, misalign_deg=0.0):
    """Full run: 4 pentagon contexts + the (l5, l1') context + eps estimation."""
    # A1': exactly orthogonal to l5 but rotated by delta from l1 within the
    # plane orthogonal to l5 (this is the experimental imperfection).
    u = np.cross(L[4], L[0]); u /= np.linalg.norm(u)
    d = np.deg2rad(misalign_deg)
    l1p = np.cos(d) * L[0] + np.sin(d) * u

    pairs = [(L[0], L[1]), (L[1], L[2]), (L[2], L[3]), (L[3], L[4]), (L[4], l1p)]
    corrs, errs = [], []
    for a, b in pairs:
        c, e, _ = measure_context(a, b, PSI, visibility, n_photons)
        corrs.append(c); errs.append(e)
    S = sum(corrs); S_err = np.sqrt(sum(e ** 2 for e in errs))

    p_diff, p_diff_err = sequential_disagreement(L[0], l1p, PSI, visibility, n_photons)
    eps = 2 * p_diff
    return S, S_err, corrs, eps, 2 * p_diff_err

# ----------------------------------------------------------------- report ---
if __name__ == "__main__":
    p, proj_sum, corr_sum = exact_report()
    nchv_corr, nchv_proj = nchv_bounds()

    print("=" * 72)
    print("KCBS geometry check")
    print("=" * 72)
    for i, l in enumerate(L):
        print(f"  l{i+1} = [{l[0]:+.6f} {l[1]:+.6f} {l[2]:+.6f}]   "
              f"l{i+1}.l{(i+1)%5+1} = {L[i] @ L[(i+1)%5]:+.2e}")
    print(f"\n  <P_i> = {p[0]:.6f}  (= 1/sqrt(5) = {1/np.sqrt(5):.6f})")
    print(f"  projector form : sum <P_i> = {proj_sum:.6f}   "
          f"(QM: sqrt(5) = {np.sqrt(5):.6f},  NCHV bound: {nchv_proj})")
    print(f"  correlation form: S_QM = {corr_sum:.6f}   "
          f"(QM: 5-4*sqrt(5) = {5-4*np.sqrt(5):.6f},  NCHV bound: {nchv_corr})")

    print("\n" + "=" * 72)
    print("Ideal 'experiment'  (V = 1, perfect alignment, 10^6 photons/context)")
    print("=" * 72)
    S, dS, corrs, eps, deps = run_experiment(10 ** 6, 1.0, 0.0)
    for i, c in enumerate(corrs):
        lbl = f"<A{i+1}A{i+2}>" if i < 4 else "<A5A1'>"
        print(f"  {lbl:9s} = {c:+.4f}")
    print(f"  S = {S:.4f} +/- {dS:.4f}   vs NCHV bound -3 - eps, eps = {eps:.4f}")
    print(f"  violation: {abs(S - (-3 - eps)) / dS:.0f} standard deviations")

    print("\n" + "=" * 72)
    print("Realistic run  (V = 0.977, A1' misaligned 1 deg  ->  Nature 2011 regime)")
    print("=" * 72)
    S, dS, corrs, eps, deps = run_experiment(10 ** 6, 0.977, 1.0)
    for i, c in enumerate(corrs):
        lbl = f"<A{i+1}A{i+2}>" if i < 4 else "<A5A1'>"
        print(f"  {lbl:9s} = {c:+.4f}")
    print(f"  S = {S:.4f} +/- {dS:.4f}")
    print(f"  eps = {eps:.4f} +/- {deps:.4f}  ->  corrected NCHV bound: {-3-eps:.4f}")
    print(f"  paper reported S = -3.893 +/- 0.006")
    print(f"  violation of corrected bound: "
          f"{(-3 - eps - S) / np.sqrt(dS**2 + deps**2):.1f} standard deviations")

    print("\n" + "=" * 72)
    print("Noise robustness: critical visibility")
    print("=" * 72)
    v_crit = (-3 - (-5 / 3)) / ((5 - 4 * np.sqrt(5)) - (-5 / 3))
    print(f"  S(V) = V*(5-4*sqrt(5)) + (1-V)*(-5/3)  ->  S < -3 requires "
          f"V > {v_crit:.4f}")
    for v in (1.0, 0.977, 0.90, 0.70, 0.60, 0.55):
        S, dS, *_ = run_experiment(10 ** 5, v, 0.0)
        tag = "VIOLATES" if S + 2 * dS < -3 else ("--------" if S - 2*dS > -3 else "marginal")
        print(f"  V = {v:.3f}:  S = {S:+.4f} +/- {dS:.4f}   {tag}")
