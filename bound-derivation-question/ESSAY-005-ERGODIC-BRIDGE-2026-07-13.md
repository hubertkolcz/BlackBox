# ESSAY-005 / ERGODIC BRIDGE — master synthesis (2026-07-13)

**Role: INTEGRATOR.** This is the essay-ready assembly of three formalization
legs that were built and adversarially reviewed on 2026-07-13. It states, per
leg, the precise result, its honest status, the anchors reproduced, what is
borrowed machinery vs new contribution, and the exact statement that stays open.

**Governing honesty verdict (survives three independent reviews, zero fatals):**
The two contextuality-related cohomologies (static Abramsky–Brandenburger /
GE-composed-bound side, and dynamic ergodic-optimization / Bousch–Livšić side)
were each **repackaged** as a natural instance of existing (co)sheaf machinery,
and both repackagings reproduce their anchors exactly. **No genuine cohomological
bridge between the two sides was built.** The one claim that would have unified
them — a single `T→0` dequantization carrying the static GE sheaf onto the
dynamic certificate — is a **category error**, and is reported here as a
refuted-as-posed **obstruction**, which is itself a legitimate result under the
project ethos.

Status tags: **[established-in-project]**, **[new-claim]** (checkable, first
stated here), **[conjecture]** (plausible, unproven).

Source specs: `ESSAY-005-BRIDGE-formalA-weighted-presheaf.md`,
`ESSAY-005-BRIDGE-formalD-debruijn-cosheaf.md`,
`ESSAY-005-BRIDGE-formalC-tropical-limit.md`.
Implementations: `bridge_weighted_presheaf.wl`/`.json`, `bridge_verify_A.py`,
`bridge_debruijn_cosheaf.wl`, `bridge_verify_D.py`, `bridge_verify_D_k{3,4,5}.json`,
`bridge_tropical_limit.wl`, `bridge_static_falsifier.py`, `p3_certificates.json`.

---

## Leg A — weighted-presheaf invariant for S_k  ·  STATUS: CONSTRUCTION (degree-0); higher-cohomology question OPEN

**Result.** `S_k(G)` is reproduced exactly as a **degree-0 capacity** of the
weighted GE presheaf `F`. Sections over a maximal clique `K` are subnormalized
weightings `F(K) = {w:K→[0,1], Σw ≤ 1}` over the effect-module `R = (Q≥0,+,×)`;
restrictions are coordinate projection. Because sections are point-functions on a
shared event set, `F` **glues trivially**, so `H^0(F)` is exactly the packing
polytope of the k-fold conormal power `G^{∨k}`. The invariant is
`Λ_k(G) = sup_{p∈H^0(F)} Σ_v p_v` (the total-mass functional maximized over global
sections) `= L_k(G)`, and `S_k = Λ_k^{1/k}`. Its LP dual is a `Q≥0`-valued Čech
0-cochain = fractional clique-cover certificate.

**Anchors reproduced (exact; verified in two independent runs — Wolfram exact
simplex + scipy LP + independent ω):**
- `Λ_1(C5)=5/2` → per-copy `5/2`.
- `Λ_2(C5)=5` → per-copy `RootReduce = √5` (exact irrational); census `C5^{∨2}=535={4:525,5:10}`, ω=5.
- `Λ_2(C7)=49/4` → per-copy `7/2`; `RootReduce[49/4 − θ(C7)²] ≠ 0` (does NOT sag to θ(C7)²≈11.007). Census `C7^{∨2}=1715={4:1715}`, ω=4. (Trap-1 control holds.)
- `Λ_3(C7)=343/8` → per-copy `7/2`; tight sandwich with `ω(C7^{∨3})=8` now directly confirmed (no longer a citation).
- Dual 0-cochain: **exact integer partition of unity** at (C5,k=2) — five weight-1 slope-pentads, disjoint, cover all 25 events; **properly fractional** at C7 (y=1/4 on 49 edge-squares, 4∤49; y=1/8 on 343 edge-cubes, 8∤343). This dichotomy is exactly why the pentagon gives √5 and C7 stays flat at 7/2.

