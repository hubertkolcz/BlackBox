"""ERG-003 generic two-layer elimination solver for pentagram families.

Problem (identical to erg003_pentagram_search.py): does G = H v C5 with
H = C_n^vk contain an S-clique with layer size vector vec?  Pentagram-layer
principle: layers Q_0..Q_4 are H-cliques, and for each pentagram pair
(i, i+2 mod 5) the union Q_i u Q_{i+2} is an H-clique.

Method: the pair constraints form a 5-cycle over the layers (ring order
0-2-4-1-3-0).  Pick two ring-NON-adjacent layers e1, e2 (ring: e1-X-e2-Y-Z-e1)
and ELIMINATE them: for fixed (Q_X, Q_Y, Q_Z) the eliminated layers exist iff
    P_e1: exists |Q_e1|-clique inside cn(Q_X) cap cn(Q_Z)
    P_e2: exists |Q_e2|-clique inside cn(Q_X) cap cn(Q_Y)
(e1's ring neighbours are X and Z; e2's are X and Y; cn = common H-nbhd).
Q_e1, Q_e2 are NOT mutually constrained (their layers are C5-adjacent), so the
two predicates are independent: this is exact CSP variable elimination, no
approximation.  Remaining constraints: Q_Y u Q_Z is a clique (ring edge Y-Z),
plus the two predicates.

Search: pin vertex 0 into Q_X (translation transitivity), enumerate
Q_X = {0} u (s_X-1)-cliques of N(0), then Q_Y inside the fvec-filtered set
FY = {y : all x in Q_X : fvec_{s_e2}[y-x] != False}  (fvec from
erg003_fvec.json: exists s-clique in N(a) cap N(b) depends only on b-a; False
entries are exact exhaustions, so the filter is sound; None/unknown pass),
exact-test P_e2, then Q_Z inside cn(Q_Y) cap FZ (fvec_{s_e1} filter vs Q_X),
exact-test P_e1.  All exact tests use the selftest-validated coloring-bounded
enumerator (find-first for YES, full exhaustion for NO).  Deterministic.

A YES rebuilds the full 17-vertex witness and verifies it independently
against raw G adjacency.  A NO is a full exhaustion of the family.

CLI:
  --gates       cross-validate on the C9^v2 (+C5) cell: every S=8,9 family
                status must equal the chain searcher's (search_family), which
                at S=9 reproduces the exhaustive NO of chain GATE-1b.
                Same for C7^v2 at S=9,10 (omega(C7vC7vC5)=9).
  --run17       all 26 S=17 families of the (9,3) cell, cheapest-first
  --fams i,..   subset
  --maxsec T    per-family budget (default 480), resumable via anchor skip
"""
import argparse
import itertools
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
RESULT_DIR = os.path.join(HERE, "erg003_family_results")
sys.path.insert(0, HERE)
import erg003_pentagram_search as ps

RING = [0, 2, 4, 1, 3]


def vsub(u, v, n, k):
    """coordinatewise difference u - v mod n as a vertex index."""
    out = 0
    p = 1
    r = 0
    cu, cv = [], []
    x = u
    for _ in range(k):
        cu.append(x % n)
        x //= n
    x = v
    for _ in range(k):
        cv.append(x % n)
        x //= n
    for t in range(k - 1, -1, -1):
        r = r * n + ((cu[t] - cv[t]) % n)
    return r


