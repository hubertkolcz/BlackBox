"""Sparsity-exploiting Lovasz theta -- companion solver to BlackBox`LovaszThetaSparse.

NOT a new method (adversarial novelty audit, 11-12 July 2026): route 1 (chordal
decomposition) is Fukuda-Kojima-Murota-Nakata (2000/2001) applied to theta specifically
at comparable scale by R. Zhang, arXiv:2306.15288 / Math. Programming (2024), n=13659.
Route 2 (DFT block-diagonalization for cyclic-symmetric graphs) is Brimkov-Codenotti-
Crespi-Leoncini (LNCS 1767, 2000) and Brimkov et al. (ECCC TR03-081, 2003), subsumed
generally by de Klerk-Pasechnik-Schrijver (Math. Program. 109, 2007). What is new here
is only the application to pentagon-chain/ring meshes from quantum contextuality and the
dual Wolfram/Python validation, not the underlying algorithms.

Two independent exact routes to theta(G) for pentagon meshes with 10^4..10^5 blocks:

1. chordal_theta(n, edges): general sparse graphs.
   theta(G) = min lambda_max(J - B) over B supported on E(G)   (Lovasz dual)
            = min t : M = [[t*I + B, e], [e^T, 1]] >= 0        (Schur on rank-one J = e e^T)
   The support of M is (chordal extension H of G) + apex, which is chordal, so by the
   Grone completion / Agler decomposition theorem the single (n+1)-cone splits into one
   PSD block per maximal clique of H (+ apex).  Cost scales with treewidth, not n.
   Solved with Clarabel (interior point, sparse KKT); SCS fallback.

2. ring_theta_symmetric(N, family): pentagon rings only (Z_N-symmetric meshes).
   TWO distinct ring families exist ("cis"/"trans" gluing orientation, see the builders);
   CaseStudies.wl pentagonRing is the TRANS family, BlackBox`PentagonChain closed up
   cyclically is the CIS family, and they are NOT isomorphic: theta/N -> 1.376717746
   (trans) vs exactly theta = N + theta(C_N) (cis, so theta/N -> 3/2 and even-N cis
   rings sit at alpha = theta = alpha* = 3N/2). PentagonChain pieces are induced
   subgraphs of CIS rings only -- chain-anchored bounds do not transfer to trans rings.
   The ring is block-circulant (blocks a_k, b_k, x_k), so an optimal dual witness B can be
   taken Z_N-invariant; the 3N-dimensional LMI block-diagonalises under the DFT into N
   Hermitian 3x3 symbols A(w) = J3*N*[f=0] + B0 + w*B1 + conj(w)*B1^T, w = exp(2*pi*i*f/N).
   theta = min over 4 reals of max_f lambda_max(A(w_f)) -- solved by cutting planes,
   and the final max_f lambda_max (batched numpy eigvalsh over every frequency) is an
   unconditional eigenvalue certificate theta <= max_f lambda_max(A).

Both routes return an eigenvalue-certified upper bound alongside the solver optimum.
Validation: `python lovasz_theta_sparse.py validate` reproduces the kernel-verified
dense-SDP values of CaseStudies.wl (rings and chains N = 3..15) to 1e-5.
Scaling run:  `python lovasz_theta_sparse.py scaling` -> N = 100, 1000, 10^4, 10^5.
"""

import argparse
import heapq
import math
import sys
import time

import numpy as np
import scipy.sparse as sp

SQRT2 = math.sqrt(2.0)


# ---------------------------------------------------------------------------
# mesh builders (0-based mirrors of BlackBox`PentagonChain / CaseStudies pentagonRing)
# ---------------------------------------------------------------------------

def pentagon_ring(nb):
    """CaseStudies pentagonRing (TRANS gluing): 3*nb vertices a_k=3k, b_k=3k+1,
    x_k=3k+2; 4*nb edges.  Pentagon k = a_{k-1}-b_{k-1}-a_k-b_k-x_k; consecutive
    pentagons share edge (a_k, b_k) and attach their short sides to ALTERNATING
    endpoints of it (b_{k-1}->a_k, then b_k->a_{k+1})."""
    if nb < 3:
        raise ValueError("ring needs nb >= 3")
    a = lambda k: 3 * (k % nb)
    b = lambda k: 3 * (k % nb) + 1
    x = lambda k: 3 * (k % nb) + 2
    edges = set()
    for k in range(nb):
        for u, v in ((a(k - 1), b(k - 1)), (b(k - 1), a(k)), (a(k), b(k)),
                     (b(k), x(k)), (x(k), a(k - 1))):
            edges.add((min(u, v), max(u, v)))
    return 3 * nb, sorted(edges)


def pentagon_ring_cis(nb):
    """Cyclic closure of BlackBox`PentagonChain (CIS gluing): the short sides of
    consecutive pentagons attach to the SAME endpoint of each shared edge, so the
    c1 vertices form a rail c1_0-c1_1-...-c1_{nb-1}-c1_0.  Vertices c1_k=3k,
    c2_k=3k+1, c3_k=3k+2; pentagon k = c1_{k-1}-c1_k-c2_k-c3_k-c2_{k-1}; 4*nb edges.
    NOT isomorphic to pentagon_ring: the two meshes differ in gluing orientation."""
    if nb < 3:
        raise ValueError("ring needs nb >= 3")
    c1 = lambda k: 3 * (k % nb)
    c2 = lambda k: 3 * (k % nb) + 1
    c3 = lambda k: 3 * (k % nb) + 2
    edges = set()
    for k in range(nb):
        for u, v in ((c1(k - 1), c1(k)), (c1(k), c2(k)), (c2(k), c3(k)),
                     (c3(k), c2(k - 1)), (c2(k - 1), c1(k - 1))):
            edges.add((min(u, v), max(u, v)))
    return 3 * nb, sorted(edges)


