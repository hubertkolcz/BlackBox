"""ERG-003 rigid-pair exhaustive family decider.

Same problem as erg003_pentagram_search.py (S-cliques of G = H v C5,
H = C_n^vk conormal power, via the pentagram-layer principle), but anchored on
the RIGIDITY of large pentagram-pair unions instead of raw clique enumeration:

  L1 (verified in erg003_rigor_lemmas.py, SAT-UNSAT + vertex transitivity):
      every omega-clique of H (omega = 2^k) is an edge-product (one C_n edge
      per factor, n^k of them).
  L2 (same file): every (omega-1)-clique of H extends to an omega-clique,
      hence lies inside an edge-product.

A pentagram pair (Q_i, Q_{i+2}) with |Q_i|+|Q_{i+2}| = omega unions to an
omega-clique of H  =>  the union IS one of the n^k products and (Q_i, Q_{i+2})
is one of its C(omega,|Q_i|) ordered splits.  With sum omega-1 the union is a
7-clique => (L2) a (omega-1)-subset of a product.  Anchoring a family on such
a pair replaces the million-node enumeration wall with <= n^k * C(omega, s)
cheap anchors; later chain edges with sum >= omega-1 collapse the same way
(products containing a nonempty clique are <= 2^k, found by mask containment).
Chain edges with smaller sums use the original coloring-bounded enumerator on
the (now tiny) common-neighborhood candidate sets.

No symmetry quotient is taken anywhere: the anchor ranges over ALL products
and ALL splits, so a NO is a full exhaustion of the family.  Deterministic.

CLI:
  --gates          validation battery against ground truths of the chain
                   searcher (must have erg003_lemma_results.json first):
                     RGA cross-check vs search_family on ALL C7^v2 S=8 families
                     RG1 C7^v2 +C5: S=9 YES reproduced, S=10 all NO
                     RG2 C9^v2 +C5: S=8 YES reproduced, S=9 all NO (=gate-1b)
                     RG3 C9^v3 +C5: S=16 YES with independently verified witness
  --run17          decide all 26 S=17 families of the (9,3) cell
  --fams i,j,...   restrict --run17 to these family indices
  --maxsec T       per-family budget (default 540; PARTIAL + resumable)
Result files: erg003_family_results/family_NN_rigid.json
"""
import argparse
import itertools
import json
import math
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
RESULT_DIR = os.path.join(HERE, "erg003_family_results")
sys.path.insert(0, HERE)
import erg003_pentagram_search as ps  # noqa: E402


# ---------------------------------------------------------------------------
def products(n, k):
    """All edge-product cliques of C_n^vk: (vertex tuple sorted, bitmask)."""
    out = []
    for starts in itertools.product(range(n), repeat=k):
        vs = []
        for deltas in itertools.product((0, 1), repeat=k):
            idx = 0
            for t in range(k):
                idx = idx * n + ((starts[t] + deltas[t]) % n)
            vs.append(idx)
        vs = tuple(sorted(vs))
        m = 0
        for v in vs:
            m |= 1 << v
        out.append((vs, m))
    return out


def popcount(x):
    return x.bit_count()


# ---------------------------------------------------------------------------
# traversal choice: rotate/reflect the pentagram cycle so the anchor edge
# (chain positions 0,1) has pair-sum omega (rigid) or omega-1 (L2), and the
# estimated downstream cost is minimal.
# ---------------------------------------------------------------------------
def traversals(vec):
    base = ps.PENT[:]
    sizes = [vec[l] for l in base]
    for direction in (1, -1):
        L = base[::direction]
        Sz = sizes[::direction]
        for start in range(5):
            cl = [L[(start + j) % 5] for j in range(5)]
            cs = [Sz[(start + j) % 5] for j in range(5)]
            yield cs, cl


def edge_kind(a, b, omega, l2ok):
    s = a + b
    if s == omega:
        return "rigid"
    if s == omega - 1 and l2ok:
        return "sub"
    return "enum"


