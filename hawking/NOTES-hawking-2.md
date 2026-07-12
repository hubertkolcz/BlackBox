# NOTES-hawking-2.md — Second Pass: Engaging the Dispute Directly, the Cauchy–Schwarz Route, and a Certificate-Stack Sketch

Hubert Kołcz's project — 11 July 2026. Branch `claude/hawking-emulation`, built on tip
`46e3311f` (the first pass). This note is strictly additive: `NOTES-hawking.md` (375
lines) and `hawking_cf_bridge.py` (338 lines) were read in full from that commit before
writing anything here, and neither is edited. It also rereads `mbqc_blackbox_test.py`
(branch `claude/mbqc-blackbox-test`) and `signaling_taxonomy.py`/`NOTES-signaling.md`
(branch `claude/signaling-taxonomy`) for the certificate-stack/LP patterns reused below,
and `SignedNegativity.wl`/`kcbs_wigner_flow.wl` (master) as candidate homes for the
Cauchy–Schwarz route before concluding, with reasons, that none of them fit.

Scope: the three questions the task set, in the priority order given. Item 1 is a
literature-and-availability investigation, not a computation — no code accompanies it,
because the honest finding is that there is nothing to compute on. Item 2 is likewise
answered in prose plus two small, self-contained derivations (not a new LP/SDP script),
because the honest finding is that this project's existing LP machinery does not apply
and building a new one to force a fit would be exactly the "computation just to have one"
the brief warned against. Item 3 is a design note, as the brief explicitly allows.

---

## 1. Can the Leonhardt/Steinhauer dispute be engaged with directly?

**Short answer: no — searched hard, found no shared dataset on either side, and the full
texts of both disputants show precisely why "give me the data" was never how this fight
was going to be settled. Below is exactly what was checked and exactly what would be
needed.**

### 1.1 What was searched

- Web searches for a data-availability statement, repository, or supplementary dataset
  attached to Steinhauer, *Nat. Phys.* 12, 959 (2016) (arXiv:1510.00621): none found.
  Nature Physics' own editorial history states the data-availability-statement policy
  was only piloted from March 2016 and rolled out to all Nature Research journals by
  early 2017 — this paper (submitted Nov 2015, published Aug 2016) sits right at that
  boundary, and no such statement is visible on the article page.