class Elim2:
    def __init__(self, n, k, fvec=None):
        self.n, self.k = n, k
        self.N, self.coords, self.adj, self.FULL = ps.build_H(n, k)
        self.omega = 2 ** k
        # difference table diff[u][v] would be N^2; compute per use instead
        self.fvec = fvec or {}
        self.pred_cache = {}
        # Stab(0) = coordinate permutations x per-coordinate reflection,
        # as explicit vertex permutation tables (automorphisms of H fixing 0)
        self.stab = []
        for p in itertools.permutations(range(k)):
            for sg in itertools.product((1, -1), repeat=k):
                tab = [0] * self.N
                for v in range(self.N):
                    cv = self.coords[v]
                    cw = tuple((sg[t] * cv[p[t]]) % n for t in range(k))
                    w = 0
                    for x in cw:
                        w = w * n + x
                    tab[v] = w
                self.stab.append(tab)

    def canon_union(self, mask):
        """canonical form of a vertex set under translations x Stab(0):
        translate each member to 0, apply all stab elements, take min tuple."""
        verts = list(ps.bits(mask))
        n, k = self.n, self.k
        best = None
        for u in verts:
            cu = self.coords[u]
            shifted = []
            for v in verts:
                cv = self.coords[v]
                w = 0
                for t in range(k):
                    w = w * n + ((cv[t] - cu[t]) % n)
                shifted.append(w)
            for tab in self.stab:
                img = tuple(sorted(tab[w] for w in shifted))
                if best is None or img < best:
                    best = img
        return best

    # -- exact predicate: exists s-clique in cn(A) cap cn(B) ----------------
    # depends on A,B only through U = A u B; cached on canon(U) under
    # translations x Stab(0) (automorphisms of H: soundness exact)
    def pred(self, maskA, maskB, s, stats):
        u = maskA | maskB
        k0 = (u, s)
        v = self.pred_cache.get(k0)
        if v is not None:
            return v
        key = (self.canon_union(u), s)
        v = self.pred_cache.get(key)
        if v is None:
            cand = self.FULL
            for x in ps.bits(u):
                cand &= self.adj[x]
            v = False
            for _ in ps.enum_size_cliques(cand, s, self.adj, stats):
                v = True
                break
            if len(self.pred_cache) < 4_000_000:
                self.pred_cache[key] = v
        if len(self.pred_cache) < 4_000_000:
            self.pred_cache[k0] = v
        return v

    def pred_witness(self, maskA, maskB, s):
        cand = self.FULL
        for x in ps.bits(maskA | maskB):
            cand &= self.adj[x]
        st = [0, None]
        for m in ps.enum_size_cliques(cand, s, self.adj, st):
            return m
        return None

    # -- fvec filter: vertices y compatible with every x in mask ------------
    def filt(self, mask, s):
        tab = self.fvec.get(s)
        if tab is None:
            return self.FULL
        out = self.FULL
        for x in ps.bits(mask):
            out &= tab[x]
        return out

    # -- choose elimination pair + ordering ---------------------------------
    def plans(self, vec):
        """yield (e1, e2, X, Y, Z) ring layouts; e1 nbrs X,Z; e2 nbrs X,Y."""
        for i in range(5):
            e1 = RING[i]
            X = RING[(i + 1) % 5]
            e2 = RING[(i + 2) % 5]
            Y = RING[(i + 3) % 5]
            Z = RING[(i + 4) % 5]
            yield (e1, e2, X, Y, Z)

    def plan_cost(self, vec, plan):
        e1, e2, X, Y, Z = plan
        s_e1, s_e2 = vec[e1], vec[e2]
        sX, sY, sZ = vec[X], vec[Y], vec[Z]
        if sX == 0:
            return None  # pin needs nonempty X (all S=17 sizes >=1 anyway)
        # eliminate the biggest layers; heavily reward sparse fvec on e1/e2
        anchor = {1: 1, 2: 386, 3: 37464, 4: 1202564,
                  5: 14461740}.get(sX, 10 ** 9)
        dens1 = self.fvec_density(s_e1)
        dens2 = self.fvec_density(s_e2)
        fy = self.N * (dens2 ** max(sX, 1))
        qy = max(fy, 1.0) ** sY
        fz = self.N * 0.53 ** sY * (dens1 ** max(sX, 1))
        qz = max(fz, 1.0) ** sZ
        return anchor * (1.0 + qy * (1.0 + qz))

    def fvec_density(self, s):
        return getattr(self, "_dens", {}).get(s, 1.0)

    # -- persistent canonical predicate cache (family-independent facts) ----
    def load_cache(self, fn):
        if os.path.exists(fn):
            with open(fn) as f:
                for verts, s, val in json.load(f):
                    self.pred_cache[(tuple(verts), s)] = bool(val)
            print(f"[cache] loaded {len(self.pred_cache)} canonical predicate "
                  f"entries", flush=True)

    def save_cache(self, fn):
        rows = [[list(kk[0]), kk[1], vv]
                for kk, vv in self.pred_cache.items()
                if isinstance(kk[0], tuple)]
        with open(fn, "w") as f:
            json.dump(rows, f)
        print(f"[cache] saved {len(rows)} canonical predicate entries",
              flush=True)

    # -- family decision -----------------------------------------------------
    def decide(self, vec, maxsec=None, start_anchor=0):
        best = None
        for plan in self.plans(vec):
            c = self.plan_cost(vec, plan)
            if c is not None and (best is None or c < best[0]):
                best = (c, plan)
        e1, e2, X, Y, Z = best[1]
        s_e1, s_e2 = vec[e1], vec[e2]
        sX, sY, sZ = vec[X], vec[Y], vec[Z]
        adj, FULL = self.adj, self.FULL
        stats = [0, (time.time() + maxsec) if maxsec else None]
        ai = -1

        def anchors():
            if sX == 1:
                yield 1  # {0}
            else:
                for t in ps.enum_size_cliques(adj[0], sX - 1, adj, stats):
                    yield t | 1

        try:
            for qx in anchors():
                ai += 1
                if ai < start_anchor:
                    continue
                fy = self.filt(qx, s_e2)
                # Q_Y enumeration within fy
                for qy in ps.enum_size_cliques(fy, sY, adj, stats) \
                        if sY > 0 else iter((0,)):
                    if not self.pred(qx, qy, s_e2, stats):
                        continue
                    fz = self.filt(qx, s_e1)
                    cz = fz
                    for v in ps.bits(qy):
                        cz &= adj[v]
                    for qz in ps.enum_size_cliques(cz, sZ, adj, stats) \
                            if sZ > 0 else iter((0,)):
                        if not self.pred(qx, qz, s_e1, stats):
                            continue
                        # witness
                        m1 = self.pred_witness(qx, qz, s_e1)
                        m2 = self.pred_witness(qx, qy, s_e2)
                        wit = {X: qx, Y: qy, Z: qz, e1: m1, e2: m2}
                        return {"status": "YES", "nodes": stats[0],
                                "anchors_done": ai + 1, "plan": best[1],
                                "witness": [(l, sorted(ps.bits(wit[l])))
                                            for l in range(5)]}
        except ps.Deadline:
            return {"status": "PARTIAL", "nodes": stats[0],
                    "anchors_done": max(ai, 0), "plan": best[1],
                    "witness": None}
        return {"status": "NO", "nodes": stats[0], "anchors_done": ai + 1,
                "plan": best[1], "witness": None}

    # -- family decision, TOP-LEVEL ROOT-RANGE-SPLIT (multi-core parallel) ---
    def decide_ranged(self, vec, maxsec=None, i_lo=0, i_hi=None, order=None, colornum=None):
        """Same decision as decide(), but restricts the anchor/X-layer search to
        root indices [i_lo, i_hi) in the SAME order/colornum arrays
        ps.greedy_color(adj[0], adj) produces (pass the identical precomputed
        arrays to every chunk splitting one family, so root index i means the
        identical vertex/position everywhere). Disjoint contiguous chunks whose
        ranges union to [0, len(order)) decide the SAME family exhaustively and
        without overlap -- validated in erg003_ranged_selftest.py (set-equality
        unit tests) and against the full, already-decided S=17 census (status
        agreement end-to-end). sX==1 families have a single trivial anchor {0},
        handled specially and assigned by convention to the i_lo==0 chunk only.
        Resumable: a PARTIAL result reports resume_i_hi -- pass it as the next
        call's i_hi (i_lo unchanged) to continue this exact sub-range."""
        best = None
        for plan in self.plans(vec):
            c = self.plan_cost(vec, plan)
            if c is not None and (best is None or c < best[0]):
                best = (c, plan)
        e1, e2, X, Y, Z = best[1]
        s_e1, s_e2 = vec[e1], vec[e2]
        sX, sY, sZ = vec[X], vec[Y], vec[Z]
        adj, FULL = self.adj, self.FULL
        stats = [0, (time.time() + maxsec) if maxsec else None]

        def try_anchor(qx):
            fy = self.filt(qx, s_e2)
            for qy in ps.enum_size_cliques(fy, sY, adj, stats) if sY > 0 else iter((0,)):
                if not self.pred(qx, qy, s_e2, stats):
                    continue
                fz = self.filt(qx, s_e1)
                cz = fz
                for v in ps.bits(qy):
                    cz &= adj[v]
                for qz in ps.enum_size_cliques(cz, sZ, adj, stats) if sZ > 0 else iter((0,)):
                    if not self.pred(qx, qz, s_e1, stats):
                        continue
                    m1 = self.pred_witness(qx, qz, s_e1)
                    m2 = self.pred_witness(qx, qy, s_e2)
                    wit = {X: qx, Y: qy, Z: qz, e1: m1, e2: m2}
                    return {"status": "YES", "nodes": stats[0], "plan": best[1],
                            "witness": [(l, sorted(ps.bits(wit[l]))) for l in range(5)]}
            return None

        if sX == 1:
            if i_lo == 0:
                r = try_anchor(1)
                if r:
                    r.update({"i_lo": i_lo, "i_hi": i_hi, "chunk_exhausted": True})
                    return r
            return {"status": "NO", "nodes": stats[0], "i_lo": i_lo, "i_hi": i_hi,
                    "chunk_exhausted": True, "plan": best[1], "witness": None}

        if order is None or colornum is None:
            order, colornum = ps.greedy_color(adj[0], adj)
        if i_hi is None:
            i_hi = len(order)
        need = sX - 1

        excluded = 0
        for j in range(len(order) - 1, i_hi - 1, -1):
            excluded |= (1 << order[j])
        Pw = adj[0] & ~excluded

        try:
            for i in range(i_hi - 1, i_lo - 1, -1):
                if colornum[i] < need:
                    return {"status": "NO", "nodes": stats[0], "i_lo": i_lo, "i_hi": i_hi,
                            "chunk_exhausted": True, "plan": best[1], "witness": None}
                v = order[i]
                low = 1 << v
                if not (Pw & low):
                    continue
                subP = Pw & adj[v]
                for t in ps.enum_size_cliques(subP, need - 1, adj, stats):
                    qx = (low | t) | 1
                    r = try_anchor(qx)
                    if r:
                        r.update({"i_lo": i_lo, "i_hi": i_hi, "chunk_exhausted": False,
                                  "stopped_at_i": i})
                        return r
                Pw ^= low
        except ps.Deadline:
            return {"status": "PARTIAL", "nodes": stats[0], "i_lo": i_lo, "i_hi": i_hi,
                    "resume_i_hi": i + 1, "chunk_exhausted": False, "plan": best[1],
                    "witness": None}

        return {"status": "NO", "nodes": stats[0], "i_lo": i_lo, "i_hi": i_hi,
                "chunk_exhausted": True, "plan": best[1], "witness": None}


