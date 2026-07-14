"""ERG-003 pentagram-layer clique search for G = Cn v Cn v ... v C5 (k boxes + C5).

Decides existence of an S-clique in G = H v C5, H = OR/conormal power of Cn (k
copies), by the pentagram-layer reduction (design doc
erg003-pentagram-design-2026-07-13.md). A G-clique meets each C5 layer c in a set
Q_c that is an H-clique; C5-adjacent layers are jointly free (conormal); the two
pentagram-nonadjacent layers of each position must union to an H-clique. Placing
the 5 layers along the pentagram 5-cycle 0-2-4-1-3-0 makes consecutive layers the
constrained pairs: Q_{j+1} subset N_H(Q_j), and the cycle closes with
Q_4 subset N_H(Q_3) cap N_H(Q_0). One translation pin (H is vertex-transitive)
fixes vertex 0 into the smallest nonempty layer.

Everything is bitset (Python big-int masks over |V(H)| bits) and DETERMINISTIC:
vertices scanned in increasing index, families in fixed canonical order, no RNG.

CLI:
  --gates                 run mandatory validation gates (1a,1b,2), print literal
  --probe S               capped cost probe over all S-families, ranks cheapest-first
  --run S [--maxsec T]    full per-family search for target S; resumable JSON per family
  --family "a,b,c,d,e"    run one explicit size-vector family (debug)

Result files: erg003_family_results/family_NN.json
  {family, S, pin_layer, status in NO|YES|PARTIAL, witness|null, nodes,
   anchors_done, anchors_total_or_-1, wall_seconds}
"""
import argparse
import itertools
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
RESULT_DIR = os.path.join(HERE, "erg003_family_results")


# ---------------------------------------------------------------------------
# H = OR-power of C_n (k copies).  Vertices 0..n^k-1, mixed-radix base n.
# ---------------------------------------------------------------------------
def build_H(n, k):
    N = n ** k
    coords = [None] * N
    for v in range(N):
        c = []
        x = v
        for _ in range(k):
            c.append(x % n)
            x //= n
        coords[v] = tuple(reversed(c))
    # adjacency as big-int bitsets
    adj = [0] * N
    for u in range(N):
        cu = coords[u]
        row = 0
        for w in range(N):
            if u == w:
                continue
            cw = coords[w]
            if any((cu[t] - cw[t]) % n in (1, n - 1) for t in range(k)):
                row |= (1 << w)
        adj[u] = row
    FULL = (1 << N) - 1
    return N, coords, adj, FULL


class Deadline(Exception):
    """raised inside enumeration when the wall-clock budget is exhausted."""


# ---------------------------------------------------------------------------
# bitset helpers
# ---------------------------------------------------------------------------
def bits(mask):
    while mask:
        low = mask & -mask
        yield low.bit_length() - 1
        mask ^= low


def neigh_of_clique(verts, adj, FULL):
    """common H-neighborhood of a list of vertices; empty list -> FULL."""
    m = FULL
    for v in verts:
        m &= adj[v]
    return m


# ---------------------------------------------------------------------------
# exact-size clique enumeration inside a candidate bitset P (induced subgraph).
# Deterministic: always consume the lowest-index candidate first, only extend to
# higher-index neighbors (combination order, each clique emitted once).
# Yields chosen-vertex bitsets of size == need.  Counts nodes into stats[0].
# ---------------------------------------------------------------------------
def greedy_color(P, adj):
    """Greedy coloring of the induced subgraph on candidate set P (big-int mask).
    Returns (order, colornum): vertices grouped into independent color classes,
    listed ascending by color.  colornum[i] is the color of order[i].  A clique
    picks <=1 vertex per color, so a clique using only vertices of color <= c has
    size <= c: the Tomita MCQ upper bound.  Mirrors color_sort() in
    d1_k3_maxclique.c."""
    order = []
    colornum = []
    Pleft = P
    color = 0
    while Pleft:
        color += 1
        Q = Pleft
        while Q:
            low = Q & -Q
            v = low.bit_length() - 1
            order.append(v)
            colornum.append(color)
            Pleft ^= low                 # remove v from Pleft
            Q = Q & ~adj[v] & ~low       # same color class = independent set
    return order, colornum