**Borrowed vs new.** Borrowed: fractional vertex-packing / clique-cover LP
duality; the effect-module / R-contextuality coefficient home (Montanhano
arXiv:2104.11411). New to the project: packaging the GE composed-bound
optimization as `sup μ` over `H^0` of a `[0,1]`-semimodule presheaf, with the
LP dual read as a Čech 0-cochain (softened partition of unity). No new theorem.

**Exact open statement.** ESSAY-005 asks "**which cohomological invariant equals
S_k?**" This leg answers it **only at degree 0**: `S_k` is a capacity of `H^0`,
not a class in any `H^{≥1}`. The genuinely open question is **conjecture C-A1**:
whether a semimodule/tropical Čech `H^1` of the clique-colouring co-presheaf
vanishes iff `Λ_k` is realized by an exact partition of unity (predict `H^1=0`
at (C5,k=2), `H^1≠0` at C7). What was actually computed is an integrality-gap
**PROXY** (denominator test on `Λ_k`), matching the predicted pattern, **not** a
proven cohomology group. So the higher-class form of ESSAY-005's question
remains **UNANSWERED**. Honest caveat the reviews insist on: "H^0-as-global-
sections of a trivially-gluing presheaf" is the LP feasible set — calling `Λ_k`
"cohomological" is honest only in the weak sense that `H^0` is the global-section
object; the resource content is optimization *over* `H^0`, not a class *in*
higher cohomology.

---

## Leg D — sub-action = cellular 0-cochain on the de Bruijn-k graph  ·  STATUS: CONSTRUCTION (materialized windows); no higher cohomology

**Result.** The windowed ε-certificate is packaged as a **cellular (co)sheaf on
the de Bruijn-k graph** with (max,+) tropical stalks: 0-cells = length-k windows,
1-cells = transitions, stalks `T = R_max`. The sub-action `Ψ` is a 0-cochain
`Ψ:V→R`; the edge payoff `c(e)=d(x)−r(e)` is a 1-cochain; the certificate
inequality `σ(e) ≤ Γ_k` rewrites exactly as `LΨ ≤ Γ_k ⊙ Ψ` — i.e. `Ψ` is a
Γ_k-super-eigenvector (calibrated sub-action) of the (max,+) transfer operator
`L`. By the max-plus spectral theorem, `Γ_k` = the unique tropical eigenvalue
= max cycle mean of `c`, with min–max duality `Γ_k = min_Ψ ‖c ⊙ δΨ‖_∞`.

**Anchors reproduced (exact rational `max_e σ = Γ_k`, plus independent Karp
max-cycle-mean cross-check to sliver < 1.3e-8):**
- k=3: `0.1250040` (doc 1/8) · k=4: `0.1019686` (= brief Γ_3=0.1020) · k=5: `0.0953015` (= brief Γ_5=0.0953) · k=7: `0.0770624` · k=8: `0.0753086`. All five materialized windows pass all three properties (pointwise sub-action bound; exact dual attainment; independent Karp sliver).
- **k=6 (= brief Γ_5=0.0824): PARTIAL.** Two independent strategy-iteration seeds both converged to `Γ_6 = 0.08235129` (matches 0.0824), but the certificate file did not materialize (`k6_gen.log`: "product exited"), so the independent cosheaf/Karp cross-check is **not yet closed** for k=6. Value corroborated; full validation open.

**Indexing note (non-negotiable).** Window size = word length k is authoritative
(matches `CaseStudies.wl` D3_*). The task brief's Γ labels are shifted one index:
brief Γ_3=0.1020 is window k=4, brief Γ_5=0.0824 is window k=6.

