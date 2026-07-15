# ESSAY-005 — Phase-2/3 execution plan for probes P1–P4 (2026-07-13)

Author: probe-designer agent. Parent spec: `ESSAY-005-problem-spec.md` (Traps 1/2, probes P1–P4,
acceptance criteria). Tooling: `BlackBox/Kernel/BlackBox.wl` (`CoverScenario`, `CechObstruction`,
`CechCohomology`, `CechRelativeCohomology`, `ObstructionOrder` key, `GlobalSectionQ`,
`ContextualFraction`), patterns from `SupportCohomology.wl`. Source for P2's predicate:
Abramsky–Brandenburger, arXiv:1102.0264 (NJP 13 (2011) 113036), §2.4 and §9.3 — read from the
PDF during this design pass; the predicate below is derived from the actual statements of
Prop. 9.3/9.4, not from folklore.

Design-pass verification already performed (2026-07-13, Python/igraph/HiGHS, this machine —
executors may cite these numbers but MUST regenerate anything that enters a certificate):

| object | |V| | # maximal cliques | size histogram | omega | plain glued LP |
|---|---|---|---|---|---|
| C5^v1 (edge cover) | 5 | 5 | {2:5} | 2 | 2.5 |
| C7^v1 | 7 | 7 | {2:7} | 2 | 3.5 |
| C5^v2 (conormal square) | 25 | 535 | {4:525, 5:10} | 5 | 5.000000 |
| C7^v2 | 49 | 1715 | {4:1715} | 4 | 12.250000 |
| C5^v3 (conormal cube) | 125 | 103,778,725 | {7:500, 8:82,005,625, 9:21,381,000, 10:391,600} | 10 | (do NOT solve; certified 12.5, see P3-C5) |

