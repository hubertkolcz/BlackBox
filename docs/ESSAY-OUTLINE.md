# ESSAY-OUTLINE.md — the master WSRI computational essay

Date: 2026-07-13. Architect's design for the repository's single master computational
essay, *Evaluating black-box physics through optical emulation*. This document is the
build contract: it fixes the title, the abstract (answering the project description
verbatim), the section spine, the per-claim live-computation manifest, and the figure
manifest. It does **not** restate values — it names, for every quantitative claim, the
module or paclet call that must produce that value **at essay-evaluation time** (THE
PRIME DIRECTIVE). Implementation follows the precedent of
`pentagon-foundations/CertifyingQuantumness.wl` (a `.wl` computational-essay source,
Get-safe, headless-verifiable via a runner that prints a final association `OK -> True`).

---

## 0. Deliverable form and build discipline

- **Source:** `EvaluatingBlackBoxPhysics.wl` (repo root), a Wolfram computational-essay
  package with `(* ::Title:: *)`, `(* ::Abstract:: *)`, `(* ::Section:: *)`,
  `(* ::CodeText:: *)`, `(* ::Input:: *)` cells — same cell grammar as
  `CertifyingQuantumness.wl`.
- **Runner:** `runners/RunMasterEssay.wl`, using the `Get[]`-inside-runner pattern
  (avoids `-file` `Global`` parse-shadowing of paclet symbols). Prints a final
  `MasterEssayVerification` association ending `"OK" -> True`.
- **Notebook:** `EvaluatingBlackBoxPhysics.nb` generated from the source.
- **Live-computation law:** every printed number comes from a `Needs`/`Get` of a
  verified module or a recomputation with the `HubertKolcz`BlackBox`` paclet
  (interface: `IndependenceNumber, LovaszTheta, FractionalPackingNumber, KCBSDirections,
  GlueGraphs, PentagonChain, PentagonRing, CEFilter, CEFilterMixed, CycleScenario,
  CycleModel, NoncontextualFraction, ContextualFraction, GlobalSectionQ, SignedNegativity,
  PossibilisticSupport, CycleCoboundary, HarmonicResidual, CoverScenario, CechCohomology,
  CechRelativeCohomology, AvNArgument, CechObstruction, CascadeGenerators, So3Axis,
  DLADimension, CycleORProduct, QuantumEventProbability`). Heavy Python results
  (LP/SDP/search verdicts) are pulled from committed JSON/`.wl` result files via a small
  reader, never re-typed.
- **Labeling discipline (mirrors `docs/FRAMEWORK-2026-07-13.md`):** every statement is
  tagged **[T]** theorem/machine-verified, **[C]** certified numeric, **[R]** refuted
  route (established negative), or **[H]** named hypothesis (open). Layer-2 statements
  carry their hypothesis tag inline ("under H1", ...). Novelty is scoped exactly as the
  audits scoped it (see Honesty ledger, section 11).

---

## 1. Title and abstract

**Title.** *Evaluating black-box physics through optical emulation: a two-lens
certification theory, complete under five named hypotheses.*

**Subtitle.** *Correlation invariants and Lie-algebraic resource criteria for deciding
when a quantum device is indistinguishable from a classical optical emulator — with the
KCBS pentagon as atom, pentagon-mesh composition as algebra, and analogue Hawking
radiation as application.*

**Abstract (answers the RESEARCH.md verbatim description).** The description asks: *given
only black-box access, under what conditions is it mathematically impossible to
distinguish a genuinely quantum device from a classical optical emulation at the level of
input-output behavior?* The essay answers by structuring certification as two provably
irreducible lenses — a **correlation lens** (graph invariants of measurement statistics)
and a **geometric lens** (the dynamical Lie algebra pricing resource scaling) — and
proving neither is derivable from the other. On the KCBS pentagon it computes the atomic
hierarchy classical 2 < quantum sqrt5 < exclusivity-only 5/2; states the exact
indistinguishability blind spot as a proposition; and closes it, class-relatively, with a
completeness theorem over the intensity-emulator adversary class. It then develops an
exact composition algebra (pentagon-mesh gluing), a degree-0 sheaf derivation of the
composed exclusivity bound, and illustrates the framework on the classical emulatability
of Hawking-radiation dynamics — Gaussian sector emulable, qubit-information sector
reproducible, both certified. It assesses the taxonomy's extension to signaling. Finally
it states the framework **completely**: the established layer unconditionally, then the
five named open hypotheses (H1, H1', H2', H3, H4', H5) with proof targets, developed as
number theory is developed under the Riemann Hypothesis. Every quantitative claim is
produced live by a kernel-verified module in this repository.

*numberManifest for the abstract:* `2, sqrt5, 5/2` via
`{IndependenceNumber, LovaszTheta, FractionalPackingNumber}[CycleGraph[5]]`; `2 sqrt5 - 4`
via `ContextualFraction[CycleScenario[5], CycleModel[5,"Quantum"], WorkingPrecision->Infinity]`.

---

## 2. Section spine (12 sections + 2 appendices)

Ten-part spine as commissioned, plus a Summary-of-Results header (precedent) and a
References close.

### S0 — Summary of results (bulleted `(* ::Item:: *)`, precedent-style)
Six-to-eight one-line bullets, each naming its live source. Mirrors
`CertifyingQuantumness.wl`'s "Summary of Results" block.

### S1 — The question and the pentagon atom (F1)
- The central question quoted verbatim; the two-lens thesis stated.
- **Live:** the pentagon `CycleGraph[5]`; the three invariants
  `{IndependenceNumber, LovaszTheta, FractionalPackingNumber}` = `{2, sqrt5, 5/2}`;
  `GraphData[{"Cycle",5}, ...]` curated oracle cross-check; `KCBSDirections[]` with the
  cyclic-orthogonality + axis-sum-to-sqrt5 identity (`Simplify`, exact).
- alpha=2, theta=sqrt5, alphaStar=5/2; the theta>alpha gap named as the resource. **[T]**

### S2 — The certification protocol and its located blind spot (BBT-001/002, Prop 1)
- The pre-registered protocol summarized (7 gates, thresholds, seed) — read from the
  protocol module, not re-typed.
- **Prop 1 (blind spot, BBT-002):** a tuned intensity emulator (t = 1/sqrt5, delta = 0)
  is table-level indistinguishable by construction; assumptions A1-A4 stated. **[T]**
- **Live:** the emulator construction reproduces the quantum table (CF-hat ~ 0.4803, all
  certificates clean → QUANTUM-CERTIFIED false positive by design), pulled from
  `certification-protocol/` results; a `CEFilter`/`ContextualFraction` recomputation
  shows the emulator table and the quantum table coincide.
- Cite the adversary as published: Frustaglia et al. PRL 116 250404 (classical fields
  reach sqrt5); Kovtoniuk-Bohmann-Semenov arXiv:2601.13869 (single-detector
  coherent-forgeability). **[T]/cited**

### S3 — Two lenses, necessarily and completely (Prop 2/BBT-003, OQ1/OQ2, Prop O3-C, G7+G7-CV)
- **Prop 2 (BBT-003):** no function of the empirical table lower-bounds the device's DLA
  (two tables identical, DLA 3 vs <3) → the geometric lens is not derivable from the
  correlation lens; two-lens necessity. **[T]**
- **Live geometric lens (G7):** `CascadeGenerators[]`, `So3Axis`, `DLADimension` →
  generator span rank **0-vs-2** distinction and DLA **dim 3** at commutator depth one.
- **Access staircase (F3):** OQ1 theta-blind rig orbit **rank 0 vs quantum rank 2**
  (`oq1_interventional_dla.py` result); OQ2 attenuation gate **G8 matrix, 25/25** emulator
  failures (`oq2_attenuation_gate.py` result); Corollary 1 collapse to alpha=2.
- **G7-CV / F11:** Sp(2n,R) leaf-confinement — Lie dims passive **u(n) dim n^2**
  (u(2)=4) vs active **sp(2n,R) dim n(2n+1)** (sp(4,R)=10, sp(2,R)=3), exact-arithmetic
  Lie closure (`certification-protocol/final_o3_cv_dla.py` result). **[C]**
- **Prop O3-C / BBT-004 / F10 [T, conditional]:** over the intensity-emulator class
  A_IE the gate set {C1-C5, G7, G7-CV, G8} is complete; load-bearing premise (KBS
  detector model) and white-box trust stated openly.
- **Embed `certification_map.png`** (regenerated live by `certification_map.wl`).

### S4 — Composition: the mesh laws and the optimal word (F4, F5, CERT-003)
- **direct/twisted dichotomy (MESH-001/002):** two non-isomorphic gluing families; orientation
  not size controls gap survival. direct law theta = N + theta(C_N), alpha = floor(3N/2).
  **Live:** `PentagonRing`/`GlueGraphs` + `LovaszTheta`/`IndependenceNumber` reproduce the
  law for small N; even-N pinch vs odd-N residual gap.
- **tau\* [C]:** `Root[49 x^3 - 128 x^2 - 75 x + 218, 2]` = 1.37671774591586, recomputed
  live via `Root`/`N`; twisted density.
- **alpha-direct theorem (F4):** alpha-bar(w) >= max(4/3, 1 + f_d/2), equality at 4/3 iff
  w = (ddt)^k; gap(ddt) = 0.0698975 (irrational, no low-degree closed form); 61% over
  twisted. **[T]/[C]**
- **Gamma_k certificate ladder (F5):** exact rationals Gamma_7 = 0.07702057,
  Gamma_8 = 0.07526640, Gamma_9 = 0.0720260 read from `EpsilonCertificate{7,8,9}*.wl`;
  Gamma_10 = 0.0714575 numeric; the monotone bracket → gap(ddt); certified
  eps = Gamma_10 - gap(ddt) = 0.00156. Bousch sub-action / max-plus eigenvalue framing.
- **Orbit-spectrum reading (CERT-003):** seed values = orbit density - 1 — direct 3/2, twisted
  tau\*, 16/11, 19/13, 25/17 — matched to ~4e-6 (finite-k truncation). **Embed
  `orbit_spectrum.png`** (from `orbit_spectrum_figure.wl`).

### S5 — The sheaf question: derivation at degree 0, the H1 obstruction (SH-009/010)
- The project's **priority question** (ESSAY-005) stated: can the Abramsky-Brandenburger
  sheaf *derive* (not just describe) the GE composed bound over products of C5?
- **Degree-0 answer (F6/SH-009) [T]:** S_k = Lambda_k^(1/k); **live** on C5 and the C7
  control — S1(C5)=5/2, S2(C5)=sqrt5 (`RootReduce`), C7 stays 7/2 at k=2,3; the mechanism
  is integer-partition-of-unity (pentads, y=1) vs properly fractional (y=1/4 on 49,
  since 4 does not divide 49; y=1/8 on 343, since 8 does not divide 343).
- **H1 route REFUTED as posed (F9vii/SH-010) [R]:** delta(y* mod Z) is (1) undefined in
  the fractional case (20776 bad overlaps at C7,k=2), (2) gauge non-invariant
  (positive-dimensional optimal face; 3000 bad overlaps for an alternate C5 dual),
  (3) forced to zero where defined (connected nerve). Counts read from
  `final_h1_cocycle_results.json`.
- Single-copy sheaf stratification (SH-001/005) as supporting live exhibits:
  `PossibilisticSupport` |S_e| = 32 / 11 (= `LucasL[5]`) / 0; `HarmonicResidual`
  Laplacian rejection; `CechObstruction` torsion orders (2 for GHZ/Peres-Mermin/CEG-18,
  order 1 for Hardy).
- **Named-hypothesis pointer:** H2' (a genuine quantitative-cohomology detector on a
  different cover) — Layer-2, tagged.

### S6 — Hawking two-sector illustration (HK-003/006/007, F8)
- **Structural negative (HK-003) [T]:** the Cauchy-Schwarz witness used by real
  analogue-Hawking experiments is single-context → CF ≡ 0 identically; **live** at
  K = 2,4,9,11 (incidence matrix = identity). The graph-invariant lens cannot even be
  *posed* for this witness class (unclaimed ground; de Nova-Sols-Zapata concede the
  quadratic-witness restriction).
- **Gaussian sector (HK-007) [T/C]:** the A1-A8 scoreboard as **live symbolic anchors** —
  Planck `Sinh[r_w]^2 == 1/(exp(w/T_H)-1)`, thermal S_vN, log-negativity
  `E_N = 2r/Log[2]`, CS `theta(nbar) = 1 + 1/(2 nbar) > 1`, Busch-Parentani
  `Delta = -Sinh[r]^2 < 0`, CHSH `2 Sqrt[1 + Tanh[2r]^2] -> 2 sqrt2`, single-context
  CF == 0, CV-DLA closes to **dim 10 = sp(4,R), ACTIVE** — all `FullSimplify`/exact Lie
  closure from `hawking-application/gaussian_*.wl`.
- **Qubit info-dynamics sector (HK-006) [T]:** Page curve (Chowdhury Renyi-2 at N=8/10/12),
  Hayden-Preskill mirroring, CHSH/CF certification; anchors CF(2 sqrt2)=sqrt2-1,
  CF(2.25)=0.125; confirmed against four published papers. **Live** via the qubit
  confirmation suite readers.
- **EPR bridge:** r → infinity EPR limit joins the two sectors; B = 2.25 maps to
  r_eff = 0.285020. **Two-tier emulability verdict** stated. **[T]**

### S7 — The constructive mirror: emulator blueprints (EMU-001, F8)
- The optical-synthesis three-layer optical compiler as the synthesis dual of the BBT protocol —
  same two-lens math, target → blueprint.
- **Live:** demo1 KCBS pentagon L1 = exact Lapkiewicz reconstruction, cascade
  [P,T1,T2,T1,T2], **cos theta = 1/GoldenRatio exactly**, genuine so(3) DLA = 3; demo2
  C7 heptagon **S = 7 - 4 theta(C7)**; demo4 V=977/1000 table leaf-confined
  (`DLADimension` < 3). Each blueprint re-simulated by `VerifyBlueprint` (OK → True).
- **Embed** `optical-synthesis/schematics/demo1_kcbs_pentagon_L1.png` and
  `demo3_ddt_mesh_reps2.png`.

### S8 — Gates that failed (the credibility signature; F9)
A dedicated section — negative results are first-class. Each with its live/refuted anchor:
- **Sheaf Laplacian (SH-004/F9iv) [R]:** `HarmonicResidual` = 0 on classical, quantum,
  Wright alike — a no-disturbance projector, live.
- **Affine alpha-credit tilt (F9i) [R]:** no affine-in-f_c certificate family has limit
  gap(ddt).
- **Legendre theta-frontier (F9viii/CERT-004) [R, theorem]:** the concave hull is pinned
  flat at 3/2 on f_c in [1/2,1]; ddt sits 0.0967691 below, unexposed — live via
  `final_ddt_hull.py` result (hull(2/3)=3/2, ddt theta-bar=1.4032309).
- **Q/Z H1 detector (F9vii) [R]:** cross-reference S5 (20776 bad overlaps).
- **Delsarte / Schrijver theta' (F9ix/ERG-004a) [R, theorem]:** theta' = 13^(k/2) exactly;
  theta'(3) = 46.87, floor 46 = the Lovasz ceiling — cannot tighten [39,46]. Read from
  `final_paley13_lp.py` result.
- **Ramsey obstruction (F9v) [R]:** Choudhary-Barbosa technique cannot certify omega<=17
  for the mixed nonagon cell.
- **Ergodic-sheaf category error (F9ii) [R]:** cross-side T→0 yields packing 5/2, not
  Gamma, and does not select ddt.
- **Bound-inertness (F9x/ERG-004b) [R]:** 0 of 26 pentagram families eliminated.

### S9 — The framework under named hypotheses (the honest frontier; Layer 1)
The five open hypotheses stated as sharply-posed problems with proof targets, developed
under-hypothesis exactly as Layer 2 of the FRAMEWORK does. Each **[H]**, with its Layer-2
consequence tagged "under H*":
- **H1 (ddt optimality):** sup gap = gap(ddt); certified within eps = Gamma_10 - gap(ddt)
  = 0.00156; corridor f_c ~ 2/3, alpha-bar in [4/3, 1.4301); target: nonlinear-in-
  frequency certificate (Legendre route dead). **+ H1' (Gamma-limit).**
- **H2' (cohomological detection, reopened):** a genuine quantitative-cohomology detector
  on a cover other than the maximal-clique cover (the delta route is closed).
- **H3 (no-activation):** omega(C9 v C9 v C9 v C5) = 16; live bracket omega in {16..19},
  activation iff omega >= 18, omega(H) = 8 via `(1 + Sec[Pi/9])^3 < 9` (recomputable);
  2/26 NO, 24 PARTIAL, ~69M nodes (read from `erg003_verdict.json`).
- **H4' (A_IE-maximality):** is A_IE the maximal classically-emulable class? (super-class
  with PNR / heralded Fock / non-fair-sampling open.)
- **H5 (Paley product):** omega(P13^v3) = 39; bracket [39, 46], ceiling 46 = floor(13^1.5);
  target Lasserre-2 / non-abelian symmetrization / search.
- **Signaling assessment (O5/SIG-001..003):** feasibility delivered — 3-gate taxonomy on
  7 exemplars, exact cost identity mu = 2 sqrt5 - 4 bits/round, one candidate identity
  refuted (kept). Live via `ContextualFraction`/`SignedNegativity` recomputation of the
  C5 lock CNTX = SF = mu = 2 sqrt5 - 4.

### S10 — Methods appendix (verification culture, the Get-runner pattern, the ledger)
- The `Get[]`-inside-runner rationale (Global`-shadowing of paclet symbols under `-file`).
- The per-module `...Verification` → `OK -> True` discipline; exact arithmetic where
  claimed (Q(sqrt5), `RootReduce`, `WorkingPrecision -> Infinity`, rational SDP/LP
  certificates); pre-registration of gates (Laplacian, protocol thresholds).
