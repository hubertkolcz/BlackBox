"""Independent (pure Python, separate from maxclique.c) re-verification that
the witness cliques reported by the C solver are genuinely valid cliques of
the claimed size, by decoding each global tuple index back to its (a,b,c)
coordinates and checking OR-adjacency directly against the base graph edge
sets from scratch -- not reusing the .bin files or any C-solver code path.
"""
import itertools

def cycle_edges(n):
    return set(frozenset((i,(i+1)%n)) for i in range(n))

def petersen_edges():
    verts = list(itertools.combinations(range(5), 2))
    edges = set()
    for a,b in itertools.combinations(verts,2):
        if set(a).isdisjoint(b):
            edges.add(frozenset((verts.index(a), verts.index(b))))
    return edges, len(verts)

def paley_edges(q):
    qr = set((x*x)%q for x in range(1,q))
    edges = set()
    for i,j in itertools.combinations(range(q),2):
        if (i-j)%q in qr:
            edges.add(frozenset((i,j)))
    return edges

def check(name, n, edge_set, k, witness_global_ids):
    tuples = list(itertools.product(range(n), repeat=k))  # matches build_graphs.py ordering
    verts = [tuples[g] for g in witness_global_ids]
    assert len(set(verts)) == len(verts), f"{name}: duplicate tuple in witness!"
    ok = True
    for (u,v) in itertools.combinations(verts, 2):
        adjacent_somewhere = any(frozenset((u[t],v[t])) in edge_set for t in range(k))
        if not adjacent_somewhere:
            ok = False
            print(f"  FAIL: {u} and {v} not OR-adjacent in any coordinate")
    print(f"{name}: witness size={len(verts)}  all-pairs-OR-adjacent={ok}")
    return ok

if __name__ == "__main__":
    c7e = cycle_edges(7)
    w_c7 = [0,242,318,325,193,333,290,286]
    r1 = check("C7^(OR3)",   7, c7e, 3, w_c7)

    pete, npet = petersen_edges()
    w_pet = [0,996,862,722,671,619,468,281,249,128,904,95]
    r2 = check("Petersen^(OR3)", npet, pete, 3, w_pet)

    pal = paley_edges(13)
    w_pal33 = [0,2196,1810,1663,815,1535,1509,797,1369,1492,2144,1322,648,316,974,1207,1134,1198,983,1594,685,2171,1398,1976,1947,1781,1355,1170,854,780,585,390,350]
    r3 = check("Paley13^(OR3) [lower-bound witness]", 13, pal, 3, w_pal33)

    print()
    print("ALL INDEPENDENT PYTHON RE-VERIFICATIONS PASS:", all([r1,r2,r3]))