def load_fvec_93():
    fn = os.path.join(HERE, "erg003_fvec.json")
    if not os.path.exists(fn):
        return None, None
    with open(fn) as f:
        d = json.load(f)
    reps = d["orbit_reps"]
    orbit_of = d["orbit_of"]
    N = len(orbit_of)
    masks = {}
    dens = {}
    for s_str, tab in d["tables"].items():
        s = int(s_str)
        m = [0] * N
        cnt = 0
        for u in range(N):
            v = tab.get(str(reps[orbit_of[u]]))
            if v is not False:      # True or unknown -> passes filter
                cnt += 1
        dens[s] = cnt / N
        masks[s] = m
    return d, dens


def build_fvec_masks(n, k, per_orbit_cap=120.0):
    """fvec masks straight from stored JSON for (9,3); brute for small cells."""
    N, coords, adj, FULL = ps.build_H(n, k)
    if (n, k) == (9, 3):
        fn = os.path.join(HERE, "erg003_fvec.json")
        with open(fn) as f:
            d = json.load(f)
        reps, orbit_of = d["orbit_reps"], d["orbit_of"]
        out = {}
        dens = {}
        for s_str, tab in d["tables"].items():
            s = int(s_str)
            m = {}
            mask_all = 0
            cnt = 0
            for u in range(N):
                v = tab.get(str(reps[orbit_of[u]]))
                if v is not False:
                    mask_all |= (1 << u)
                    cnt += 1
            # per-vertex filter mask: translate mask_all by +x for each x
            out[s] = (mask_all, None)
            dens[s] = cnt / N
        return out, dens
    # small cells: compute difference-vector table directly (exact, cheap)
    out = {}
    dens = {}
    omega = 2 ** k
    for s in range(2, omega + 1):
        mask_all = 0
        cnt = 0
        for u in range(N):
            cand = adj[0] & adj[u] if u else adj[0]
            got = False
            for _ in ps.enum_size_cliques(cand, s, adj, [0, None]):
                got = True
                break
            if got:
                mask_all |= (1 << u)
                cnt += 1
        out[s] = (mask_all, None)
        dens[s] = cnt / N
    return out, dens


