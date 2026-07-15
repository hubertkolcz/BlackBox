"""Build packed adjacency .bin for the ERG-003 cell G = C9 v C9 v C9 v C5
(conormal/OR product, 3645 vertices) in the exact format d1_k3_maxclique.c reads
(int64 N, int64 WORDS, then N*WORDS uint64 words row-major; bit b of word w in
row i = i adjacent to w*64+b). Also validates the packer by rebuilding
H = C9 v C9 v C9 and byte-comparing to bin/Hc9x3.bin.

Vertex order: (a,b,c,d), a,b,c in 0..8, d in 0..4, index = ((a*9+b)*9+c)*5+d.
This is itertools.product([9,9,9,5]) lexicographic order (matches the essay /
structure_check convention with the C5 catalyst as the last coordinate).
"""
import itertools
import os
import struct
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))


def pack_and_write(path, M):
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


def conormal(dims):
    """Adjacency of the OR/conormal product of cycles C_{dims[i]}.
    Vertices in itertools.product(range(d0),range(d1),...) lexicographic order."""
    verts = np.array(list(itertools.product(*[range(d) for d in dims])), dtype=np.int64)
    N = verts.shape[0]
    M = np.zeros((N, N), dtype=bool)
    for t, d in enumerate(dims):
        col = verts[:, t]
        diff = (col[:, None] - col[None, :]) % d
        M |= (diff == 1) | (diff == d - 1)
    np.fill_diagonal(M, False)
    return M, verts


def main():
    # --- validate packer: rebuild H=C9^3 and byte-compare to bin/Hc9x3.bin ---
    MH, _ = conormal([9, 9, 9])
    NH, WH = pack_and_write(os.path.join(HERE, "bin", "_Hcheck.bin"), MH)
    ref = os.path.join(HERE, "bin", "Hc9x3.bin")
    if os.path.exists(ref):
        with open(ref, "rb") as f:
            a = f.read()
        with open(os.path.join(HERE, "bin", "_Hcheck.bin"), "rb") as f:
            b = f.read()
        print(f"H packer validation vs Hc9x3.bin: "
              f"{'IDENTICAL' if a == b else 'DIFFERENT'} "
              f"(N={NH} WORDS={WH}, deg0={int(MH[0].sum())})", flush=True)
        if a != b:
            print("WARNING: packer mismatch -- coordinate order differs; aborting.",
                  flush=True)
            sys.exit(1)
    os.remove(os.path.join(HERE, "bin", "_Hcheck.bin"))

    # --- build G = C9 v C9 v C9 v C5 ---
    MG, verts = conormal([9, 9, 9, 5])
    N = MG.shape[0]
    deg0 = int(MG[0].sum())
    # sanity: expected deg(0) = 3645 - 1 - 7*7*7*3 (non-neighbors: each coord
    # non-adjacent; C9 non-adj to 0 = {0,2,3,4,5,6,7} (7 vals incl self),
    # C5 non-adj to 0 = {0,2,3} (3 vals)) = 3645-1-1029+... self counted once
    nonneigh = 7 * 7 * 7 * 3 - 1   # minus self
    exp_deg0 = N - 1 - nonneigh
    path = os.path.join(HERE, "bin", "Gc9x3_c5.bin")
    Nn, Wn = pack_and_write(path, MG)
    print(f"wrote {path}: N={Nn} WORDS={Wn} deg(0)={deg0} (expected {exp_deg0}) "
          f"symmetric={np.array_equal(MG, MG.T)} density={MG.sum()/(N*(N-1)):.3f}",
          flush=True)


if __name__ == "__main__":
    main()