def enum_size_cliques(P, need, adj, stats):
    """Yield every size-`need` clique (as a chosen big-int bitmask) inside the
    induced subgraph on candidate set P.  Tomita greedy-coloring bound: process
    vertices high-color-first and break when a vertex's color < need (the
    remaining vertices cannot complete a `need`-clique).  SOUND -- never skips a
    real clique -- validated by selftest against the count-only enumerator."""
    if need == 0:
        yield 0
        return
    stats[0] += 1
    if stats[1] is not None and (stats[0] & 0x3FFF) == 0 and time.time() > stats[1]:
        raise Deadline
    if P.bit_count() < need:
        return
    order, colornum = greedy_color(P, adj)
    Pw = P
    for i in range(len(order) - 1, -1, -1):
        if colornum[i] < need:           # bound: remaining colors too few
            break
        v = order[i]
        low = 1 << v
        subP = Pw & adj[v]
        for tail in enum_size_cliques(subP, need - 1, adj, stats):
            yield low | tail
        Pw ^= low                        # v exhausted as a chosen vertex


def enum_size_cliques_ranged(P, need, adj, stats, i_lo, i_hi, order, colornum):
    """TOP-LEVEL-ONLY root-split variant of enum_size_cliques (need >= 1 only --
    the need==0 base case never applies here since this is only ever called at
    the anchor/X-layer level, where need = sX-1 >= 1). order/colornum MUST be the
    exact arrays greedy_color(P, adj) would produce for this SAME P -- precompute
    ONCE and pass the identical arrays to every worker splitting this P's root
    range, so root index i means the identical vertex/position in every worker.

    Restricts the OUTER loop (which enum_size_cliques runs over i in
    range(len(order)-1, -1, -1)) to i in [i_lo, i_hi) -- i.e. i = i_hi-1 downto
    i_lo, using the SAME i-descending traversal and coloring-bound break.
    Reproduces Pw's exact state at the start of that sub-range by excluding every
    root at position j >= i_hi (already consumed by earlier chunks in the FULL
    traversal, per Pw's monotonic-exclusion invariant). Because each root's
    subtree is disjoint (Pw excludes a root after its subtree completes, in every
    chunk consistently), a partition of [0, len(order)) into disjoint contiguous
    [i_lo, i_hi) ranges, unioned across workers, yields EXACTLY the same set of
    cliques as one call to enum_size_cliques(P, need, adj, stats) -- no omissions,
    no duplicates. Exhaustively validated against enum_size_cliques and the
    count-only reference in erg003_ranged_selftest.py (unit-level set-equality on
    synthetic cases; end-to-end status agreement on the full, already-decided
    S=17 census)."""
    assert need >= 1
    excluded = 0
    for j in range(len(order) - 1, i_hi - 1, -1):
        excluded |= (1 << order[j])
    Pw = P & ~excluded
    for i in range(i_hi - 1, i_lo - 1, -1):
        if colornum[i] < need:           # bound: remaining colors too few
            break
        v = order[i]
        low = 1 << v
        if not (Pw & low):
            continue                     # v not in P at all (shouldn't happen if
                                          # order/colornum truly came from this P)
        stats[0] += 1
        if stats[1] is not None and (stats[0] & 0x3FFF) == 0 and time.time() > stats[1]:
            raise Deadline
        subP = Pw & adj[v]
        for tail in enum_size_cliques(subP, need - 1, adj, stats):
            yield low | tail
        Pw ^= low                        # v exhausted as a chosen vertex


def _enum_count_only(P, need, adj):
    """Reference enumerator (count-only, no coloring bound) for selftest."""
    if need == 0:
        return 1
    if P.bit_count() < need:
        return 0
    total = 0
    Pw = P
    while Pw:
        low = Pw & -Pw
        v = low.bit_length() - 1
        Pw ^= low
        total += _enum_count_only(Pw & adj[v], need - 1, adj)
    return total