def score_traversal(cs, cl, omega, l2ok, nprod, nH):
    s01 = cs[0] + cs[1]
    if s01 == omega:
        anchors = nprod * math.comb(omega, cs[0])
    elif s01 == omega - 1 and l2ok:
        anchors = nprod * omega * math.comb(omega - 1, cs[0])
    else:
        return None
    inner = 1.0
    pinned = cs[0] + cs[1]
    for j in range(2, 5):
        if cs[j] == 0:
            continue
        kind = edge_kind(cs[j - 1], cs[j], omega, l2ok)
        if kind == "rigid":
            inner += 2 ** 3
        elif kind == "sub":
            inner += 2 ** 4
        else:
            # candidate ~ nH * density^pred, enum cost ~ cand^size crude
            pred = cs[j - 1] if j < 4 else cs[j - 1] + cs[0]
            cand = nH * (0.53 ** max(pred, 1))
            inner += cand ** min(cs[j], 4)
        pinned += cs[j]
    return anchors * inner


def pick_traversal(vec, omega, l2ok, nprod, nH):
    best = None
    for cs, cl in traversals(vec):
        sc = score_traversal(cs, cl, omega, l2ok, nprod, nH)
        if sc is None:
            continue
        if best is None or sc < best[0]:
            best = (sc, cs, cl)
    if best is None:
        return None
    return best[1], best[2]


# ---------------------------------------------------------------------------
# per-family exhaustive decision
# ---------------------------------------------------------------------------
class FamilyRun:
    def __init__(self, n, k, adj, N, FULL, prods, l2ok):
        self.n, self.k = n, k
        self.adj, self.N, self.FULL = adj, N, FULL
        self.prods = prods
        self.l2ok = l2ok
        self.omega = 2 ** k

    def prods_containing(self, qmask):
        return [(vs, m) for (vs, m) in self.prods if (m & qmask) == qmask]

    def decide(self, vec, maxsec=None, start_anchor=0, want_first=True):
        adj, FULL, omega = self.adj, self.FULL, self.omega
        pick = pick_traversal(vec, omega, self.l2ok, len(self.prods), self.N)
        if pick is None:
            return {"status": "UNSUPPORTED", "reason": "no anchorable pair",
                    "nodes": 0, "anchors_done": 0, "anchors_total": 0}
        cs, cl = pick
        stats = [0, None]
        stats[1] = (time.time() + maxsec) if maxsec is not None else None
        s01 = cs[0] + cs[1]

        # ---- anchor stream: (Q0mask, Q1mask) pairs, deterministic order ----
        def anchor_stream():
            if s01 == omega:
                for (vs, m) in self.prods:
                    for combo in itertools.combinations(vs, cs[0]):
                        q0 = 0
                        for v in combo:
                            q0 |= 1 << v
                        yield q0, m ^ q0
            else:  # omega-1 (L2): 7-subset of a product, then split
                for (vs, m) in self.prods:
                    for drop in vs:
                        rest = tuple(v for v in vs if v != drop)
                        for combo in itertools.combinations(rest, cs[0]):
                            q0 = 0
                            for v in combo:
                                q0 |= 1 << v
                            q1 = 0
                            for v in rest:
                                q1 |= 1 << v
                            yield q0, q1 ^ q0

        ai = -1
        witness = None
        try:
            for q0, q1 in anchor_stream():
                ai += 1
                if ai < start_anchor:
                    continue
                stats[0] += 1
                if stats[1] is not None and (stats[0] & 0xFFF) == 0 \
                        and time.time() > stats[1]:
                    raise ps.Deadline
                w = self._extend(2, cs, cl, [q0, q1], stats)
                if w is not None:
                    witness = w
                    break
        except ps.Deadline:
            return {"status": "PARTIAL", "witness": None, "nodes": stats[0],
                    "anchors_done": max(ai, 0), "anchors_total": -1,
                    "chain_sizes": cs, "chain_layers": cl}
        out = {"status": "YES" if witness else "NO", "nodes": stats[0],
               "anchors_done": ai + 1, "anchors_total": ai + 1,
               "chain_sizes": cs, "chain_layers": cl, "witness": None}
        if witness:
            out["witness"] = [(cl[i], sorted(ps.bits(witness[i])))
                              for i in range(5)]
        return out

    def _extend(self, j, cs, cl, qmasks, stats):
        """Place chain layer j (2..4). qmasks: chosen layer bitmasks so far.
        Returns list of 5 masks on success else None."""
        adj, FULL = self.adj, self.FULL
        if j == 5:
            return qmasks
        need = cs[j]
        prevmask = qmasks[j - 1]
        # candidate set from sequential pair constraint (+ closing at j=4)
        cand = FULL
        for v in ps.bits(prevmask):
            cand &= adj[v]
        if j == 4:
            for v in ps.bits(qmasks[0]):
                cand &= adj[v]
        if need == 0:
            return self._extend(j + 1, cs, cl, qmasks + [0], stats)

        kind = edge_kind(cs[j - 1], need, self.omega, self.l2ok)
        if j == 4 and kind == "enum":
            # closing edge may be the rigid one instead
            k2 = edge_kind(cs[0], need, self.omega, self.l2ok)
            if k2 != "enum":
                kind, prevmask = k2, qmasks[0]

        if kind == "rigid":
            for (vs, m) in self.prods_containing(prevmask):
                qj = m ^ prevmask
                stats[0] += 1
                if popcount(qj) == need and (qj & cand) == qj:
                    w = self._extend(j + 1, cs, cl, qmasks + [qj], stats)
                    if w is not None:
                        return w
            return None
        if kind == "sub":
            seen = set()
            for (vs, m) in self.prods_containing(prevmask):
                avail = [v for v in vs if not ((prevmask >> v) & 1)
                         and ((cand >> v) & 1)]
                for combo in itertools.combinations(avail, need):
                    qj = 0
                    for v in combo:
                        qj |= 1 << v
                    if qj in seen:
                        continue
                    seen.add(qj)
                    stats[0] += 1
                    w = self._extend(j + 1, cs, cl, qmasks + [qj], stats)
                    if w is not None:
                        return w
            return None
        # plain enumeration on the (small) candidate set
        for qj in ps.enum_size_cliques(cand, need, adj, stats):
            w = self._extend(j + 1, cs, cl, qmasks + [qj], stats)
            if w is not None:
                return w
        return None


