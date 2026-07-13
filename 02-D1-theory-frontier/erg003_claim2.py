"""Claim 2 (fast, no igraph): the maximum 8-cliques of H = C9vC9vC9 are EXACTLY
the 729 products-of-one-edge-per-factor.

Strategy (rigorous, uses vertex-transitivity of H):
  - omega(H) = 8 (confirmed separately by the C solver bin/mcq.exe).
  - The 729 products-of-edges are all 8-cliques (checked directly, cheap).
  - Enumerate ALL maximum cliques of H that contain vertex 0 = all size-7
    cliques of the induced subgraph N_H(0) (386 vertices), via a bitset
    Bron-Kerbosch with a size bound. If there are exactly 8 of them and each,
    together with vertex 0, is a product-of-edges, then by vertex-transitivity
    every vertex lies in exactly 8 maximum cliques all of product form, so the
    total number of 8-cliques is 729*8/8 = 729 and every one is a product.
"""
import itertools
import sys

import numpy as np

N9 = 9
OMEGA = 8


def cyc(n):
    A = np.zeros((n, n), bool)
    for i in range(n):
        A[i, (i + 1) % n] = True
        A[(i + 1) % n, i] = True
    return A


def orp(A, k):
    n = A.shape[0]
    idx = np.array(list(itertools.product(range(n), repeat=k)), dtype=np.int64)
    M = np.zeros((idx.shape[0], idx.shape[0]), bool)
    for t in range(k):
        col = idx[:, t]
        M |= A[np.ix_(col, col)]
    np.fill_diagonal(M, False)
    return M, idx


M, idx = orp(cyc(9), 3)
Nv = M.shape[0]


def tup(i):
    return tuple(int(x) for x in idx[i])


def tidx(a, b, c):
    return (a * 9 + b) * 9 + c


# --- the 729 products-of-edges, as frozensets of vertex indices ---
edges9 = [(i, (i + 1) % 9) for i in range(9)]
products = set()
for e0 in edges9:
    for e1 in edges9:
        for e2 in edges9:
            products.add(frozenset(tidx(a, b, c)
                                   for a in e0 for b in e1 for c in e2))
assert len(products) == 729

# forward: all products are 8-cliques
fwd = True
for blk in products:
    v = list(blk)
    sub = M[np.ix_(v, v)]
    np.fill_diagonal(sub, True)
    if not sub.all():
        fwd = False
        break
print(f"729 products-of-edges, all are 8-cliques: {fwd}")


def is_product(vertset):
    tuples = [tup(i) for i in vertset]
    if len(tuples) != 8:
        return False
    projs = []
    for t in range(3):
        vals = sorted(set(tp[t] for tp in tuples))
        if len(vals) != 2 or (vals[1] - vals[0]) % 9 not in (1, 8):
            return False
        projs.append(vals)
    return set(tuples) == set(itertools.product(*projs))


# --- enumerate all maximum cliques through vertex 0 ---
# neighborhood N(0) and induced adjacency as python-int bitsets
nb0 = [v for v in range(Nv) if M[0, v]]
pos = {v: i for i, v in enumerate(nb0)}
m = len(nb0)
adj = [0] * m
for i, u in enumerate(nb0):
    bits = 0
    row = M[u]
    for j, w in enumerate(nb0):
        if row[w]:
            bits |= (1 << j)
    adj[i] = bits
print(f"N(0): {m} vertices (target: size-{OMEGA-1} cliques here)")

TARGET = OMEGA - 1        # 7-cliques in N(0) <-> 8-cliques of H through 0
found = []


def popcount(x):
    return bin(x).count("1")


def color_bound(P):
    """Greedy coloring of the induced subgraph on P; returns the number of
    color classes = an upper bound on omega(P). Cheap, strong prune."""
    colors = 0
    uncolored = P
    while uncolored:
        avail = uncolored
        while avail:
            v = (avail & -avail).bit_length() - 1
            uncolored &= ~(1 << v)
            avail &= ~(1 << v)
            avail &= ~adj[v]      # same color class must be non-adjacent
        colors += 1
    return colors


def bk(R, P):
    lr = len(R)
    if lr == TARGET:
        found.append(list(R))     # maximal (omega(N(0))=TARGET) -> P is empty
        return
    if lr + color_bound(P) < TARGET:
        return
    # pivot on max-degree-in-P vertex to reduce branching
    best_u, best_c, tmp = -1, -1, P
    while tmp:
        u = (tmp & -tmp).bit_length() - 1
        tmp &= tmp - 1
        c = popcount(P & adj[u])
        if c > best_c:
            best_c, best_u = c, u
    ext = P & ~adj[best_u]
    tmp = ext
    while tmp:
        v = (tmp & -tmp).bit_length() - 1
        tmp &= tmp - 1
        bk(R + [v], P & adj[v])
        P &= ~(1 << v)


full_P = (1 << m) - 1
sys.setrecursionlimit(10000)
import time
_t = time.time()
bk([], full_P)
print(f"[enumeration of size-{TARGET} cliques of N(0) done in {time.time()-_t:.1f}s]",
      flush=True)

# map back to H-vertex 8-cliques (add vertex 0)
maxcliques0 = [frozenset([0] + [nb0[i] for i in c]) for c in found]
maxcliques0 = set(maxcliques0)
n0 = len(maxcliques0)
all_prod = all(is_product(c) for c in maxcliques0)
# each must be one of the 8 products through vertex 0
prods_through_0 = {p for p in products if 0 in p}
setmatch = (maxcliques0 == prods_through_0)
print(f"maximum cliques through vertex 0: {n0}  (expected 8)")
print(f"  all are products-of-edges: {all_prod}")
print(f"  set == the 8 products through v0: {setmatch}  "
      f"(|products through v0|={len(prods_through_0)})")

total_8cliques = 729 * n0 // OMEGA
print(f"\nBy vertex-transitivity: total 8-cliques = 729*{n0}/8 = {total_8cliques}")
ok = (fwd and n0 == 8 and all_prod and setmatch and total_8cliques == 729)
print(f"\nCLAIM 2 {'PASS' if ok else 'FAIL'}: max 8-cliques of H are EXACTLY the "
      f"729 products-of-one-edge-per-factor")
sys.exit(0 if ok else 1)