def selftest():
    """Validate the coloring-bounded enumerator against the count-only reference
    on the 2-box cell H = C7 v C7 (small) for several candidate sets and sizes."""
    N, coords, adj, FULL = build_H(7, 2)
    ok = True
    cases = [FULL, adj[0], adj[0] & adj[8], adj[3], adj[1] & adj[2]]
    for ci, P in enumerate(cases):
        for need in range(1, 5):
            ref = _enum_count_only(P, need, adj)
            got = sum(1 for _ in enum_size_cliques(P, need, adj, [0, None]))
            flag = "ok" if ref == got else "MISMATCH"
            if ref != got:
                ok = False
            print(f"  selftest case{ci} need={need}: ref={ref} colored={got} [{flag}]",
                  flush=True)
    # also on H=C9^3 for a couple of neighborhoods and larger sizes
    N3, c3, adj3, F3 = build_H(9, 3)
    for ci, P in enumerate([adj3[0], adj3[0] & adj3[1]]):
        for need in (2, 3, 4):
            ref = _enum_count_only(P, need, adj3)
            got = sum(1 for _ in enum_size_cliques(P, need, adj3, [0, None]))
            flag = "ok" if ref == got else "MISMATCH"
            if ref != got:
                ok = False
            print(f"  selftest H3 case{ci} need={need}: ref={ref} colored={got} [{flag}]",
                  flush=True)
    print(f"SELFTEST {'PASS' if ok else 'FAIL'}", flush=True)
    return ok


# ---------------------------------------------------------------------------
# pentagram machinery
# ---------------------------------------------------------------------------
PENT = [0, 2, 4, 1, 3]          # pentagram 5-cycle order over the C5 layers


def d5_orbit(v):
    o = set()
    for k in range(5):
        o.add(tuple(v[(i - k) % 5] for i in range(5)))
        o.add(tuple(v[(-i - k) % 5] for i in range(5)))
    return o


def canon(v):
    return min(d5_orbit(v))


def families(total, cap):
    """canonical size vectors (s_0..s_4), sum=total, s_i+s_{i+2}<=cap, up to D5.
    Returned sorted for a stable family numbering."""
    raw = [v for v in itertools.product(range(cap + 1), repeat=5)
           if sum(v) == total and all(v[i] + v[(i + 2) % 5] <= cap for i in range(5))]
    fam = sorted({canon(v) for v in raw})
    return fam


def _order_cost(cs):
    """Heuristic cost of a chain ordering (cs = sizes along the pentagram cycle,
    position 0 = pinned anchor, closing edge 4->0).  Lower is cheaper.
    Uses the PROVEN bound omega(N_H(clique size p)) <= 8-p: a layer whose
    pentagram-predecessor is EMPTY ranges over all cliques in full H (very loose);
    a layer whose predecessor+own size == 8 is forced to a max clique of a
    neighborhood (tight/cheap); intermediate 'looseness' = 8-pred-own."""
    if cs[0] == 0:
        return (9, 9, 9, 9)                      # anchor must be nonempty: reject
    empty_pred_big = 0                            # big layers after an empty layer
    looseness = 0
    for j in range(1, 5):
        if cs[j] == 0:
            continue
        # tighter of the constraining predecessors (layer 4 also sees the anchor)
        preds = [cs[j - 1]]
        if j == 4:
            preds.append(cs[0])
        p = max(preds)
        if p == 0:
            empty_pred_big += cs[j] * cs[j]       # unconstrained: cost ~ size^2
        else:
            looseness += (8 - p - cs[j])
    # anchor freedom grows with anchor size; prefer small anchor last tie-break
    return (empty_pred_big, looseness, cs[0], sum(1 for x in cs if x > 0))


def chain_from_vector(vec):
    """Return (chain_sizes, chain_layers) as the cheapest valid dihedral traversal
    of the pentagram 5-cycle whose anchor (position 0) is nonempty.  Correctness is
    unaffected by the choice (all 10 D5 traversals search the same family); only
    cost differs.  chain_layers[j] = which C5 layer sits at chain position j."""
    base_layers = PENT[:]                         # [0,2,4,1,3]
    base_sizes = [vec[l] for l in base_layers]
    best = None
    for direction in (1, -1):
        L = base_layers[::direction]
        Sz = base_sizes[::direction]
        for start in range(5):
            cs = [Sz[(start + j) % 5] for j in range(5)]
            cl = [L[(start + j) % 5] for j in range(5)]
            if cs[0] == 0:
                continue
            key = _order_cost(cs)
            if best is None or key < best[0]:
                best = (key, cs, cl)
    return best[1], best[2]