def pentagon_chain(nb):
    """3*nb + 2 vertices, edge-glued pentagons; mirrors BlackBox`PentagonChain (0-based)."""
    e0, base = (0, 1), 1
    edges = set()
    for _ in range(nb):
        for u, v in ((e0[0], base + 1), (base + 1, base + 2), (base + 2, base + 3),
                     (base + 3, e0[1]), (e0[1], e0[0])):
            edges.add((min(u, v), max(u, v)))
        e0, base = (base + 1, base + 2), base + 3
    return 3 * nb + 2, sorted(edges)


def cycle_graph(n):
    return n, [(i, (i + 1) % n) if i + 1 < n else (0, n - 1) for i in range(n)]


def pentagon_ring_word(word, reps=1):
    """Necklace of edge-glued pentagons with per-gluing orientation word in {t,c}:
    letter k orients the entry of pentagon k+1 on pentagon k's exit edge (c1_k, c2_k)
    -- 'c' keeps the short-side endpoint (u' = c1_k), 't' alternates (u' = c2_k).
    'c'*L reproduces pentagon_ring_cis(L) and 't'*L reproduces pentagon_ring(L)
    with identical vertex labels (c1_k = 3k, c2_k = 3k+1, c3_k = 3k+2)."""
    w = word * reps
    L = len(w)
    if L < 3:
        raise ValueError("need at least 3 blocks")
    edges = set()
    for k in range(L):
        km = (k - 1) % L
        c1p, c2p = 3 * km, 3 * km + 1
        u, v = (c1p, c2p) if w[km] == "c" else (c2p, c1p)
        c1, c2, c3 = 3 * k, 3 * k + 1, 3 * k + 2
        for a, b in ((u, v), (u, c1), (c1, c2), (c2, c3), (c3, v)):
            edges.add((min(a, b), max(a, b)))
    return 3 * L, sorted(edges)


def alpha_ring_word(word, reps=1):
    """Exact independence number of pentagon_ring_word(word, reps) by a max-plus
    transfer DP over the glue-edge interface. State = independent-set restriction
    to the entry pair (u, v) in {(0,0), (1,0), (0,1)}; each pentagon contributes
    its three new vertices c1, c2, c3 subject to the 5-cycle constraints; the
    letter decides whether the exit pair (c1, c2) enters the next block straight
    ('c') or swapped ('t')."""
    w = word * reps
    L = len(w)
    states = [(0, 0), (1, 0), (0, 1)]
    NEG = -(10 ** 9)

    def transfer(letter):
        T = [[NEG] * 3 for _ in range(3)]
        for i, (su, sv) in enumerate(states):
            for s1 in (0, 1):
                if su and s1:
                    continue
                for s2 in (0, 1):
                    if s1 and s2:
                        continue
                    for s3 in (0, 1):
                        if (s2 and s3) or (s3 and sv):
                            continue
                        out = (s1, s2) if letter == "c" else (s2, s1)
                        j = states.index(out)
                        T[i][j] = max(T[i][j], s1 + s2 + s3)
        return T

    Tc, Tt = transfer("c"), transfer("t")
    best = NEG
    for s0 in range(3):
        vec = [NEG] * 3
        vec[s0] = 0
        for k in range(L):
            T = Tc if w[k] == "c" else Tt
            vec = [max(vec[i] + T[i][j] for i in range(3)) for j in range(3)]
        best = max(best, vec[s0])
    return best


def alpha_density_word(word):
    """Exact per-block limit alpha(word^m)/(m len(word)) as m -> infinity: the
    max-plus cycle mean of the one-period transfer product (exact Fraction)."""
    from fractions import Fraction
    NEG = -(10 ** 9)
    P = None
    # rebuild the two 3x3 transfer matrices via alpha_ring_word's local logic
    states = [(0, 0), (1, 0), (0, 1)]

    def transfer(letter):
        T = [[NEG] * 3 for _ in range(3)]
        for i, (su, sv) in enumerate(states):
            for s1 in (0, 1):
                if su and s1:
                    continue
                for s2 in (0, 1):
                    if s1 and s2:
                        continue
                    for s3 in (0, 1):
                        if (s2 and s3) or (s3 and sv):
                            continue
                        j = states.index((s1, s2) if letter == "c" else (s2, s1))
                        T[i][j] = max(T[i][j], s1 + s2 + s3)
        return T

    def mp_mul(A, B):
        return [[max(A[i][k] + B[k][j] for k in range(3)) for j in range(3)]
                for i in range(3)]

    Tc, Tt = transfer("c"), transfer("t")
    for ch in word:
        M = Tc if ch == "c" else Tt
        P = M if P is None else mp_mul(P, M)
    # max cycle mean over cycles of length 1..3 in the period-product matrix
    best = Fraction(NEG)
    Q = P
    for ell in range(1, 4):
        for i in range(3):
            best = max(best, Fraction(Q[i][i], ell))
        Q = mp_mul(Q, P)
    return best / len(word)


def pentagon_chain_word(word):
    """OPEN chain of m = len(word)+1 edge-glued pentagons with per-gluing
    orientation letters (3m+2 vertices: seed glue edge (0,1), block k adds
    3k+2, 3k+3, 3k+4). 'c'*(m-1) reproduces BlackBox`PentagonChain[m] with
    identical vertex labels; 't'*(m-1) is the open TRANS chain."""
    m = len(word) + 1
    edges = set()
    u, v = 0, 1
    for k in range(m):
        a, b, x = 3 * k + 2, 3 * k + 3, 3 * k + 4
        for p, q in ((u, v), (u, a), (a, b), (b, x), (x, v)):
            edges.add((min(p, q), max(p, q)))
        if k < m - 1:
            u, v = (a, b) if word[k] == "c" else (b, a)
    return 3 * m + 2, sorted(edges)


