# End-to-end validation of Elim2.decide_ranged against KNOWN GROUND TRUTH:
# the 3 fully-decided S=17 families (0=NO, 1=NO, 11=YES, verified witness).
# For each, run decide_ranged partitioned into several different chunk counts
# (union over chunks, no time limit) and confirm the AGGREGATE status matches
# ground truth exactly -- the critical regression test before trusting this in
# a real paid job.
import sys, time, json
sys.path.insert(0, '.')
import erg003_elim2 as e2
import erg003_pentagram_search as ps

CASES = [
    ("family0_NO", [1, 1, 1, 7, 7], "NO"),
    ("family1_NO", [1, 1, 2, 7, 6], "NO"),
    ("family11_YES", [1, 3, 5, 5, 3], "YES"),
]


def partitions(L, k):
    if L == 0:
        return [(0, 0)]
    base, rem = divmod(L, k)
    chunks = []
    lo = 0
    for i in range(k):
        sz = base + (1 if i < rem else 0)
        hi = lo + sz
        if sz > 0:
            chunks.append((lo, hi))
        lo = hi
    return chunks


def run_ranged_full(sol, vec, nchunks):
    adj = sol.adj
    order, colornum = ps.greedy_color(adj[0], adj)
    L = len(order)
    chunks = partitions(L, nchunks) if L > 0 else [(0, 0)]
    total_nodes = 0
    any_yes = None
    all_exhausted = True
    for (lo, hi) in chunks:
        r = sol.decide_ranged(vec, maxsec=None, i_lo=lo, i_hi=hi, order=order, colornum=colornum)
        total_nodes += r["nodes"]
        if r["status"] == "YES":
            any_yes = r
            break
        if not r.get("chunk_exhausted", False):
            all_exhausted = False
    if any_yes:
        return "YES", any_yes, total_nodes
    return ("NO" if all_exhausted else "PARTIAL"), None, total_nodes


def adjG_independent(u, v):
    if u == v:
        return False
    for t in range(3):
        if (u[t] - v[t]) % 9 in (1, 8):
            return True
    return (u[3] - v[3]) % 5 in (1, 4)


def verify_witness_independently(witness_pairs):
    # witness_pairs: [(layer, sorted H-vertex list), ...] from decide_ranged;
    # reconstruct G-tuples (x1,x2,x3,c) and check all pairs independently.
    n, k = 9, 3
    tuples = []
    for layer, hverts in witness_pairs:
        for hv in hverts:
            coords = []
            x = hv
            for _ in range(k):
                coords.append(x % n)
                x //= n
            coords.reverse()
            tuples.append(tuple(coords) + (layer,))
    from itertools import combinations
    bad = [(a, b) for a, b in combinations(tuples, 2) if not adjG_independent(a, b)]
    return len(tuples), bad


def main():
    ok = True
    for label, vec, expect in CASES:
        # fresh solver per trial -- a shared solver's pred_cache warms across
        # nchunks trials and makes later trials' node counts artificially low
        # (cache hits skip the search entirely); that's a benign perf artifact,
        # not a correctness issue, but we want an honest apples-to-apples count.
        sol0 = e2.make_solver(9, 3)
        r0 = sol0.decide(vec, maxsec=None, start_anchor=0)
        print(f"     {label} REFERENCE decide() (unranged, fresh solver): "
              f"status={r0['status']} nodes={r0['nodes']} plan={r0['plan']}", flush=True)
        for nchunks in (1, 2, 3, 4, 5):
            sol = e2.make_solver(9, 3)
            t0 = time.time()
            status, yes_result, nodes = run_ranged_full(sol, vec, nchunks)
            dt = time.time() - t0
            match = status == expect
            ok &= match
            extra = ""
            if status == "YES" and yes_result:
                sz, bad = verify_witness_independently(yes_result["witness"])
                extra = f" witness_size={sz} bad_pairs={len(bad)} independently_verified={len(bad)==0 and sz==17}"
                ok &= (len(bad) == 0 and sz == 17)
            print(f"{'OK  ' if match else 'FAIL'} {label} nchunks={nchunks}: status={status} "
                  f"(expect {expect}) nodes={nodes} [{dt:.1f}s]{extra}", flush=True)
    print("\n" + ("ALL E2E RANGED CASES PASS" if ok else "SOME E2E CASES FAILED"))
    return ok


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
