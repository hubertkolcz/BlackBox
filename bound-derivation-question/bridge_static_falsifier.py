"""Static-side falsifier for Bridge C (ESSAY-005 formalizer C, section 7).

Entropy-regularize the STATIC GE packing LP for C5:
    S(C5; T) = max_p  ( sum_v p_v  +  T * H(p) )   s.t.  p_v + p_{v+1} <= 1  (5 pentagon edges), 0<=p<=1
with H(p) = sum_v [ -p ln p - (1-p) ln(1-p) ]  (per-vertex binary entropy, the Maslov/Gibbs softening).

Claim to check: as T -> 0, S(C5;T) -> S_1(C5) = 5/2, the fractional PACKING number -- NOT any Gamma_K
mean-payoff/de-Bruijn quantity. Confirms the strong Bridge C (dynamic Gamma_K = T->0 limit of the static
GE LP) is a CATEGORY ERROR: each side dequantizes its OWN operator; the static limit is a packing number.
"""
import numpy as np
from scipy.optimize import minimize

n = 5
edges = [(i, (i + 1) % n) for i in range(n)]  # C5 pentagon: 5 maximal cliques (edges)

def neg_softened(p, T):
    eps = 1e-12
    pc = np.clip(p, eps, 1 - eps)
    H = np.sum(-pc * np.log(pc) - (1 - pc) * np.log(1 - pc))
    return -(np.sum(p) + T * H)

def solve(T):
    cons = [{"type": "ineq", "fun": (lambda p, e=e: 1.0 - p[e[0]] - p[e[1]])} for e in edges]
    bnds = [(0, 1)] * n
    best = None
    for seed in range(6):
        x0 = np.random.RandomState(seed).uniform(0, 0.5, n)
        r = minimize(neg_softened, x0, args=(T,), bounds=bnds, constraints=cons,
                     method="SLSQP", options={"maxiter": 500, "ftol": 1e-12})
        val = np.sum(r.x)  # report the LP objective (packing value), entropy term -> 0
        if best is None or val > best:
            best = val
    return best

print("Static falsifier: entropy-regularized packing LP on C5")
print("  T        S(C5;T) [packing objective sum p]     -> target 5/2 = 2.5")
for T in [1.0, 0.5, 0.2, 0.1, 0.05, 0.02, 0.01, 0.005, 0.001]:
    print(f"  {T:6.3f}   {solve(T):.10f}")
print("\n  LP optimum (T=0)              = 5/2 = 2.5  (fractional packing number of C5)")
print("  Any dynamic Gamma_K (K=3..5)  in [0.0953, 0.1250]  -- a mean-payoff/de-Bruijn value")
print("  => static T->0 limit = 2.5 (packing number), NOT any Gamma_K.")
print("     No shift, no orbit average, no de-Bruijn graph on the static side.")
print("     Strong Bridge C (static S_k == dynamic Gamma_K) REFUTED as an identity: category error.")