def alpha_chain_word(word):
    """Exact independence number of pentagon_chain_word(word) by the open-
    boundary version of the interface transfer DP (seed pair counted)."""
    m = len(word) + 1
    states = [(0, 0), (1, 0), (0, 1)]
    NEG = -(10 ** 9)
    vec = [su + sv for (su, sv) in states]   # seed vertices contribute
    for k in range(m):
        letter = word[k] if k < m - 1 else "c"   # last exit unused
        new = [NEG] * 3
        for i, (su, sv) in enumerate(states):
            if vec[i] <= NEG // 2:
                continue
            for s1 in (0, 1):
                if su and s1: continue
                for s2 in (0, 1):
                    if s1 and s2: continue
                    for s3 in (0, 1):
                        if (s2 and s3) or (s3 and sv): continue
                        out = (s1, s2) if letter == "c" else (s2, s1)
                        j = states.index(out)
                        new[j] = max(new[j], vec[i] + s1 + s2 + s3)
        vec = new
    return max(vec)


def word_density_transfer_sdp(word, solver="clarabel"):
    """EXACT theta-density of the periodic gluing word by the position-space
    transfer SDP: per position one Q block (5x5 on the glue quad u,v,A,B +
    apex) and one R block (4x4 on v,B,X + apex), uniform unit diagonal and
    border, fills zero; minimize the mean apex-corner sum d. Certified by the
    same Schur/assembly argument as EpsilonCertificate.wl; agrees with the
    DFT-symbol route to solver precision without any symmetry reduction."""
    import clarabel as _cl
    p = len(word)
    T5, T4 = 15, 10
    qoff = {k: k * T5 for k in range(p)}
    roff = {k: p * T5 + k * T4 for k in range(p)}
    nvar = p * (T5 + T4)
    def sidx(i, j):
        if i > j: i, j = j, i
        return j * (j + 1) // 2 + i
    qv = lambda k, i, j: qoff[k % p] + sidx(i, j)
    rv = lambda k, i, j: roff[k % p] + sidx(i, j)
    IU, IV, IA, IB, IP = range(5)
    JV, JB, JX, JP = range(4)
    rows, cols, vals, bvals = [], [], [], []
    def add(terms, rhs):
        r = len(bvals)
        for var, coef in terms:
            rows.append(r); cols.append(var); vals.append(coef)
        bvals.append(rhs)
    for k in range(p):
        add([(rv(k, JX, JX), 1.0)], 1.0)
        add([(rv(k, JX, JP), 1.0)], 1.0)
        add([(qv(k, IV, IA), 1.0)], 0.0)
        add([(qv(k, IU, IB), 1.0)], 0.0)
        add([(qv(k, IV, IB), 1.0), (rv(k, JV, JB), 1.0)], 0.0)
        b = word[k]
        rA, rB = (IU, IV) if b == "c" else (IV, IU)
        kp = (k + 1) % p
        t = [(qv(k, IA, IA), 1.0), (qv(kp, rA, rA), 1.0)]
        if b == "t": t.append((rv(kp, JV, JV), 1.0))
        add(t, 1.0)
        t = [(qv(k, IB, IB), 1.0), (rv(k, JB, JB), 1.0), (qv(kp, rB, rB), 1.0)]
        if b == "c": t.append((rv(kp, JV, JV), 1.0))
        add(t, 1.0)
        t = [(qv(k, IA, IP), 1.0), (qv(kp, rA, IP), 1.0)]
        if b == "t": t.append((rv(kp, JV, JP), 1.0))
        add(t, 1.0)
        t = [(qv(k, IB, IP), 1.0), (rv(k, JB, JP), 1.0), (qv(kp, rB, IP), 1.0)]
        if b == "c": t.append((rv(kp, JV, JP), 1.0))
        add(t, 1.0)
    neq = len(bvals)
    dims = []
    for k in range(p):
        for (i, j) in [(i, j) for j in range(5) for i in range(j + 1)]:
            r = len(bvals)
            rows.append(r); cols.append(qv(k, i, j))
            vals.append(-1.0 if i == j else -SQRT2)
            bvals.append(0.0)
        dims.append(5)
    for k in range(p):
        for (i, j) in [(i, j) for j in range(4) for i in range(j + 1)]:
            r = len(bvals)
            rows.append(r); cols.append(rv(k, i, j))
            vals.append(-1.0 if i == j else -SQRT2)
            bvals.append(0.0)
        dims.append(4)
    A = sp.csc_matrix((vals, (rows, cols)), shape=(len(bvals), nvar))
    c = np.zeros(nvar)
    for k in range(p):
        c[qv(k, IP, IP)] += 1.0
        c[rv(k, JP, JP)] += 1.0
    cones = [_cl.ZeroConeT(neq)] + [_cl.PSDTriangleConeT(d) for d in dims]
    st = _cl.DefaultSettings(); st.verbose = False
    st.tol_gap_abs = st.tol_gap_rel = st.tol_feas = 1e-11
    P = sp.csc_matrix((nvar, nvar))
    res = _cl.DefaultSolver(P, c, A, np.array(bvals), cones, st).solve()
    x = np.array(res.x)
    return sum(x[qv(k, IP, IP)] + x[rv(k, JP, JP)] for k in range(p)) / p


# ---------------------------------------------------------------------------
# chordal extension: minimum-degree elimination with lazy heap
# ---------------------------------------------------------------------------

