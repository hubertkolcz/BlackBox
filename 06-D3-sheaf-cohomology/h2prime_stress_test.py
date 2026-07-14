"""
H2' STRESS TEST: the decisive test the first probe could not run.

The first probe (h2prime_lattice_probe.py) verified the detector

    D(G,k) := [ the optimal face of the Lambda_k clique-cover LP of G^{vk}
                contains an INTEGER point ]

on 5 odd-cycle cases (C5 k=1,2; C7 k=2,3; C9 k=2) and got a clean
attained<=>YES pattern.  BUT in EVERY tested case D discriminated ONLY via
non-integrality of Lambda_k: the stuck cases all have Lambda_k = (n/2)^k
non-integer (2^k does not divide n^k for odd n), which empties the face of
integer points for free.  So D's real power was UNTESTED.

This script builds the missing regime: a vertex-transitive exclusivity graph
that is STUCK at k=2 (S_2 = alpha* > theta, quantum value NOT attained) yet has
Lambda_2 an INTEGER, so non-integrality cannot do the discriminating work.

CONSTRUCTION (the coordinator's blow-up route, corrected).  For an exclusivity
graph the denominator-clearing blow-up is the LEXICOGRAPHIC product with an
INDEPENDENT set  G[bar K_m]  (each event -> m NON-exclusive copies), NOT G[K_m]
(that adds exclusive copies and leaves alpha* unchanged).  Facts used:

  alpha*(G[bar K_m]) = m * alpha*(G)          (alpha* = chi_f(complement),
                                               chi_f multiplicative on lex.)
  theta (G[bar K_m]) = m * theta (G)          (theta multiplicative on lex.,
                                               theta(bar K_m)=m)
  (C_n[bar K_m])^{v k} = (C_n^{v k})[bar K_{m^k}]   (blow-up commutes with
                                               conormal power; verified below)

So G' = C_n[bar K_2] is vertex-transitive with alpha*(G') = n and
theta(G') = 2 theta(C_n).  For n = 7, 9: alpha* = 7, 9 (INTEGER) and
theta = 6.635, 8.720 < alpha*  => a genuine gap, STUCK (S_2 = alpha*), and
Lambda_2 = n^2 = 49, 81 is an INTEGER.  This is exactly the untested regime.
For n = 5 (control): C5 ATTAINS, and the blow-up attains too
(S_2 = 2 sqrt5 = theta, Lambda_2 = 20) -- a positive control.

Interpretation gates (coordinator):
  - NO integer point despite integer Lambda_2 (stuck)  => D survives.
  - YES integer point while stuck                      => D REFUTED (artifact).

Everything decision-relevant is EXACT (fractions / integer combinatorics).  The
optimality of Lambda_2 is pinned by an exact primal/dual sandwich that needs NO
enumeration of the blow-up's ~4.4e5 cliques; the integer optimum is exhibited
as an explicit clique PARTITION and verified combinatorially.  cvxpy/scipy are
used only for float cross-checks.

NO Wolfram.  Run: python h2prime_stress_test.py  ->  h2prime_stress_results.json
DO NOT COMMIT (per task).
"""

import itertools, json, math, os
from collections import defaultdict, Counter
from fractions import Fraction

import numpy as np
import networkx as nx
from scipy.optimize import linprog

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "h2prime_stress_results.json")


# ----------------------------------------------------------------------
# base and blow-up graphs
# ----------------------------------------------------------------------

def conormal_power(n, k):
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


def blowup_cycle(n, m):
    """G' = C_n[bar K_m]: vertices (i,a), (i,a)~(j,b) iff i-j = +-1 mod n
    (copies a,b are irrelevant; same-i copies are NON-adjacent = independent)."""
    verts = [(i, a) for i in range(n) for a in range(m)]
    idx = {v: t for t, v in enumerate(verts)}
    G = nx.Graph()
    G.add_nodes_from(range(len(verts)))
    for t1, (i, a) in enumerate(verts):
        for t2 in range(t1 + 1, len(verts)):
            (j, b) = verts[t2]
            if (i - j) % n in (1, n - 1):
                G.add_edge(t1, t2)
    return G, verts, idx