class FvecView:
    """fvec[s][x] as a bitmask of compatible partners of x = translate of the
    base difference mask by +x (u passes iff (u - x) in base set)."""
    def __init__(self, n, k, base_masks):
        self.n, self.k = n, k
        self.N = n ** k
        self.base = base_masks  # {s: (mask_over_diffs, _)}
        self.cache = {}

    def get(self, s):
        if s not in self.base:
            return None
        return _TwistedRow(self, s)


class _TwistedRow:
    def __init__(self, view, s):
        self.view = view
        self.s = s

    def __getitem__(self, x):
        key = (self.s, x)
        c = self.view.cache.get(key)
        if c is not None:
            return c
        base, _ = self.view.base[self.s]
        n, k, N = self.view.n, self.view.k, self.view.N
        m = 0
        b = base
        while b:
            low = b & -b
            d = low.bit_length() - 1
            b ^= low
            # u = x + d coordinatewise
            u = 0
            xd, dd = x, d
            cu = []
            for _ in range(k):
                cu.append(((xd % n) + (dd % n)) % n)
                xd //= n
                dd //= n
            for t in range(k - 1, -1, -1):
                u = u * n + cu[t]
            m |= (1 << u)
        if len(self.view.cache) < 100000:
            self.view.cache[key] = m
        return m