# ---------------------------------------------------------------------------
# per-family search
# ---------------------------------------------------------------------------
def search_family(vec, adj, FULL, N, want_first=True, maxsec=None,
                  start_anchor=0, stats=None, progress=None):
    """Search one canonical size vector `vec` for a full 5-layer assignment.

    Returns dict: {status, witness (list of chain-layer vertex sets) or None,
                   nodes, anchors_done, anchors_total (or -1 if streamed)}.
    Deterministic.  If maxsec exceeded -> status PARTIAL with anchors_done so far.
    `start_anchor` skips that many top-level anchor cliques (resume).
    """
    if stats is None:
        stats = [0, None]
    stats[1] = (time.time() + maxsec) if maxsec is not None else None
    cs, cl = chain_from_vector(vec)
    m0 = cs[0]

    # anchor stream: cliques of size m0 through vertex 0 = {0} + (m0-1)-clique in N(0)
    anchor_tail_need = m0 - 1
    anchor_stream = enum_size_cliques(adj[0], anchor_tail_need, adj, stats)

    ai = -1
    witness = None
    try:
        for tail in anchor_stream:
            ai += 1
            if ai < start_anchor:
                continue
            Q0 = [0] + list(bits(tail))
            Q0mask = 1 | tail
            nQ0 = neigh_of_clique(Q0, adj, FULL)
            res = _extend_chain(1, cs, cl, [Q0], [Q0mask], nQ0, nQ0, adj, FULL, stats,
                                want_first)
            if res is not None:
                witness = res
                break
    except Deadline:
        # deadline hit while processing anchor `ai` (0..ai-1 fully done)
        return {"status": "PARTIAL", "witness": None, "nodes": stats[0],
                "anchors_done": max(ai, 0), "anchors_total": -1}
    if witness is not None:
        return {"status": "YES", "witness": witness, "nodes": stats[0],
                "anchors_done": ai + 1, "anchors_total": ai + 1}
    return {"status": "NO", "witness": witness, "nodes": stats[0],
            "anchors_done": ai + 1, "anchors_total": ai + 1}


def _extend_chain(j, cs, cl, Qs, Qmasks, cand_prev, nQ0, adj, FULL, stats, want_first):
    """Recurse placing chain layer j (1..4). cand_prev = N_H(Q_{j-1}) (FULL if the
    previous layer was empty). nQ0 = N_H(Q_0) for the closing constraint.
    Returns a witness [(layer, [verts])...] or None."""
    if j == 5:
        # full assignment
        return [(cl[i], sorted(bits(Qmasks[i]))) for i in range(5)]
    mj = cs[j]
    if mj == 0:
        # empty layer: no constraint contributed; N(empty)=FULL for the next layer
        Qs2 = Qs + [[]]
        Qmasks2 = Qmasks + [0]
        cand_next = FULL
        # closing handled when j reaches 4
        if j == 4:
            # last layer empty: closing constraint vacuous, success
            return [(cl[i], sorted(bits(Qmasks2[i]))) for i in range(5)]
        return _extend_chain(j + 1, cs, cl, Qs2, Qmasks2, cand_next, nQ0, adj, FULL,
                             stats, want_first)
    # candidate set for this layer
    if j == 4:
        cand = cand_prev & nQ0            # close the pentagram cycle
    else:
        cand = cand_prev
    for chosen in enum_size_cliques(cand, mj, adj, stats):
        cverts = list(bits(chosen))
        if j == 4:
            return [(cl[i], sorted(bits(Qmasks[i]))) for i in range(4)] + \
                   [(cl[4], sorted(cverts))]
        nQj = neigh_of_clique(cverts, adj, FULL)
        res = _extend_chain(j + 1, cs, cl, Qs + [cverts], Qmasks + [chosen], nQj, nQ0,
                            adj, FULL, stats, want_first)
        if res is not None:
            return res
    return None


