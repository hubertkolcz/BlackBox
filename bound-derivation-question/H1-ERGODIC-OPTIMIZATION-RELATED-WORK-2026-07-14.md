# H1 — Related Work: Is `(ddt)^∞` Precedented, and What Is the Simplest Formalization?

Literature pass of 2026-07-14. Companion to `docs/FRAMEWORK-2026-07-13.md` (H1's
statement, §"Layer 1 — named hypotheses"), `ESSAY-005-BRIDGE-formalC-tropical-limit.md`
(the Bousch–Mairesse risk, §6), and `docs/RELATED-WORK.md` (whose axis-citation style
this file follows). Triggered by a direct question: does the direct/twisted-necklace
*representation*, or the "which infinite word maximizes an ergodic average" *question*,
have precedent under a different name, in a different field? **MUST-CITE** = this
project could not honestly omit it if H1 is written up. **[new]** = not previously in
the ledger/docs as of the 2026-07-13 wave. **[proj]** = already known in-project;
re-dated/re-verified here. **[unverified]** = surfaced only via a search snippet or a
paywalled abstract, not fetched in full — check before citing in the essay.

## 0. Bottom line

Two separate questions were asked; they have two separate answers.

**(a) Does the direct/twisted binary-necklace *representation* of edge-glued polygon chains
have precedent?** Yes, extensively — chemical graph theory, §2 below. But every
extremal result in that ~45-year literature is for a *counting* index (Merrifield–Simmons
σ, Hosoya Z, Wiener, Schultz, Gutman, Kirchhoff), and every extremal chain ever found
there is period ≤ 2 (the pure chain, or the alternating/zigzag chain — occasionally, in
restricted "fully-angular" subclasses, the pure helicene). Nobody has run an
independence-number / Lovász-θ *growth-rate* optimization over that word space. The
quoted verdict — "not a citation to hunt down, a claim to cite this repository for" —
holds up under this fresh pass; if anything it is now better-cited than before.

**(b) Does "which infinite word maximizes an ergodic average of a potential" have
precedent under a different name?** Yes, precisely — this is the field of **ergodic
optimization**, and its matrix-cocycle special case is the **joint-spectral-radius (JSR)
/ spectrum-maximizing-product** literature, §1. This is not a new discovery — Bousch–Mairesse
and Ahmadi–Jungers–Parrilo–Roozbehani are already in the project's citations — but this
pass surfaces materially new, actionable results: a 2026 theorem set covering the *exact*
ambient space `{d,t}^ℕ`; an explicit *period-5* mixed-word precedent in the JSR literature
structurally analogous to `ddt`; a devil's-staircase theorem explaining *why* a low-period,
rational-slope word is the expected outcome rather than a fragile coincidence; and a
concrete alternative numerical route (with public code) to the sub-action certificate the
project is already building by hand.

**Net effect on H1's confidence rating.** Nothing found closes H1. Nothing found weakens
it either. The devil's-staircase and prevalence results below give "very high confidence"
(`FRAMEWORK-2026-07-13.md`) firmer structural footing than the 2026-07-12/13 numerics
alone provided — but they are structural analogies for a *different* potential family, not
a proof for *this* potential. The proof target stated in-project (a certificate whose
limit is `gap(ddt)`, or a selection theorem using the α-direct structure specifically) stands
unchanged.

## 1. Ergodic optimization / joint spectral radius — the "different field, same question"

### 1a. Already known in-project, re-dated

- **[proj]** Bousch, T., Mairesse, J., *Asymptotic height optimization for topical IFS,
  Tetris heaps, and the finiteness conjecture*, J. Amer. Math. Soc. **15** (2002), 77–111.
  Confirmed: proves densest two-piece Tetris heaps are Sturmian, and constructs the first
  explicit counterexample to the Lagarias–Wang finiteness conjecture.
