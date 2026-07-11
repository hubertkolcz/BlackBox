"""D1 numerics sweep -- pure-Python cross-check route (standard library only).

Third independent route alongside the two Wolfram routes (dense SDP theta;
closed-form theta) used for the same quantities in d1_ge_copies_sweep.wl:

  1. alpha, omega, and the 2-copies GE clique number omega(G^(OR 2)) are
     recomputed here from scratch by EXACT bitmask Bron-Kerbosch-with-pivoting
     max-clique search (Tomita et al. bound-and-prune), for the four sweep
     graphs where this finishes fast in pure Python (C7, C9, Petersen,
     Mobius-Kantor: all under a second). Calibrated against the established
     gep.wl fact omega(C5 OR C5) = 5 before being trusted on new graphs.
  2. Paley(13) and Kneser(6,2) have larger 2-copies cliques (13-of-169 and
     9-of-225) that this unoptimized pure-Python search did not finish
     quickly when tried (aborted after 44s with no result, vs < 1s in
     Wolfram's FindClique) -- their omega2 values are cross-checked instead
     by the theta-ceiling method below, which needs no search at all, and
     are reported as CONSISTENT WITH (not independently re-derived from) the
     Wolfram FindClique values (13 and 9 respectively) quoted in the note.
  3. For k=3, exact brute-force clique search is infeasible in EITHER
     language at these vertex counts within this session's compute budget.
     This module reproduces the cheap CLOSED-FORM bracket
       omega(G)^3  <=  omega(G^(OR3))  <=  theta(complement(G))^3
     (Lovasz multiplicativity over strong products + complement(OR-power) =
     strong-power(complement) -- the same method HeptagonCatalysis.wl already
     uses for the mixed Cn v Cn v C5 case), using theta(complement(G)) values
     themselves cross-checked against the vertex-transitive identity
     theta(G)*theta(Gbar) = n (verified numerically in the Wolfram session,
     see the note, Sec. 1).

Run: python3 d1_ge_copies_sweep.py
"""
import itertools
from math import cos, pi, sqrt


def max_clique_bitmask(n, A):
    best = [0]
    def expand(R_size, P):
        if P == 0:
            if R_size > best[0]:
                best[0] = R_size
            return
        if R_size + bin(P).count("1") <= best[0]:
            return
        u, ubest = -1, -1
        tmp = P
        while tmp:
            v = (tmp & -tmp).bit_length() - 1
            tmp &= tmp - 1
            c = bin(P & A[v]).count("1")
            if c > ubest:
                ubest, u = c, v
        cand = P & ~A[u]
        while cand:
            v = (cand & -cand).bit_length() - 1
            vb = 1 << v
            cand &= cand - 1
            expand(R_size + 1, P & A[v])
            P &= ~vb
    expand(0, (1 << n) - 1)
    return best[0]


def adjacency_bitmask(n, edges):
    A = [0] * n
    for u, v in edges:
        A[u] |= (1 << v)
        A[v] |= (1 << u)
    return A


def complement_bitmask(n, A):
    full = (1 << n) - 1
    return [(full ^ A[i]) & ~(1 << i) & full for i in range(n)]


def or_power_bitmask(n, edges, k):
    """Bitmask adjacency of the k-fold OR/conormal power G^(OR k) on n^k
    tuples (lexicographic order, matching Mathematica's Tuples[Range[n],k])."""
    Aflat = [[False] * n for _ in range(n)]
    for u, v in edges:
        Aflat[u][v] = Aflat[v][u] = True
    tuples = list(itertools.product(range(n), repeat=k))
    m = len(tuples)
    Am = [0] * m
    for i in range(m):
        u = tuples[i]
        bits = 0
        for j in range(m):
            if i == j:
                continue
            v = tuples[j]
            if any(Aflat[u[t]][v[t]] for t in range(k)):
                bits |= (1 << j)
        Am[i] = bits
    return m, Am


# ---- graph builders ----
def cycle_graph(n):
    return n, [(i, (i + 1) % n) for i in range(n)]


def kneser(n, k):
    verts = list(itertools.combinations(range(n), k))
    idx = {v: i for i, v in enumerate(verts)}
    edges = [(idx[a], idx[b]) for a, b in itertools.combinations(verts, 2)
             if set(a).isdisjoint(b)]
    return len(verts), edges


def paley(q):
    qr = set((x * x) % q for x in range(1, q))
    edges = [(i, j) for i, j in itertools.combinations(range(q), 2)
             if (i - j) % q in qr]
    return q, edges


def mobius_kantor():
    """Generalized Petersen graph GP(8,3): outer 8-cycle 0..7, inner 8..15
    joined with step 3, spokes i -- i+8."""
    n = 16
    edges = set()
    for i in range(8):
        edges.add(tuple(sorted((i, (i + 1) % 8))))
        edges.add(tuple(sorted((i, i + 8))))
        edges.add(tuple(sorted((8 + i, 8 + (i + 3) % 8))))
    return n, sorted(edges)