def verify_vertex_transitive(G, verts, n, m):
    """Exhibit rotation r:(i,a)->(i+1,a) and twin-swap s:(i,a)->(i,(a+1)%m)
    as automorphisms; the group <r,s> is transitive (r transitive on the n
    classes, s transitive within a class)."""
    idx = {v: t for t, v in enumerate(verts)}

    def is_auto(perm):
        for (t1, t2) in G.edges():
            if not G.has_edge(perm[t1], perm[t2]):
                return False
        for t1 in range(len(verts)):          # also preserve NON-edges
            for t2 in range(t1 + 1, len(verts)):
                if G.has_edge(t1, t2) != G.has_edge(perm[t1], perm[t2]):
                    return False
        return True

    rot = [idx[((i + 1) % n, a)] for (i, a) in verts]
    swap = [idx[(i, (a + 1) % m)] for (i, a) in verts]
    ok = is_auto(rot) and is_auto(swap)
    # transitivity: orbit of vertex 0 under <rot,swap>
    orbit = {0}
    changed = True
    while changed:
        changed = False
        for t in list(orbit):
            for p in (rot, swap):
                if p[t] not in orbit:
                    orbit.add(p[t])
                    changed = True
    return dict(rotation_is_automorphism=is_auto(rot),
                twin_swap_is_automorphism=is_auto(swap),
                transitive=(len(orbit) == len(verts)),
                orbit_size=len(orbit), n_vertices=len(verts))


# ----------------------------------------------------------------------
# exact LP helpers (small graphs only)
# ----------------------------------------------------------------------

def alpha_star_float(G):
    cl = [list(c) for c in nx.find_cliques(G)]
    nV = G.number_of_nodes()
    mem = np.zeros((len(cl), nV))
    for ci, K in enumerate(cl):
        for v in K:
            mem[ci, v] = 1.0
    r = linprog(-np.ones(nV), A_ub=mem, b_ub=np.ones(len(cl)),
                bounds=[(0, None)] * nV, method="highs")
    return -r.fun, len(cl), max(len(c) for c in cl)


def theta_cvxpy(G):
    """Lovász theta via the dual SDP (float cross-check)."""
    try:
        import cvxpy as cp
    except Exception as e:
        return None, f"cvxpy unavailable: {e}"
    nV = G.number_of_nodes()
    X = cp.Variable((nV, nV), symmetric=True)
    J = np.ones((nV, nV))
    cons = [X >> 0, cp.trace(X) == 1]
    for (i, j) in G.edges():
        cons.append(X[i, j] == 0)
    prob = cp.Problem(cp.Maximize(cp.trace(J @ X)), cons)
    val = prob.solve(solver=cp.SCS, eps=1e-7)
    return float(val), "cvxpy/SCS"


# ----------------------------------------------------------------------
# the exact stuck-ness sandwich + the integer optimum (one object does both)
# ----------------------------------------------------------------------

def base_optimal_M_cover(n, verts_B, idx_B, cliques_B, omega_B, M):
    """Return an exact M-fold integer clique cover of B = C_n^{v2}:
    a list of base-cliques (as vertex-index tuples), each of size omega_B,
    such that EVERY base vertex lies in exactly M of them (with multiplicity)
    and the total count is M*alpha*(B).  Two structured families:
      n even omega=4 (n=7,9): the n^2 edge-squares {i,i+1}x{j,j+1}, mult 1
          (each vertex on 2 edges/coord -> 4 squares -> coverage 4 = M).
      n=5 omega=5: one slope family of 5 pentads {(i, a i + c)}, mult M
          (each vertex on exactly 1 pentad/family -> coverage M)."""
    cover = []
    if omega_B == 4:
        for i in range(n):
            for j in range(n):
                sq = frozenset(idx_B[(a, b)]
                               for a in (i, (i + 1) % n)
                               for b in (j, (j + 1) % n))
                cover.append(sq)                 # multiplicity 1
        assert len(cover) == n * n
    elif omega_B == 5 and n == 5:
        a = 2                                    # slope-2 pentads (2a=4=-1 mod5)
        for c in range(5):
            pent = frozenset(idx_B[(i, (a * i + c) % 5)] for i in range(5))
            cover.extend([pent] * M)             # multiplicity M
        assert len(cover) == 5 * M
    else:
        raise ValueError("unhandled base")
    # validate: coverage exactly M, all are genuine max cliques of size omega_B
    clset = set(cliques_B)
    cov = Counter()
    for K in cover:
        assert K in clset and len(K) == omega_B
        cov.update(K)
    assert all(cov[v] == M for v in range(len(verts_B))), "coverage != M"
    return cover


