"""
LANE 5 -- Paley-13 closure via the Delsarte LP (theta').

We want omega(Paley13^{OR k}) = alpha( complement(Paley13)^{strong k} ), an
independence number of a Cayley graph Gbar on the abelian group A = Z_13^k.

Delsarte LP (independence number, translation scheme of A):
  maximize   sum_d b_d
  s.t.       b_0 = 1,
             b_d >= 0                                  (Schrijver nonnegativity)
             b_d = 0 for d in S    (S = connection set of Gbar = forbidden diffs)
             sum_d b_d chi_y(d) >= 0  for every character chi_y.
This LP value = theta'(Gbar) (Bose-Mesner algebra is commutative -> SDP collapses
to LP; the pointwise b_d>=0 is exactly the Schrijver strengthening). It upper
bounds alpha(Gbar) = omega(Paley13^{OR k}).

SYMMETRIZATION.  Gamma = (C_6)^k >< S_k acts on A by per-coordinate multiplication
by quadratic residues (the order-6 QR subgroup of F_13^*) and coordinate perms.
This preserves the connection set S and the objective, so the LP has an optimum
constant on Gamma-orbits.  Using only the (C_6)^k part, each coordinate collapses
to a TYPE in {0, R, N} (zero / quadratic-residue value / non-residue value); an
orbit is an ordered k-tuple of types, 3^k classes.  Everything factorizes over
coordinates.

Single-coordinate character sums (omega = exp(2 pi i /13)):
  g_R = sum_{x in QR} omega^x = (-1+sqrt13)/2,
  g_N = sum_{x in NQR} omega^x = (-1-sqrt13)/2,   g_R+g_N=-1, g_R*g_N=-3.
Transfer matrix S(u,t), u=character-type, t=class-type:
          t=0   t=R   t=N
   u=0     1     6     6
   u=R     1    g_R   g_N
   u=N     1    g_N   g_R
and Q(u-tuple, t-tuple) = prod_i S(u_i, t_i).

Forbidden classes: t-tuple != 0^k with every t_i in {0,N}  (all-residue-free diffs
= connection set of the complement = strong power of complement(Paley13)).

Run: python final_paley13_lp.py
"""
import itertools
import numpy as np
from scipy.optimize import linprog

SQRT13 = np.sqrt(13.0)
gR = (-1.0 + SQRT13) / 2.0
gN = (-1.0 - SQRT13) / 2.0

# transfer matrix indexed by type 0->0, 1->R, 2->N
S = np.array([
    [1.0, 6.0, 6.0],
    [1.0, gR,  gN ],
    [1.0, gN,  gR ],
])

TYPES = (0, 1, 2)  # 0, R, N


def lp_bound(k, verbose=False):
    classes = list(itertools.product(TYPES, repeat=k))
    nC = len(classes)
    idx = {c: i for i, c in enumerate(classes)}

    # objective coefficients |C_c| = prod 6^[t_i != 0]
    size = np.array([np.prod([6 if t != 0 else 1 for t in c]) for c in classes], dtype=float)

    # Q matrix: rows = dual class u, cols = primal class c
    Q = np.ones((nC, nC))
    for i, u in enumerate(classes):
        for j, c in enumerate(classes):
            v = 1.0
            for a, b in zip(u, c):
                v *= S[a][b]
            Q[i, j] = v

    zero_class = tuple([0] * k)
    forbidden = [c for c in classes
                 if c != zero_class and all(t in (0, 2) for t in c)]

    # scipy linprog minimizes c^T x, constraints A_ub x <= b_ub, A_eq x = b_eq, bounds
    # variables x = B_c, all >= 0
    # maximize sum size*B  ->  minimize -size*B
    cobj = -size

    A_eq = []
    b_eq = []
    # B_{0^k} = 1
    row = np.zeros(nC); row[idx[zero_class]] = 1.0
    A_eq.append(row); b_eq.append(1.0)
    # forbidden B_c = 0
    for c in forbidden:
        row = np.zeros(nC); row[idx[c]] = 1.0
        A_eq.append(row); b_eq.append(0.0)

    # character positivity: sum_c B_c Q[i,c] >= 0  ->  -Q[i,:] . B <= 0
    A_ub = -Q
    b_ub = np.zeros(nC)

    res = linprog(cobj, A_ub=A_ub, b_ub=b_ub, A_eq=np.array(A_eq), b_eq=np.array(b_eq),
                  bounds=[(0, None)] * nC, method="highs")
    if not res.success:
        raise RuntimeError(f"LP failed k={k}: {res.message}")
    val = -res.fun
    if verbose:
        print(f"k={k}: #classes={nC}, #forbidden={len(forbidden)}, LP(theta') = {val:.10f}")
        # show nonzero B
        for c, b in zip(classes, res.x):
            if b > 1e-9:
                print(f"    B{c} = {b:.6f}  (|C|={int(size[idx[c]])})")
    return val, res


if __name__ == "__main__":
    print("Delsarte/theta' LP bound for omega(Paley13^{OR k}) = alpha(complement^{strong k})")
    print(f"sqrt(13) = {SQRT13:.10f},  13^(3/2) = {13**1.5:.10f}\n")
    for k in (1, 2, 3):
        val, _ = lp_bound(k, verbose=True)
        print(f"  => k={k}: theta' = {val:.10f}, floor = {int(np.floor(val + 1e-9))}\n")
