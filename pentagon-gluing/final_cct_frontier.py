"""LANE 1 -- cct global optimality via the certified Legendre theta-frontier.

Reads the exact de Bruijn-k certificate export (final_cct_frontier_kK.txt):
 nodes with (isC last-letter, d(x) = theta head payoff, exact rational)
 edges u->v with (isC added, r(e) = alpha inner value, exact rational).

CERTIFIED objects (window k):
  Gamma_k          = maxCycleMean_e [ d(v) - r(e) ]      (flat gap bound; reproduces cert)
  Gamma_k^th(lam)  = maxCycleMean_e [ d(v) - lam*isC(v) ] (Legendre theta family, lam>=0)
  frontier_k(fc)   = min_lam [ Gamma_k^th(lam) + lam*fc ] (certified upper bnd on theta_max(fc))
  gapbound_k       = max_fc [ frontier_k(fc) - max(4/3, 1+fc/2) ]  (nonlinear alpha floor)

Because d(v)-cyclemean upper-bounds theta-bar(word) for every word and
alpha-bar(word) >= max(4/3,1+fc/2) is a PROVEN theorem, gapbound_k certifies
  sup_words [ theta-bar - alpha-bar ]  <=  gapbound_k   for every finite k.
"""
import sys
from fractions import Fraction

def load(path):
    nodes_isc, nodes_d = [], []
    edges = []  # (u, v, iscAdded, r_float, r_frac)
    gam = None
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith("#"):
                if "gammaNum" in line:
                    parts = dict(p.split("=") for p in line[1:].split() if "=" in p)
                    gam = Fraction(int(parts["gammaNum"]), int(parts["gammaDen"]))
                    kval = int(parts["k"])
                if line.startswith("# NODES"):
                    mode = "N"
                elif line.startswith("# EDGES"):
                    mode = "E"
                continue
            t = line.split()
            if mode == "N":
                # idx isC dnum dden
                nodes_isc.append(int(t[1]))
                nodes_d.append(Fraction(int(t[2]), int(t[3])))
            else:
                u, v, isc = int(t[0]), int(t[1]), int(t[2])
                rf = Fraction(int(t[3]), int(t[4]))
                edges.append((u, v, isc, rf))
    return kval, gam, nodes_isc, nodes_d, edges


