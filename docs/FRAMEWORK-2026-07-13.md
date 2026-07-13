# The Black-Box Framework — completed under named hypotheses

Date: 2026-07-13. Status document. This is the framework of *Evaluating black-box
physics through optical emulation*, stated **completely**: the established layer
(theorems and machine-verified results), then the **named hypotheses** — the best
possible assumptions, each explicitly an open problem awaiting mathematical proof —
and the conditional theory that follows from them. Style: as number theory is
routinely developed conditional on the Riemann Hypothesis, this framework is
developed conditional on H1–H5, with every hypothesis's evidence, confidence,
and precise proof target stated. Claim provenance: project claims ledger
(`01-claims-ledger/ledger.json`, keys cited inline).

Legend: **[T]** theorem / machine-verified · **[C]** certified numeric ·
**[R]** refuted route (established negative) · **[H]** named hypothesis (open).

---

## Layer 0 — The established foundation (unconditional)

**F1. Atomic invariants [T].** KCBS pentagon: α=2, ϑ=√5, α\*=5/2; the ϑ>α gap is
the contextuality resource. (FOUND-001; CSW dictionary.)

**F2. Two-lens necessity [T].** A tuned intensity emulator is table-level
indistinguishable from the quantum device (Proposition 1, assumptions A1–A4;
BBT-002), and **no function of the table can lower-bound the device's DLA**
(Proposition 2; BBT-003). Hence certification is irreducibly two-lens:
correlation lens + geometric/dynamics lens, neither derivable from the other
(LP-002 decorrelation).

**F3. The access staircase [T]/[C].** Interventional access defeats the θ-blind
emulator (OQ1-A: orbit rank 0 vs 2) but not a θ-aware one (OQ1-B: fit <1e-9);
attenuation/event-semantics defeats even the θ-aware forger (OQ2/G8, 25/25;
Corollary 1 collapses the class to α=2; anchored to the single-detector
coherent-forgeability theorem, arXiv:2601.13869). See
`00-BBT-blackbox-protocol/certification_map.nb`.

**F4. Exact mesh-composition laws [T].** Two non-isomorphic gluing families
(cis/trans; MESH-001); orientation, not size, controls gap survival (MESH-002);
τ\* = Root[49x³−128x²−75x+218,2] = 1.37671774591586 exactly; cis laws
θ = N+θ(C_N), α = ⌊3N/2⌋; the α-cis theorem ᾱ(w) ≥ max(4/3, 1+f_c/2) with
equality at 4/3 **iff** w=(cct)^k. cct achieves gap density 0.0698975 (61%
over trans; MESH-003) [C: 320-digit certified, no low-degree closed form].

**F5. The certificate hierarchy [T]/[C].** Windowed transfer-SDP certificates:
gap(w) ≤ Γ_k for **all** gluing words; exact rational Γ₇=0.0770206,
Γ₈=0.0752664, Γ₉=0.0720260 (regenerated tighter than the originals);
Γ₁₀=0.0714575 [C numeric]. The certificate condition is a Bousch sub-action
(tropical 0-cochain on de Bruijn-k; Γ_k = max-plus eigenvalue, Karp-verified).
Spurious policy-iteration values are periodic-orbit densities −1 (cis 3/2,
trans τ\*, 16/11, 19/13, 25/17): the orbit-spectrum/crowding reading
(`05-CERT-epsilon-certificates/CONVERGENCE-ANALYSIS-2026-07-13.md`).

**F6. Degree-0 sheaf derivation of GE [T].** The weighted GE presheaf capacity
Λ_k computes the composed bound: S_k = Λ_k^{1/k}; exact on C₅ (5/2 → √5) and
the C₇ negative control (7/2 at k=2,3). Mechanism identified: the optimal dual
0-cochain is an **integer** partition of unity exactly when the quantum value is
achieved (C₅ pentads), **properly fractional** otherwise (C₇: 4∤49, 8∤343).
(`06-D3-sheaf-cohomology/ESSAY-005-ERGODIC-BRIDGE-2026-07-13.md`.)

