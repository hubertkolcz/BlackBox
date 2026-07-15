"""ERG-003 load-bearing lemma verification for the rigid-pair route.

Lemmas over H = C9 v C9 v C9 (OR/conormal product, 729 vertices), all reduced
to vertex 0 by translation transitivity (coordinate shifts mod 9 are
automorphisms of H and permute edge-products onto edge-products):

  L0: omega(H) = 8            <=> no 8-clique inside N(0)         [SAT UNSAT]
  L1: every 8-clique of H is an edge-product e1 x e2 x e3
      <=> no 7-clique C in N(0) with {0} u C not inside any of the 8
          products through 0                                       [SAT UNSAT]
  L2: every 7-clique of H is contained in an 8-clique (hence in a product)
      <=> no 6-clique C in N(0) with {0} u C not inside any product
          through 0                                                [SAT UNSAT]

Also brute-force analogues for the small gate cells:
  H2 = C9 v C9  (81 verts):  omega=4, all 4-cliques = 81 edge-products
  H7 = C7 v C7  (49 verts):  omega=4, all 4-cliques = 49 edge-products
  and the 7-clique-extension analogue (3-cliques inside products) for both.

SAT via pysat (cadical); prints PASS/FAIL/UNVERIFIED lines and a JSON summary
to erg003_lemma_results.json.  Deterministic.
"""
import itertools
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from erg003_pentagram_search import build_H, bits  # noqa: E402

from pysat.solvers import Cadical153  # noqa: E402
from pysat.card import CardEnc, EncType  # noqa: E402


def products(n, k):
    """All edge-product cliques of C_n^vk as sorted vertex-index tuples."""
    out = []
    for starts in itertools.product(range(n), repeat=k):
        vs = []
        for deltas in itertools.product((0, 1), repeat=k):
            idx = 0
            for t in range(k):
                idx = idx * n + ((starts[t] + deltas[t]) % n)
            vs.append(idx)
        out.append(tuple(sorted(vs)))
    assert len(set(out)) == len(out)
    return out


def sat_clique_excluding(n, k, adj, N, base_vertex, size, excl_products,
                         timeout_hint=None):
    """SAT: exists clique C of given `size` inside N(base_vertex) such that
    {base_vertex} u C is NOT a subset of any product in excl_products.
    Returns (status, model_or_None); status in SAT|UNSAT.
    Variables 1..N: v selected."""
    nb = adj[base_vertex]
    cand = [v for v in range(N) if (nb >> v) & 1]
    cset = set(cand)
    cnf = []
    # non-adjacent pairs inside the candidate set
    for i, u in enumerate(cand):
        au = adj[u]
        for v in cand[i + 1:]:
            if not ((au >> v) & 1):
                cnf.append([-(u + 1), -(v + 1)])
    # vertices outside N(base) are off
    for v in range(N):
        if v not in cset and v != base_vertex:
            cnf.append([-(v + 1)])
    cnf.append([-(base_vertex + 1)])  # base handled implicitly
    # exclusion: for each product P (containing base), >=1 selected outside P
    for P in excl_products:
        Pset = set(P)
        clause = [v + 1 for v in cand if v not in Pset]
        cnf.append(clause)
    # cardinality: exactly `size` selected among cand -> use >= size and
    # <= size (atmost needed so "outside P" cannot be dodged by oversize)
    lits = [v + 1 for v in cand]
    top = N + 1
    ge = CardEnc.atleast(lits=lits, bound=size, top_id=top, encoding=EncType.seqcounter)
    cnf.extend(ge.clauses)
    top = max(top, ge.nv) + 1
    le = CardEnc.atmost(lits=lits, bound=size, top_id=top, encoding=EncType.seqcounter)
    cnf.extend(le.clauses)
    with Cadical153(bootstrap_with=cnf) as s:
        sat = s.solve()
        if sat:
            model = s.get_model()
            chosen = [v for v in cand if model[v] > 0]
            return "SAT", chosen
        return "UNSAT", None


