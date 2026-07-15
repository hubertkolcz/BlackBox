"""Finite part of the all-n theorem: decide 9-clique in Cn v Cn v C5 for odd n.

Analytic part (Lovasz theta, multiplicative under strong products; the
complement of the conormal product is the strong product of complements):
  omega(Cn v Cn v C5) <= theta(comp Cn)^2 * sqrt5
  even n: theta(comp Cn) = 2            -> ceiling 4*sqrt5 = 8.944 < 9: settled
  odd n:  theta(comp Cn) = 1+sec(pi/n)  -> ceiling < 9 iff n >= 29: settled
Remaining: odd n in 9..27, decided here by the pentagram-layer reduction with
two extra exact savings:
  (a) every admissible size vector contains a 1 and its chain can be rotated to
      start there; translation symmetry of Cn v Cn pins that singleton to
      {(0,0)} - one starting clique instead of ~n^2;
  (b) a size-3 layer forces both pentagram partners to size 1, so consecutive
      class pairs are only (1,1),(1,2),(2,1),(2,2),(1,3),(3,1): the (3,3) and
      (2,3) compatibility blocks are never needed.
Controls: n=7 must return the known YES (verified witness); n=9,13,15 must
reproduce the earlier flat-solver NOs.
"""
import itertools, sys, time
import numpy as np

PENT = [0, 2, 4, 1, 3]

def build(n):
    """Adjacency of H = Cn v Cn as bool matrix; vertex (a,b) -> a*n+b."""
    nH = n * n
    a = np.arange(nH) // n
    b = np.arange(nH) % n
    da = (a[:, None] - a[None, :]) % n
    db = (b[:, None] - b[None, :]) % n
    A = ((da == 1) | (da == n - 1)) | ((db == 1) | (db == n - 1))
    np.fill_diagonal(A, False)
    return A

def cliques_by_size(A):
    """cl[s] = int array (K_s, s) of vertex indices, s = 1,2,3."""
    nH = len(A)
    ones = np.arange(nH).reshape(-1, 1)
    e = np.argwhere(np.triu(A, 1))                      # edges u < v
    tris = []
    for u, v in e:
        w = np.flatnonzero(A[u] & A[v])
        w = w[w > v]
        if len(w):
            tris.append(np.stack([np.full(len(w), u), np.full(len(w), v), w], 1))
    t = np.concatenate(tris) if tris else np.empty((0, 3), int)
    return {1: ones, 2: e, 3: t}

def na_masks(A, cl):
    """na[s][i, v] = True iff v adjacent to every member of clique i."""
    na = {1: A.copy()}
    na[2] = A[cl[2][:, 0]] & A[cl[2][:, 1]]
    na[3] = A[cl[3][:, 0]] & A[cl[3][:, 1]] & A[cl[3][:, 2]]
    return na

def compat_block(cl_t, na_s, chunk=4096):
    """bool (K_s, K_t): [a, b] = True iff Q_b subset of N(Q_a) (=> disjoint)."""
    Ks, Kt = len(na_s), len(cl_t)
    Ct = np.zeros((Kt, na_s.shape[1]), dtype=np.float32)
    rows = np.repeat(np.arange(Kt), cl_t.shape[1])
    Ct[rows, cl_t.ravel()] = 1.0
    out = np.zeros((Ks, Kt), dtype=bool)
    for lo in range(0, Ks, chunk):
        hi = min(lo + chunk, Ks)
        notNA = (~na_s[lo:hi]).astype(np.float32)
        out[lo:hi] = (notNA @ Ct.T) == 0                 # [a, b]: |Q_b \ N(Q_a)| = 0
    return out

def decide(n, verbose=True):
    t0 = time.time()
    A = build(n)
    cl = cliques_by_size(A)
    na = na_masks(A, cl)
    sizes = {s: len(cl[s]) for s in (1, 2, 3)}

    vecs = [v for v in itertools.product((1, 2, 3), repeat=5)
            if sum(v) == 9 and all(v[i] + v[(i + 2) % 5] <= 4 for i in range(5))]
    chains = []
    for vec in vecs:
        m = [vec[p] for p in PENT]
        r = m.index(1)                                   # rotate chain to start at a 1
        chains.append([m[(r + j) % 5] for j in range(5)])
    need = sorted({(c[j], c[(j + 1) % 5]) for c in chains for j in range(5)})
    assert set(need) <= {(1, 1), (1, 2), (2, 1), (2, 2), (1, 3), (3, 1)}, need

    blocks = {(s, t): compat_block(cl[t], na[s]) for s, t in need}
    if verbose:
        print(f"n={n}: cliques {sizes}, blocks {need} "
              f"[built in {time.time()-t0:.0f}s]", flush=True)

    a0 = 0                                               # singleton {(0,0)}
    for chain in chains:
        F = [None] * 5
        F[0] = np.zeros(sizes[1], bool); F[0][a0] = True
        ok = True
        for j in range(1, 5):
            s, t = chain[j - 1], chain[j]
            rows = np.flatnonzero(F[j - 1])
            F[j] = np.logical_or.reduce(blocks[(s, t)][rows], axis=0) \
                if len(rows) else np.zeros(sizes[t], bool)
            if not F[j].any():
                ok = False
                break
        if not ok:
            continue
        closing = F[4] & blocks[(1, chain[4])][a0]       # compat with a0, symmetric
        if closing.any():
            # reconstruct: pick b4 then walk back
            pick = [None] * 5
            pick[0] = a0
            pick[4] = int(np.flatnonzero(closing)[0])
            for j in (3, 2, 1):
                s, t = chain[j], chain[j + 1]
                cand = np.flatnonzero(F[j] & blocks[(s, t)][:, pick[j + 1]])
                pick[j] = int(cand[0])
            return chain, [cl[chain[j]][pick[j]] for j in range(5)], time.time() - t0
    return None, None, time.time() - t0

def verify_witness(n, chain, qs):
    """Assemble tuples and check all 36 pairs + distinctness, pure python."""
    # chain position j sits on C5 layer: rotation r was applied; layers follow
    # the pentagram order starting wherever - relabel layers 0,2,4,1,3 rotated:
    # position j -> layer PENT[(PENT.index? )]; simpler: positions are cyclically
    # consecutive on the pentagram, so assign layer l_j with l_{j+1} = l_j + 2 mod 5.
    lay = [(2 * j) % 5 for j in range(5)]
    w = sorted((int(v) // n, int(v) % n, lay[j]) for j, Q in enumerate(qs) for v in Q)
    ok = len(set(w)) == 9 and all(
        (u[0] - v[0]) % n in (1, n - 1) or (u[1] - v[1]) % n in (1, n - 1)
        or (u[2] - v[2]) % 5 in (1, 4)
        for u, v in itertools.combinations(w, 2))
    return ok, w

if __name__ == "__main__":
    ns = [int(x) for x in sys.argv[1:]] or [7, 9, 13, 15, 17, 19, 21, 23, 25, 27]
    for n in ns:
        chain, qs, dt = decide(n)
        if qs is None:
            print(f"n={n}: NO 9-clique (exhaustive)  [{dt:.0f}s]", flush=True)
        else:
            ok, w = verify_witness(n, chain, qs)
            print(f"n={n}: 9-CLIQUE FOUND, verified={ok}: {w}  [{dt:.0f}s]", flush=True)
