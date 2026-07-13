"""Independent verification of Bridge A (weighted-presheaf capacity Lambda_k).

Recomputes the packing LP value on the conormal power C_n^{v k} WITHOUT Wolfram's
LinearOptimization. Uses:
  - own conormal-graph construction (adjacency = adjacent in >=1 coordinate),
  - igraph maximal_cliques for the clique constraints,
  - scipy.optimize.linprog (HiGHS) for the fractional packing LP,
  - exact rational cross-check against the claimed anchors.

Anchors to reproduce:
  Lambda_1(C5)=5/2, Lambda_2(C5)=5, Lambda_2(C7)=49/4, Lambda_2(C7)!=theta(C7)^2,
  Lambda_3(C7)=343/8 via sandwich (dual edge-cube cover + omega(C7^v3)<=8).
"""
import itertools, numpy as np
from fractions import Fraction
from scipy.optimize import linprog
import igraph as ig

def conormal_adj(u, v, n):
    return any((u[i]-v[i]) % n in (1, n-1) for i in range(len(u)))

def build_graph(n, k):
    verts = list(itertools.product(range(n), repeat=k))
    idx = {v:i for i,v in enumerate(verts)}
    edges = []
    for a in range(len(verts)):
        for b in range(a+1, len(verts)):
            if conormal_adj(verts[a], verts[b], n):
                edges.append((a,b))
    g = ig.Graph(n=len(verts), edges=edges)
    return g, verts, idx

def packing_lp(g):
    """max sum p  s.t.  sum_{v in K} p_v <= 1 for every maximal clique K, 0<=p<=1."""
    cliques = g.maximal_cliques()
    nV = g.vcount()
    A = np.zeros((len(cliques), nV))
    for r,K in enumerate(cliques):
        for v in K: A[r,v] = 1.0
    res = linprog(c=-np.ones(nV), A_ub=A, b_ub=np.ones(len(cliques)),
                  bounds=[(0,1)]*nV, method="highs")
    return -res.fun, cliques

def theta_c7_sq():
    import math
    c = math.cos(math.pi/7)
    theta = 7*c/(1+c)
    return theta**2

out = {}
for (n,k,claim) in [(5,1,Fraction(5,2)),(5,2,Fraction(5)),(7,1,Fraction(7,2)),(7,2,Fraction(49,4))]:
    g, verts, idx = build_graph(n,k)
    val, cliques = packing_lp(g)
    sizes = sorted(set(len(K) for K in cliques))
    from collections import Counter
    hist = dict(Counter(len(K) for K in cliques))
    fval = Fraction(val).limit_denominator(1000)
    ok = abs(val - float(claim)) < 1e-7
    out[(n,k)] = (val, fval, claim, ok, len(verts), len(cliques), hist)
    print(f"C{n}^v{k}: |V|={len(verts)} maxCliques={len(cliques)} sizes={hist} "
          f"Lambda={val:.10f} (~{fval}) claim={claim} MATCH={ok} perCopy={val**(1/k):.6f}")

print(f"\ntheta(C7)^2 = {theta_c7_sq():.10f}  (Lambda_2(C7)=12.25 must NOT equal this)")
print(f"  |Lambda_2(C7) - theta^2| = {abs(12.25 - theta_c7_sq()):.6f}  -> distinct: {abs(12.25-theta_c7_sq())>0.1}")

# ---- k=3 (C7) sandwich ----
print("\n--- k=3 (C7) sandwich for Lambda_3(C7)=343/8 ---")
# Dual: 343 edge-cubes {i,i+1}x{j,j+1}x{l,l+1}, weight 1/8. Coverage per vertex?
verts3 = list(itertools.product(range(7), repeat=3))
cover = {v:0 for v in verts3}
edgecubes = []
for i in range(7):
    for j in range(7):
        for l in range(7):
            cube = list(itertools.product([i,(i+1)%7],[j,(j+1)%7],[l,(l+1)%7]))
            edgecubes.append(cube)
            for v in cube: cover[v] += Fraction(1,8)
covmin = min(cover.values()); covmax = max(cover.values())
# verify each edge-cube is actually a clique in conormal C7^v3
allclique = all(all(conormal_adj(a,b,7) for a,b in itertools.combinations(cube,2)) for cube in edgecubes)
dual_obj = Fraction(len(edgecubes),8)
print(f"  343 edge-cubes all cliques: {allclique}; coverage min={covmin} max={covmax}; "
      f"dual objective = {dual_obj} => Lambda_3 <= {dual_obj}  (feasible dual: {covmin>=1})")

# Lower bound: primal p=1/8 uniform feasible iff omega(C7^v3) <= 8. Compute omega with igraph.
print("  computing omega(C7^v3) with igraph (343 vertices)...")
g3, v3, i3 = build_graph(7,3)
omega = g3.clique_number()
print(f"  omega(C7^v3) = {omega}  => primal p=1/8 feasible (needs omega<=8): {omega<=8}")
primal_total = Fraction(343,8)
lam3 = primal_total if (omega<=8 and covmin>=1) else None
print(f"  => Lambda_3(C7) = {lam3}  per-copy = {float(lam3)**(1/3):.6f}  (target 343/8, 7/2)")
print(f"  343/8 = {float(Fraction(343,8)):.6f}; sandwich tight: {lam3==Fraction(343,8)}")