# ---------------------------------------------------------------------------
# witness verification (independent, from raw adjacency of G = H v C5)
# ---------------------------------------------------------------------------
def verify_G_clique(tuples, n, k):
    """tuples: list of (h-coords..., c). All pairs must be G-adjacent, distinct."""
    def adjG(u, v):
        if u == v:
            return False
        for t in range(k):
            if (u[t] - v[t]) % n in (1, n - 1):
                return True
        if (u[k] - v[k]) % 5 in (1, 4):
            return True
        return False
    if len(set(tuples)) != len(tuples):
        return False, "duplicate vertices"
    bad = 0
    for a, b in itertools.combinations(tuples, 2):
        if not adjG(a, b):
            bad += 1
    return bad == 0, f"{len(tuples)} verts, {bad} nonadjacent pairs of {len(tuples)*(len(tuples)-1)//2}"


def witness_to_tuples(witness, coords):
    """witness = [(layer, [h-vertex-indices])]; -> list of (h-coords..., c)."""
    out = []
    for layer, verts in witness:
        for hv in verts:
            out.append(tuple(coords[hv]) + (layer,))
    return out


# ---------------------------------------------------------------------------
# GATES
# ---------------------------------------------------------------------------
def run_gates():
    ok_all = True

    def gate(label, cond, detail):
        nonlocal ok_all
        status = "PASS" if cond else "FAIL"
        if not cond:
            ok_all = False
        print(f"GATE {label}: {status} -- {detail}", flush=True)
        return cond

    # ---- GATE-1a: omega(C7 v C7 v C5) = 9 : FIND a 9-clique ----
    N, coords, adj, FULL = build_H(7, 2)
    fams = families(9, cap=4)           # omega(H2)=4
    found = None
    for vec in fams:
        r = search_family(vec, adj, FULL, N, want_first=True)
        if r["status"] == "YES":
            found = (vec, r); break
    if found:
        vec, r = found
        tup = witness_to_tuples(r["witness"], coords)
        okv, det = verify_G_clique(tup, 7, 2)
        gate("1a", len(tup) == 9 and okv,
             f"omega(C7vC7vC5)>=9: found 9-clique family {vec}, verify {det}")
    else:
        gate("1a", False, "NO 9-clique found in C7vC7vC5 (expected YES)")

    # ---- GATE-1b: omega(C9 v C9 v C5) = 8 : target-8 YES, target-9 NO ----
    N9, coords9, adj9, FULL9 = build_H(9, 2)
    f8 = families(8, cap=4)
    got8 = any(search_family(v, adj9, FULL9, N9, want_first=True)["status"] == "YES"
               for v in f8)
    f9 = families(9, cap=4)
    got9 = any(search_family(v, adj9, FULL9, N9, want_first=True)["status"] == "YES"
               for v in f9)
    gate("1b", got8 and not got9,
         f"omega(C9vC9vC5)=8: 8-clique exists={got8}, 9-clique exists={got9} "
         f"(expected True/False)")

    # ---- GATE-2: FIND a 16-clique of the (3,1) cell G = C9^v3 v C5 ----
    N3, coords3, adj3, FULL3 = build_H(9, 3)
    f16 = families(16, cap=8)           # omega(H)=8
    found16 = None
    for vec in f16:
        r = search_family(vec, adj3, FULL3, N3, want_first=True)
        if r["status"] == "YES":
            found16 = (vec, r); break
    if found16:
        vec, r = found16
        tup = witness_to_tuples(r["witness"], coords3)
        okv, det = verify_G_clique(tup, 9, 3)
        # layer sizes of witness
        lay = tuple(len(vs) for (_, vs) in sorted(r["witness"]))
        gate("2", len(tup) == 16 and okv,
             f"omega(C9^v3 v C5)>=16: found 16-clique family {vec}, "
             f"witness verify {det}")
    else:
        gate("2", False, "NO 16-clique found (expected YES)")

    print(f"\nGATES {'ALL PASS' if ok_all else 'FAILED'}", flush=True)
    return ok_all


