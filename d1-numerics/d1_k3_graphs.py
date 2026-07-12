"""D1 k=3 brackets -- graph construction and validation.

Builds C7, C9 (anchor/cross-check only), Petersen, and Paley(13) and their
k-fold OR/co-normal power exclusivity graphs G^(OR k), EXACTLY matching this
project's own convention already established in d1_ge_copies_sweep.py's
`or_power_bitmask` (itertools.product tuple order; edge iff tuples differ
AND are adjacent in the base graph in at least one coordinate -- i.e. the
identical-copies GE exclusivity graph, complement(G^(OR k)) = complement(G)^
(strong k), the same construction CEFilter/CycleORProduct implement in this
repo's actual BlackBox.wl API).

Each base graph is validated against its known invariants (vertex count,
regularity, edge count, and k=1 clique number) before being used to build
any product graph. Product-graph adjacency is packed into uint64 bitset
rows and written to a binary file that d1_k3_maxclique.c reads directly.

Run: python3 d1_k3_graphs.py
"""
import itertools
import os
import struct
import numpy as np


def cycle_graph(n):
    A = np.zeros((n, n), dtype=bool)
    for i in range(n):
        A[i, (i + 1) % n] = True
        A[(i + 1) % n, i] = True
    return A


def petersen_graph():
    """Kneser(5,2): vertices = 2-subsets of {0..4}; edges iff disjoint.
    Standard construction of the (unique) Petersen graph."""
    verts = list(itertools.combinations(range(5), 2))
    n = len(verts)
    A = np.zeros((n, n), dtype=bool)
    for i, a in enumerate(verts):
        for j, b in enumerate(verts):
            if i != j and set(a).isdisjoint(b):
                A[i, j] = True
    return A


def paley_graph(q):
    """Paley graph on GF(q), q prime with q = 1 (mod 4) so -1 is a QR and
    the relation is symmetric. q=13: QRs are {1,3,4,9,10,12}."""
    qr = set((x * x) % q for x in range(1, q))
    A = np.zeros((q, q), dtype=bool)
    for i in range(q):
        for j in range(q):
            if i != j and (i - j) % q in qr:
                A[i, j] = True
    return A


def validate(name, A, expect_n, expect_regular_degree, expect_edges):
    n = A.shape[0]
    assert n == expect_n, f"{name}: n={n} expected {expect_n}"
    assert np.array_equal(A, A.T), f"{name}: not symmetric"
    assert not A.diagonal().any(), f"{name}: has self-loops"
    degs = A.sum(axis=1)
    assert (degs == expect_regular_degree).all(), (
        f"{name}: degrees {set(degs.tolist())} expected all {expect_regular_degree}")
    edges = int(A.sum() // 2)
    assert edges == expect_edges, f"{name}: edges={edges} expected {expect_edges}"
    return True


def or_power(A, k):
    """k-fold OR/co-normal power: N=n^k vertices (tuples in
    itertools.product order), edge iff tuples differ and ANY coordinate
    pair is adjacent in the base graph A."""
    n = A.shape[0]
    idx = np.array(list(itertools.product(range(n), repeat=k)), dtype=np.int64)
    N = idx.shape[0]
    M = np.zeros((N, N), dtype=bool)
    for t in range(k):
        col = idx[:, t]
        M |= A[np.ix_(col, col)]
    np.fill_diagonal(M, False)
    return M


def pack_and_write(path, M):
    """Pack a boolean adjacency matrix into row-major uint64 bitset words
    and write: int64 N, int64 WORDS, then N*WORDS uint64 words. Bit b of
    word w in row i means vertex i is adjacent to vertex (w*64+b)."""
    N = M.shape[0]
    WORDS = (N + 63) // 64
    out = np.zeros((N, WORDS), dtype=np.uint64)
    Mu = M.astype(np.uint64)
    for w in range(WORDS):
        lo, hi = w * 64, min(w * 64 + 64, N)
        chunk = Mu[:, lo:hi]
        word = np.zeros(N, dtype=np.uint64)
        for b in range(hi - lo):
            word |= (chunk[:, b] << np.uint64(b))
        out[:, w] = word
    with open(path, "wb") as f:
        f.write(struct.pack("<qq", N, WORDS))
        f.write(out.tobytes())
    return N, WORDS


def brute_omega_small(A):
    """Trivial exact clique number for small n (<=16), independent of the
    C solver -- used only to cross-check the tiny base graphs themselves."""
    n = A.shape[0]
    best = 0
    def ext(R, P):
        nonlocal best
        if not P:
            best = max(best, len(R))
            return
        if len(R) + len(P) <= best:
            return
        v = P[0]
        rest = P[1:]
        ext(R + [v], [u for u in rest if A[v, u]])
        ext(R, rest)
    ext([], list(range(n)))
    return best


if __name__ == "__main__":
    graphs = {}
    C7 = cycle_graph(7);  validate("C7", C7, 7, 2, 7);          graphs["C7"] = C7
    C9 = cycle_graph(9);  validate("C9", C9, 9, 2, 9);          graphs["C9"] = C9
    Pet = petersen_graph(); validate("Petersen", Pet, 10, 3, 15); graphs["Petersen"] = Pet
    Pal13 = paley_graph(13); validate("Paley13", Pal13, 13, 6, 39); graphs["Paley13"] = Pal13

    print("Base graph validation OK (n, regular degree, edge count all match known values):")
    for name, A in graphs.items():
        print(f"  {name}: n={A.shape[0]}, degree={int(A.sum(axis=1)[0])}, edges={int(A.sum()//2)}")

    print("\nSingle-copy (k=1) exact clique numbers (independent brute force):")
    expected1 = {"C7": 2, "C9": 2, "Petersen": 2, "Paley13": 3}
    for name, A in graphs.items():
        w = brute_omega_small(A)
        status = "OK" if w == expected1[name] else "MISMATCH"
        print(f"  omega({name}) = {w}  (expect {expected1[name]})  [{status}]")
        assert w == expected1[name]

    os.makedirs("bin", exist_ok=True)
    manifest = []
    for name, A in graphs.items():
        for k in (1, 2, 3):
            M = or_power(A, k)
            path = f"bin/{name}_k{k}.bin"
            N, WORDS = pack_and_write(path, M)
            deg0 = int(M[0].sum())
            manifest.append((name, k, N, WORDS, deg0))
            print(f"wrote {path}: N={N} WORDS={WORDS} deg(vertex0)={deg0}")

    with open("manifest.txt", "w") as f:
        for row in manifest:
            f.write(" ".join(str(x) for x in row) + "\n")
    print("\nDone.")
