import sys, time, multiprocessing as mp
sys.path.insert(0, '.')
import erg003_elim2 as e2
import erg003_pentagram_search as ps


def worker(args):
    i_lo, i_hi, order, colornum, vec, maxsec = args
    sol = e2.make_solver(9, 3)
    t0 = time.time()
    r = sol.decide_ranged(vec, maxsec=maxsec, i_lo=i_lo, i_hi=i_hi, order=order, colornum=colornum)
    r["wall"] = round(time.time() - t0, 1)
    return r


def main():
    fams = ps.families(18, cap=8)
    vec = fams[0]
    sol0 = e2.make_solver(9, 3)
    order, colornum = ps.greedy_color(sol0.adj[0], sol0.adj)
    L = len(order)
    K = 4
    base, rem = divmod(L, K)
    chunks = []
    lo = 0
    for i in range(K):
        sz = base + (1 if i < rem else 0)
        chunks.append((lo, lo + sz))
        lo += sz
    print("chunks:", chunks, "  (total span", L, ")")
    args = [(c[0], c[1], order, colornum, vec, 45) for c in chunks]
    t0 = time.time()
    with mp.Pool(K) as pool:
        results = pool.map(worker, args)
    dt = time.time() - t0
    print(f"wall clock for {K} parallel workers x 45s each: {dt:.1f}s")
    total_nodes = 0
    for c, r in zip(chunks, results):
        print(f"  chunk {c}: status={r['status']} nodes={r['nodes']} "
              f"chunk_exhausted={r.get('chunk_exhausted')} resume_i_hi={r.get('resume_i_hi')} "
              f"wall={r['wall']}s")
        total_nodes += r['nodes']
    # sanity: ranges partition correctly (no gaps/overlaps)
    sorted_chunks = sorted(chunks)
    ok = sorted_chunks[0][0] == 0 and sorted_chunks[-1][1] == L
    for a, b in zip(sorted_chunks, sorted_chunks[1:]):
        ok &= a[1] == b[0]
    print("partition covers [0,L) with no gaps/overlaps:", ok)
    print("total nodes across 4 parallel chunks:", total_nodes)
    any_yes = any(r['status'] == 'YES' for r in results)
    print("any YES found:", any_yes)


if __name__ == "__main__":
    main()
