# Symmetry-breaking-augmented SAT encoding for ERG-003 per-family clique decision.
# Adds two sound reductions on top of erg003_sat.build_cnf:
#   (a) translation SBP: unit clause pinning vertex 0 = (0,0,0,0) TRUE. Sound iff
#       family[0] >= 1 (A0 = Z9^3 x {0} acts freely/transitively on layer-0 vertices
#       and preserves the family profile since it never touches the C5 coordinate).
#   (b) point-group SBP: lex-leader clauses for each of G0's 6 generators (CGLR
#       generator-only lex-leader -- sound, not complete, applied independently not
#       composed).
# See design doc (prior-agent spec) for the full derivation/soundness argument.
import sys, os, itertools, contextlib
sys.path.insert(0, '.')
import erg003_helper as H
import erg003_lasserre as L
from erg003_sat import build_cnf
from pysat.formula import CNF
from pysat.card import CardEnc, EncType
from pysat.solvers import Cadical153


def var(p):
    return p + 1  # SAT variable of vertex-index p -- must match erg003_sat.py's var(v)=v+1


# --- convention (be explicit, per task instructions) ---------------------------------
# perm is a permutation array on vertex indices: perm[p] = index that vertex p maps to
# under the automorphism (this is exactly _g0_generators()'s output convention). For a
# position p in the lex bit-vector (bit p = value of var(p)), we compare it against
# bit "perm[p]" of the SAME assignment, i.e.
#     a_p := literal of var(p)          (bit p of x)
#     b_p := literal of var(perm[p])    (bit p of the "g(x)" vector being compared against)
# This is the exact b_p definition from the design spec. (Using perm vs. perm^-1 here is
# immaterial for CGLR soundness -- either is some element of the same generated group, and
# the lex-leader argument only needs "b" to be x transformed by *some* group element.)
def lex_leader_clauses(perm, fixed_vertex, top_id):
    assert perm[fixed_vertex] == fixed_vertex, "fixed_vertex must be a fixed point of perm"
    n = len(perm)
    positions = [p for p in range(n) if p != fixed_vertex]  # fixed_vertex ties trivially
    # (a_fixed == b_fixed identically, since perm[fixed_vertex]==fixed_vertex) --
    # already pinned TRUE by the unit clause, so excluding it from the lex chain is
    # sound: comparing the length-(n-1) subsequence is lex-equivalent to comparing the
    # full length-n sequence given that first position is a guaranteed tie.
    clauses = []
    top = top_id
    eq = []  # eq[i] = aux var "positions[0..i] agree"

    p0 = positions[0]
    a0, b0 = var(p0), var(perm[p0])
    top += 1
    Eq0 = top
    eq.append(Eq0)
    clauses += [
        [-a0, b0],
        [-Eq0, -a0, b0],
        [-Eq0, a0, -b0],
        [Eq0, a0, b0],
        [Eq0, -a0, -b0],
    ]
    m = len(positions)
    for i in range(1, m):
        p = positions[i]
        ap, bp = var(p), var(perm[p])
        Eqprev = eq[i - 1]
        if i < m - 1:
            top += 1
            Eqp = top
            eq.append(Eqp)
            clauses += [
                [-Eqprev, -ap, bp],
                [-Eqp, Eqprev],
                [-Eqp, -ap, bp],
                [-Eqp, ap, -bp],
                [Eqp, -Eqprev, ap, bp],
                [Eqp, -Eqprev, -ap, -bp],
            ]
        else:
            clauses.append([-Eqprev, -ap, bp])
    return clauses, top


# A generator P is only a symmetry of a SPECIFIC family's CNF (cardinality constraints
# included) if its induced action on layer indices leaves the family vector invariant --
# NOT just whether it fixes the pinned vertex. This is a real, independent precondition
# missed by "P[0]==0 for all 6 generators": 5 of the 6 generators (neg on coords 0-2,
# both S3 permutations) fix every layer POINTWISE (never touch the layer coordinate) so
# they trivially preserve any family. But neg(3) maps layer c -> (-c) mod 5, i.e. swaps
# layers 1<->4 and 2<->3 (fixing layer 0) -- it is a graph automorphism but only a
# symmetry of THIS family's CNF when family[1]==family[4] and family[2]==family[3].
# Caught empirically by tier2_small_graph_test's disagreement on an asymmetric family
# (ground truth SAT, but naively adding all generators' lex-leader clauses gave UNSAT).
# family0=[1,1,1,7,7]: family[1]=1 != family[4]=7 -> neg(3) must be EXCLUDED.
# family11=[1,3,5,5,3]: family[1]=3==family[4]=3, family[2]=5==family[3]=5 -> neg(3) OK.
def _generator_preserves_family(P, layer_reps, layer_of, family):
    k = len(family)
    sigma = [layer_of[P[layer_reps[c]]] for c in range(k)]
    return all(family[c] == family[sigma[c]] for c in range(k))