**F7. The ERG-003 reduction [T].** ω(C₉∨C₉∨C₉∨C₅) ∈ {16..19}; activation ⟺
ω ≥ 18. The 5-layer pentagram decomposition is exactly equivalent to cliques of
G (both directions, 68k tests); ω(H)=8 proven analytically; the 26-family S=17
census is complete; families (1,1,1,7,7) and (1,1,2,7,6) proven NO. A finished
family sweep is a valid proof.

**F8. Constructive realizations [T].** The cct mesh realized as a cluster state
and verified at 9M qubits; MBQC execution of Bernstein–Vazirani (10⁵ bits),
Grover, contextuality-powered universal classical gates; Hawking information
dynamics (Page curve, Hayden–Preskill, CHSH/CF certification) built agnostically
and confirmed against four published papers. All Clifford; honest scope in headers.

**F9. Established negatives [R] (part of the theory).** (i) The affine α-credit
tilt is inert — no affine-in-f_c certificate family can have limit gap(cct);
(ii) the static↔dynamic ergodic-sheaf unification is a category error (cross-side
T→0 limit yields packing 5/2, not Γ, and does not select cct); (iii) the
possibilistic (support) presheaf is blind to S_k; (iv) the cellular-sheaf
Laplacian fails as a contextuality measure (SH-004); (v) Choudhary–Barbosa's
Ramsey technique cannot certify ω≤17 for the mixed nonagon cell; (vi) the
sheaf-Laplacian, GLV-hierarchy, and monolithic-SAT routes are closed as
priced/impossible. Negative results are first-class: they fix the boundary of
the method space.

---

## Layer 1 — The named hypotheses (best possible assumptions; open problems)

### H1 — cct Optimality Hypothesis
**Statement.** sup over all infinite gluing words w of gap(w) = gap(cct)
= 0.0698975…, attained (uniquely up to rotation) by (cct)^∞.
**Evidence.** Exhaustive over all periods ≤18 (~29,000 necklaces, unique max);
all balanced/Sturmian words fall ≥0.012 below; certified globally within
ε = Γ₁₀ − gap(cct) = 0.00156; **exactly proven** on the region ᾱ ≥ 1.4301025;
the α-penalty mechanism (F4) punishes every deviation from cct.
**Confidence.** Very high. Any counterexample must be an aperiodic, unbalanced
word with f_c ≈ 2/3 and ᾱ ∈ [4/3, 1.4301) — a thin corridor with no known
inhabitant.
**Proof target.** Either (a) close the corridor: a certificate family whose
limit is gap(cct) — the Legendre/Pareto-frontier certificate (θ̄ bounded as a
function of f_c against the *kinked* floor max(4/3,1+f_c/2); not covered by the
affine-inertness refutation) is the live candidate; or (b) an
ergodic-optimization selection theorem for this potential class. Known hard:
the finiteness property fails in general (Bousch–Mairesse), so (b) cannot be
generic — it must use the α-cis structure.
**Related open sub-hypothesis H1′ (Γ-limit).** lim Γ_k = sup_w gap(w). The
hierarchy is decreasing and bounded below by the sup; equality of the limit
with the sup is itself unproven. H1 ∧ H1′ ⟺ lim Γ_k = gap(cct).

