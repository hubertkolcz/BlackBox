"""
H2' DECISIVE PROBE: integer-point existence in the OPTIMAL DUAL FACE of the
weighted GE gluing LP (Lambda_k capacity formulation).

Hypothesis under test (FRAMEWORK-2026-07-13.md, reopened H2'): the
gauge-invariant detector of "GE attains the quantum value" is

    D(G,k) := [ the optimal face of the Lambda_k clique-cover LP (LP-D1)
                contains an INTEGER point ]

where LP-D1 (ESSAY-005-BRIDGE-formalA-weighted-presheaf.md Sec. 3b):

    Lambda_k(G) = min  sum_K y_K
                  s.t. sum_{K ni v} y_K >= 1  for all v in V(G^{vk}),
                       y_K >= 0,  K ranging over maximal cliques of G^{vk}
                       (conormal/OR k-th power).

The optimal face F* = { y feasible : sum_K y_K = Lambda_k } is a canonical
object of the LP; D quantifies over ALL of F*, so D is gauge-invariant BY
CONSTRUCTION -- this is exactly what the refuted Q/Z route (F9vii,
final_h1_cocycle_results.json) lacked (its class depended on WHICH optimal
dual was chosen).

WHY Lambda_k, NOT S_k: the per-copy value S_2(C5) = sqrt5 is irrational; a
face at an irrational optimum of a rational LP is empty of rational points
with that objective value, so "integer point at objective sqrt5" is vacuous
nonsense.  The rational home of the detector is the CAPACITY Lambda_k
(= L_k = S_k^k): 5/2, 5, 49/4, 343/8, 81/4 -- and there the C5,k=2 pentad
partition of unity IS an integer point at objective 5.

Cases: (C5,k=1), (C5,k=2), (C7,k=2), (C7,k=3), (C9,k=2) [out-of-sample
control, GE-002: C9 stuck at alpha* = 9/2 for k=1,2,3].

Everything decision-relevant is EXACT (fractions.Fraction / integer
combinatorics).  scipy(HiGHS) floats are used only as cross-checks and to
sample a generic vertex of the optimal face (then re-verified exactly).

NO Wolfram.  Run:  python h2prime_lattice_probe.py
Output: h2prime_results.json (same directory).  DO NOT COMMIT (per task).
"""

import itertools, json, math, os, sys, time
from collections import Counter, defaultdict
from fractions import Fraction

import numpy as np
import networkx as nx
from scipy.optimize import linprog

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "h2prime_results.json")


# ----------------------------------------------------------------------
# graph machinery
# ----------------------------------------------------------------------

def conormal_power(n, k):
    """C_n conormal (OR) k-th power: u~v iff exists t with u_t-v_t = +-1 mod n."""
    verts = list(itertools.product(range(n), repeat=k))
    idx = {v: i for i, v in enumerate(verts)}
    G = nx.Graph()
    G.add_nodes_from(range(len(verts)))
    for i, u in enumerate(verts):
        for j in range(i + 1, len(verts)):
            v = verts[j]
            if any((u[t] - v[t]) % n in (1, n - 1) for t in range(k)):
                G.add_edge(i, j)
    return G, verts, idx


def census(G):
    cl = [frozenset(c) for c in nx.find_cliques(G)]
    return cl, dict(Counter(len(c) for c in cl))


# ----------------------------------------------------------------------
# exact sandwich: primal uniform 1/omega  vs  dual structured cover
# ----------------------------------------------------------------------

def exact_sandwich(nV, cliques, omega, dual_support, dual_weight, target):
    """Prove Lambda = target exactly.
    Primal packing feasible point: p = 1/omega uniform -> value nV/omega
      (feasible iff every maximal clique has size <= omega : checked).
    Dual cover feasible point: y = dual_weight on dual_support (list of
      frozensets) -> value len(support)*weight (coverage >= 1 checked exactly).
    Weak duality: primal value <= Lambda <= dual value; equality pins Lambda."""
    w = Fraction(1, omega)
    assert all(len(K) <= omega for K in cliques), "primal uniform infeasible"
    primal_val = Fraction(nV) * w
    cov = defaultdict(Fraction)
    for K in dual_support:
        for v in K:
            cov[v] += dual_weight
    assert all(cov[v] >= 1 for v in range(nV)), "dual cover infeasible"
    dual_val = dual_weight * len(dual_support)
    assert primal_val == dual_val == target, (primal_val, dual_val, target)
    cover_exact = all(cov[v] == 1 for v in range(nV))
    return dict(primal_uniform_value=str(primal_val),
                dual_structured_value=str(dual_val),
                dual_coverage_exactly_one=cover_exact,
                Lambda_exact=str(target))