# ---------------------------------------------------------------------------
def build_cell(n, k, l2ok):
    N, coords, adj, FULL = ps.build_H(n, k)
    prods = products(n, k)
    return FamilyRun(n, k, adj, N, FULL, prods, l2ok), coords


def decide_S(fr, coords, S, verbose=True, maxsec_each=None, only=None):
    """Decide every family of target S on cell fr. Returns list of rows."""
    omega = fr.omega
    fams = ps.families(S, cap=omega)
    rows = []
    for i, vec in enumerate(fams):
        if only is not None and i not in only:
            continue
        t0 = time.time()
        r = fr.decide(vec, maxsec=maxsec_each)
        dt = time.time() - t0
        row = {"idx": i, "vec": list(vec), "status": r["status"],
               "nodes": r["nodes"], "anchors": r["anchors_done"],
               "wall": round(dt, 2)}
        if r["status"] == "YES":
            tup = ps.witness_to_tuples(r["witness"], coords)
            okv, det = ps.verify_G_clique(tup, fr.n, fr.k)
            row["witness"] = [list(t) for t in tup]
            row["witness_verified"] = okv
            row["witness_detail"] = det
        rows.append(row)
        if verbose:
            print(f"  fam {i:02d} {vec}: {r['status']} nodes={r['nodes']} "
                  f"anchors={r['anchors_done']} {dt:.1f}s"
                  + (f" verify={row.get('witness_detail','')}"
                     if r["status"] == "YES" else ""), flush=True)
    return rows