### H2 — Cohomological Detection Hypothesis (ESSAY-005 at H¹)
**Statement.** On the weighted GE presheaf cover, the connecting class
δ(c mod ℤ) ∈ H¹(cover; ℤ) of an optimal dual 0-cochain c is well-defined
(gauge-invariant across the optimal face) and vanishes **iff** the GE sequence
attains the graph's quantum value — i.e., sheaf cohomology *derives* (not just
describes) the quantum-classical boundary.
**Evidence.** The degree-0 mechanism (F6) is exactly an integer-vs-fractional
partition phenomenon — the classical shape of a lifting obstruction along
0 → ℤ → ℚ → ℚ/ℤ → 0; the C₅/C₇ divisibility pattern matches the prediction.
**Confidence.** Moderate. The construction exists; gauge invariance (class
independence of the chosen optimal dual) is the untested make-or-break.
**Proof target.** (i) Gauge invariance over the optimal face; (ii) correct
zero/nonzero values on C₅(k=1,2), C₇(k=2,3) and an out-of-sample control (C₉);
(iii) functoriality under graph maps. If (i) fails, H2 is refuted as posed and
the detector must be sought in a finer invariant (semimodule cohomology).

### H3 — No-Activation Hypothesis (ERG-003)
**Statement.** ω(C₉∨C₉∨C₉∨C₅) = 16: the (3,1) nonagon cell does **not**
activate; pentagon catalysis remains n=7-unique through three boxes.
**Evidence.** Five independent methods plateau at 16; zero 17-cliques in >10⁸
exact search nodes; every found 16-clique has product structure; 2/26 families
proven NO; the Ramsey shortcut provably cannot decide it (F9v) — consistent
with a true-but-hard NO.
**Confidence.** High (beyond reasonable doubt, unproven).
**Proof target.** All 26 families NO — by search (elim2, per-family) and/or by
proven per-family relaxation bounds. Purely finite; bounded by compute, not by
mathematical obstruction. Under H3's negation (any 17-clique at S=18 census):
a *second activation family* — a discovery, immediately checkable.

### H4 — Two-Lens Completeness Hypothesis (SQ1; the O3 capstone)
**Statement.** Against the physical adversary class 𝒜 = {classical optical
devices: intensity redistribution + single unmodified on-off detection}, the
gate set {C1–C5 (statistics), G7 (DLA audit), G8 (attenuation)} is **complete**:
every device in 𝒜 either is distinguished by some gate or genuinely obeys the
NCHV bound. Equivalently: the indistinguishability set of the certification map
is exactly the cells marked in `certification_map.nb`, and no third lens is
needed for 𝒜.
**Evidence.** Necessity is proven (F2); every probed escape is closed at some
access rung (F3); the class ceiling is anchored to the published
coherent-forgeability theorem.
**Confidence.** High *relative to 𝒜*; the unrestricted version (all classical
adversaries, all side-channels, CV sources) is genuinely deep and touches
sampling-hardness (Aaronson–Arkhipov) — not expected to close soon.
**Proof target.** (a) Class-relative: formalize 𝒜 and derive completeness from
the detector theorem + Corollary 1 — plausibly provable now. (b) Extend the map
by the **CV/Gaussian column**: the Sp(2n,ℝ) leaf-confinement criterion (passive
u(n), dim n², vs active sp(2n,ℝ), dim n(2n+1)) — derivable and implementable as
the CV analogue of G7 (the audit NOTES-hawking flags as never done).

### H5 — Paley Product Hypothesis (GE-003 residue)
**Statement.** ω(Paley13^∨3) = 39 (= 13·3, the product witness is optimal).
**Evidence.** Doubly-verified 39-clique; no 40-clique in ~1.7×10⁸ exact nodes +
5,496 heuristic restarts; ceiling 46 from ϑ-multiplicativity.
**Confidence.** High.
**Proof target.** A Delsarte-LP / Schrijver-ϑ′ bound on the ℤ₁₃³ translation
scheme (explicit Paley eigenvalues) **< 40** would close it outright with an LP
certificate; otherwise exhaustion of the ~1,000 residual branches (measured
distribution now known). This is the cheapest of the five to close.

---

## Layer 2 — The conditional theory (what the framework says if H1–H5 hold)

