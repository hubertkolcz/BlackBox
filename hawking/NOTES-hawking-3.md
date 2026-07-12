# NOTES-hawking-3.md — Third Pass: Does the Cauchy-Schwarz Route Have a Native Reading in This Project's Graph-Invariant Language? Plus a Concrete Finite-Sample Design

Hubert Kołcz's project — 11 July 2026. Branch `claude/hawking-emulation`, built on tip
`d0a47ce40c59474c7bc62dc1e80b27e58b0a34e0` (the second pass). This note is strictly
additive: `NOTES-hawking.md` (first pass) and `NOTES-hawking-2.md` (second pass) were
read in full from that commit before writing anything here, and neither is edited.
Artifact: `hawking_cs_route.py` (executable, exit 0, all internal consistency checks
PASS — every number quoted below with no citation was produced there). It also rereads
`hawking_cf_bridge.py` and `mbqc_blackbox_test.py` for conventions, and `BlackBox.wl`
(master, `BlackBox/Kernel/BlackBox.wl`) directly for the exact SDP/LP forms this repo
uses for `LovaszTheta`, `IndependenceNumber`, `FractionalPackingNumber`, and
`ContextualFraction`/`NoncontextualFraction`, to make sure every claim below is checked
against this project's *actual* conventions, not a generic textbook version of them.

## 0. An honest framing problem, stated up front

This session's task specification asks, as its top priority: does the Cauchy-Schwarz
(CS) route have a reading in this project's α/ϑ/CF language — a two-outcome exclusivity
graph, a KCBS-style odd cycle, or something else? **`NOTES-hawking-2.md` Sec. 2 already
answered this, in full, with a literature-grounded negative finding**: the naive
{H-click, P-click} exclusivity graph is edgeless (ϑ = α = 2, no gap), the de
Nova–Sols–Zapata ratio θ_ud2(x) is a monotone on/off indicator rather than a graded
scale, and all four of this project's existing finite-scenario tools (CF/ϑ, α*,
signed negativity ν, Contextuality-by-Default) were checked and ruled out for one
shared structural reason (a finite measurement scenario is required; the CS bound
supplies continuous-variable second moments instead). Repeating that derivation here
would not be honest work. What this note does instead — read together with, not
instead of, `NOTES-hawking-2.md` §2 — is:

1. **Generalize** the "one graph they tried was vacuous" finding to a proved,
   LP-verified theorem: *every* finite discretization of a jointly-measured
   density correlator has CF = 0, identically, including the actual TMSV joint
   distribution itself, not merely the specific 2-outcome graph tried before (§3).
2. **Give the sharp mechanism**, not just the symptom: contextuality/Bell-type gaps
   require ≥ 2 *incompatible* contexts; a density-density correlator is measured in
   one shot with no experimenter-chosen incompatible alternative, so it is
   operationally single-context regardless of outcome alphabet (§3). This explains,
   rather than merely observes, why CHSH succeeds where CS cannot: Ciliberto et al.'s
   pseudospin construction manufactures a *new*, genuinely incompatible dichotomic
   observable, which is the only reason a context ever appears at all.
3. **Independently re-derive** CS violation from a two-mode-squeezed-vacuum (TMSV)
   state vector, closed-form and numerically cross-checked, rather than relying only
   on the cited de Nova–Sols–Zapata scattering-matrix formula (§4).
4. **Make concrete, with actual numbers**, the claim `NOTES-hawking-2.md` §2.3 named
   but did not build: CS violation is a 2×2 instance of the Shchukin–Vogel
   moment-matrix hierarchy, a *different species* of SDP than Lovász θ (feasibility
   vs. extremal; operator monomials vs. graph vertices) (§5).
5. **Foreclose a route `NOTES-hawking-2.md` did not consider**: even a hypothetical
   *continuous* Wigner-negativity witness (as opposed to the discrete qutrit
   Wootters-type one in `kcbs_wigner_flow.wl`, already ruled out on dimension
   grounds) cannot work here, because Gaussian states — which is what these
   Bogoliubov Hawking-pair states are — have provably non-negative Wigner functions
   (§6).
6. **Build the finite-sample certificate-stack design** the task's item 2 asks for,
   with explicit verdict labels, pre-registered thresholds, and a computed N*
   sample-size scoping table via the delta method — the exact piece
   `NOTES-hawking-2.md` §3.3 flagged as necessary and left undone (§9).

## 1. Literature check: has anyone already tried to bridge CS into a graph/exclusivity language?

Searched directly (not reconstructed from memory) for any existing bridge between
Glauber–Sudarshan-P/Cauchy-Schwarz-type nonclassicality witnesses and
Kochen-Specker/exclusivity-graph contextuality, in general (not Hawking-specific).
Found no such construction in the contextuality literature. What the search *did*
turn up, and what is genuinely useful:

**A very recent (Aug. 2024), structurally analogous, independent case study.** Ghosh,
Varshney, Debnath, "Equivalence of Cauchy-Schwarz and Bell's inequality violation by
photon-phonon pair generation in a multifield-driven optomechanical cavity,"
arXiv:2405.02896 (fetched and read: abstract, introduction, and the start of the
theoretical-framework section, directly). This is a different physical platform
(an optomechanical cavity producing entangled photon-phonon pairs by parametric
interaction) but the *same* mathematical structure as a Hawking/partner pair — a
bosonic parametric pair-production process, tested by both a CS inequality on
g^(2)-type correlators and a CHSH-type Bell inequality. Their own introduction states
the relationship precisely, and it is worth quoting because it independently
corroborates this note's own finding: "The implication of CS violation is two-fold,
firstly, it depicts the stronger quantum correlations between multimode bosonic
systems which is absent in the classical picture, and secondly, **it implies the
possibility of** nonlocal effects encountered in the Clauser-Horne-Shimony-Holt (CHSH)
framework" (emphasis added). That is *"CS violation is an indicator that CHSH
violation may be achievable,"* not *"CS violation is a CHSH-type inequality"* or *"CS
and CHSH share a representation."* Structurally, their paper treats CS (Sec. II.2,
via correlation functions) and CHSH (Sec. III.3, via a separately-constructed
dichotomic Bell operator, with its own analytical form spelled out in a dedicated
Appendix A) as two *separately computed* quantities on the same simulated state, not
one reduced to the other — exactly the "siblings, not identical" relationship
`NOTES-hawking-2.md` §2.1 already found between Steinhauer's Δ and de
Nova–Sols–Zapata's θ, now corroborated in an unrelated 2024 platform. Their
introduction independently cites "The CS violation is also considered a major
prediction of the spontaneous Hawking radiation in sonic black holes" — i.e. this
paper is aware of, and situates itself relative to, the exact literature thread this
project's own notes have been tracking. **Reading for this project:** even the most
recent, closest analogue found treats CS and CHSH/Bell as *correlated but distinct*
witnesses computed by *separate constructions* on the same state — nobody, in this
literature or the wider contextuality literature, has unified them into one
graph-invariant object. This is corroborating evidence, not a new proof; the actual
proof of *why* is §3 below, worked out independently of this citation.

**A confirmed, upgraded citation.** `NOTES-hawking-2.md` Ref. 18 cited Isoard,
Milazzo, Pavloff, Giraud's 2021 Gaussian-entanglement paper only via a Sept. 2025
conference-slide mention, flagged as "not independently fetched this session."
Fetched directly this session: Isoard, Milazzo, Pavloff, Giraud, "Bipartite and
tripartite entanglement in a Bose-Einstein acoustic black hole," Phys. Rev. A 104,
063302 (2021); arXiv:2102.06175 (abstract confirmed directly). Confirms the citation
notes-2 relied on secondhand is a real, correctly-attributed paper — a small but
genuine upgrade in provenance, not a new substantive finding.

## 2. A caveat addressed before it is asked: what about a τ-dependent or multi-basis version of the correlator?

Two natural objections to "single context," addressed directly rather than left as a
gap in the argument:

- **Could different time-delays τ in g^(2)(τ) count as different, mutually exclusive
  contexts** (measuring the correlation at τ₁ "instead of" τ₂), the way choosing
  setting a₀ vs. a₁ is mutually exclusive per shot in CHSH? No: for a stationary
  process, the *entire* time trace of the recorded density signal is available from
  one realization, and g^(2)(τ) at every τ is a different **statistic computed from
  the same recorded data**, not a different, incompatible measurement choice that
  forecloses recording other τ's. There is no per-shot "must pick one τ" the way a
  Bell test's experimenter must pick one setting.
- **Could a different measurement *basis* (e.g. homodyne/quadrature detection instead
  of direct photon counting) supply the missing second, incompatible context?** Yes —
  and this is exactly what Ciliberto et al.'s GKMR pseudospin construction does
  (`NOTES-hawking.md` §3): it replaces the native, always-compatible photon-number
  observable with a genuinely different, tunable, incompatible dichotomic observable.
  That is precisely why CHSH gets into this project's graph-invariant machinery and
  the native g^(2)/CS correlator does not: the multi-context structure a Bell/KS-type
  gap requires is not present in the *native* observable at all; it has to be
  manufactured by switching to a different measurement device. This sharpens, rather
  than contradicts, the diagnosis below.

## 3. The structural argument: single-context data cannot carry a Kochen-Specker/Bell-type gap, by construction