**Borrowed vs new.** Borrowed (and rigorous, NOT new mathematics): `Γ_k` = max
cycle mean (Karp); certificate inequality = Bousch/Mañé–Conze–Guivarc'h
sub-action; `Γ_k` = (max,+) eigenvalue with bias-vector = eigenvector
(Cuninghame-Green; BCOQ; Akian–Gaubert policy iteration — the generator's
"strategy iteration" *is* this). New to the project, but MODEST: casting it as a
tropical cellular (co)sheaf (Ghrist–Riess Tarski Hodge theory) — a genuine change
of *object* from the rejected real-valued sheaf Laplacian (SH-004), but it
produces **no new number**.

**Exact open statement.** On a graph there is only `δ^0`; `δ^1=0` vacuously, so
**there is no genuine higher cohomology** — reviews correctly call the
cellular-sheaf label "decorative." The construction's only real payoff is
upgrading `Ψ` from an ad-hoc SDP potential to a cohomological 0-cochain. Open
items: (i) close k=6 with the independent cross-check; (ii) `R_max` is a semiring,
not a ring — there is no derived-functor abelian `H^1` here, and any "deep
cohomological invariant" claim overstates it.

---

## Leg C — tropical-limit / Maslov-dequantization bridge  ·  STATUS: PARTIAL (within-side dequantization holds; cross-side unification is an OBSTRUCTION)

**Result — two clearly separated claims.**

1. **[within-side, holds numerically — new packaging of established theorems].**
   The dynamic `Γ_K` is a genuine zero-temperature limit of a `(+,×)` Ruelle
   transfer operator built from the certificate's *own* payoff:
   `F_K(β) = (1/β) log ρ(exp(β A^{(K)}))` decreases in β and `→ Γ_K`. Verified:
   K=3 cert/mcm 0.12500 (doc 1/8); K=4 0.10197 (doc 0.101964); K=5 0.09530 (doc
   0.095297) — match to ~4e-6, the documented rationalization sliver. This is
   Maslov dequantization of the certificate's max-plus operator (Litvinov–Maslov;
   Baraviera–Leplaideur–Lopes pressure → ergodic optimization).

2. **[cross-side unification — OBSTRUCTION, refuted as posed].** The claim that
   the dynamic `Γ_K` is the `T→0` limit of the *static* GE weighted-sheaf LP
   (value `S_k`) is a **category error**. Static falsifier confirms:
   `S(C5;T) → 5/2` (the packing number) as `T→0` for T in [1, 1e-3] — it returns
   the packing value, exhibits **no** de Bruijn / mean-payoff structure, and does
   **not** select `cct`. The two LPs live on different base spaces (conormal
   powers of C5 vs de Bruijn `{c,t}` words), the static side has no shift/ergodic
   average (finite k copies ≠ orbit length →∞), and no operator homomorphism
   carries one onto the other. Each side dequantizes its **own** Ruelle operator —
   a generic thermodynamic fact holding for any payoff, blind to `cct` (the
   contextuality optimizer).

**Anchors / context used.** gap(cct)=0.0698975 (irrational); τ*=1.37671774591586;
cis density 3/2. Static T→0 limit = 5/2 (packing), not any Γ_K.

**Borrowed vs new.** Borrowed: Maslov/Litvinov dequantization; pressure →
ergodic-optimization; Bousch–Mairesse / Chazottes–Hochman non-selection. New: the
project framing + the honest **negative** result that the two sides do NOT unify
under one dequantization.

**Exact open statement.** Two things stay open (and are *conjectural, at risk*):
(i) the visibility family V (CF-004) as temperature — calibratable but not
established, and asserting the *same* V is the temperature on *both* sides is
exactly the refuted cross-side leap; (ii) whether `cct` is the `T→0` equilibrium
measure `μ_β → δ_cct` — **fragile**: the observed orbit-crowding (near-optimal
periodic words 16/11, 19/13, 25/17, … crowding the irrational gap(cct)) is direct
evidence the finiteness property may fail, so selection can fail even though the
value leg `F_K(∞)=Γ_K → gap(cct)` holds. Global optimality of `cct` is itself
open in-project.

---

## How this answers ESSAY-005