def chordal_cliques(n, edges):
    """Bags of a min-degree elimination; parent-absorbed bags dropped.
    Returns list of sorted vertex tuples (cliques of the chordal extension H;
    every pair co-occurring in a bag is an edge of H)."""
    adj = [set() for _ in range(n)]
    for u, v in edges:
        adj[u].add(v)
        adj[v].add(u)
    heap = [(len(adj[v]), v) for v in range(n)]
    heapq.heapify(heap)
    eliminated = [False] * n
    elim_index = [-1] * n
    bags = []  # (v, madj frozenset)
    while heap:
        d, v = heapq.heappop(heap)
        if eliminated[v] or d != len(adj[v]):
            continue
        eliminated[v] = True
        elim_index[v] = len(bags)
        nb = adj[v]
        bags.append((v, frozenset(nb)))
        nbl = list(nb)
        for i, u in enumerate(nbl):
            adj[u].discard(v)
            for w in nbl[i + 1:]:
                if w not in adj[u]:
                    adj[u].add(w)
                    adj[w].add(u)
        for u in nbl:
            heapq.heappush(heap, (len(adj[u]), u))
        adj[v] = set()
    keep = [True] * len(bags)
    for i, (v, madj) in enumerate(bags):
        if madj:
            p = min(madj, key=lambda u: elim_index[u])  # parent: first-eliminated neighbour
            pi = elim_index[p]
            if bags[pi][1] <= (madj - {p}):             # B_p subset of B_v -> drop B_p
                keep[pi] = False
    return [tuple(sorted((v, *madj))) for i, (v, madj) in enumerate(bags) if keep[i]]


# ---------------------------------------------------------------------------
# conic assembly + solve (Clarabel primary, SCS fallback)
# ---------------------------------------------------------------------------

def _svec_positions(d, order):
    """(row, col) pairs, row <= col, in the solver's svec order."""
    if order == "upper_col":    # Clarabel: upper triangle stacked by columns
        return [(p, q) for q in range(d) for p in range(q + 1)]
    if order == "lower_col":    # SCS: lower triangle stacked by columns
        return [(q, p) for q in range(d) for p in range(q, d)]
    raise ValueError(order)


def _assemble(n, edges, cliques, order, scale=1.0):
    """Conic problem  min tau  s.t.  A x = b on Zero rows, block svecs PSD.
    x = [tau] ++ svec(S_j) blocks (off-diagonals carry the sqrt(2) svec scaling).
    The LMI is solved for M' = D M D with D = diag(1/sqrt(scale),...,1), so all
    entries stay O(1) at any mesh size: diagonal sums to tau = t/scale, border
    to 1/sqrt(scale), corner to 1; theta = scale * tau."""
    edge_set = set(edges)
    dims = [len(K) + 1 for K in cliques]          # apex appended to every clique
    offs = np.zeros(len(cliques) + 1, dtype=np.int64)
    for j, d in enumerate(dims):
        offs[j + 1] = offs[j] + d * (d + 1) // 2
    nvar = 1 + int(offs[-1])

    diag_terms = [[] for _ in range(n)]     # vertex -> [xvar]
    bord_terms = [[] for _ in range(n)]
    corn_terms = []
    fill_terms = {}                          # (i,i') -> [xvar]
    for j, K in enumerate(cliques):
        d = dims[j]
        pos = _svec_positions(d, order)
        loc = {(p, q): r for r, (p, q) in enumerate(pos)}
        base = 1 + int(offs[j])
        m = d - 1
        for p in range(m):
            diag_terms[K[p]].append(base + loc[(p, p)])
            bord_terms[K[p]].append(base + loc[(p, m)])
        corn_terms.append(base + loc[(m, m)])
        for p in range(m):
            for q in range(p + 1, m):
                pr = (K[p], K[q])
                if pr not in edge_set:
                    fill_terms.setdefault(pr, []).append(base + loc[(p, q)])

    rows, cols, vals, bvals = [], [], [], []

    def add_row(terms, coeff, rhs):
        r = len(bvals)
        for c in terms:
            rows.append(r), cols.append(c), vals.append(coeff)
        bvals.append(rhs)
        return r

    for i in range(n):                       # sum_j S_j[ii] - tau = 0
        r = add_row(diag_terms[i], 1.0, 0.0)
        rows.append(r), cols.append(0), vals.append(-1.0)
    for i in range(n):                       # sum_j S_j[i,apex] = 1/sqrt(scale)
        add_row(bord_terms[i], 1.0, SQRT2 / math.sqrt(scale))
    add_row(corn_terms, 1.0, 1.0)            # sum_j S_j[apex,apex] = 1
    for pr, terms in fill_terms.items():     # extension fill pairs vanish
        add_row(terms, 1.0, 0.0)
    neq = len(bvals)

    psd_rows = int(offs[-1])
    r0 = neq
    rows.extend(range(r0, r0 + psd_rows))
    cols.extend(range(1, 1 + psd_rows))
    vals.extend([-1.0] * psd_rows)
    bvals.extend([0.0] * psd_rows)

    A = sp.csc_matrix((vals, (rows, cols)), shape=(neq + psd_rows, nvar))
    b = np.array(bvals)
    c = np.zeros(nvar)
    c[0] = 1.0
    return A, b, c, neq, dims, offs


