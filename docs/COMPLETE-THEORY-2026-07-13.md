# THE COMPLETE THEORY — 2026-07-13

Definitive per-question synthesis of the five-lane integration push, after two
independent review passes (both verdict **sound**; all findings **minor** —
no fatal/major correction forced a label downgrade). Every claim below carries
one of: **theorem** / **conditional-theorem** / **certified-numeric** /
**strong-evidence** / **conjecture** / **refuted-route**.

Review-driven clarifications are folded into each lane's EVIDENCE / WHAT REMAINS
and collected in the closing caveats. Ledger keys are cross-referenced inline.

---

## Q1 — ddt-optimality: can a Legendre theta-frontier close the window?

**Question.** Can a certified Legendre theta-frontier
`frontier_k(fc) = min_lambda [ Gamma_k(lambda) + lambda*fc ]`, combined pointwise
with the exact nonlinear alpha floor `max(4/3, 1+fc/2)`, beat the flat gap
certificate `Gamma_k` and drive the sup gap toward `gap(ddt) = 0.0698975`?

### THE MAXIMAL ANSWER — **theorem** (obstruction, enumeration-independent)

**NO.** Any certified frontier `frontier_k(fc) = min_lambda[Gamma_k(lambda)+lambda*fc]`
with `Gamma_k(lambda) >= sup_w[theta-bar(w) - lambda*fc(w)]` is the lower envelope
of affine forms, i.e. it certifies exactly the **upper concave hull** of exact
`theta-bar` over `fc`. That hull is **pinned flat at 3/2 on the entire interval
fc in [1/2, 1]**: the words `ct` (fc=1/2) and `dddt` (fc=3/4) both have exact
`theta-bar = 3/2`, and `theta-bar <= 3/2` is the global ceiling. ddt sits at
`(fc=2/3, theta-bar=1.4032309)`, a **strict interior point 0.0967691 below the
hull**. Because ddt is not on the concave hull, **no single supporting hyperplane
(no Legendre frontier, for any window k, any theta bound) exposes it.** The
enrichment is therefore inert: the certifiable gap-bound at fc=2/3 is
`>= 3/2 - 4/3 = 1/6 = 0.1667`, strictly **worse** (larger) than the flat
`Gamma_9 = 0.0720260`, so it cannot drive the sup gap toward gap(ddt).

This is the theta-frontier generalization of the established result that the
**affine alpha-credit tilt is proven inert** (any affine-in-`fc` credit caps the
certifiable limit at ~0.076 off-ddt). Both say the same thing: linear/affine
enrichment of a flat certificate cannot expose an interior optimum.

### THE EVIDENCE
- Exact concave-hull computation: hull(2/3) = 3/2 exactly; ddt actual 1.4032309;
  interior gap 0.0967691; `max_fc[hull(fc) - floor(fc)] = 0.1666667`.
  File: `pentagon-gluing/final_ddt_hull.py` (re-run 2026-07-13, confirmed).
- theta-bar = 3/2 achieved across fc in [1/2,1] by the family `ct, dddtdt..., dddddt...`
  (enumerated to period 14) — the flat ceiling is realized, not just bounded.
- k=9 certified numeric frontier corroboration:
  `pentagon-gluing/final_ddt_frontier_k9.txt`
  (gammaNum/gammaDen exact; 512 nodes, 1024 edges).
- Falsification harness: `final_ddt_falsify.py`; frontier drivers
  `final_ddt_frontier.py`, `final_ddt_frontier_export.wl`.
- Anchors (established, cited not re-derived): `gap(ddt)=0.0698975` (irrational);
  `Gamma_10=0.0714575` (numeric), `Gamma_9=0.0720260` (exact); alpha-direct theorem
  `alpha-bar(w) >= max(4/3, 1+f_d/2)`, equality at 4/3 iff `w=(ddt)^k`.

