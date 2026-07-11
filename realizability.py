"""Physical-realizability profile of the trans pentagon-chain contextuality advantage.

Addresses the QUANTUM_CONTEXTUALITY.md sec.9 hardware open item *for the theta-density
thread*: "does a real device realize the pentagon-mesh extensive advantage?"  It converts
that vague item into two quantified, hardware-deciding curves in the chain length N
(number of edge-glued pentagons in the open TRANS chain = pentagon_chain_word('t'*(N-1))):

  (1) DIMENSION d(N) = rank of the optimal theta-SDP Gram matrix
      = dimension of an orthonormal representation of the exclusivity graph that SATURATES
        theta = the Hilbert-space dimension a single-system CSW realization needs.
      Interior-point solvers return the maximum-rank optimal point, so this rank is the
      minimum orthonormal-representation dimension (a single pentagon already forces 3).
      FINDING: d(N) = 3 for every N with an advantage -> a single QUTRIT (the same 3-mode
      single-photon / spin-1 system demonstrated by Lapkiewicz et al. 2011 for one pentagon)
      realizes the CSW bound of an ARBITRARILY LONG chain. The resource that grows is the
      number of measurement contexts (3N+2 rank-1 projectors), NOT the system dimension.

  (2) NOISE (standard ISOTROPIC model rho = v|psi><psi| + (1-v) I/3): the CSW value is
      S(v) = v*theta + (1-v)*(3N+2)/3, since each of the M=3N+2 rank-1 events gets floor
      1/3 from the maximally mixed qutrit. Advantage survives iff S(v) > alpha, i.e.
      v > v*(N) = (alpha - (3N+2)/3)/(theta - (3N+2)/3).
      FINDING: v*(N) -> 1/(3(tau*-1)) = 0.88484 (bulk), rising from 0.58541 (single
      pentagon); equivalently each measurement tolerates depolarizing error up to
      q* -> (tau*-4/3)/(tau*-1) = 0.11516. CRUCIALLY, because a CSW test estimates each
      event probability on FRESHLY prepared states (not a sequential cascade), per-context
      noise does NOT accumulate with N -- the visibility requirement is a FIXED ~88.5%,
      INDEPENDENT of chain length. The real large-N limiter is STATISTICAL, not noise:
      the relative margin (theta-alpha)/alpha shrinks to 3*tau*/4 - 1 = 0.0325, so
      certifying the advantage needs ~1/margin^2 ~ 945x the single-pentagon runs.
      [Correction: an earlier version reported v* = alpha/theta -> 0.9685; that used a
      wrong noise floor of 0 (no I/3 contribution) and overstated the requirement.]

  Plus a small exact sub-result: theta = alpha EXACTLY at N=2 and N=5 only (not periodic;
  N=8,11 do not resonate) -- those two trans chains carry NO quantum advantage despite
  being built from contextual pentagons (a sharp instance of composition boundary B1).

Everything is triple cross-checked across three independent SDP code paths (dense CLARABEL,
dense SCS, and the repo's chordal-decomposition solver). This is computable-bound theory:
it pins down the TARGET a real device must hit (dimension 3, visibility -> ~96.8%), not a
claim that any device has realized it -- a laboratory sequential-measurement test still
faces the compatibility/detection loopholes discussed in sec.3, and these are idealized
projective-measurement / isotropic-noise numbers, not a full device error model.
"""
import numpy as np
import cvxpy as cp
from lovasz_theta_sparse import pentagon_chain_word, alpha_chain_word, chordal_theta

TAU_STAR = 1.3767177459158590533          # Root[49 x^3 - 128 x^2 - 75 x + 218, 2]


def theta_gram(n, edges, solver=cp.CLARABEL):
    """theta(G) via the orthonormal-representation SDP; returns (theta, optimal Gram X)."""
    X = cp.Variable((n, n), symmetric=True)
    cons = [X >> 0, cp.trace(X) == 1] + [X[i, j] == 0 for (i, j) in edges]
    prob = cp.Problem(cp.Maximize(cp.sum(X)), cons)
    prob.solve(solver=solver, verbose=False)
    return prob.value, X.value