# ----------------------------------------------------------------------
# structured dual families
# ----------------------------------------------------------------------

def edges_k_products(n, k, idx):
    """The 'edge-cube' cliques: products E_1 x ... x E_k of edges of C_n.
    n^k of them, each a 2^k-clique of the conormal power, weight 1/2^k gives
    exact coverage 1 (each C_n vertex lies on 2 edges -> 2^k cubes/vertex)."""
    edges = [(a, (a + 1) % n) for a in range(n)]
    fam = []
    for combo in itertools.product(edges, repeat=k):
        fam.append(frozenset(idx[p] for p in itertools.product(*combo)))
    return fam


def pentads(idx):
    """C5^v2 slope pentads {(i, a*i+j mod 5)}: a clique iff 2a = +-1 mod 5,
    i.e. a in {2,3}; 10 pentads, two disjoint families of 5."""
    fam = []
    for a in (2, 3):
        for j in range(5):
            fam.append(frozenset(idx[(i, (a * i + j) % 5)] for i in range(5)))
    return fam


# ----------------------------------------------------------------------
# omega(C7^v3) = 8, independently re-proven (no census needed at k=3)
# ----------------------------------------------------------------------

def prove_omega_c7v3():
    """Lower bound: edge-cube {0,1}^3 is an 8-clique.  Upper bound: by
    translation-transitivity (Z_7^3 acts), a 9-clique may be assumed to
    contain (0,0,0); decide 'no 8-clique in G[N((0,0,0))]' (218 vertices)
    by Tomita-style branch-and-bound with greedy-coloring bound, seeded at
    best=7 (pure decision).  ~25 s, ~1.2M nodes."""
    n, k = 7, 3
    verts = list(itertools.product(range(n), repeat=k))
    idx = {v: i for i, v in enumerate(verts)}
    N = len(verts)
    adj = [0] * N
    for i, u in enumerate(verts):
        for j in range(i + 1, N):
            v = verts[j]
            if any((u[t] - v[t]) % n in (1, n - 1) for t in range(k)):
                adj[i] |= 1 << j
                adj[j] |= 1 << i
    cube = [idx[(a, b, c)] for a in (0, 1) for b in (0, 1) for c in (0, 1)]
    lower_ok = all((adj[cube[i]] >> cube[j]) & 1
                   for i in range(8) for j in range(i + 1, 8))
    v0 = idx[(0, 0, 0)]
    sub = [i for i in range(N) if (adj[v0] >> i) & 1]
    m = len(sub)
    A = [0] * m
    for a in range(m):
        for b in range(a + 1, m):
            if (adj[sub[a]] >> sub[b]) & 1:
                A[a] |= 1 << b
                A[b] |= 1 << a
    best = 7           # decision seed: search only for cliques of size >= 8
    found = [False]
    nodes = [0]
    sys.setrecursionlimit(100000)

    def color_sort(P):
        order, bounds, color = [], [], 0
        Q = P
        while Q:
            color += 1
            cand = Q
            while cand:
                v = (cand & -cand).bit_length() - 1
                order.append(v)
                bounds.append(color)
                cand &= ~((1 << v) | A[v])
                Q &= ~(1 << v)
        return order, bounds

    def expand(P, rsize):
        nodes[0] += 1
        if not P:
            if rsize > best:
                found[0] = True
            return
        order, bounds = color_sort(P)
        for i in range(len(order) - 1, -1, -1):
            if rsize + bounds[i] <= best or found[0]:
                return
            v = order[i]
            expand(P & A[v], rsize + 1)
            P &= ~(1 << v)

    t0 = time.time()
    expand((1 << m) - 1, 0)
    return dict(edge_cube_is_8clique=lower_ok,
                no_9clique=not found[0],
                omega=8 if (lower_ok and not found[0]) else None,
                bnb_nodes=nodes[0],
                bnb_seconds=round(time.time() - t0, 1),
                method="translation reduction to N((0,0,0)) (218 vts) + "
                       "coloring-bounded B&B, decision seed 7")


