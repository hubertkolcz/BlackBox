"""ERG-003 family 00 = (1,1,1,7,7) exhaustive decision by variable elimination.

A 17-clique of G = C9^v3 v C5 with layer sizes (1,1,1,7,7) is, by the
pentagram-layer principle, exactly a tuple (q0, q1, q2, Q3, Q4):
    Q_0={q0}, Q_1={q1}, Q_2={q2} single H-vertices, Q_3, Q_4 7-cliques of H,
pair constraints (i, i+2 mod 5):
    (0,2): q0 ~ q2 in H
    (1,3), (3,0): Q_3 subset N(q1) cap N(q0),  a 7-clique
    (2,4), (4,1): Q_4 subset N(q2) cap N(q1),  a 7-clique
Layers 3 and 4 are C5-adjacent: NO constraint between Q_3 and Q_4.  So they
eliminate into independent existence predicates:
    f(a, b) := exists 7-clique inside N(a) cap N(b)   (a=b allowed: N(a))
and family 00 has a 17-clique  <=>  exists q1, q0, q2 with q0~q2 and
    f(q1, q0) and f(q1, q2).
Translation transitivity pins q1 = 0 (translations are automorphisms of G
fixing the C5 layers).  The vertex-0 stabilizer (coordinate permutations S3 x
per-coordinate reflection, order 48) acts on the remaining u, so f(0, u) is
constant on stabilizer orbits: only orbit representatives need the (find-first
or exhaustive-NO) 7-clique test, run with the selftest-validated
coloring-bounded enumerator of erg003_pentagram_search.

Resumable: erg003_fam00_elim_state.json stores per-orbit results.
Final verdict written into erg003_family_results/family_00.json (method
'elimination') after an independent witness verification on YES.
"""
import itertools
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import erg003_pentagram_search as ps

STATE = os.path.join(HERE, "erg003_fam00_elim_state.json")
RESULT = os.path.join(ps.RESULT_DIR, "family_00.json")
BUDGET = float(sys.argv[1]) if len(sys.argv) > 1 else 540.0


def stab0_orbits(N, coords, n=9, k=3):
    """Orbits of V(H) under Stab(0) = S_k (coord perms) x {x -> -x}^k."""
    perms = list(itertools.permutations(range(k)))
    signs = list(itertools.product((1, -1), repeat=k))
    orbit_of = [-1] * N
    reps = []
    for v in range(N):
        if orbit_of[v] >= 0:
            continue
        rep = len(reps)
        reps.append(v)
        stack = [v]
        orbit_of[v] = rep
        while stack:
            u = stack.pop()
            cu = coords[u]
            for p in perms:
                for s in signs:
                    cw = tuple((s[t] * cu[p[t]]) % n for t in range(k))
                    w = 0
                    for x in cw:
                        w = w * n + x
                    if orbit_of[w] < 0:
                        orbit_of[w] = rep
                        stack.append(w)
    return reps, orbit_of


def main():
    N, coords, adj, FULL = ps.build_H(9, 3)
    reps, orbit_of = stab0_orbits(N, coords)
    print(f"[fam00] {len(reps)} Stab(0)-orbits over {N} vertices", flush=True)

    state = {}
    if os.path.exists(STATE):
        with open(STATE) as f:
            state = json.load(f)

    deadline = time.time() + BUDGET
    total_nodes = int(state.get("_nodes", 0))
    t0 = time.time()
    for ri, rep in enumerate(reps):
        key = str(rep)
        if key in state:
            continue
        if time.time() > deadline:
            print(f"[fam00] budget hit at orbit {ri}/{len(reps)}", flush=True)
            break
        cand = adj[0] & adj[rep] if rep != 0 else adj[0]
        stats = [0, None]
        t1 = time.time()
        found = None
        for m in ps.enum_size_cliques(cand, 7, adj, stats):
            found = m
            break
        total_nodes += stats[0]
        state[key] = {"f": bool(found), "nodes": stats[0],
                      "wall": round(time.time() - t1, 3),
                      "witness_mask_hex": format(found, "x") if found else None,
                      "cand_size": cand.bit_count()}
        state["_nodes"] = total_nodes
        with open(STATE, "w") as f:
            json.dump(state, f)
        print(f"  orbit {ri:02d} rep={rep} {coords[rep]} cand="
              f"{cand.bit_count()} f={bool(found)} nodes={stats[0]} "
              f"{time.time()-t1:.2f}s", flush=True)

    done = all(str(r) in state for r in reps)
    if not done:
        print(f"[fam00] PARTIAL: {sum(1 for r in reps if str(r) in state)}"
              f"/{len(reps)} orbits decided, resumable", flush=True)
        return

    # assemble f over all vertices, then search for an H-edge (q0, q2)
    # with f(q0) and f(q2)   (f(u) := f(0,u), q1 pinned to 0)
    fvec = [state[str(reps[orbit_of[u]])]["f"] for u in range(N)]
    good = [u for u in range(N) if fvec[u]]
    print(f"[fam00] vertices u with 7-clique in N(0) cap N(u): {len(good)}"
          f"/{N}", flush=True)
    pair = None
    for q0 in good:
        a0 = adj[q0]
        for q2 in good:
            if q2 > q0 and ((a0 >> q2) & 1):
                pair = (q0, q2)
                break
        if pair:
            break

    out = {"family": [1, 1, 1, 7, 7], "S": 17, "method": "elimination",
           "pin": "q1=0 (translation)", "orbits": len(reps),
           "nodes": total_nodes,
           "wall_seconds": round(time.time() - t0, 1),
           "good_vertex_count": len(good), "witness": None}
    if pair is None:
        out["status"] = "NO"
        print("[fam00] VERDICT: NO 17-clique in family (1,1,1,7,7) -- "
              "EXHAUSTED", flush=True)
    else:
        q0, q2 = pair
        m3 = int(state[str(reps[orbit_of[q0]])]["witness_mask_hex"], 16)
        m4 = int(state[str(reps[orbit_of[q2]])]["witness_mask_hex"], 16)
        # orbit witness is for the REP, not u itself: recompute for exact u
        s3 = [0, None]
        m3 = next(ps.enum_size_cliques(adj[0] & adj[q0], 7, adj, s3))
        m4 = next(ps.enum_size_cliques(adj[0] & adj[q2], 7, adj, s3))
        witness = [(0, [q0]), (1, [0]), (2, [q2]),
                   (3, sorted(ps.bits(m3))), (4, sorted(ps.bits(m4)))]
        tup = ps.witness_to_tuples(witness, coords)
        okv, det = ps.verify_G_clique(tup, 9, 3)
        out["status"] = "YES" if okv else "VERIFY-FAIL"
        out["witness"] = [list(t) for t in tup]
        out["witness_verified"] = okv
        out["witness_detail"] = det
        print(f"!!! JACKPOT fam00: 17-clique, verify {det}", flush=True)
    with open(RESULT, "w") as f:
        json.dump(out, f, indent=1)
    print("[fam00] wrote family_00.json", flush=True)


if __name__ == "__main__":
    main()