The Abramsky–Brandenburger/Cabello–Severini–Winter (CSW) framework this project's CF,
α, and ϑ all live in is fundamentally a statement about **≥ 2 incompatible contexts**:
a cover of the observable set by maximal jointly-measurable subsets, and the question
of whether one global assignment (hidden variable) can reproduce every context's
marginal simultaneously. With exactly one context, that question is vacuous — the
observed joint distribution over that single context trivially *is* its own
noncontextual model (interpret it directly as a hidden-variable distribution over
which single joint outcome occurs). A density-density correlator between the Hawking
and partner modes is measured jointly, in one shot, with no experimenter-chosen
incompatible alternative (n̂_H and n̂_P commute — they act on different tensor
factors — and are read out from the same realization). Operationally this is a
single-context empirical model, whatever finite alphabet the outcomes are binned into.

**Proved and LP-verified in `hawking_cs_route.py` §1** (using this project's own AB
incidence-matrix LP, `M·d ≤ e, d ≥ 0`, `NCF = max 1·d`, `CF = 1 − NCF`, the identical
formulation as `BlackBox.wl`'s `ContextualFraction`/`NoncontextualFraction` and
`mbqc_blackbox_test.py`'s `ncf_lp`): for a one-context scenario on K outcomes, the
incidence matrix is the K×K identity (each deterministic global assignment IS one of
the K outcomes), so `d = e` is simultaneously feasible and optimal, giving **NCF = 1,
CF = 0 exactly, for every valid probability vector e, for every K**. Checked at K = 2
(the exact null-graph case `NOTES-hawking-2.md` tried by hand), K = 4 (a 2×2 truncated
joint-occupation table), K = 9 (a random valid 3×3 truncated joint table), and K = 11
(**the actual TMSV joint distribution itself**, truncated) — all four give CF = 0 to
machine precision (max deviation 3.3×10⁻¹⁶). This is the needed generalization: it is
not that the *specific* graph tried in `NOTES-hawking-2.md` happened to be vacuous —
**no finite discretization of this measurement can ever be anything but vacuous**,
because the obstruction is about the number of contexts (one), not about which graph
structure is imposed on the outcomes. This closes off both possibilities the task
asked about at once: it is not a two-outcome exclusivity graph, and it is not a
KCBS-style odd cycle or any other combinatorial object either — no graph on any
number of vertices, built from this correlator alone, can carry a classical/quantum
gap.

**Epistemic grade: Class A** (exact LP computation on an exact incidence matrix,
plus an elementary, fully rigorous proof of the general K-outcome case).

## 4. Independent re-derivation: exact Cauchy-Schwarz violation for the idealized TMSV Hawking/partner pair

`NOTES-hawking.md` §5 already uses the idealized T = 0 EPR limit (S → 2√2, "the
analogue system literally realizes a qubit EPR pair") as the natural stand-in for
the maximally-idealized case of the CHSH bridge. This section applies the *same*
idealization — a two-mode squeezed vacuum (TMSV), |TMSV⟩ = √(1−λ²) Σₙ λⁿ|n,n⟩ — to
the native CS route, **independently of and without reference to** the de
Nova–Sols–Zapata scattering-matrix formula already cited in `NOTES-hawking.md` §2 and
`NOTES-hawking-2.md` §2.1.

Since n_H = n_P = n exactly on every term of the TMSV superposition, the de
Nova–Sols–Zapata correlators Γ_ij reduce to ordinary thermal-marginal factorial
moments (⟨n(n−1)⋯(n−k+1)⟩ = k! n̄ᵏ for a geometric/thermal photon-number
distribution — the standard chaotic-light factorial-moment identity):

```
Γ_HH = Γ_PP = ⟨n(n−1)⟩ = 2 n̄²
Γ_HP        = ⟨n_H n_P⟩ = ⟨n²⟩ = 2 n̄² + n̄
D_CS  ≡ Γ_HP² − Γ_HH Γ_PP = n̄²(4n̄ + 1)          (> 0 for every n̄ > 0)
θ(n̄) ≡ Γ_HP / √(Γ_HH Γ_PP) = 1 + 1/(2n̄)
```

`lim_{n̄→0+} θ = ∞`, `lim_{n̄→∞} θ = 1`. Cross-checked numerically (`hawking_cs_route.py`
§2) by direct Fock-space summation of the geometric Schmidt distribution to a 20,000
cutoff at five values of λ (0.05 to 0.8, i.e. n̄ from 0.0025 to 1.78): closed form and
numeric sum agree to floating-point precision (max absolute difference 8.9×10⁻¹⁶).

This is an independent confirmation, by a completely different route (state-vector
Fock-space algebra, not a scattering-matrix boundary-value calculation), of exactly the
qualitative shape `NOTES-hawking-2.md` §2.2 already reported from the de
Nova–Sols–Zapata formula: CS is violated for *every* nonzero pairing amplitude
(on/off, not graded), diverging as the pairing weakens and approaching the classical
boundary from above as it strengthens — the opposite of a graded scale like
`hawking_cf_bridge.py`'s own finding CF(S) = (S−2)/2 on S ∈ [2,4].

**Epistemic grade: Class A** (exact closed-form derivation on a stated idealized
state, numerically cross-checked) — with the caveat, stated as plainly as
`NOTES-hawking.md` states it for its own CHSH-EPR-limit numbers, that TMSV is an
idealization of the actual Bogoliubov ground/thermal state, not a re-derivation of
the physical scattering problem itself (that remains `NOTES-hawking.md` §6 item 3's
open item).

## 5. Cauchy-Schwarz as Shchukin–Vogel 2×2 moment-matrix positivity: a different SDP species than Lovász θ

de Nova–Sols–Zapata's own words (arXiv:1211.1761, already quoted in
`NOTES-hawking-2.md` §2.1): "the proof of (4) requires the system to be described by
a positive (Glauber–Sudarshan) P function." The 2×2 matrix
`M = [[Γ_HH, Γ_HP], [Γ_HP, Γ_PP]]` is literally the smallest nontrivial instance of
the Shchukin–Vogel moment-matrix hierarchy (Shchukin, Vogel, Phys. Rev. A 72, 043808
(2005); already named, not built, in `NOTES-hawking-2.md` §2.3): P ≥ 0 forces M ⪰ 0,
and the 2×2 PSD test (nonnegative diagonal, nonnegative determinant) is *exactly* the
CS inequality. Built and checked explicitly (`hawking_cs_route.py` §3) using the
TMSV numbers from §4 above:

| n̄ | TMSV moment-matrix eigenvalues | verdict | classical-boundary eigenvalues (Γ_HP = √(Γ_HHΓ_PP)) |
|---|---|---|---|
| 0.05 | [−0.0500, 0.0600] | **not PSD** (CS violated) | [0.0000, 0.0100] (PSD, boundary) |
| 0.20 | [−0.2000, 0.3600] | **not PSD** (CS violated) | [0.0000, 0.1600] (PSD, boundary) |
| 1.00 | [−1.0000, 5.0000] | **not PSD** (CS violated) | [0.0000, 4.0000] (PSD, boundary) |

This makes concrete, with real numbers, that CS-violation-as-positivity-failure is not
a metaphor: the TMSV moment matrix genuinely fails PSD-ness at every n̄, and a
constructed "classical boundary" model (same marginals, cross term capped exactly at
the CS bound — a legitimate, P-representable, classically-correlated Gaussian model)
sits exactly on the PSD/non-PSD boundary (one zero eigenvalue), as it must.

**But this does not hand CS a home in this project's Lovász-θ machinery.** Both are
"PSD matrix subject to linear constraints" in the abstract, but they are different
*species* of semidefinite program:

- **Lovász θ** (this repo's `BlackBox.wl`, checked directly: `LovaszTheta[g]` maximizes
  `Total[X,2]` over PSD X with `Tr[X]=1`, `X[i,j]=0` forced only on **edges of a
  finite graph g**) is an **extremal** SDP: maximize a linear functional, indexed by
  **graph vertices**, subject to orthogonality constraints from a finite combinatorial
  exclusivity structure.
- **Shchukin–Vogel/CS** is a **feasibility** SDP: does a PSD completion of the observed
  moments exist, indexed by **operator monomials** on an infinite-dimensional bosonic
  algebra (truncated in practice), with no combinatorial exclusivity graph anywhere in
  its definition.

Both are legitimately "SDP-flavored"; there is no known dictionary translating one
into the other for this system, and this note does not claim one. Building the *full*
Shchukin–Vogel hierarchy (beyond the minimal 2×2 case checked here) remains a real,
separate, unbuilt future stream, exactly as `NOTES-hawking-2.md` §2.3 already flagged.

**Epistemic grade: Class A for the 2×2 case** (exact, checked at three n̄ values plus
the classical-boundary contrast); **the general hierarchy remains an open/unbuilt
Class B construction** (a genuine SDP that could be built, not attempted here beyond
the minimal case).

## 6. A route not considered in `NOTES-hawking-2.md`: continuous Wigner-negativity is foreclosed too, by Hudson's theorem

`NOTES-hawking-2.md` §2.2 ruled out `kcbs_wigner_flow.wl` as a candidate home for the
CS route on **dimension/discreteness** grounds: that file computes a discrete,
finite-dimensional (3×3-cell) Wootters/Gross-type Wigner function for a single qutrit
(confirmed directly this session: `kcbs_wigner_flow.wl`'s `wigner[v_]` calls
`QuantumWignerTransform[QuantumState[v, 3]]`, an odd-prime-dimension discrete
construction), a different mathematical object from the continuous phase-space
Glauber–Sudarshan P-function the CS bound's positivity actually concerns.

This section forecloses a *different*, more general possible route that
`NOTES-hawking-2.md` did not need to rule out separately, because it goes further:
even a hypothetical *continuous*-variable Wigner-negativity witness — not the
discrete qutrit tool, but the genuine continuous Wigner function of the actual
bosonic Hawking-pair modes — cannot certify anything here, because these states are
Gaussian, and **Gaussian states have manifestly non-negative continuous Wigner
functions.** This is elementary: the Wigner function of a Gaussian state is, by the
definition of "Gaussian state," a Gaussian function of the phase-space variables
(∝ exp of a negative-semidefinite quadratic form), hence pointwise non-negative
wherever the covariance matrix is a bona fide physical one — which it is, for any
actual quantum state. This is the standard framing in the same continuous-variable
Gaussian-information formalism `NOTES-hawking.md` §4 already cites for a different
purpose (Weedbrook, Pirandola, García-Patrón, Cerf, Ralph, Shapiro, Lloyd, Rev. Mod.
Phys. 84, 621 (2012); arXiv:1110.3234) — reused here rather than introducing a new
citation, for internal consistency. The nontrivial *converse* (a non-negative Wigner
function on a *pure* state implies the state is Gaussian) is the actual content of
Hudson's theorem (R. Hudson, "When is the Wigner quasi-probability density
non-negative?", Rep. Math. Phys. 6, 249 (1974) — confirmed via corroborating
secondary/review sources this session, not fetched from the 1974 original directly,
flagged honestly as such), which is not the direction used here but is the standard
reference the field cites for this fact, so it is named for completeness.