def _certify_upper(n, edges, cliques, dims, offs, x, order, scale=1.0):
    """Read the dual witness B off the solution, return lambda_max(J - B):
    an unconditional upper bound on theta for ANY x (Lovasz dual feasibility)."""
    from scipy.sparse.linalg import eigsh, LinearOperator
    t = x[0] * scale
    acc = {}
    for j, K in enumerate(cliques):
        d = dims[j]
        pos = _svec_positions(d, order)
        base = 1 + int(offs[j])
        m = d - 1
        for r, (p, q) in enumerate(pos):
            if p < q < m:
                pr = (K[p], K[q])
                acc[pr] = acc.get(pr, 0.0) + scale * x[base + r] / SQRT2
    edge_set = set(edges)
    items = [(u, v, w) for (u, v), w in acc.items() if (u, v) in edge_set]
    if items:
        iu, iv, w = map(np.array, zip(*items))
        B = sp.coo_matrix((np.concatenate([w, w]),
                           (np.concatenate([iu, iv]), np.concatenate([iv, iu]))),
                          shape=(n, n)).tocsr()
    else:
        B = sp.csr_matrix((n, n))
    if n <= 400:
        lam = float(np.linalg.eigvalsh(np.ones((n, n)) - B.toarray())[-1])
    else:
        op = LinearOperator((n, n), matvec=lambda v: np.full(n, v.sum()) - B @ v,
                            dtype=float)
        lam = None
        for k, ncv in ((1, 64), (4, 128), (8, 256)):   # widen Krylov space if the
            try:                                        # top of the spectrum clusters
                ev = eigsh(op, k=k, which="LA", return_eigenvectors=False,
                           v0=np.ones(n), ncv=min(n - 1, ncv), tol=1e-9,
                           maxiter=100000)
                lam = float(ev.max())
                break
            except Exception:
                continue
        if lam is None:
            if n <= 5000:
                lam = float(np.linalg.eigvalsh(np.ones((n, n)) - B.toarray())[-1])
            else:
                return float("nan"), float("nan")
    return lam, abs(lam - t)


def chordal_theta(n, edges, solver="clarabel", verbose=False):
    """theta(G) by chordal decomposition. Returns dict with Theta, UpperBound,
    CliqueCount, MaxClique, Vars, Rows, SetupTime, SolveTime, Status."""
    t0 = time.perf_counter()
    cliques = chordal_cliques(n, edges)
    order = "upper_col" if solver == "clarabel" else "lower_col"
    scale = float(max(1, n))          # keeps all LMI entries O(1) at any mesh size
    A, b, c, neq, dims, offs = _assemble(n, edges, cliques, order, scale)
    setup = time.perf_counter() - t0

    t0 = time.perf_counter()
    if solver == "clarabel":
        import clarabel
        cones = [clarabel.ZeroConeT(neq)] + [clarabel.PSDTriangleConeT(d) for d in dims]
        settings = clarabel.DefaultSettings()
        settings.verbose = verbose
        settings.tol_gap_abs = 1e-9
        settings.tol_gap_rel = 1e-9
        settings.tol_feas = 1e-9
        settings.max_iter = 500
        P = sp.csc_matrix((len(c), len(c)))
        s = clarabel.DefaultSolver(P, c, A, b, cones, settings)
        res = s.solve()
        x = np.array(res.x)
        status = str(res.status)
    elif solver == "scs":
        import scs
        data = {"A": A, "b": b, "c": c}
        cone = {"z": neq, "s": dims}
        res = scs.solve(data, cone, verbose=verbose, eps_abs=1e-7, eps_rel=1e-9,
                        max_iters=200000)
        x = np.array(res["x"])
        status = res["info"]["status"]
    else:
        raise ValueError(solver)
    solve = time.perf_counter() - t0

    upper, gap = _certify_upper(n, edges, cliques, dims, offs, x, order, scale)
    return {"Theta": float(x[0]) * scale, "UpperBound": upper, "CertGap": gap,
            "CliqueCount": len(cliques), "MaxClique": max(dims) - 1,
            "Vars": A.shape[1], "Rows": A.shape[0],
            "SetupTime": setup, "SolveTime": solve, "Status": status}


# ---------------------------------------------------------------------------
# Z_N symmetry-reduced solver for pentagon rings
# ---------------------------------------------------------------------------

# edge orbits of the two Z_N-symmetric ring families, as supports of the
# block-circulant parameter matrices B0 (offset 0) and B1 (offset +1):
# trans (pentagon_ring):     B0 on (a,b),(b,x);  B1 on b->a, a->x
# cis (pentagon_ring_cis):   B0 on (c1,c2),(c2,c3);  B1 on c1->c1, c2->c3
RING_SPECS = {"trans": {"b0": [(0, 1), (1, 2)], "b1": [(1, 0), (0, 2)]},
              "cis":   {"b0": [(0, 1), (1, 2)], "b1": [(0, 0), (1, 2)]}}


def _ring_symbols(N, freqs, params, spec, j0=None):
    """Hermitian 3x3 symbols A(w_f) for the ring dual, batched over freqs.
    j0 is the weight of the all-ones block at f = 0 (N in original units;
    pass 1 to work in density units theta/N, which keeps entries O(1))."""
    b0, b1 = spec["b0"], spec["b1"]
    B0 = np.zeros((3, 3), dtype=complex)
    B1 = np.zeros((3, 3), dtype=complex)
    for (i, j), v in zip(b0, params[:len(b0)]):
        B0[i, j] = B0[j, i] = v
    for (i, j), v in zip(b1, params[len(b0):]):
        B1[i, j] = v
    w = np.exp(2j * np.pi * np.asarray(freqs) / N)
    H = (B0[None, :, :] + w[:, None, None] * B1[None, :, :]
         + np.conj(w)[:, None, None] * B1.conj().T[None, :, :])
    H[np.asarray(freqs) == 0] += (N if j0 is None else j0) * np.ones((3, 3))
    return H