def build_symmetric_cnf(family):
    assert family[0] >= 1, (
        "translation pin (x_1=TRUE) is only sound when family[0]>=1 -- see design doc; "
        "for family[0]==0 use the generalized layer-c* pin instead (not implemented here)")
    cnf, build_s = build_cnf(family)
    cnf.append([1])  # vertex 0 = (0,0,0,0), SAT var 1, forced TRUE
    top = cnf.nv
    gens = L._g0_generators()
    layer_of = [v[3] for v in H.verts]
    layer_reps = [H.idx[(0, 0, 0, c)] for c in range(5)]
    skipped = []
    for gi, P in enumerate(gens):
        assert P[0] == 0  # required precondition for pinning fixed_vertex=0 below
        if not _generator_preserves_family(P, layer_reps, layer_of, family):
            skipped.append(gi)
            continue
        clauses, top = lex_leader_clauses(P, 0, top)
        cnf.extend(clauses)
    info = {"build_seconds": build_s, "vars": cnf.nv, "clauses": len(cnf.clauses),
            "generators_used": len(gens) - len(skipped), "generators_skipped": skipped}
    return cnf, top, info


# =======================================================================================
# Self-test (soundness verification plan, Tiers 1 & 2 -- Tier 0 real-scale runs deferred
# to a later phase per task instructions). Actually executes; prints PASS/FAIL.
# =======================================================================================

@contextlib.contextmanager
def _quiet_native_stdout():
    # Cadical153 (native C library) writes diagnostic lines like "found falsified
    # original clause" straight to fd 1 on trivially-UNSAT bootstrap CNFs -- harmless,
    # but drowns out the PASS/FAIL summary across thousands of tiny solves in tier1/2.
    fd = sys.stdout.fileno()
    saved = os.dup(fd)
    devnull = os.open(os.devnull, os.O_WRONLY)
    sys.stdout.flush()
    os.dup2(devnull, fd)
    try:
        yield
    finally:
        sys.stdout.flush()
        os.dup2(saved, fd)
        os.close(devnull)
        os.close(saved)


def _brute_force_lex(a, perm, fixed_vertex):
    positions = [p for p in range(len(perm)) if p != fixed_vertex]
    lhs = [a[p] for p in positions]
    rhs = [a[perm[p]] for p in positions]
    return lhs <= rhs


def _sat_check_lex(a, perm, fixed_vertex, n):
    clauses, top = lex_leader_clauses(perm, fixed_vertex, n)
    units = [[var(p) if a[p] else -var(p)] for p in range(n)]
    with _quiet_native_stdout(), Cadical153(bootstrap_with=clauses + units) as s:
        return s.solve()


def tier1_lex_leader_unit_test():
    print("--- Tier 1: lex_leader_clauses standalone logic test ---", flush=True)
    n = 10
    rng_perm_mixed = [0, 3, 4, 1, 2, 6, 7, 8, 9, 5]     # fixes 0, mixed 3-cycle + 6-cycle
    rng_perm_random = [0, 5, 7, 2, 9, 1, 3, 8, 6, 4]    # fixes 0, "random"-looking rest
    identity = list(range(n))
    swap_1_2 = [0, 2, 1, 3, 4, 5, 6, 7, 8, 9]           # fixes 0, transposition
    test_perms = {
        "identity": identity,
        "swap_1_2": swap_1_2,
        "mixed_cycles": rng_perm_mixed,
        "randomish": rng_perm_random,
    }
    for name, perm in test_perms.items():
        assert sorted(perm) == list(range(n)), f"{name}: not a valid permutation"
        assert perm[0] == 0, f"{name}: must fix position 0 (matches real generator property)"
        mismatches = 0
        for bits in itertools.product([0, 1], repeat=n):
            a = list(bits)
            truth = _brute_force_lex(a, perm, 0)
            got = _sat_check_lex(a, perm, 0, n)
            if truth != got:
                mismatches += 1
                if mismatches <= 3:
                    print(f"    MISMATCH perm={name} a={a} truth={truth} sat_encoding={got}", flush=True)
        status = "PASS" if mismatches == 0 else "FAIL"
        print(f"  [{status}] perm={name}: {2**n} assignments checked, {mismatches} mismatches", flush=True)
        if mismatches:
            return False
    return True


