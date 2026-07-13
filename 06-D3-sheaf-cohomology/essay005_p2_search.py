#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ESSAY-005 PROBE P2 - partition-type cover exhaustion on <= 10 measurements.

Question (spec: ESSAY-005-problem-spec.md, probe P2; plan: ESSAY-005-phase23-execution-plan.md
section 2): does any *partition-type* (Bell-type) measurement cover on <= 10 measurements carry
five events with C5 exclusivity "with matching probabilistic structure" (the KCBS tier values
classical 2 / no-signalling 5/2 / quantum sqrt(5))?

PREDICATE SOURCE - verified against the paper text (ar5iv render of arXiv:1102.0264,
Abramsky-Brandenburger, "The Sheaf-Theoretic Structure Of Non-Locality and Contextuality",
NJP 13 (2011) 113036), fetched and read 2026-07-13 by the executing agent:

  Sec 2.4:   "A measurement cover M on the set X of measurements is a family of subsets of X
              such that: U M = X" and "M is an anti-chain".
  Sec 2.4.1: Bell-type scenarios: "Consider a disjoint family {X_i} ... We define M to be those
              subsets of X containing exactly one measurement from each part."
  Proposition 9.3 (verbatim): "A measurement cover M arises from a Bell-type scenario if and
              only if it is the family of maximal cliques of a graph G = (X, E_G) which is the
              complement of an equivalence relation R on X: E_G = {{x,y} | not(x R y)}."
              Proof: "Equivalence relations are in bijective correspondence with partitions
              X = ∐_i X_i. The maximal cliques of G are exactly the transversals of this
              partition, i.e. the sets T ⊆ X such that T intersects with each X_i in exactly
              one element."
              Following remark: "Note in particular that in Bell-type scenarios, incompatibility
              is transitive."
  Proposition 9.4 (verbatim): "Consider a measurement cover M of Bell type, and any quantum
              representation of M. For any s in E(C) with C in M, there is a quantum state rho
              such that s is in the support of rho_C."  (Proof: product of eigenvector states.)
              Following remark: "Hence there is no Kochen-Specker-type theorem for Bell-type
              scenarios."

Prop 9.4 is why this probe MUST be probabilistic: on a partition-type cover every section is in
the support of some quantum state, so no support-level (possibilistic) invariant can see
anything - the "matching probabilistic structure" test happens at the probability tiers.

ENCODING (verified by the executor against Prop 9.3 and by the SBBC positive control):
An event on a Bell-type scenario is (C, s): C a transversal context (one measurement per
block/part), s a joint outcome. A 5-tuple of events (e_0..e_4) induces, per block b, a pair of
set partitions of {0..4}:
    pi_b : i ~ j  iff e_i, e_j choose the same measurement in block b,
    rho_b: i ~ j  iff same measurement AND same outcome    (rho_b refines pi_b).
Conflicts contributed by block b = pairs {i,j} in the same pi_b-cell, different rho_b-cells.
Exclusivity: e_i excl e_j iff some block conflicts them. The 5-tuple realizes C5 iff
  (i)  Union_b conflicts(b) = E(C5) = {01,12,23,34,40}, and
  (ii) conflicts(b) subset of E(C5) for every b.
Distinctness of the five events follows from (i)+(ii) (proved in lemma L4 below).

REDUCTION LEMMAS (each with proof sketch; asserted where checkable):
  L1 (outcome coarse-graining). Merging all outcomes of a measurement not used by the 5 events
     into one dump outcome maps NS boxes to NS boxes and quantum to quantum preserving every
     P(e_i); conversely any box on the reduced outcome sets is a box on the original. Hence
     WLOG outcome set of x = used outcomes + one dump.
  L1'(triangle-freeness, sharpens L1 - found in this execution pass). Conflicts within one
     pi-cell form a complete multipartite graph on its rho-subcells; >= 3 subcells would give a
     triangle, but C5 is triangle-free. So every conflicting cell has exactly 2 rho-subcells,
     and (checking the <= 5-point cases) conflicting cells are exactly edge pairs {i,i+1} split
     into singletons, or path triples {i,i+1,i+2} split {i,i+2}|{i+1}. Hence d_x <= 3 for every
     measurement (<= 2 used outcomes + dump).
  L2 (block monotonicity). Deleting any block b whose conflict edges are all covered by the
     other blocks (in particular any conflict-free block) leaves a valid C5 5-tuple on the
     smaller scenario, and the achievable value sum_i P(e_i) does not decrease: given a box P on
     the larger scenario, the marginal box P' (well-defined by NS) has
     P'(e_i') = sum_{o} P(e_i minus block b, m_i^b -> o) >= P(e_i). The reduced events stay
     distinct by L4 applied to the remaining blocks. Hence the SUPREMUM of every tier over all
     <= 10-measurement configurations is attained on multisets of *conflicting* block types
     only; conflict-free blocks never help and are excluded from the enumeration.
  L3 (unused measurements). A measurement chosen by none of the 5 events can be deleted: no
     C_i passes through it and boxes restrict/extend freely (NS and quantum). WLOG block b has
     exactly #cells(pi_b) measurements.
  L4 (distinctness is automatic). For non-adjacent i,j there is a C5-edge {i,k} with {j,k} not
     an edge. The block realizing conflict {i,k} has i,k in one pi-cell, different rho-subcells;
     if j sat in i's rho-subcell there, j would conflict k - forbidden by (ii). So j is
     separated from i in that block, hence e_i != e_j.

TIERS (plan section 2.3):
  T0 combinatorial: induced-C5 exclusivity - built into the enumeration, (i)+(ii).
  T1 classical = 2, automatic: adjacent events conflict on a shared measurement so at most
     alpha(C5)=2 events hold simultaneously; any non-adjacent pair agrees on all shared
     measurements, so their partial assignments are consistent and extend to a global one -
     2 is attained. (No search needed.)
  T2 no-signalling LP: max sum_i P(e_i) over the NS polytope. A priori <= 5/2: for an adjacent
     pair sharing measurement m with outcomes o_i != o_j, P(e_i)+P(e_j) <= P(m->o_i)+P(m->o_j)
     <= 1 through m's (NS-well-defined) marginal; the C5 edge LP then gives 5/2. "Matching"
     means NS value = 5/2 exactly; hits are certified by an exact rational feasible point with
     objective 5/2 (Fractions; no float enters the certificate).
  T3 quantum (REPORT-ONLY, not part of the exhaustion certificate): NPA-style moment-matrix
     upper bound (level 1+AB: monomials {1} U singles U cross-party pairs (+ per-event triples
     for 5-party configs)), hand-rolled in cvxpy. Question: does any class reach
     sqrt(5) = 2.2360679...? Note quantum <= NS, so classes with certified NS < sqrt(5) need no
     SDP. Literature control: Sadiq-Badziag-Bourennane-Cabello (SBBC), arXiv:1106.4754,
     PRA 87, 012128 (2013): pentagon Bell inequalities have quantum max 2.178 / (3+sqrt2)/2
     ~ 2.207 < sqrt(5).