### WHAT REMAINS
The obstruction closes the **Legendre/affine-in-fc route** specifically. The
ddt-optimality window `[gap(ddt)=0.0699, Gamma_9=0.0720]` — the interval between
the true optimum and the best flat certificate — stays **open**. Closing it
requires a certificate that is **genuinely nonlinear in the frequency coordinate**
(a supporting object that can bend to touch an interior point), OR a different
invariant than `(fc, theta-bar)` in which ddt becomes extremal. Any method whose
certified output is an affine/concave envelope of a per-word bound is now provably
ruled out. **Open statement:** does there exist a per-word functional `Phi(w)`,
nonlinear in fc, with `sup_w Phi = gap(ddt)` attained only on `(ddt)^k`?

---

## Q2 — ESSAY-005: is delta(y* mod Z) a genuine H^1 obstruction class?

**Question.** Is `delta(y* mod Z)` — the connecting map of `0 -> Z -> Q -> Q/Z`
applied to the mod-Z reduction of the optimal LP-dual 0-cochain `y*` on the
maximal-clique cover of the conormal power `G^vk` — a genuine, gauge-invariant
`H^1` class detecting quantum-achieved (H^1=0 at C5,k=2) vs stuck (H^1 nonzero at
C7,k=2,3)?

### THE MAXIMAL ANSWER — **refuted-route** (rigorous obstruction, three grounds)

**NO — REFUTED.** `delta(y* mod Z)` is neither well-defined nor gauge-invariant,
and where it *is* defined it is forced to 0. It can never be the nonzero detector
the conjecture required. Three independent, exactly-verified grounds:

1. **Cocycle prerequisite fails.** `delta: H^0(U;Q/Z) -> H^1(U;Z)` is defined only
   on 0-cocycles, i.e. needs `y*(K) == y*(K') mod Z` on every overlapping clique
   pair. The canonical C7,k=2 dual (`y = 1/4` on the 49 edge-squares) has
   **20776 bad overlaps** where a `1/4`-clique meets a `0`-clique. So delta is
   **UNDEFINED exactly in the fractional/stuck case** it was meant to flag nonzero.
2. **Gauge non-invariance.** The packing-LP optimal dual face is
   positive-dimensional. At C5,k=2 the pentad-partition optimum `y=1` is a defined
   cocycle (delta=0), while another equally-optimal dual (`y=1/2` on both
   partitions) is not even a cocycle (3000 bad overlaps). The candidate "class"
   depends on which optimum is chosen — not a gauge invariant, hence not a class.
3. **Forced zero where defined.** The nerve is connected, so
   `H^0(U;Q/Z) = Q/Z` (global mod-Z constants only). `ybar` is a cocycle iff `y*`
   is globally constant mod Z, and delta of a global constant is `[0]`. So whenever
   delta is defined it is **identically 0** — no nonzero value is ever available.

The trivial repair (ordinary Cech coboundary `d(ybar)` in `C^1(U;Q/Z)`) is a
coboundary by construction, hence 0 in `H^1(U;Q/Z)` for every graph — detects
nothing at both C5 and C7.

### THE EVIDENCE
- `bound-derivation-question/final_h1_cocycle_results.json` (verdict + all counts).
- Probes: `final_h1_cocycle_probe.py`, `final_h1_structured_duals.py`.
- Cover data confirmed: C5^v2 = 25 vertices / 535 max cliques / 10 pentads;
  C7^v2 = 49 vertices / 1715 max cliques / 49 edge-squares; nerves connected.
- Structured duals verified exactly optimal: C5,k=2 pentad partition `y=1` -> value 5,
  coverage [1,1]; C7,k=2 edge-squares `y=1/4` -> value 49/4, coverage [1,1].

### WHAT REMAINS
The refutation is **structural, not size-dependent**: any properly fractional dual
(denominator > 1) supported on a strict subset of cliques meets a 0-valued clique
(non-cocycle), and packing-LP optimal dual faces are generically positive-dimensional
(gauge-dependent). This **closes the "H^1 of the maximal-clique cover" route**. It
sharpens formalA Category-Error Guard #1 with the precise mechanism: `y*` lives in
`C^0(Q)`, its mod-Z reduction is a cochain not a cocycle, and the dual is non-unique.