# ----------------------------------------------------------------------
# integer-point decision on the optimal face
# ----------------------------------------------------------------------

def integer_point_decision(label, Lambda, nV, cliques, max_size):
    """Decide exactly: does F* = {y >= 0, coverage >= 1, sum y = Lambda}
    contain an integer point (y over maximal cliques)?

    (i) If Lambda is not an integer: NO, unconditionally -- every integer
        y >= 0 has integer objective sum_K y_K != Lambda.  (Allowing
        non-maximal cliques changes nothing: lifting each clique to a
        maximal superset preserves integrality, objective and coverage.)

    (ii) If Lambda is an integer (here only C5,k=2, Lambda=5): counting
        lemma.  For feasible y:  sum_K y_K |K| = sum_v coverage(v) >= nV.
        With sum_K y_K = Lambda and |K| <= max_size, sum_K y_K |K|
        <= Lambda * max_size.  If Lambda * max_size == nV the two squeeze:
        coverage(v) == 1 for every v, support only on maximum cliques
        (|K| = max_size), no multiplicity >= 2 (would force coverage >= 2
        on its vertices).  Integer optimal points are then EXACTLY the
        partitions of V into Lambda maximum cliques -- enumerated
        exhaustively below."""
    if Lambda.denominator != 1:
        return dict(integer_point="NO",
                    proof=f"Lambda = {Lambda} is not an integer; any integer "
                          f"y>=0 has integer objective, so the optimal face "
                          f"(objective == {Lambda}) contains no integer point. "
                          f"Face-level and unconditional: holds for every "
                          f"optimal dual representative simultaneously.",
                    n_integer_points=0)
    L = Lambda.numerator
    assert L * max_size == nV, "counting lemma squeeze does not apply"
    maxcl = [K for K in cliques if len(K) == max_size]
    partitions = []
    allv = frozenset(range(nV))

    def rec(chosen, covered, start):
        if covered == allv:
            partitions.append(list(chosen))
            return
        if len(chosen) == L:
            return
        for i in range(start, len(maxcl)):
            K = maxcl[i]
            if not (K & covered):
                rec(chosen + [i], covered | K, i + 1)

    rec([], frozenset(), 0)
    # exact re-verification of each found integer point
    for part in partitions:
        cov = Counter()
        for i in part:
            cov.update(maxcl[i])
        assert len(part) == L and all(cov[v] == 1 for v in range(nV))
    return dict(integer_point="YES" if partitions else "NO",
                proof=f"Lambda = {L} integer; counting lemma forces integer "
                      f"optima to be partitions of the {nV} vertices into "
                      f"{L} maximum cliques (size {max_size}); exhaustive "
                      f"enumeration over the {len(maxcl)} maximum cliques "
                      f"found {len(partitions)} such partition(s).",
                n_integer_points=len(partitions),
                integer_points=[[sorted(maxcl[i]) for i in part]
                                for part in partitions])


# ----------------------------------------------------------------------
# scipy cross-checks + generic optimal-face vertex (robustness)
# ----------------------------------------------------------------------

def membership_matrix(nV, cliques):
    mem = np.zeros((nV, len(cliques)))
    for ci, K in enumerate(cliques):
        for v in K:
            mem[v, ci] = 1.0
    return mem


def lp_float_check(nV, cliques, target):
    mem = membership_matrix(nV, cliques)
    res = linprog(np.ones(len(cliques)), A_ub=-mem, b_ub=-np.ones(nV),
                  bounds=[(0, None)] * len(cliques), method="highs")
    return dict(scipy_value=res.fun,
                matches_target=bool(abs(res.fun - float(target)) < 1e-9))