ESSAY-005 asks: *which cohomological invariant of the weighted presheaf equals
`S_k`?* The honest answer this synthesis supports:

- **At degree 0: answered.** `S_k = (sup_{H^0(F)} total mass)^{1/k}` — the
  degree-0 capacity of the weighted GE presheaf, dual to a fractional
  clique-cover Čech 0-cochain. This reproduces C5 **and** the C7 control exactly
  and is forced by LP duality (P1 already proved the possibilistic/support layer
  is blind, so the invariant must be of the weighted, [0,1]-semimodule presheaf —
  confirmed).
- **At degree ≥1: unanswered.** There is no established higher cohomology class
  equal to `S_k`. The sharp open form is conjecture C-A1 (a semimodule/tropical
  `H^1` detecting exact-vs-fractional partition of unity), for which only an
  integrality-gap **proxy** was computed — matching the predicted pattern but not
  a proven cohomology group.

So ESSAY-005's core question has a clean degree-0 answer and an unresolved
higher-degree question; the dynamic legs (D, C) do not close it, because — as
Leg C establishes — the dynamic side is a *different kind of object*
(mean-payoff on a shift) that does not unify with the static packing number.

## What a genuine unification would still need

1. **A common base system.** A single shift/dynamical system whose one-parameter
   (temperature/visibility) family of operators specializes to BOTH the static GE
   packing LP and the dynamic de Bruijn mean-payoff certificate. None is known;
   the static side's only "dynamical" axis is the copy-number k (Cabello product,
   Θ(C5)=√5 growth rate) — a *different* shift from the gluing shift `{c,t}^Z`.
2. **A real higher cohomology, not a proxy.** A proven semimodule/tropical Čech
   `H^1` (Montanhano-style, or a lattice/Tarski-Laplacian `H^1`) whose class —
   not a denominator test — equals or refines `S_k` (C-A1), with the C5/C7
   dichotomy as a theorem.
3. **A selection theorem on the dynamic side.** A finiteness-property proof (or
   its failure) settling whether `μ_β → δ_cct`, converting the value-leg
   convergence into an equilibrium-state statement — the piece orbit-crowding
   currently threatens.
4. **A operator homomorphism** connecting the (+,×) static Ruelle operator and the
   (max,+) dynamic transfer operator beyond each side's own T→0 limit. Leg C's
   falsifier shows the naive identity fails; any bridge must supply this map or
   concede the category distinction is permanent.

## Ledger cross-links

- **ESSAY-005** — core question (weighted-presheaf invariant for S_k): Leg A answers degree-0, leaves C-A1 open.
- **SH-004 / SH-006** — the rejected real-valued sheaf Laplacian as a contextuality measure; Leg D's tropical cellular sheaf is the distinct, viable object superseding that rejection (idempotent Hodge theory, H^0 = global sections). `SupportCohomology.wl`'s honest Z-module Čech H^1 is a *different* object on the *blind* support presheaf (P1).
- **D3_*** (`pentagon-gluing/CaseStudies.wl`: `D3_epsilonCertificate`, `posSigma`/`posCheck`) — the certificate data Leg D/C transcribe verbatim; τ*, cis 3/2, alpha-cis theorem are the dynamic-side anchors.
- **CF-004** — the visibility/noise family V; Leg C's "V as temperature" is calibratable but conjectural, and the cross-side "same V both sides" identification is the refuted leap.

## Overall verdict

**PARTIAL / OBSTRUCTION.** Three correct, exactly-anchored, honestly-caveated
repackagings: A (degree-0 capacity for S_k, construction), D (sub-action =
tropical 0-cochain, construction on materialized windows), C (each side's own
Maslov dequantization, partial). **Zero genuine cohomological bridges between the
two cohomologies.** The single unification claim (static = dynamic via one
dequantization) is a category error, cleanly refuted — a legitimate obstruction
result. ESSAY-005's higher-cohomology question (C-A1) and the dynamic selection
question stay open.