# --- Tier 2: small synthetic Cayley graph Z4^3 x Z3 (|V|=192), same construction shape --
_DIMS = (4, 4, 4, 3)


def _small_verts_idx():
    verts = list(itertools.product(*[range(d) for d in _DIMS]))
    idx = {v: i for i, v in enumerate(verts)}
    return verts, idx


def _small_adjbits(verts):
    N = len(verts)
    def adjG(u, v):
        if u == v:
            return False
        for t in range(3):
            if (u[t] - v[t]) % _DIMS[t] in (1, _DIMS[t] - 1):
                return True
        return (u[3] - v[3]) % _DIMS[3] in (1, _DIMS[3] - 1)
    bits = [0] * N
    for i in range(N):
        m = 0
        for j in range(N):
            if adjG(verts[i], verts[j]):
                m |= (1 << j)
        bits[i] = m
    return bits


def _small_g0_generators(verts, idx):
    def neg(c):
        return lambda e: tuple(v if k != c else (-v) % _DIMS[c] for k, v in enumerate(e))
    def prm(p):
        return lambda e: (e[p[0]], e[p[1]], e[p[2]], e[3])
    gens = [neg(0), neg(1), neg(2), neg(3), prm((1, 0, 2)), prm((1, 2, 0))]
    return [tuple(idx[g(e)] for e in verts) for g in gens]


def _bitlist(m):
    r, i = [], 0
    while m:
        if m & 1:
            r.append(i)
        m >>= 1
        i += 1
    return r


def _build_cnf_small(N, adjbits, layer_of, family, k):
    cnf = CNF()
    full = (1 << N) - 1
    for u in range(N):
        nonadj_mask = full & ~adjbits[u] & ~(1 << u)
        m = nonadj_mask >> (u + 1) << (u + 1)
        for v in _bitlist(m):
            cnf.append([-(u + 1), -(v + 1)])
    layers = {c: [v for v in range(N) if layer_of[v] == c] for c in range(k)}
    top = N
    for c in range(k):
        lits = [v + 1 for v in layers[c]]
        enc = CardEnc.equals(lits=lits, bound=family[c], top_id=top, encoding=EncType.seqcounter)
        cnf.extend(enc.clauses)
        top = max([abs(l) for cl in enc.clauses for l in cl] + [top])
    return cnf


def _verify_small(clique, adjbits):
    cl = list(dict.fromkeys(clique))
    if len(cl) != len(clique):
        return False
    for i, a in enumerate(cl):
        for b in cl[i + 1:]:
            if not (adjbits[a] >> b) & 1:
                return False
    return True


def _brute_force_clique_exists(N, adjbits, layer_of, family):
    S = sum(family)
    full = (1 << N) - 1
    best = [False]
    def rec(cand_mask, chosen, counts):
        if best[0]:
            return
        if chosen == S:
            if counts == family:
                best[0] = True
            return
        if cand_mask == 0:
            return
        if bin(cand_mask).count("1") < S - chosen:
            return
        v = (cand_mask & -cand_mask).bit_length() - 1
        rest = cand_mask & ~(1 << v)
        lv = layer_of[v]
        if counts[lv] < family[lv]:
            counts[lv] += 1
            rec(cand_mask & adjbits[v] & rest, chosen + 1, counts)
            counts[lv] -= 1
            if best[0]:
                return
        rec(rest, chosen, counts)
    rec(full, 0, [0] * len(family))
    return best[0]


def _solve_cnf(cnf):
    with _quiet_native_stdout(), Cadical153(bootstrap_with=cnf.clauses) as s:
        sat = s.solve()
        model = s.get_model() if sat else None
    return sat, model