- The claims ledger as provenance spine; the A-D epistemic grading; how the essay imports
  numbers so the WSRI requirement is a *build property*, not an editing discipline.
- Environment capture (`$Version`, paclet version, date) into the verification log.

### S11 — References
KCBS (PRL 101 020403); CSW (arXiv:1010.2163); Cabello GE (arXiv:1210.2988, PRL 110
060402); Abramsky-Brandenburger (arXiv:1102.0264, NJP 13); Abramsky-Barbosa-Mansfield
(PRL 119 050504); Ulrey (arXiv:2001.09756, scoped EPRB-bound); Choudhary-Barbosa
(arXiv:2411.09773); Frustaglia et al. (PRL 116 250404); Kovtoniuk-Bohmann-Semenov
(arXiv:2601.13869); Lapkiewicz et al. (Nature 474 490); Hansen-Ghrist (arXiv:1808.01513);
Steinhauer 2016 + Ciliberto-Emig-Pavloff-Isoard (PRA 109 063325); Hudson (1974). Full set
in `docs/RELATED-WORK.md`.

---

## 3. Verification cell (the essay's `OK -> True` contract)

`MasterEssayVerification = <| ... |>` keyed one entry per section, each an exact/tolerant
Boolean recomputed live:
`"atom"` (hierarchy 2, sqrt5, 5/2 + geometry sum) · `"blindspot"` (emulator table ==
quantum table) · `"twoLens"` (`DLADimension[CascadeGenerators[]] == 3`, `So3Axis` rank 2)
· `"cvColumn"` (u(2)=4, sp(4,R)=10 from the CV reader) · `"completeness"` (Prop O3-C
premises present) · `"mesh"` (direct law on small N; tau\* root; gap(ddt) bracket monotone)
· `"gammaLadder"` (Gamma_7>Gamma_8>Gamma_9>Gamma_10 → gap(ddt)) · `"sheaf0"`
(S1=5/2, S2=RootReduce=sqrt5, C7=7/2) · `"h1Refuted"` (bad-overlap counts nonzero) ·
`"laplacian"` (`HarmonicResidual` == 0 on all three) · `"hawking"` (CF==0 single-context;
Planck + CHSH symbolic identities; CV-DLA dim 10) · `"emu"` (cos theta == 1/GoldenRatio;
VerifyBlueprint OK) · `"negatives"` (hull(2/3)=3/2; theta'(3) floor 46). Final:
`"OK" -> And @@ Values[...]`.

---

## 4. numberManifest — every quantitative claim → the module that computes it live

| Claim | Value | Live source (evaluation-time) |
|---|---|---|
| pentagon hierarchy | 2, sqrt5, 5/2 | paclet `IndependenceNumber/LovaszTheta/FractionalPackingNumber[CycleGraph[5]]` + `GraphData` oracle |
| KCBS geometry | axis-sum = sqrt5 | `KCBSDirections[]` + `Simplify` |
| two-copy activation | 535 cliques, sqrt5, Wright 5/4, C7 no-activation | `CEFilter[pentagon, ...]` |
| contextual fraction | 2 sqrt5 - 4 | `ContextualFraction[CycleScenario[5], CycleModel[5,"Quantum"], WorkingPrecision->Infinity]` |
| DLA jump (G7) | span rank 2, dim 3 | `So3Axis/@CascadeGenerators[]`, `DLADimension[CascadeGenerators[]]` |
| access staircase | OQ1 rank 0-vs-2; OQ2 25/25 | readers over `oq1_interventional_dla.py`, `oq2_attenuation_gate.py` results |
| CV Lie dims (G7-CV) | u(2)=4, sp(4,R)=10, sp(2,R)=3 | reader over `certification-protocol/final_o3_cv_dla.py` result |
| certification map | full 3x3 + CV column | `certification_map.wl` regenerates `certification_map.png` live |
| direct law | theta=N+theta(C_N), alpha=floor(3N/2) | `PentagonRing`/`GlueGraphs`+`LovaszTheta`/`IndependenceNumber` on small N |
| twisted density | tau\* = Root[49x^3-128x^2-75x+218,2] | `Root`/`N` live |
| alpha-direct / gap(ddt) | max(4/3,1+f_d/2); 0.0698975 | `CaseStudies.wl` reader; bracket monotonicity check |
| Gamma_k ladder | 0.07702057, 0.07526640, 0.0720260, 0.0714575; eps=0.00156 | readers over `EpsilonCertificate{7,8,9}*.wl` + Gamma_10 numeric |
| orbit spectrum | direct 3/2, twisted tau\*, 16/11, 19/13, 25/17 | `orbit_spectrum_figure.wl` regenerates `orbit_spectrum.png`; residual check |
| degree-0 sheaf | S1=5/2, S2=sqrt5, C7 7/2; Lambda_2(C5)=5, Lambda_2(C7)=49/4, Lambda_3(C7)=343/8 | `bridge_weighted_presheaf.wl`/`essay005_p3_gluing_lp.wl` recompute; `RootReduce` |
| divisibility | 4 does not divide 49; 8 does not divide 343 | `Mod` live |
| H1 refutation | 20776 and 3000 bad overlaps | reader over `final_h1_cocycle_results.json` |
| single-copy sheaf | |S_e| 32/11/0, LucasL[5]=11; torsion 2, Hardy 1 | `PossibilisticSupport`, `CechObstruction` |
| Hawking CF | CF == 0 at K=2,4,9,11 | `hawking_cs_route.py` reader + live incidence recompute |
| Gaussian anchors | Planck, E_N=2r/Log[2], CS theta(nbar), CHSH→2 sqrt2, CV-DLA=10 | `gaussian_*.wl` `FullSimplify` + exact Lie closure |
| qubit sector | CF(2 sqrt2)=sqrt2-1, CF(2.25)=0.125; Page/HP | readers over `ddt_mbqc_hawking_*.wl` results |
| EPR bridge | r_eff = 0.285020 at B=2.25 | live solve of CHSH(r)=2.25 |
| EMU blueprints | cos theta = 1/GoldenRatio; S=7-4 theta(C7); DLA<3 | `OpticalCompiler.wl` demos + `VerifyBlueprint` |
| Legendre dead | hull(2/3)=3/2, ddt 0.0967691 below | reader over `final_ddt_hull.py` result |
| Delsarte dead | theta'(3)=46.87, floor 46 | reader over `final_paley13_lp.py` result |
| ERG-003 | omega in {16..19}, omega(H)=8, 2/26 NO | `(1+Sec[Pi/9])^3<9` live; `erg003_verdict.json` reader |
| Paley bracket | [39,46], 46=floor(13^1.5) | `Floor[13^(3/2)]` live |
| signaling lock | CNTX=SF=mu=2 sqrt5 - 4 | `ContextualFraction`/`SignedNegativity` recompute |

---

## 5. figureManifest

| Figure | Origin | Section | Regeneration |
|---|---|---|---|
| `certification_map.png` | `certification-protocol/certification_map.wl` | S3 | live regenerate (CV column filled) |
| `orbit_spectrum.png` | `composition-optimality/orbit_spectrum_figure.wl` | S4 | live regenerate |
| `demo1_kcbs_pentagon_L1.png` | `optical-synthesis/schematics/` | S7 | existing; re-emit via `OpticalCompiler.wl` |
| `demo3_ddt_mesh_reps2.png` | `optical-synthesis/schematics/` | S7 | existing; re-emit |
| Gamma_k bracket plot (NEW) | inline `ListLinePlot` in the essay | S4 | live from the Gamma-ladder readers → gap(ddt) |
| Pentagon-chain gap-parity plot | inline (precedent cell) | S4 | live `PentagonChain` + `LovaszTheta` |
| Hawking two-sector schematic (NEW, optional) | inline, Gaussian r-sweep of CHSH(r) | S6 | live from `2 Sqrt[1+Tanh[2r]^2]` |

Any newly-authored figure is generated **inside** the essay from live values (no static
imports of unverifiable art); the four existing PNGs are re-emitted by their generators as
part of the build so they never drift from the numbers.

---

## 6. Build order for the implementer

1. Scaffold `EvaluatingBlackBoxPhysics.wl` with the cell grammar and the loader cell
   (paclet load + `Remove` de-shadow) copied from `CertifyingQuantumness.wl`.
2. Write small readers for the committed Python/JSON result artifacts (one `Association`
   per artifact) so their numbers enter the kernel verified, not re-typed.
3. Fill S1-S10 top to bottom; after each section, extend `MasterEssayVerification`.
4. Add `runners/RunMasterEssay.wl` (Get-based); confirm headless `OK -> True`.
5. Regenerate the two live figures; embed the four PNGs; author the inline plots.
6. Generate `EvaluatingBlackBoxPhysics.nb` from the source.
7. Commit source + runner + notebook + this outline.