535 matches the GE-001 census in `pentagon-foundations/CertifyingQuantumness.wl` ("all 535
maximal cliques ... saturating the ten 5-cliques at exactly 1"). The exact dual/primal
certificates behind the LP column are verified by summation below (P3).

WARNING (hard-won): C5^v3 has ~1.04e8 maximal cliques. Never materialize a clique-constraint LP
at k=3; use the certificate method of P3. The census itself (igraph `maximal_cliques`) takes
~4 min; `clique_number` alone is cheaper.

---

## 0. Division of labor

| agent | probes | language | wall-clock | WL kernels |
|---|---|---|---|---|
| Phase-2 agent A (cheap, immediate) | P1 + P4 (one script, shared compute) | Wolfram (paclet verbatim) | ~2–3 h | 1 |
| Phase-3 agent B | P2 (cover exhaustion) | Python only (numpy/igraph/scipy/sympy — no WL seat) | 1–2 days | 0 |
| Phase-3 agent C | P3 (gluing LP + certificates) | Python + optional WL exact cross-check | ~half day | <=1, briefly |

Rationale: P1/P4 reuse paclet functions verbatim (no new mathematics — the parent spec's "safe
to delegate immediately"); P2 and P3 each need the formalizations fixed in this document and are
independent of each other and of A. Agent B uses no Wolfram seat, so it can run concurrently
with the three other local workflows without license contention.

---

## 1. P1 + P4 — support-census negative control and torsion-vs-GE-value scan (Phase-2 agent A)

One wolframscript run produces both deliverables; P4 is free once P1's objects are in memory.

### 1.1 Model families (exact arithmetic throughout)

Single-copy C5 models, two parametrized paths plus the extremal point:

- **Path S (edge-symmetric, the classical -> quantum -> alpha\* path).**
  `e[p_] := CycleModel[5, 1 - 2 p, p]` — edge distribution `(1-2p, p, p, 0)`, per-event marginal
  P(x_i = 1) = p, KCBS sum Sigma = 5p. Support per context is {00, 01, 10} (3 sections) for ALL
  p in (0, 1/2), and drops to {01, 10} exactly at p = 1/2 (the Wright/alpha\* point). The path
  therefore passes Sigma = 2 (classical max, p = 2/5) and Sigma = sqrt(5) (quantum max,
  p = 1/sqrt(5)) strictly INSIDE one support stratum — this is the entire design of P1:
  everything the LP layer sees move happens where the support presheaf is constant.
  Grid (exact rationals + one exact radical):
  `pGrid = {1/5, 3/10, 2/5, 21/50, 1/Sqrt[5], 23/50, 12/25, 49/100, 499/1000, 1/2}`.
  Sanity assert before the sweep: `Simplify[CycleModel[5,"Quantum"] == e[1/Sqrt[5]]]` is True
  (Cos[Pi/5]/(1+Cos[Pi/5]) = 1/Sqrt[5]).

- **Path V (visibility mixing, crosses a support boundary the other way).**
  `eV[v_] := Simplify[v CycleModel[5, "Quantum"] + (1 - v) ConstantArray[1/4, 20]]`.
  For v < 1 the 11-outcome (p11 = (1-v)/4 > 0) sections enter: support = all 4 sections per
  context (a THIRD stratum, full support). Grid: `vGrid = {1/2, 9/10, 99/100, 1}` (v = 1
  coincides with p = 1/Sqrt[5] on path S — use it as the cross-check row).

- **Mixed products (stratum controls on the product cover):**
  quantum (x) Wright and classical (x) Wright.

Two-copy product models on the FIXED 25-context product cover (verbatim from
`SupportCohomology.wl`, Sec. "The Two-Copy Product Cover"):

```wl
edges5 = Table[{i, Mod[i + 1, 5]}, {i, 0, 4}];
scenProd = CoverScenario[Join[Table[{1, i}, {i, 0, 4}], Table[{2, i}, {i, 0, 4}]],
  Flatten[Table[{{1, ed[[1]]}, {1, ed[[2]]}, {2, f[[1]]}, {2, f[[2]]}}, {ed, edges5}, {f, edges5}], 1]];
prodModel[m1_, m2_] := With[{d1 = AssociationThread[Tuples[{0, 1}, 2] -> m1[[1 ;; 4]]],
   d2 = AssociationThread[Tuples[{0, 1}, 2] -> m2[[1 ;; 4]]]},
  Flatten[Table[d1[s[[1 ;; 2]]] d2[s[[3 ;; 4]]], {c, scenProd["Contexts"]}, {s, Tuples[{0, 1}, 4]}]]];
```

Model list = { prodModel[e[p], e[p]] : p in pGrid } ∪ { prodModel[eV[v], eV[v]] : v in vGrid }
∪ { prodModel[CycleModel[5,"Quantum"], CycleModel[5,"Wright"]],
    prodModel[e[2/5], CycleModel[5,"Wright"]] } — 15 product rows — plus the 14 single-copy
rows on `scen5 = CycleScenario[5]` for reference.

### 1.2 Calls per row (all existing paclet functions, verbatim)

```wl
ch  = CechObstruction[scen, m];               (* support census + ObstructionOrder *)
cc  = CechCohomology[scen, m];                (* absolute H0/H1, torsion, ComplexCloses *)
r1  = CechRelativeCohomology[scen, m, 1];     (* relative group at first context *)
r13 = CechRelativeCohomology[scen, m, 13];    (* second base context (product rows only; use 3 for single-copy) *)
gs  = GlobalSectionQ[scen, N@m];              (* LP layer *)
cf  = ContextualFraction[scen, N@m];          (* LP layer — the thing that MOVES *)
```

### 1.3 Output tables (CSV, exported to this module)

`p1p4_census.csv` (P1 deliverable), one row per (family, param, cover):

```
family, param, SigmaPerCopy, stratum, SectionCount, SupportSizesTally, GlobalSupportSize,
H0Rank_obstr, ObstructedCount, CohStronglyContextual, FalseNegativesCount,
ccH0, ccH1free, ccH1torsion, ComplexCloses, GlobalSectionQ, CF
```

`p1p4_torsion.csv` (P4 deliverable):

```
family, param, SigmaPerCopy, stratum, OrderTally, rel1_H1free, rel1_H1torsion, rel1_GammaTally,
rel13_H1free, rel13_H1torsion, rel13_GammaTally, GammaCocyclesVerified, OrdersMatchObstruction, CF
```

`SigmaPerCopy` = 5p exactly (path S) / N[5 (v/Sqrt[5] + (1-v)/2)] (path V, recorded, not a
contextuality claim — path V leaves the exclusivity stratum p11 = 0, which is its purpose).
Param column: exact InputForm strings. CF: 12 significant digits.

### 1.4 Pre-registered expectations (write these into the runner as a verification association, house style `OK -> True`)

Stratum A = products of path-S models, 0 < p < 1/2 (includes p = 2/5, 1/Sqrt[5], 49/100...):
- SectionCount 225 (9 per context), GlobalSupportSize 121 = 11^2, H0Rank 36 = 6^2,
  ObstructedCount 0, all orders 1, ccH1free 0, ccH1torsion {}, rel torsion {} — IDENTICAL
  ACROSS THE WHOLE STRATUM. CF strictly increasing in p; GlobalSectionQ True iff p <= 2/5.
Stratum W = p = 1/2 product (Wright (x) Wright):
- SectionCount 100, GlobalSupportSize 0, ObstructedCount 100, all orders Infinity,
  CohStronglyContextual True (matches `SupportCohomology.wl` chWW).
Stratum F = path V, v < 1 (full support):
- SectionCount 400, GlobalSupportSize 1024, ObstructedCount 0 (deterministic witness for every
  section), everything cohomological trivial; gs/CF recorded (no prediction).
Mixed rows: quantum(x)Wright expected 15x10 = 150 sections, obstructed >= the Wright-factor
sections (record; marginalization argument of `SupportCohomology.wl` says every product section
with an obstructed factor is obstructed).

**Acceptance mapping (verbatim from parent spec).** P1: if ANY support-level column differs
between two stratum-A rows (in particular between Sigma = 2, sqrt(5), 5/2-epsilon), Trap 2 is
REFUTED and that invariant is promoted to research object — escalate immediately, do not
continue the sweep. If all stratum-A rows are identical, the possibilistic route to S_k is
CLOSED with a citable computation. P4: the torsion/order/relative-group columns must be flat
within strata and may move only at stratum boundaries (v = 1, p = 1/2); the two CSVs are the
essay's "what cohomology can and cannot see" exhibit. Both outcomes are deliverables; no
outcome wastes the run.

### 1.5 Runtime and ops

Per product-cover row: CechObstruction ~1–3 min (225 sections; stratum-F rows faster — global
witness short-circuits), CechCohomology ~2–10 min (stratum F has the largest C1), relative
cohomology 2 calls ~2–5 min, LP calls seconds. Total ~15 rows x ~10 min + 14 cheap single-copy
rows: **~2–3 h, one kernel**. Run as `wolframscript -file probe-P1P4.wl`. On a transient
"Please activate the product" error: license-seat contention — sleep 60 s and retry (do not
diagnose licensing). Keep to 1 kernel; do not parallelize contexts.

---

## 2. P2 — partition-type cover exhaustion on <= 10 measurements (Phase-3 agent B)

### 2.1 The predicate, derived from AB Prop. 9.3/9.4

AB §2.4: a *measurement cover* M on X is a family of subsets with union X forming an antichain;
§2.4.1 defines Bell-type scenarios by a disjoint family {X_i} (parts), contexts = subsets
containing exactly one measurement from each part. Prop. 9.3 (§9.3) characterizes these
intrinsically: M arises from a Bell-type scenario if and only if M is the family of maximal
cliques of the graph G = (X, E_G) that is the complement of an equivalence relation R on X
(E_G = pairs with not(x R y)); the proof identifies the maximal cliques of such G with the
transversals of the partition induced by R (sets meeting each block exactly once). Prop. 9.4
adds the reason these covers are barren for KS-type arguments: for a Bell-type cover and ANY
quantum representation, every section s in E(C), C in M, is in the support of some state (take
the product of the eigenvector states picked out by s). Consequence for us: no SUPPORT-level
restriction can distinguish anything on a partition-type cover, so "C5 with matching
probabilistic structure" (parent spec) must be tested at the probabilistic tiers defined in 2.3.

Executable predicate (transcribe as-is):

```python
from itertools import product as iproduct

def is_partition_type(X, M):
    """AB Prop 9.3: M (list of contexts, each a subset of X) is the maximal-clique cover of
    the complement of an equivalence relation on X."""
    Ms = {frozenset(C) for C in M}
    if set().union(*Ms) != set(X):                                   # covers X
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
    trans = {frozenset(t) for t in iproduct(*blocks)}                # ALL transversals
    return Ms == trans                                               # both inclusions (Prop 9.3)
```

Both inclusions in the last line matter: a cover whose compatibility graph is complete
multipartite but which omits some transversal is NOT the family of maximal cliques and fails P.

### 2.2 Search space, reduction lemmas, canonical enumeration

**Target.** A partition-type cover on |X| = n <= 10 together with five *events*
e_i = (C_i, s_i) (context + full joint outcome) such that the exclusivity relation
[e ⊥ e' iff exists x in C ∩ C' with s(x) != s'(x)] restricted to {e_0..e_4} is exactly the
5-cycle: e_i ⊥ e_{i+1 (mod 5)}, and NOT e_i ⊥ e_{i+2 (mod 5)}, all events pairwise distinct.

**Reduction lemmas (executor asserts each with a 3-line proof in the certificate):**

- **L1 (outcome coarse-graining).** Merging all outcomes of a measurement not used by any of the
  5 events into one dummy outcome is a surjection of scenarios preserving each P(e_i), the
  classical value, and the NS value (marginals compose with the merge). Hence WLOG the outcome
  set of x = {outcomes used at x by the events} + one dummy; d_x <= 6.
- **L2 (inactive blocks).** A block in which the five events use five pairwise-distinct
  measurements (or impose no conflict and no shared-measurement constraint) contributes no
  exclusivity and no consistency constraint; deleting it preserves the induced exclusivity
  pattern and the achievable {P(e_i)} (product with a deterministic marginal on the deleted
  block, and conversely marginalize). WLOG every block is *active*: it makes at least one
  adjacent pair conflict, or forces a shared measurement between some pair.
- **L3 (unused measurements).** Measurements of a block not chosen by any of the 5 events can be
  deleted (contexts through them are never the C_i, and NS models extend freely). WLOG block b
  has exactly the measurements used, i.e. n_b = #cells(pi_b) below.

**Canonical data.** After L1–L3, the whole configuration is captured blockwise: for each block
b, the five events induce a pair of set partitions of {0,...,4}:
pi_b (same measurement chosen in block b) and a refinement rho_b (same measurement AND same
outcome). Conflicts contributed by b = pairs {i, j} in the same pi_b-cell but different
rho_b-cells. The event 5-tuple has C5 exclusivity iff
(i) Union_b conflicts(b) = E(C5) and (ii) conflicts(b) ⊆ E(C5) for every b (non-adjacent pairs
are never conflicted), and (iii) distinctness: for each non-adjacent (and hence agreeing) pair
{i, j} there is some b with i, j in different pi_b-cells or different rho_b-cells — otherwise
e_i = e_j.

Number of (pi, rho) pairs with rho <= pi on 5 points: sum over pi of prod_cells Bell(|cell|)
= 52 + 75 + 100 + 50 + 60 + 20 + 1 = **358 block types**; those with nonempty conflict set
contained in E(C5) are the *active types* (a few dozen after the D5 filter — executor reports
the exact count). A scenario = a **multiset of active types** {tau_1..tau_m} with
sum_b #cells(pi_b) <= 10 (the measurement budget; #cells >= 2 for any conflict-carrying type,
so m <= 5). Enumerate multisets in weakly-decreasing type order (orderly generation — this IS
the completeness argument: every configuration has exactly one sorted representative), check
(i)–(iii), then deduplicate under the dihedral group D5 (order 10) acting on indices 0–4.
Estimated canonical configurations: **10^4–10^6** (crude bound: multisets of <= 5 items from
<= 100 active types intersected with the budget); combinatorial tier < 1 h in Python.

**Recovering the cover.** From a surviving multiset: X = disjoint union of blocks, block b
having one measurement per pi_b-cell; outcome sets per L1; M = all transversals;
C_i = (cell of i in pi_b)_b; s_i = (rho-cell outcome labels). `is_partition_type(X, M)` must
return True (self-check).

### 2.3 The three tiers of "matching probabilistic structure"

- **Tier 0 (combinatorial, part of the certificate):** induced-C5 exclusivity as above. Exact.
- **Tier 1 (classical, automatic — assert, don't search):** the max number of the five events
  realizable by one deterministic global assignment is exactly 2 for ANY tier-0 hit: adjacent
  events conflict on a shared measurement (<= alpha(C5) = 2), and any non-adjacent pair agrees
  on all shared measurements, so their union is a consistent partial assignment (= 2 attained).
- **Tier 2 (no-signalling LP, part of the certificate):** NS value := max sum_i P(e_i) over the
  no-signalling polytope of the cover (variables p_C(s) >= 0 per context-section, normalization
  per context, marginal agreement on every pairwise context overlap; objective
  sum_i p_{C_i}(s_i)). Upper bound 5/2 holds a priori (adjacent pair: P(e_i) + P(e_{i+1}) <= 1
  through the shared measurement's marginal). "Matching" := NS value = 5/2 exactly. Solve
  float (HiGHS), then reconstruct an exact rational optimal point
  (Fraction.limit_denominator on the basic solution) and verify feasibility + objective = 5/2
  by exact summation; only exact verification enters the certificate. LP sizes after L1–L3:
  contexts prod #cells <= ~36, <= ~6 outcomes/measurement, typically <= 10^4 variables —
  seconds each.
- **Tier 3 (quantum, REPORT ONLY — not part of the exhaustion certificate):** for each D5-class
  of tier-2 hits, compute an upper bound on the quantum value of sum_i P(e_i) (NPA level 1+AB,
  hand-rolled moment-matrix SDP in cvxpy — small: side <= 1 + sum_x(d_x - 1) ~ 50) and a
  seesaw lower bound. Question: does any partition-type realization reach sqrt(5) = 2.2360...?
  Literature says no for the known bipartite pentagon inequalities: Sadiq–Badziag–Bourennane–
  Cabello, "Bell inequalities for the simplest exclusivity graph", arXiv:1106.4754,
  PRA 87, 012128 (2013) — quantum max strictly below sqrt(5). Any class reaching
  sqrt(5) - 1e-6 is a MAJOR surprise (would break SH-006's obstacle) — escalate.

**Positive control (mandatory validation gate):** the enumeration MUST rediscover the
Sadiq et al. bipartite pentagon configurations (their scenario fits in n <= 10). Executor
fetches arXiv:1106.4754, identifies the scenario (parts/settings/outcomes) and confirms the
corresponding multiset appears among tier-0 hits with tier-2 value 5/2, before trusting any
negative claim. A second, dumb brute-force checker (no symmetry, direct enumeration of events
over all partition-type covers with n <= 6, d_x <= 3) must reproduce the canonical counts on
its range — the completeness cross-validation.

### 2.4 Exhaustion certificate format

`p2_certificate.json` in this module:

```json
{ "predicate_source_sha256": "...", "n_max": 10,
  "lemmas": ["L1 coarse-grain: <proof sketch>", "L2 inactive blocks: ...", "L3 unused measurements: ..."],
  "enumeration": {"active_types": N1, "canonical_multisets_visited": N2,
                   "tier0_hits": N3, "d5_classes": N4,
                   "bruteforce_crosscheck": {"n_max": 6, "match": true}},
  "hits": [ {"partition": [...], "block_types": [["pi_b","rho_b"], ...],
              "events": [...], "tier1_classical": 2,
              "tier2_ns_value": "5/2", "tier2_exact_witness": "...",
              "tier3_quantum_upper": 2.17..., "tier3_quantum_lower": 2.17...,
              "verdict": "PARTIAL | FULL-MATCH"} ],
  "claim": "<one of the two statement templates>" }
```

Statement templates (either is publishable per the parent spec):
(a) impossibility half — "No partition-type measurement cover on <= 10 measurements carries
five events with C5 exclusivity whose no-signalling value ... / whose quantum value reaches
sqrt(5) [state the tier at which the transfer fails, and the bound n <= 10 honestly]";
(b) construction half — the explicit counterexample(s) with certificates.
Expected outcome given the literature: tier-0 and tier-2 hits EXIST (pentagon Bell
inequalities), the failure is at tier 3 (quantum < sqrt(5)) — i.e. the separation the essay
needs sits at the quantum tier, which is itself a sharp, previously-unstated form of SH-006's
obstacle. But the search must be run, not assumed: tier-2 could conceivably fail too for n <= 10.

Runtime: tier 0 < 1 h; tier 2 on hits: hours; tier 3 on D5-classes: ~minutes/class numeric SDP.
Total **1–2 days**, Python only. No WL seat, no cloud.

---

## 3. P3 — the product-ansatz gluing LP, derived and hand-verified (Phase-3 agent C)

### 3.1 Objects

G = C_n as exclusivity graph on Z_n (i ~ i+1 mod n). k-fold conormal (disjunctive/OR) power
G^vk on V = Z_n^k: u ~ v iff exists t with u_t - v_t = +-1 mod n. Cover U_k = maximal cliques
of G^vk (censuses in the header table). The *subnormalized-weighting presheaf* W on the cover
poset: W(U) = { w : U -> [0,1] }, restriction = function restriction, with the cone constraint
sum_{v in K} w(v) <= 1 attached to each cover element K. A compatible family {w_K} with
w_K |_{K ∩ K'} = w_{K'} |_{K ∩ K'} glues (uniquely, trivially — sections are point-functions)
to one global weight p : V -> [0,1]. HONEST FRAMING, to carry into the essay: for THIS presheaf
gluing never obstructs; the derivational content lives in the cone constraints and — dually —
in fractional partitions of unity subordinate to subcovers (Cech 0-cochains on the cover with
values in Q_{>=0}). That is where the "which cohomological invariant computes the LP" question
lands (see 3.5).

### 3.2 The two encodings (transcribe exactly)

**E1 — glued LP (no ansatz).** Variables p_v >= 0 (v in V(G^vk)); constraints
sum_{v in K} p_v <= 1 for every K in U_k; objective max sum_v p_v. Value L_k(G); per-copy score
s_k = L_k^{1/k}. This is the fractional clique-cover / packing LP of the power graph; by LP
duality L_k = min { sum_K y_K : y >= 0, sum_{K ∋ v} y_K >= 1 } (fractional clique cover).

**E2 — product ansatz.** Variables q_i >= 0 (i in Z_n); set p = q^{⊗k}
(p_{(i_1..i_k)} = prod_t q_{i_t}); constraints sum_{(i_1..i_k) in K} prod_t q_{i_t} <= 1 for
every K in U_k; objective (sum_i q_i)^k. Value A_k(G). Every ansatz point is E1-feasible, so
**A_k <= L_k** always. E2 is a polynomial program, NOT an LP — at k = 2 no solver is needed
because sandwich certificates below settle it exactly.

**Scoring gate (Trap 1, pre-registered — any failure means the ENCODING is wrong; stop and
fix before any tool-building):**

| target | required exact value | wrong value that must NOT appear |
|---|---|---|
| L_1(C5) = A_1(C5) | 5/2 | — |
| L_2(C5) = A_2(C5) | 5   (per-copy sqrt(5)) | — |
| L_1(C7) = A_1(C7) | 7/2 | theta(C7) ≈ 3.3177 |
| L_2(C7) = A_2(C7) | 49/4 (per-copy 3.5) | theta(C7)^2 ≈ 11.008 |

This matches S_1(C5) = 5/2, S_2(C5) = sqrt(5), S_2(C7) = 3.5 — the three known values, with C7
as the critical negative control (an encoding that lets the C7 two-copy value sag toward
theta^2 has smuggled in the wrong relaxation).

### 3.3 Hand derivation and certificates (verified by summation during this design pass)

- **C1, k=1, C_n:** primal p ≡ 1/2 (each edge sums to 1); dual y ≡ 1/2 on the n edges (each
  vertex in exactly 2 edges, coverage 1). Both values n/2. Hence L_1(C5) = 5/2, L_1(C7) = 7/2.
  A_1 = L_1 (k=1 ansatz is no restriction).
- **C2, k=2, C5:** the pentads P_j = {(i, 2i+j) : i in Z5}, j in Z5, are five pairwise-disjoint
  5-cliques (steps +-1 hit the first coordinate; steps +-2 make the second coordinate move by
  +-4 ≡ ∓1) that PARTITION the 25 vertices: dual y = 1 on the five pentads covers every vertex
  exactly once ⇒ L_2 <= 5. Primal p ≡ 1/5 is feasible because omega(C5^v2) = 5 (census:
  {4:525, 5:10}); value 25/5 = 5. **L_2(C5) = 5 exactly.** Ansatz: q ≡ 1/sqrt(5) is
  E2-feasible (every 4-clique sums to 4/5; each of the ten 5-cliques — both pentad families,
  slopes 2 and 3 — sums to exactly 1, reproducing CertifyingQuantumness.wl), value
  (5·5^{-1/2})^2 = 5 ⇒ **A_2(C5) = 5**, per-copy sqrt(5) = S_2. The exact partition-of-unity
  dual (the pentad 0-cochain) is the "specific Cech 0-cochain" of the parent spec.
- **C3, k=2, C7 (the critical control):** dual y = 1/4 on the 49 edge x edge 4-cliques — every
  vertex (i,j) lies in exactly 4 of them (2 edges through i times 2 through j) ⇒ coverage 1,
  value 49/4 ⇒ L_2 <= 49/4. Primal p ≡ 1/4 feasible because **omega(C7^v2) = 4** (census: all
  1715 maximal cliques have size 4; hand argument for the absence of a pentad analogue: a
  linear 7-clique {(i, ai+j)} needs 2a ≡ ±1 (mod 7) ⇒ a in {3,4}, but then 3a ≡ ±2 — blocked);
  value 49/16·... = 49·(1/4) = 49/4. **L_2(C7) = 49/4 = 12.25 = 3.5^2 exactly.** Ansatz:
  q ≡ 1/2 makes every maximal (4-)clique sum exactly 1 ⇒ feasible, (7/2)^2 = 49/4 ⇒
  **A_2(C7) = 49/4**, per-copy 3.5 = S_2(C7) — NOT theta(C7)^2. The control passes on paper.
- **C4, k=3, C5 (NEW discriminator, found during this design pass):** dual y = 1/2 on the 25
  ten-cliques {pentad_j on coords (1,2)} x {edge_m on coord 3} — each vertex lies in exactly 2
  (unique j, two edges through its third coordinate) ⇒ L_3 <= 25/2. Primal p ≡ 1/10 feasible
  because omega(C5^v3) = 10 (census above); value 125/10 = 25/2. **L_3(C5) = 25/2, per-copy
  12.5^{1/3} ≈ 2.3208 > sqrt(5) ≈ 2.2361.** Meanwhile A_3(C5) >= 5^{3/2} ≈ 11.180 (q ≡
  1/sqrt(5) remains feasible: 10-cliques sum to 10·5^{-3/2} ≈ 0.894) and A_3 <= L_3 = 12.5.
  If S_3(C5) = sqrt(5) per copy (plausible from CE-hierarchy monotonicity, but NOT established
  — record as open), then at k = 3 the glued LP WITHOUT the ansatz stops tracking S_k while the
  ansatz value may not. **Consequence for ESSAY-005: at k = 2 the gluing alone already computes
  S_2 on both C5 and C7 (L_2 = A_2 = S_2^2 — the k=2 coincidence is now a theorem-by-
  certificate), so the "derivation" question at k = 2 reduces to the dual partition-of-unity
  structure; at k = 3 the ansatz constraint is expected to carry content beyond gluing. Both
  facts sharpen the essay either way.**
- **C5 (stretch), k=3, C7:** conjectured L_3(C7) = 343/8 = 3.5^3 via y = 1/8 on the 343
  edge^x3 8-cliques (coverage exactly 8·1/8 = 1) — dual side unconditional; primal p ≡ 1/8
  needs omega(C7^v3) = 8, machine check (igraph `clique_number`, budget 2 h — if it times out,
  restrict the claim to k <= 2, which is all the gate requires; do NOT run `maximal_cliques`
  blindly, see the 1.04e8 warning).

### 3.4 Executor tasks (transcription, no derivation)

1. Regenerate the k <= 2 censuses (igraph, exact adjacency as in 3.1) and re-verify
   certificates C1–C4 by EXACT summation over the census (Python `fractions`; feasibility of
   the stated primal against every maximal clique, coverage >= 1 of the stated dual at every
   vertex, primal value = dual value). No LP solver enters the certified claim; run HiGHS float
   once per case as an independent cross-check (must agree to 1e-9 with 5/2, 5, 7/2, 49/4).
2. Verify A_2 feasibility symbolically: q ≡ 1/sqrt(5) against all 535 cliques (exact radical
   arithmetic — sympy or WL), q ≡ 1/2 against all 1715.
3. k=3: verify C4 exactly (the 25-clique dual list is explicit — no census needed for the dual;
   the primal needs only omega = 10, cited from this design pass or recomputed via
   `clique_number`). Attempt C5-stretch under budget. Numeric multistart QCQP for A_3(C5)
   (scipy SLSQP, 200 random starts, report best value and whether it exceeds 5^{3/2} + 1e-6).
4. Emit `p3_certificates.json` (each certificate: primal vector spec, dual vector spec, both
   values as exact rationals, verification booleans) + a short results table appended to this
   file's module README. Gate verdict: PASS iff the 3.2 table holds exactly.

### 3.5 What P3 hands back to the essay

If the gate passes (expected — proven on paper above): ESSAY-005's "derivation" question
becomes exactly: *which invariant of the weighted (Q_{>=0}-semimodule) presheaf on the product
cover computes the optimal fractional partition of unity, and when is that optimum attained by
an EXACT partition (pentads at k=2 on C5) rather than a fractional one (edge-squares, weight
1/4, on C7)?* — the sharply-posed question the parent spec asked for, now with the k=3
discriminator separating "gluing content" from "ansatz content". If the gate fails anywhere,
the encoding is wrong and NOTHING downstream may be built until it is fixed.

---

## 4. Cost summary

| probe | agent | compute | wall-clock | cloud |
|---|---|---|---|---|
| P1+P4 | Phase-2 A | 1 WL kernel | 2–3 h | none |
| P2 | Phase-3 B | Python (no WL seat) | 1–2 days | none |
| P3 | Phase-3 C | Python + brief WL cross-check | ~half day | none |

Nothing here approaches local infeasibility; no RemoteBatchSubmit / cloud credits required.
The only guarded step is any k=3 clique census (10^8 objects — certificates avoid it).

## 5. Pilot (run before dispatching the full agents; ~45 min)

1. P1 mini-sweep at p in {2/5, 1/Sqrt[5], 1/2} on the product cover (3 rows): stratum-A rows
   identical and the p=1/2 jump present ⇒ P1/P4 design sound. (~15 min, 1 kernel.)
2. P3 certificate check C1–C3 by exact summation (regenerated censuses; ~10 min, Python).
3. P2 predicate smoke test: `is_partition_type` on (i) the CHSH cover (True), (ii) the C5 edge
   cover (False — incompatibility is not transitive), (iii) a 3-block toy (True); then the
   n <= 6 brute-force tier-0 scan (~10 min) — sanity: does an induced C5 already appear at
   n = 6? Record either way.
Kill criteria: any P3 certificate fails ⇒ fix encoding before Phase-3 dispatch. P1 stratum-A
rows differ ⇒ Trap 2 refuted — escalate to the lead, redesign (this is the good surprise).
