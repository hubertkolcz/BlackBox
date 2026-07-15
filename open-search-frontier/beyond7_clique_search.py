"""Beyond n = 7: exact 9-clique decisions for the catalysed n-cycle boxes.

Companion to HeptagonCatalysis.wl, section "Beyond n = 7". Decides whether the
OR (conormal) product G_n v G_n v C5 contains a 9-clique, where G_n is C_n
(n-cycle box pair) or P7 (the wraparound-free path product whose 9-clique would
have embedded into EVERY C_n v C_n v C5 with n >= 7 at once).

Method (exact, exhaustive): a clique of H v C5 meets each pentagon layer c in a
clique Q_c of H. Layers at C5-distance 1 are exclusive for free; each pentagram
pair (c, c+2 mod 5) needs Q_c, Q_{c+2} disjoint with Q_c u Q_{c+2} a clique of
H, hence |Q_c| + |Q_{c+2}| <= omega(H). Summing around the pentagram cycle
0-2-4-1-3-0: omega(H v C5) <= floor(5*omega(H)/2). For a 9-clique over
omega(H) = 4 no layer can be empty (the other four split into two pentagram
pairs, at most 8 events), so all five layer sizes lie in {1,2,3}: 15 size
vectors, searched as closed 5-chains in the clique-compatibility graph.

Results (July 2026), each in seconds:
    C7 v C7 v C5 : 9-clique EXISTS (recovers the heptagon activation)
    P7 v P7 v C5 : NO 9-clique  -> the universal single-witness route is closed
    C9 v C9 v C5 : NO 9-clique  -> omega = 8, load 2/sqrt(5): CE-safe
    n = 8, 10, 11, 12, 13, 14, 15 : NO 9-clique
THEOREM (completed by beyond7_theorem_sweep.py + the Lovasz theta ceiling):
    two n-cycle boxes + one pentagon catalyst violate CE  <=>  n = 7.
    Even n and odd n >= 29: omega <= theta(comp Cn)^2 sqrt5 < 9 analytically;
    odd 9 <= n <= 27: exhaustive sweep, all negative.
Cross-checks: igraph's exact branch-and-bound on the full 245-vertex product
reproduces omega(P7 v P7 v C5) = 8, and CaDiCaL on the direct SAT encoding
(clause -x_u | -x_v per non-edge, cardinality >= 9) reproduces SAT for C7.

Usage:
    python beyond7_clique_search.py            # the table above
    python beyond7_clique_search.py direct p7  # igraph on the full product
Requires: numpy, python-igraph.
"""
import itertools
import sys
import time

import numpy as np
import igraph as ig

PENT = [0, 2, 4, 1, 3]          # pentagram order of the five C5 layers
C5ADJ = lambda x, y: (x - y) % 5 in (1, 4)


def factor(kind):
    """(size, adjacency) of one box factor: 'p7' or 'c<n>'."""
    if kind == "p7":
        return 7, lambda x, y: abs(x - y) == 1
    n = int(kind[1:])
    return n, lambda x, y: (x - y) % n in (1, n - 1)


def box_product(kind):
    """H = G v G on tuple vertices, as (igraph Graph, vertex list, adj)."""
    n, fadj = factor(kind)
    verts = list(itertools.product(range(n), range(n)))
    idx = {v: i for i, v in enumerate(verts)}
    hadj = lambda u, v: fadj(u[0], v[0]) or fadj(u[1], v[1])
    edges = [(idx[u], idx[v]) for u, v in itertools.combinations(verts, 2)
             if hadj(u, v)]
    return ig.Graph(n=len(verts), edges=edges), verts, hadj


def nine_clique_via_layers(kind):
    """Exact decision for a 9-clique in (G v G) v C5. Returns a verified
    witness (list of (a, b, c) tuples) or None (exhaustive negative)."""
    H, verts, hadj = box_product(kind)
    assert H.clique_number() == 4, "size lemma needs omega(H) = 4"

    cliques = [tuple(c) for c in H.cliques(min=1, max=3)]
    sizes = np.array([len(c) for c in cliques])
    nH, K = H.vcount(), len(cliques)

    A = np.zeros((nH, nH), dtype=bool)
    for e in H.es:
        A[e.source, e.target] = A[e.target, e.source] = True
    C = np.zeros((K, nH), dtype=np.float32)
    NA = np.ones((K, nH), dtype=bool)       # NA[i,v]: v adjacent to all of i
    for i, c in enumerate(cliques):
        for x in c:
            C[i, x] = 1.0
            NA[i] &= A[x]
    D = C @ (~NA).astype(np.float32).T      # D[b,a] = |Q_b \ N(Q_a)|
    compat = (D.T == 0)                     # disjoint and union a clique
    assert (compat == compat.T).all()

    by_size = {s: np.flatnonzero(sizes == s) for s in (1, 2, 3)}
    vecs = [v for v in itertools.product((1, 2, 3), repeat=5)
            if sum(v) == 9 and all(v[i] + v[(i + 2) % 5] <= 4 for i in range(5))]

    for vec in vecs:
        I = [by_size[vec[p]] for p in PENT]
        M = [compat[np.ix_(I[j], I[(j + 1) % 5])].astype(np.float32)
             for j in range(5)]
        F = M[0]
        for j in (1, 2, 3):
            F = np.clip(F @ M[j], 0, 1)
        closed = (F * M[4].T).sum(axis=1)
        if not closed.any():
            continue
        a0 = int(np.flatnonzero(closed)[0])          # reconstruct one witness
        b = [None] * 5
        b[4] = M[4][:, a0] > 0
        for j in (3, 2, 1):
            b[j] = (M[j] @ b[j + 1].astype(np.float32)) > 0
        chain = [a0]
        for j in range(1, 5):
            chain.append(int(np.flatnonzero((M[j - 1][chain[-1]] > 0) & b[j])[0]))
        witness = sorted((*verts[x], PENT[j])
                         for j, ci in enumerate(chain)
                         for x in cliques[I[j][ci]])
        assert len(set(witness)) == 9
        assert all(hadj(u[:2], v[:2]) or C5ADJ(u[2], v[2])
                   for u, v in itertools.combinations(witness, 2))
        return witness
    return None


def direct(kind):
    """Independent check: igraph exact max clique on the full product."""
    n, fadj = factor(kind)
    verts = list(itertools.product(range(n), range(n), range(5)))
    idx = {v: i for i, v in enumerate(verts)}
    adj = lambda u, v: (fadj(u[0], v[0]) or fadj(u[1], v[1])
                        or C5ADJ(u[2], v[2]))
    g = ig.Graph(n=len(verts),
                 edges=[(idx[u], idx[v])
                        for u, v in itertools.combinations(verts, 2)
                        if adj(u, v)])
    t0 = time.time()
    best = g.largest_cliques()[0]
    w = sorted(verts[i] for i in best)
    assert all(adj(u, v) for u, v in itertools.combinations(w, 2))
    print(f"{kind}: omega({kind}v{kind}vC5) = {len(best)} "
          f"[igraph exact, {time.time() - t0:.0f}s]\n  witness: {w}")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "direct":
        direct(sys.argv[2])
        sys.exit()
    for kind in ["c7", "p7", "c8", "c9", "c10", "c11", "c12", "c13"]:
        t0 = time.time()
        w = nine_clique_via_layers(kind)
        verdict = ("9-clique EXISTS, verified witness: " + str(w) if w
                   else "NO 9-clique (exhaustive)")
        print(f"{kind}v{kind}vC5: {verdict}  [{time.time() - t0:.1f}s]")
