# Proposal — three focused computational essays

The comprehensive `TheBlackBoxFramework.nb` stays as the umbrella research essay.
This proposes **three focused, submittable computational essays** carved from it,
each a single coherent question with a tight narrative — the shape Wolfram
Community's "computational essay" ideal favors. Each is self-contained and
reproducible via the same standalone loader (fetches paclet + committed results
from the public repo; `$BlackBoxRef` pins a commit), and each closes on its own
`<Name>Verification` with `OK -> True`.

Nothing here is built yet — this is the plan. Say which to build (any/all, one at
a time) and I assemble it as its own `.wl` + generated `.nb`, drawing on the
existing verified section builders so every number stays live-computed.

---

## Essay 1 — "The Two Irreducible Lenses: certifying quantum contextuality from black-box statistics"

**Question.** Given only input–output access, when is a genuinely quantum KCBS
device mathematically indistinguishable from a classical optical emulator — and
what does it take to tell them apart?

**Thesis.** Certification is *irreducibly two-lens* (a correlation lens + a
geometric/dynamical-Lie-algebra lens), neither derivable from the other; on the
pentagon this is exact, has exactly one structural blind spot, and is closed
*class-relatively* by a completeness theorem.

**Outline (live computation in brackets).**
1. The pentagon atom — classical 2 < quantum √5 < exclusivity 5/2 `[atomHierarchy]`
2. The certification protocol and its one exact blind spot — the tuned intensity
   emulator (case iii-d, `CF ≈ 0.4803`, all certificates clean) `[blindSpotDelta]`
3. The geometric lens — DLA / leaf-confinement: genuine so(3) dim 3 vs emulator < 3 `[g7*]`
4. Two-lens necessity — Prop 1/2 (BBT-002/003): no table functional lower-bounds the DLA
5. Class-relative completeness — Prop O3-C (F10) over the intensity-emulator class 𝒜_IE
6. The adversary ceiling H4′ — the G9 antibunching gate (g²(0) ≥ 1) + η\* = 2/√5
7. *(coda)* the constructive mirror — the optical-synthesis compiler emits self-certifying blueprints

**Draws on:** `essay_sections_1_3.wl` (S1–S3) + `essay_sections_7_10.wl` (Prop O3-C, EMU) + the H4′ `.py` gates.
**Novelty anchor:** two-lens necessity + the class-relative resolution of the central O3 question.
**Audience:** quantum foundations / QI. **Size:** ~45–55 cells, ~35 live numbers. **This is the flagship** — the tightest, most citable of the three.

---

## Essay 2 — "The Optimal Pentagon Word: exact composition laws and a certificate ladder"

**Question.** How does contextuality compose when you edge-glue pentagons, and is
there a *best* way to glue them?

**Thesis.** A pentagon mesh is a binary (cis/trans) necklace with exact composition
laws; a believed-optimal word **cct** carries an irrational gap density 0.0698975…;
and a windowed transfer-SDP ladder Γ_k brackets it from above — an ergodic-
optimization problem whose optimizer is a sharp, isolated peak.

**Outline.**
1. Meshes as necklaces — cis vs trans are non-isomorphic; orientation, not size, controls the gap `[gluingArbitration]`
2. Exact laws — cis θ = N+θ(C_N), α = ⌊3N/2⌋; τ\* = Root[49x³−128x²−75x+218,2] = 1.37671775 `[tauStar]`
3. The α-cis theorem — ᾱ(w) ≥ max(4/3, 1+f_c/2), equality **iff** (cct)^k `[cisLawTable]`
4. The certificate ladder — exact Γ₇, Γ₈, Γ₉ (and Γ₁₀) descending toward gap(cct) `[gammaExact]`
5. The orbit-spectrum reading — spurious policy values are periodic-orbit densities − 1 `[orbitSeeds]`
6. H1 — the cct-optimality hypothesis and why it's hard (finiteness fails; Bousch–Mairesse)
7. *(optional)* the degree-0 sheaf derivation (F6) — an integer-vs-fractional partition of unity `[lam*]`

**Draws on:** `essay_sections_4_6.wl` (S4, S5) + `EpsilonCertificate{7,8,9}*.wl` + `orbit_spectrum.png` + H1.
**Novelty anchor:** the exact Lovász-θ density theory of edge-glued C₅ meshes + τ\* + the α-cis equality-iff-cct theorem.
**Audience:** combinatorial / ergodic optimization, SDP. **Size:** ~50–60 cells, ~40 live numbers. **The deepest mathematics.**

---

## Essay 3 — "Emulating a Black Hole: where the contextuality lens reaches, and where it structurally can't"

**Question.** Can analogue-Hawking-radiation dynamics be classically emulated — and
can the framework's lenses even *see* them?

**Thesis.** The information-dynamics sector (Page curve, Hayden–Preskill, CHSH) is
Clifford-reproducible on the pentagon mesh, and the Gaussian/Bogoliubov *thermal*
sector — Hawking's own 1974–75 mathematics — is exactly emulable as symplectic
linear algebra; **but** the single-context Cauchy–Schwarz witness used in real
experiments provably cannot be phrased in the graph-invariant language (CF = 0
identically). A structural negative, not a failed search.

**Outline.**
1. Why CHSH, not KCBS (HK-001) — Hawking pairs are bipartite `[chshLimit]`
2. The bridge — published S = 2.25 → CF = 0.125 (HK-002)
3. The structural obstruction — single context ⇒ CF = 0 for every alphabet K (HK-003) `[qubitCF]` — the headline
4. The qubit information-dynamics module (HK-006) — Page curve, Hayden–Preskill, CHSH, confirmed vs four papers
5. The Gaussian sector (HK-007) — Bogoliubov A1–A8: Planck spectrum, entanglement = thermality, CHSH → 2√2 `[rEff225]`
6. The two-tier emulability verdict

**Draws on:** `essay_sections_4_6.wl` (S6) + `hawking-application/*` (Gaussian) + `cluster-state-realization/*` (qubit).
**Novelty anchor:** the CF = 0 structural obstruction (a headline contribution of the umbrella essay).
**Audience:** analogue gravity / quantum simulation / foundations. **Size:** ~40 cells, ~25 live numbers. **The cleanest self-contained application.**

---

## What stays only in the umbrella notebook

- The full **conditional-theory architecture** (Layer 0 F1–F12 / Layer 1 named
  hypotheses H1–H5 / Layer 2 / Layer-3 ledger) — its value is the *whole* map.
- The **catalogue of failed gates** (the established negatives F9i–F9xi) — first-class
  in the research document, but tangential to any single focused essay.
- ERG-003 (H3) and the Delsarte/Paley (H5) frontier lanes.

## Build order (recommended)

1 → 2 → 3. Essay 1 is the flagship and reuses the most-polished modules; Essay 3 is
the most self-contained (good second to validate the split pattern); Essay 2 is the
heaviest (the certificate ladder + ergodic-optimization narrative).