**Under H1 (+H1′):** the composition theory is *final*: cct is THE optimal
gluing rule; the design principle "orientation over size, cct over all" is
exact; the Γ_k hierarchy is an asymptotically tight certificate scheme; the
θ-density theory of glued cycle families (apparently unstudied territory) has a
complete solution over {c,t}.

**Under H2:** ESSAY-005 is answered affirmatively at H¹: quantum advantage in
GE composition *is* the vanishing of an integral lifting obstruction — a
cohomological criterion computable from cover data alone. The describe/derive
separation (F9iii) is then precisely located: derivation lives in the weighted
(probabilistic) sheaf at degree ≤1, while possibilistic invariants remain blind.
This would be the project's deepest structural result.

**Under H3:** the catalysis landscape is closed for k ≤ 3: activation is a
*sharp resonance* at n=7 — the pentagon catalyst's power does not extend to
n=9 even with three boxes. Practically: single-copy E-principle certification
carries no known activation blind spot beyond the heptagon family, and the
constant-dimension-catalyst phenomenon is special, not generic.

**Under H4 (class-relative):** O3 is *answered* for physical optical emulators:
indistinguishability is exactly table-access vs the tuned forger; the protocol
{C1–C5, G7, G8} is sufficient as well as necessary; with the CV column built,
the certification map covers discrete and Gaussian device classes alike. The
unrestricted completeness question remains the framework's stated deep frontier.

**Under H5:** GE-003's last bracket closes; the k=3 activation census over the
six vertex-transitive test graphs is complete, and the product-structure
heuristic (ω multiplicative on these OR-powers) gains its strongest data point —
itself a candidate lemma for the Shannon-capacity-adjacent family.

**Jointly:** the framework is then complete in the sense the project defined:
one exact correlation theory (F1, F6+H2), one exact composition theory (F4,
F5+H1), one decided activation frontier (F7+H3, H5), and one certified
answer to the central question (F2, F3+H4) — with every remaining gap located
*outside* the framework (sampling hardness, CV field theory, aperiodic ergodic
selection) rather than inside it.

---

## Layer 3 — The proof ledger (what official mathematics still owes the framework)

| # | Open problem | Type | Nearest known obstruction | Cheapest credible path |
|---|---|---|---|---|
| H1 | sup gap = gap(cct) | ergodic optimization | finiteness property fails generically (Bousch–Mairesse); affine tilts inert | Legendre-frontier certificate tight at f_c=2/3 |
| H1′ | lim Γ_k = sup gap | hierarchy convergence | none known — likely provable | SFT window-approximation argument |
| H2 | δ(c mod ℤ) is THE detector | sheaf cohomology | gauge invariance untested | compute class over optimal face; C₉ control |
| H3 | ω(nonagon cell)=16 | finite search | per-family cost wall (fam02+) | bound-elimination + residual sweep |
| H4a | completeness rel. 𝒜 | protocol theory | detector-model assumptions | derive from arXiv:2601.13869 + Cor 1 |
| H4b | CV column (Sp(2n,ℝ) audit) | Lie theory | none — never attempted | matrix Lie-closure implementation |
| H4c | unrestricted completeness | complexity theory | sampling hardness (BosonSampling) | out of scope; stated as frontier |
| H5 | ω(P13^∨3)=39 | association schemes | plain ϑ gives only 46 | Delsarte LP on ℤ₁₃³ scheme |

**Reading discipline.** Results in Layer 0 may be cited unconditionally. Any
statement from Layer 2 must carry its hypothesis tag ("under H1", …). The
framework is *complete under H1–H5*; each hypothesis is precisely the kind of
sharply-posed open problem the project set out to distill, and each has a
stated, finite proof target.

---

## Delta 2026-07-13 (final-push workflow; both reviews sound, 0 fatals)

The five-lane push moved the following items. Full evidence:
`docs/COMPLETE-THEORY-2026-07-13.md` and the committed `final_*` lane files.