Ciliberto et al. (2024) themselves describe the object under study as a "Gaussian
2/3-mode Bogoliubov state" (`NOTES-hawking.md` §3, already quoted) — so the *native*
Hawking-pair object is exactly the case Hudson's theorem and its elementary converse
apply to. One honest caveat: a non-Gaussian *conditioned* state (e.g. from
non-Gaussian post-selection on detector clicks) could in principle escape this, but
that is not the unconditioned object this literature studies. **Consequence**: since
this project's only existing Wigner-negativity tool (`kcbs_wigner_flow.wl`) is
foreclosed for two independent reasons now (discreteness mismatch, per
`NOTES-hawking-2.md`; and, even hypothetically generalized to the continuous case,
provable non-negativity for this exact state class, per this section) — whatever
"quantumness" a Hawking-pair CS/Bell violation certifies, it cannot be single-mode
Wigner nonclassicality. It must be **entanglement**: a well-known textbook fact is
that a positive-Wigner-function multimode Gaussian state can still be entangled (TMSV
itself is the canonical example — positive Wigner function, yet entangled), which is
exactly consistent with Ciliberto et al.'s own approach of targeting genuine
entanglement/Bell operators rather than any single-mode nonclassicality witness.

**Epistemic grade: Class A** for the elementary "Gaussian ⟹ non-negative Wigner"
direction actually used (definitional, unconditionally true for physical states);
**Class C** for the Hudson-theorem citation itself (confirmed via secondary sources,
not a direct fetch of the primary 1974 text, flagged as such per this project's
citation discipline).

