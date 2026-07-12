# NOTES — Classical Emulatability of Hawking-Radiation Dynamics: A First Pass

Hubert Kołcz's project — 10 July 2026. Worktree branch `claude/hawking-emulation`
(base `master` 9f4be1e). Artifact: `hawking_cf_bridge.py` (executable, exit 0, all
anchors PASS — every number quoted below with no citation was produced there).
Status: **first pass**, as scoped — literature grounding plus one small, honest
computational bridge, not a finished result. Every quantitative claim below is
either (a) sourced to a specific arXiv/DOI, fetched and read directly for this
note, or (b) explicitly flagged as this note's own bridging construction.

## 0. Why this stream had zero prior work

The project's research description names "the classical emulatability of
Hawking-radiation dynamics" as an application; nothing in this repo (root,
`BlackBox/`, or any other worktree) mentions Hawking, analogue gravity, or
Bogoliubov before this branch (checked: `grep -ril hawking` across the whole
tree returns only this worktree's own new files).

## 1. Two families of analogue-gravity experiment — a distinction the project needs

The literature search turned up two genuinely different kinds of experiment,
and the project's quantum-vs-classical machinery (CF, exclusivity graphs) is
only relevant to one of them.

**(A) Classical / stimulated wave-equation tests.** These verify the *kinematic*
analogy (a horizon exists; the field equation on a moving medium mode-converts
the way Hawking's equations predict) using an already-classical input signal.
There is no hidden-variable question here — the "signal" was never claimed to
be quantum, so there is nothing for a CF-style certificate to certify.
- Philbin, Kuklewicz, Robertson, Hill, König, Leonhardt, "Fiber-Optical Analog
  of the Event Horizon," Science 319, 1367 (2008); arXiv:0711.4796 (main text),
  arXiv:0711.4797 (appendices). Abstract, verbatim: "We observed a classical
  optical effect, the blue-shifting of light at a white-hole horizon. We also
  show by theoretical calculations that such a system is capable of probing
  the quantum effects of horizons" — i.e. the *observation* is classical; the
  quantum case is a theoretical proposal only, not claimed as observed.
- Weinfurtner, Tedford, Penrice, Unruh, Lawrence, "Measurement of Stimulated
  Hawking Emission in an Analogue System," PRL 106, 021302 (2011);
  arXiv:1008.1911. A streamlined obstacle in open-channel water flow; measures
  the thermal spectrum of *stimulated* (classically seeded) wave conversion.
  Explicitly stimulated, not spontaneous: "our measurements... demonstrate the
  thermal nature of the conversion process... [and] attest to the generality
  of the Hawking process" by analogy, not by a quantum/classical separation.
- Euvé, Michel, Parentani, Philbin, Rousseaux, "Observation of Noise Correlated
  by the Hawking Effect in a Water Tank," PRL 117, 121301 (2016);
  arXiv:1511.08145. Correlated noise from a horizon — but the correlated
  "vacuum" is literal water-surface turbulence. Leonhardt (see §3) describes
  this precisely: "the slight turbulence of the water played the role of the
  quantum vacuum, stimulating Hawking radiation from classical fluctuations...
  classical fluids like water cannot show quantum entanglement."

**(B) Spontaneous / quantum tests.** Only these pose the quantum-vs-classical
question this project's machinery is built for: is the observed pair
correlation explicable by a classical (thermal/stimulated) model, or does it
require a genuinely nonclassical (entangled / Bell-violating) resource? This
is Steinhauer's BEC line of work (§2) and, theoretically, its 2024
Bell-inequality extension (§3) — and it is where this note's computational
bridge (§4) is aimed.

## 2. The Steinhauer BEC program, precisely

**The correlation signature.** Balbinot, Fabbri, Fagnocchi, Recati, Carusotto,
"Non-local density correlations as signal of Hawking radiation in BEC acoustic
black holes," Phys. Rev. A 78, 021603(R) (2008); arXiv:0711.4520, proposed the
density-density correlation function G⁽²⁾(x,x′) between points inside and
outside a sonic horizon as the observable signature of Hawking pairs.

**The 2016 entanglement claim.** Steinhauer, "Observation of quantum Hawking
radiation and its entanglement in an analogue black hole," Nature Phys. 12,
959 (2016); arXiv:1510.00621 (fetched and read in full for this note). Key
facts, verbatim from the paper:
- Measured Hawking temperature k_BT_H = 0.36 mc²_out, "slightly above the
  range of predicted approximate maximum values 0.25–0.32 mc²_out."
- The entanglement criterion actually used is the nonseparability parameter
  Δ ≡ ⟨b†_HR b_HR⟩⟨b†_P b_P⟩ − |⟨b_HR b_P⟩|² (their Eq. 3); Δ<0 ⟺ nonseparable.
  This inequality form is due to Busch & Parentani, Phys. Rev. D 89, 105024
  (2014) ("Quantum entanglement in analogue Hawking radiation: When is the
  final state nonseparable?"); its equivalence to the Peres–Horodecki
  criterion for stationary, homogeneous modes is shown in Steinhauer,
  "Measuring the entanglement of analogue Hawking radiation by the
  density-density correlation function," Phys. Rev. D 92, 024043 (2015) — the
  companion methods paper the 2016 result implements.
- Reported significance, in the paper's own words: "the Hawking temperature
  determined from the population distribution is 1.2 nK, far below the
  measured 2.7 nK upper limit for quantum entanglement" — a ratio-of-scales
  argument, not a sigma count.

**The distinct Cauchy–Schwarz route.** A *different*, closely related
criterion — the one this project's brief specifically named — is due to
de Nova, Sols, Zapata, "Violation of Cauchy-Schwarz inequalities by
spontaneous Hawking radiation in resonant boson structures," Phys. Rev. A 89,
043808 (2014); arXiv:1211.1761 (fetched and read in full). Exact form: for
outgoing-quasiparticle correlators Γ_ij, the classical bound is
[g⁽²⁾_ij(τ)]² ≤ g⁽²⁾_ii(0) g⁽²⁾_jj(0) (their Eq. 4), violated iff θ_ij ≡
Γ_ij/√(Γ_iiΓ_jj) > 1 (Eq. 6); for the anomalous Hawking-pair channel this
reduces at T=0 to θ_ud2 = (|S_d2d2|²−½)/(|S_d2d2|²−1) > 1, guaranteed whenever
the Hawking S-matrix element S_ud2 ≠ 0 (Eq. 12) — i.e. spontaneous Hawking
emission *entails* CS violation. This is a **theoretical proposal for a
resonant double-barrier structure** (a discrete-spectrum toy horizon amenable
to direct atom-counting), not the criterion Steinhauer's 2016 experiment (a
smooth gray-soliton horizon) actually used. The follow-up unification, de
Nova, Sols, Zapata, "Entanglement and violation of classical inequalities in
the Hawking radiation of flowing atom condensates," New J. Phys. 17, 105003
(2015); arXiv:1509.02224, reviews several criteria and concludes (abstract,
verbatim): "within a class of detection schemes, only the violation of
quadratic Cauchy-Schwarz inequalities can be discerned" — i.e. CS violation,
not Δ or full state tomography, is the practically measurable one. **Reading
for this project:** the project brief's phrase "Cauchy-Schwarz-inequality
violation... to argue the observed Hawking-pair correlations are quantum" is
accurate as a description of *this literature family's toolbox*, but the
specific 2016 Nature Physics result used the algebraically related
nonseparability Δ, not literally the g⁽²⁾ Cauchy–Schwarz form; the two are
siblings (both are "classical bound vs. quantum-violating bound" statements
about the same second-order correlation data), not the same equation.

**The 2019 thermal-spectrum follow-up.** de Nova, Golubkov, Kolobov,
Steinhauer, "Observation of thermal Hawking radiation at the Hawking
temperature in an analogue black hole," Nature 569, 688 (2019);
arXiv:1809.00913 — confirms the Planck spectrum and its temperature matches
the analogue surface gravity, a separate claim from entanglement.

**The controversy (report plainly, as instructed).** Leonhardt, "Questioning
the recent observation of quantum Hawking radiation," Annalen der Physik,
DOI 10.1002/andp.201700114 (2018); arXiv:1609.03803 (fetched and read in
full) disputes the 2016 entanglement claim on five points: the measured
spectrum is not fully Planckian; correlations appear beyond the wavenumber
where the particle population is zero within error bars (physically
impossible for genuine pair correlations); accounting for wavenumber
uncertainty reduces the entanglement signal from "1σ to 2σ" separation to
indistinguishable at 2σ; the population of only the Hawking-side (not the
partner-side) mode was independently measured, so n̄_H = n̄_P was assumed, not
verified; and the Fourier-filtering method used to extract the correlation
band was not shown against the full noise floor. Leonhardt's paper states the
original claim's own quoted confidence, citing Steinhauer's informal response
arXiv:1609.09017: "having observed entanglement with a confidence of
90/16 = 5.7σ..., which reduces to the order of 1σ after an analysis of the
uncertainties involved." Steinhauer's arXiv:1609.09017 rebuts the critique
point by point ("We answer all of the comments... and show that the
criticisms are not valid"). **This is a live, unresolved dispute in the
primary literature**, not a caveat this note is inventing.

## 3. The 2024 Bell-inequality bridge — the load-bearing find

Ciliberto, Emig, Pavloff, Isoard, "Violation of Bell inequalities in an
analogue black hole," arXiv:2404.16497 (2024) (fetched and read in full).
They discretize the Gaussian 2/3-mode Bogoliubov state of a 1D BEC
analogue-horizon via GKMR pseudospin operators (Hermitian, eigenvalues ±1,
Wigner transforms tractable on Gaussian states) and construct genuine CHSH,
Svetlichny (tripartite), and Mermin Bell operators. Exact facts:
- CHSH: local-realist bound 2, Cirel'son (Tsirelson) bound 2√2 = 2.8284.
  "Waterfall" flow configuration at downstream Mach number m_d = 2.9 (matching
  the Technion 2019 experiment, i.e. de Nova–Golubkov–Kolobov–Steinhauer,
  Nature 569, 688 (2019)): at T = 0, max Hawking/partner CHSH parameter
  **B⁽⁰|²⁾ = 2.25**; the companion/partner pair peaks at exactly B⁽¹|²⁾ = 2
  (no violation) at this same Mach number. The bipartite ceiling 2√2 is
  reached only in the idealized EPR limit (upstream Mach number m_u → 0 or 1).
- Temperature fragility: at T = 0.2 gn_u, the CHSH parameters "no longer show
  evidences of violation of Bell inequality, except in the (1|2) sector for
  waterfall configurations with m_u ≲ 0.15 and, in a lesser extent, in the
  (0|2) sector for m_u ≳ 0.85" — i.e. the bipartite Bell signal is fragile
  but not uniformly zero at finite T.
- Tripartite Svetlichny parameter S⁽⁰|¹|²⁾: bound 2 (local), 2√2 (nonlocal
  ceiling); reached EXACTLY at ω→0, T=0 for every configuration tested — but
  "always lower or equal to 2" already at T = 0.05 gn_u. The ω=0, T=0 vacuum
  is shown to be an infinite sum of degenerate three-mode GHZ states — unlike
  qubit GHZ states, it stays entangled after tracing out one mode, because of
  the infinite degeneracy of the pseudospin eigenvalues on continuous
  variables.
- Mermin parameter M⁽⁰|¹|²⁾: algebraic max 4, reached at T=0,ω=0 for all
  configurations; local (Mermin–Klyshko) bound 2. More temperature-robust
  than CHSH in places: at T = 0.1 gn_u, m_u = 0.3, M = 2.19 (still violating)
  versus the largest CHSH values in the same configuration, 2 and 2.017
  (essentially not violating).
- This is a **theoretical proposal**; no such Bell test has been performed on
  a real analogue-Hawking device.

## 4. The precise analogy to this project's machinery

**KCBS-C5 is the wrong graph; CHSH is the right one, and it is already here.**
KCBS/C5 (this project's atomic block) is a single-system, multi-context
scenario — one wire, sequentially compatible measurements
(`kcbs_circuit.wl`, verbatim: "CHSH needs two wires because it is a two-party
test; KCBS deliberately does not"). Hawking-pair correlations are inherently
bipartite (Hawking mode vs. partner mode; tripartite with the companion mode
peculiar to Lorentz-violating analogues). The structurally correct point of
contact is therefore CHSH, not the pentagon — and CHSH is **already inside
this project's existing machinery**, twice over:
1. `kcbs_circuit.wl` already computes the CHSH exclusivity graph Ci(8;1,4)
   and its Lovász number, `lovaszTheta[CirculantGraph[8,{1,4}]]` = 2+√2,
   verbatim: "CHSH is the same graph formalism with a different graph (8
   events... theta = 2 + Sqrt[2])" (also `QUANTUM_CONTEXTUALITY.md` §5: "CHSH
   exclusivity graph = Ci(8;1,4), ϑ = 2+√2 (same SDP machinery covers
   nonlocality)").
2. Independently, branch `claude/signaling-taxonomy` (`signaling_taxonomy.py`
   / `NOTES-signaling.md`) already computed the exact Abramsky–Brandenburger
   contextual fraction of CHSH itself: **CF(CHSH Tsirelson) = √2−1 ≈
   0.4142135624**, CF(CHSH PR box) = 1 — the same LP machinery this project
   uses for the pentagon, already run on the bipartite scenario Hawking pairs
   actually need.

**The bridge this note builds (`hawking_cf_bridge.py`, mine, not a claim of
either cited paper).** A CHSH value S alone does not fix a probability table
— it is one linear functional of it. `hawking_cf_bridge.py` uses the standard
*isotropic* table (three settings pairs at correlation +S/4, one at −S/4,
exactly `chsh_corr_model`'s convention in `signaling_taxonomy.py`) as the
canonical representative and computes its exact CF by the same
Abramsky–Brandenburger LP as `mbqc_blackbox_test.py` (`ncf_lp`/`cf_of`), on
the native (2,2,2,2) Bell scenario (4 contexts, 4 outcome sections, 16
deterministic local assignments) — rebuilt from scratch in this worktree and
cross-checked, not copied, against the two pre-existing anchors above.

**Disanalogies, stated plainly, per the task's own instruction:**
- The isotropic-table map S ↦ e(S) is *this note's* construction. Ciliberto
  et al. compute an expectation value of a Bell operator on an idealized
  Gaussian state, not a measured (2,2,2,2) outcome table; no real
  analogue-Hawking Bell experiment exists to check the isotropy assumption
  against.
- There is no finite-sample layer here. `mbqc_blackbox_test.py`'s whole
  apparatus — Hoeffding bounds, bootstrap CIs, a pre-registered verdict order,
  a DLA/leaf-confinement audit against a specific spoofing mechanism — has no
  counterpart for this application, because the "device" is a theoretical
  model, not yet a black box with real click data. See §5.
- The DLA/so(3) leaf-confinement audit (`mbqc_blackbox_test.py`'s
  `dla_hook`/`cascade_generators`) does not transplant directly. It was built
  for a *specific* spoof — a claimed multi-axis qutrit mode compilation that
  is secretly confined to one rotation axis (SO(3) acting on a 3-dimensional
  Stokes/Bloch sphere). Hawking-pair states are Gaussian continuous-variable
  states; their symmetry group is the real symplectic group Sp(2n,R) acting
  on covariance matrices (n=2 or 3 modes here), not SO(3) — see Weedbrook,
  Pirandola, García-Patrón, Cerf, Ralph, Shapiro, Lloyd, "Gaussian quantum
  information," Rev. Mod. Phys. 84, 621 (2012); arXiv:1110.3234, for the
  standard formalism. A leaf-confinement-style audit for THIS platform would
  need to be re-derived on Sp(4,R)/Sp(6,R) orbits and their Casimirs, not
  reused from so(3). Not done here; see §5.
- A CHSH/Bell violation, if it were unambiguously measured (not merely
  computed on an idealized model), is by construction already
  device-independent evidence against any classical/local model — unlike the
  KCBS pentagon's intensity-emulator loophole (§ mbqc_blackbox_test.py's
  adversarial case iii-d), which survives *because* it exploits a semantics
  gap between intensity fractions and single-event clicks that a bare
  probability table cannot see. The corresponding worry for a real
  analogue-Hawking Bell test is not a DLA-style structural audit but the
  standard Bell-test loophole pair: **locality** (are the two mode
  measurements genuinely independent, spacelike-chosen settings, or read out
  from one jointly accessible classical field?) and **detection efficiency**
  (fair sampling of phonon/atom counts). Both are open experimental
  questions, not yet addressed anywhere in this literature search.
- A genuinely useful, low-cost analogy this note DID find: Leonhardt's
  critique's point that n̄_H = n̄_P was assumed rather than independently
  measured is structurally identical to `mbqc_blackbox_test.py`'s **C1
  no-disturbance certificate** (a measurement's marginal must agree across
  the two contexts sharing it). A real black-box test of analogue Hawking
  radiation would need exactly this as its first, pre-registered check —
  independently confirming n̄_H = n̄_P — before any entanglement or CHSH claim
  is meaningful, mirroring this project's own certificate ordering (V1
  precedes V2/V3 in `mbqc_blackbox_test.py`).

## 5. What `hawking_cf_bridge.py` computed (338 lines; exit 0, all anchors PASS)

Pre-registered anchors, checked before the literature point (mirroring
`mbqc_blackbox_test.py`'s "abort if any anchor is off" rule):

| anchor | computed | reference value |
|---|---|---|
| CF(CHSH local/classical bound, S=2) | 0.0000000000 | 0 (exact) |
| CF(CHSH Tsirelson, S=2√2) | 0.4142135624 | √2−1, `signaling_taxonomy.py` |
| CF(CHSH PR box, S=4) | 1.0000000000 | 1 (exact) |
| CF(KCBS quantum pentagon) | 0.4721359550 | 2√5−4, this repo |
| CF(S) monotone on S∈[2,4] | confirmed, 21-pt grid | — |
| CF(S) = (S−2)/2 on the isotropic family | max deviation 2.22e-16 | machine precision |

All six pass; the CHSH-Tsirelson and KCBS-pentagon numbers match
pre-existing, independently-computed values elsewhere in this repo to
machine precision, which is the actual point of the anchor step (this
script's own LP harness is trustworthy before it is pointed at anything new).
A genuine, LP-verified finding along the way: on the isotropic family the
exact contextual fraction of the (2,2,2,2) Bell scenario is **CF(S) =
(S−2)/2**, confirmed by linear programming, not merely asserted.

Then, the literature point (external input, clearly separated from the
anchors): **S = 2.25** (Ciliberto et al. 2024, waterfall configuration,
m_d = 2.9, T = 0) gives **CF = 0.125** — about 30% of the way from the
classical bound to the generic CHSH/Tsirelson ceiling (CF = 0.4142), and
about 26% of the KCBS pentagon's own CF (0.4721). The idealized T=0 EPR limit
of the same paper (S → 2√2) gives CF → 0.4142, i.e. the same ceiling as the
generic Tsirelson anchor, since in that limit the analogue system literally
realizes a qubit EPR pair. All caveats in §4 apply to these two numbers; the
script prints them again at runtime so they travel with the result.

## 6. Open questions

1. **Build the real thing `mbqc_blackbox_test.py` has and this doesn't:** a
   finite-sample certificate stack for an ACTUAL discretized measurement of
   Hawking-pair correlations (real or simulated Bogoliubov data), starting
   with the n̄_H = n̄_P no-disturbance check (§4), then CHSH (or Δ / CS
   violation) with a pre-registered confidence budget, in place of a bare
   expectation value on an idealized state.
2. **Resolve or at least formally register** the Leonhardt/Steinhauer dispute
   (§2) as a modeled case: does this project's Hoeffding/bootstrap CF
   machinery, applied to a re-analysis of the published Fig. 1–6 data of
   Steinhauer (2016), land on QUANTUM-CERTIFIED, INCONCLUSIVE, or
   EMULATION-SUSPECT under a pre-registered protocol? Not attempted here —
   would need the underlying pixel data (Leonhardt states his own reanalysis
   was done pixel-by-pixel from the published figures; the data are not in
   this repo).
3. **Derive, don't borrow, the Bogoliubov S=2.25 number.** This note treats
   S=2.25 as an external citation. Reproducing it requires the actual
   scattering-matrix solution of the "waterfall" 1D Gross-Pitaevskii/
   Bogoliubov-de Gennes boundary-value problem (Zapata, Albert, Parentani,
   Sols, New J. Phys. 13, 063048 (2011); Larré, Recati, Carusotto, Pavloff,
   Phys. Rev. A 85, 013621 (2012), are the underlying scattering-theory
   references cited by the papers above) — nontrivial physics modeling, out
   of scope for a first pass, flagged rather than faked.
4. **Re-derive the leaf-confinement idea on Sp(2n,R).** What is the Gaussian-
   state analogue of "DLA < 3 ⟹ intensity-emulable"? Candidate: a Bell/CHSH
   violation that survives only because of a restricted (e.g.
   passive-optics-only, no genuine two-mode squeezing) symplectic
   compilation would be the right notion of "leaf-confined" here — not
   formalized.
5. **The CS-inequality route (§2) is arguably more native to this project's
   E-principle framing than CHSH:** de Nova–Sols–Zapata's θ_ij > 1 criterion
   is itself a two-outcome exclusivity-type bound derived from positivity of
   a Glauber–Sudarshan P function. Whether it can be phrased as a graph
   invariant the way CF/ϑ/α* are (rather than bridged through CHSH as done
   here) is open and untried.
6. **Locality/detection-efficiency loopholes** (§4) for any future real
   analogue-Hawking Bell test — genuinely open, not analyzed here.

## 7. Doc-merge notes (do not edit QUANTUM_CONTEXTUALITY.md / README.md from this branch)

- `QUANTUM_CONTEXTUALITY.md` §6 (artifacts): if merged, add
  `hawking_cf_bridge.py` + this note with the headline: CHSH (not KCBS-C5) is
  the correct graph for Hawking-pair correlations; CF(Hawking/partner,
  Ciliberto et al. 2024, T=0) = 0.125 on this project's own CF scale, via an
  explicitly-flagged isotropic-table bridge.
- §8/references: add the full reference list of §8 below.
- §9 (open threads): add items 1–6 of §6 above; flag this as the newest, and
  least mature, stream — first pass only, per the task that started it.

## 8. References (pinned, arXiv/DOI verified by direct fetch during this session)

1. T. G. Philbin, C. Kuklewicz, S. Robertson, S. Hill, F. König, U. Leonhardt,
   Science 319, 1367 (2008); arXiv:0711.4796 (main), arXiv:0711.4797 (appendices).
2. S. Weinfurtner, E. W. Tedford, M. C. J. Penrice, W. G. Unruh, G. A. Lawrence,
   PRL 106, 021302 (2011); arXiv:1008.1911.
3. L.-P. Euvé, F. Michel, R. Parentani, T. G. Philbin, G. Rousseaux, PRL 117,
   121301 (2016); arXiv:1511.08145.
4. R. Balbinot, A. Fabbri, S. Fagnocchi, A. Recati, I. Carusotto, Phys. Rev. A
   78, 021603(R) (2008); arXiv:0711.4520.
5. J. Steinhauer, Nat. Phys. 12, 959 (2016); arXiv:1510.00621; DOI
   10.1038/nphys3863.
6. J. Steinhauer, Phys. Rev. D 92, 024043 (2015) (density-density →
   entanglement method).
7. X. Busch, R. Parentani, Phys. Rev. D 89, 105024 (2014) (nonseparability
   criterion).
8. J. R. M. de Nova, F. Sols, I. Zapata, Phys. Rev. A 89, 043808 (2014);
   arXiv:1211.1761 (Cauchy–Schwarz violation, exact inequality forms).
9. J. R. M. de Nova, F. Sols, I. Zapata, New J. Phys. 17, 105003 (2015);
   arXiv:1509.02224 (unifying review; CS violation "discernible" claim).
10. J. R. M. de Nova, K. Golubkov, V. I. Kolobov, J. Steinhauer, Nature 569,
    688 (2019); arXiv:1809.00913; DOI 10.1038/s41586-019-1241-0.
11. U. Leonhardt, Annalen der Physik, DOI 10.1002/andp.201700114 (2018);
    arXiv:1609.03803 (critique).
12. J. Steinhauer, arXiv:1609.09017 (rebuttal; source of the "90/16=5.7σ" figure).
13. G. Ciliberto, S. Emig, N. Pavloff, M. Isoard, arXiv:2404.16497 (2024)
    (Bell/Svetlichny/Mermin violation in an analogue black hole).
14. C. Weedbrook, S. Pirandola, R. García-Patrón, N. J. Cerf, T. C. Ralph,
    J. H. Shapiro, S. Lloyd, Rev. Mod. Phys. 84, 621 (2012); arXiv:1110.3234
    (Gaussian quantum information; Sp(2n,R) formalism, cited for §4's
    disanalogy discussion).
15. This repo: `kcbs_circuit.wl` (CHSH-as-Ci(8;1,4) remark), `QUANTUM_
    CONTEXTUALITY.md` §5, `signaling_taxonomy.py`/`NOTES-signaling.md` (branch
    `claude/signaling-taxonomy`; CF(CHSH) anchors), `mbqc_blackbox_test.py`
    (branch `claude/mbqc-blackbox-test`; LP/certificate-stack style reused
    throughout).