- **[proj]** Jenkinson, O., *Ergodic optimization in dynamical systems*, Ergodic Theory
  Dynam. Systems (2019 survey), arXiv:1712.02307.
- **[proj]** Contreras, G., *Ground states are generically a periodic orbit*, Invent.
  Math. **205**, 383–412 (2016), arXiv:1307.0559. Precise scope now confirmed: maximizing
  measures of a **Baire-generic Lipschitz** potential are supported on a single periodic
  orbit; stated directly for the symbolic full shift `{1,…,d}^ℕ` (Lopes 2026, Thm 2, §1b)
  — i.e. it literally covers the `d=2` case `{d,t}^ℕ`, but only says this holds for
  *almost every* potential in a topological sense, silent on any specific one.
- **[proj]** Ahmadi, A.A., Jungers, R., Parrilo, P., Roozbehani, M., *Analysis of the
  joint spectral radius via Lyapunov functions on path-complete graphs*, HSCC 2011
  (extended: SIAM J. Control Optim. 2014). The `Γ_k` hierarchy is this genus of object —
  confirmed, no known general convergence-rate theorem, consistent with the project's own
  2026-07-12 push finding.
- **[proj]** Guglielmi, N., Protasov, V. — invariant-polytope algorithm, several 2013–2016
  papers; improved version: *Improved invariant polytope algorithm and applications*, ACM
  TOMS **46**(3) (2020), arXiv:1812.03080.
- **[proj]** Li, Z., Sun, Y., *Tropical thermodynamic formalism*, arXiv:2408.10169.
  Confirmed real; studies the tropical adjoint Bousch operator, Aubry set and Mañé
  potential for the zero-temperature large-deviation rate function.
- **[proj]** Baraviera, A., Leplaideur, R., Lopes, A.O., *Ergodic Optimization, Zero
  Temperature Limits and the Max-Plus Algebra*, 29º Colóquio Brasileiro de Matemática,
  IMPA (2013).

### 1b. New: theorems on the *exact* ambient space `{d,t}^ℕ`

- **MUST-CITE [new]** Ding, J., Li, Z., Zhang, Y., *On the prevalence of the periodicity
  of maximizing measures*, Adv. Math. **438**, 109485 (2024), arXiv:2303.00536. Proves
  that for the **one-sided full shift on two symbols** — literally `{d,t}^ℕ` — periodicity
  of the maximizing measure is **prevalent** (Hunt–Sauer–Yorke measure-theoretic
  genericity, strictly stronger than topological genericity) among Lipschitz functions
  w.r.t. metrics with mildly-fast-decaying cylinder diameters. This is the sharpest
  "almost every potential ⇒ periodic maximizer" statement on record for this exact space.
  **Action item, not yet done:** check whether `gap(w) = θ̄(w) − ᾱ(w)`, in the natural
  product-cylinder metric, satisfies their decay-rate hypothesis — the certificate's own
  boundary-correction estimates (§9 of `QUANTUM_CONTEXTUALITY.md`) may already supply the
  needed Lipschitz bound. This does not prove H1 (prevalence is silent on any one specific
  potential) but it upgrades the "default expectation" a full step beyond Contreras.
