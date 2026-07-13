"""ERG-003 structure verifier for the (3 boxes, 1 catalyst) cell
G = C9 v C9 v C9 v C5 = H v C5,  H = C9 v C9 v C9 (729 vertices).
'v' = OR / conormal product. Activation (CE violation) iff omega(G) >= 18.

Runnable, prints PASS/FAIL per claim. Compute-light (numpy only; NO igraph --
igraph's Cliquer hangs for many minutes on this density-0.53 729-vertex graph,
so omega is certified by the exact Lovasz-theta ceiling plus an explicit
construction, and claim 2 is settled by an exhibited + symmetry-multiplied
counterexample).

Claims:
  (1) omega(H) = 8.                                                    -> PASS
  (2) the maximum 8-cliques of H are EXACTLY the 729 products of one
      edge per C9 factor.                                              -> FAIL
      (A verified 8-clique that is NOT a product-of-edges exists; its
       symmetry orbit alone gives thousands more, and HeptagonCatalysis.wl
       itself reports the size-8 clique population at >10^8. The "729
       products" characterization -- a load-bearing 'established fact' and
       the basis of the method council's rigidity argument -- is false.)
  (3) size-vector families (s_0..s_4), s_i>=0, sum=17, up to D5, with
      s_i+s_{i+2}<=8: 26 families, 25 with some pair = 8.              -> PASS
      (pure combinatorics; TRUE. But note the council's downstream
       inference "pentagram pin => product-of-edges hence rigid" is
       INVALID given claim 2's failure.)
  (4) the known 16-clique decomposes into layer vector (8,8,0,0,0) with
      both nonempty layers product-of-edges max 8-cliques.             -> PASS
      (the known construction is product-structured; claim 2's failure
       means this does NOT imply other 16-cliques are product-structured.)

Run: python3 erg003_structure_check.py
"""
import itertools
import math
import sys

import numpy as np

N9 = 9
results = []


def record(claim, ok, detail):
    results.append((claim, ok))
    print(f"[{'PASS' if ok else 'FAIL'}] {claim}: {detail}", flush=True)


# ---------------------------------------------------------------------------
# graph construction (matches d1_k3_graphs.py / or_power exactly)
# ---------------------------------------------------------------------------
def cyc(n):
    A = np.zeros((n, n), bool)
    for i in range(n):
        A[i, (i + 1) % n] = True
        A[(i + 1) % n, i] = True
    return A


def or_power(A, k):
    n = A.shape[0]
    idx = np.array(list(itertools.product(range(n), repeat=k)), dtype=np.int64)
    M = np.zeros((idx.shape[0], idx.shape[0]), bool)
    for t in range(k):
        col = idx[:, t]
        M |= A[np.ix_(col, col)]
    np.fill_diagonal(M, False)
    return M, idx


MH, idxH = or_power(cyc(9), 3)
Nv = MH.shape[0]