The **positive** degree-0 result stands untouched and is the surviving spine:
**ESSAY-005 degree-0 GE-capacity construction is established** — weighted GE
presheaf capacity `Lambda_k`, `S_k = Lambda_k^(1/k)`, anchors `S1(C5)=5/2`,
`S2(C5)=sqrt5`, C7 control 7/2 at k=2,3 exact. Mechanism: the optimal dual
0-cochain is an **exact integer partition of unity** at (C5,k=2) but **properly
fractional** at C7 (4 does not divide 49; 8 does not divide 343). That
integer-vs-fractional distinction is real and load-bearing — it just **does not
lift to an H^1 class** of this cover. **Open statement:** is there any natural
cohomological (or other functorial) invariant, on a *different* cover or complex,
whose vanishing coincides with the integer-partition-of-unity condition? The
ergodic-sheaf unification remains **refuted** (category error) and the
possibilistic route **closed** (P1).

---

## Q3 — ERG-003: can bounds eliminate S=17 families, and what is omega(C9vC9vC9vC5)?

**Question.** Can neighborhood clique bounds + layer parity eliminate any of the
residual S=17 pentagram families without exhaustive search, and what is the final
`omega(C9 v C9 v C9 v C5)` verdict?

### THE MAXIMAL ANSWER — **refuted-route** (bound-inertness, certified) + honest open verdict

**Bound-inertness (constructive + numerically certified).** **NO** single-neighborhood
clique bound and **NO** layer-parity counting eliminates *any* pentagram family with
`S <= 18`; run over all **26** families, the bound pass eliminates **0**.

**KEY LEMMA.** For any layer m, placing `Q_m` as an `s_m`-subset of a product 8-clique
`e1 x e2 x e3` of H gives `omega(cn(Q_m)) >= 8 - s_m` (the complementary `8-s_m`
vertices form a clique inside the common H-neighborhood; certified for `s_m = 1..7`).
Since the family generator enforces `s_m + s_partner <= 8` for each pentagram pair,
every neighborhood bound is satisfied with slack — the bounds are **inert** by
construction, independent of the specific family.

**Final verdict — honest and open.** `omega(C9 v C9 v C9 v C5)`: the existence of a
17-clique is **undecided**. No 17-clique witness was found anywhere; **2 of 26**
families are exhausted **NO** by exact search (not by bounds); the remaining **24**
are **PARTIAL** (no witness, not exhausted). The activation threshold is unchanged:
`omega in {16..19}`, activation iff `omega >= 18`; `omega(H) = 8` proven
(`(1+sec(pi/9))^3 < 9`). So the theory neither confirms nor refutes S=17; it
records a **precise obstruction to the cheap route** and leaves the exhaustive
verdict open.

### THE EVIDENCE
- Bound-elim pass: `open-search-frontier/final_erg003_bounds_elim.py` (0/26 eliminated).
- Verdict ledger: `open-search-frontier/erg003_verdict.json`
  (familiesExhausted 2/26; NO=2 [fam00 `(1,1,1,7,7)`, fam01 `(1,1,2,7,6)`], PARTIAL=24;
  totalNodes 69,449,278; no witness).
- Per-family results: `open-search-frontier/erg003_family_results/`;
  f-vector `erg003_fvec.json`; design note `erg003-pentagram-design-2026-07-13.md`.
- Gate-validated solver: `erg003_elim2.py` (exact per-family agreement with the chain
  searcher on C9^v2 S=8,9 and C7^v2 S=9,10, including exhaustive NOs).
- Established context (cited): 5-layer pentagram decomposition proven exactly
  equivalent (68k tests); 26-family census complete;
  "max-8-cliques-of-H-are-products" premise **FALSE** (committed counterexample);
  Ramsey route has a precise obstruction (C5 catalyst has short odd cycles).

### WHAT REMAINS
The 24 PARTIAL families need exact exhaustion to settle S=17. What would close it:
either a 17-clique witness in any of the 24 (proves `omega >= 17`), or exhaustive
`elim2` NO across all 24 (proves `omega = 16`). The bound route is now provably
not the way in — future work must be search-based (elim2 scale-up) or find a
**new** structural invariant sharper than single-neighborhood clique bounds and
parity. **Open statement:** does any of the 24 residual S=17 pentagram families
admit a 17-clique?