- **[new]** Huang, W., Jenkinson, O., Xu, L., Zhang, Y., *Typical periodic optimization
  for dynamical systems: symbolic dynamics*, arXiv:2603.07224 (2026); accepted, Invent.
  Math., DOI 10.1007/s00222-026-01411-x. Extends "typical periodic optimization" (TPO)
  past subshifts of finite type to sofic, eventually-sofic, and "eventually fragile"
  shifts. The plain full shift `{d,t}^ℕ` is the trivial SFT case (empty Markov boundary)
  and is already covered by Contreras/Bousch — this paper adds no *new* leverage there,
  but its **Completely Maximizing Criterion** (a minimax set with `sup_n sup_{x} S_nf(x) <
  ∞` is automatically completely maximizing and dynamically minimal, via a
  bounded-Birkhoff-sum test) and its **subset closing property** (near-returns shadowed by
  an actual periodic orbit within a uniform bound, substituting for Anosov's closing lemma)
  are a certificate technique genuinely independent of Bousch sub-actions — a second,
  different route worth trying on H1's corridor (§6).
- **[new]** Lopes, A.O., *Ergodic Optimization and Ground States: a brief Introduction*,
  arXiv:2605.13342 (2026; dedicated to Contreras's memory). Clean modern exposition set
  directly on `Ω = {1,…,d}^ℕ`. Contains the exact certificate machinery the project's
  windowed transfer-SDP sub-action *is* an instance of, made fully explicit — see §4.

### 1c. New: explicit low-period mixed-word precedent (the closest structural analogue to `ddt`)

- **MUST-CITE [new]** Morris, I.D., Sidorov, N., *On a devil's staircase associated to the
  joint spectral radii of a family of pairs of matrices*, J. Eur. Math. Soc. **15**(5),
  1747–1782 (2013), arXiv:1107.3506. For a one-parameter family of 2×2 matrix pairs, the
  growth-rate-maximizing sequence is Sturmian with a characteristic ratio that is a
  **devil's staircase** function of the parameter: it attains **every rational value on a
  whole interval** (a mode-locked plateau — the sequence is then genuinely periodic) and
  attains irrational values only on a parameter set of **Hausdorff dimension zero**. This
  is the single most useful structural fact found in this pass: it is the textbook
  explanation for why a low-period, rational-"slope" word (`ddt` has letter-frequency
  `f_c = 2/3`, exactly a rational slope) being the true, isolated, robust maximizer is the
  *expected*, typical behaviour of this genus of problem — not a coincidence requiring
  special pleading — even though it is a different potential family and proves nothing
  about `gap(w)` directly.
- **[new]** — (unsigned/anon. authorship not resolved in this pass) *Spectrum Maximizing
  Products Are Not Generically Unique*, SIAM J. Matrix Anal. Appl. (2023),
  arXiv:2301.12574. Exhibits a nonempty open set of 2×2 matrix pairs `(A,B)` for which the
  length-5 mixed products `A²BAB²` and `B²ABA²` are *both* spectrum-maximizing
  simultaneously (a "Horowitz pair"). This is the most concrete available precedent for "a
  short, specific, non-monotone periodic word is the robust maximizer over an open
  parameter regime" — structurally the closest thing to `ddt` that this pass turned up
  outside the project's own computation.
- **[unverified, worth Hubert's own follow-up]** *Partial classification of spectrum
  maximizing products for pairs of 2×2 matrices*, ScienceDirect (2025) — a recent
  classification effort for exactly this question; abstract-only in this pass
  (paywalled), full text not fetched.
- **[new]** Jenkinson, O., Pollicott, M., *Joint spectral radius, Sturmian measures, and
  the finiteness conjecture*, Ergodic Theory Dynam. Systems **38**(8), 3062–3100 (2018),
  arXiv:1501.03419. Exhibits an **open set** of 2×2 matrix pairs generating uncountably
  many finiteness-conjecture counterexamples via Sturmian invariant measures — i.e. the
  Bousch–Mairesse failure mode is not an isolated pathology but occurs on open sets. Read
  together with 1c's Morris–Sidorov staircase, the picture is: open sets of *aperiodic*
  failure coexist with, and are separated by codimension from, mode-locked plateaus of
  *periodic* (rational-slope) success — exactly the dichotomy `FRAMEWORK-2026-07-13.md`
  already frames H1's "thin corridor" around.
- **[new, physics-side motivation]** Hunt, B.R., Ott, E., *Optimal periodic orbits of
  chaotic systems occur at low period*, Phys. Rev. E **54**, 328–337 (1996) (companion:
  Phys. Rev. Lett. **76**, 2254–2257 (1996)). Independent, older, physics-side statement of
  the same "generic maximizer has low period" intuition — good color, not a proof tool.

### 1d. New: certificate/algorithm machinery — a second route to close the corridor

- **MUST-CITE [new]** The exact certificate the project wants, made fully explicit in
  Lopes 2026 (§1b) as **Theorem 4**: if `μ` is `A`-maximizing and `u` is *any* subaction
  (`u∘σ ≥ u + A − α(A)`), then the defect `R(x) = u(σx) − u(x) − A(x) + α(A) ≥ 0`
  vanishes exactly on `supp(μ)`; conversely, if `R = 0` on the support of some invariant
  `μ`, then `μ` is maximizing. This is a two-sided necessity-and-sufficiency test —
  exhibit one subaction with `R = 0` on `orbit((ddt)^∞)` and `R > 0` strictly everywhere
  else, and H1 is proved. It is the same Mañé–Conze–Guivarc'h/Bousch machinery the
  project's windowed transfer-SDP `ψ` already instantiates (`σ(e) ≤ Γ_k` *is* a sub-action
  inequality), now with the exact textbook necessity+sufficiency statement and its
  "contact locus" (`𝕄_A(u) = {R=0}`) vocabulary attached — worth adopting so the
  project's own certificate can be stated as "does `𝕄` equal `orbit(ddt)` exactly," a
  sharper target than the current ε-bracket framing.
- **[new, actionable]** Ferreira, H.H., Lopes, A.O., Oliveira, E.R., *An iterative
  process for approximating subactions* (2021) and *Explicit examples in Ergodic
  Optimization*, São Paulo J. Math. Sci. **14**, 443–489 (2020). The **"1/2-iteration
  method"** — a numerical procedure, purpose-built for symbolic dynamics (not
  matrix/JSR-native like Guglielmi–Protasov), that *guesses* a calibrated subaction from a
  potential, checkable by hand afterward. **Public code:**
  `github.com/hermes-hf/Explicit_examples_ergodic`. This is a concrete alternative to the
  Guglielmi–Protasov zero-slack recalibration the project's 2026-07-12 push flagged as
  "the concrete next step" — worth running in parallel, since it is native to exactly this
  problem's setting (symbolic full shift, not a matrix pair) and comes with runnable code
  rather than requiring a from-scratch reimplementation.
- **[new]** Garibaldi, E., Lopes, A.O., Thieullen, P., *On calibrated and separating
  sub-actions*, Bull. Braz. Math. Soc. **40**, 577–602 (2009) — the general
  existence/genericity source for the sub-action apparatus above.
- **[new]** Garibaldi, E., Lopes, A.O., *On Aubry–Mather theory for symbolic dynamics*,
  Ergodic Theory Dynam. Systems **28**, 791–815 (2008) — ties the Aubry–Mather / Mañé
  potential machinery specifically to symbolic (not manifold) dynamics, i.e. exactly this
  project's setting.
- **[new]** Morris, I., *Prevalent uniqueness in ergodic optimisation*, Proc. Amer. Math.
  Soc. **149**(4), 1631–1639 (2021), arXiv:2003.08762 — companion prevalence result to
  Ding–Li–Zhang (§1b), for uniqueness rather than periodicity.

## 2. Chemical graph theory — confirming and dating the representation precedent

- **MUST-CITE [new]** Gutman, I., *Extremal hexagonal chains*, J. Math. Chem. (foundational
  paper introducing the binary orientation-word encoding: at each internal vertex a
  hexagonal chain is either "linear" (L) or "angular/kink" (A), and consecutive kinks are
  same-direction (helicene-forming) or alternating (zigzag-forming) — the direct ancestor
  of this project's direct/twisted letter). Gutman & Zhang subsequently determined: **the
  linear chain (pure "L" word) uniquely maximizes the Hosoya index and minimizes the
  Merrifield–Simmons index** among all hexagonal chains of given length; in restricted
  "fully-angular" subclasses the **zig-zag chain** (alternating, period 2) and **helicene**
  (pure kink, period 1) take over as the extremal pair. Every extremal word found in this
  line of work is period ≤ 2.
- **[new]** Cruz, R., Marín, C., Rada, J., *Hosoya index of catacondensed hexagonal
  systems* (~2017) — transfer-matrix method for the same word space; confirms the
  linear-chain extremum by an independent computational route.
- **[new]** Wagner, S., survey *Maxima and minima of the Hosoya index and the
  Merrifield-Simmons index* (math.sun.ac.za/swagner/survey.pdf) — general confirmation
  that this "extremal chain" paradigm (find the period-1 or period-2 word that
  maximizes/minimizes a fixed counting index) is the standing paradigm across the field,
  not an artifact of the hexagonal case specifically.
- **[new]** Ma, Q. et al., *Extremal polygonal chains with respect to the Kirchhoff
  index*, arXiv:2210.10316 — generalizes the extremal-chain question to **general k-gon**
  chains (not just hexagons), still finds only "even/odd" (period ≤ 2) extremal types —
  the closest existing generalization to the pentagon (k=5) case for a *different*
  invariant (resistance-distance-based, not counting-based).
- **[new]** *The study of pentagonal chain with respect to schultz index, modified
  schultz index, schultz polynomial and modified schultz polynomial*, PLOS ONE (2024),
  doi:10.1371/journal.pone.0304695 — read in full this pass. **Important negative
  finding:** this paper, specifically about *pentagonal* chains and the Schultz index
  (the closest-sounding title match to the project's own object), does **not** use a
  direct/twisted word-family formalism at all — it fixes a single canonical chain shape `P_n`
  (attributed to He et al.) and computes closed-form Wiener/Gutman/Schultz/modified-Schultz
  values for that one shape. The pentagon-specific sub-literature is *narrower* than the
  hexagonal one: it has not yet even posed the "which gluing word" question that Gutman
  answered for hexagons in the 1970s–80s, let alone asked it for a growth-rate invariant.
  This sharpens (rather than merely repeats) the quoted claim: for pentagons specifically,
  not even the counting-index extremal-word question has been asked in the literature
  found here.
- **[proj]** Sedlar, J., *Independent sets in chain cacti*, arXiv:1105.1940 (2011) —
  vertex-glued (cactus/spiro), not edge-glued; gives the *uniform* answer `α = 2m`,
  independent of gluing word, because vertex-glued pentagon chains have no direct/twisted
  choice to make in the first place. Confirms edge-gluing is what creates the
  combinatorial word space this project (and the hexagonal-chain literature) works in.

## 3. Adversarial checks — searched for, not found

Good-faith attempts to falsify the novelty claim, per the project's own verification
discipline:

- **Quantum contextuality × ergodic optimization / JSR.** Searched directly for any paper
  connecting Lovász-θ / Kochen–Specker / contextuality graph invariants to ergodic
  optimization, joint spectral radius, or matrix-cocycle growth rates. Nothing found. The
  contextuality-graph-theory literature (Cabello–Severini–Winter and descendants) and the
  ergodic-optimization/JSR literature (Bousch, Jenkinson, Morris, Contreras, Guglielmi–Protasov)
  do not currently reference each other.
- **Tensor-network contraction ordering.** Checked as a candidate "different name, same
  question" field, since it also asks "which sequence controls asymptotic growth of a
  chain built by gluing local objects." Ruled out: that literature optimizes the
  contraction *order* of a **fixed, finite** network to minimize *transient* cost (an
  NP-complete combinatorial search over a finite object), not the *infinite-word* limit of
  an *unboundedly extensible* chain's growth rate. Different question; no useful overlap
  found.
- **Switched-linear-systems / worst-case-gain control theory.** Checked as the control-theory
  cousin of the JSR question (worst-case switching sequence maximizing induced gain). Confirms
  the JSR/path-complete-Lyapunov connection already in-project but surfaced no result beyond
  what §1a/1d already cover.

## 4. The simplest mathematical definition

Stripped of the pentagon/SDP specifics, H1 is an instance of the following completely
standard object, called **ergodic optimization**:

> Let `(Σ, σ)` be a one- or two-sided shift space over a finite alphabet `A` (here
> `A = {d,t}`, `Σ = A^ℕ` or `A^ℤ`, the *full* shift — every gluing sequence is
> realizable, no forbidden words). Let `M_σ(Σ)` be the set of `σ`-invariant Borel
> probability measures on `Σ` — nonempty, convex, and weak-\* compact. Let `φ : Σ → ℝ` be
> a continuous potential. For `μ ∈ M_σ(Σ)`, Birkhoff's ergodic theorem gives, for
> `μ`-a.e. `x`, the **ergodic average**
> `lim_{n→∞} (1/n) Σ_{k=0}^{n-1} φ(σ^k x) = ∫ φ dμ` whenever `μ` is ergodic. Define
> `β(φ) := sup_{μ ∈ M_σ(Σ)} ∫ φ dμ`. Because the objective is affine and `M_σ(Σ)` is
> compact and convex, the supremum is attained, and — by the Krein–Milman / ergodic
> decomposition theorem — attained at an **extreme point**, i.e. at an **ergodic**
> measure. A measure attaining `β(φ)` is called `φ`-**maximizing**; an orbit whose time
> average equals `β(φ)` is `φ`-**maximizing**.

The single sentence answer to "which infinite word maximizes an ergodic average of a
potential function" is therefore: **the one whose orbit measure is an extreme point of
`M_σ(Σ)` attaining `sup_μ ∫φdμ`** — and the entire content of the field of ergodic
optimization is the study of *which* extreme point that is, as a function of `φ`. The two
cleanest special cases:

- If `μ` is supported on a single **periodic orbit** of period `p`, `∫φdμ` is just the
  finite arithmetic mean `(1/p) Σ_{k=0}^{p-1} φ(σ^k x)` — a computable number for each
  candidate word. This is why periodic words are always the first thing tried, and why
  (per §1a/1c) they are provably the *typical* answer.
- If no periodic orbit is maximizing, the maximizing measure can be **uniquely ergodic
  but aperiodic** — the paradigm case being a **Sturmian measure** (the orbit closure of
  an irrational rotation's coding), which is exactly the failure mode Bousch–Mairesse
  proved can occur (§1a) and which Morris–Sidorov showed occupies a Hausdorff-dimension-zero
  parameter set, mode-locked out almost everywhere by rational-slope periodic plateaus
  (§1c).

**H1's specialization.** `Σ = {d,t}^ℤ` (or `ℕ`), and the potential is not a simple
cylinder function but is built two levels deep: `φ(w) "=" θ̄(w) − ᾱ(w)`, where
`ᾱ(w) = lim_n (1/n) · [max-plus/tropical growth rate of the length-n transfer-matrix
product selected by `w`]` — literally a **joint-spectral-radius-type quantity in the
`(max,+)` semiring**, i.e. `ᾱ` genuinely *is* a matrix cocycle (§1's JSR literature
applies to it directly) — while `θ̄(w) = lim_n (1/n) · [value of a growing, `w`-indexed
semidefinite program]` is a Fekete limit of a subadditive sequence (proven to exist in
`twisted_chain_proofs.py`), a strictly more exotic "SDP-density" cocycle without a known
finite-dimensional linear representation. `gap(w) = θ̄(w) − ᾱ(w)` is therefore a
*difference of two already-optimized growth rates*, each of which is itself an instance of
the abstract problem above, composed once more. This double-optimization structure is the
project's own genuinely novel object; the abstract machinery in §1 (sub-actions, contact
loci, prevalence, path-completeness) applies to it as soon as `φ = θ̄ − ᾱ` is shown
continuous — which subadditivity (for `θ̄`) and exact tropical linear algebra (for `ᾱ`)
already give.

## 5. What this pass adds that the project did not already have

1. A prevalence-class (not merely topological-genericity) theorem, Ding–Li–Zhang, stated
   on the *exact* ambient space `{d,t}^ℕ` — an unchecked but plausibly-satisfiable
   hypothesis test against the certificate's own known Lipschitz estimates (§1b).
2. A textbook two-sided necessity+sufficiency certificate (Lopes 2026, Theorem 4) with a
   named target object (`𝕄_A(u)`, the contact locus) sharper than the current ε-bracket
   framing (§1d).
3. A second, sub-action-independent certificate technique — Huang–Jenkinson–Xu–Zhang's
   Completely Maximizing Criterion / subset closing property — as a cross-check route
   (§1b).
4. A purpose-built, symbolic-dynamics-native numerical subaction solver with public code
   (Ferreira–Lopes–Oliveira's "1/2-iteration method") as an alternative to reimplementing
   Guglielmi–Protasov from the matrix/JSR side (§1d).
5. A structural explanation (Morris–Sidorov's devil's staircase) for why a short,
   rational-slope, mixed periodic word being the robust global optimum is the *expected*
   outcome of this genus of problem, plus a directly analogous explicit example (the
   period-5 Horowitz pair, arXiv:2301.12574) of exactly that phenomenon happening in the
   JSR literature (§1c).
6. Dated, citable confirmation — not mere assertion — that the chemical-graph-theory
   precedent claim is accurate, sharpened by the finding that the pentagon-specific
   sub-literature is narrower than the hexagon literature the project had been implicitly
   generalizing from (§2).
7. Two adversarial checks that turned up nothing, recorded as such (§3), consistent with
   project practice of recording negative results as first-class.

None of the above closes H1. All of it is either directly actionable (items 1–4) or
raises the evidentiary floor under "very high confidence" (items 5–6) without changing
what would constitute an actual proof.

## References — quick index (full detail in §1–3 above)

Bousch–Mairesse JAMS 2002 · Jenkinson arXiv:1712.02307 · Contreras Invent. Math. 2016
(arXiv:1307.0559) · Ahmadi–Jungers–Parrilo–Roozbehani HSCC 2011 / SICON 2014 ·
Guglielmi–Protasov arXiv:1812.03080 · Li–Sun arXiv:2408.10169 · Baraviera–Leplaideur–Lopes
IMPA 2013 · **Ding–Li–Zhang Adv. Math. 438 (2024), arXiv:2303.00536** ·
**Huang–Jenkinson–Xu–Zhang arXiv:2603.07224 (2026)** · **Lopes arXiv:2605.13342 (2026)** ·
**Morris–Sidorov JEMS 15 (2013), arXiv:1107.3506** · SMP-non-uniqueness SIAM J. Matrix
Anal. Appl. 2023, arXiv:2301.12574 · Jenkinson–Pollicott ETDS 38 (2018), arXiv:1501.03419 ·
Hunt–Ott PRE 54 (1996) · Ferreira–Lopes–Oliveira São Paulo J. Math. Sci. 14 (2020) + code
`github.com/hermes-hf/Explicit_examples_ergodic` · Garibaldi–Lopes–Thieullen Bull. Braz.
Math. Soc. 40 (2009) · Garibaldi–Lopes ETDS 28 (2008) · Morris Proc. AMS 149 (2021),
arXiv:2003.08762 · Gutman *Extremal hexagonal chains* · Cruz–Marín–Rada (~2017) · Wagner
survey (math.sun.ac.za) · Ma et al. arXiv:2210.10316 · PLOS ONE 10.1371/journal.pone.0304695
(2024) · Sedlar arXiv:1105.1940 (2011) [proj].