def check_cell_bruteforce(n, k):
    """Small cells: enumerate ALL omega-cliques directly, compare to products.
    Also check every (omega-1)-clique extends into a product."""
    N, coords, adj, FULL = build_H(n, k)
    omega = 2 ** k
    prods = set(products(n, k))
    # enumerate all omega-cliques by simple recursion (N<=81: cheap)
    allc = []

    def rec(start, cur, curmask):
        if len(cur) == omega:
            allc.append(tuple(cur))
            return
        for v in range(start, N):
            if all((adj[v] >> u) & 1 for u in cur):
                rec(v + 1, cur + [v], 0)
    rec(0, [], 0)
    all_are_products = set(allc) == prods
    # (omega-1)-cliques all inside some product?
    subs = set()
    for P in prods:
        for drop in P:
            subs.add(tuple(x for x in P if x != drop))
    bad = 0

    def rec2(start, cur):
        nonlocal bad
        if len(cur) == omega - 1:
            if tuple(cur) not in subs:
                bad += 1
            return
        for v in range(start, N):
            if all((adj[v] >> u) & 1 for u in cur):
                rec2(v + 1, cur + [v])
    rec2(0, [])
    return {
        "cell": f"C{n}^v{k}",
        "omega_clique_count": len(allc),
        "product_count": len(prods),
        "all_max_cliques_are_products": all_are_products,
        "num_submax_cliques_outside_products": bad,
    }


def main():
    t0 = time.time()
    out = {}

    # small cells brute force
    for (n, k) in ((7, 2), (9, 2)):
        r = check_cell_bruteforce(n, k)
        out[r["cell"]] = r
        print(f"[{r['cell']}] max-cliques={r['omega_clique_count']} products="
              f"{r['product_count']} all-products={r['all_max_cliques_are_products']} "
              f"submax-outside-products={r['num_submax_cliques_outside_products']}",
              flush=True)

    # big cell H = C9^v3 via SAT at base vertex 0
    n, k = 9, 3
    N, coords, adj, FULL = build_H(n, k)
    prods = products(n, k)
    through0 = [P for P in prods if 0 in P]
    print(f"[C9^v3] products through vertex 0: {len(through0)} (expect 8)", flush=True)
    out["C9^v3"] = {"products_through_0": len(through0)}

    # L0: no 8-clique in N(0)  (omega(H) <= 8; >=8 known from products)
    t = time.time()
    st, model = sat_clique_excluding(n, k, adj, N, 0, 8, [])
    out["C9^v3"]["L0_no_9clique_status"] = st
    out["C9^v3"]["L0_seconds"] = round(time.time() - t, 1)
    print(f"[L0] 8-clique inside N(0): {st} ({out['C9^v3']['L0_seconds']}s) "
          f"-> omega(H)=8 {'CONFIRMED' if st == 'UNSAT' else 'BROKEN: ' + str(model)}",
          flush=True)

    # L1: no 7-clique in N(0) avoiding all 8 products through 0
    t = time.time()
    st, model = sat_clique_excluding(n, k, adj, N, 0, 7, through0)
    out["C9^v3"]["L1_nonproduct_8clique_status"] = st
    out["C9^v3"]["L1_seconds"] = round(time.time() - t, 1)
    print(f"[L1] non-product 8-clique through 0: {st} "
          f"({out['C9^v3']['L1_seconds']}s) -> all 8-cliques are products: "
          f"{'CONFIRMED' if st == 'UNSAT' else 'BROKEN: ' + str(model)}", flush=True)

    # L2: no 6-clique in N(0) avoiding all products through 0
    t = time.time()
    st, model = sat_clique_excluding(n, k, adj, N, 0, 6, through0)
    out["C9^v3"]["L2_nonextendable_7clique_status"] = st
    out["C9^v3"]["L2_seconds"] = round(time.time() - t, 1)
    print(f"[L2] 7-clique through 0 outside every product: {st} "
          f"({out['C9^v3']['L2_seconds']}s) -> every 7-clique lies in a product: "
          f"{'CONFIRMED' if st == 'UNSAT' else 'BROKEN: ' + str(model)}", flush=True)

    out["total_seconds"] = round(time.time() - t0, 1)
    with open(os.path.join(HERE, "erg003_lemma_results.json"), "w") as f:
        json.dump(out, f, indent=1)
    print("WROTE erg003_lemma_results.json", flush=True)


if __name__ == "__main__":
    main()
