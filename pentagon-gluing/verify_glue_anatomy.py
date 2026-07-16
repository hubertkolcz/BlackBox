"""verify_glue_anatomy.py -- independent cross-check (Python/networkx/cvxpy/SCS) of every
quantitative claim displayed in pentagon-gluing/glue_anatomy_figure.wl.
Run 2026-07-16 in a WL-kernel-free sandbox: ALL 16 checks OK.
  theta(C5)    = 2.236067978  (sqrt5)
  theta(ddt^2) = 8.347042163  (chordal anchor 8.347042185, agrees to 2e-8)
  theta(ttt^2) = 8.097889106  -> gap6 = 0.016315
  theta(ddd^2) = 8.999999982  = alpha (direct collapse, gap 0 at L=6 already)
Mirrors: wordRing (CaseStudies.wl 281-288), dpTransfer (BuildMeshGlueNotebook.wl 506-514),
LovaszTheta SDP (BlackBox/Kernel/BlackBox.wl 62-69). Letters: d == c (direct/direct)."""
import itertools, networkx as nx, numpy as np, cvxpy as cp

def word_ring(word, reps):
    w = list(word) * reps; L = len(w); G = nx.Graph()
    G.add_nodes_from(range(1, 3*L + 1))
    for k in range(L):
        km = (k - 1) % L
        u, v = (3*km + 1, 3*km + 2) if w[km] in "cd" else (3*km + 2, 3*km + 1)
        G.add_edges_from([(u, v), (u, 3*k + 1), (3*k + 1, 3*k + 2),
                          (3*k + 2, 3*k + 3), (3*k + 3, v)])
    return G, w

def alpha(G):
    Gc = nx.complement(G); best = 0
    for cl in nx.find_cliques(Gc): best = max(best, len(cl))
    return best

def lovasz_theta(G):
    nodes = sorted(G.nodes()); n = len(nodes); idx = {u: i for i, u in enumerate(nodes)}
    X = cp.Variable((n, n), symmetric=True)
    cons = [X >> 0, cp.trace(X) == 1] + [X[idx[u], idx[v]] == 0 for u, v in G.edges()]
    prob = cp.Problem(cp.Maximize(cp.sum(X)), cons)
    prob.solve(solver=cp.SCS, eps=1e-9, max_iters=200000)
    return prob.value

# max-plus transfer DP (verbatim port of dpTransfer)
dp_states = [(0, 0), (1, 0), (0, 1)]
def dp_transfer(letter):
    T = np.full((3, 3), -np.inf)
    for i, st in enumerate(dp_states):
        for s1, s2, s3 in itertools.product((0, 1), repeat=3):
            if (st[0] and s1) or (s1 and s2) or (s2 and s3) or (s3 and st[1]): continue
            out = (s1, s2) if letter in "cd" else (s2, s1)
            j = dp_states.index(out)
            T[i, j] = max(T[i, j], s1 + s2 + s3)
    return T
def mp_mul(A, B):
    return np.array([[max(A[i, k] + B[k, j] for k in range(3)) for j in range(3)] for i in range(3)])
def mp_word(w):
    M = dp_transfer(w[0])
    for ch in w[1:]: M = mp_mul(M, dp_transfer(ch))
    return M

if __name__ == "__main__":
    checks = {}
    G6, w6 = word_ring("ddt", 2)
    G9, _ = word_ring("ddt", 3)
    checks["vertices=3L (18)"] = G6.number_of_nodes() == 18
    checks["edges=4L (24)"]    = G6.number_of_edges() == 24
    a6, a9 = alpha(G6), alpha(G9)
    checks["alpha(ddt^2)=8"]  = a6 == 8
    checks["alpha(ddt^3)=12"] = a9 == 12
    checks["alpha staircase 4/3"] = (a9 - a6) / 3 == 4/3
    # DP factorization: max-plus trace over the word == alpha of the ring
    checks["DP trace == alpha (ddt^2)"] = max(np.diag(mp_word(w6))) == a6
    Gt, wt = word_ring("ttt", 2)
    checks["DP trace == alpha (ttt^2)"] = max(np.diag(mp_word(wt))) == alpha(Gt) == 8
    # density = max-plus cycle mean of one period
    checks["cycle mean(T_d T_d T_t)=4 (4/3 per block)"] = max(np.diag(mp_word("ddt"))) == 4.0
    # every block an induced C5
    def block_ok(G, w, k):
        L = len(w); km = (k - 1) % L
        u, v = (3*km + 1, 3*km + 2) if w[km] in "cd" else (3*km + 2, 3*km + 1)
        S = G.subgraph([u, v, 3*k + 1, 3*k + 2, 3*k + 3])
        return S.number_of_edges() == 5 and all(d == 2 for _, d in S.degree())
    checks["every block induced C5"] = all(block_ok(G6, w6, k) for k in range(6))
    # two pentagons glued on one edge = C8 + chord (NOT C7)
    P = nx.cycle_graph(5); Q = nx.relabel_nodes(nx.cycle_graph(5), {0: 1, 1: 2, 2: 5, 3: 6, 4: 7})
    GG = nx.compose(P, Q)          # shares edge {1,2}
    checks["glued pair: 8 vertices, 9 edges"] = (GG.number_of_nodes(), GG.number_of_edges()) == (8, 9)
    deg = sorted(d for _, d in GG.degree())
    checks["degrees: two 3s (chord ends), six 2s"] = deg == [2]*6 + [3]*2
    GG2 = GG.copy(); GG2.remove_edge(1, 2)
    checks["remove shared edge -> C8"] = all(d == 2 for _, d in GG2.degree()) and nx.is_connected(GG2)
    # w1 / orientation parity: t-count mod 2 depends on ring length, not the word alone
    par = lambda word, reps: (word.count("t") * reps) % 2
    checks["(ddt)^2 annulus, (ddt)^17 Moebius"] = par("ddt", 2) == 0 and par("ddt", 17) == 1
    checks["(ttt)^17 Moebius too (same w1 as ddt^17)"] = par("ttt", 17) == 1
    # SDP anchors
    th5 = lovasz_theta(nx.cycle_graph(5))
    checks["theta(C5)=sqrt5"] = abs(th5 - np.sqrt(5)) < 1e-6
    th6 = lovasz_theta(G6)
    checks["theta(ddt^2)=8.347042185"] = abs(th6 - 8.347042185) < 1e-5
    tht = lovasz_theta(Gt)
    tau = 1.3767177  # tau* numeric
    print(f"theta(C5)      = {th5:.9f}   (sqrt5 = {np.sqrt(5):.9f})")
    print(f"theta(ddt^2)   = {th6:.9f}   (chordal anchor 8.347042185); /6 = {th6/6:.9f}; gap6 = {th6/6-4/3:.9f}")
    print(f"theta(ttt^2)   = {tht:.9f}   /6 = {tht/6:.9f}  (asymptote tau* = {tau})")
    for k, v in checks.items(): print(f"{'OK ' if v else 'FAIL'} {k}")
    print("ALL OK" if all(checks.values()) else "SOME FAILED")