---

## Q4 — O3: class-relative completeness + the CV column

**Question.** (A) State + prove a class-relative COMPLETENESS proposition for the
black-box gate set over the intensity-emulator adversary class; (B) derive +
implement the `Sp(2n,R)` leaf-confinement criterion filling the certification-map
CV column (CV analogue of G7).

### THE MAXIMAL ANSWER — **conditional-theorem** (Prop O3-C) + **certified-numeric** (G7-CV)

**Prop O3-C [new-claim, conditional-theorem].** Within the intensity-emulator class
`A_IE` (P>=0 classical light + intensity redistribution up to `alpha* = 5/2` + one
unmodified on-off detector per outcome, fair-sampled, fresh-per-trial), the gate set
`{C1-C5, G7, G7-CV, G8}` is **COMPLETE**: every device is either **DISTINGUISHED**
from a genuine KCBS device or certified **NCHV-BOUNDED** (`alpha <= 2`); none both
reproduces `alpha > 2` and passes every gate. **Proof** = case partition on node sum:
`alpha <= 2 => C1-C5 return NCHV` (verdict b); `alpha > 2 =>` the only `A_IE` route
above the deterministic ceiling is the intensity-vs-single-click semantics gap, which
by the KBS single-detector coherent-forgeability theorem carries the attenuation
signature that **G8 flags** (verdict a). The compilation flank (G7 / G7-CV) audits the
claimed dynamics independently, robust to an adversary who declines the attenuation test.

**G7-CV [new-claim, certified-numeric].** The CV analogue of the G7 so(3)/DLA audit,
implemented and validated exactly: a claimed Gaussian compilation whose dynamical Lie
algebra stays inside `u(n)` (dim `<= n^2`, all generators antisymmetric) is
**passive-confined** = classically emulable by linear optics; one that closes beyond
`u(n)` toward `sp(2n,R)` (a symmetric/squeezing generator appears) is **active**.
Validated in exact arithmetic: `u(2) = 4` (confined); `+ two-mode squeezer ->
sp(4,R) = 10` (active); single-mode squeezer + phase `-> sp(2,R) = 3` (active). This
**fills the certification map's previously-unbuilt CV column** (the CV analogue of G7).

### THE EVIDENCE
- Proof + adversary-class definition: `certification-protocol/final_o3_completeness.md`.
- G7-CV implementation (exact-arithmetic, all anchors pass): `final_o3_cv_dla.py`.
- Base proposition (two-lens necessity, Prop 1/2, Cor 1/2): `PROPOSITION-O3.md`.
- Certification map generator: `certification_map.wl`; kernel `BlackBox/Kernel/BlackBox.wl`;
  CV derivation notes: `.claude/worktrees/hawking-emulation/NOTES-hawking.md`.
- External ceiling (cited, load-bearing): Kovtoniuk-Bohmann-Semenov, arXiv:2601.13869
  (single-detector coherent-forgeability + attenuation signature).
- Established context: Prop 2 = BBT-003 (no table functional bounds the DLA; two-lens
  necessity); OQ1 (theta-blind rig rank 0 vs quantum 2); OQ2 gate G8 validated
  (emulator fails 25/25).

### WHAT REMAINS
Completeness is **exactly as strong as its one load-bearing premise**: the KBS detector
model (every `A_IE` device — classical light + one unmodified on-off detector,
fair-sampled — exhibits the G8 attenuation signature, and G8's thresholds have power at
tested visibilities). G7/G7-CV additionally carry the **white-box trust assumption**
(they audit the *claimed* dynamics, not the actual). The honest open cell (**conjecture**,
successor to SQ1): is `A_IE` the *maximal* classically-emulable class? An adversary
**outside** `A_IE` — photon-number-resolving detection, heralded Fock sources,
engineered non-fair-sampling — is not covered; whether some super-class survives the
full gate set while still counting as "classical emulation" is **open**. **Open
statement:** does a super-class of `A_IE` survive `{C1-C5, G7, G7-CV, G8}`?

---

