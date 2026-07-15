"""Independent max-cycle-mean (tropical eigenvalue) check for Bridge D.

Reads bridge_verify_D_k*.json (nodes, edges, sigma, cWeight dumped from the certs)
and computes the max cycle mean of BOTH the sigma cocycle and the bare c-weight
using an INDEPENDENT method (Bellman-Ford / Lawler binary search on edge means),
totally separate from the builder's Wolfram Karp routine. Then checks:
  (i)   max_e sigma(e) == stored Gamma      (dual attainment)
  (ii)  sigma(e) <= Gamma for all e         (sub-action bound)
  (iii) maxCycleMean(sigma) == maxCycleMean(c) == Gamma  (coboundary telescopes)
Anchors (word length -> value): wl3=0.125, wl4=0.1020, wl5=0.0953.
"""
import json, glob, os

def max_cycle_mean(n, edges, w):
    """Lawler binary search: largest mu s.t. a cycle with mean >= mu exists.
    Detect positive cycle of (w[e]-mu) via Bellman-Ford longest-path relaxation."""
    lo = min(w); hi = max(w)
    def has_cycle_ge(mu):
        # longest-path style: if we can relax after n rounds -> positive cycle in (w-mu)
        dist = [0.0]*n
        for _ in range(n):
            updated = False
            for (a,b),we in zip(edges,w):
                if dist[a] + (we-mu) > dist[b] + 1e-15:
                    dist[b] = dist[a] + (we-mu); updated = True
            if not updated: break
        # one more pass: any relaxation => positive cycle exists
        for (a,b),we in zip(edges,w):
            if dist[a] + (we-mu) > dist[b] + 1e-15:
                return True
        return False
    for _ in range(200):
        mid = (lo+hi)/2
        if has_cycle_ge(mid): lo = mid
        else: hi = mid
    return (lo+hi)/2

for path in sorted(glob.glob(os.path.join(os.path.dirname(__file__),"bridge_verify_D_k*.json"))):
    d = json.load(open(path))
    k = d["k"]; nodes = d["nodes"]; edges = [tuple(e) for e in d["edges"]]
    # JSON numbers already parsed as float
    sigma = [float(x) for x in d["sigma"]]; cw = [float(x) for x in d["cWeight"]]
    gamma = float(d["Gamma"]); maxsig = float(d["maxSigma"])
    n = len(nodes)
    # reindex to 0-based (dump used 1-based)
    e0 = [(a-1,b-1) for (a,b) in edges]
    mcm_sigma = max_cycle_mean(n, e0, sigma)
    mcm_c     = max_cycle_mean(n, e0, cw)
    maxe_sigma = max(sigma)
    sub_ok = all(s <= gamma + 1e-12 for s in sigma)
    print(f"--- word length k={k}  ({n} nodes, {len(edges)} edges) ---")
    print(f"  stored Gamma            = {gamma:.12f}")
    print(f"  max_e sigma(e)          = {maxe_sigma:.12f}   (== Gamma: {abs(maxe_sigma-gamma)<1e-9})")
    print(f"  independent mcm(sigma)  = {mcm_sigma:.12f}   |diff Gamma|={abs(mcm_sigma-gamma):.2e}")
    print(f"  independent mcm(cWeight)= {mcm_c:.12f}   |diff Gamma|={abs(mcm_c-gamma):.2e}")
    print(f"  sub-action bound sigma<=Gamma all edges: {sub_ok}")
    print(f"  mcm(sigma)==mcm(c) (coboundary telescopes): {abs(mcm_sigma-mcm_c)<1e-8}")
