# ESSAY-005 BRIDGE — Formalizer A: the weighted GE presheaf and its S_k invariant

> **INTEGRATOR STATUS (2026-07-13, post-review):** CONSTRUCTION at degree 0 —
> `S_k` reproduced exactly (all four gates) as `Λ_k^{1/k}`, `Λ_k = sup μ` over
> `H^0(F)`. The higher-cohomology question (C-A1) stays OPEN: only an
> integrality-gap PROXY was computed, not a proven semimodule `H^1`. Do not read
> `Λ_k` as a class in `H^{≥1}`. Master synthesis: `ESSAY-005-ERGODIC-BRIDGE-2026-07-13.md`.

Author role: FORMALIZER A (weighted/probabilistic presheaf side of ESSAY-005).
Date: 2026-07-13. Status of each claim is tagged inline as one of:
**[ESTABLISHED-in-project]** (already computed/verified here, cite file),
**[NEW-claim]** (this note's formalization, checkable but first stated here),
**[CONJECTURE]** (plausible, unproven — flagged for Phase-3 to test/refute).

This spec fixes ONE object (the weighted presheaf `F`) and ONE candidate
invariant of it claimed to equal the GE composed bound `S_k`, stated precisely
enough for Phase-3 to implement and score against the pre-registered anchors.
It deliberately separates what is a *derivation* from what is a *conjecture*,
because the honest answer here is subtle: **the quantity `S_k` is a degree-0
(global-section / LP-dual) invariant, not a higher cohomology class**, and the
only place a genuine `H^1` can live is the integrality obstruction to a
partition of unity. Both halves are made checkable below.

---

## 0. Notation and the anchors (the non-negotiable validation gates)

Let `G` be an exclusivity graph (vertices = events, edges = exclusive pairs).
For the pentagon `G = C5`; negative control `G = C7`. The GE composed bound for
`k` copies is defined on the **k-fold conormal power** `G^{∨k}`:

- vertices `V_k = {0..n-1}^k`;
- `u ~ v` iff there exists a coordinate `t` with `u_t - v_t ≡ ±1 (mod n)`
  (adjacency in at least one coordinate = conormal/co-normal/OR product).

Define the **GE (exclusivity-LP) value**

    L_k(G) = max_p  Σ_{v∈V_k} p_v
             s.t.   Σ_{v∈K} p_v ≤ 1  for every maximal clique K of G^{∨k},
                    p_v ≥ 0.                                           (LP-E1)

This is the fractional vertex-packing LP under maximal-clique (exclusivity)
constraints — the "product-ansatz gluing LP" of probe P3. The **per-copy score**
is `S_k(G) = L_k(G)^{1/k}`.

**Anchors (exact; any deviation ⇒ the formalization is wrong — do not fudge):**

| target        | `L_k` exact | per-copy `S_k`         | note |
|---------------|-------------|------------------------|------|
| L_1(C5)       | 5/2         | 5/2 = α*(C5)           | KCBS |
| L_2(C5)       | 5           | √5                     | Cabello 2-copy |
| L_3(C5)       | 25/2        | (25/2)^{1/3} ≈ 2.3208  | k=3 discriminator, > √5 |
| L_1(C7)       | 7/2         | 7/2                    | control |
| L_2(C7)       | 49/4        | 7/2  (**not** θ(C7)²≈11.008) | control |
| L_3(C7)       | 343/8       | 7/2                    | control |

All six reproduced exactly by `essay005_p3_gluing_lp.wl` → `p3_certificates.json`
(gate verdict PASS). **[ESTABLISHED-in-project]** Trap 1 (score against `S_k`,
never `θ(G)`) and Trap 2 (possibilistic layer is blind — `essay005_p1_p4.wl`,
TRAP 2 CONFIRMED) are the two failure modes this construction must avoid; it
avoids both by construction (weighted, not support; scored on `L_k`).

---

## 1. The coefficient object: a `[0,1]`-semimodule, not a `Z`-module

**[ESTABLISHED-in-project]** P1 (`essay005_p1_p4.wl`, verdict "TRAP 2
CONFIRMED") proved the AB **support** presheaf (coefficients in the `Z`-module of
the free abelian group on sections) is *constant* across classical→quantum→α*
wherever supports coincide, so no `Z`-module Čech invariant can output √5. The
invariant must therefore live in a presheaf whose coefficients form an **ordered
idempotent-free `[0,1]`-semimodule**, i.e. carry the additive partial monoid of
sub-probability weights, where the LP layer (`ContextualFraction`,
`GlobalSectionQ`) is exactly the part that *moves*.

Concretely fix the semiring `R = (Q≥0, +, ×)` (rational to keep exact simplex
arithmetic; `[0,1] ⊂ R` is the sub-probability sub-poset). Coefficient object of
the presheaf below is the free `R`-semimodule on events, cut down by a
normalization (an **effect-module** / effect-algebra structure in the sense of
Roumen; the `Σ ≤ 1` cap is the effect-algebra partial sum). **[NEW-claim]** this
is the right coefficient home for the ESSAY-005 invariant; it is the coefficient
object Montanhano's `R`-contextuality (arXiv:2104.11411) parametrizes, so the
construction sits inside an existing semimodule-Čech framework.

---

## 2. The weighted GE presheaf `F`

Cover / site. The cover `U(G^{∨k})` has one open per **maximal clique** `K` of
`G^{∨k}` (a maximal set of pairwise-exclusive events = a measurement context in
the GE reading). Nerve intersections are vertex-set intersections `K ∩ K'`.
(This is `CoverScenario`'s cover data, generalized from the 5-edge single-copy
cover to the maximal-clique cover of the power; P3 builds it via `FindClique`.)

Sections. For an open `K` define

    F(K) = { w : K → [0,1]  |  Σ_{v∈K} w(v) ≤ 1 }   ⊂  R^K,

the **subnormalized weightings** on `K` (a sub-`R`-semimodule-with-cap; the
project's P3 name). For a subset `A ⊆ K`,

    restriction  ρ^K_A : F(K) → F(A),   ρ^K_A(w) = w|_A         (RESTRICT)

is coordinate projection (drop events outside `A`). Functoriality
`ρ^A_B ∘ ρ^K_A = ρ^K_B` is immediate, and `Σ w|_A ≤ Σ w ≤ 1` so it lands in
`F(A)`: `F` is a genuine presheaf of `R`-semimodules-with-cap on `U`.
**[ESTABLISHED-in-project]** P3 records that with these restriction maps the
presheaf **glues trivially**: because sections are *point-functions* on a shared
event set, two local weightings agree on `K ∩ K'` iff they are the two
restrictions of a single global function `p : V_k → [0,1]`. Hence:

Gluing / global sections.

    H^0(F) := { compatible families }  ≅
              { p : V_k → [0,1]  |  Σ_{v∈K} p_v ≤ 1  ∀ maximal clique K }.  (H0)

`H^0(F)` is exactly the **packing polytope** `P(G^{∨k})` of LP-E1. This is not a
conjecture — it is forced by the point-function form of the sections.

---

## 3. The candidate invariant (the checkable claim)

### 3a. Primary claim — `S_k` is a **degree-0 capacity** of `F`  **[NEW-claim, checkable]**

Define the **total-mass functional** `μ : H^0(F) → R`, `μ(p) = Σ_v p_v` (an
`R`-semimodule homomorphism = the "global counting section"). The candidate
invariant is its **ordered supremum over global sections**:

    Λ_k(G) := sup_{ p ∈ H^0(F) }  μ(p)  =  max total mass of a global section.  (INV)

Claim (INV = LP-E1): **`Λ_k(G) = L_k(G)`**, hence `S_k = Λ_k^{1/k}`.

This is a *degree-0* statement: `Λ_k` is the value of a linear functional
maximized over `H^0(F)`; it is the "capacity" of the top of the global-section
semimodule under `μ`. It is **not** an `H^1`, not a torsion order, not an
obstruction class. Calling it "cohomological" is honest only in the weak sense
that `H^0` of a (co)sheaf is its global-section object; the resource content is
an *optimization over* `H^0`, not a class *in* any `H^{≥1}`.

Why this is the right altitude (and why P3 already half-proved it): the
support-presheaf Čech tower is blind (P1); the moving quantity is the LP layer;
LP-E1 is literally a functional on `H^0(F)`. So the "cohomological invariant that
computes `S_k`" is, at this altitude, `sup μ` on `H^0` — nothing higher is
needed to *reproduce the anchors*, and nothing lower (support level) can.

### 3b. LP-dual class — a `Q≥0`-valued Čech 0-cochain on the cover  **[NEW-claim, checkable]**

By strong LP duality, `Λ_k(G)` equals the **fractional clique-cover number**:

    Λ_k(G) = min_y  Σ_K y_K
             s.t.   Σ_{K ∋ v} y_K ≥ 1  ∀ v ∈ V_k,
                    y_K ≥ 0   (y : maximal cliques → Q≥0).                (LP-D1)

Read `y` as a **0-cochain on the nerve of the cover** valued in `R = Q≥0`: it
assigns a weight to each context (open) and the coverage constraint
`Σ_{K∋v} y_K ≥ 1` is a **partition-of-unity condition softened to an
inequality**. The optimal `y*` is the "GE bound as a fractional partition of
unity" — the dual class witnessing `S_k`. This IS the "specific Čech 0-cochain =
fractional clique-cover certificate" the P3 spec anticipated.

**Dichotomy the dual class must exhibit (the discriminating content):**

- **C5, k=2:** `y* = 1` on the five slope-`a` pentads `{(i, a·i+j mod 5)}` is an
  **EXACT integer partition of unity** — the 5 pentads are disjoint and cover all
  25 events; `Λ_2 = 5`. **[ESTABLISHED-in-project]** the exact simplex dual came
  back supported precisely on these five weight-1 pentads (`p3_certificates.json`,
  gate "solver dual (C5,k=2) supported on pentads, exact partition, value 5").
- **C7, k=2:** `y* = 1/4` on the 49 edge-square 4-cliques — a **properly
  fractional** cover; `4 ∤ 49`, so **no integer partition of unity exists**;
  `Λ_2 = 49/4`. **[ESTABLISHED-in-project]** (gate "solver dual (C7,k=2) value
  49/4 (fractional cover, no partition)"). Likewise `y*=1/8` on 343 edge-cubes at
  k=3, `8 ∤ 343`.

### 3c. Where a genuine `H^1` can live — the integrality obstruction  **[CONJECTURE]**

The one place a true higher class appears is the **obstruction to promoting the
optimal fractional partition-of-unity 0-cochain `y*` to an integral one** (a
literal partition of `V_k` into cliques = a section of the "colour/context-
assignment" co-presheaf). Conjecture:

> **[CONJECTURE C-A1]** There is a semimodule Čech `H^1` (Montanhano-style, over
> `R = Q≥0` or its tropical limit; equivalently a lattice/quantale Tarski-Laplacian
> `H^1` of a co-presheaf of clique-colourings) whose vanishing is equivalent to
> "the fractional GE optimum `Λ_k` is attained by an EXACT partition of unity",
> i.e. `H^1 = 0` for (C5,k=2) and `H^1 ≠ 0` for (C7, k=2,3). Its magnitude tracks
> the integrality gap `Λ_k − (integral clique-cover number)`.

C-A1 is a *conjecture*, not a derivation. It is the sharp, testable form of
ESSAY-005's "which cohomological invariant?" question. Note it does **not** and
must **not** move `L_k` off its anchors: `Λ_k` (INV/LP-D1) already equals `L_k`
regardless of whether `H^1` vanishes; `H^1` only classifies *how* the optimum is
realized (exact vs fractional). This is why the construction correctly refuses to
produce `θ(C7)`: `Λ_2(C7)=49/4` is forced by LP duality; the C7 `H^1 ≠ 0` merely
records that the certificate is fractional, consistent with Choudhary–Barbosa
flatness at `S=7/2`.

---

## 4. Category-error guards (the main risk, named)

1. **Altitude error.** `S_k` is degree-0 (a sup over `H^0`), NOT an `H^1`/torsion
   class. Any Phase-3 claim of the form "`S_k = |H^1(...)|`" is almost certainly a
   miscount; the honest higher invariant (C-A1) classifies the *dual's
   integrality*, not the *value*. Keep the two ledgers separate.
2. **Semiring error.** The invariant is a supremum in an ordered `Q≥0`-semimodule;
   it is not a rank/dimension over a field and not an order over `Z`. Do not
   reuse the support-presheaf's Smith-normal-form order machinery here — that is
   the blind layer (P1).
3. **Product error.** Adjacency is the **conormal** power (adjacent in ≥1
   coordinate), not the strong/tensor power. The pentad-partition certificate and
   the 535/1715 clique censuses are conormal facts; a strong-product cover gives
   different numbers and would miss the anchors.
4. **Per-copy vs LP-value error.** Anchors come in two currencies: `L_k` (the LP
   value: 5, 49/4, …) and `S_k = L_k^{1/k}` (√5, 7/2, …). State which is being
   matched at every step; `√5` is `L_2(C5)^{1/2}`, the LP value is the rational 5.

---

## 5. Validation plan for Phase-3 (exact acceptance conditions)

Implement `F`, `ρ`, `H^0` and both LP faces, then require ALL of:

1. **INV = LP-E1 reproduction.** Build `H^0(F)` as the packing polytope of
   `G^{∨k}`'s maximal-clique cover; compute `Λ_k = sup μ` by exact rational
   simplex. Require exactly: `Λ_1(C5)=5/2`, `Λ_2(C5)=5`, `Λ_3(C5)=25/2`,
   `Λ_1(C7)=7/2`, `Λ_2(C7)=49/4`, `Λ_3(C7)=343/8`. (Reuses P3's
   `exactPackingLP`; k=3 via the certificate sandwich, no census.)
2. **Dual 0-cochain (LP-D1).** Compute `y*` by the dual simplex; verify
   `Λ_k = Σ y*`. Verify the **exact-partition** property at (C5,k=2): support =
   five pentads, all `y*=1`, disjoint, covering 25 events. Verify the
   **no-partition** property at (C7,k=2 and k=3): support fractional, coverage
   `≥1` tight, and no integral partition exists (`4∤49`, `8∤343`).
3. **Trap-1 control.** Assert `Λ_2(C7) ≠ θ(C7)²` (`RootReduce[49/4 − θ(C7)²]≠0`)
   and per-copy `S_2(C7)=S_3(C7)=7/2` flat.
4. **Trap-2 cross-check.** Confirm (cite `p1p4_*.csv`) the support-presheaf
   invariants are constant on the same models — i.e. the moving quantity is
   `F`'s LP layer, not any `Z`-module class.
5. **[CONJECTURE test] C-A1.** Construct a candidate semimodule/lattice `H^1` of
   the clique-colouring co-presheaf; test the prediction `H^1=0` at (C5,k=2) and
   `H^1≠0` at (C7,k=2,3). A clean pass = the ESSAY-005 invariant question is
   answered *including* the higher class; a clean failure = report the obstruction
   (the value `S_k` is degree-0-only and no natural `H^1` refines the
   integrality gap) — equally a result per project ethos.

Gates 1–4 are derivations already backed by `p3_certificates.json` and are the
minimum bar; gate 5 is the genuinely open, conjectural step.

---

## 6. One-paragraph honest summary

`S_k` is reproduced exactly, on both C5 and the C7 control, as a **degree-0
capacity** of the weighted GE presheaf `F`: the max total mass over its global
sections `H^0(F)` (= the packing polytope), dual to a `Q≥0`-valued Čech
0-cochain that is an **exact partition of unity for (C5,k=2)** and a **properly
fractional cover for C7** (`4∤49`, `8∤343`) — which is precisely why it yields
`√5` for the pentagon and stays at `7/2` for C7 rather than collapsing to
`θ(C7)`. That much is a **derivation** (P3-backed). The claim that a genuine
`H^1` (semimodule/tropical) refines this by detecting the exact-vs-fractional
integrality obstruction — vanishing for (C5,k=2), non-vanishing for C7 — is a
**conjecture** (C-A1), and is the sharp form of ESSAY-005's open "which
cohomological invariant" question handed to Phase-3.
