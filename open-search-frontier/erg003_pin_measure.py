"""ERG-003 design measurements: quantify pin-propagation candidate-set sizes and
clique-domain sizes for the pentagram search design doc. Compute-light (numpy +
igraph, seconds-to-low-minutes). Prints numbers the design doc cites.
"""
import itertools
import time

import numpy as np
import igraph as ig


def cycle_graph(n):
    A = np.zeros((n, n), dtype=bool)
    for i in range(n):
        A[i, (i + 1) % n] = True
        A[(i + 1) % n, i] = True
    return A


def or_power(A, k):
    n = A.shape[0]
    idx = np.array(list(itertools.product(range(n), repeat=k)), dtype=np.int64)
    N = idx.shape[0]
    M = np.zeros((N, N), dtype=bool)
    for t in range(k):
        col = idx[:, t]
        M |= A[np.ix_(col, col)]
    np.fill_diagonal(M, False)
    return M, idx


def tidx(a, b, c, n=9):
    return (a * n + b) * n + c


MH, idxH = or_power(cycle_graph(9), 3)
N = MH.shape[0]
print(f"H: |V|={N}, deg(v0)={int(MH[0].sum())} (regular)")

# --- sample pin: max 8-clique K = edges (0,1)x(0,1)x(0,1), split into (Q_a, Q_b)
K = [tidx(a, b, c) for a in (0, 1) for b in (0, 1) for c in (0, 1)]
print("\n[pin propagation] pinned pentagram pair union = product-of-edges 8-clique K")
print("common H-neighborhood size |N_H(S)| of a sub-clique S of K, by |S|:")
for s in (1, 2, 3, 4, 5, 6, 7, 8):
    # take the first s vertices of K as the sub-clique S (one representative split)
    S = K[:s]
    common = np.ones(N, dtype=bool)
    for v in S:
        common &= MH[v]
    for v in S:
        common[v] = False
    nb = int(common.sum())
    # how large a clique can live in that neighborhood (omega of induced subgraph)
    verts = np.flatnonzero(common)
    if 0 < len(verts) <= 700:
        sub = MH[np.ix_(verts, verts)]
        iu = np.argwhere(np.triu(sub, 1))
        gsub = ig.Graph(n=len(verts), edges=iu.tolist())
        om = gsub.clique_number()
    else:
        om = None
    print(f"  |S|={s}: |N_H(S)|={nb:4d}  omega(induced N_H(S))={om}")

# --- clique-domain sizes of H by size (time-boxed via igraph exact counts)
iu = np.argwhere(np.triu(MH, 1))
gH = ig.Graph(n=N, edges=iu.tolist())
print("\n[clique domains] number of k-cliques of H (igraph exact enumeration;")
print("  size>=4 is known to explode -- essay reports 219,167,289 size-4 cliques --")
print("  so we only materialize the small tractable domains here):")
for k in (1, 2, 3):
    t0 = time.time()
    cliques = gH.cliques(k, k)
    print(f"  size {k}: {len(cliques):>12,d}   [{time.time()-t0:.1f}s]", flush=True)

# NOTE: do NOT call gH.largest_cliques() / gH.clique_number() on the full
# 729-vertex H -- igraph's Cliquer hangs for many minutes at this density.
# omega(H)=8 is certified in erg003_structure_check.py (theta ceiling +
# construction) and by bin/mcq.exe (MCQ solver, ~1s). The number of MAXIMUM
# 8-cliques is >10^8 (HeptagonCatalysis.wl line ~224; and non-product ones
# exist -- see erg003_structure_check.py claim 2), NOT 729.
print("done.")