## Q5 — Paley-13: can the Delsarte LP close or tighten omega(Paley13^{OR3})?

**Question.** Can the Delsarte LP (= Schrijver theta') on the `Z_13^3` translation
scheme close or tighten `omega(Paley13^{OR3})` in `[39, 46]`?

### THE MAXIMAL ANSWER — **theorem** (certified) — the LP route cannot help

**NO.** The Delsarte/Schrijver LP `theta'` for
`omega(Paley13^{OR k}) = alpha(complement(Paley13)^{strong k})`, over the translation
scheme of `Z_13^k` symmetrized by `Gamma = (C_6)^k x| S_k` (per-coordinate QR-multipliers
times coordinate perms), equals **exactly `13^{k/2}` for all k**. In particular
`theta'(k=3) = 13^{3/2} = 46.8721665810...`, floor **46** — **IDENTICAL** to the
pre-existing Lovász-theta ceiling. So the Delsarte-LP route **cannot close** (would need
`< 40`) nor even **tighten** (would need `< 46`) the bracket. `[39, 46]` stands.

The Bose-Mesner algebra of the scheme is commutative, so the SDP collapses to an LP and
the pointwise `b_d >= 0` is exactly the Schrijver strengthening — this LP value *is*
`theta'` on this scheme, and it reproduces `theta` exactly. This is a clean instance of
the project lesson: **the Delsarte LP on a symmetric association scheme = Schrijver
theta-prime there**, and here that equals Lovász theta by theta-multiplicativity
(`theta(P13) = sqrt13`).

### THE EVIDENCE
- LP computation: `open-search-frontier/final_paley13_lp.py` (re-run 2026-07-13):
  `theta'(k=1) = sqrt13 = 3.6055512755`; `theta'(k=2) = 13.0000000000` exact;
  `theta'(k=3) = 46.8721665810 = 13^{3/2}`, floor 46.
- Certification harness: `final_paley13_lp_certify.py`.
- Established context (cited): `omega(P13^v3) in [39,46]`; 39-clique = product of an
  exact 13-clique of `P13^v2` with a triangle, doubly verified; ceiling 46 = `floor(13^1.5)`
  from theta-multiplicativity; ~171M search nodes, no 40-clique; exhaustion walls locally.

### WHAT REMAINS
The bracket `[39, 46]` is **open**. Both linear-programming routes (Lovász theta and its
Schrijver/Delsarte strengthening on the natural translation scheme) are now provably
exhausted at 46 — neither can tighten. Closing requires a fundamentally sharper object:
a higher-order SDP (Lasserre level >= 2 / Gvozdenović-Laurent), a non-abelian
symmetrization, or a targeted search that either finds a 40-clique or exhausts to
prove `omega <= 39`. **Open statement:** is `omega(Paley13^{OR3}) = 39`, and can a
level-2 Lasserre bound get below 46?

---

## THE THEORY AS A WHOLE

### The certification map, updated

This push filled two previously-open cells of the O3 certification map
(`certification_map.wl`). The map's `.wl`-encoded open-cell text predates this session;
the authoritative updated picture is:

- **CV column — FILLED.** Previously "unbuilt (needs an `Sp(2n,R)` re-derivation)". Now
  built: **G7-CV**, the `Sp(2n,R)` leaf-confinement criterion (`u(n)` passive-confined vs
  `sp(2n,R)` active), exact-validated in `final_o3_cv_dla.py`. **[certified-numeric]**
- **Outer boundary — UPGRADED.** Previously a *two-lens necessity* statement. Now a
  *class-relative completeness* statement, **Prop O3-C**: inside `A_IE` the assembled gate
  set `{C1-C5, G7, G7-CV, G8}` is provably exhaustive (every device distinguished or
  NCHV-bounded). **[conditional-theorem]**, load-bearing on the KBS detector model.
- **Still open (sharpened).** The old vague SQ1 "is there an adversary that survives
  everything?" is now the precise question: **does a super-class of `A_IE` (PNR detection /
  heralded Fock / non-fair-sampling) survive the full gate set?** **[conjecture]**