- Web searches for the dataset on Zenodo, Figshare, GitHub, Dryad, and the Technion
  institutional repository: none found for any Steinhauer analogue-black-hole paper
  (2010–2021). The lab's own site (`phsites.technion.ac.il/atomlab/research/hawking-
  radiation/`) lists six related publications and links to a description of the
  entanglement-measurement *technique*, but no data files or repository.
- Fetched the full text of both primary combatants directly (not just the summaries
  already in `NOTES-hawking.md`), specifically hunting for any statement about data
  sharing:
  - Leonhardt, arXiv:1609.03803 (final v3, Apr 2018): the paper is explicit, repeatedly,
    that its own inputs are **not** raw data but pixel coordinates read off the
    published figures — "taken pixel–by–pixel from the electronic version of Fig. 3 of
    the article," again for Fig. 5b, again for Fig. 6a (his Figs. 1–3 captions,
    verbatim). Leonhardt is not reanalysing a dataset; he is re-digitizing plots.
  - Steinhauer's rebuttal, arXiv:1609.09017 (2016), a 17-page point-by-point response
    engaging Leonhardt's comments at the level of individual figure captions and
    convolution kernels, **never once offers an underlying dataset**. Every rebuttal
    point is argued by re-describing what a cited figure of the original article
    already shows or by disputing Leonhardt's error-bar arithmetic (a factor of 2, a
    factor of √2, FWHM-vs-σ, a factor of 1.2) — not by producing numbers Leonhardt
    didn't have. That silence, in a document with every incentive to end the argument
    by pointing at a file, is itself informative (weak, not conclusive, evidence — the
    absence of an offer to share data is not proof none exists, but 17 pages of
    micro-level methodological combat with no "here is the raw run-by-run data" is
    notable).
  - Leonhardt's own critique states plainly that the *partner*-mode population n̄_P was
    never independently published at all: "The article [13] contains a hint [33] that
    also the population of the Hawking partners was measured, but the data were not
    published" (his footnote 33: a stray correction-factor mention in the original text
    "indicates that the population n_P was measured and not only n_H"). Steinhauer's
    rebuttal (Comment 50) does **not** contest this — it defends the *assumption*
    n̄_H = n̄_P as physically reasonable, but does not produce the n̄_P measurement.
    This is the one point in the whole exchange where both sides effectively agree a
    number exists that was never published.
- Checked whether either side's argument even depends on disputed *values*: it does not.
  Every quantitative disagreement in both full texts is about the **definition of
  uncertainty** applied to the *same* pixel-read points from the *same* six figures of
  the *same* 2016 article (is a plotted bar a 1σ error bar or a FWHM mode-width; does
  combining two k-variables multiply widths by √2; is the half-width-at-half-maximum
  equal to σ or 1.2σ). Neither side ever disputes the other's reading of a data point;
  the entire "5.7σ reduces to ~1σ" fight (both papers, same number, same citation chain)
  is a dispute over a convention for turning already-published aggregate curves into an
  error bar, not a dispute over a raw measurement.
- Checked for a resolving follow-up. Kolobov, Golubkov, de Nova, Steinhauer, *Nat. Phys.*
  17, 362 (2021) (arXiv:1910.09363) is the natural next candidate — it re-examines the
  same apparatus — but it targets **stationarity** of the Hawking spectrum over time, not
  a re-run of the entanglement/CS significance calculation; it does not settle the 2016
  dispute and does not carry a data-availability statement either (checked the arXiv and
  Nature abstract pages; none visible).
- Checked the most current expert source available: a September 2025 conference talk by
  M. Isoard, G. Ciliberto, N. Milazzo, N. Pavloff, O. Giraud — co-authors of the 2024
  Bell-inequality paper this project's first pass already used — "Entanglement in a BEC
  analogue black hole" (IFPU Trieste workshop, Sept. 2025; slides at
  `lptms.universite-paris-saclay.fr/nicolas_pavloff/files/2025/09/Trieste_2025.pdf`).
  Their own "state of play" table lists analogue-BEC thermality as **"roughly YES (but
  disputed)"**, and their conclusion slide states, verbatim: "The thermality of
  analogous Hawking radiation is still a matter of debate," and on the quantum
  (entanglement) question specifically: "can be directly addressed by present time
  experimental setups / → **no indisputable result yet**." This is the most recent
  first-party assessment found, and it confirms — from inside the field, eight-plus
  years after Leonhardt's critique — that the dispute this project's first pass reported
  as "live and unresolved" is *still* considered live and unresolved by the people
  building on it, not a settled matter this project's notes were simply slow to update.
  (Treated here as what it is — informal conference slides, not a peer-reviewed
  citation — but a legitimate and very current primary source on the field's own
  self-assessment.) The same talk cross-checks a **third** criterion, the continuous-
  variable PPT/Peres–Horodecki parameter (Serafini–Adesso–Illuminati, Phys. Rev. A 2005,
  as adapted by these authors), plotted directly against six real data points read from
  de Nova–Golubkov–Kolobov–Steinhauer, *Nature* 569, 688 (2019) — again explicitly
  labelled "points from de Nova et al. Nature 2019," i.e. again figure-derived, not raw,
  and again captioned with three explicit assumptions ("Gaussian state," "companion
  occupation negligible," "⟨ĉ₀ĉ₂⟩ accurately extracted from the density–density
  correlation signal") that a from-scratch reanalysis would have to either accept on
  faith or independently check — which is impossible without the run-by-run data.
- A related but distinct system, cited in the same talk, is worth a one-line flag and no
  more: Gondret et al., PRL (2025), reporting entanglement of pairs produced by the
  dynamical Casimir effect (a different analogue platform, not a BEC sonic horizon) —
  offered by the talk as an example of a platform where an "indisputable" entanglement
  result *has* recently been claimed, in implicit contrast to the BEC-horizon case. Not
  investigated further here; it is a different physical system from this project's
  Hawking-pair thread and outside the scope of items 1–2.

### 1.2 Finding

No raw click data, run-by-run density profile, or machine-readable correlation table for
any Steinhauer analogue-Hawking-radiation experiment is publicly available, from either
side of the dispute, in 2016, 2019, 2021, or as of the most recent (Sept. 2025) follow-up
work found. Both the original claim and its critique, and the follow-up literature that
plots against the original claim, work entirely from pixel-digitized published figures.
**This project's certificate machinery (`mbqc_blackbox_test.py`'s Hoeffding/bootstrap
apparatus, `signaling_taxonomy.py`'s LP gates) cannot be run against this dispute** — not
because of a missing translation step, but because there is no dataset to feed it. Per
the task's own instruction, no data is fabricated or simulated here to fill that gap.

### 1.3 What would actually be needed (precise, not generic)

Grounded in exactly what both full texts turned out to disagree about:

1. **The independent partner-population measurement n̄_P(k)**, not just n̄_H(k) — the one
   point Steinhauer's own rebuttal does not contest was never published. This is the
   direct analogue of this project's **C1 no-disturbance check** in
   `mbqc_blackbox_test.py` (a measurement's marginal must be checked, not assumed, in
   both contexts that share it) and was already flagged as the key open item in
   `NOTES-hawking.md` §4's last bullet; this second pass confirms, from the primary
   sources, that the missing half of exactly this check is the crux of the published
   dispute, not a peripheral detail.
2. **Run-by-run (shot-resolved) density profiles**, not the ensemble-averaged,
   Fourier-filtered density–density correlation map (Fig. 4 of the 2016 article) that
   both sides work from. Without per-shot data there is no way to construct a
   sample-size-parameterized confidence interval at all — "N" in this project's Hoeffding
   bounds is the number of independent runs (4,600, per the 2016 article), and neither
   paper's dispute ever engages that number; it argues entirely about the width of an
   already-averaged curve.
3. **An unambiguous, pre-registered definition of the resolution/error width**, fixed
   *before* looking at the data. The entire "5.7σ → ~1σ" disagreement is a dispute about
   whether a plotted bar is a 1σ statistical uncertainty or a physical mode-width (FWHM
   of the outgoing wavepacket), and about combination factors (√2, 1.2, 2) applied to it.
   This is precisely the kind of ambiguity a pre-registered protocol eliminates by
   construction, and its presence here — argued for 2+ rounds across 2016–2018 without
   resolution — is itself an argument for why this project's "fix the confidence budget
   before computing anything" discipline (visible in every existing certificate file in
   this repo) is not a stylistic preference but the actual fix for this specific,
   real dispute.
4. **The full (unfiltered) Fourier spectrum of the density–density correlation**, not
   just the components along the "line of expected correlations" that the 2016 article's
   method extracts (Leonhardt's point 5, not disputed on this specific point by
   Steinhauer's rebuttal, which defends the *choice* of line but does not supply the
   discarded components) — needed for anything resembling this project's **CE2/support**
   certificates, which require seeing the *whole* empirical table, not a pre-selected
   slice of it.

### 1.4 What can honestly be said without data

This project's tools cannot adjudicate which side's statistical reading holds up, and no
attempt is made here to guess. What direct reading of both full texts *does* support is a
narrower, procedural observation: the dispute is not about a disagreement over measured
values (neither side contests the other's pixel-read numbers) but over which uncertainty-
quantification convention to apply to them after the fact — exactly the class of
disagreement a pre-registered protocol (this project's actual house style) is designed to
make impossible, by fixing the convention before the data exists rather than relitigating
it once two papers already disagree about what "the data" show. That is a statement about
methodology, not a verdict on Hawking radiation, and it is offered as exactly that.

---

## 2. Is there a native Cauchy–Schwarz-route certificate in this project's own language?

**Short answer: no, and the reason is structural, not a translation this note failed to
find. Checked all three of this project's existing quantitative machineries — the
Abramsky–Brandenburger CF/α/ϑ LP, `SignedNegativity.wl`'s signed-decomposition ν, and
`signaling_taxonomy.py`'s Contextuality-by-Default cyclic criterion — and all three share
one prerequisite the Cauchy–Schwarz route does not have: a *finite* set of jointly
measurable-in-some-context discrete outcomes. Below is the literature (cited), the
precise mismatch, and what the route *does* connect to instead.**

### 2.1 The literature, read directly (not reconstructed from memory)

Fetched and read in full: de Nova, Sols, Zapata, "Violation of Cauchy-Schwarz
inequalities by spontaneous Hawking radiation in resonant boson structures," Phys. Rev. A
89, 043808 (2014); arXiv:1211.1761. The exact object (their Eqs. 1–12, notation
preserved):

- Second-order correlation function for two modes i ≠ j:
  g⁽²⁾_ij(τ) ≡ ⟨â_i†(0) â_j†(τ) â_j(τ) â_i(0)⟩ / (⟨â_i†â_i⟩⟨â_j†â_j⟩).
- Classical-light inequalities: 1 ≤ g⁽²⁾_ii(0); g⁽²⁾_ii(τ) ≤ g⁽²⁾_ii(0); and the
  Cauchy–Schwarz inequality proper, [g⁽²⁾_ij(τ)]² ≤ g⁽²⁾_ii(0) g⁽²⁾_jj(0) (their Eq. 4).
- Their own words on what licenses this bound, verbatim: **"the proof of (4) requires
  the system to be described by a positive (Glauber–Sudarshan) P function."** This is
  the load-bearing sentence for everything below — the CS bound is a statement that a
  *quasiprobability distribution over classical phase space* is everywhere non-negative;
  its violation is a certificate that no such non-negative P-function exists.
- Applied to outgoing Hawking-pair quasiparticle operators, with Γ_ij ≡
  ⟨γ_i-out† γ_j-out† γ_j-out γ_i-out⟩ (their Eq. 5) and θ_ij ≡ Γ_ij/√(Γ_ii Γ_jj), the
  violation criterion is θ_ij > 1 (Eq. 6); at T = 0 this reduces (their Eq. 12, using
  pseudo-unitarity of the scattering matrix S) to
  θ_ud2 = (|S_d2d2|² − 1/2)/(|S_d2d2|² − 1) > 1, **guaranteed whenever S_ud2 ≠ 0** — i.e.
  spontaneous Hawking emission of any nonzero amplitude *entails* CS violation by this
  route, exactly as already reported in `NOTES-hawking.md` §2.
- This is explicitly a proposal for a **resonant double-barrier structure** (a
  discrete-peak toy horizon), not what Steinhauer's 2016 smooth-gray-soliton experiment
  measured. But rereading Leonhardt's arXiv:1609.03803 in full turns up a refinement
  `NOTES-hawking.md` did not have: Leonhardt states the Busch–Parentani/Steinhauer
  nonseparability bound *itself*, |⟨b̂_H b̂_P⟩|² > n̄_H n̄_P, follows from "the
  Cauchy–Schwarz inequality for probabilities" (his words, immediately before Eq. 6 of
  his paper) — i.e. the criterion the **actual 2016 experiment used** is *also*,
  in Leonhardt's own framing, a Cauchy–Schwarz-type bound, just a first-moment
  (pairing-amplitude) one, not de Nova–Sols–Zapata's second-moment (intensity-ratio) one.
  The two "CS routes" in this literature are siblings, not identical: both are
  "classical-bound-vs-quantum-violating-bound" statements about the same second-order
  BEC correlation data, one built from ⟨b_H b_P⟩ vs n_Hn_P, the other from g⁽²⁾ ratios —
  but only the g⁽²⁾ form is literally de Nova–Sols–Zapata's inequality, and only the
  ⟨b_H b_P⟩ form is what Steinhauer's actual apparatus reports.

### 2.2 Why it does not translate into CF/α/ϑ (or ν, or CbD)

The Cabello–Severini–Winter / Abramsky–Brandenburger machinery this project's CF, α, and
ϑ all live in requires a **measurement scenario**: a finite set of contexts, each a finite
set of jointly-measurable outcomes, with an *exclusivity* relation between outcomes that
cannot both occur in some shared context. The classical bound is the independence number
α(G) of the resulting exclusivity graph, the quantum bound its Lovász number ϑ(G), the
general-probabilistic bound its fractional packing number α*(G). CHSH embeds into this
framework — this is exactly why `kcbs_circuit.wl` and `hawking_cf_bridge.py` could reuse
it — because CHSH's four correlators rewrite as a sum of probabilities of eight pairwise-
exclusive events, the circulant graph Ci(8;1,4) already in this repo.

The Cauchy–Schwarz bound is not that kind of object, on either of its two forms above:

- **It is a bound relating three *second moments*** (Γ_ii, Γ_jj, Γ_ij, or equivalently
  n̄_H, n̄_P, ⟨b_H b_P⟩), each already an *average over a continuum of Fock states* of a
  bosonic field on an infinite-dimensional Hilbert space — not a sum of probabilities of
  finitely many discrete, mutually exclusive outcomes. There is no "exclusivity" relation
  between "a click in mode H" and "a click in mode P" to begin with: these are not
  outcomes of *incompatible* measurements that cannot co-occur, they are the two halves
  of the very correlation being measured, and a single run typically registers *both*.
  Naively trying to build the smallest possible exclusivity graph on {H-click, P-click}
  gives the **null (edgeless) graph on two vertices**: with no exclusivity edge,
  α = ϑ = 2 for that graph (a standard fact about the Lovász number — ϑ of an edgeless
  graph on n vertices is exactly n; Knuth, "The Sandwich Theorem," Electron. J. Combin. 1
  (1994), A1), so the naive embedding produces no classical/quantum gap whatsoever: it is
  vacuous, not merely hard to compute. This is a small, honest demonstration of *why* the
  translation fails, not an assertion that it does.
- **The inequality is quadratic/geometric-mean-shaped** (Γ_ij ≤ √(Γ_ii Γ_jj)), not linear
  in a probability simplex, so even the generic "any two-outcome correlation Bell
  inequality embeds in some exclusivity graph" trick that gets CHSH into this repo's
  machinery does not apply mechanically here — there is no linear functional of a finite
  probability table that reproduces it.
- **It is qualitatively a different kind of bound than CHSH/CF.** Own derivation from
  Eq. 12 above: writing x ≡ |S_d2d2|² > 1, θ_ud2(x) = (x − 1/2)/(x − 1) is strictly
  decreasing on (1, ∞), diverging as x → 1⁺ and approaching **1 from above** as x → ∞.
  So θ_ud2 > 1 for *every* x > 1 — i.e. for every nonzero anomalous scattering amplitude,
  with no graded window analogous to CHSH's bounded [2, 2√2] separating "weakly quantum"
  from "maximally quantum." At T = 0 this route is structurally an on/off detector of
  whether spontaneous pair production happened *at all*, not a graded measure of *how
  quantum* the correlation is — unlike CF(S) = (S−2)/2, which is exactly graded on
  S ∈ [2, 4] (`hawking_cf_bridge.py`'s own finding). This point is independently
  corroborated by the practitioners themselves: the Sept. 2025 Isoard–Ciliberto–
  Milazzo–Pavloff–Giraud talk (§1.1) classifies the Cauchy–Schwarz and PPT criteria
  together as **"non-monotonous (qualitative: Yes/No)"**, explicitly contrasted with
  **"entanglement monotones (quantitative)"** — entanglement entropy/formation and
  (squared) logarithmic negativity / Gaussian contangle (Adesso & Illuminati, New J.
  Phys. 8, 15 (2006)) — in their own taxonomy of criteria for exactly this system. That a
  from-scratch algebraic derivation here and the field's own current working taxonomy
  land on the same qualitative/quantitative split is a reassuring cross-check, not a
  coincidence to lean on further.
- **The other two candidate homes in this repo fail for the identical underlying
  reason.** `SignedNegativity.wl`'s ν is an LP over a *finite* set of deterministic
  global assignments (same incidence-matrix machinery as CF, just a signed relaxation of
  it) — same finite-outcome prerequisite, same mismatch.
  `signaling_taxonomy.py`'s axis-2 Contextuality-by-Default criterion (Kujala–Dzhafarov)
  needs a finite cyclic system of binary measurements with well-defined per-context
  marginals — again a finite measurement scenario. And `kcbs_wigner_flow.wl`'s
  "negativity" is a **discrete, finite-dimensional (3×3-cell, qutrit) Wootters-type**
  Wigner function — a completely different mathematical object from the **continuous**
  Glauber–Sudarshan P-function on the infinite phase space of a bosonic mode that the
  Cauchy–Schwarz bound's positivity actually concerns. All four of this project's
  existing quantitative tools (CF/ϑ, α*, ν, CbD) share one prerequisite — a finite
  measurement scenario in the Abramsky–Brandenburger sense — that this continuous-
  variable, infinite-dimensional setting simply does not have. This is a complete
  negative finding, not just a CF-specific one.

### 2.3 What the route actually connects to (named, not built here)

The Cauchy–Schwarz/nonseparability family is native to a *different*, well-established
formalism: continuous-variable Gaussian quantum information. Its proper computational
apparatus is not an LP/SDP over an exclusivity graph but:

- The **positive-partial-transpose (PPT) criterion for CV systems**: Duan, Giedke,
  Cirac, Zoller, Phys. Rev. Lett. 84, 2722 (2000) (arXiv:quant-ph/9908056), and Simon,
  Phys. Rev. Lett. 84, 2726 (2000) — a positivity condition on symplectic eigenvalues of
  a covariance matrix, which is exactly the ν^PT_- object the Sept. 2025 talk computes
  from de Nova et al.'s 2019 data points (§1.1).
- The **Shchukin–Vogel moment-matrix hierarchy**: Shchukin, Vogel, Phys. Rev. A 72,
  043808 (2005) (arXiv:quant-ph/0506029) — nonclassicality certified by positive-
  semidefiniteness of matrices of field-operator moments, the genuine SDP-hierarchy
  analogue of this project's LP/SDP style, but built on a moment problem for continuous
  bosonic observables rather than a finite exclusivity hypergraph.
- The **entanglement monotones** the field itself now prefers for grading (not just
  detecting) Gaussian entanglement: logarithmic negativity and its multipartite Gaussian
  contangle (Adesso & Illuminati 2006, cited above), satisfying a monogamy inequality
  𝒢^(i|jk) ≥ 𝒢^(i|j) + 𝒢^(i|k) — the actual answer, in this literature, to "what plays
  the role of CF" is this contangle, not anything transplantable from this repo.

None of these three is built here. Doing so honestly would mean standing up a genuinely
new computational machinery (continuous-variable covariance-matrix SDPs), not reusing or
lightly adapting this project's existing incidence-matrix LPs — a legitimate, but
separate, future stream, not a "bridge" in the sense `hawking_cf_bridge.py` built for
CHSH. Flagged here as a real, named, sourced option rather than attempted.

---

## 3. Sketch of a finite-sample certificate stack for the Hawking-pair setting

A design note only, per the task's own allowance — no code, and nothing here is
executed, because the honest input data for it does not exist (§1). The goal is to make
the shape of the missing protocol precise enough that building it later is a matter of
following a plan, not starting from nothing — mirroring `mbqc_blackbox_test.py`'s
docstring-as-specification structure.

### 3.1 What plays the role of "clicks per context"

This is the first place the analogy strains, and saying so precisely matters more than
forcing an answer. In `mbqc_blackbox_test.py`, a *context* is a freely chosen pair of
compatible measurement settings, and a *click* is one single-photon event assigning a
definite outcome to that pair, repeated N times per context. A Hawking-pair experiment
has **no analogue of freely chosen settings** — there is no experimenter dial selecting
"context" per shot; what is fixed instead is a **pair of spatial or wavenumber bins**
(x_H, x_P) or (k_H, k_P) read out from every single realization of the condensate. This
is a structural disanalogy worth stating outright: Hawking-pair correlation measurements
are not a Bell-test "settings choice" experiment at all; they are an always-on
correlation between two fixed regions of one continuously-prepared field, repeated over
independent condensate preparations (N = 4,600 in the 2016 experiment). The right
operationalization of "clicks per context" here is therefore: **N = independent
experimental runs/shots**, and "outcome" = the per-shot, per-bin density fluctuation
δn(x) (or its Fourier/quasiparticle-basis transform), not a binary click. Turning that
continuous per-shot signal into something a Hoeffding-style bound can grip (as
`mbqc_blackbox_test.py` does for genuine binomial click counts) requires an explicit,
pre-registered discretization rule (e.g. a fixed threshold on the shot-noise-subtracted
signal) that does not yet exist in the published literature and would itself need
justification before any confidence interval built on it could be trusted — this is
flagged as open, not solved.

### 3.2 The classical/thermal-emulator null model

`mbqc_blackbox_test.py`'s three boxes are a Born-rule quantum sampler, a literal NCHV
hidden-variable sampler, and an intensity-fraction emulator that mimics the quantum table
without single-event semantics. The Hawking-pair analogue of the *third* box already has
a literal physical instantiation in the literature this project's first pass catalogued,
which is worth naming explicitly rather than inventing a toy: the **classical/stimulated
analogue experiments** of `NOTES-hawking.md` §1(A) — Weinfurtner et al., PRL 106, 021302
(2011) (arXiv:1008.1911) and Euvé et al., PRL 117, 121301 (2016) (arXiv:1511.08145) — are
driven by a classical noise source (turbulence, or a deliberately seeded/stimulated
signal) reproducing the *same* correlation-function shape without any spontaneous,
vacuum-origin pair production. That is a ready-made, literature-grounded "box (ii)/(iii)"
competitor: same marginal spectrum, classically-achievable (positive-P-representable)
joint statistics, by construction. The corresponding theory-side null model is a Gaussian
state with the same first-moment (population) spectrum n(ω) as the quantum prediction but
built to keep a non-negative Glauber–Sudarshan P-function throughout (no genuine two-mode
squeezing) — the natural CS-criterion analogue of the intensity emulator, differing from
the quantum target only in the joint (not marginal) statistics.

### 3.3 Proposed certificate order (design only)

Mirroring the V1–V5 discipline of `mbqc_blackbox_test.py` (no-disturbance always checked
before anything else, exact anchors before finite-sample computation):

- **C0 (population/no-disturbance).** Independently estimate n̄_H and n̄_P with a
  Hoeffding bound at a pre-registered N; require both to be reported and their agreement
  certified (not assumed) before anything downstream is evaluated. This is the direct
  transplant of `mbqc_blackbox_test.py`'s C1 and is precisely the check §1.3 identifies
  as the one thing both disputants agree was never done.
- **C1 (Cauchy–Schwarz/nonseparability bound, finite-sample).** From the same shot data,
  build a confidence interval — not a bare point estimate — on Δ̂ = n̄_H n̄_P −
  |⟨b_H b_P⟩|²_hat (Steinhauer's actual criterion) or θ̂_ij (de Nova–Sols–Zapata's, if the
  resonant-structure platform is the one under test). Certify nonseparability only if the
  **upper** confidence bound on Δ is negative (mirroring this project's CF_lo > 0 gate,
  V3 in `mbqc_blackbox_test.py`) — i.e. use the conservative end of the interval, never
  the point estimate, which is exactly where the published dispute (§1) broke down.
  Open technical question, flagged rather than solved: Δ̂ and θ̂ are built from *products*
  and *ratios* of separately-estimated moments, not a simple binomial fraction, so the
  clean Hoeffding bound `mbqc_blackbox_test.py` uses for click fractions does not
  transplant as-is; a delta-method or bootstrap propagation (already present as a
  secondary/non-gating tool in both `mbqc_blackbox_test.py` and `signaling_taxonomy.py`)
  would need to become the *primary* tool here, not a second opinion.
- **C2 (CHSH/CF cross-check, optional).** If a full (2,2,2,2)-style outcome table were
  ever reconstructed from a genuine pseudospin discretization (Ciliberto et al. 2024's
  route), report CF_lo via `hawking_cf_bridge.py`'s existing machinery as an independent
  second opinion. Explicitly aspirational: no such table has ever been built from real
  data, only from an idealized Gaussian state (as `NOTES-hawking.md` §4 already notes).

### 3.4 The sample-complexity question

`mbqc_blackbox_test.py` fixes N = 10⁴ clicks/context and 25 repetitions at a pre-
registered 95% gate-pass rate. The Hawking-pair analogue of this question is sharper than
it looks: given the reported 4,600 runs of the 2016 experiment, split across some number
of k-bins, what per-bin N does that actually amount to, and what confidence-interval
width on Δ or θ does *that* N support — decided **before** looking at the resulting
curve, not after two papers already disagree about it? Reframed this way, the entire
Leonhardt/Steinhauer dispute *is* a sample-complexity/confidence-interval-convention
question that was never pre-registered, which is exactly the failure mode this project's
Hoeffding/bootstrap discipline exists to prevent. This is offered as the single most
concrete, transplantable lesson from the dispute for any future real protocol here.

### 3.5 Why this stays a sketch

No synthetic "data" is generated to demonstrate this stack end-to-end. §1 found no real
data to validate a synthetic stand-in against, and simulating a fake Hawking-pair dataset
and running the above on it would produce numbers indistinguishable in form from a real
result — precisely what the task instructed against. `mbqc_blackbox_test.py`'s own three
boxes are legitimate because they are explicit, clearly-labelled theoretical constructs
being certified *as theoretical constructs*; the risk here is narrower and specific to
this application: a toy Hawking-pair Gaussian state dressed up in this project's
certificate-stack language could easily be mistaken for progress on the actual, real
dispute in §1, which it would not be. That risk is exactly why this section stops at a
design note.

---

## 4. Summary: literature-sourced vs. this note's own construction

**Literature facts (cited above, fetched and read in full this session unless marked
otherwise):** the non-existence of a public dataset or data-availability statement for
any Steinhauer analogue-Hawking paper (searched, not found); Leonhardt's pixel-digitization
methodology and Steinhauer's rebuttal never offering raw data (arXiv:1609.03803,
arXiv:1609.09017, both read in full); the unpublished partner-population measurement
(Leonhardt's footnote 33, uncontested by Steinhauer's Comment 50); the Sept. 2025 "no
indisputable result yet" assessment (Isoard–Ciliberto–Milazzo–Pavloff–Giraud conference
slides, read directly — flagged throughout as informal, not peer-reviewed); Isoard,
Pavloff, PRL 124, 060401 (2020) (arXiv:1909.02509), confirming a *published, peer-reviewed*
departure-from-thermality result independent of the Leonhardt dispute; the exact
Cauchy–Schwarz inequality and its P-function-positivity basis (de Nova, Sols, Zapata,
arXiv:1211.1761, read in full); Leonhardt's own framing of the Busch–Parentani criterion
as a Cauchy–Schwarz-for-probabilities statement; the PPT/log-negativity/Gaussian-contangle
apparatus and its "qualitative vs. quantitative" taxonomy (Duan et al. PRL 2000; Simon PRL
2000; Shchukin & Vogel, Phys. Rev. A 72, 043808 (2005); Adesso & Illuminati, New J. Phys. 8,
15 (2006); all named in, and cross-checked against, the Sept. 2025 talk).

**This note's own constructions (flagged as such, not literature claims):** the reading
of both disputants' silence on data-sharing as weak corroborating evidence (§1.1); the
diagnosis that the dispute is a confidence-interval-convention disagreement rather than a
disagreement over measured values (§1.4); the null-graph argument and the θ_ud2(x)
monotonicity derivation showing the CS route does not embed in this project's
exclusivity-graph machinery (§2.2) — corroborated by, but derived independently of, the
Sept. 2025 talk's own taxonomy; the identification of all three (not just CF) of this
project's existing finite-scenario tools as structurally inapplicable, for one shared
reason (§2.2); and the entire certificate-stack sketch of §3, offered as a design note,
not a result.

## 5. References beyond `NOTES-hawking.md` §8

15. V. I. Kolobov, K. Golubkov, J. R. M. de Nova, J. Steinhauer, Nature Phys. 17, 362
    (2021); arXiv:1910.09363 (stationarity follow-up; does not revisit the 2016
    entanglement-significance dispute).
16. R. Dardashti, S. Hartmann, K. P. Y. Thébault, E. Winsberg, "Hawking Radiation and
    Analogue Experiments: A Bayesian Analysis," arXiv:1604.05932 (philosophy-of-physics
    treatment of analogue-experiment confirmation; noted, not used quantitatively here).
17. M. Isoard, N. Pavloff, Phys. Rev. Lett. 124, 060401 (2020); arXiv:1909.02509
    ("Departing from Thermality of Analogue Hawking Radiation in a Bose-Einstein
    Condensate" — peer-reviewed, independent of the Leonhardt/Steinhauer dispute).
18. M. Isoard, G. Ciliberto, N. Milazzo, N. Pavloff, O. Giraud, "Entanglement in a BEC
    analogue black hole," IFPU Trieste workshop conference slides, Sept. 2025 (informal;
    cites their own Ciliberto, Emig, Pavloff, Isoard, Phys. Rev. A (2024) [= arXiv:
    2404.16497, already in `NOTES-hawking.md` §8] and Isoard, Milazzo, Pavloff, Giraud,
    Phys. Rev. A (2021), the latter not independently fetched this session).
19. L.-M. Duan, G. Giedke, J. I. Cirac, P. Zoller, Phys. Rev. Lett. 84, 2722 (2000);
    arXiv:quant-ph/9908056 (CV inseparability criterion).
20. R. Simon, Phys. Rev. Lett. 84, 2726 (2000) (Peres–Horodecki criterion for CV
    systems).
21. E. Shchukin, W. Vogel, Phys. Rev. A 72, 043808 (2005); arXiv:quant-ph/0506029
    (nonclassical-moments SDP hierarchy).
22. G. Adesso, F. Illuminati, New J. Phys. 8, 15 (2006) (Gaussian contangle, monogamy).
23. A. Serafini, G. Adesso, F. Illuminati, Phys. Rev. A (2005) (symplectic-eigenvalue
    PPT criterion for multimode Gaussian states, as adapted in Ref. 18; not
    independently re-fetched this session, cited as named in Ref. 18).
24. D. Knuth, "The Sandwich Theorem," Electron. J. Combin. 1 (1994), A1 (standard
    Lovász-number facts used in §2.2: ϑ(edgeless graph on n vertices) = n).
25. This repo: `SignedNegativity.wl`, `kcbs_wigner_flow.wl` (master; checked as candidate
    homes for the CS route in §2.2, both ruled out for the reasons given there).

## 6. Doc-merge notes (do not edit `QUANTUM_CONTEXTUALITY.md`/`README.md` from this branch)

- If merged, add to `QUANTUM_CONTEXTUALITY.md` §6/§9: the Leonhardt/Steinhauer dispute
  remains unengageable directly (no public data, confirmed by a dedicated search, not
  merely assumed); the Cauchy–Schwarz route native to the actual BEC experiments does not
  embed in this project's CF/ϑ/ν/CbD machinery, for a structural reason common to all
  four tools (finite measurement scenario required, continuous-variable Gaussian
  correlators supplied); a certificate-stack design (not yet executable) exists for a
  future real dataset.
- This note's own open items, in addition to `NOTES-hawking.md` §6's: (a) the
  discretization rule for "clicks per context" in §3.1 is unsolved and would need its own
  justification before any Hoeffding bound built on it could be trusted; (b) the
  delta-method/bootstrap propagation for Δ̂/θ̂ confidence intervals in §3.3 is sketched,
  not derived; (c) a genuine CV-Gaussian moment-SDP or PPT-criterion certificate stack
  (§2.3) is a real, separate future stream, not attempted here.