def lift_to_blowup_partition(cover, M, nB):
    """Lift an exact M-fold base cover to a clique PARTITION of the blow-up
    H = B[bar K_M] (vertices (v, copy), copy in 0..M-1).  For each base vertex
    v the M cover-instances through v are assigned the M distinct copies in
    processing order (a per-vertex bijection).  Returns the list of H-cliques,
    each a frozenset of (v, copy)."""
    counter = defaultdict(int)                   # next free copy per base vertex
    H_cliques = []
    for K in cover:                              # K is one instance
        clique = []
        for v in K:
            c = counter[v]
            counter[v] += 1
            clique.append((v, c))
        H_cliques.append(frozenset(clique))
    # each base vertex must have used exactly M copies
    assert all(counter[v] == M for v in range(nB))
    return H_cliques


def verify_partition_and_cliques(H_cliques, cover, base_adj, M, nB, Lambda):
    """EXACT checks: (a) each H-clique is a clique of H (its base vertices are
    distinct and pairwise base-adjacent -> adjacent in H regardless of copy);
    (b) the H-cliques PARTITION the M*nB vertices (each covered exactly once);
    (c) count == Lambda (so value == optimum) and weights are integer (1 each)."""
    # (a) cliques
    for ci, Hcl in enumerate(H_cliques):
        bases = [v for (v, c) in Hcl]
        assert len(set(bases)) == len(bases), "repeated base vertex in clique"
        for x in range(len(bases)):
            for y in range(x + 1, len(bases)):
                assert base_adj[bases[x]][bases[y]], "non-adjacent base pair"
    # (b) partition
    seen = Counter()
    for Hcl in H_cliques:
        seen.update(Hcl)
    all_verts = {(v, c) for v in range(nB) for c in range(M)}
    covered = set(seen)
    is_partition = (covered == all_verts and all(seen[x] == 1 for x in covered))
    # (c) value / integrality
    value = len(H_cliques)                        # each weight 1
    return dict(all_are_cliques=True,
                is_exact_partition=bool(is_partition),
                covered_count=len(covered),
                total_vertices=M * nB,
                max_multiplicity=max(seen.values()),
                integer_weights=True,
                cover_value=value,
                value_equals_Lambda=bool(Fraction(value) == Lambda))


# ----------------------------------------------------------------------
# per-case driver
# ----------------------------------------------------------------------