def _ring_lambda_max(N, params, spec, j0=None):
    freqs = np.arange(N // 2 + 1)
    lam = np.linalg.eigvalsh(_ring_symbols(N, freqs, params, spec, j0))[:, -1]
    return lam, freqs


def ring_theta_symmetric(N, family="trans", tol=1e-8, verbose=False):
    """Exact theta(pentagon ring N) via the Z_N-reduced dual; cutting planes on
    frequencies. Returns dict with Theta, UpperBound (certified), Cuts, Rounds."""
    import clarabel
    spec = RING_SPECS[family]
    npar = len(spec["b0"]) + len(spec["b1"])
    t0 = time.perf_counter()
    active = sorted(set([0] + list(np.linspace(1, N // 2, min(32, N // 2), dtype=int))))
    zdim = 1 + npar  # t plus the orbit weights
    basis = np.eye(npar)  # parameter directions (t handled separately)
    rounds = 0
    theta = None
    while True:
        rounds += 1
        blocks, bvals, Acols = [], [], [[] for _ in range(zdim)]
        rows_so_far = 0
        dims = []
        for f in active:
            # density units (j0 = 1): entries stay O(1) at any N, theta = N * t
            const = _ring_symbols(N, [f], np.zeros(npar), spec, j0=1.0)[0]
            mats = [_ring_symbols(N, [f], e, spec, j0=1.0)[0] - const for e in basis]
            real = (f == 0) or (2 * f == N)
            if real:
                d = 3
                Kc = -const.real
                Kt = np.eye(3)
                Km = [-m.real for m in mats]
            else:
                d = 6
                def realify(Hr, Hi):
                    return np.block([[Hr, Hi], [-Hi, Hr]])
                Kc = realify(-const.real, const.imag)
                Kt = np.eye(6)
                Km = [realify(-m.real, m.imag) for m in mats]
            pos = _svec_positions(d, "upper_col")
            scale = np.array([1.0 if p == q else SQRT2 for p, q in pos])
            sv = lambda M: np.array([M[p, q] for p, q in pos]) * scale
            bvals.append(sv(Kc))
            Acols[0].append(-sv(Kt))          # t coefficient
            for i in range(npar):
                Acols[1 + i].append(-sv(Km[i]))
            dims.append(d)
            rows_so_far += len(pos)
        b = np.concatenate(bvals)
        A = sp.csc_matrix(np.column_stack([np.concatenate(col) for col in Acols]))
        c = np.zeros(zdim)
        c[0] = 1.0
        cones = [clarabel.PSDTriangleConeT(d) for d in dims]
        settings = clarabel.DefaultSettings()
        settings.verbose = False
        P = sp.csc_matrix((zdim, zdim))
        res = clarabel.DefaultSolver(P, c, A, b, cones, settings).solve()
        z = np.array(res.x)
        theta = z[0]
        lam, freqs = _ring_lambda_max(N, z[1:], spec, j0=1.0)
        worst = float(lam.max())
        if verbose:
            print(f"  round {rounds}: t={theta:.9f} cuts={len(active)} "
                  f"max-violation={worst - theta:.3e}")
        if worst <= theta + max(tol * max(1.0, abs(theta)), 1e-12):
            break
        new = set(int(f) for f in freqs[np.argsort(lam)[-16:]]) - set(active)
        if not new:      # every violated frequency already active: solver-precision floor
            break
        active = sorted(set(active) | new)
        if rounds > 60:
            raise RuntimeError("cutting planes did not converge")
    return {"Theta": N * float(theta), "UpperBound": N * worst,
            "CertGap": N * (worst - float(theta)),
            "Cuts": len(active), "Rounds": rounds,
            "Time": time.perf_counter() - t0, "Status": str(res.status)}


def ring_density_limit(family="trans", grid=8192):
    """N -> infinity limit of theta(ring N)/N: continuum minimax over the circle."""
    from scipy.optimize import minimize
    # tau(params) = max( lmax(J3 + B0 + B1 + B1^T), max_w lmax(B0 + w B1 + conj(w) B1^T) )
    spec = RING_SPECS[family]
    b0, b1 = spec["b0"], spec["b1"]
    w = np.exp(2j * np.pi * np.arange(grid // 2 + 1) / grid)

    def tau(p):
        B0 = np.zeros((3, 3), dtype=complex)
        B1 = np.zeros((3, 3), dtype=complex)
        for (i, j), v in zip(b0, p[:len(b0)]):
            B0[i, j] = B0[j, i] = v
        for (i, j), v in zip(b1, p[len(b0):]):
            B1[i, j] = v
        H = (B0[None] + w[:, None, None] * B1[None]
             + np.conj(w)[:, None, None] * B1.conj().T[None])
        lam1 = np.linalg.eigvalsh(H)[:, -1].max()
        lam0 = np.linalg.eigvalsh(np.ones((3, 3)) + B0 + B1 + B1.conj().T)[-1].real
        return max(lam0, lam1)

    best = min((minimize(tau, x0, method="Nelder-Mead",
                         options={"xatol": 1e-12, "fatol": 1e-14, "maxiter": 20000})
                for x0 in ([-.6, -.6, -.6, -.6], [-1, -1, -.5, -.5], [0, 0, 0, 0])),
               key=lambda r: r.fun)
    # polish on a 16x finer circle grid: the coarse sup undersamples by O(1/grid^2)
    w = np.exp(2j * np.pi * np.arange(8 * grid + 1) / (16 * grid))
    best = minimize(tau, best.x, method="Nelder-Mead",
                    options={"xatol": 1e-13, "fatol": 1e-15, "maxiter": 20000})
    return float(best.fun), best.x


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

# kernel-verified dense-SDP reference values (LovaszTheta of BlackBox, 10 July 2026;
# ring 18/21 and chain 16/19/31 re-verified against the dense solver on the same day
# during the cis/trans arbitration)
DENSE_REFERENCE = {
    ("cycle", 5): 2.2360679775,
    ("cycle", 7): 3.3176672429,
    ("chain", 3): 5.1366009255,
    ("chain", 7): 11.0819756102,
    ("chain", 11): 17.0601247032,
    ("chain", 15): 23.0478487708,
    ("chain", 16): 25.0000000400,
    ("chain", 19): 29.0398749689,
    ("ring", 3): 4.0000000000,
    ("ring", 4): 5.5013812407,
    ("ring", 5): 6.7701780843,
    ("ring", 6): 8.0978893848,
    ("ring", 7): 9.6037295839,
    ("ring", 8): 11.0027628459,
    ("ring", 9): 12.3097288871,
    ("ring", 10): 13.6791514062,
    ("ring", 11): 15.1336153299,
    ("ring", 12): 16.5041434741,
    ("ring", 13): 17.8335830299,
    ("ring", 14): 19.2190970921,
    ("ring", 15): 20.6483877489,
    ("ring", 18): 24.7460601318,
    ("ring", 21): 28.8675595512,
}

BUILDERS = {"cycle": cycle_graph, "chain": pentagon_chain, "ring": pentagon_ring,
            "cring": pentagon_ring_cis}


def cmd_validate(args):
    ok = True
    print("chordal solver vs kernel-verified dense SDP values:")
    for (kind, N), ref in sorted(DENSE_REFERENCE.items()):
        n, edges = BUILDERS[kind](N)
        r = chordal_theta(n, edges, solver=args.solver)
        d = abs(r["Theta"] - ref)
        ok &= d < 1e-5 and r["CertGap"] < 1e-5
        print(f"  {kind:5s} N={N:3d} (n={n:3d})  theta={r['Theta']:.9f}  ref={ref:.9f}  "
              f"|diff|={d:.2e}  certgap={r['CertGap']:.2e}  w={r['MaxClique']}")
    print("symmetry solver vs dense (trans rings):")
    for N in list(range(3, 16)) + [18, 21]:
        r = ring_theta_symmetric(N)
        d = abs(r["Theta"] - DENSE_REFERENCE[("ring", N)])
        ok &= d < 1e-5
        print(f"  ring  N={N:3d}  theta={r['Theta']:.9f}  |diff|={d:.2e}  "
              f"certgap={r['CertGap']:.2e}")
    print("cross-check chordal vs symmetry at N=100 (both families):")
    for family, builder in (("trans", pentagon_ring), ("cis", pentagon_ring_cis)):
        n, edges = builder(100)
        rc = chordal_theta(n, edges, solver=args.solver)
        rs = ring_theta_symmetric(100, family=family)
        d = abs(rc["Theta"] - rs["Theta"])
        ok &= d < 5e-4
        print(f"  {family:5s} chordal={rc['Theta']:.9f}  symmetric={rs['Theta']:.9f}  "
              f"|diff|={d:.2e}")
    print("monotonicity: theta(chain m) <= theta(cis-ring m+2) [chain is induced]:")
    ch = chordal_theta(*pentagon_chain(31), solver=args.solver)
    cr = ring_theta_symmetric(33, family="cis")
    ok &= ch["Theta"] <= cr["Theta"] + 1e-5
    print(f"  chain 31 = {ch['Theta']:.6f}  <=  cis-ring 33 = {cr['Theta']:.6f}: "
          f"{ch['Theta'] <= cr['Theta'] + 1e-5}")
    print("open word-chain builder vs PentagonChain (all-cis word):")
    for m in (3, 7, 16):
        r = chordal_theta(*pentagon_chain_word("c" * (m - 1)), solver=args.solver)
        d = abs(r["Theta"] - DENSE_REFERENCE[("chain", m)])
        ok &= d < 1e-5
        print(f"  chain {m:2d}: theta={r['Theta']:.9f}  |diff|={d:.2e}   "
              f"alpha={alpha_chain_word('c' * (m - 1))}")
    print("per-cycle transfer SDP (position-space exact word densities):")
    for wd, ref in (("t", 1.3767177459), ("c", 1.5), ("cct", 1.4032308692)):
        v = word_density_transfer_sdp(wd)
        ok &= abs(v - ref) < 2e-6
        print(f"  {wd:>4}: transfer-SDP = {v:.9f}  ref = {ref:.9f}  "
              f"|diff| = {abs(v - ref):.2e}")
    print("VALIDATE OK:", ok)
    return 0 if ok else 1


def cmd_ring(args):
    builder = pentagon_ring if args.family == "trans" else pentagon_ring_cis
    if args.method in ("chordal", "both"):
        n, edges = builder(args.N)
        r = chordal_theta(n, edges, solver=args.solver, verbose=args.verbose)
        print(f"chordal   {args.family} N={args.N}: theta={r['Theta']:.6f}  "
              f"upper={r['UpperBound']:.6f} (certgap {r['CertGap']:.2e})  "
              f"density={r['Theta']/args.N:.6f}  "
              f"cliques={r['CliqueCount']} w={r['MaxClique']} vars={r['Vars']} "
              f"setup={r['SetupTime']:.1f}s solve={r['SolveTime']:.1f}s [{r['Status']}]")
    if args.method in ("symmetry", "both"):
        r = ring_theta_symmetric(args.N, family=args.family, verbose=args.verbose)
        print(f"symmetry  {args.family} N={args.N}: theta={r['Theta']:.6f}  "
              f"upper={r['UpperBound']:.6f} (certgap {r['CertGap']:.2e})  "
              f"density={r['Theta']/args.N:.6f}  "
              f"cuts={r['Cuts']} rounds={r['Rounds']} time={r['Time']:.1f}s [{r['Status']}]")
    return 0


def cmd_chain(args):
    n, edges = pentagon_chain(args.N)
    r = chordal_theta(n, edges, solver=args.solver, verbose=args.verbose)
    print(f"chain N={args.N} (n={n}): theta={r['Theta']:.6f}  upper={r['UpperBound']:.6f} "
          f"(certgap {r['CertGap']:.2e})  theta/N={r['Theta']/args.N:.6f}  "
          f"cliques={r['CliqueCount']} w={r['MaxClique']} "
          f"setup={r['SetupTime']:.1f}s solve={r['SolveTime']:.1f}s [{r['Status']}]")
    return 0


def cmd_words(args):
    """Sweep all binary gluing bracelets (necklaces up to rotation+reversal) of
    period <= args.period: exact alpha density (max-plus cycle mean), theta density
    (chordal solver at ~args.blocks blocks), gap density. Answers: which gluing
    word maximizes the extensive quantum gap?"""
    from fractions import Fraction

    def bracelets(pmax):
        seen, out = set(), []
        for p in range(1, pmax + 1):
            for bits in range(2 ** p):
                w = "".join("tc"[(bits >> i) & 1] for i in range(p))
                reps = {w[r:] + w[:r] for r in range(p)}
                reps |= {s[::-1] for s in reps}
                canon = min(reps)
                if canon in seen:
                    continue
                seen.add(canon)
                if any(canon == (canon[:d] * (p // d)) for d in range(1, p) if p % d == 0):
                    continue  # smaller period, already covered
                out.append(canon)
        return out

    words = bracelets(args.period)
    print(f"{len(words)} bracelets up to period {args.period}; "
          f"theta at ~{args.blocks} blocks (chordal, certified)")
    print(f"{'word':>8} {'L':>6} {'theta/L':>11} {'conv':>9} {'alpha/L':>10} "
          f"{'gap/L':>10} {'certgap':>9}")
    rows = []
    for w in words:
        p = len(w)
        reps = max(3, args.blocks // p)
        L = reps * p
        n, edges = pentagon_ring_word(w, reps)
        r = chordal_theta(n, edges, solver=args.solver)
        n2, edges2 = pentagon_ring_word(w, max(3, reps // 2))
        r2 = chordal_theta(n2, edges2, solver=args.solver)
        thd = r["Theta"] / L
        conv = abs(thd - r2["Theta"] / (len(edges2) // 4))
        ad = alpha_density_word(w)
        # exact-alpha sanity at this L
        assert alpha_ring_word(w, reps) <= ad * L + 1  # cycle-mean dominates
        gap = thd - float(ad)
        rows.append((gap, w, L, thd, conv, ad))
        print(f"{w:>8} {L:>6} {thd:11.7f} {conv:9.1e} "
              f"{str(ad):>10} {gap:10.7f} {r['CertGap']/L:9.1e}")
    rows.sort(reverse=True)
    print("\nranking by extensive gap density:")
    for gap, w, L, thd, conv, ad in rows[:8]:
        print(f"  {w:>8}: gap/L = {gap:.7f}   theta/L = {thd:.7f}   alpha/L = {ad}")
    best = rows[0]
    print(f"\npure trans optimal: {best[1] == 't'}   "
          f"(trans gap {next(r[0] for r in rows if r[1] == 't'):.7f})")
    return 0


def cmd_scaling(args):
    print("theta(pentagon ring N); trans ring: alpha = floor(4N/3), alpha* = 3N/2")
    print(f"{'family':>6} {'N':>7} {'theta':>16} {'method':>9} {'density':>9} "
          f"{'alpha':>8} {'certgap':>9} {'time':>8}")
    for family in ("trans", "cis"):
        builder = pentagon_ring if family == "trans" else pentagon_ring_cis
        for N in args.sizes:
            rs = ring_theta_symmetric(N, family=family)
            alpha = f"{4*N//3:8d}" if family == "trans" else f"{'':8}"
            print(f"{family:>6} {N:7d} {rs['Theta']:16.6f} {'symmetry':>9} "
                  f"{rs['Theta']/N:9.6f} {alpha} {rs['CertGap']:9.2e} {rs['Time']:7.1f}s")
            if N <= args.chordal_cap:
                n, edges = builder(N)
                rc = chordal_theta(n, edges, solver=args.solver)
                print(f"{family:>6} {N:7d} {rc['Theta']:16.6f} {'chordal':>9} "
                      f"{rc['Theta']/N:9.6f} {'':8} {rc['CertGap']:9.2e} "
                      f"{rc['SetupTime']+rc['SolveTime']:7.1f}s   "
                      f"(cliques={rc['CliqueCount']}, w={rc['MaxClique']}, vars={rc['Vars']})")
    for family in ("trans", "cis"):
        lim, p = ring_density_limit(family)
        print(f"N->infinity {family}-ring density limit (continuum symbol minimax): "
              f"{lim:.9f}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--solver", choices=["clarabel", "scs"], default="clarabel")
    ap.add_argument("--verbose", action="store_true")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("validate")
    p = sub.add_parser("ring")
    p.add_argument("N", type=int)
    p.add_argument("--method", choices=["chordal", "symmetry", "both"], default="both")
    p.add_argument("--family", choices=["trans", "cis"], default="trans")
    p = sub.add_parser("chain")
    p.add_argument("N", type=int)
    p = sub.add_parser("density")
    p.add_argument("word", type=str)
    p = sub.add_parser("transchain")
    p.add_argument("M", type=int)
    p = sub.add_parser("scaling")
    p.add_argument("--sizes", type=int, nargs="*", default=[100, 1000, 10000, 100000])
    p.add_argument("--chordal-cap", type=int, default=100000)
    p = sub.add_parser("words")
    p.add_argument("--period", type=int, default=6)
    p.add_argument("--blocks", type=int, default=1200)
    args = ap.parse_args()
    def cmd_density(a):
        print(f"theta-density({a.word}) = {word_density_transfer_sdp(a.word):.9f}")
        return 0
    def cmd_transchain(a):
        n, e = pentagon_chain_word("t" * (a.M - 1))
        r = chordal_theta(n, e, solver=a.solver)
        al = alpha_chain_word("t" * (a.M - 1))
        print(f"trans-chain M={a.M} (n={n}): theta={r['Theta']:.6f} "
              f"(certgap {r['CertGap']:.1e})  alpha={al}  "
              f"gap={r['Theta'] - al:.6f}  gap/M={(r['Theta'] - al)/a.M:.6f}")
        return 0
    return {"validate": cmd_validate, "ring": cmd_ring, "chain": cmd_chain,
            "scaling": cmd_scaling, "words": cmd_words,
            "density": cmd_density, "transchain": cmd_transchain}[args.cmd](args)


if __name__ == "__main__":
    sys.exit(main())