## 7. Where the CS route actually lives (named in `NOTES-hawking-2.md` §2.3; this pass adds the concrete minimal case)

Restating, and crediting `NOTES-hawking-2.md` §2.3 for first identifying these, now
with §5 above making the smallest case concrete:

- **PPT criterion for CV systems** (Duan, Giedke, Cirac, Zoller, PRL 84, 2722 (2000);
  Simon, PRL 84, 2726 (2000)) — a positivity condition on symplectic eigenvalues of a
  covariance matrix.
- **Shchukin–Vogel moment-matrix hierarchy** (PRA 72, 043808 (2005)) — now confirmed
  concretely: its 2×2 minimal case IS the Cauchy-Schwarz inequality itself (§5).
- **Gaussian contangle / logarithmic negativity monotones** (Adesso, Illuminati, New
  J. Phys. 8, 15 (2006)) — the field's actual preferred *graded* measure, per the
  Sept. 2025 Isoard–Ciliberto–Milazzo–Pavloff–Giraud taxonomy already cited in
  `NOTES-hawking-2.md` §2.2 ("entanglement monotones (quantitative)" vs. CS/PPT
  "(qualitative: Yes/No)").

None of these three is built out in general here (only the 2×2 CS-specific case, §5).
This remains a legitimate, separate, future computational stream — standing up
continuous-variable covariance-matrix SDPs is a different kind of construction from
this project's existing incidence-matrix LPs, not a lightweight adaptation of them.