- Unchanged cells: the correlation-lens staircase (A1 static table INDISTINGUISHABLE for
  tuned emulators, defeated only by A3 attenuation/event-semantics); the geometric lens's
  irreducibility (Prop 2 / BBT-003).

Ledger actions registered: `BBT-004` (class-relative completeness of the gate set over
`A_IE`), `BBT-005` (the `Sp(2n,R)` leaf-confinement criterion). Cross-ref `BBT-002` as
Prop 1's blind-spot companion.

### The established spine (cite, do not re-derive)

- **Two-lens necessity (O3 / BBT-003).** No table functional lower-bounds the DLA; the
  correlation lens and the geometric/DLA lens are irreducible. This session extends it to
  a completeness statement inside `A_IE` and to the CV column. **[established + new]**
- **Degree-0 GE capacity (ESSAY-005).** `S_k = Lambda_k^(1/k)`, anchors `S1(C5)=5/2`,
  `S2(C5)=sqrt5`, C7 control 7/2 at k=2,3. The integer-partition-of-unity vs
  properly-fractional distinction (4∤49, 8∤343) is the real mechanism. This session proves
  it is **degree-0-only**: no H^1 of the maximal-clique cover refines the integrality gap.
  **[established + refuted-route on the H^1 lift]**
- **The orbit-spectrum reading (ddt).** Seed values = orbit density − 1 (direct 3/2, twisted
  `tau* = Root[49x^3-128x^2-75x+218,2]`, 16/11, 19/13, 25/17); `gap(ddt)=0.0698975`
  irrational; alpha-direct theorem equality at 4/3 iff `w=(ddt)^k`. This session proves the
  Legendre/affine-in-fc enrichment **cannot expose ddt** (it is a strict interior point of
  the flat-at-3/2 concave hull). **[established + theorem-obstruction]**
- **The exact mesh laws.** `alpha-bar(w) >= max(4/3, 1+f_d/2)`; census exhaustive to
  period 18; balanced/Sturmian words >= 0.012 below ddt; affine alpha-credit tilt proven
  inert. **[established]**
- **The LP = theta' = theta collapse (Paley / ERG-003).** On a symmetric association
  scheme the Delsarte LP equals Schrijver theta', and for `Z_13^k` it equals Lovász theta
  (`13^{k/2}`) — LP routes are exhausted for Paley13^{OR3}. The same LP-duality lens frames
  the ERG-003 bound-inertness. **[theorem + refuted-route]**

### The honest boundary of current knowledge

Four of the five lanes returned **rigorous negatives** — obstructions and refutations,
not resolutions — and they are the strongest available statements, not failures. The
theory now knows, precisely, **which cheap routes are dead**:

- **ddt-optimality window `[0.0699, 0.0720]`:** open. Legendre/affine-in-fc enrichment
  provably cannot close it; needs a genuinely nonlinear-in-frequency certificate.
- **ESSAY-005 H^1 detector:** dead (structural refutation). Degree-0 capacity is the whole
  story; the integrality distinction does not lift to cohomology of this cover.
- **`omega(C9^v3 v C5)` S=17:** undecided. Bounds + parity provably inert (0/26); 2/26
  exhausted NO, 24/26 PARTIAL; needs search, not bounds.
- **O3 completeness:** conditionally closed inside `A_IE` (one load-bearing KBS premise +
  white-box trust); the maximality of `A_IE` is the open frontier.
- **`omega(Paley13^{OR3})` bracket `[39,46]`:** open. Both LP routes exhausted at 46;
  needs level-2 Lasserre / non-abelian symmetrization / targeted search.

The unifying methodological lesson: **flat/linear certificates cannot expose interior
optima, and LP relaxations on symmetric schemes cannot beat their own theta ceiling.**
Every lane that failed, failed for a version of this reason — which is why the negatives
are enumeration-independent and structural, and why the open questions above are each
pinned to a specific sharper tool.

---

*Provenance: assembled 2026-07-13 from the five lane deliverables and two sound review
passes. All numeric anchors re-confirmed this session (ddt hull, Paley LP, ERG-003
verdict, H^1 counts, G7-CV validation). Labels per claim; ledger keys inline. No git
commit performed.*