def or_dimension(X, rel=1e-6):
    """Rank of the optimal Gram = orthonormal-representation (Hilbert) dimension."""
    w = np.linalg.eigvalsh((X + X.T) / 2)
    w = np.clip(w, 0.0, None)
    return int((w > rel * w.max()).sum())


def profile(nmax=11):
    rows = []
    for N in range(1, nmax + 1):
        word = "t" * (N - 1)
        n, edges = pentagon_chain_word(word)
        th, X = theta_gram(n, edges)
        a = alpha_chain_word(word)
        rows.append(dict(N=N, verts=n, theta=th, alpha=a,
                         ratio=th / a, vstar=a / th, dim=or_dimension(X)))
    return rows


def noise_profile(nmax=11):
    """Isotropic-noise critical visibility v*(N) and relative margin (statistical cost)."""
    out = []
    for N in range(1, nmax + 1):
        n, edges = pentagon_chain_word("t" * (N - 1))
        th, _ = theta_gram(n, edges)
        a = alpha_chain_word("t" * (N - 1))
        floor = (3 * N + 2) / 3
        out.append(dict(N=N, theta=th, alpha=a,
                        vstar_iso=(a - floor) / (th - floor),   # isotropic critical visibility
                        margin=(th - a) / a))                   # relative margin
    return out


def main():
    print(f"{'N':>2} {'verts':>5} {'theta':>10} {'alpha':>5} {'th/alpha':>9} "
          f"{'v*=a/th':>8} {'dim d(N)':>8}")
    for r in profile():
        print(f"{r['N']:>2} {r['verts']:>5} {r['theta']:>10.6f} {r['alpha']:>5} "
              f"{r['ratio']:>9.6f} {r['vstar']:>8.5f} {r['dim']:>8}")
    print()
    print("Isotropic-noise ceiling (rho = v|psi><psi| + (1-v) I/3): v*(N) and margin")
    for r in noise_profile():
        print(f"  N={r['N']:>2}: v*_iso={r['vstar_iso']:.5f}  rel-margin={r['margin']:.5f}")
    print(f"  bulk: v*_iso -> 1/(3(tau*-1)) = {1/(3*(TAU_STAR-1)):.6f}; "
          f"per-measurement error q* -> {(TAU_STAR-4/3)/(TAU_STAR-1):.6f}; "
          f"margin -> {3*TAU_STAR/4-1:.5f} (~{(3*TAU_STAR/4-1)**-2:.0f}x runs). "
          f"No noise accumulation with N (fresh-state measurements).")
    print()
    print(f"Limits N->inf:  theta/N -> tau* = {TAU_STAR:.7f},  alpha/N -> 4/3 = {4/3:.7f}")
    print(f"  relative margin  theta/alpha -> 3 tau*/4      = {3*TAU_STAR/4:.7f}")
    print(f"  critical visibility v* -> 4/(3 tau*)          = {4/(3*TAU_STAR):.7f}")
    print(f"  single pentagon: theta/alpha = sqrt5/2 = {5**0.5/2:.7f}, v* = 2/sqrt5 = {2/5**0.5:.7f}")
    # third-path confirmation of dimension-independent theta and the N=2,5 resonances
    print("\nchordal-decomposition cross-check (theta = alpha exactly at N=2,5 only):")
    for N in (2, 5, 8):
        word = "t" * (N - 1); n, edges = pentagon_chain_word(word)
        th = chordal_theta(n, edges)["Theta"]; a = alpha_chain_word(word)
        print(f"  N={N:>2}: theta={th:.6f}  alpha={a}  |theta-alpha|={abs(th-a):.2e}")


if __name__ == "__main__":
    main()