## 8. Direct answer to the task's question

**Is the CS bound structurally a two-outcome exclusivity graph, or does it need a
different combinatorial object entirely (odd-cycle or otherwise)?**

**Neither, in the sense the question anticipates as live.** It is not a two-outcome
exclusivity graph (§3: proved vacuous, and not merely for the one graph tried before —
for every finite discretization of this measurement). It also does not need a
*different combinatorial object* within the graph-invariant family — no KCBS-style
odd cycle, no other exclusivity structure on any number of outcomes, rescues it,
because the obstruction (§3) is about the number of *contexts* (exactly one), not
about which graph is drawn on the outcomes. What it needs is a different **kind** of
mathematical object entirely: a continuous-variable moment-positivity/feasibility-SDP
problem (Shchukin–Vogel/PPT, §5, §7), not a combinatorial exclusivity hypergraph at
all. This is a structural "no," reached independently in this pass via a general
theorem (§3) and a from-scratch derivation (§4–§6), not merely a repetition of
`NOTES-hawking-2.md`'s own (already solid) "no."

**Consequently, per the task's own instruction:** no native CS-route certificate in
this project's α/ϑ/CF language is claimed, because none exists to claim. The
finite-sample stack below (§9) is therefore built around the native CS/Δ-type
statistic directly (delta-method estimation of a moment gap), with the CHSH/CF bridge
(`hawking_cf_bridge.py`, already built in pass 1) kept as the explicitly-labeled
fallback the task anticipated, not the primary route.

## 9. Finite-sample certificate-stack design (task item 2)

A concrete specification, mirroring `mbqc_blackbox_test.py`'s structure
(pre-registered thresholds, verdict logic, sample-complexity N* estimate) as closely
as the underlying statistics allow, adapted to the CS/moment-gap statistic since §3–§8
establish that is the right native object (not CF). Built on, and making concrete,
the design sketch already in `NOTES-hawking-2.md` §3 — this section supplies the
missing numbers, verdict labels, and the delta-method derivation §3.3 of that note
flagged as necessary and left open.

### 9.1 What plays the role of "clicks per context" (adopting `NOTES-hawking-2.md` §3.1's conclusion)

No experimenter-chosen context exists (§3 above, independently confirming why
`NOTES-hawking-2.md` §3.1 found no Bell-test-style "settings choice" here). The
operationalization adopted: **N = independent condensate-preparation shots**;
per shot, the observable is the joint (n_H, n_P) occupation read from that shot
(or, for a real experiment, the density-fluctuation signal in the Hawking and
partner wavenumber bins, requiring its own pre-registered discretization rule — still
open, as `NOTES-hawking-2.md` §3.1 already flagged; adopted here as photon/phonon
occupation number for concreteness).

### 9.2 Certificate order and verdict logic (explicit thresholds)