# ---------------------------------------------------------------------------
def load_lemmas():
    fn = os.path.join(HERE, "erg003_lemma_results.json")
    if not os.path.exists(fn):
        print("MISSING erg003_lemma_results.json -- run erg003_rigor_lemmas.py",
              flush=True)
        sys.exit(2)
    with open(fn) as f:
        return json.load(f)


def lemma_ok_small(lem, cell):
    c = lem.get(cell, {})
    return (c.get("all_max_cliques_are_products") is True,
            c.get("num_submax_cliques_outside_products") == 0)


def run_gates():
    lem = load_lemmas()
    ok_all = True

    def gate(label, cond, detail):
        nonlocal ok_all
        st = "PASS" if cond else "FAIL"
        if not cond:
            ok_all = False
        print(f"RIGID-GATE {label}: {st} -- {detail}", flush=True)

    # lemma preconditions
    l1_7, l2_7 = lemma_ok_small(lem, "C7^v2")
    l1_9, l2_9 = lemma_ok_small(lem, "C9^v2")
    big = lem.get("C9^v3", {})
    l0_big = big.get("L0_no_9clique_status") == "UNSAT"
    l1_big = big.get("L1_nonproduct_8clique_status") == "UNSAT"
    l2_big = big.get("L2_nonextendable_7clique_status") == "UNSAT"
    gate("L", l1_7 and l1_9 and l0_big and l1_big,
         f"lemmas: C7v2 products={l1_7},{l2_7} C9v2 products={l1_9},{l2_9} "
         f"C9v3 L0={l0_big} L1={l1_big} L2={l2_big}")

    # RGA: cross-check statuses vs the chain searcher on C7^v2, S=8 families
    fr7, coords7 = build_cell(7, 2, l2_7)
    N7, c7, adj7, F7 = ps.build_H(7, 2)
    agree = True
    detail = []
    for S in (8, 9):
        for vec in ps.families(S, cap=4):
            a = fr7.decide(vec)["status"]
            b = ps.search_family(vec, adj7, F7, N7, want_first=True)["status"]
            if {a, b} not in ({"YES"}, {"NO"}) and a != b:
                if not (a == "UNSUPPORTED"):
                    agree = False
                    detail.append(f"{S}:{vec}:{a} vs {b}")
                else:
                    b2 = b  # chain decided; rigid could not anchor: not a bug
                    detail.append(f"{S}:{vec}: rigid UNSUPPORTED (chain {b2})")
    gate("A", agree, "C7^v2 S=8,9 per-family status agreement with chain "
         f"searcher; notes: {detail if detail else 'exact agreement'}")

    # RG1: C7 cell: S=9 has a YES (gate-1a), S=10 all NO (omega=9)
    r9 = decide_S(fr7, coords7, 9, verbose=False)
    got9 = any(r["status"] == "YES" and r.get("witness_verified") for r in r9)
    r10 = decide_S(fr7, coords7, 10, verbose=False)
    bad10 = [r for r in r10 if r["status"] not in ("NO", "UNSUPPORTED")]
    unsup10 = [r for r in r10 if r["status"] == "UNSUPPORTED"]
    gate("1", got9 and not bad10 and not unsup10,
         f"C7vC7vC5: 9-clique found+verified={got9}; S=10: "
         f"{len([r for r in r10 if r['status']=='NO'])}/{len(r10)} NO, "
         f"{len(unsup10)} unsupported")

    # RG2: C9^v2 cell: S=8 YES, S=9 all NO (must match exhaustive gate-1b)
    fr9, coords9 = build_cell(9, 2, l2_9)
    r8 = decide_S(fr9, coords9, 8, verbose=False)
    got8 = any(r["status"] == "YES" and r.get("witness_verified") for r in r8)
    r9b = decide_S(fr9, coords9, 9, verbose=False)
    bad9 = [r for r in r9b if r["status"] not in ("NO", "UNSUPPORTED")]
    unsup9 = [r for r in r9b if r["status"] == "UNSUPPORTED"]
    gate("2", got8 and not bad9 and not unsup9,
         f"C9vC9vC5: 8-clique found+verified={got8}; S=9: "
         f"{len([r for r in r9b if r['status']=='NO'])}/{len(r9b)} NO, "
         f"{len(unsup9)} unsupported")

    # RG3: C9^v3 cell: S=16 YES with verified witness
    fr3, coords3 = build_cell(9, 3, l2_big)
    f16 = ps.families(16, cap=8)
    got16 = False
    det16 = "none"
    for i, vec in enumerate(f16):
        r = fr3.decide(vec, maxsec=120)
        if r["status"] == "YES":
            tup = ps.witness_to_tuples(r["witness"], coords3)
            okv, det = ps.verify_G_clique(tup, 9, 3)
            got16 = okv
            det16 = f"family {vec}: {det}"
            break
    gate("3", got16, f"C9^v3 v C5: 16-clique {det16}")

    print(f"\nRIGID GATES {'ALL PASS' if ok_all else 'FAILED'}", flush=True)
    return ok_all