def generic_face_vertex_exact(nV, cliques, Lambda, seed):
    """Sample a vertex of the OPTIMAL FACE (add equality sum y = Lambda,
    minimize a random direction), snap to rationals, verify exactly."""
    mem = membership_matrix(nV, cliques)
    nC = len(cliques)
    rng = np.random.default_rng(seed)
    res = linprog(rng.standard_normal(nC), A_ub=-mem, b_ub=-np.ones(nV),
                  A_eq=np.ones((1, nC)), b_eq=[float(Lambda)],
                  bounds=[(0, None)] * nC, method="highs")
    assert res.success
    y = {}
    for i, v in enumerate(res.x):
        if v > 1e-9:
            f = Fraction(v).limit_denominator(64)
            if abs(float(f) - v) > 1e-7:
                f = Fraction(v).limit_denominator(10**6)
            y[i] = f
    # exact verification
    cov = defaultdict(Fraction)
    for i, f in y.items():
        for v in cliques[i]:
            cov[v] += f
    feas = all(cov[v] >= 1 for v in range(nV))
    val = sum(y.values())
    return y, dict(exact_feasible=feas, exact_value=str(val),
                   on_optimal_face=bool(feas and val == Lambda),
                   support_size=len(y),
                   value_histogram={str(f): c for f, c in
                                    Counter(y.values()).items()})


def overlap_pairs(cliques):
    byv = defaultdict(list)
    for ci, K in enumerate(cliques):
        for v in K:
            byv[v].append(ci)
    pairs = set()
    for lst in byv.values():
        for a in range(len(lst)):
            for b in range(a + 1, len(lst)):
                pairs.add((lst[a], lst[b]))
    return pairs


def bad_overlaps(ydict, pairs):
    """Representative-level statistic of the REFUTED Q/Z route: number of
    overlapping clique pairs with y(K) - y(K') not in Z."""
    bad = 0
    for (a, b) in pairs:
        d = ydict.get(a, Fraction(0)) - ydict.get(b, Fraction(0))
        if d.denominator != 1:
            bad += 1
    return bad


# ----------------------------------------------------------------------
# theta of odd cycles (context only, floats)
# ----------------------------------------------------------------------

def theta_odd_cycle(n):
    c = math.cos(math.pi / n)
    return n * c / (1 + c)


# ----------------------------------------------------------------------
# main
# ----------------------------------------------------------------------