Statistic: `D_CS ≡ Γ_HP² − Γ_HH·Γ_PP` (the absolute Cauchy-Schwarz gap; chosen over
the ratio θ because a difference has better-behaved delta-method variance than a
ratio with a denominator that can approach zero). Confidence budget α = 0.01 total
(matching `mbqc_blackbox_test.py`'s headline budget), split α_C0 = α_C1 = 0.005
(one-sided each, mirroring that file's Bonferroni-split style, adapted to two
certificate families instead of four since there are only two native checks here).

- **C0 (population/no-disturbance, the direct transplant of `mbqc_blackbox_test.py`'s
  C1 and `NOTES-hawking.md`/`NOTES-hawking-2.md`'s repeatedly-flagged missing check):**
  independently estimate n̄_H and n̄_P with confidence intervals at level 1 − α_C0;
  require the intervals to overlap. This directly implements the one check both
  Leonhardt and Steinhauer's rebuttal agree was never done (n̄_P was never
  independently published — `NOTES-hawking-2.md` §1.3 item 1).
- **C1 (Cauchy-Schwarz gap):** build a one-sided lower confidence bound
  `D_CS,lo = D̂_CS − z_{α_C1}·σ̂/√N` (delta-method/normal-approximation, not
  Hoeffding — see caveat below).
- **(C2, optional, fallback only):** if a genuine (2,2,2,2) pseudospin outcome table
  is ever reconstructed (Ciliberto-et-al.-style), report `CF_lo` via
  `hawking_cf_bridge.py`'s existing, unmodified machinery as a fully independent
  second opinion — never combined numerically with C0/C1, since §3–§8 establish they
  measure different things on different discretizations of the state.

**Verdict logic** (evaluated in this order, mirroring `mbqc_blackbox_test.py`'s V1–V5):

| step | condition | verdict |
|---|---|---|
| V1 | C0 intervals for n̄_H, n̄_P do not overlap | **EMULATION-SUSPECT** (population/no-disturbance failure — nothing downstream is meaningful; mirrors V1 of `mbqc_blackbox_test.py`) |
| V2 | else if `D_CS,lo > 0` | **QUANTUM-CERTIFIED** (Cauchy-Schwarz violation certified at the pre-registered confidence level) |
| V3 | else if `\|D̂_CS\|` below a pre-registered τ_classical AND the CI is consistent with the P-representable/classical-boundary model (§5) | **CLASSICAL** |
| V4 | else | **INCONCLUSIVE** |

**A structural observation about the adversarial case, honestly flagged as a
hypothesis, not built or tested:** `mbqc_blackbox_test.py`'s hardest case (iii-d) is a
classical intensity emulator *tuned* to reproduce the exact quantum table — a
semantics gap (intensity fractions vs. single-event clicks) invisible to any bare
probability table. The CS route has **no structural analogue of this loophole**,
because the CS bound is *derived directly from* P-function positivity, which is the
literal definition of "classical light" — nothing classical, by construction, can
exceed it. The residual worry for a real CS-based protocol is therefore not a
semantics gap but a **detector-artifact** one: e.g. electronic cross-talk between the
H- and P-channel detectors inflating the apparent Γ_HP. This is named here as the
right category of concern for future work, not shown to be a real vulnerability or
built into any check above.

### 9.3 Sample-size (N*) scoping, delta method (`hawking_cs_route.py` §5)

Derived in full in the script: modeling each shot's joint occupation as the TMSV/
thermal toy distribution of §4 (an explicit, named modeling choice standing in for
the real, unpublished per-shot statistics — `NOTES-hawking-2.md` §1.2 already
established no such data are public for any Steinhauer-program experiment), the
exact per-shot moments give (θ ≡ n̄ here for brevity):

```
Var(n)        = n̄(n̄+1)                              [thermal-marginal variance, standard]
Var(n(n−1))   = 20n̄⁴ + 24n̄³ + 4n̄²
Cov(n, n(n−1))= 4n̄³ + 4n̄²
D_CS (pop.)   = 4n̄³ + n̄²
Var(D̂_CS)·N   = 4n̄³(n̄+1)(40n̄² + 16n̄ + 1)            [delta method, exact under this toy model]
```

At the pre-registered budget (α_C1 = 0.005 one-sided, z = 2.5758), N* ≡ smallest N
with `D_CS − z·√(Var(D̂_CS)) > 0`:

| n̄ (illustrative) | D_CS (population) | N* |
|---|---|---|
| 0.01 | 1.04 × 10⁻⁴ | 2885 |
| 0.02 | 4.32 × 10⁻⁴ | 1550 |
| 0.05 | 3.00 × 10⁻³ | 735 |
| 0.10 | 1.40 × 10⁻² | 447 |
| 0.20 | 7.20 × 10⁻² | 285 |
| 0.50 | 7.50 × 10⁻¹ | 168 |
| 1.00 | 5.00 | 121 |

**Cross-check against the one real number available**: N = 4,600 independent runs
(Steinhauer 2016, as already established in `NOTES-hawking.md`/`NOTES-hawking-2.md`).
Inverting N*(n̄) = 4,600 under this same toy model: n̄* ≈ 0.00608 — i.e., under this
illustrative noise model, 4,600 shots would be enough to certify a population
Cauchy-Schwarz gap corresponding to a mean pair-occupation as small as ≈ 0.006 per
mode. This is `NOTES-hawking-2.md` §3.4's suggested reframing ("given the reported
4,600 runs... what per-bin N does that actually amount to") made concrete for the
first time, not a claim about what the real experiment's actual noise supports.

**Caveats (binding, not decorative):**
- n̄ is **not** a measured quantity from any published Steinhauer-program run; every
  number in the table above besides the formula structure and N = 4,600 itself is
  illustrative, generated from the stated toy model — exactly the honesty distinction
  `NOTES-hawking-2.md` §1 insists on.
- **Hoeffding's inequality (used throughout `mbqc_blackbox_test.py`) requires bounded
  outcomes**; photon number is not naturally bounded. This is a further, previously
  unstated methodological disanalogy from the click-based machinery: the
  delta-method/CLT normal approximation is used here instead, as
  `NOTES-hawking-2.md` §3.3 anticipated would be necessary. A fully rigorous version
  would replace it with a Bernstein/Bennett-type sub-exponential concentration bound
  (Boucheron, Lugosi, Massart, *Concentration Inequalities*, Oxford University Press,
  2013) or a bootstrap CI — named as the correct next step, not built here.

**Epistemic grade: Class C** ("symbolic replay with stated assumptions" — the formula
itself is exact *given* the stated toy per-shot model, which is explicitly a stand-in
for unpublished real data, not a measured quantity).

## 10. Open questions (additions to, not a repeat of, `NOTES-hawking.md` §6 and `NOTES-hawking-2.md` §6)

1. Build the *general* Shchukin–Vogel/PPT covariance-matrix SDP machinery (§5, §7) —
   still entirely open; only the CS-specific 2×2 minimal case was built here.
2. Replace the toy per-shot noise model of §9.3 with real run-by-run statistics, if
   and when such data become public (still blocked, per `NOTES-hawking-2.md` §1).
3. Replace the delta-method/normal-approximation CI of §9 with a genuine
   distribution-free Bernstein/Bennett-type bound, or a fully worked bootstrap
   propagation (named in §9.3, not built).
4. Test whether the "detector cross-talk" adversarial-case hypothesis (§9.2) can be
   made precise and built into an actual audit, analogous to `mbqc_blackbox_test.py`'s
   DLA/leaf-confinement hook for the KCBS case.
5. The Sp(2n,R)-orbit leaf-confinement analogue for Gaussian-state mode compilations
   (`NOTES-hawking.md` §6 item 4) remains open, untouched by this pass.
6. The Leonhardt/Steinhauer dispute (`NOTES-hawking-2.md` §1) remains unengageable
   directly — unchanged by this pass, which did not revisit that question.
7. This note's §6 Hudson's-theorem argument was checked against secondary sources,
   not the 1974 original — if a fully first-hand-verified citation chain matters for
   a future merge, the primary source should be tracked down and read directly.

## 11. Doc-merge notes (do not edit `QUANTUM_CONTEXTUALITY.md`/`README.md` from this branch)

- If merged, add to `QUANTUM_CONTEXTUALITY.md` §6/§9: the Cauchy-Schwarz route native
  to actual BEC analogue-Hawking experiments does not reduce to this project's
  α/ϑ/CF machinery, for a structural reason (single-context data cannot carry a
  Kochen-Specker/Bell-type gap, proved and LP-verified for every finite
  discretization, not just one attempted graph); it lives instead in a
  continuous-variable moment-positivity/SDP hierarchy (Shchukin–Vogel/PPT), whose
  minimal 2×2 case IS the CS inequality (built and checked here) but whose general
  form remains unbuilt; a concrete finite-sample certificate-stack design (C0/C1,
  explicit verdict labels, a delta-method N* formula) exists for a future real
  dataset, none of it executable against real data yet (none exists publicly).
- This note's own open items are §10 above, in addition to the prior two notes' lists.

## 12. References beyond `NOTES-hawking-2.md` §5

26. J. Ghosh, S. K. Varshney, K. Debnath, "Equivalence of Cauchy-Schwarz and Bell's
    inequality violation by photon-phonon pair generation in a multifield-driven
    optomechanical cavity," arXiv:2405.02896 (2024) (fetched and read directly this
    session: abstract, introduction, start of theoretical framework).
27. R. Hudson, "When is the Wigner quasi-probability density non-negative?", Rep.
    Math. Phys. 6, 249 (1974) (statement confirmed via corroborating secondary/review
    sources this session; the 1974 original was not fetched directly — flagged per
    this project's citation discipline).
28. S. Boucheron, G. Lugosi, P. Massart, *Concentration Inequalities: A
    Nonasymptotic Theory of Independence*, Oxford University Press (2013) (standard
    reference for Bernstein/Bennett-type bounds on unbounded, bounded-variance
    random variables — named as the correct tool for a fully rigorous version of
    §9's C0/C1 gates, not used to derive a bound here).
29. M. Isoard, N. Milazzo, N. Pavloff, O. Giraud, Phys. Rev. A 104, 063302 (2021);
    arXiv:2102.06175 ("Bipartite and tripartite entanglement in a Bose-Einstein
    acoustic black hole" — independently fetched and confirmed this session,
    upgrading `NOTES-hawking-2.md` Ref. 18's secondhand citation via conference
    slides).
30. This repo: `hawking_cs_route.py` (this session's artifact); `BlackBox/Kernel/
    BlackBox.wl` (master; `LovaszTheta`, `IndependenceNumber`,
    `FractionalPackingNumber`, `NoncontextualFraction`/`ContextualFraction` — read
    directly this session to confirm this project's exact SDP/LP conventions before
    claiming anything about them); `kcbs_wigner_flow.wl` (master; confirmed directly
    this session to use `QuantumWignerTransform` on a 3-dimensional `QuantumState`,
    i.e. the discrete Wootters/Gross construction `NOTES-hawking-2.md` §2.2 already
    described).
