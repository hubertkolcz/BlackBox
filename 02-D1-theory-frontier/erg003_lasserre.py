# ERG-003 symmetry-reduced SDP tower for alpha(Xbar) = omega(C9vC9vC9vC5).
# Xbar = Cbar9 (X) Cbar9 (X) Cbar9 (X) Cbar5 is a CAYLEY GRAPH on the abelian group
# A = Z9 x Z9 x Z9 x Z5 (|A|=3645), connection set S = {0,+-2,+-3,+-4}^3 x {0,+-2} \ {0}.
# Level-1 (Delsarte LP over characters) == Lovasz theta == 19.6664645521 (floor 19), VALIDATED.
# Goal: level-2 (Lasserre/Schrijver) reduced by the full automorphism group
#   Aut = A rtimes G0,  G0 = ({+-1}^3 rtimes S3) x {+-1}  (order 96; multipliers preserving S),
# to certify alpha <= 17 (=> the (3,1) cell does NOT activate).
import numpy as np

n9, n5 = 9, 5
NA = 9 * 9 * 9 * 5  # 3645
D9 = [0, 2, 3, 4, 5, 6, 7]   # Cbar9 "0 or complement-adjacent" per coord
D5 = [0, 2, 3]               # Cbar5 "0 or complement-adjacent"


def a_index(g1, g2, g3, g5):
    return ((g1 * 9 + g2) * 9 + g3) * 5 + g5


def a_tuple(i):
    g5 = i % 5; i //= 5
    g3 = i % 9; i //= 9
    g2 = i % 9; i //= 9
    g1 = i % 9
    return (g1, g2, g3, g5)


def connection_set():
    S = []
    for a in D9:
        for b in D9:
            for c in D9:
                for e in D5:
                    if (a, b, c, e) != (0, 0, 0, 0):
                        S.append(a_index(a, b, c, e))
    return sorted(set(S))   # |S| == 1028


def eigenvalues():
    """Spectrum of Xbar over characters k in A (self-dual). lam_k factors per coordinate."""
    def g9(k): return float(sum(np.cos(2 * np.pi * k * d / 9) for d in D9))
    def g5(k): return float(sum(np.cos(2 * np.pi * k * d / 5) for d in D5))
    lam = np.array([g9(a) * g9(b) * g9(c) * g5(e) - 1.0
                    for a in range(9) for b in range(9) for c in range(9) for e in range(5)])
    return lam   # lam[k] with k enumerated in the same a_index order


def g0_orbit_rep(k1, k2, k3, k5):
    """Canonical rep of character (k1,k2,k3,k5) under G0 = ({+-1}^3 rtimes S3) x {+-1}."""
    a9 = tuple(sorted(min(x, 9 - x) for x in (k1, k2, k3)))  # negation + S3 on Z9 coords
    b5 = min(k5, 5 - k5)                                     # negation on Z5 coord
    return a9 + (b5,)


def g0_orbits():
    """Orbits of G0 on A (== on Ahat). Returns {rep: [member_indices]}."""
    from collections import defaultdict
    orb = defaultdict(list)
    for i in range(NA):
        g1, g2, g3, g5 = a_tuple(i)
        orb[g0_orbit_rep(g1, g2, g3, g5)].append(i)
    return dict(orb)


def block_diagonalizer(seed=3, tol=1e-7):
    """Robust, non-fragile block-diagonalization of the Terwilliger algebra
    T = (C^{AxA})^{G0}.  Take a generic self-adjoint element A0 = sum_g c_g P_g of the
    GROUP ALGEBRA (not the commutant): its eigenspaces have dimension exactly the block
    multiplicities m_k, and since T commutes with A0, restricting any moment matrix M in T
    to each eigenspace gives its blocks.  Returns list of eigenspace bases (N x m_k).
    VALIDATED: distinct eigenspace dims == {8,12,20,30,40,60,70,80,90,100,105,120,150,180}
    (matches the independent Schrijver/Terwilliger recipe), 40 eigenspaces, max 180."""
    G = [np.asarray(p) for p in _g0_perms()]
    rng = np.random.default_rng(seed)
    A0 = np.zeros((NA, NA))
    for p, c in zip(G, rng.standard_normal(len(G))):
        A0[p, np.arange(NA)] += c
    A0 = (A0 + A0.T) / 2
    w, V = np.linalg.eigh(A0)
    o = np.argsort(w); w, V = w[o], V[:, o]
    groups, cur = [], [0]
    for i in range(1, NA):
        if abs(w[i] - w[cur[-1]]) <= tol * max(1, abs(w[i])) + 1e-8:
            cur.append(i)
        else:
            groups.append(cur); cur = [i]
    groups.append(cur)
    return [V[:, g] for g in groups]


def _g0_perms():
    from itertools import product
    el = list(product(*[range(m) for m in (9, 9, 9, 5)])); ix = {e: i for i, e in enumerate(el)}
    def neg(c):
        return lambda e: tuple(v if k != c else (-v) % (9, 9, 9, 5)[c] for k, v in enumerate(e))
    def prm(p):
        return lambda e: (e[p[0]], e[p[1]], e[p[2]], e[3])
    gens = [neg(0), neg(1), neg(2), neg(3), prm((1, 0, 2)), prm((1, 2, 0))]
    gp = [tuple(ix[g(e)] for e in el) for g in gens]
    grp = {tuple(range(NA))}; fr = [tuple(range(NA))]
    while fr:
        nf = []
        for q in fr:
            for g in gp:
                r = tuple(g[q[i]] for i in range(NA))
                if r not in grp:
                    grp.add(r); nf.append(r)
        fr = nf
    return list(grp)


# ------- VALIDATED FINDINGS (local, 2026-07-14) -------
# level-1 (Delsarte LP over 105 G0-orbits) == Lovasz theta == 19.6664645521 -> floor 19.
# symmetry: Aut = A rtimes G0, |G0| = 96 (multipliers = +-1 only; no extra units preserve S).
# three-point (Schrijver/Terwilliger, BGSV s=1,t=1) block structure, VALIDATED:
#   20 PSD blocks (40 eigenspaces w/ irrep-multiplicity), sizes {105,120,30,180,120,150,90,
#   60,60,12} u {70,80,20,120,80,100,60,40,40,8}; max 180; sum m_k=1545; sum m_k^2=160433.
# three-point variable counts: 1 (point) + 65 edge-orbits + 54532 triangle-orbits.
#   => the block cone is small/local, but the ~54.5k triangle-orbit coupling (algebra
#   change-of-basis ~54k x 160k, effectively dense) makes the FULL solve MOSEK/HPC-scale,
#   NOT a clean local SCS run. No guarantee the bound reaches < 18 even if solved.
if __name__ == "__main__":
    S = connection_set(); lam = eigenvalues(); orb = g0_orbits()
    print("|A|=%d  |S|=%d  distinct eigenvalues=%d  G0-orbits=%d"
          % (NA, len(S), len(np.unique(np.round(lam, 6))), len(orb)))
    blocks = block_diagonalizer()
    dims = sorted(b.shape[1] for b in blocks)
    print("block-diagonalizer: %d eigenspaces, distinct dims=%s, max=%d"
          % (len(blocks), sorted(set(dims)), max(dims)))