def main():
    results = dict(
        module="H2' decisive probe: integer point in the optimal dual face "
               "of the Lambda_k capacity LP",
        date="2026-07-13",
        formulation="LP-D1 of ESSAY-005-BRIDGE-formalA-weighted-presheaf.md: "
                    "min sum y_K, coverage >= 1, y >= 0 over maximal cliques "
                    "of the conormal power G^{vk}; optimal face F* = "
                    "{feasible y : sum y = Lambda_k}; detector D(G,k) = "
                    "[F* contains an integer point]",
        why_Lambda_not_Sk="S_2(C5) = sqrt5 is irrational: a rational LP face "
                          "at an irrational objective contains no rational "
                          "point at all, so the detector must live at the "
                          "rational capacity Lambda_k = S_k^k (objective 5, "
                          "not sqrt5, for C5 k=2). The pentad partition is an "
                          "integer point of THAT face.",
        cases={}, )

    t_all = time.time()

    # ---- case specifications ------------------------------------------
    # (n, k, Lambda target, attained?, structured dual)
    specs = [
        ("C5_k1", 5, 1, Fraction(5, 2)),
        ("C5_k2", 5, 2, Fraction(5)),
        ("C7_k2", 7, 2, Fraction(49, 4)),
        ("C7_k3", 7, 3, Fraction(343, 8)),
        ("C9_k2", 9, 2, Fraction(81, 4)),   # out-of-sample control (GE-002)
    ]

    c7k3_omega = None
    for label, n, k, Lambda in specs:
        t0 = time.time()
        entry = dict(n=n, k=k, nV=n ** k, Lambda_target=str(Lambda))
        theta = theta_odd_cycle(n)
        Sk = float(Lambda) ** (1.0 / k)
        entry["S_k"] = Sk
        entry["theta_G"] = theta
        entry["quantum_value_attained"] = bool(abs(Sk - theta) < 1e-12)

        if (n, k) == (7, 3):
            # no census at k=3: omega proof + edge-cube dual sandwich
            c7k3_omega = prove_omega_c7v3()
            entry["omega_proof"] = c7k3_omega
            assert c7k3_omega["omega"] == 8
            verts = list(itertools.product(range(7), repeat=3))
            idx = {v: i for i, v in enumerate(verts)}
            fam = edges_k_products(7, 3, idx)
            # sandwich needs 'every maximal clique <= omega'; that is the
            # omega=8 fact itself, so pass a placeholder census of the fam
            # and check sizes against omega directly:
            assert all(len(K) == 8 for K in fam)
            w = Fraction(1, 8)
            cov = defaultdict(Fraction)
            for K in fam:
                for v in K:
                    cov[v] += w
            assert all(cov[v] == 1 for v in range(343))
            primal_val = Fraction(343, 8)          # p = 1/8 uniform, omega=8
            dual_val = w * len(fam)                # 343/8
            assert primal_val == dual_val == Lambda
            entry["certificate"] = dict(
                primal_uniform_value=str(primal_val),
                primal_feasibility="p=1/8 uniform feasible because "
                                   "omega(C7^v3)=8 (re-proven above)",
                dual_structured_value=str(dual_val),
                dual_family="343 edge-cubes E1xE2xE3, y=1/8, coverage "
                            "exactly 1 (each vertex on 2 edges/coord -> "
                            "2^3=8 cubes)",
                dual_coverage_exactly_one=True,
                Lambda_exact=str(Lambda))
            entry["census"] = dict(skipped="k=3 census not needed: sandwich "
                                           "is a complete optimality proof")
            entry["decision"] = integer_point_decision(
                label, Lambda, 343, fam, 8)
        else:
            G, verts, idx = conormal_power(n, k)
            cliques, hist = census(G)
            entry["census"] = dict(n_max_cliques=len(cliques),
                                   size_histogram={str(s): c for s, c
                                                   in sorted(hist.items())})
            omega = max(hist)
            if (n, k) == (5, 2):
                fam = pentads(idx)
                famname = "10 slope-pentads {(i, a*i+j)}, a in {2,3}; dual "\
                          "y=1 on either disjoint family of 5"
                support = fam[:5]        # slope-2 family: a partition
                weight = Fraction(1)
            else:
                fam = edges_k_products(n, k, idx)
                famname = f"{n**k} edge-{'square' if k==2 else 'cube' if k==3 else 'product'}s"\
                          f" (k=1: the {n} edges), y=1/{2**k}"
                support = fam
                weight = Fraction(1, 2 ** k)
            clset = set(cliques)
            entry["structured_dual_cliques_maximal"] = all(
                K in clset for K in fam)
            entry["certificate"] = exact_sandwich(
                n ** k, cliques, omega, support, weight, Lambda)
            entry["certificate"]["dual_family"] = famname
            entry["scipy_crosscheck"] = lp_float_check(n ** k, cliques, Lambda)
            entry["decision"] = integer_point_decision(
                label, Lambda, n ** k, cliques, omega)
            if (n, k) == (5, 2):
                # one-sided integrality: packing side HAS a gap here
                alpha = max(len(c) for c in
                            nx.find_cliques(nx.complement(G)))
                entry["packing_side"] = dict(
                    alpha=alpha, alpha_star=str(Lambda),
                    packing_integrality_gap=bool(alpha < Lambda),
                    note="covering side integral (chi_bar = 5 = chi_bar_f) "
                         "while packing side fractional (alpha = 4 < 5): "
                         "one-sided integrality, NOT perfection/TDI")
            # scaled 2^k-cover integer points exist at EVERY stuck case:
            t = 2 ** k if (n, k) != (5, 2) else 1
            if t > 1:
                entry["scaled_integrality"] = dict(
                    t=t, statement=f"y = 1 on the structured family is an "
                    f"INTEGER {t}-fold cover of total weight {t*Lambda} = "
                    f"t*Lambda; scaled integer points exist at every stuck "
                    f"case, so the detector is discriminating ONLY at t=1 "
                    f"(genuine partition of unity).")
        entry["seconds"] = round(time.time() - t0, 1)
        results["cases"][label] = entry
        print(f"[{label}] Lambda={Lambda}  S_k={Sk:.6f}  theta={theta:.6f}  "
              f"attained={entry['quantum_value_attained']}  "
              f"integer_point={entry['decision']['integer_point']}  "
              f"({entry['seconds']}s)")

    # ---- robustness: the two duals that broke the Q/Z route (C7,k=2) ---
    print("robustness: C7 k=2 canonical vs generic optimal dual ...")
    G, verts, idx = conormal_power(7, 2)
    cliques, _ = census(G)
    clindex = {K: i for i, K in enumerate(cliques)}
    Lambda = Fraction(49, 4)
    # canonical y = 1/4 on the 49 edge-squares
    canon = {clindex[K]: Fraction(1, 4)
             for K in edges_k_products(7, 2, idx)}
    covc = defaultdict(Fraction)
    for i, f in canon.items():
        for v in cliques[i]:
            covc[v] += f
    assert all(covc[v] == 1 for v in range(49))
    assert sum(canon.values()) == Lambda
    # generic vertex of the optimal face (random objective over F*)
    gen, gencert = generic_face_vertex_exact(49, cliques, Lambda, seed=1)
    pairs = overlap_pairs(cliques)
    same_support = set(canon) == set(gen)
    rob = dict(
        canonical=dict(support_size=len(canon), value="49/4",
                       histogram={"1/4": 49}),
        generic_vertex=gencert,
        supports_identical=same_support,
        representative_level_Qz_statistic=dict(
            n_overlap_pairs=len(pairs),
            bad_overlaps_canonical=bad_overlaps(canon, pairs),
            bad_overlaps_generic=bad_overlaps(gen, pairs),
            reading="the refuted F9vii construction depended on these "
                    "representative-level numbers, which differ between "
                    "optimal duals"),
        face_level_answer=dict(
            canonical="NO", generic="NO",
            reason="D quantifies over the WHOLE face: Lambda = 49/4 not an "
                   "integer kills every integer candidate simultaneously, "
                   "independent of which optimal dual is exhibited. "
                   "Gauge-invariance is automatic by construction."))
    results["robustness_C7k2"] = rob
    print(f"  canonical support 49 (y=1/4)  generic support "
          f"{gencert['support_size']} on-face={gencert['on_optimal_face']}  "
          f"supports_identical={same_support}")
    print(f"  Q/Z bad-overlaps: canonical="
          f"{rob['representative_level_Qz_statistic']['bad_overlaps_canonical']}"
          f" generic="
          f"{rob['representative_level_Qz_statistic']['bad_overlaps_generic']}"
          f"  -> face-level answer NO for both")

    # ---- verdict -------------------------------------------------------
    pattern_ok = all(
        (results["cases"][c]["decision"]["integer_point"] == "YES")
        == results["cases"][c]["quantum_value_attained"]
        for c in results["cases"])
    results["verdict"] = dict(
        pattern_verified=pattern_ok,
        detector_statement=(
            "D(G,k): the optimal face of the Lambda_k clique-cover LP of "
            "G^{vk} (coverage >= 1, objective == Lambda_k) contains an "
            "integer point  <=>  Lambda_k is an integer AND the integral "
            "clique-cover number chi_bar(G^{vk}) equals Lambda_k (an exact "
            "integer partition-of-unity certificate exists). Verified on "
            "all 5 cases: YES exactly at (C5,k=2) -- the unique tested case "
            "with S_k = theta(G); NO at (C5,k=1), (C7,k=2), (C7,k=3) and "
            "the out-of-sample (C9,k=2) (predicted NO, confirmed)."),
        gauge_invariance=(
            "automatic: D is a predicate of the optimal face (a canonical "
            "object of the LP), not of any chosen optimal dual; the two "
            "duals that broke the Q/Z route give identical face-level "
            "answers by construction (demonstrated above)."),
        honesty=dict(
            no_cases_decided_by="in all four NO cases the objective "
                "Lambda_k = (n/2)^k is a non-integer (2^k does not divide "
                "n^k for odd n), which alone empties the face of integer "
                "points; the YES case carries the real content (an integer "
                "cover exists AND is optimal).",
            iff_scope="the 'iff' is verified on these 5 instances only. A "
                "decisive future test needs a graph stuck at an INTEGER "
                "fractional-packing value; none is in the tested family "
                "(odd cycles stuck at (n/2)^k are automatically "
                "non-integer). Until then 'D <=> attainment' is "
                "data-supported, not proven.",
            scaled_integrality="integer t-fold covers (t = 2^k) exist at "
                "every stuck case, so the detector is only meaningful at "
                "t=1; 'integer point at objective t*Lambda' does NOT "
                "discriminate."),
        tdi_paragraph=(
            "Connection to total dual integrality / perfection (verified "
            "vs conjectured): for a PERFECT graph the clique-constraint "
            "system is TDI (Lovasz/Fulkerson-Chvatal), the covering LP has "
            "integral optima for every objective, and alpha = theta = "
            "chi_bar -- the quantum value is attained trivially at k=1 with "
            "an integer certificate. The graphs here are imperfect (C5^v2 "
            "contains the diagonal odd hole C5), and VERIFIED: at (C5,k=2) "
            "integrality is strictly ONE-SIDED -- the covering face is "
            "integral (chi_bar = chi_bar_f = 5, two pentad-partition "
            "integer points) while the packing side has a gap (alpha = 4 < "
            "alpha* = 5) -- so the mechanism is NOT perfection and NOT full "
            "TDI, but single-face dual integrality at the all-ones "
            "right-hand side, exactly where theta(G)^k = chi_bar_f(G^{vk}). "
            "CONJECTURED: attainment  <=>  theta(G)^k = chi_bar(G^{vk}) "
            "in general, i.e. whenever theta reaches the fractional cover "
            "bound of the power, an integral optimal cover exists. A proof "
            "would require (i) attainment => theta(G^{vk}) = "
            "chi_bar_f(G^{vk}) (theta is squeezed: theta(G)^k <= "
            "theta(G^{vk}) <= chi_bar_f can fail supermultiplicatively -- "
            "needs care under the conormal product), and (ii) a rounding "
            "theorem producing an integral cover from theta = chi_bar_f "
            "-- e.g. via a sharply transitive clique family as with the "
            "Z5 slope pentads; no general TDI machinery applies to "
            "imperfect graphs, so (ii) is genuinely open."),
        proof_requires=(
            "(1) theta-attainment => Lambda_k integer (true for C5: "
            "theta^2 = 5; needs 'attainment happens at integer capacity' "
            "in general); (2) attainment => existence of an integral "
            "optimal cover (rounding/orbit argument); (3) converse: "
            "integral optimal cover => S_k = theta (this direction is "
            "NOT even heuristically clear -- an imperfect graph could "
            "conceivably have chi_bar = alpha* integer without theta "
            "reaching it; finding or excluding such a case is the "
            "sharpest next experiment)."))
    results["provenance"] = dict(
        anchors="ESSAY-005-BRIDGE-formalA-weighted-presheaf.md, "
                "p3_certificates.json, bridge_weighted_presheaf.json "
                "(all values re-derived exactly here, censuses "
                "reproduced: C5^v2 535={4:525,5:10}, C7^v2 1715={4:1715}; "
                "new: C9^v2 3807={4:3807}); omega(C7^v3)=8 independently "
                "re-proven in this run",
        refuted_route="final_h1_cocycle_results.json (F9vii)",
        exactness="all decision-relevant arithmetic in fractions.Fraction; "
                  "scipy/HiGHS used only for cross-checks and to sample a "
                  "generic face vertex, which is then re-verified exactly")
    results["total_seconds"] = round(time.time() - t_all, 1)

    with open(OUT, "w") as f:
        json.dump(results, f, indent=1)
    print(f"\npattern_verified = {pattern_ok}")
    print(f"wrote {OUT}  ({results['total_seconds']}s total)")


if __name__ == "__main__":
    main()