def make_solver(n, k):
    base, dens = build_fvec_masks(n, k)
    view = FvecView(n, k, base)
    sol = Elim2(n, k)
    sol.fvec = {s: view.get(s) for s in base}
    sol._dens = dens
    return sol


def verify_and_report(sol, vec, r, S):
    out = {"family": list(vec), "S": S, "method": "elim2",
           "status": r["status"], "nodes": r["nodes"],
           "anchors_done": r["anchors_done"], "plan": list(r["plan"])}
    if r["status"] == "YES":
        tup = ps.witness_to_tuples(r["witness"], sol.coords)
        okv, det = ps.verify_G_clique(tup, sol.n, sol.k)
        out["witness"] = [list(t) for t in tup]
        out["witness_verified"] = okv
        out["witness_detail"] = det
    return out


def run_gates():
    ok_all = True

    def gate(label, cond, detail):
        nonlocal ok_all
        st = "PASS" if cond else "FAIL"
        if not cond:
            ok_all = False
        print(f"ELIM2-GATE {label}: {st} -- {detail}", flush=True)

    for (n, k, Syes, Sno) in ((9, 2, 8, 9), (7, 2, 9, 10)):
        sol = make_solver(n, k)
        N, coords, adj, FULL = ps.build_H(n, k)
        mism = []
        gotyes = False
        for S in (Syes, Sno):
            for vec in ps.families(S, cap=2 ** k):
                a = sol.decide(vec)
                b = ps.search_family(vec, adj, FULL, N, want_first=True)
                if a["status"] != b["status"]:
                    mism.append(f"S={S} {vec}: elim2={a['status']} "
                                f"chain={b['status']}")
                if S == Syes and a["status"] == "YES":
                    rep = verify_and_report(sol, vec, a, S)
                    if rep.get("witness_verified"):
                        gotyes = True
                    else:
                        mism.append(f"S={S} {vec}: witness verify FAIL")
        gate(f"C{n}^v{k}", not mism and gotyes,
             f"S={Syes} YES verified={gotyes}; per-family agreement with "
             f"chain searcher on S={Syes},{Sno}: "
             f"{'exact' if not mism else mism}")
    print(f"\nELIM2 GATES {'ALL PASS' if ok_all else 'FAILED'}", flush=True)
    return ok_all


