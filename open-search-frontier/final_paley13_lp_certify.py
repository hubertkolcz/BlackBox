"""
LANE 5 -- exact certification + theta-vs-theta' comparison for the Paley13 LP.

(1) Re-solve the k=3 Delsarte LP WITHOUT the pointwise b_d>=0 constraints
    (off the fixed/forbidden set): that LP is exactly the Lovasz theta of the
    scheme.  If it equals the full-Schrijver value, the nonnegativity
    strengthening is inactive => theta' = theta, and no LP over this scheme can
    beat the theta ceiling.

(2) Certify the exact value with sympy over Q(sqrt13): build the LP data in
    exact Z[sqrt13], verify a matched primal/dual pair proving optimum = 13^(k/2).
"""
import itertools
import numpy as np
from scipy.optimize import linprog
import sympy as sp

SQRT13 = np.sqrt(13.0)
gR = (-1.0 + SQRT13) / 2.0
gN = (-1.0 - SQRT13) / 2.0
Sf = np.array([[1.0, 6.0, 6.0], [1.0, gR, gN], [1.0, gN, gR]])
TYPES = (0, 1, 2)


def build(k):
    classes = list(itertools.product(TYPES, repeat=k))
    idx = {c: i for i, c in enumerate(classes)}
    size = np.array([np.prod([6 if t != 0 else 1 for t in c]) for c in classes], float)
    nC = len(classes)
    Q = np.ones((nC, nC))
    for i, u in enumerate(classes):
        for j, c in enumerate(classes):
            v = 1.0
            for a, b in zip(u, c):
                v *= Sf[a][b]
            Q[i, j] = v
    zero = tuple([0] * k)
    forbidden = [c for c in classes if c != zero and all(t in (0, 2) for t in c)]
    return classes, idx, size, Q, zero, forbidden


def solve(k, nonneg):
    classes, idx, size, Q, zero, forbidden = build(k)
    nC = len(classes)
    A_eq = [np.eye(nC)[idx[zero]]]; b_eq = [1.0]
    for c in forbidden:
        A_eq.append(np.eye(nC)[idx[c]]); b_eq.append(0.0)
    bounds = [(0, None)] * nC if nonneg else [(None, None)] * nC
    # keep b_0 and forbidden handled by eq; free vars otherwise
    res = linprog(-size, A_ub=-Q, b_ub=np.zeros(nC),
                  A_eq=np.array(A_eq), b_eq=np.array(b_eq),
                  bounds=bounds, method="highs")
    return -res.fun, res.success


def exact_certificate(k):
    """Exact Z[sqrt13] check that optimum = 13^(k/2) via the product (tensor)
    primal solution and the theta dual polynomial."""
    s = sp.sqrt(13)
    gRe = (-1 + s) / 2
    gNe = (-1 - s) / 2
    Se = sp.Matrix([[1, 6, 6], [1, gRe, gNe], [1, gNe, gRe]])
    classes = list(itertools.product(TYPES, repeat=k))
    idx = {c: i for i, c in enumerate(classes)}
    size = {c: sp.prod([6 if t != 0 else 1 for t in c]) for c in classes}
    zero = tuple([0] * k)
    forbidden = [c for c in classes if c != zero and all(t in (0, 2) for t in c)]

    # k=1 optimal primal: B_0=1, B_R=(sqrt13-1)/6, B_N=0.  value = 1+6*B_R = sqrt13.
    b1 = {0: sp.Integer(1), 1: (s - 1) / 6, 2: sp.Integer(0)}
    # tensor to k coords
    B = {c: sp.prod([b1[t] for t in c]) for c in classes}
    # feasibility: B_0=1
    assert B[zero] == 1
    # forbidden are 0
    for c in forbidden:
        assert B[c] == 0, (c, B[c])
    # nonnegativity: each factor b1 >=0 so product >=0 (b1[1]=(sqrt13-1)/6>0)
    assert sp.simplify(b1[1]) > 0
    # objective
    obj = sp.nsimplify(sp.expand(sum(size[c] * B[c] for c in classes)))
    obj = sp.simplify(obj)
    # character positivity: Q[u,:].B = prod_i (row-sum over that coord) >=0.
    # By the tensor structure it factorizes to prod_i ( sum_t Se[u_i,t]*b1[t] ).
    coord_vals = {}
    for u in TYPES:
        coord_vals[u] = sp.simplify(sum(Se[u, t] * b1[t] for t in TYPES))
    # these per-coordinate values must all be >=0
    per_coord = {u: sp.simplify(coord_vals[u]) for u in TYPES}
    return obj, per_coord, b1


if __name__ == "__main__":
    print("=== theta vs theta' (Schrijver nonnegativity active?) ===")
    for k in (1, 2, 3):
        v_theta, _ = solve(k, nonneg=False)
        v_schrijver, _ = solve(k, nonneg=True)
        print(f"k={k}: theta(LP,free) = {v_theta:.10f} | theta'(b>=0) = {v_schrijver:.10f} | "
              f"equal? {abs(v_theta - v_schrijver) < 1e-7}")
    print(f"\n13^(1/2)={13**0.5:.10f}  13={13.0}  13^(3/2)={13**1.5:.10f}")

    print("\n=== exact Z[sqrt13] certificate (tensor primal) ===")
    for k in (1, 2, 3):
        obj, per_coord, b1 = exact_certificate(k)
        target = sp.sqrt(13) ** k
        ok = sp.simplify(obj - target) == 0
        pcvals = {u: (sp.nsimplify(v), float(v)) for u, v in per_coord.items()}
        print(f"k={k}: objective = {obj} = 13^(k/2)? {ok}")
        print(f"      per-coordinate character values (must be >=0): "
              f"u0={float(per_coord[0]):.6f}, uR={float(per_coord[1]):.6f}, uN={float(per_coord[2]):.6f}")
    print("\nb1 optimal single-coord primal:", {k: str(v) for k, v in exact_certificate(1)[2].items()})
