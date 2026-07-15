# Validates enum_size_cliques_ranged: a partition of the root range [0, len(order))
# into disjoint contiguous chunks, unioned across chunks, MUST reproduce exactly the
# same set of cliques as the unrestricted enum_size_cliques (and, transitively, the
# independent count-only reference _enum_count_only). Run before trusting any
# ranged-split code in a real (paid) job.
import sys, itertools, random
sys.path.insert(0, '.')
import erg003_pentagram_search as ps


def all_cliques(P, need, adj):
    stats = [0, None]
    return set(ps.enum_size_cliques(P, need, adj, stats))


def all_cliques_ranged_union(P, need, adj, chunks):
    order, colornum = ps.greedy_color(P, adj)
    out = set()
    total_nodes = 0
    for (lo, hi) in chunks:
        stats = [0, None]
        out |= set(ps.enum_size_cliques_ranged(P, need, adj, stats, lo, hi, order, colornum))
        total_nodes += stats[0]
    return out, len(order)


def partitions(L, k):
    """k roughly-equal contiguous chunks covering [0, L)."""
    if L == 0:
        return [(0, 0)]
    base = L // k
    rem = L % k
    chunks = []
    lo = 0
    for i in range(k):
        sz = base + (1 if i < rem else 0)
        hi = lo + sz
        if sz > 0:
            chunks.append((lo, hi))
        lo = hi
    return chunks


def check_case(label, n, k, need, P, adj):
    ref = _enum_count_only_set(P, need, adj)
    full = all_cliques(P, need, adj)
    assert ref == full, f"{label}: enum_size_cliques disagrees with count-only reference!"
    for nchunks in (1, 2, 3, 5, 7):
        union, L = all_cliques_ranged_union(P, need, adj, partitions(L=(len(ps.greedy_color(P, adj)[0])), k=nchunks))
        if union != full:
            missing = full - union
            extra = union - full
            print(f"FAIL {label} nchunks={nchunks}: missing={len(missing)} extra={len(extra)}")
            return False
    print(f"OK   {label}: |cliques|={len(full)}  agrees across nchunks in (1,2,3,5,7)")
    return True


def _enum_count_only_set(P, need, adj):
    """Reference: same recursion as _enum_count_only but SET-yielding, for exact
    cross-check (not just a count) against enum_size_cliques."""
    if need == 0:
        return {0}
    if P.bit_count() < need:
        return set()
    out = set()
    Pw = P
    while Pw:
        low = Pw & -Pw
        v = low.bit_length() - 1
        Pw ^= low
        for tail in _enum_count_only_set(Pw & adj[v], need - 1, adj):
            out.add(low | tail)
    return out


def main():
    ok = True
    # Case A: small synthetic H = C7 v C7 (49 vertices), several (P,need)
    N, coords, adj, FULL = ps.build_H(7, 2)
    for need in (1, 2, 3):
        ok &= check_case(f"C7vC7 need={need} P=FULL", 7, 2, need, FULL, adj)
    ok &= check_case("C7vC7 need=2 P=adj[0]", 7, 2, 2, adj[0], adj)

    # Case B: the REAL H = C9^v3 (729 vertices) used by ERG-003, P=adj[0], need in {1,2,3}
    # (matches sX-1 for sX in {2,3,4}, exactly what decide_ranged will split)
    N9, coords9, adj9, FULL9 = ps.build_H(9, 3)
    for need in (1, 2, 3):
        ok &= check_case(f"C9^v3(REAL) need={need} P=adj[0]", 9, 3, need, adj9[0], adj9)

    # Case C: randomized candidate subsets of adj9[0], several sizes
    random.seed(0)
    bits0 = list(ps.bits(adj9[0]))
    for trial in range(5):
        keep = random.sample(bits0, k=random.randint(20, len(bits0)))
        P = 0
        for b in keep:
            P |= (1 << b)
        for need in (1, 2, 3):
            ok &= check_case(f"random-subset trial={trial} need={need} |P|={len(keep)}", 9, 3, need, P, adj9)

    print("\n" + ("ALL RANGED-SELFTEST CASES PASS" if ok else "SOME CASES FAILED"))
    return ok


if __name__ == "__main__":
    import sys as _sys
    _sys.exit(0 if main() else 1)