# ---------------------------------------------------------------------------
# PROBE: capped per-family cost, rank cheapest-first
# ---------------------------------------------------------------------------
def run_probe(S, cap_anchors=40, maxsec_each=25):
    N, coords, adj, FULL = build_H(9, 3)
    fams = families(S, cap=8)
    print(f"S={S}: {len(fams)} families; probing (cap {cap_anchors} anchors / "
          f"{maxsec_each}s each)", flush=True)
    rows = []
    for i, vec in enumerate(fams):
        stats = [0, None]
        t0 = time.time()
        r = _probe_one(vec, adj, FULL, N, cap_anchors, maxsec_each, stats)
        dt = time.time() - t0
        rows.append((i, vec, r["status"], r["anchors_seen"], stats[0], dt, r["chain"]))
        print(f"  fam {i:02d} {vec} chain={r['chain']}: probe={r['status']} "
              f"anchors={r['anchors_seen']} nodes={stats[0]} {dt:.1f}s "
              f"({stats[0]/max(dt,0.001):.0f} nodes/s)", flush=True)
    # rank: decided-cheap first (NO fully exhausted within cap), then by nodes/sec cost
    print("\nRanked cheapest-first:", flush=True)
    def costkey(row):
        i, vec, st, seen, nodes, dt, chain = row
        if st == "YES":
            return (0, 0.0)                        # jackpot: do first
        if st == "NO":
            return (1, dt)                          # already decided in probe: trivial
        return (2, nodes / max(seen, 1))            # capped: cost ~ nodes per anchor
    ranked = sorted(rows, key=costkey)
    order = [r[0] for r in ranked]
    for i, vec, st, seen, nodes, dt, chain in ranked:
        per = nodes / max(seen, 1)
        print(f"  fam {i:02d} {vec}: {st} ~{per:.0f} nodes/anchor, "
              f"probe {dt:.1f}s", flush=True)
    print("\nSUGGESTED --order " + ",".join(str(i) for i in order), flush=True)
    return rows


def _probe_one(vec, adj, FULL, N, cap_anchors, maxsec, stats):
    """Cost probe: extend up to cap_anchors anchors under a maxsec deadline.
    Returns status NO (exhausted), YES (witness), or capped (hit cap/deadline)."""
    cs, cl = chain_from_vector(vec)
    m0 = cs[0]
    stats[1] = time.time() + maxsec
    anchor_stream = enum_size_cliques(adj[0], m0 - 1, adj, stats)
    seen = 0
    try:
        for tail in anchor_stream:
            if seen >= cap_anchors:
                return {"status": "capped", "anchors_seen": seen,
                        "anchor_total_est": -1, "chain": cs}
            seen += 1
            Q0 = [0] + list(bits(tail))
            nQ0 = neigh_of_clique(Q0, adj, FULL)
            res = _extend_chain(1, cs, cl, [Q0], [1 | tail], nQ0, nQ0, adj, FULL,
                                stats, True)
            if res is not None:
                return {"status": "YES", "anchors_seen": seen,
                        "anchor_total_est": seen, "chain": cs}
    except Deadline:
        return {"status": "capped", "anchors_seen": seen, "anchor_total_est": -1,
                "chain": cs}
    return {"status": "NO", "anchors_seen": seen, "anchor_total_est": seen,
            "chain": cs}


# ---------------------------------------------------------------------------
# RUN: full per-family search with resumable JSON
# ---------------------------------------------------------------------------
def load_result(fn):
    if os.path.exists(fn):
        try:
            with open(fn) as f:
                return json.load(f)
        except Exception:
            return None
    return None