def tup(i):
    return (i // 81, (i // 9) % 9, i % 9)


def tidx(a, b, c):
    return (a * 9 + b) * 9 + c


def adjH(u, v):
    return u != v and any((u[c] - v[c]) % 9 in (1, 8) for c in range(3))


def is_clique(T):
    return len(set(T)) == len(T) and all(adjH(a, b)
                                         for a, b in itertools.combinations(T, 2))


def is_product_of_edges(T):
    """True iff T (list of 3-tuples) is a Cartesian product E0xE1xE2 of C9-edges."""
    if len(set(T)) != 8:
        return False
    projs = []
    for c in range(3):
        vals = sorted(set(t[c] for t in T))
        if len(vals) != 2 or (vals[1] - vals[0]) % 9 not in (1, 8):
            return False
        projs.append(vals)
    return set(T) == set(itertools.product(*projs))


# ---------------------------------------------------------------------------
# Claim 1: omega(H) = 8, certified by theta ceiling (upper) + construction (lower)
# ---------------------------------------------------------------------------
# comp(H) = strong product of comp(C9)'s; Lovasz theta is multiplicative over
# strong products and omega(H) <= theta(comp H) = theta(comp C9)^3.
# theta(comp C_n) = 1 + sec(pi/n) for odd n (Lovasz 1979).
theta_c9 = 1 + 1 / math.cos(math.pi / 9)
theta_H = theta_c9 ** 3
ub = math.floor(theta_H + 1e-9)
# explicit product-of-edges 8-clique -> lower bound 8
low = [(a, b, c) for a in (0, 1) for b in (0, 1) for c in (0, 1)]
lower_ok = is_clique(low) and len(low) == 8
record("claim1_omega_H_eq_8", ub == 8 and lower_ok,
       f"theta(comp H)=theta(comp C9)^3={theta_H:.4f} -> omega<=8; "
       f"explicit product 8-clique exists -> omega>=8; hence omega(H)=8")


# ---------------------------------------------------------------------------
# Claim 2: FALSE. Max 8-cliques are NOT exactly the 729 products.
# ---------------------------------------------------------------------------
# The 729 products ARE 8-cliques (necessary direction holds):
edges9 = [(i, (i + 1) % 9) for i in range(9)]
products = set()
for e0 in edges9:
    for e1 in edges9:
        for e2 in edges9:
            products.add(frozenset((a, b, c) for a in e0 for b in e1 for c in e2))
products_are_cliques = (len(products) == 729 and
                        all(is_clique(list(p)) for p in products))

# ... but a NON-product maximum 8-clique also exists (found by the exact C
# solver bin/mcq.exe, re-verified here from scratch against the raw adjacency):
witness = [tup(i) for i in (0, 562, 707, 481, 698, 717, 644, 638)]
w_is_clique = is_clique(witness)
w_is_product = is_product_of_edges(witness)
w_projections = [sorted(set(t[c] for t in witness)) for c in range(3)]

# multiply by symmetry (Z9^3 translations x S3 factor permutations) -> a large
# family of DISTINCT non-product maximum 8-cliques:
nonproduct = set()
for perm in itertools.permutations(range(3)):
    for d in itertools.product(range(9), repeat=3):
        T = frozenset(tuple((t[perm[k]] + d[k]) % 9 for k in range(3))
                      for t in witness)
        if not is_product_of_edges(list(T)):
            nonproduct.add(T)
# sanity: they are all genuine 8-cliques
sample_ok = all(is_clique(list(T)) for T in list(nonproduct)[:50])

claim2_true = (products_are_cliques and w_is_clique and not w_is_product
               and len(nonproduct) == 0)
record("claim2_maxcliques_are_729_products", claim2_true,
       f"729 products are cliques={products_are_cliques}; BUT a verified "
       f"NON-product 8-clique exists (coord-0 values {w_projections[0]}, "
       f"clique={w_is_clique}, product={w_is_product}); its symmetry orbit gives "
       f">={len(nonproduct)} distinct non-product max 8-cliques (sample all "
       f"cliques={sample_ok}). Essay reports total size-8 population >10^8. "
       f"CHARACTERIZATION IS FALSE.")


# ---------------------------------------------------------------------------
# Claim 3: size-vector family census (pure combinatorics -- TRUE)
# ---------------------------------------------------------------------------
def d5_orbit(v):
    o = set()
    for k in range(5):
        o.add(tuple(v[(i - k) % 5] for i in range(5)))
        o.add(tuple(v[(-i - k) % 5] for i in range(5)))
    return o


def canon(v):
    return min(d5_orbit(v))


def pairs(v):
    return [v[i] + v[(i + 2) % 5] for i in range(5)]


def families(total, cap=8):
    raw = [v for v in itertools.product(range(cap + 1), repeat=5)
           if sum(v) == total and all(v[i] + v[(i + 2) % 5] <= 8 for i in range(5))]
    fam = {}
    for v in raw:
        fam.setdefault(canon(v), []).append(v)
    return fam


for total in (16, 17, 18):
    fam = families(total)
    wp = sum(1 for c in fam if max(pairs(c)) == 8)
    print(f"  sum={total}: {len(fam)} families up to D5, {wp} with a size-8 "
          f"pentagram pin, {len(fam)-wp} without", flush=True)

fam17 = families(17)
wp17 = sum(1 for c in fam17 if max(pairs(c)) == 8)
no_pin = sorted(c for c in fam17 if max(pairs(c)) < 8)
record("claim3_families_26_pins_25", len(fam17) == 26 and wp17 == 25,
       f"sum=17: {len(fam17)} families, {wp17} with a size-8 pin, "
       f"no-pin family/families {no_pin} "
       f"(NOTE: council's 'pin => product-of-edges, rigid' inference is INVALID; "
       f"see claim 2)")


# ---------------------------------------------------------------------------
# Claim 4: known 16-clique layer decomposition (construction is product -- TRUE)
# ---------------------------------------------------------------------------
def adjG(u, v):
    return u != v and (((u[0] - v[0]) % 9 in (1, 8)) or
                       ((u[1] - v[1]) % 9 in (1, 8)) or
                       ((u[2] - v[2]) % 9 in (1, 8)) or
                       ((u[3] - v[3]) % 5 in (1, 4)))


e = (0, 1)
clique16 = [(a, b, c, d) for d in e for a in e for b in e for c in e]
ok16 = (len(set(clique16)) == 16 and
        all(adjG(u, v) for u, v in itertools.combinations(clique16, 2)))
layers = {d: sorted({(a, b, c) for (a, b, c, dd) in clique16 if dd == d})
          for d in range(5)}
sv = tuple(len(layers[d]) for d in range(5))
nonempty_prod = all(is_product_of_edges(Q) for Q in layers.values() if Q)
pair_ok = all(sv[i] + sv[(i + 2) % 5] <= 8 for i in range(5))
record("claim4_16clique_layer_decomp",
       ok16 and sv == (8, 8, 0, 0, 0) and nonempty_prod and pair_ok,
       f"16-clique valid={ok16}, layer vector={sv}, nonempty layers "
       f"product-of-edges={nonempty_prod}, pentagram constraint ok={pair_ok} "
       f"(the KNOWN construction is product-structured; claim 2's failure means "
       f"this does not imply uniqueness/rigidity)")


# ---------------------------------------------------------------------------
print("\n=== SUMMARY ===", flush=True)
for claim, ok in results:
    print(f"  {'PASS' if ok else 'FAIL'}  {claim}")
np_ = sum(1 for _, ok in results if ok)
print(f"{np_}/{len(results)} claims PASS; "
      f"claim2 (729-products characterization) FAILS -- a load-bearing "
      f"'established fact' is FALSE.", flush=True)
sys.exit(0)