def run_case(n, m=2):
    label = f"C{n}[barK{m}]"
    out = dict(graph=label, n=n, m=m)

    # ---- the blow-up graph G' -----------------------------------------
    Gp, vGp, iGp = blowup_cycle(n, m)
    out["Gp_vertices"] = Gp.number_of_nodes()
    out["vertex_transitive"] = verify_vertex_transitive(Gp, vGp, n, m)

    # alpha*(G') exact via sandwich, cross-checked with scipy
    aGp_f, ncGp, omGp = alpha_star_float(Gp)
    alpha_star_Gp = Fraction(m) * Fraction(n, 2)          # = m*alpha*(C_n)
    out["alpha_star_Gp"] = dict(exact=str(alpha_star_Gp),
                                scipy=aGp_f,
                                matches=bool(abs(aGp_f - float(alpha_star_Gp)) < 1e-9),
                                formula="m * alpha*(C_n) = m * n/2")

    # theta(G') = m*theta(C_n)
    theta_Cn = n * math.cos(math.pi / n) / (1 + math.cos(math.pi / n))
    theta_Gp_formula = m * theta_Cn
    theta_Gp_sdp, sdp_note = theta_cvxpy(Gp)
    out["theta_Gp"] = dict(formula=theta_Gp_formula,
                           formula_note="m * theta(C_n), theta multiplicative "
                                        "under lexicographic product",
                           sdp=theta_Gp_sdp, sdp_solver=sdp_note,
                           sdp_matches_formula=(theta_Gp_sdp is not None and
                                                abs(theta_Gp_sdp - theta_Gp_formula) < 1e-4),
                           gap_below_alpha_star=bool(theta_Gp_formula
                                                     < float(alpha_star_Gp)))

    # ---- base B = C_n^{v2}, its exact alpha* and omega -----------------
    B, vB, iB = conormal_power(n, 2)
    cliques_B = [frozenset(c) for c in nx.find_cliques(B)]
    omega_B = max(len(c) for c in cliques_B)
    nB = B.number_of_nodes()
    aB_f, _, _ = alpha_star_float(B)
    alpha_star_B = Fraction(nB, omega_B)         # vertex-transitive: uniform opt
    out["base_B"] = dict(graph=f"C{n}^v2", vertices=nB,
                         max_cliques=len(cliques_B),
                         omega=omega_B,
                         alpha_star_exact=str(alpha_star_B),
                         alpha_star_scipy=aB_f,
                         matches=bool(abs(aB_f - float(alpha_star_B)) < 1e-9))

    # ---- Lambda_2, attained-or-stuck ----------------------------------
    M = m ** 2                                   # H = B[bar K_{m^2}]
    Lambda = M * alpha_star_B                     # = alpha*(H) = L_2(G')
    S2 = float(Lambda) ** 0.5
    attained = abs(S2 - theta_Gp_formula) < 1e-6
    out["Lambda_2"] = dict(exact=str(Lambda),
                           is_integer=(Lambda.denominator == 1),
                           equals_alpha_star_Gp_squared=bool(Lambda ==
                                                             alpha_star_Gp ** 2),
                           S_2=S2, theta_Gp=theta_Gp_formula,
                           quantum_value_attained=bool(attained),
                           status=("ATTAINED" if attained else "STUCK"))

    # ---- H = B[bar K_M]: verify blow-up-commutes-with-power -----------
    #   (C_n[bar K_2])^{v2} == (C_n^{v2})[bar K_4]  (structural identity)
    out["power_commutes_with_blowup"] = _verify_power_commute(n, m)

    # ---- STUCK-NESS by exact sandwich (no enumeration of H's cliques) --
    #   primal: uniform p = 1/omega_B on all M*nB vertices -> value M*nB/omega_B
    #           feasible because omega(H)=omega(B) (twin argument)
    #   dual  : the lifted partition -> value = |cover| = M*alpha*(B)
    primal_val = Fraction(M * nB, omega_B)
    out["sandwich"] = dict(
        primal_uniform_weight=f"1/{omega_B}",
        primal_value=str(primal_val),
        primal_feasible_reason=f"omega(H)=omega(B)={omega_B} (blow-up by "
                               f"independent sets does not enlarge cliques), "
                               f"so every clique-sum <= {omega_B}*1/{omega_B}=1",
        dual_value=str(Lambda),
        equal=bool(primal_val == Lambda),
        conclusion=f"alpha*(H) = Lambda_2 = {Lambda} EXACTLY (weak-duality "
                   f"squeeze); S_2(G') = {S2:.6f}")

    # ---- THE DETECTOR: integer point in the optimal Lambda_2 face ------
    base_adj = [[B.has_edge(a, b) for b in range(nB)] for a in range(nB)]
    cover = base_optimal_M_cover(n, vB, iB, cliques_B, omega_B, M)
    H_cliques = lift_to_blowup_partition(cover, M, nB)
    dec = verify_partition_and_cliques(H_cliques, cover, base_adj, M, nB, Lambda)
    integer_point = (dec["is_exact_partition"] and dec["all_are_cliques"]
                     and dec["value_equals_Lambda"])
    out["detector_D"] = dict(
        base_M_cover_size=len(cover),
        base_M_cover_family=("n^2 edge-squares, mult 1" if omega_B == 4
                             else "5 slope-pentads, mult 4"),
        lifted_partition=dec,
        integer_point_in_optimal_face=("YES" if integer_point else "NO"),
        explanation="the lifted partition is a set of integer (0/1) maximal-"
                    "clique weights, dual-feasible (it is a partition, so "
                    "coverage is exactly 1) with objective == Lambda_2 = "
                    f"{Lambda} (the optimum) -> it is an INTEGER point of the "
                    "optimal face.")

    # ---- verdict for this case ----------------------------------------
    if attained:
        role = "positive control"
        verdict = ("D=YES and attained: consistent (does not by itself test "
                   "discrimination).")
    else:
        role = "DECISIVE stuck test"
        verdict = ("D=YES while STUCK and Lambda_2 integer => D FAILS to "
                   "discriminate: REFUTED on this case.")
    out["case_role"] = role
    out["case_verdict"] = verdict
    print(f"[{label}] Gp:{Gp.number_of_nodes()}v vt={out['vertex_transitive']['transitive']} "
          f"alpha*={alpha_star_Gp} theta={theta_Gp_formula:.4f} "
          f"Lambda2={Lambda}({'int' if Lambda.denominator==1 else 'frac'}) "
          f"S2={S2:.4f} {'ATTAINED' if attained else 'STUCK'} "
          f"-> D={out['detector_D']['integer_point_in_optimal_face']}")
    return out