def run_full(S, maxsec_total=9000, order=None, per_family_cap=1800):
    os.makedirs(RESULT_DIR, exist_ok=True)
    N, coords, adj, FULL = build_H(9, 3)
    fams = families(S, cap=8)
    if order is not None:
        fams = [fams[i] for i in order if i < len(fams)]
    t_global = time.time()
    for idx, vec in enumerate(fams):
        fam_no = families(S, cap=8).index(vec)
        fn = os.path.join(RESULT_DIR, f"family_{fam_no:02d}.json")
        prev = load_result(fn)
        if prev and prev.get("status") in ("NO", "YES"):
            print(f"[skip] family_{fam_no:02d} {vec} already {prev['status']}",
                  flush=True)
            if prev["status"] == "YES":
                print("!!! JACKPOT recorded in a prior run:", prev.get("witness"),
                      flush=True)
                return prev
            continue
        remaining = maxsec_total - (time.time() - t_global)
        if remaining <= 5:
            print(f"[time] global cap reached before family_{fam_no:02d}", flush=True)
            break
        start_anchor = prev.get("anchors_done", 0) if prev and prev.get("status") == "PARTIAL" else 0
        budget = min(remaining, per_family_cap)
        print(f"[run] family_{fam_no:02d} {vec} (resume@{start_anchor}) budget={budget:.0f}s",
              flush=True)
        stats = [0, None]
        t0 = time.time()
        r = search_family(vec, adj, FULL, N, want_first=True, maxsec=budget,
                          start_anchor=start_anchor, stats=stats)
        dt = time.time() - t0
        out = {"family": list(vec), "S": S, "status": r["status"],
               "witness": None, "nodes": r["nodes"],
               "anchors_done": r["anchors_done"],
               "anchors_total": r["anchors_total"],
               "wall_seconds": round(dt + (prev.get("wall_seconds", 0) if prev else 0), 2)}
        if r["status"] == "YES":
            tup = witness_to_tuples(r["witness"], coords)
            okv, det = verify_G_clique(tup, 9, 3)
            out["witness"] = [list(t) for t in tup]
            out["witness_verified"] = okv
            out["witness_detail"] = det
            with open(fn, "w") as f:
                json.dump(out, f, indent=1)
            print(f"!!! JACKPOT family_{fam_no:02d} {vec}: {S}-CLIQUE, verify {det}",
                  flush=True)
            print("STOP everything.", flush=True)
            return out
        with open(fn, "w") as f:
            json.dump(out, f, indent=1)
        print(f"[done] family_{fam_no:02d} {vec}: {r['status']} "
              f"anchors={r['anchors_done']}/{r['anchors_total']} nodes={r['nodes']} "
              f"{dt:.1f}s", flush=True)
    # summary
    print("\n=== RUN SUMMARY ===", flush=True)
    done = part = 0
    for fam_no, vec in enumerate(families(S, cap=8)):
        fn = os.path.join(RESULT_DIR, f"family_{fam_no:02d}.json")
        p = load_result(fn)
        st = p["status"] if p else "MISSING"
        if st in ("NO", "YES"):
            done += 1
        elif st == "PARTIAL":
            part += 1
        print(f"  family_{fam_no:02d} {vec}: {st}", flush=True)
    print(f"{done} decided, {part} partial, {len(families(S,cap=8))-done-part} untouched",
          flush=True)
    return None


# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gates", action="store_true")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--probe", type=int, metavar="S")
    ap.add_argument("--run", type=int, metavar="S")
    ap.add_argument("--maxsec", type=float, default=9000)
    ap.add_argument("--famcap", type=float, default=1800,
                    help="max seconds per family before checkpoint+move on")
    ap.add_argument("--family", type=str, help="a,b,c,d,e explicit vector on (9,3) cell")
    ap.add_argument("--order", type=str, help="comma list of family indices for --run")
    args = ap.parse_args()

    if args.selftest:
        ok = selftest()
        sys.exit(0 if ok else 1)
    if args.gates:
        ok = selftest() and run_gates()
        sys.exit(0 if ok else 1)
    if args.probe is not None:
        run_probe(args.probe)
        return
    if args.family:
        vec = tuple(int(x) for x in args.family.split(","))
        N, coords, adj, FULL = build_H(9, 3)
        stats = [0, None]
        t0 = time.time()
        r = search_family(vec, adj, FULL, N, want_first=True, maxsec=args.maxsec,
                          stats=stats)
        dt = time.time() - t0
        print(f"family {vec}: {r['status']} anchors={r['anchors_done']}/"
              f"{r['anchors_total']} nodes={stats[0]} {dt:.1f}s")
        if r["status"] == "YES":
            tup = witness_to_tuples(r["witness"], coords)
            okv, det = verify_G_clique(tup, 9, 3)
            print("witness verify:", det, "->", tup)
        return
    if args.run is not None:
        order = [int(x) for x in args.order.split(",")] if args.order else None
        run_full(args.run, maxsec_total=args.maxsec, order=order,
                 per_family_cap=args.famcap)
        return
    ap.print_help()


if __name__ == "__main__":
    main()