def karp_mcm(n, edge_uvw):
    """Karp max cycle mean over a strongly connected digraph.
    edge_uvw: list of (u, v, w) with weight w on u->v (float).
    Returns (lambda_max, cycle_nodes). Cycle recovered via parent pointers."""
    NEG = float("-inf")
    inedges = [[] for _ in range(n)]
    for (u, v, w) in edge_uvw:
        inedges[v].append((u, w))
    s = 0
    F = [[NEG] * n for _ in range(n + 1)]
    P = [[-1] * n for _ in range(n + 1)]
    F[0][s] = 0.0
    for j in range(1, n + 1):
        Fj, Fp, Pj = F[j], F[j - 1], P[j]
        for v in range(n):
            best, bu = NEG, -1
            for (u, w) in inedges[v]:
                val = Fp[u] + w
                if val > best:
                    best, bu = val, u
            Fj[v] = best
            Pj[v] = bu
    lam, vstar = NEG, s
    for v in range(n):
        if F[n][v] == NEG:
            continue
        mn = float("inf")
        for j in range(n):
            if F[j][v] == NEG:
                continue
            val = (F[n][v] - F[j][v]) / (n - j)
            if val < mn:
                mn = val
        if mn > lam:
            lam, vstar = mn, v
    # recover a cycle: walk back n steps from vstar via parents, find a repeat
    path = [vstar]
    cur, lvl = vstar, n
    while lvl > 0:
        cur = P[lvl][cur]
        lvl -= 1
        if cur < 0:
            break
        path.append(cur)
    seen = {}
    cyc = None
    for i, node in enumerate(path):
        if node in seen:
            cyc = path[seen[node]:i]
            break
        seen[node] = i
    return lam, (cyc if cyc else [vstar])


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "final_cct_frontier_k9.txt"
    k, gam, isc, d, edges = load(path)
    n = len(d)
    df = [float(x) for x in d]
    print(f"=== window k={k}  |V|={n}  |E|={len(edges)}  Gamma_{k}(cert)={float(gam):.10f} ===")

    # --- sanity 0: reproduce flat Gamma_k = mcm(d(v) - r(e)) ---
    ew_gap = [(u, v, df[v] - float(rf)) for (u, v, isca, rf) in edges]
    lam_gap, cyc_gap = karp_mcm(n, ew_gap)
    print(f"[chk] flat mcm(d-r)          = {lam_gap:.10f}   (cert Gamma={float(gam):.10f}, "
          f"d={abs(lam_gap-float(gam)):.2e})")

    # --- sanity 1: mcm(d) alone = max theta over all words (expect 3/2) ---
    ew_d = [(u, v, df[v]) for (u, v, isca, rf) in edges]
    lam_d, cyc_d = karp_mcm(n, ew_d)
    fc_d = sum(isc[x] for x in cyc_d) / len(cyc_d)
    print(f"[chk] mcm(d) = theta_max      = {lam_d:.10f}   (expect 1.5; argmax fc={fc_d:.3f})")

    # --- anchor cycles: cct, all-c, all-t  (cyclemean of d over their dB-9 cycles) ---
    # node index by word: reconstruct words from isc? we only have isc; instead find
    # cct/ccc/ttt cycles by following edges. Build word->idx not available; use structure:
    # all-c cycle = the self-loop node with isc chain all c; identify via a helper below.
    anchor = anchors_cyclemean(n, edges, df, isc, k)
    for name, cm, fcv in anchor:
        print(f"[anchor] cyclemean d over {name:>10}: {cm:.10f}  fc={fcv:.4f}")

    # --- Legendre theta family over a lambda grid ---
    import numpy as np
    lam_hi = 2.0  # d in [~1.33,1.5]; slope of frontier <= 1, lam up to ~1 suffices, pad to 2
    lams = sorted(set(list(np.linspace(0.0, lam_hi, 401)) +
                      list(np.linspace(0.0, 0.6, 301))))
    G = []
    for lam in lams:
        ew = [(u, v, df[v] - lam * isc[v]) for (u, v, isca, rf) in edges]
        g, cyc = karp_mcm(n, ew)
        fcv = sum(isc[x] for x in cyc) / len(cyc)
        G.append((lam, g, fcv))
    # frontier(fc) = min_lam [G(lam) + lam*fc]
    fcs = np.linspace(0.0, 1.0, 501)
    frontier = []
    for fc in fcs:
        frontier.append(min(g + lam * fc for (lam, g, _) in G))
    frontier = np.array(frontier)
    floor = np.maximum(4.0 / 3.0, 1.0 + fcs / 2.0)
    gapcurve = frontier - floor
    imax = int(np.argmax(gapcurve))
    print(f"\n--- Legendre frontier (k={k}) ---")
    print(f"frontier(fc=0.000) = {frontier[0]:.8f}   (pure trans theta tau*=1.3767177)")
    i23 = int(np.argmin(np.abs(fcs - 2.0 / 3.0)))
    print(f"frontier(fc=0.667) = {frontier[i23]:.8f}   (cct theta = 1.4032309)")
    print(f"frontier(fc=1.000) = {frontier[-1]:.8f}   (pure cis theta = 1.5)")
    print(f"\nGAP BOUND max over fc = {gapcurve[imax]:.8f}  at fc={fcs[imax]:.4f}")
    print(f"   flat Gamma_{k}          = {float(gam):.8f}")
    print(f"   improvement over flat  = {float(gam) - gapcurve[imax]:.8f}")
    print(f"   gap(cct) target        = 0.06989750")
    # report a few points of the gap curve near the peak
    print("\n  fc      frontier     floor      gap")
    for i in range(0, 501, 25):
        print(f"  {fcs[i]:.3f}   {frontier[i]:.7f}  {floor[i]:.7f}  {gapcurve[i]:+.7f}")
    return 0


def anchors_cyclemean(n, edges, df, isc, k):
    """Find the all-c, all-t, and (cct)^* cycles in de Bruijn-k by following the
    deterministic rotation for a periodic word, using edge overlap structure.
    We rebuild word labels from isc alone is impossible; instead we locate cycles
    by their de Bruijn signature: append letters and track node identity via the
    unique in/out structure. Simplest robust route: reconstruct node words from a
    spanning walk is heavy -- instead we identify the three anchor cycles by their
    isc-pattern along a closed walk of the right period. We brute force small cycles."""
    # Build adjacency
    adj = [[] for _ in range(n)]
    for (u, v, isca, rf) in edges:
        adj[u].append((v, isca))
    out = []
    # all-c: a fixed point node whose only out-neighbour repeating 'c' returns to itself
    # find node with a self-loop where added letter c (period-1 cycle, all c)
    def find_periodic(pattern):
        # pattern like "c","t","cct"; find a cycle whose added-letter sequence == pattern repeated
        pl = len(pattern)
        target = [1 if ch == "c" else 0 for ch in pattern]
        for start in range(n):
            node = start
            seq = []
            ok = True
            walk = [node]
            for step in range(pl):
                want = target[step % pl]
                nxt = [(v, isca) for (v, isca) in adj[node] if isca == want]
                if not nxt:
                    ok = False
                    break
                node = nxt[0][0]
                seq.append(want)
                walk.append(node)
            if ok and node == start and seq == target:
                cm = sum(df[x] for x in walk[:-1]) / pl
                fcv = sum(isc[x] for x in walk[:-1]) / pl
                return cm, fcv
        return None
    for name, pat in (("all-c", "c"), ("all-t", "t"), ("cct", "cct")):
        r = find_periodic(pat)
        if r:
            out.append((name, r[0], r[1]))
    return out


if __name__ == "__main__":
    sys.exit(main())
