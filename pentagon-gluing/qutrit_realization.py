"""Item #3: EXPLICIT qutrit (d=3) realization of the pentagon-mesh contextuality advantage.

realizability.py proved d(N)=3 (a single qutrit saturates theta for any twisted-chain length).
This module makes that constructive: it extracts, from the rank-3 theta-SDP Gram matrix, the
actual CSW measurement directions and state that achieve the CSW bound theta on one qutrit.

Dictionary (verified below; reproduces sqrt5 for the single pentagon):
  * Solve theta = max <J,X>, X>=0, tr X=1, X_ij=0 on exclusive (adjacent) pairs.
  * X* has rank 3; factor X* = G^T G with columns g_i in R^3, so <g_i,g_j>=X*_ij
    (=> g_i _|_ g_j for every exclusive pair; sum||g_i||^2 = 1; ||sum g_i||^2 = theta).
  * MEASUREMENT DIRECTIONS: unit vectors |v_i> = g_i/||g_i|| in R^3 (subset C^3),
    rank-1 projectors P_i = |v_i><v_i|; exclusive events -> orthogonal -> jointly
    measurable & mutually exclusive.  CONTEXTS = edges of the exclusivity graph (the
    graph is triangle-free, so each maximal clique is an edge = one pair of exclusive
    events measured together), exactly as in the KCBS pentagon.
  * STATE: |psi> = (sum_i g_i)/sqrt(theta)  (the "umbrella handle"; = top eigenvector
    of sum_i |v_i><v_i|, i.e. the optimal state).
  * Then the CSW functional  S = sum_i <psi|P_i|psi> = sum_i <psi|v_i>^2 = theta.

So an arbitrarily long twisted pentagon chain is realized on the SAME 3-level system that
Lapkiewicz et al. (2011) already used for one pentagon -- only the number of measurement
settings (3N+2 directions, in edge-contexts) grows, not the Hilbert-space dimension.
This is computable-bound theory: it hands over an explicit projective-measurement protocol
(the target), not a claim any device has run it.
"""
import numpy as np
import cvxpy as cp
from lovasz_theta_sparse import pentagon_chain_word


def theta_gram(n, edges):
    X = cp.Variable((n, n), symmetric=True)
    cons = [X >> 0, cp.trace(X) == 1] + [X[i, j] == 0 for (i, j) in edges]
    cp.Problem(cp.Maximize(cp.sum(X)), cons).solve(solver=cp.CLARABEL, verbose=False)
    return float(cp.sum(X).value), np.array(X.value)


def realization(N):
    """Return (theta, V, psi, edges) for the open twisted chain of N pentagons:
    V is (3N+2) x 3 with unit rows |v_i>; psi is the 3-vector state."""
    n, edges = pentagon_chain_word("t" * (N - 1))
    th, X = theta_gram(n, edges)
    w, U = np.linalg.eigh((X + X.T) / 2)
    idx = np.argsort(w)[::-1][:3]
    G = (U[:, idx] * np.sqrt(np.clip(w[idx], 0, None))).T     # 3 x n
    g = [G[:, i] for i in range(n)]
    V = np.array([gi / np.linalg.norm(gi) for gi in g])       # unit rows
    psi = np.sum(g, axis=0) / np.sqrt(th)
    return th, V, psi, edges


def verify(N, tol=1e-6):
    th, V, psi, edges = realization(N)
    unit = np.allclose(np.linalg.norm(V, axis=1), 1.0, atol=tol)
    excl = max((abs(V[i] @ V[j]) for (i, j) in edges), default=0.0)   # ~0 on exclusive pairs
    psi_unit = abs(np.linalg.norm(psi) - 1.0) < tol
    S = float(np.sum((V @ psi) ** 2))                                  # CSW functional
    return dict(N=N, verts=len(V), theta=th, S=S, achieves=abs(S - th) < 1e-4,
                unit_dirs=unit, max_exclusive_overlap=excl, state_unit=psi_unit)


def main():
    print("Verification (dictionary reproduces theta as the CSW value on one qutrit):")
    for N in (1, 3, 4, 6, 7):        # skip N=2,5 (theta=alpha resonances: no advantage)
        r = verify(N)
        print(f"  N={r['N']}: theta={r['theta']:.6f}  S=sum<psi|P_i|psi>={r['S']:.6f}  "
              f"achieves={r['achieves']}  unit_dirs={r['unit_dirs']}  "
              f"max|<v_i|v_j>|_excl={r['max_exclusive_overlap']:.1e}  state_unit={r['state_unit']}")

    print("\nExplicit N=3 protocol (3*3+2 = 11 qutrit directions + state, in R^3):")
    th, V, psi, edges = realization(3)
    print(f"  theta = {th:.6f}   (classical bound alpha = 5)")
    print(f"  state |psi> = ({psi[0]:+.5f}, {psi[1]:+.5f}, {psi[2]:+.5f})")
    for i, v in enumerate(V):
        print(f"    |v_{i:>2}> = ({v[0]:+.5f}, {v[1]:+.5f}, {v[2]:+.5f})   "
              f"<psi|P_{i}|psi> = {(psi @ v) ** 2:.5f}")
    print(f"  contexts (exclusive pairs, jointly measured) = {edges}")
    print(f"  sum of clicks = {float(np.sum((V @ psi) ** 2)):.6f} = theta  (> alpha = 5)")


if __name__ == "__main__":
    main()