def _build_symmetric_cnf_small(N, adjbits, layer_of, verts, idx, family, gens, k):
    # generalized translation pin: smallest layer c* with family[c*]>0 (design doc's
    # generalization for family[0]==0; here A0-analog acts transitively within any
    # single fixed layer). A generator is only usable here if BOTH: (1) it fixes the
    # pinned vertex (required by lex_leader_clauses' fixed-point precondition), AND
    # (2) it preserves the family vector under its induced layer permutation (required
    # for it to be a symmetry of THIS specific CNF at all -- see
    # _generator_preserves_family; this is the check the original design spec missed
    # and tier2 caught empirically). Generators failing either are simply dropped --
    # still sound, just a weaker (fewer-generator) symmetry break.
    c_star = next(c for c in range(k) if family[c] > 0)
    fixed_vertex = idx[(0, 0, 0, c_star)]
    layer_reps = [idx[(0, 0, 0, c)] for c in range(k)]
    cnf = _build_cnf_small(N, adjbits, layer_of, family, k)
    cnf.append([var(fixed_vertex)])
    top = cnf.nv
    for P in gens:
        if P[fixed_vertex] != fixed_vertex:
            continue
        if not _generator_preserves_family(P, layer_reps, layer_of, family):
            continue
        clauses, top = lex_leader_clauses(P, fixed_vertex, top)
        cnf.extend(clauses)
    return cnf, fixed_vertex


def _layer_clique_upper_bound(verts, adjbits, layer_of):
    # Within layer 0, partition by (x%2,y%2,z%2) of the first three coords: 8 classes of
    # 8 vertices each. Fast, non-recursive check (not full backtracking search) that each
    # class is an independent set gives a rigorous pigeonhole bound: any single-layer
    # clique has size <= (number of classes). This lets us build a genuinely UNSAT test
    # family (n_c = bound+1) as independent ground truth without the combinatorial
    # blow-up of proving non-existence by exhaustive backtracking (verified separately to
    # hang well past a minute on this 192-vertex, clique-rich graph -- weak pruning on the
    # "no witness exists" side is the classic hard case for naive clique search).
    layer0 = [i for i in range(len(verts)) if layer_of[i] == 0]
    parts = {}
    for i in layer0:
        x, y, z, _ = verts[i]
        parts.setdefault((x % 2, y % 2, z % 2), []).append(i)
    for cls in parts.values():
        for a in cls:
            for b in cls:
                if a != b:
                    assert not (adjbits[a] >> b) & 1, "parity-class independence assumption violated"
    return len(parts)


def tier2_small_graph_test():
    print("--- Tier 2: small Cayley-graph (Z4^3 x Z3, |V|=192) end-to-end test ---", flush=True)
    verts, idx = _small_verts_idx()
    N = len(verts)
    adjbits = _small_adjbits(verts)
    layer_of = [v[3] for v in verts]
    gens = _small_g0_generators(verts, idx)
    assert all(P[idx[(0, 0, 0, 0)]] == idx[(0, 0, 0, 0)] for P in gens[:5]), \
        "the 5 non-neg(3) generators must fix the origin"

    bound = _layer_clique_upper_bound(verts, adjbits, layer_of)  # == 8
    print(f"  independent pigeonhole bound on any single-layer clique: {bound}", flush=True)

    candidate_families = [
        [1, 1, 1], [1, 2, 2], [2, 2, 2], [1, 1, 0], [0, 2, 2], [0, 0, 3],
        [0, 3, 3], [3, 3, 3], [1, 0, 0],
    ]
    n0_pos, n0_zero = [], []
    for fam in candidate_families:
        truth = _brute_force_clique_exists(N, adjbits, layer_of, fam)
        (n0_pos if fam[0] > 0 else n0_zero).append((fam, truth))
    # analytic (pigeonhole) UNSAT instances -- infeasible by construction (bound+1 in a
    # single layer), giving a genuine known-NO case in each of the n0>0 / n0=0 groups
    # without the brute-force search hanging (see _layer_clique_upper_bound docstring).
    n0_pos.append(([bound + 1, 0, 0], False))
    n0_zero.append(([0, bound + 1, 0], False))
    print(f"  ground truth (n0>0): {n0_pos}", flush=True)
    print(f"  ground truth (n0=0): {n0_zero}", flush=True)
    if not (any(t for _, t in n0_pos) and any(not t for _, t in n0_pos)):
        print("  WARNING: n0>0 candidate set lacks both a YES and a NO instance", flush=True)
    if not (any(t for _, t in n0_zero) and any(not t for _, t in n0_zero)):
        print("  WARNING: n0=0 candidate set lacks both a YES and a NO instance", flush=True)

    all_ok = True
    for fam, truth in n0_pos + n0_zero:
        c_star = next(c for c in range(3) if fam[c] > 0)
        fixed_vertex = idx[(0, 0, 0, c_star)]

        # (i) base CNF alone
        base_cnf = _build_cnf_small(N, adjbits, layer_of, fam, 3)
        sat_i, model_i = _solve_cnf(base_cnf)

        # (ii) base + translation-pin only
        pin_cnf = _build_cnf_small(N, adjbits, layer_of, fam, 3)
        pin_cnf.append([var(fixed_vertex)])
        sat_ii, model_ii = _solve_cnf(pin_cnf)

        # (iii) base + translation-pin + lex-leader (all applicable generators)
        sym_cnf, fv = _build_symmetric_cnf_small(N, adjbits, layer_of, verts, idx, fam, gens, 3)
        sat_iii, model_iii = _solve_cnf(sym_cnf)

        ok = (bool(sat_i) == truth) and (bool(sat_ii) == truth) and (bool(sat_iii) == truth)
        if sat_iii:
            clique = [v for v in range(N) if model_iii[v] > 0]
            counts = [0, 0, 0]
            for v in clique:
                counts[layer_of[v]] += 1
            verified = _verify_small(clique, adjbits)
            ok = ok and verified and counts == fam and fixed_vertex in clique
        status = "PASS" if ok else "FAIL"
        print(f"  [{status}] family={fam} (n0={'>0' if fam[0] else '0'}, c*={c_star})  "
              f"truth={truth}  base={bool(sat_i)}  +pin={bool(sat_ii)}  +pin+lex={bool(sat_iii)}", flush=True)
        all_ok = all_ok and ok
    return all_ok