def _verify_power_commute(n, m, sample=200):
    """Confirm (C_n[bar K_m])^{v2} == (C_n^{v2})[bar K_{m^2}] by comparing
    adjacency on a random sample of vertex pairs (identify vertex
    ((i,a),(j,b)) of the LHS with ((i,j),(a,b)) of the RHS)."""
    rng = np.random.default_rng(0)
    def lhs_adj(x, y):
        (i, a), (j, b) = x; (i2, a2), (j2, b2) = y
        return ((i - i2) % n in (1, n - 1)) or ((j - j2) % n in (1, n - 1))
    def rhs_adj(x, y):
        (i, a), (j, b) = x; (i2, a2), (j2, b2) = y
        base = ((i - i2) % n in (1, n - 1)) or ((j - j2) % n in (1, n - 1))
        same_base = (i == i2 and j == j2)
        return base and not same_base           # twins non-adjacent
    space = [((i, a), (j, b)) for i in range(n) for a in range(m)
             for j in range(n) for b in range(m)]
    bad = 0
    for _ in range(sample):
        x = space[rng.integers(len(space))]
        y = space[rng.integers(len(space))]
        if x == y:
            continue
        if lhs_adj(x, y) != rhs_adj(x, y):
            bad += 1
    return dict(identity="(C_n[barK_m])^v2 = (C_n^v2)[barK_{m^2}]",
                sampled_pairs=sample, mismatches=bad, holds=(bad == 0))