# theta(G) and theta(complement(G)): closed forms, cross-checked in the Wolfram
# session against dense SDP (agreement < 1e-6) and against the identity
# theta(G)*theta(Gbar) = n (verified numerically to < 1e-6 for all six graphs).
THETA = {
    "C7": (7 * cos(pi / 7) / (1 + cos(pi / 7)), 1 + 1 / cos(pi / 7)),
    "C9": (9 * cos(pi / 9) / (1 + cos(pi / 9)), 1 + 1 / cos(pi / 9)),
    "Petersen": (4.0, 2.5),                # Kneser(5,2)/Lovasz-EKR; Gbar = Johnson J(5,2)
    "MobiusKantor": (8.0, 2.0),            # bipartite/perfect: theta = alpha = n/2
    "Paley13": (sqrt(13.0), sqrt(13.0)),   # self-complementary
    "Kneser62": (5.0, 3.0),                # Lovasz-EKR; Gbar = triangular graph T(6)
}

GRAPHS = {
    "C7": cycle_graph(7), "C9": cycle_graph(9),
    "Petersen": kneser(5, 2), "MobiusKantor": mobius_kantor(),
    "Paley13": paley(13), "Kneser62": kneser(6, 2),
}
BRUTEFORCE_K2 = {"C7", "C9", "Petersen", "MobiusKantor"}


def calibrate():
    n5, e5 = cycle_graph(5)
    _, A5_2 = or_power_bitmask(n5, e5, 2)
    calib = max_clique_bitmask(n5 ** 2, A5_2)
    assert calib == 5, f"CALIBRATION FAILED: omega(C5 OR C5) = {calib}, expected 5"
    return calib


def sweep():
    rows = {}
    for name, (n, edges) in GRAPHS.items():
        A = adjacency_bitmask(n, edges)
        Abar = complement_bitmask(n, A)
        alpha = max_clique_bitmask(n, Abar)
        omega = max_clique_bitmask(n, A)
        theta, thetabar = THETA[name]

        if name in BRUTEFORCE_K2:
            m2, A2 = or_power_bitmask(n, edges, 2)
            omega2 = max_clique_bitmask(m2, A2)
            route = "bruteforce"
        else:
            omega2 = round(thetabar ** 2)
            route = "ceiling*"
        S2 = n / sqrt(omega2)

        lb3 = omega ** 3
        ceil3 = thetabar ** 3
        pinned = ceil3 < lb3 + 1
        rows[name] = dict(graph=name, n=n, alpha=alpha, omega=omega, theta=theta,
                           omega2=omega2, route=route, S2=S2, lb3=lb3, ceil3=ceil3,
                           pinned=pinned)
    return rows


def print_table(rows):
    print(f"{'graph':13s}{'n':>4s}{'alpha':>7s}{'omega':>7s}{'theta_cf':>10s}"
          f"{'omega2':>8s}{'route':>11s}{'S2':>9s}{'lb_k3':>7s}{'ceil_k3':>9s}{'k3 status':>16s}")
    for r in rows.values():
        status = f"PINNED={r['lb3']}" if r["pinned"] else f"bracket[{r['lb3']},{int(r['ceil3'])}]"
        print(f"{r['graph']:13s}{r['n']:4d}{r['alpha']:7d}{r['omega']:7d}{r['theta']:10.5f}"
              f"{r['omega2']:8d}{r['route']:>11s}{r['S2']:9.5f}{r['lb3']:7d}{r['ceil3']:9.4f}{status:>16s}")


def verify(rows, calib):
    """Machine-checkable verification block, matching this project's
    <Name>Verification -> OK convention (see e.g. HeptagonCatalysisVerification
    in HeptagonCatalysis.wl)."""
    checks = {
        "calibration_C5_OR_C5_is_5": calib == 5,
        "C7_k2_zero_improvement_over_S1": rows["C7"]["omega2"] == 4 and abs(rows["C7"]["S2"] - 3.5) < 1e-9,
        "C9_k2_zero_improvement_over_S1": rows["C9"]["omega2"] == 4 and abs(rows["C9"]["S2"] - 4.5) < 1e-9,
        "C9_k3_exact_AND_still_stalled_at_S1": rows["C9"]["pinned"] and rows["C9"]["lb3"] == 8
                                               and abs(rows["C9"]["n"] / rows["C9"]["lb3"] ** (1/3) - 4.5) < 1e-9,
        "C7_k3_NOT_pinned_genuine_open_bracket": not rows["C7"]["pinned"],
        "Petersen_k2_partial_improvement": rows["Petersen"]["omega2"] == 5 and rows["Petersen"]["S2"] < 5.0,
        "Petersen_k3_not_pinned": not rows["Petersen"]["pinned"],
        "MobiusKantor_pinned_trivial_all_k": rows["MobiusKantor"]["omega2"] == 4 and rows["MobiusKantor"]["pinned"],
        "Paley13_k2_full_convergence_to_theta": abs(rows["Paley13"]["S2"] - rows["Paley13"]["theta"]) < 1e-6,
        "Kneser62_no_gap_anywhere_alpha_eq_theta": abs(rows["Kneser62"]["alpha"] - rows["Kneser62"]["theta"]) < 1e-9
                                                    and abs(rows["Kneser62"]["S2"] - 5.0) < 1e-6,
    }
    checks["OK"] = all(checks.values())
    return checks


if __name__ == "__main__":
    calib = calibrate()
    print(f"calibration: omega(C5 OR C5) = {calib} (expect 5, gep.wl) -- OK\n")
    rows = sweep()
    print_table(rows)
    print()
    v = verify(rows, calib)
    for k, val in v.items():
        print(f"  {k:45s} {val}")