**H4a → PROVEN as a conditional theorem (moves to Layer 0 as F10).**
**F10 [T, conditional].** Prop O3-C: within the intensity-emulator adversary
class 𝒜_IE (classical light + intensity redistribution up to α\*=5/2 + one
unmodified on-off detector, fair-sampled, fresh-per-trial), the gate set
{C1–C5, G7, G7-CV, G8} is **complete** — every device is distinguished or
certified NCHV-bounded. Load-bearing premises (stated, not hidden): the KBS
single-detector coherent-forgeability theorem + white-box trust on G7/G7-CV.
The residual open problem is **H4′ (𝒜_IE-maximality)**: is 𝒜_IE the right
adversary ceiling (PNR/heralded/non-fair-sampling devices are outside it)?

**H4b → BUILT (moves to Layer 0 as F11).**
**F11 [T/C].** G7-CV, the Sp(2n,ℝ) leaf-confinement audit, implemented and
exact-validated (u(2) dim 4 = passive-confined; +two-mode squeezer → sp(4,ℝ)
dim 10 = active). The certification map's CV/Gaussian column is **filled**
(`00-BBT-blackbox-protocol/final_o3_cv_dla.py`; map regenerated).

**H2 → REFUTED AS POSED (moves to Layer 0 negatives as F9vii).**
**F9vii [R].** δ(y\* mod ℤ) is not an H¹ detector: (1) undefined exactly in
the fractional/stuck case (the canonical C₇,k=2 dual has 20,776 bad overlaps —
not a 0-cocycle); (2) not gauge-invariant (the optimal face is
positive-dimensional; an independent optimum gives a different count); (3)
forced to zero wherever defined (connected nerve). The degree-0 result (F6)
stands untouched. The H¹ question remains open but this cover/coefficient
choice is closed; a detector must be sought in finer structures.

**H1: the Legendre-frontier route → provably dead (added as F9viii).**
**F9viii [R, theorem].** Any certified Legendre frequency-frontier equals the
*concave hull* of θ̄ over f_c, which is pinned flat at 3/2 on [1/2, 1] (ct and
ccct achieve exact θ̄ = 3/2); cct sits 0.0968 strictly below the hull,
unexposed by any supporting hyperplane — the route certifies ≥ 1/6 at f_c=2/3,
*worse* than flat Γ₉. Enumeration-independent. Consequence: both affine (F9i)
and Legendre families are now closed; H1 needs a **nonlinear-in-frequency**
certificate or a selection theorem. H1 status: open, window [0.0699, 0.0720].

**H5: the Delsarte-LP route → provably dead (added as F9ix).**
**F9ix [R, theorem].** Schrijver ϑ′ / Delsarte LP on the ℤ₁₃^k translation
scheme equals exactly 13^{k/2} — identical to the Lovász ceiling (verified
k=1,2,3; ϑ′(k=3)=46.87). The LP route can neither close (<40) nor tighten
(<46) the bracket. H5 status: open, [39, 46]; next tools are level-2 Lasserre,
non-abelian symmetrization, or search.

**H3: bound-elimination → inert (added as F9x).** 0 of 26 families are
bound-eliminable (inertness lemma: ω(cn(Q_m)) ≥ 8−s_m meets the generator
constraint). H3 status: open; S=17 is search-bound (2/26 NO, 24 PARTIAL,
~69M nodes, no witness).

**Net position after the delta.** Proven layer grows by F10, F11 (+F9vii–x);
the hypothesis set is now {H1, H1′, H3, H5, H4′(maximality), and the reopened
H2′ (a genuine quantitative-cohomology detector beyond this cover)}. Four of
five lanes returned rigorous negatives, none inflated — each surviving open
problem now carries a *sharper* cheapest-path in the Layer-3 ledger (H1:
nonlinear certificate; H3: elim2 scale-up; H5: Lasserre-2/search; H4′:
adversary-class analysis).