def build_symmetric_cnf_refusal_check():
    print("--- checking build_symmetric_cnf refuses family[0]==0 as designed ---", flush=True)
    try:
        build_symmetric_cnf([0, 1, 1, 1, 14])
        print("  FAIL: expected AssertionError for family[0]==0, none raised", flush=True)
        return False
    except AssertionError:
        print("  PASS: build_symmetric_cnf correctly refuses family[0]==0", flush=True)
        return True


def real_family_generator_filter_check():
    # cheap (no 3645-var CNF construction) direct check that the family-preservation
    # filter correctly separates the two real calibration families: family0's neg(3)
    # generator must be skipped (asymmetric [1,1,7,7] under 1<->4,2<->3 layer swap),
    # family11's must be kept (symmetric [3,5,5,3]).
    print("--- checking generator filter on the two real calibration families ---", flush=True)
    gens = L._g0_generators()
    layer_of = [v[3] for v in H.verts]
    layer_reps = [H.idx[(0, 0, 0, c)] for c in range(5)]
    family0 = [1, 1, 1, 7, 7]
    family11 = [1, 3, 5, 5, 3]
    keep0 = [_generator_preserves_family(P, layer_reps, layer_of, family0) for P in gens]
    keep11 = [_generator_preserves_family(P, layer_reps, layer_of, family11) for P in gens]
    ok = (keep0 == [True, True, True, False, True, True]) and (keep11 == [True] * 6)
    print(f"  family0 keep-mask={keep0} (expect neg(3)=index3 excluded)", flush=True)
    print(f"  family11 keep-mask={keep11} (expect all 6 kept)", flush=True)
    print(f"  [{'PASS' if ok else 'FAIL'}]", flush=True)
    return ok


if __name__ == "__main__":
    r1 = tier1_lex_leader_unit_test()
    r2 = tier2_small_graph_test()
    r3 = build_symmetric_cnf_refusal_check()
    r4 = real_family_generator_filter_check()
    overall = r1 and r2 and r3 and r4
    print("=" * 60)
    print(f"TIER 1 (lex-leader logic):        {'PASS' if r1 else 'FAIL'}")
    print(f"TIER 2 (small end-to-end graph):  {'PASS' if r2 else 'FAIL'}")
    print(f"build_symmetric_cnf n0=0 refusal: {'PASS' if r3 else 'FAIL'}")
    print(f"real-family generator filter:     {'PASS' if r4 else 'FAIL'}")
    print(f"OVERALL SELF-TEST: {'PASS' if overall else 'FAIL'}")
    sys.exit(0 if overall else 1)