def run17(only=None, maxsec=540):
    lem = load_lemmas()
    big = lem.get("C9^v3", {})
    if not (big.get("L0_no_9clique_status") == "UNSAT"
            and big.get("L1_nonproduct_8clique_status") == "UNSAT"):
        print("L0/L1 not verified UNSAT -- refusing to run", flush=True)
        sys.exit(2)
    l2ok = big.get("L2_nonextendable_7clique_status") == "UNSAT"
    fr, coords = build_cell(9, 3, l2ok)
    os.makedirs(RESULT_DIR, exist_ok=True)
    fams = ps.families(17, cap=8)
    for i, vec in enumerate(fams):
        if only is not None and i not in only:
            continue
        fn = os.path.join(RESULT_DIR, f"family_{i:02d}_rigid.json")
        prev = None
        if os.path.exists(fn):
            with open(fn) as f:
                prev = json.load(f)
            if prev.get("status") in ("NO", "YES"):
                print(f"[skip] fam {i:02d} {vec} already {prev['status']}",
                      flush=True)
                continue
        start = prev.get("anchors_done", 0) if prev else 0
        t0 = time.time()
        r = fr.decide(vec, maxsec=maxsec, start_anchor=start)
        dt = time.time() - t0
        out = {"family": list(vec), "S": 17, "method": "rigid-pair",
               "status": r["status"], "nodes": r["nodes"],
               "anchors_done": r["anchors_done"],
               "anchors_total": r["anchors_total"],
               "chain_sizes": r.get("chain_sizes"),
               "chain_layers": r.get("chain_layers"),
               "l2_shortcuts_enabled": l2ok,
               "wall_seconds": round(dt + (prev.get("wall_seconds", 0)
                                           if prev else 0), 2),
               "witness": None}
        if r["status"] == "YES":
            tup = ps.witness_to_tuples(r["witness"], coords)
            okv, det = ps.verify_G_clique(tup, 9, 3)
            out["witness"] = [list(t) for t in tup]
            out["witness_verified"] = okv
            out["witness_detail"] = det
            with open(fn, "w") as f:
                json.dump(out, f, indent=1)
            print(f"!!! JACKPOT fam {i:02d} {vec}: 17-CLIQUE, verify {det}",
                  flush=True)
            return
        with open(fn, "w") as f:
            json.dump(out, f, indent=1)
        print(f"[done] fam {i:02d} {vec}: {r['status']} nodes={r['nodes']} "
              f"anchors={r['anchors_done']}/{r['anchors_total']} {dt:.1f}s",
              flush=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gates", action="store_true")
    ap.add_argument("--run17", action="store_true")
    ap.add_argument("--fams", type=str)
    ap.add_argument("--maxsec", type=float, default=540)
    args = ap.parse_args()
    if args.gates:
        ok = run_gates()
        sys.exit(0 if ok else 1)
    if args.run17:
        only = set(int(x) for x in args.fams.split(",")) if args.fams else None
        run17(only=only, maxsec=args.maxsec)
        return
    ap.print_help()


if __name__ == "__main__":
    main()