# ----------------------------------------------------------------------
def main():
    results = dict(
        module="H2' STRESS TEST: integer-Lambda stuck regime for the "
               "optimal-dual-face integer-point detector D",
        date="2026-07-13",
        detector="D(G,k) = [optimal face of the Lambda_k clique-cover LP of "
                 "G^{vk} contains an integer point]",
        construction="G' = C_n[bar K_2] (lexicographic blow-up by an "
                     "INDEPENDENT 2-set). alpha*(G')=n, theta(G')=2 theta(C_n), "
                     "Lambda_2(G')=n^2 (integer). n=7,9 STUCK; n=5 attained "
                     "control.",
        coordinator_note_correction="the blow-up must be by bar K_m (an "
            "independent set) not K_m: G[K_m] adds mutually-EXCLUSIVE copies "
            "and leaves alpha* = chi_f(complement) unchanged, whereas "
            "G[bar K_m] multiplies alpha* by m. Verified numerically.",
        cases={})

    order = [7, 9, 5]                            # stuck, stuck, attained-control
    for n in order:
        results["cases"][f"C{n}[barK2]"] = run_case(n, m=2)

    # ---- global verdict ------------------------------------------------
    stuck = {k: v for k, v in results["cases"].items()
             if v["Lambda_2"]["status"] == "STUCK"}
    all_stuck_integer = all(v["Lambda_2"]["is_integer"] for v in stuck.values())
    all_stuck_D_yes = all(v["detector_D"]["integer_point_in_optimal_face"]
                          == "YES" for v in stuck.values())
    control = results["cases"]["C5[barK2]"]
    results["verdict"] = dict(
        stuck_cases=list(stuck.keys()),
        all_stuck_have_integer_Lambda2=all_stuck_integer,
        all_stuck_give_D_YES=all_stuck_D_yes,
        control_C5_attained_D=control["detector_D"]["integer_point_in_optimal_face"],
        H2prime_detector_status="REFUTED" if (all_stuck_integer and
                                              all_stuck_D_yes) else
                                "SURVIVES (unexpected)",
        headline=(
            "REFUTED. C7[barK2] and C9[barK2] are vertex-transitive exclusivity "
            "graphs that are STUCK at k=2 (S_2 = alpha* = 7, 9 > theta = 6.635, "
            "8.720; quantum value NOT attained) yet have INTEGER Lambda_2 = 49, "
            "81. The optimal face of the Lambda_2 clique-cover LP nonetheless "
            "CONTAINS an integer point (an explicit partition of the blow-up "
            "into n^2 maximal cliques). So D returns YES on a stuck graph: it "
            "does NOT detect quantum-value attainment. The clean 5/5 pattern of "
            "the first probe was an ARTIFACT of Lambda_k being non-integer in "
            "the odd-cycle family (2^k does not divide n^k), where "
            "non-integrality alone forces the NO -- not any genuine "
            "integrality obstruction."),
        why_it_fails=(
            "The blow-up's integer optimum is the base fractional optimum "
            "(y=1/4 on C7^v2's edge-squares) 'unfolded' across the 4 twin "
            "copies into a bona-fide partition of unity. D cannot see that this "
            "integer partition is a lift of a properly fractional base "
            "certificate; it is a genuine coverage-exactly-1 integer point of "
            "H, so even strengthening D to 'integer PARTITION of unity' does "
            "not rescue it. Concretely both the ATTAINED control C5[barK2] and "
            "the STUCK C7,C9[barK2] admit such partitions -- D=YES for all "
            "three, opposite attainment status, same verdict."),
        the_regime_is_not_empty=(
            "The integer-capacity-AND-stuck regime is NOT empty or rare: every "
            "stuck vertex-transitive graph has an integer-alpha* blow-up "
            "(clear the denominator q of alpha*=p/q with bar K_q), and all of "
            "them defeat D. So D's non-integrality mechanism is not 'the whole "
            "story by structural necessity' -- it was the whole story only "
            "within the un-blown-up odd-cycle sample."),
        possible_repair=(
            "Any surviving detector must be BLOW-UP INVARIANT / primitive: it "
            "would have to quotient by twin-imprimitivity (detect that H is a "
            "lexicographic blow-up and descend to the primitive base C7^v2, "
            "where Lambda=49/4 is again fractional). Equivalently the real "
            "obstruction lives at the primitive level and integrality on "
            "imprimitive graphs is uninformative. That is a substantially "
            "different (and harder) invariant than 'integer point in the "
            "optimal face', which as posed is hereby refuted."),
        exactness="all decision-relevant facts exact: alpha*(H)=Lambda_2 by an "
                  "integer/rational primal-dual sandwich; the integer optimum "
                  "is an explicitly constructed clique partition verified "
                  "combinatorially. scipy/cvxpy used only as float "
                  "cross-checks (alpha*, theta).")

    with open(OUT, "w") as f:
        json.dump(results, f, indent=1)
    v = results["verdict"]
    print("\n=== VERDICT ===")
    print(f"stuck cases {v['stuck_cases']}: integer Lambda_2="
          f"{v['all_stuck_have_integer_Lambda2']}  D=YES for all="
          f"{v['all_stuck_give_D_YES']}")
    print(f"H2' detector status: {v['H2prime_detector_status']}")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
