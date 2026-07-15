"""ERG-003 LANE 3: bounds-only family elimination attempt (search-free).

Question (task): of the 24 residual S=17 PARTIAL families (of 26 total; fam00,
fam01 already exhausted NO), how many can be ELIMINATED by provable clique
BOUNDS on neighborhood substructures ALONE -- i.e. without the exhaustive
two-layer CSP search that timed out?

Levers tested (both proposed in the lane brief):
 (1) NEIGHBORHOOD CLIQUE BOUNDS. Pentagram ring pairs (i,i+2 mod 5); each layer
     Q_m has two pentagram partners p1=(m+2)%5, p2=(m-2)%5 which are themselves
     C5-adjacent (free), so Q_p1, Q_p2 both live inside cn(Q_m) (common H-nbhd
     of the anchor layer). Necessary: omega(cn(Q_m)) >= max(s_p1, s_p2) for SOME
     s_m-clique Q_m.  Family is bound-eliminable if for EVERY s_m-clique Q_m,
     omega(cn(Q_m)) < max(s_p1,s_p2).
 (2) PARITY / COUNTING across the 5 layers: each H-vertex h may appear only in a
     pentagram-independent set of layers (the pentagram is a 5-cycle, max
     independent set 2), so each h used <= 2 times; sum s_i = 17 <= 2*729.

Provable primitives (all exact / provable upper bounds, no heuristic):
 - fvec (erg003_fvec.json): fvec_s[d] = (exists s-clique in N(a)cap N(b)),
   d=b-a, EXACT exhaustion (False = proven impossible). Pair-neighborhood oracle.
 - greedy_color coloring bound (Tomita) = provable omega upper bound.
 - product 8-clique witness: e1 x e2 x e3 (one C9-edge per factor) is an
   8-clique of H; any s_m-subset Q_m of it has the other 8-s_m vertices as a
   clique inside cn(Q_m), so omega(cn(Q_m)) >= 8 - s_m  (constructive lower bnd).

KEY LEMMA (proved by the witness above): for any layer m,
   max over s_m-cliques Q_m of omega(cn(Q_m))  >=  8 - s_m.
Since the family generator enforces s_m + s_p <= 8 for each pentagram pair,
max(s_p1,s_p2) <= 8 - s_m.  Hence the marginal necessary condition
   omega(cn(Q_m)) >= max(s_p1,s_p2)
is ALWAYS satisfiable (take Q_m inside a product 8-clique).  => lever (1)
eliminates ZERO families.  This script certifies that lemma numerically for
every layer of every family, and checks lever (2) can never bind.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import erg003_pentagram_search as ps

N, coords, adj, FULL = ps.build_H(9, 3)


def color_bound(P):
    order, cn = ps.greedy_color(P, adj)
    return max(cn) if cn else 0


def cn_mask(verts):
    return ps.neigh_of_clique(verts, adj, FULL)


def idx(a, b, c):
    return a * 81 + b * 9 + c


def product_8clique(off=(0, 0, 0)):
    """e1 x e2 x e3 with edge {t, t+1} in each C9 factor (C9 edges are +-1)."""
    verts = []
    for da in (0, 1):
        for db in (0, 1):
            for dc in (0, 1):
                verts.append(idx((off[0] + da) % 9,
                                  (off[1] + db) % 9,
                                  (off[2] + dc) % 9))
    return verts


def certify_lemma():
    """For s_m in 1..7: exhibit an s_m-clique Q (subset of a product 8-clique)
    with omega(cn(Q)) >= 8 - s_m, using the provable coloring bound as a check
    that cn(Q) indeed contains a (8-s_m)-clique (the complementary subset)."""
    K = product_8clique()
    # verify K is an 8-clique
    for i in range(8):
        for j in range(i + 1, 8):
            assert (adj[K[i]] >> K[j]) & 1, "product set not a clique!"
    rows = []
    for s_m in range(1, 8):
        Q = K[:s_m]
        rest = K[s_m:]                       # 8 - s_m vertices, still a clique
        cn = cn_mask(Q)
        # every 'rest' vertex must be in cn(Q):
        allin = all((cn >> v) & 1 for v in rest)
        cb = color_bound(cn)                 # provable omega UPPER bound on cn(Q)
        # constructive lower bound = |rest| (they form a clique inside cn)
        rows.append((s_m, 8 - s_m, allin, cb))
    return rows


def marginal_check(vec):
    """For each layer m, required = max(s_p1,s_p2); guaranteed achievable
    lower bound on max_Q omega(cn(Q_m)) = 8 - s_m. Eliminable iff some layer has
    required > (best provable achievable). Returns (eliminable, detail)."""
    detail = []
    elim = False
    for m in range(5):
        p1, p2 = (m + 2) % 5, (m - 2) % 5
        req = max(vec[p1], vec[p2])
        guaranteed = 8 - vec[m]              # KEY LEMMA lower bound
        ok = guaranteed >= req
        if not ok:
            elim = True
        detail.append((m, vec[m], req, guaranteed, ok))
    return elim, detail


def main():
    print("=== KEY LEMMA certification (product-8-clique witness) ===")
    print(" s_m | 8-s_m | rest subset of cn(Q)? | coloring-omega(cn(Q)) upper")
    for s_m, lo, allin, cb in certify_lemma():
        print(f"  {s_m}  |   {lo}   |   {allin}   |   {cb}")
    print()

    fams = ps.families(17, cap=8)
    print(f"=== marginal neighborhood-bound elimination over {len(fams)} families ===")
    elim_count = 0
    residual = []
    for i, vec in enumerate(fams):
        vec = list(vec)
        elim, det = marginal_check(vec)
        # parity/counting lever:
        parity_bad = sum(vec) > 2 * N        # each h used <=2 times
        status = "ELIMINATED" if (elim or parity_bad) else "survives"
        if elim or parity_bad:
            elim_count += 1
        else:
            residual.append(i)
        worst = min(g - r for (_, _, r, g, _) in det)  # min slack (8-s_m - req)
        print(f" fam{i:02d} {vec}: {status}  min_slack(8-s_m - maxpartner)={worst}")
    print()
    print(f"BOUND-ELIMINATED: {elim_count}/{len(fams)}")
    print(f"parity lever binds: {'never (17 << 1458)' }")
    print(f"residual (survive all bounds): {len(residual)} families -> {residual}")


if __name__ == "__main__":
    main()