def run17(only=None, maxsec=480, cache_fn=None):
    sol = make_solver(9, 3)
    if cache_fn:
        sol.load_cache(cache_fn)
    fams = ps.families(17, cap=8)
    order = sorted(range(len(fams)),
                   key=lambda i: min(c for c in
                                     (sol.plan_cost(fams[i], p)
                                      for p in sol.plans(fams[i]))
                                     if c is not None))
    os.makedirs(RESULT_DIR, exist_ok=True)
    for i in order:
        if only is not None and i not in only:
            continue
        vec = fams[i]
        fn = os.path.join(RESULT_DIR, f"family_{i:02d}.json")
        prev = None
        if os.path.exists(fn):
            with open(fn) as f:
                prev = json.load(f)
            if prev.get("status") in ("NO", "YES"):
                print(f"[skip] fam {i:02d} {vec} already {prev['status']} "
                      f"({prev.get('method','chain')})", flush=True)
                continue
        start = prev.get("anchors_done", 0) \
            if prev and prev.get("method") == "elim2" else 0
        t0 = time.time()
        r = sol.decide(vec, maxsec=maxsec, start_anchor=start)
        dt = time.time() - t0
        out = verify_and_report(sol, vec, r, 17)
        out["wall_seconds"] = round(dt, 1)
        if prev and prev.get("method") != "elim2":
            out["chain_partial"] = {kk: prev.get(kk) for kk in
                                    ("nodes", "anchors_done", "wall_seconds")}
        if r["status"] == "PARTIAL" and prev and prev.get("method") == "elim2":
            out["wall_seconds"] = round(dt + prev.get("wall_seconds", 0), 1)
        with open(fn, "w") as f:
            json.dump(out, f, indent=1)
        if cache_fn:
            sol.save_cache(cache_fn)
        print(f"[{r['status']}] fam {i:02d} {vec} plan={r['plan']} "
              f"nodes={r['nodes']} anchors={r['anchors_done']} {dt:.1f}s"
              + (f" verify={out.get('witness_detail')}"
                 if r["status"] == "YES" else ""), flush=True)
        if r["status"] == "YES":
            print("!!! JACKPOT -- stopping", flush=True)
            return


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gates", action="store_true")
    ap.add_argument("--run17", action="store_true")
    ap.add_argument("--fams", type=str)
    ap.add_argument("--maxsec", type=float, default=480)
    ap.add_argument("--cache", type=str, default="erg003_predcache.json")
    args = ap.parse_args()
    if args.gates:
        ok = run_gates()
        sys.exit(0 if ok else 1)
    if args.run17:
        only = set(int(x) for x in args.fams.split(",")) if args.fams else None
        run17(only=only, maxsec=args.maxsec,
              cache_fn=os.path.join(HERE, args.cache))
        return
    ap.print_help()


if __name__ == "__main__":
    main()