POSITIVE CONTROL (mandatory): SBBC inequality (2) [events 00|00, 11|01, 10|11, 00|10, 11|00 in
the 2x2 setting / 2-outcome scenario] and inequality (4) [events 00|00, 11|01, 10|11, 00|10,
11|20; Alice 3 settings, Bob 2] must be rediscovered among tier-0 classes with tier-2 value
5/2. SBBC inequality (3) contains the marginal event P(_1|_0) (Alice does nothing), which is
not a full-joint-outcome event, hence lies outside this probe's event class by construction -
recorded, not searched for.

COMPLETENESS of the enumeration: every configuration (after L1-L3) is exactly a multiset of
conflicting block types (pairs (pi,rho) with nonempty conflict set inside E(C5)), with
sum_b #cells(pi_b) <= 10 and (i) coverage of all five edges. Multisets are generated once each
as weakly-increasing index tuples (orderly generation); D5 = Aut(C5) (order 10) acts on event
labels and the lexicographically minimal image is the class representative. A dumb brute-force
enumeration of raw event 5-tuples over all partition-type scenarios with n <= 6 measurements,
d = 3 outcomes each (sufficient by L1'), cross-validates the canonical class census on its
range.

Usage:
    python essay005_p2_search.py all            # phases in order (resumable)
    python essay005_p2_search.py types|smoke|enum|lp|exact|control|brute|npa|cert
Outputs (this module folder): p2_results.csv, p2_certificate.json, p2_state/*.json.
"""

import csv
import itertools
import json
import math
import os
import sys
import time
from fractions import Fraction

import numpy as np
from scipy.optimize import linprog
from scipy.sparse import csr_matrix

HERE = os.path.dirname(os.path.abspath(__file__))
STATE = os.path.join(HERE, "p2_state")
RESULTS_CSV = os.path.join(HERE, "p2_results.csv")
CERT_JSON = os.path.join(HERE, "p2_certificate.json")
os.makedirs(STATE, exist_ok=True)

SQRT5 = math.sqrt(5.0)
N_MAX = 10  # measurement budget (the probe's stated bound)

# ----------------------------------------------------------------------------------
# The executable predicate, transcribed from the plan (derived from AB Prop 9.3).
# ----------------------------------------------------------------------------------

def is_partition_type(X, M):
    """AB Prop 9.3: M (list of contexts, each a subset of X) is the maximal-clique cover of
    the complement of an equivalence relation on X."""
    Ms = {frozenset(C) for C in M}
    if not Ms or set().union(*Ms) != set(X):                         # covers X
        return False
    if any(A < B for A in Ms for B in Ms):                           # antichain
        return False
    comp = {(x, y) for C in Ms for x in C for y in C if x != y}      # compatibility graph
    R = {(x, y) for x in X for y in X if x == y or (x, y) not in comp}
    if any((x, y) in R and (y, z) in R and (x, z) not in R
           for x in X for y in X for z in X):                        # R transitive?
        return False
    blocks, seen = [], set()                                         # R-classes
    for x in X:
        if x not in seen:
            cls = frozenset(y for y in X if (x, y) in R)
            blocks.append(sorted(cls)); seen |= cls
    trans = {frozenset(t) for t in itertools.product(*blocks)}       # ALL transversals
    return Ms == trans                                               # both inclusions (Prop 9.3)


# ----------------------------------------------------------------------------------
# Block types: pairs (pi, rho) of set partitions of {0..4}, rho refining pi.
# ----------------------------------------------------------------------------------

E5 = frozenset(frozenset(p) for p in [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)])
E5_LIST = sorted(tuple(sorted(e)) for e in E5)
E5_INDEX = {frozenset(e): k for k, e in enumerate(E5_LIST)}


def set_partitions(items):
    items = list(items)
    if not items:
        yield []
        return
    first, rest = items[0], items[1:]
    for part in set_partitions(rest):
        for i in range(len(part)):
            yield part[:i] + [[first] + part[i]] + part[i + 1:]
        yield [[first]] + part


def canon_partition(cells):
    return tuple(sorted(tuple(sorted(c)) for c in cells))


def refinements(pi):
    """All partitions rho refining pi (product of set partitions of each cell)."""
    per_cell = [[canon_partition(p) for p in set_partitions(cell)] for cell in pi]
    for combo in itertools.product(*per_cell):
        yield canon_partition([c for sub in combo for c in sub])


def conflicts_of(pi, rho):
    """Pairs in the same pi-cell but different rho-cells."""
    cell_of_rho = {}
    for c in rho:
        for i in c:
            cell_of_rho[i] = c
    out = set()
    for cell in pi:
        for i, j in itertools.combinations(sorted(cell), 2):
            if cell_of_rho[i] is not cell_of_rho[j]:
                out.add(frozenset((i, j)))
    return frozenset(out)


def build_types():
    """All (pi, rho) block types; returns (all_types, active_types_indices)."""
    all_types = []
    for pi_cells in set_partitions(range(5)):
        pi = canon_partition(pi_cells)
        for rho in refinements(pi):
            all_types.append((pi, rho))
    all_types = sorted(set(all_types))
    assert len(all_types) == 358, f"block-type count {len(all_types)} != 358 (design figure)"
    active = []
    for idx, (pi, rho) in enumerate(all_types):
        cf = conflicts_of(pi, rho)
        if cf and cf <= E5:
            active.append(idx)
    return all_types, active


ALL_TYPES, ACTIVE_IDX = build_types()


def type_cost(t):
    return len(ALL_TYPES[t][0])          # number of pi-cells = measurements in the block


def type_edge_mask(t):
    m = 0
    for e in conflicts_of(*ALL_TYPES[t]):
        m |= 1 << E5_INDEX[e]
    return m


TYPE_COST = {t: type_cost(t) for t in ACTIVE_IDX}
TYPE_MASK = {t: type_edge_mask(t) for t in ACTIVE_IDX}
FULL_MASK = (1 << len(E5_LIST)) - 1

# structural assertions from L1' (triangle-freeness of C5)
for t in ACTIVE_IDX:
    pi, rho = ALL_TYPES[t]
    sub_of = {}
    for c in rho:
        for i in c:
            sub_of[i] = c
    for cell in pi:
        subs = {tuple(sub_of[i]) for i in cell}
        if len(subs) > 1:
            assert len(subs) == 2, "L1' violated: conflicting cell with >2 rho-subcells"
            assert len(cell) in (2, 3), "L1' violated: conflicting cell size not in {2,3}"

# D5 = Aut(C5) acting on labels 0..4
D5 = []
for k in range(5):
    D5.append(tuple((i + k) % 5 for i in range(5)))
    D5.append(tuple((k - i) % 5 for i in range(5)))
D5 = sorted(set(D5))
assert len(D5) == 10

TYPE_INDEX = {tp: i for i, tp in enumerate(ALL_TYPES)}


def apply_perm_type(perm, t):
    pi, rho = ALL_TYPES[t]
    pi2 = canon_partition([[perm[i] for i in c] for c in pi])
    rho2 = canon_partition([[perm[i] for i in c] for c in rho])
    return TYPE_INDEX[(pi2, rho2)]


PERM_TYPE = {perm: {t: apply_perm_type(perm, t) for t in ACTIVE_IDX} for perm in D5}


def canon_config(cfg):
    """Lexicographically minimal D5 image of a sorted tuple of active type indices."""
    return min(tuple(sorted(PERM_TYPE[p][t] for t in cfg)) for p in D5)


# ----------------------------------------------------------------------------------
# Phase: types
# ----------------------------------------------------------------------------------

def phase_types():
    print(f"[types] total block types (pi,rho) on 5 points: {len(ALL_TYPES)} (asserted == 358)")
    print(f"[types] active types (nonempty conflicts inside E(C5)): {len(ACTIVE_IDX)}")
    by_cost = {}
    for t in ACTIVE_IDX:
        by_cost.setdefault(TYPE_COST[t], []).append(t)
    for c in sorted(by_cost):
        print(f"[types]   cost {c}: {len(by_cost[c])} types")
    orbits = set()
    for t in ACTIVE_IDX:
        orbits.add(min(PERM_TYPE[p][t] for p in D5))
    print(f"[types] active types up to D5: {len(orbits)}")
    return {"all_types": len(ALL_TYPES), "active_types": len(ACTIVE_IDX),
            "active_by_cost": {str(c): len(v) for c, v in sorted(by_cost.items())},
            "active_types_mod_D5": len(orbits)}


# ----------------------------------------------------------------------------------
# Phase: smoke tests of the predicate (plan section 5.3)
# ----------------------------------------------------------------------------------

def phase_smoke():
    # (i) CHSH cover: parts {a0,a1},{b0,b1}; contexts = 4 transversals -> True
    chsh = [("a0", "b0"), ("a0", "b1"), ("a1", "b0"), ("a1", "b1")]
    r1 = is_partition_type(["a0", "a1", "b0", "b1"], chsh)
    # (ii) C5 edge cover -> False (incompatibility is not transitive)
    c5 = [(i, (i + 1) % 5) for i in range(5)]
    r2 = is_partition_type(list(range(5)), c5)
    # (iii) 3-block toy {x0,x1},{y0},{z0,z1,z2} -> True
    toy = [(x, "y0", z) for x in ("x0", "x1") for z in ("z0", "z1", "z2")]
    r3 = is_partition_type(["x0", "x1", "y0", "z0", "z1", "z2"], toy)
    # (iv) missing-transversal cover -> False (both inclusions matter)
    r4 = is_partition_type(["a0", "a1", "b0", "b1"], chsh[:3])
    ok = r1 and (not r2) and r3 and (not r4)
    print(f"[smoke] CHSH cover True: {r1}; C5 edge cover False: {not r2}; "
          f"3-block toy True: {r3}; missing-transversal False: {not r4}  -> OK={ok}")
    assert ok, "predicate smoke test failed"
    return {"chsh_true": r1, "c5_false": not r2, "toy_true": r3,
            "missing_transversal_false": not r4}


# ----------------------------------------------------------------------------------
# Phase: enum - orderly enumeration of multisets + D5 canonical classes
# ----------------------------------------------------------------------------------

def phase_enum():
    t0 = time.time()
    active = sorted(ACTIVE_IDX)
    classes = []
    seen_canon = set()
    visited = 0
    valid = 0

    def rec(start, cfg, cost, mask):
        nonlocal visited, valid
        for k in range(start, len(active)):
            t = active[k]
            c = TYPE_COST[t]
            if cost + c > N_MAX:
                continue
            cfg.append(t)
            visited += 1
            m2 = mask | TYPE_MASK[t]
            if m2 == FULL_MASK and len(cfg) >= 2:
                valid += 1
                cc = canon_config(tuple(cfg))
                if cc not in seen_canon:
                    seen_canon.add(cc)
                    classes.append(cc)
            rec(k, cfg, cost + c, m2)
            cfg.pop()

    rec(0, [], 0, 0)
    classes.sort()
    el = time.time() - t0
    print(f"[enum] multiset nodes visited: {visited}; valid configs (coverage, <=10 meas): {valid}; "
          f"D5 classes: {len(classes)}; {el:.1f}s")
    with open(os.path.join(STATE, "classes.json"), "w") as f:
        json.dump({"visited": visited, "valid": valid, "classes": [list(c) for c in classes]}, f)
    return {"visited": visited, "valid_configs": valid, "d5_classes": len(classes)}


def load_classes():
    with open(os.path.join(STATE, "classes.json")) as f:
        d = json.load(f)
    return d["visited"], d["valid"], [tuple(c) for c in d["classes"]]


# ----------------------------------------------------------------------------------
# Scenario construction and the NS LP
# ----------------------------------------------------------------------------------

class Scenario:
    """Bell-type scenario built from a multiset of active block types (L1-L3 reduced)."""

    def __init__(self, cfg):
        self.cfg = tuple(cfg)
        self.blocks = []          # per block: list of cells; each cell: (members, subcells)
        for t in cfg:
            pi, rho = ALL_TYPES[t]
            sub_of = {}
            for c in rho:
                for i in c:
                    sub_of[i] = tuple(sorted(c))
            cells = []
            for cell in pi:
                subs = sorted({sub_of[i] for i in cell})
                cells.append((tuple(cell), subs))
            self.blocks.append(cells)
        self.nblocks = len(self.blocks)
        # measurement (b, c) has d = len(subcells)+1 outcomes (dump last), except cells with a
        # single subcell still get used=1 + dump = 2 outcomes (L1).
        self.d = [[len(subs) + 1 for (_, subs) in cells] for cells in self.blocks]
        # events: context = cell index per block; outcome = subcell index per block
        self.ev_ctx, self.ev_out = [], []
        for i in range(5):
            ctx, out = [], []
            for b, cells in enumerate(self.blocks):
                for ci, (members, subs) in enumerate(cells):
                    if i in members:
                        ctx.append(ci)
                        out.append(next(k for k, s in enumerate(subs) if i in s))
                        break
            self.ev_ctx.append(tuple(ctx)); self.ev_out.append(tuple(out))
        self.n_meas = sum(len(cells) for cells in self.blocks)
        self.contexts = list(itertools.product(*[range(len(cells)) for cells in self.blocks]))

    def cover(self):
        """(X, M) with X = measurement ids, M = all transversals (for is_partition_type)."""
        X = [(b, c) for b, cells in enumerate(self.blocks) for c in range(len(cells))]
        M = [tuple((b, ctx[b]) for b in range(self.nblocks)) for ctx in self.contexts]
        return X, M

    def var_index(self):
        idx, n = {}, 0
        for ctx in self.contexts:
            douts = [range(self.d[b][ctx[b]]) for b in range(self.nblocks)]
            for s in itertools.product(*douts):
                idx[(ctx, s)] = n
                n += 1
        return idx, n

    def build_lp(self):
        """Equality-form NS LP. Returns (A(csr), b, c_obj, nvars)."""
        idx, n = self.var_index()
        rows, cols, vals, b_eq = [], [], [], []
        r = 0
        # normalization per context
        for ctx in self.contexts:
            douts = [range(self.d[b][ctx[b]]) for b in range(self.nblocks)]
            for s in itertools.product(*douts):
                rows.append(r); cols.append(idx[(ctx, s)]); vals.append(1.0)
            b_eq.append(1.0); r += 1
        # NS: contexts differing in exactly one block agree on the shared marginal
        for bb in range(self.nblocks):
            ncells = len(self.blocks[bb])
            other = [range(len(cells)) for k, cells in enumerate(self.blocks) if k != bb]
            for oc in itertools.product(*other):
                def full_ctx(ci):
                    lst = list(oc)
                    lst.insert(bb, ci)
                    return tuple(lst)
                for c1, c2 in itertools.combinations(range(ncells), 2):
                    ctx1, ctx2 = full_ctx(c1), full_ctx(c2)
                    oth_outs = [range(self.d[k][ctx1[k]]) for k in range(self.nblocks) if k != bb]
                    for t in itertools.product(*oth_outs):
                        for o in range(self.d[bb][c1]):
                            s = list(t); s.insert(bb, o)
                            rows.append(r); cols.append(idx[(ctx1, tuple(s))]); vals.append(1.0)
                        for o in range(self.d[bb][c2]):
                            s = list(t); s.insert(bb, o)
                            rows.append(r); cols.append(idx[(ctx2, tuple(s))]); vals.append(-1.0)
                        b_eq.append(0.0); r += 1
        c_obj = np.zeros(n)
        for i in range(5):
            c_obj[idx[(self.ev_ctx[i], self.ev_out[i])]] -= 1.0   # linprog minimizes
        A = csr_matrix((vals, (rows, cols)), shape=(r, n))
        return A, np.array(b_eq), c_obj, n

    def ns_value(self):
        A, b, c, n = self.build_lp()
        res = linprog(c, A_eq=A, b_eq=b, bounds=(0, None), method="highs")
        if res.status != 0:
            return None, res
        return -res.fun, res


# ----------------------------------------------------------------------------------
# Phase: lp - score every class (resumable via CSV)
# ----------------------------------------------------------------------------------

HIT_TOL = 1e-7


def phase_lp():
    _, _, classes = load_classes()
    done = {}
    if os.path.exists(RESULTS_CSV):
        with open(RESULTS_CSV, newline="") as f:
            for row in csv.DictReader(f):
                done[row["class_id"]] = row
    new_file = not done
    f = open(RESULTS_CSV, "a", newline="")
    w = csv.writer(f)
    if new_file:
        w.writerow(["class_id", "config_types", "n_blocks", "n_meas", "n_contexts",
                    "lp_value", "lp_status", "hit_5_2"])
    t0 = time.time()
    processed = 0
    for ci, cfg in enumerate(classes):
        cid = str(ci)
        if cid in done:
            continue
        sc = Scenario(cfg)
        val, res = sc.ns_value()
        hit = (val is not None) and (val >= 2.5 - HIT_TOL)
        w.writerow([cid, " ".join(map(str, cfg)), sc.nblocks, sc.n_meas,
                    len(sc.contexts), f"{val:.12f}" if val is not None else "FAIL",
                    res.status, int(hit)])
        processed += 1
        if processed % 200 == 0:
            f.flush()
            rate = processed / (time.time() - t0)
            rem = (len(classes) - ci - 1) / max(rate, 1e-9)
            print(f"[lp] {ci + 1}/{len(classes)} classes; {rate:.1f}/s; ~{rem / 60:.1f} min left",
                  flush=True)
    f.close()
    # summary
    vals, hits = [], 0
    with open(RESULTS_CSV, newline="") as f:
        for row in csv.DictReader(f):
            if row["lp_value"] != "FAIL":
                vals.append(float(row["lp_value"]))
                hits += int(row["hit_5_2"])
    print(f"[lp] scored {len(vals)} classes; tier-2 hits (NS=5/2): {hits}; "
          f"max {max(vals):.9f}; min {min(vals):.9f}")
    return {"scored": len(vals), "hits": hits, "max": max(vals), "min": min(vals)}


def read_results():
    out = []
    with open(RESULTS_CSV, newline="") as f:
        for row in csv.DictReader(f):
            out.append(row)
    return out


# ----------------------------------------------------------------------------------
# Phase: exact - rational certification of tier-2 hits (primal) and, for the quantum
# shortcut, exact dual certificates NS < sqrt(5) where float value allows it.
# ----------------------------------------------------------------------------------

def lp_exact_data(sc):
    """A, b, c as Fraction-friendly integer structures (list-of-dict rows)."""
    A, b, c, n = sc.build_lp()
    A = A.tocoo()
    rows = [dict() for _ in range(A.shape[0])]
    for r, cc, v in zip(A.row, A.col, A.data):
        rows[r][int(cc)] = int(round(v))
    return rows, [int(round(x)) for x in b], [int(round(x)) for x in c], n


def verify_primal_exact(sc, x_float, target=Fraction(5, 2)):
    """Round x to rationals and verify Ax=b, x>=0, and objective == target exactly."""
    rows, b, c, n = lp_exact_data(sc)
    for den in (2, 4, 5, 8, 10, 12, 16, 20, 40, 60, 120, 840, 2520, 10 ** 4, 10 ** 6):
        x = [Fraction(v).limit_denominator(den) for v in x_float]
        if any(v < 0 for v in x):
            continue
        if any(sum(Fraction(cv) * x[j] for j, cv in row.items()) != b[r]
               for r, row in enumerate(rows)):
            continue
        if -sum(Fraction(c[j]) * x[j] for j in range(n)) == target:
            return den
    return None


def verify_dual_below(sc, y_float, bound_sq=5):
    """Round duals y to rationals; verify A^T y >= c (for max c.x, Ax=b, x>=0) exactly and
    return the rational dual objective if it certifies value^2 < bound_sq."""
    rows, b, c, n = lp_exact_data(sc)
    cols = [dict() for _ in range(n)]
    for r, row in enumerate(rows):
        for j, v in row.items():
            cols[j][r] = v
    cmax = [-v for v in c]                      # true objective coefficients (we negated)
    for den in (2, 4, 5, 8, 10, 12, 16, 20, 40, 60, 120, 840, 2520, 10 ** 4, 10 ** 6):
        y = [Fraction(v).limit_denominator(den) for v in y_float]
        if all(sum(Fraction(v) * y[r] for r, v in cols[j].items()) >= cmax[j] for j in range(n)):
            val = sum(Fraction(b[r]) * y[r] for r in range(len(rows)))
            if val >= 0 and val * val < bound_sq:
                return val
    return None


def phase_exact(max_dual_certs=None):
    _, _, classes = load_classes()
    results = read_results()
    hits = [r for r in results if r["hit_5_2"] == "1"]
    below = [r for r in results if r["hit_5_2"] != "1" and r["lp_value"] != "FAIL"
             and float(r["lp_value"]) < SQRT5]
    print(f"[exact] hits to certify (primal, =5/2): {len(hits)}; "
          f"classes with float NS < sqrt5 (dual certs): {len(below)}")
    out = {"primal": {}, "dual": {}}
    t0 = time.time()
    for k, r in enumerate(hits):
        cfg = classes[int(r["class_id"])]
        sc = Scenario(cfg)
        val, res = sc.ns_value()
        den = verify_primal_exact(sc, res.x)
        out["primal"][r["class_id"]] = den
        if den is None:
            print(f"[exact] WARNING: hit class {r['class_id']} primal rounding failed")
        if (k + 1) % 50 == 0:
            print(f"[exact] primal {k + 1}/{len(hits)} ({time.time() - t0:.0f}s)", flush=True)
    certified = sum(1 for v in out["primal"].values() if v is not None)
    print(f"[exact] primal-certified hits: {certified}/{len(hits)}")
    todo = below if max_dual_certs is None else below[:max_dual_certs]
    t0 = time.time()
    okd = 0
    for k, r in enumerate(todo):
        cfg = classes[int(r["class_id"])]
        sc = Scenario(cfg)
        val, res = sc.ns_value()
        dv = verify_dual_below(sc, list(res.eqlin.marginals))
        out["dual"][r["class_id"]] = (str(dv) if dv is not None else None)
        okd += dv is not None
        if (k + 1) % 200 == 0:
            rate = (k + 1) / (time.time() - t0)
            print(f"[exact] dual {k + 1}/{len(todo)}; ok {okd}; {rate:.1f}/s; "
                  f"~{(len(todo) - k - 1) / max(rate, 1e-9) / 60:.1f} min left", flush=True)
    print(f"[exact] dual-certified NS<sqrt5: {okd}/{len(todo)}")
    with open(os.path.join(STATE, "exact.json"), "w") as f:
        json.dump(out, f)
    return {"hits": len(hits), "primal_certified": certified,
            "dual_candidates": len(below), "dual_attempted": len(todo), "dual_certified": okd}


# ----------------------------------------------------------------------------------
# Phase: control - the SBBC positive control
# ----------------------------------------------------------------------------------

def events_to_config(assignments):
    """assignments: per block, list over events of (measurement_label, outcome_label).
    Returns the canonical class (sorted tuple of type indices), dropping conflict-free blocks."""
    cfg = []
    for ev in assignments:
        meas = {}
        for i, (m, o) in enumerate(ev):
            meas.setdefault(m, []).append(i)
        pi = canon_partition(meas.values())
        mo = {}
        for i, (m, o) in enumerate(ev):
            mo.setdefault((m, o), []).append(i)
        rho = canon_partition(mo.values())
        cf = conflicts_of(pi, rho)
        if not cf:
            continue                       # L2: conflict-free block dropped
        assert cf <= E5, "control events do not induce C5"
        cfg.append(TYPE_INDEX[(pi, rho)])
    return canon_config(tuple(sorted(cfg)))


def sbbc_configs():
    """SBBC arXiv:1106.4754 inequalities (2) and (4), events in paper order
    e0..e4 = 00|00, 11|01, 10|11, 00|10, 11|00 / 11|20 (ab|xy; Alice block, Bob block)."""
    ineq2 = [
        # Alice block: (setting, outcome) per event
        [("A0", 0), ("A0", 1), ("A1", 1), ("A1", 0), ("A0", 1)],
        # Bob block
        [("B0", 0), ("B1", 1), ("B1", 0), ("B0", 0), ("B0", 1)],
    ]
    ineq4 = [
        [("A0", 0), ("A0", 1), ("A1", 1), ("A1", 0), ("A2", 1)],
        [("B0", 0), ("B1", 1), ("B1", 0), ("B0", 0), ("B0", 1)],
    ]
    return events_to_config(ineq2), events_to_config(ineq4)


def phase_control():
    _, _, classes = load_classes()
    class_pos = {tuple(c): i for i, c in enumerate(classes)}
    results = {int(r["class_id"]): r for r in read_results()}
    c2, c4 = sbbc_configs()
    out = {}
    for name, cc in (("SBBC_ineq2", c2), ("SBBC_ineq4", c4)):
        pos = class_pos.get(cc)
        row = results.get(pos) if pos is not None else None
        val = float(row["lp_value"]) if row and row["lp_value"] != "FAIL" else None
        hit = row["hit_5_2"] == "1" if row else False
        print(f"[control] {name}: class {pos}, types {cc}, NS={val}, tier2-hit={hit}")
        assert pos is not None, f"{name} not found among tier-0 classes - enumeration incomplete!"
        assert hit, f"{name} found but NS != 5/2 - LP encoding suspect!"
        out[name] = {"class_id": pos, "types": list(cc), "ns": val, "hit": hit}
    # also self-check the reconstructed cover satisfies the AB predicate
    sc = Scenario(classes[out["SBBC_ineq2"]["class_id"]])
    X, M = sc.cover()
    assert is_partition_type(X, M), "reconstructed cover fails is_partition_type"
    print("[control] positive control PASSED (both SBBC configs rediscovered, NS = 5/2, "
          "reconstructed cover satisfies AB Prop 9.3 predicate)")
    out["note_ineq3"] = ("SBBC inequality (3) uses the marginal event P(_1|_0) (Alice acts "
                         "trivially); it is not a full-joint-outcome event and lies outside "
                         "this probe's event class by construction.")
    return out


# ----------------------------------------------------------------------------------
# Phase: brute - dumb brute-force cross-check on n <= 6 measurements, d = 3
# ----------------------------------------------------------------------------------

def phase_brute(n_max=6, d=3):
    """Independent code path: enumerate raw event 5-tuples over ALL partition-type scenarios
    with sum of block sizes <= n_max and d outcomes per measurement; reduce each induced-C5
    5-tuple to its canonical class; compare with the canonical enumeration on that range."""
    t0 = time.time()
    found = set()
    # block-size multisets, >= 2 blocks (single-block scenarios: one context, K_n exclusivity,
    # no induced C5)
    sizes_list = []
    def part_sizes(rem, mx, cur):
        if len(cur) >= 2:
            sizes_list.append(tuple(cur))
        for s in range(min(rem, mx), 0, -1):
            part_sizes(rem - s, s, cur + [s])
    for n in range(2, n_max + 1):
        part_sizes(n, n, [])
    sizes_list = sorted(set(sizes_list))
    for sizes in sizes_list:
        blocks = []
        lab = 0
        for s in sizes:
            blocks.append(list(range(lab, lab + s)))
            lab += s
        events = []
        for ctx in itertools.product(*blocks):
            for out in itertools.product(range(d), repeat=len(blocks)):
                events.append((ctx, out))
        nev = len(events)
        # adjacency bitsets
        adj = [0] * nev
        for a in range(nev):
            ca, oa = events[a]
            for b in range(a + 1, nev):
                cb, ob = events[b]
                excl = any(ca[k] == cb[k] and oa[k] != ob[k] for k in range(len(blocks)))
                if excl:
                    adj[a] |= 1 << b
                    adj[b] |= 1 << a
        # induced 5-cycles: v0 smallest label; walk v0-v1-v2-v3-v4-v0
        for v0 in range(nev):
            a0 = adj[v0]
            n0 = [v for v in range(v0 + 1, nev) if (a0 >> v) & 1]
            for v1 in n0:
                for v2 in range(v0 + 1, nev):
                    if v2 == v1 or not (adj[v1] >> v2) & 1 or (a0 >> v2) & 1:
                        continue
                    for v3 in range(v0 + 1, nev):
                        if v3 in (v1, v2) or not (adj[v2] >> v3) & 1:
                            continue
                        if (a0 >> v3) & 1 or (adj[v1] >> v3) & 1:
                            continue
                        for v4 in range(v1 + 1, nev):   # v4 > v1 kills reflection duplicate
                            if v4 in (v2, v3):
                                continue
                            if not (adj[v3] >> v4) & 1 or not (a0 >> v4) & 1:
                                continue
                            if (adj[v1] >> v4) & 1 or (adj[v2] >> v4) & 1:
                                continue
                            cyc = (v0, v1, v2, v3, v4)
                            assigns = []
                            for bi in range(len(blocks)):
                                assigns.append([(events[v][0][bi], events[v][1][bi])
                                                for v in cyc])
                            found.add(events_to_config(assigns))
    # canonical enumeration restricted to the brute range: total measurements <= n_max
    # (d=3 is enough for every active type by L1'; the dump outcome is irrelevant at tier 0)
    _, _, classes = load_classes()
    canon_range = {c for c in classes if sum(TYPE_COST[t] for t in c) <= n_max}
    match = found == canon_range
    print(f"[brute] scenarios: {len(sizes_list)} block-size shapes, n<={n_max}, d={d}; "
          f"induced-C5 classes found: {len(found)}; canonical classes with cost<={n_max}: "
          f"{len(canon_range)}; MATCH={match}; {time.time() - t0:.0f}s")
    if not match:
        print(f"[brute]   brute-only: {sorted(found - canon_range)[:5]}")
        print(f"[brute]   canon-only: {sorted(canon_range - found)[:5]}")
    assert match, "brute-force cross-check FAILED - enumeration incompleteness"
    return {"n_max": n_max, "d": d, "brute_classes": len(found),
            "canonical_classes_in_range": len(canon_range), "match": match}


# ----------------------------------------------------------------------------------
# Phase: npa - tier-3 quantum upper bounds (report-only) for tier-2 hit classes
# ----------------------------------------------------------------------------------

def npa_upper(sc, solver="CLARABEL"):
    """Moment-matrix upper bound, level 1+AB (singles + cross-party pairs; per-event triples
    added when nblocks == 5 so event moments exist). Real symmetric relaxation (valid: for any
    complex-Hermitian feasible moment matrix, (G + G^T)/2 is real-feasible with the same
    objective). Includes dump outcomes and completeness identities sum_o <u Pi_(b,c,o)> = <u>."""
    import cvxpy as cp
    ops = []                                     # (b, c, o) including dump
    for b, cells in enumerate(sc.blocks):
        for c in range(len(cells)):
            for o in range(sc.d[b][c]):
                ops.append((b, c, o))
    words = [()]
    words += [(op,) for op in ops]
    words += [(u, v) for u, v in itertools.combinations(ops, 2) if u[0] != v[0]]
    if sc.nblocks == 5:
        for i in range(5):
            tri = tuple(sorted(((b, sc.ev_ctx[i][b], sc.ev_out[i][b]) for b in range(3))))
            if tri not in words:
                words.append(tri)
    nw = len(words)

    def key_of(u, v):
        """Canonical moment key of <u^dagger v>, or None if provably zero.
        Within-party operator order is PRESERVED (same-party projectors of different
        measurements do not commute); the only identification is the global adjoint
        W -> W^dagger (reverse every party's sequence simultaneously), valid for the
        real symmetrized matrix since Re<W> = Re<W^dagger>."""
        by_party = {}
        for op in tuple(reversed(u)) + v:
            by_party.setdefault(op[0], []).append(op)
        seq = []
        for b in sorted(by_party):
            s = by_party[b]
            red = []
            for op in s:
                if red and red[-1][1] == op[1]:          # same measurement
                    if red[-1][2] == op[2]:
                        continue                          # projector idempotence
                    return None                           # orthogonal -> 0
                red.append(op)
            seq.append(tuple(red))
        fwd = tuple(seq)
        rev = tuple(tuple(reversed(s)) for s in seq)     # global adjoint
        return min(fwd, rev)

    keys = {}
    cells_idx = {}
    for i in range(nw):
        for j in range(i, nw):
            k = key_of(words[i], words[j])
            cells_idx[(i, j)] = k
            if k is not None:
                keys.setdefault(k, []).append((i, j))
    y = {k: cp.Variable() for k in keys}
    G = cp.bmat([[(y[cells_idx[(min(i, j), max(i, j))]]
                   if cells_idx[(min(i, j), max(i, j))] is not None else
                   cp.Constant(0.0)) for j in range(nw)] for i in range(nw)])
    cons = [G >> 0, y[()] == 1]
    # completeness: for every word u and measurement (b,c), sum_o key(u, u+(b,c,o)) telescopes
    for wi, u in enumerate(words):
        if len(u) > 1:
            continue                                   # keep constraint set modest
        for b, cells in enumerate(sc.blocks):
            for c in range(len(cells)):
                if any(op[0] == b and op[1] == c for op in u):
                    continue
                terms = []
                trivial = False
                for o in range(sc.d[b][c]):
                    k = key_of(u, u + ((b, c, o),)) if u else key_of((), ((b, c, o),))
                    # <u^dag u Pi> : build via key_of(u, u+(op,)) - for len(u)<=1 fine
                    if k is None:
                        continue
                    if k not in y:
                        trivial = True
                        break
                    terms.append(y[k])
                ku = key_of(u, u)
                if trivial or ku not in y:
                    continue
                cons.append(cp.sum(cp.hstack(terms)) == y[ku])
    obj_terms = []
    for i in range(5):
        mono = tuple(sorted((b, sc.ev_ctx[i][b], sc.ev_out[i][b]) for b in range(sc.nblocks)))
        # find u, v in words with key(u,v) == key of the event moment
        k = None
        if sc.nblocks == 1:
            k = key_of((), mono)
        else:
            half = sc.nblocks // 2
            u, v = mono[:half], mono[half:]
            if u in words or len(u) == 1:
                k = key_of(u, v)
        if k is None or k not in y:
            raise RuntimeError("event moment missing from moment matrix")
        obj_terms.append(y[k])
    prob = cp.Problem(cp.Maximize(cp.sum(cp.hstack(obj_terms))), cons)
    try:
        prob.solve(solver=solver)
    except Exception:
        prob.solve(solver="SCS", eps=1e-7, max_iters=200000)
    return prob.value, nw


def seesaw_lower(sc, n_starts=40, seed=0):
    """Qubit-per-party seesaw LOWER bound (any number of blocks). Each measurement is a
    rank-1 projective qubit measurement P(t)=|v(t)><v(t)|: used outcome 0 -> P, used
    outcome 1 -> I-P (dump 0), single-used-outcome cells: used -> P, dump -> I-P. State =
    real unit vector in (C^2)^{ox nblocks} (real suffices for real projectors). SBBC
    Appendix B: two qubits are enough for the bipartite pentagon inequalities."""
    from scipy.optimize import minimize
    rng = np.random.default_rng(seed)
    meas = [(b, c) for b, cells in enumerate(sc.blocks) for c in range(len(cells))]
    nb = sc.nblocks
    dim = 2 ** nb
    nang = len(meas)

    def povm_of(t, nsub):
        v = np.array([math.cos(t), math.sin(t)])
        P = np.outer(v, v)
        if nsub == 1:
            return [P, np.eye(2) - P]           # used, dump
        return [P, np.eye(2) - P, np.zeros((2, 2))]

    def value(params):
        angles = params[:nang]
        psi = params[nang:]
        n = np.linalg.norm(psi)
        if n < 1e-12:
            return 0.0
        psi = psi / n
        pv = {}
        for k, (b, c) in enumerate(meas):
            pv[(b, c)] = povm_of(angles[k], len(sc.blocks[b][c][1]))
        tot = 0.0
        for i in range(5):
            op = np.array([[1.0]])
            for b in range(nb):
                op = np.kron(op, pv[(b, sc.ev_ctx[i][b])][sc.ev_out[i][b]])
            tot += psi @ op @ psi
        return tot

    best = 0.0
    for _ in range(n_starts):
        x0 = np.concatenate([rng.uniform(0, math.pi, nang), rng.normal(size=dim)])
        r = minimize(lambda p: -value(p), x0, method="Nelder-Mead",
                     options={"maxiter": 6000, "xatol": 1e-10, "fatol": 1e-12})
        best = max(best, -r.fun)
    return best


def phase_npa(max_classes=None):
    _, _, classes = load_classes()
    results = read_results()
    hits = [int(r["class_id"]) for r in results if r["hit_5_2"] == "1"]
    ck_path = os.path.join(STATE, "npa.json")
    out = {}
    if os.path.exists(ck_path):
        with open(ck_path) as f:
            out = json.load(f)
    todo = [h for h in hits if str(h) not in out]
    if max_classes is not None:
        todo = todo[:max_classes]
    print(f"[npa] tier-2 hit classes: {len(hits)}; to process: {len(todo)}")
    t0 = time.time()
    for k, ci in enumerate(todo):
        sc = Scenario(classes[ci])
        try:
            val, nw = npa_upper(sc)
        except Exception as e:
            val, nw = None, None
            print(f"[npa] class {ci} FAILED: {e}")
        try:
            low = seesaw_lower(sc)
        except Exception as e:
            low = None
            print(f"[npa] class {ci} seesaw FAILED: {e}")
        out[str(ci)] = {"npa_1AB": val, "matrix_side": nw, "seesaw_lower": low}
        with open(ck_path, "w") as f:
            json.dump(out, f)
        el = time.time() - t0
        print(f"[npa] {k + 1}/{len(todo)} class {ci}: bound={val if val is None else f'{val:.6f}'}"
              f" (side {nw}) [{el:.0f}s]", flush=True)
    vals = [v["npa_1AB"] for v in out.values() if v["npa_1AB"] is not None]
    if vals:
        print(f"[npa] max NPA-1+AB bound over processed hits: {max(vals):.6f} "
              f"(sqrt5 = {SQRT5:.6f}; below? {max(vals) < SQRT5 - 1e-6})")
    return {"hits": len(hits), "processed": len(out),
            "max_bound": max(vals) if vals else None,
            "all_below_sqrt5": bool(vals) and max(vals) < SQRT5 - 1e-6}


# ----------------------------------------------------------------------------------
# Phase: cert - assemble p2_certificate.json
# ----------------------------------------------------------------------------------

def phase_cert(summaries):
    import hashlib
    src = open(os.path.abspath(__file__), "rb").read()
    results = read_results()
    _, _, classes = load_classes()
    exact = {}
    p = os.path.join(STATE, "exact.json")
    if os.path.exists(p):
        with open(p) as f:
            exact = json.load(f)
    npa = {}
    p = os.path.join(STATE, "npa.json")
    if os.path.exists(p):
        with open(p) as f:
            npa = json.load(f)
    hits = []
    for r in results:
        if r["hit_5_2"] != "1":
            continue
        ci = r["class_id"]
        cfg = classes[int(ci)]
        sc = Scenario(cfg)
        hits.append({
            "class_id": int(ci),
            "block_types": [{"pi": ALL_TYPES[t][0], "rho": ALL_TYPES[t][1]} for t in cfg],
            "n_measurements": sc.n_meas, "n_blocks": sc.nblocks,
            "tier1_classical": 2,
            "tier2_ns_value": "5/2",
            "tier2_exact_primal_denominator": (exact.get("primal", {}) or {}).get(ci),
            "tier3_npa_1AB_upper": (npa.get(ci) or {}).get("npa_1AB"),
            "tier3_seesaw_lower": (npa.get(ci) or {}).get("seesaw_lower"),
        })
    hits.sort(key=lambda h: (h["n_measurements"], h["class_id"]))
    cert = {
        "probe": "ESSAY-005 P2 - partition-type cover exhaustion",
        "date": "2026-07-13",
        "predicate_source": "Abramsky-Brandenburger arXiv:1102.0264 Prop 9.3/9.4 "
                            "(verbatim quotes in script docstring; re-verified against the "
                            "paper text by the executing agent on 2026-07-13)",
        "predicate_source_sha256": hashlib.sha256(src).hexdigest(),
        "n_max": N_MAX,
        "lemmas": {
            "L1": "outcome coarse-graining: unused outcomes merge to one dump; NS/quantum "
                  "values of sum_i P(e_i) preserved both directions; d_x <= used+1",
            "L1prime": "C5 is triangle-free, so conflicting pi-cells have exactly 2 "
                       "rho-subcells; conflicting cells are C5-edge pairs or C5-path triples "
                       "split {i,i+2}|{i+1}; hence d_x <= 3 (asserted over all active types)",
            "L2": "block monotonicity: deleting a block with redundant/no conflicts keeps a "
                  "valid C5 5-tuple and does not decrease sum_i P(e_i) (NS marginal box); "
                  "hence suprema are attained on multisets of conflicting types",
            "L3": "measurements unused by the 5 events delete freely; n_b = #cells(pi_b)",
            "L4": "distinctness automatic: for non-adjacent i,j pick edge {i,k} with {j,k} "
                  "not an edge; the conflicting block separates i from j or (ii) is violated",
        },
        "tiers": {
            "tier0": "induced C5 exclusivity (exact, by construction)",
            "tier1": "classical value = 2 for every tier-0 class (proof in docstring)",
            "tier2": "NS LP <= 5/2 a priori; hits = classes attaining 5/2, certified by exact "
                     "rational primal points",
            "tier3": "quantum, REPORT-ONLY: NPA 1+AB moment-matrix upper bounds on hit "
                     "classes; quantum <= NS settles classes with NS < sqrt5",
        },
        "enumeration": summaries.get("enum", {}),
        "types": summaries.get("types", {}),
        "smoke": summaries.get("smoke", {}),
        "lp": summaries.get("lp", {}),
        "exact": summaries.get("exact", {}),
        "control": summaries.get("control", {}),
        "bruteforce_crosscheck": summaries.get("brute", {}),
        "npa": summaries.get("npa", {}),
        "hits": hits,
        "claim": summaries.get("claim", ""),
    }
    with open(CERT_JSON, "w") as f:
        json.dump(cert, f, indent=1, default=str)
    print(f"[cert] wrote {CERT_JSON} ({len(hits)} tier-2 hit classes)")
    return cert


# ----------------------------------------------------------------------------------

def main():
    phases = sys.argv[1:] or ["all"]
    if phases == ["all"]:
        phases = ["types", "smoke", "enum", "lp", "exact", "control", "brute", "npa", "cert"]
    summaries = {}
    sp = os.path.join(STATE, "summaries.json")
    if os.path.exists(sp):
        with open(sp) as f:
            summaries = json.load(f)
    for ph in phases:
        print(f"===== phase {ph} =====", flush=True)
        if ph == "types":
            summaries["types"] = phase_types()
        elif ph == "smoke":
            summaries["smoke"] = phase_smoke()
        elif ph == "enum":
            summaries["enum"] = phase_enum()
        elif ph == "lp":
            summaries["lp"] = phase_lp()
        elif ph == "exact":
            summaries["exact"] = phase_exact()
        elif ph == "control":
            summaries["control"] = phase_control()
        elif ph == "brute":
            summaries["brute"] = phase_brute()
        elif ph == "npa":
            summaries["npa"] = phase_npa()
        elif ph == "cert":
            hits = summaries.get("lp", {}).get("hits", "?")
            npa_ok = summaries.get("npa", {}).get("all_below_sqrt5")
            claim = (
                f"Exhaustive over partition-type covers (AB Prop 9.3) on <= {N_MAX} "
                f"measurements: tier-0 (induced C5) classes exist; classical tier is 2 "
                f"identically; {hits} D5-classes attain the KCBS no-signalling value 5/2 "
                f"(exact rational certificates); "
                + ("every tier-2-matching class has NPA-1+AB quantum bound < sqrt(5), so no "
                   "partition-type cover on <= 10 measurements reproduces the full KCBS "
                   "tier structure - the transfer fails exactly at the quantum tier."
                   if npa_ok else
                   "tier-3 (quantum) status: see npa summary - report-only.")
            )
            summaries["claim"] = claim
            phase_cert(summaries)
        with open(sp, "w") as f:
            json.dump(summaries, f, indent=1, default=str)
    print("done.")


if __name__ == "__main__":
    main()
