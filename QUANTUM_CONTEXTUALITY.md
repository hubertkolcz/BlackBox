# Quantum Contextuality — Project Context Document

Transfer document consolidating the findings, artifacts, and verified results of an
extended research + implementation session (July 2026). Intended as project knowledge
for the "Quantum Contextuality" project. All numerical claims below were verified by
computation (Wolfram Engine / Python) or against primary sources during the session.

## 1. Central conceptual finding

**Contextuality is never a property of a state alone; it is a property of a state
together with a specified set of measurements.** This resolves the apparent tension
that started the investigation:

- Delfosse, Okay, Bermejo-Vega, Browne, Raussendorf, *"Equivalence between
  contextuality and negativity of the Wigner function for qudits"*, New J. Phys. 19,
  123024 (2017): contextuality ⇔ Wigner negativity holds for **n ≥ 2 qudits with
  stabilizer (Pauli) measurements only** (the paper states verbatim: "we consider only
  contextuality of stabilizer measurements"). For a **single qutrit** the equivalence
  fails: there exist Wigner-negative states admitting a noncontextual hidden-variable
  model **for Pauli measurements**.
- KCBS (Klyachko, Can, Binicioğlu, Shumovsky, PRL 101, 020403 (2008); arXiv:0706.0126)
  uses five **non-Pauli** rank-1 projectors (pentagon directions). A single qutrit
  state can simultaneously (a) admit an NCHV model for all Pauli measurements and
  (b) violate the KCBS inequality — no contradiction.
- The statement "KCBS is a test on a single qutrit; the five pentagon nodes are five
  measurement directions ℓᵢ, i.e. projectors |ℓᵢ⟩⟨ℓᵢ|" is **correct**.

## 2. The KCBS paper — verified facts (arXiv:0706.0126v4)

- Observables: Aᵢ = 2S²ℓᵢ − 1 = 1 − 2|ℓᵢ⟩⟨ℓᵢ| (sign convention: A = I − 2|ℓ⟩⟨ℓ|),
  five cyclically orthogonal unit directions ("pentagram").
- The paper calls its inequality **"the pentagram inequality"**; the phrase
  "fundamental inequality" does not occur (that phrase belongs to Cabello's 2013 PRL,
  see §5).
- **No physical platform is assumed.** Derivation is for an abstract "three-dimensional
  quantum system" via the marginal problem (existence of a joint distribution
  compatible with the distributions of commuting pairs). No sequential/von Neumann/
  nondestructive measurement requirements appear anywhere.
- The paper itself **proposes a photonic realization**: a single-mode biphoton (photon
  pair differing only in polarization) measured via coincidence rates in a Hanbury
  Brown–Twiss interferometer, with directions taken in Stokes space R³_pol, not
  physical space. Nothing excludes the Lapkiewicz-type implementation.

## 3. The canonical experiment — Lapkiewicz et al., Nature 474, 490 (2011)

Single heralded photon (SPDC, 20 mm ppKTP, 405 nm pump, 810 nm photons, D₀ herald,
~3500 heralded counts/s) in **three modes**: two polarizations of one spatial beam +
one extra spatial mode. Calcite PBSs merge/split modes; every two-mode transformation
is a half-wave plate. Five contexts = five configurations of ONE apparatus: wave
plates WP₁–WP₄ (109.1°, 109.1°, 109.1°, −64.1°) switched on one at a time; the
detector carrying the observable shared between neighbouring contexts is physically
untouched (compatibility enforced by construction). Detector click → Aᵢ = −1.

- Sixth observable A₁′ (the closing measurement is a different physical device);
  extended inequality Σ ≥ −3 − ε with ε = 1 − ⟨A₁A₁′⟩ = 2P(A₁ ≠ A₁′), measured by
  blocking modes with a polarizer: ε = 0.081(2), bound −3.081(2).
- Result: **Σ = −3.893(6)**, violation > 120σ. Fair-sampling assumed (detection
  loophole open); compatibility loophole closed by construction.

**Critiques (implementation-level, never platform-level):**
- Ahrens, Amselem, Cabello, Bourennane, Sci. Rep. 3, 2170 (2013): the 6-correlation
  inequality "is not a facet"; "cannot be considered a proper test... since the same
  observable is measured with different setups in different contexts". They redid the
  KCBS test — **also with photons** (time-multiplexed qutrit, sequential measurements).
- Lapkiewicz et al. reply (arXiv:1305.5529, arXiv-only): the shared measurement is
  "the identical physical measurement"; the extra correlation stems from the topology
  of the KCBS pentagon, not the implementation.
- Kujala, Dzhafarov, Larsson, PRL 115, 150401 (2015): the data show statistically
  significant inconsistent connectedness (context-dependent marginals), but the
  Contextuality-by-Default reanalysis **confirms contextuality**
  (99.99999999% CI [3.127, 4.062]).
- Rev. Mod. Phys. 94, 045007 (2022) (Budroni, Cabello, Gühne, Kleinmann, Larsson)
  treats the experiment as the legitimate first KCBS test ("joint measurements"
  category). No published work claims the photonic platform is excluded by KCBS
  assumptions.

**Why a single photon in 3 modes is a qutrit (not speculation):** the 3-mode
single-photon subspace is a 3-dim Hilbert space carrying the spin-1 formalism exactly
(one click among three detectors ↔ two of three squared spin projections equal 1);
Reck et al. decomposition gives any U(3) from two-mode elements; dimension 3 is prime
→ no tensor factorization → "indivisible", no entanglement concept (endorsed by
Cabello, Nature 474, 456). Caveats: second quantization sees mode entanglement;
classical light reproduces the mode geometry (Zhang et al., Sci. Rep. 7, 44467) — the
quantum content resides in single-photon click statistics (Markiewicz et al., npj QI
5, 5 (2019): intensity measurements shift the classical bound to the non-signaling
limit).

**Photonic qutrit encodings:** single-photon polarization is only a qubit (massless →
helicity ±1 only). Genuine spin-1: biphoton polarization triplet {|HH⟩, |VV⟩,
(|HV⟩+|VH⟩)/√2}. Alternatives: three paths (Lapkiewicz), OAM {−1,0,+1}, time bins.

## 4. Why five projectors (and not three)

Each measurement is dichotomic (Sℓ² ∈ {0,1}); orthogonal neighbours ℓᵢ ⊥ ℓᵢ₊₁ make
(Aᵢ, Aᵢ₊₁) compatible → 5 contexts, each observable in 2 contexts. Odd cycles are
required (even cycles admit NCHV saturation); the triangle C₃ fails in QM because
three mutually orthogonal directions in d=3 form ONE context (and, operationally,
sharp pairwise-compatible measurements are jointly compatible — Specker). C₅ is the
smallest usable cycle. Geometry: pentagram on a cone, cos²θ = cos(π/5)/(1+cos(π/5)),
azimuth step 4π/5; optimal state = cone axis; ⟨Pᵢ⟩ = 1/√5.

## 5. Graph-theoretic structure (Cabello, PRL 110, 060402 (2013))

Exclusivity graph of the five events = C₅. Three theories = three graph invariants:
- classical (NCHV): independence number **α = 2**
- quantum: Lovász number **ϑ = √5** (state-dependent optimum, achieved by the circuit)
- exclusivity-only ("global exclusion", E-principle single copy): fractional packing
  **α\* = 5/2**

Two-copy explanation of the quantum bound: 25 product events, exclusivity graph =
conormal product C₅∨C₅ (ϑ = 5, Lovász multiplicativity, verified by SDP); the 25
events partition into 5 pentads {(i, 2i+j mod 5)}, each a 5-clique; quantum
saturates each pentad at exactly 1 → (Σp)² ≤ 5 → Σp ≤ √5.

Game form (referee + Alice-with-context + Bob-without-context; win = consistency +
anticorrelation on a random edge): classical 4/5, quantum 2/√5 ≈ 0.8944,
exclusivity-only 1; dictionary P(win) = (2/n)Σ⟨node⟩. On C₃: classical = quantum =
2/3 (no quantum advantage — Specker triangle). CHSH exclusivity graph = Ci(8;1,4),
ϑ = 2+√2 (same SDP machinery covers nonlocality).

## 6. Artifacts (repo: C:\Users\cp\Desktop\black-box, commit e282497)

### kcbs_circuit.wl — 13-section computational essay (English, Wolfram Quantum Framework)
One circuit = the Lapkiewicz cascade `[P, T1, T2, T3, T4]` on a **native qutrit
wire**; context k = prefix of length k. All gates two-level (deviation ~1e−16).
Sections: environment (kernel-hygiene cell for the Global`-shadowing pitfall) /
geometry / stage frames with detector alternation / qutrit circuit + native Diagram /
**Heisenberg-picture analysis** (chosen over Schrödinger: contextuality is about
observables; shared-observable identity across contexts ~1e−16; pentagram closure
A₁′≡A₁ ~1e−16 — the ideal-circuit analogue of the experimental ε; cyclic
orthogonality; S from Heisenberg data) / event graph derived from circuit operators
(≅ C₅) with α, ϑ, α\* / three-party game + Monte Carlo (deterministic: win 0.801,
Σ=2.000; weighted 0.3/0.7 mixture: Σ≈2.01; coin box (0,1)/(1,0): win 1.0, Σ→5/2) /
SDP `lovaszTheta` (C₅→√5, C₇→3.3177, CHSH→2+√2, C₅∨C₅→5) + eigenvalue and NMaximize
routes / two-qubit **biphoton encoding** (triplet subspace; collective u⊗u rotations
via ZYZ Euler; disentangler; singlet = leakage flag ~1e−33) / **time-like sequential
measurements** (binary POVM {Π, 1−Π}; sequential ⟨A₂A₃⟩ = joint value exactly;
repeatability and A-B-A disagreement = 0) / **Wigner negativity**
(`QuantumWignerTransform`: input |0⟩ non-negative (stabilizer); KCBS state min
−0.1139, negativity 0.2278; the prep gate P is the non-stabilizer step; narrative tie
to §1's single-qutrit divergence) / machine-checkable `KCBSVerification` → OK.
Key verified numbers: S_qutrit = S_2qubit = S_Heisenberg = 5−4√5 = −3.94427190999916.
Evaluation notes: evaluate cell-by-cell from a fresh kernel; the first cell repairs a
kernel polluted by single-cell evaluation (Global` shadowing of QuantumState etc.).

### kcbs_simulation.wl / kcbs_simulation.py — Monte Carlo of the Nature 2011 experiment
Pentagon geometry (exact symbolic in .wl: orthogonality ≡ 0, Σ⟨Pᵢ⟩ ≡ √5), Poissonian
source + multinomial detection, the A₁′/ε protocol, noise ρ = V|ψ⟩⟨ψ| + (1−V)𝟙/3.
Results: ideal S = −3.944; realistic (V = 0.977, 1° misalignment) S ≈ −3.907 with
ε ≈ 0.013 (paper regime −3.893(6)); critical visibility V_crit = (5+3√5)/20 ≈ 0.5854.
Caveat: a classical simulator reproduces statistics, not evidential force — the
sampler knows the context, which is exactly what NCHV models are forbidden.

### BlackBox paclet — the sheaf/Čech certificate layer (added 10 July 2026)

The pipeline is packaged as the paclet `BlackBox/` (context
`HubertKolcz`BlackBox``, 27 exported symbols, `Tests/BlackBoxTests.wl` →
ALL PASS: True). On top of the LP/SDP layer (α, ϑ, α\*, contextual fraction,
`GlobalSectionQ`) it now carries the **possibilistic certificate layer** that
replaced the cellular-sheaf Laplacian after the Laplacian's own pre-registered
gate REJECTED it (residuals {0,0,0} on classical/quantum/Wright — blind; see
pipeline-2026-07-10/sheaf_laplacian.wl):

- `CechObstruction[scen, e]` — the Abramsky–Mansfield–Barbosa obstruction
  γ(s) per support section (arXiv:1502.03097 Prop. 4.4: γ(s)=0 iff a compatible
  Z-linear family restricts to s), with the **exact order** of each class by
  Smith normal form (`"ObstructionOrder"`). Gate, passed: classical C5 0/15
  obstructed; quantum 0/15 (identical support — probabilistic contextuality is
  the LP layer's jurisdiction); Wright 10/10 = strong-contextuality certificate.
  Orders: GHZ classes are **pure 2-torsion** (order exactly 2, rationally
  invisible — Mermin's mod-2 argument as a homological invariant); odd-cycle
  boxes infinite order; Hardy order 1 (the documented false negative, integral).
- `CechCohomology[scen, e]` — absolute H⁰/H¹ of the Z-linearized support
  presheaf on arbitrary covers (C² term included, δ¹δ⁰=0 verified, torsion by
  Smith). H⁰ multiplicative on the two-copy product cover (36 = 6²); ambient H¹
  is NOT a contextuality signal (PR box and noncontextual uniform both give Z).
- `AvNArgument[scen, e, d]` — All-vs-Nothing parity certificates over GF(d)
  (arXiv:1502.03097 §6): GHZ (the four Mermin equations), Wright boxes and
  their products, PR box, and the Z₃ box on the square are AvN; Hardy is not.
  AvN ⇒ cohomologically strongly contextual, verified across the census.
- `CoverScenario[X, cover, outcomes]` — arbitrary covers and per-measurement
  outcome sets (GHZ/Mermin, Z_d boxes, KS-style covers).

Verification essay: `SupportCohomology.wl` + `RunSupportCohomology.wl`
(`wolframscript -file RunSupportCohomology.wl -print all` → 25 checks,
OK -> True), including the two-copy product cover of ab_sheaf.wl
(Wright⊗Wright 100/100 obstructed; quantum⊗quantum clean, |Sₑ| = 11²) and a
census cross-validated against Cech-Cohomology-of-Ulrey-Models-AB-Sheaf.nb.
### kcbs_wigner_flow.wl — Wigner-negativity flow through the cascade (runner: RunWignerFlow.wl)
Companion note to kcbs_circuit.wl §11/§13. Discrete Wigner function of every prefix
of [P, T1, T2, T3, T4]: input |0⟩ → 0; all five prefixes → exactly 2/√5 − 2/3
≈ 0.227761 (two cells of depth 1/3 − 1/√5 each; closed forms verified symbolically,
using c₂ = cos(π/5)/(1+cos(π/5)) ≡ 1/√5). Negativity is created once, by P, and
conserved by every T_k at the SAME two phase-space cells — the column of the mode
the detectors never monitor (column sums to the no-click probability 1 − 2/√5;
monitored-mode columns pointwise non-negative in every context; mode marginals ≡
Born probabilities). What moves is positive quasi-probability, alternating between
two exact patterns ((1 ± 2s)/(3√5), (1 ∓ s)/(3√5), s = √(√5−2)) in step with the
detector alternation (handedness sign of the stage frame). Conservation is an orbit
property, not a gate property: each T_k is non-Clifford, creating negativity ≈ 0.324
from two of three basis states (sparing its shared-detector mode); P makes all
three negative. Bonus identity: every T_k is a Givens rotation with cos θ = (√5−1)/2
= 1/φ (next-nearest pentagram overlap). Machine-checkable `WignerFlowVerification`
(16 checks) → OK. Headless: `wolframscript -file RunWignerFlow.wl -print all`.

### kcbs_ledger.wl — the phase-space ledger of the Born rule (runner: RunLedger.wl)
Resolves the state/clicks segregation posed by kcbs_wigner_flow.wl. (1) Two-sided
ledger: p = 3 Σ_λ W_E(λ)W_ρ(λ) reproduces the Born rule exactly at every cut of
every context; the Heisenberg cut puts ALL negativity in the effects (all ten
pentagon effects Wigner-negative, 0.20–0.33 each; state |0⟩ clean), the Schrödinger
cut all in the state; the minimum over cuts is 2/√5 − 2/3, at the Schrödinger cut —
the flow note's accounting was the cheapest ledger, and no cut balances to zero.
(2) Frame-free invariant by exact LP (RevisedSimplex over ℚ(√5)): minimal negative
weight ν = (√5−2)/2 over noncontextual decompositions; contextual fraction
CF = 2√5 − 4 = 4ν; bridge N_Wigner = 1/3 − ν/(1+ν), with ν/(1+ν) = the no-click
probability 1 − 2/√5. (3) White-noise scan ρ_V = V|ψ⟩⟨ψ| + (1−V)𝟙/3: N(V) dies at
V\* = (10+9√5)/61 ≈ 0.4938, ν and CF share the KCBS threshold V_c = (5+3√5)/20 ≈
0.5854 ⇒ window (V\*, V_c) of Wigner-negative yet KCBS-noncontextual states — the
badges decouple; CF = 4ν holds along the ENTIRE family and CF is exactly linear
above threshold. (4) The phase-point operators (reconstructed from the framework by
linearity) are parity observables (spectrum {1,1,−1}, Tr[A_λA_μ] = 3δ): each
negative cell is a sharp binary witness with minus-probability exactly
3/(2√5) ≈ 0.6708 > 1/2; the witness eigenvectors have NO support on the undetected
mode (readout interferes the monitored modes). Enlarged event graph (5 clicks +
5 pass events + 2 witnesses): connected across the badges via the stage-1 pass
event, but α = 6, θ ≈ 6 > joint quantum sum 5 − 2/√5 ≈ 4.106 — no joint CSW
violation (exclusivity binds topologically, not metrically). Machine-checkable
`LedgerVerification` (21 checks) → OK. Headless:
`wolframscript -file RunLedger.wl -print all`.

### kcbs_epilogue.wl — closing the Wigner thread (runner: RunEpilogue.wl)
Three verdicts, 21 checks → OK. (1) CURRENCY LAW: CF = (n−1)·ν on the n-cycle —
ratios 4/6/8/10 at quantum max for n = 5/7/9/11 (deviations < 1e−9, checks at
1e−6); EXACT at the Wright boxes (rational Simplex: ν = 1/(n−1), CF = 1,
n = 5,7,9) and at the C5 quantum point (RevisedSimplex: CF = 4ν); ratio 6 across
the contextual range of the C7 white-noise family (V = 0.70–1, V_c ≈ 0.677);
ratio 4 at 40 random ASYMMETRIC quantum models and 23 random contextual
no-signalling mixtures, 9 of them certified beyond-quantum (they violate the C5
correlator quantum bound 4√5−5, calibrated on the KCBS-maximal state) — the law
holds polytope-wide, not just on the symmetric slice. Analytic proof left open
(route: the complete n-cycle inequality set, Araújo–Quintino–
Budroni–Terra Cunha–Cabello, PRA 88, 022118). (2) BINDING NO-GO: all 45 cascade
parity witnesses (5 wire points × 9 cells) pulled to one arena; 35 pentagon
edges with a pointed structure — every positive-cell witness binds to exactly
one click, the two negative-cell witnesses (the events that certify negativity,
p₋ = 3/(2√5) > 1/2) bind to NONE at any wire point; no two high-p witnesses can
ever be exclusive (3/√5 > 1 would break the Born rule); every single addition to
the pentagon raises α (best pentagon+1 violation is negative), best pentagon+2
= 0.012 ≪ √5−2 ≈ 0.236, greedy growth stops at the bare pentagon. The pentagon
is the metric optimum of its own phase-space witness pool: the badges share
topology, never strength. (3) CHANNEL LEDGER: Choi-state Wigner negativity
(framework two-qutrit transform ≡ A_λ⊗A_μ pairing, agreement 1e−15): Id and
X(shift) → 0 (Clifford); P → 0.747106; every T → 0.725972. NEW structural fact
surfaced en route: T3 = T1 and T4 = T2 to machine precision — the cascade is
gate-periodic, [P, T1, T2, T1, T2] — and T2 = Π·T1·Πᵀ for a basis permutation Π
(machine-checked); permutations are affine on Z₃, hence Clifford, so the equal
channel values are explained, not coincidental. Every cascade gate is strongly
magic-capable as a channel — the flow note's conservation is purely an orbit
fact. Headless: `wolframscript -file RunEpilogue.wl -print all`.

### LovaszThetaSparse + lovasz_theta_sparse.py — exact ϑ at 10⁵ pentagon blocks, and the cis/trans CORRECTION (commit c906427, CaseStudies.wl §D3)

**Method.** The dense primal SDP behind `LovaszTheta` (n(n+1)/2 variables) saturates
near 150 vertices. `LovaszThetaSparse` (BlackBox v1.1.0) uses the Lovász dual
ϑ = min λ_max(J − B) with B supported on the edges, absorbs the rank-one J = ee^T
into one Schur border row, and splits the (n+1)-cone along the maximal cliques of a
min-degree chordal extension (Grone completion / Agler decomposition) — one PSD block
of size ≤ treewidth+2 per clique, plus the unconditional self-certificate
ϑ ≤ λ_max(J − B) from the recovered witness. Validated against the dense SDP on 25
graphs to ≤ 4·10⁻⁶. At scale: `lovasz_theta_sparse.py` (Clarabel; ring N = 10⁴
certified to 1.3·10⁻⁵ rel in ~1 min, N = 10⁵ = 4.6M variables in ~6 min), plus an
independent Z_N-symmetry route (DFT block-diagonalization of the block-circulant dual
into 3×3 Hermitian symbols, 4 orbit parameters, frequency cutting planes,
all-frequency eigenvalue certificate) exact past N = 10⁶ in seconds. Numerical
caveat: both routes must be O(1)-conditioned (border rescaled by 1/√n / symbols in
density units), else the interior point biases high at N ≥ 10⁴.

**The correction.** Edge-glued pentagon meshes carry a hidden binary design
parameter, the gluing ORIENTATION: each pentagon meets its glue edge {u,v} with a
one-edge side and a two-edge side; attaching consecutive short sides to the SAME
endpoint (**cis**) is what `PentagonChain` builds (the c1-vertices form a rail);
ALTERNATING endpoints (**trans**) is what the CaseStudies ring builder builds. The
two families are NOT isomorphic, proven by the dense solver itself:
ϑ(trans-ring 21) = 28.8676 < ϑ(cis-chain 19) = 29.0399, and ϑ is monotone under
induced subgraphs, so cis chains do not embed in trans rings. Consequently the
previously "certified" scaling bracket ϑ(ring 10⁵) ∈ [142 491, 150 000] is
WITHDRAWN — its disjoint-chain lower bound anchored cis-chain values
(ϑ(chain 31) = 47.0268, itself correct) in the wrong family — and the expected
density rise 1.377 → 1.5 does not exist.

**Exact laws (all machine-verified, both solvers agreeing to certificate level):**
- **trans ring** (the CaseStudies mesh): ϑ = τ\*·N − o(N) with the density limit an
  ALGEBRAIC NUMBER in closed form:
  **τ\* = Root[49x³ − 128x² − 75x + 218, middle root] = 1.3767177459158590533…**
  = 128/147 + (2√27409/147)·cos(⅓ arccos(−2852191/27409^{3/2}) − 2π/3),
  27409 = 128² + 3·49·75. Derivation: the ring's reflection automorphism forces
  β_bx = γ_ax, KKT stationarity factors as (u−2g)(u+2gc) = 0 giving β_ab = 2γ_ba,
  and Gröbner elimination of the remaining polynomial KKT system leaves this single
  cubic; the dual witness lies in ℚ(τ\*) — g = (53τ²−121τ+218)/458,
  h = (327−67τ−35τ²)/229, cos θ\* = (1715τ²+77τ−3428)/916, θ\* ≈ 0.52486π — and
  feasibility on the whole frequency circle reduces to the perfect square
  4gh²(c−c\*)² ≥ 0, so a handful of RootReduce-exact zeros certify global
  optimality (convex minimax, positive multipliers; machine-checked in
  CaseStudies §D3, key D3_densityClosedForm).
  Density is FLAT: 1.37656 (N = 15, 30) → 1.3766680 (10²) → 1.3767169 (10³) →
  1.3767178 (10⁴–10⁶) → τ\*. ϑ(10⁵) = 137 671.775 (solver; rigorously
  ≤ 10⁵τ\* = 137 671.7746). The theorem α = ⌊4N/3⌋ is untouched, so the quantum gap
  stays EXTENSIVE with algebraic slope: ϑ − α = (τ\* − 4/3)·N = 0.0433844126·N
  (= 4 338.8 at N = 10⁵, exact instead of bracketed).
- **cis ring** (PentagonChain closed up): **ϑ(N) = N + ϑ(C_N) — a THEOREM**, and
  **α = ⌊3N/2⌋ — also a THEOREM** (CaseStudies §D3, machine-checked construction).
  ϑ upper: delete the N glue edges → C_N ⊔ C₂N; monotonicity + additivity +
  ϑ(C₂N) = N (perfect). ϑ lower: one-extra-dimension orthonormal representation —
  rail = optimal C_N umbrella, every c3 vertex = the handle itself, every c2
  vertex = the appended basis vector; value ϑ(C_N) + N. α upper: each of the N
  pentagons induces exactly C5 (independence 2); window-counting weighs c1, c2
  twice and c3 once → 2(s1+s2)+s3 ≤ 2N → |S| ≤ N + s3/2 ≤ 3N/2. α lower: all c3's
  + alternate rail vertices. Even N collapses the whole sandwich,
  α = ϑ = α\* = 3N/2 — NO quantum gap; odd N approaches it with deficit π²/8N and
  bounded gap ϑ − α → 1/2.
- **cis chains**: ϑ = (3m+2)/2 exactly at even m (the parity law's ϑ = α case);
  per-block increments → 3/2.

**Reading:** the bulk quantum advantage of pentagon meshes is set by the gluing
orientation (trans: ≈ 0.0434 per block, extensive), not by closing the topology —
closure and block parity only modulate it; the cis family saturates the exclusivity
bound α\* classically and carries no bulk gap.

**The optimal gluing word (follow-up computation).** Treating a mesh as a binary
necklace over {cis, trans}, pure trans is NOT gap-optimal: the word **(cct)^∞** —
two cis gluings, then one trans "reset" — keeps the trans staircase α/L = 4/3 while
lifting ϑ/L to 1.40323086923899745 (continuum-certified, below), i.e. **gap
0.0698975 per block = 1.6111× the pure-trans gap**. Method: exact α densities as
max-plus cycle means of a 3-state interface transfer DP (exact rational arithmetic;
the pure-trans staircase is its transfer matrix's 3-cycle gaining 4 per 3 blocks);
certified chordal ϑ at 1200–2400 blocks; exhaustive sweep of all binary bracelets
of period ≤ 6, and over periods ≤ 12 every word with α-density 4/3 has cis-fraction
≤ 2/3 with equality UNIQUELY for cct (its best higher-period rivals cctcctctt,
cctcctcctctt rank strictly below). Design rule: trans letters protect the classical
bound (each t breaks the cis rail before it can lift α), cis letters buy quantum
value; the optimum is the densest cis packing α tolerates. Refined conjecture:
(cct)^∞ is globally optimal over all gluing words. Tooling:
`lovasz_theta_sparse.py words`; WL anchor wordRing/cct in CaseStudies §D3
(key D3_gluingWordOptimum).

**No τ\*-style closed form for the cct density — a finding in itself.** The (cct)
unit cell yields a 9×9 DFT symbol with 12 edge-orbit parameters; the mesh's
reflection automorphism (|Aut(cct-ring of m cells)| = 2m, machine-checked) pairs
them to 7, and the continuum minimax has the same active-set shape as τ\* (J-block
+ ONE interior frequency, φ ≈ 0.70345π). Newton on the reduced KKT at 320 digits
(residual 10⁻³¹⁹, positive multipliers, witness feasible over a 2²⁰-point grid;
convexity + automorphism averaging ⇒ GLOBAL optimum) pins
ϑ/L = 1.40323086923899745105894248… exactly — but LLL integer-relation search on
250 matched digits EXCLUDES any minimal polynomial of degree ≤ 36 with coefficient
height ≲ 10⁶ (≲ 10⁶⁰ at degree 3), for the density, cos φ, and every witness
parameter. Contrast: τ\* is a cubic with two-digit coefficients. The algebraic
complexity of the symbol minimax explodes with word period; at period 3 the exact
object standing in for a closed form is the polynomial KKT system itself
(CaseStudies §D3, key D3_cctDensityCharacterized).

## 7. Wigner negativity toolchain (Wolfram Community, N. Murzin)

Source: "On quantum amplitudes, correlations and negativity"
(https://community.wolfram.com/groups/-/m/t/3026423). Framework tools:
`QuantumWignerTransform`, `QuantumWeylTransform`, `QuantumPhaseSpaceTransform`,
`QuantumWignerMICTransform`. Adopted in essay §11. The open thread — track negativity
flow through the cascade gate-by-gate — is closed by kcbs_wigner_flow.wl (see §6).

## 8. Key references

- Klyachko, Can, Binicioğlu, Shumovsky, PRL 101, 020403 (2008); arXiv:0706.0126
- Lapkiewicz et al., Nature 474, 490 (2011); arXiv:1106.4481
- Ahrens, Amselem, Cabello, Bourennane, Sci. Rep. 3, 2170 (2013); reply arXiv:1305.5529
- Kujala, Dzhafarov, Larsson, PRL 115, 150401 (2015)
- Cabello, PRL 110, 060402 (2013) ("fundamental inequality", E-principle, two copies)
- Delfosse et al., New J. Phys. 19, 123024 (2017) (negativity ⇔ contextuality, n ≥ 2)
- Budroni, Cabello, Gühne, Kleinmann, Larsson, Rev. Mod. Phys. 94, 045007 (2022)
- Abramsky, Brandenburger, NJP 13, 113036 (2011); arXiv:1102.0264 (sheaf framework)
- Abramsky, Barbosa, Kishida, Lal, Mansfield, CSL 2015; arXiv:1502.03097
  ("Contextuality, Cohomology and Paradox": Čech obstruction, AvN arguments)
- Gühne et al., PRA 81, 022121 (2010) (compatibility loophole)
- Markiewicz et al., npj Quantum Inf. 5, 5 (2019); Zhang et al., Sci. Rep. 7, 44467 (2017)

## 9. Open threads

- Push the repo to GitHub. Local side is READY (2026-07-10): all branches merged
  into master, README + LICENSE (MIT) added, full verification battery re-run on
  the merged tree. Remaining: re-auth (`gh auth login`, token for `hubertkolcz`
  invalid), decide account (hubertkolcz vs WaverQ org), name, visibility, then
  `gh repo create <name> --source . --remote origin` and push.
- ~~Gate-by-gate negativity flow through the cascade~~ — done 2026-07-10,
  kcbs_wigner_flow.wl (WignerTransform route). ~~Remaining variant: phase-space
  view of the T gates as channels~~ — done, kcbs_epilogue.wl §4 (Choi–Wigner
  route; a Weyl/MIC re-derivation would be representational, not new physics).
- ~~From kcbs_ledger.wl: is CF = 4ν a theorem or a C₅ accident? metric binding
  possible?~~ — RESOLVED, and by TWO independent derivations that agree on the
  law **CF = (n−1)·ν** (a pentagon accident: the "4" is n−1). (i) Sheaf level:
  `SignedNegativity.wl` + `RunSignedNegativity.wl` (8 checks OK) with the new
  paclet fn `SignedNegativity[scen, e]` = min negative mass of a signed
  decomposition over deterministic assignments — exact for n=5 (4), n=7 (6,
  FullSimplify), n=9 Wright (ν=1/8, ratio 8), for BOTH the quantum and Wright
  models; across scenarios the ratio varies (CHSH PR and GHZ give CF/ν = 2), so
  no universal constant, only CF = 0 ⇔ ν = 0. (ii) kcbs_epilogue.wl established
  the same CF = (n−1)ν across the n-cycle no-signalling polytope and settled the
  METRIC-BINDING half as a NO-GO within the cascade parity pool (exhaustive
  +1/+2, greedy; negative-cell witnesses never bind to clicks). The ledger's
  "CF = 4ν along the whole C₅ white-noise family" is explained: mixing stays
  inside the pentagon scenario, whose ratio is 4. ~~Analytic PROOF of
  CF = (n−1)ν~~ COMPLETE & UNCONDITIONAL for every no-disturbance model on the
  odd n-cycle (`CF-negativity-proof.md`, 11 July): (Lemma 0) every contextual
  C_n model violates exactly ONE cycle-inequality facet (parity: two odd
  patterns differ in even ≥2 coords ⇒ B_γ+B_γ′ ≤ 2(n−2)); (Lemma 1) Wright box
  ν = 1/(n−1) by G-symmetrisation; LOWER bound CF ≤ (n−1)ν via the explicit
  dual witness w_{i,(s,t)} = (1/n + γ*_i st)/(n−1), e·w = 1+2CF/(n−1), weak LP
  duality; (Lemma 2) e₀ = (e−CF·W_{γ*})/(1−CF) ∈ P_NC — (A) e₀≥0 from
  edge-positivity c_j≥−1+|m_j+m_{j+1}| plus the odd-cycle telescoping identity
  |m_i−m_{i+1}| ≤ Σ_{j≠i}|m_j+m_{j+1}| (alternating sum of the complementary
  path = m_{i+1}−m_i, needs n odd), (B) other facets reduce to CF≤1 — giving
  UPPER bound CF ≥ (n−1)ν by gauge convexity. Every step is a one-line
  inequality; machine-verified n=5,7,9 + random asymmetric. The n−1 is the odd
  cycle's frustration number (max satisfiable anti-correlations). Genuinely
  odd-cycle-specific: even cycles → Wright noncontextual; CHSH & GHZ → ratio 2.
- n-cycle generalizations (C₇, C₉...) and their circuits; run encoding B on real
  gate hardware as a genuine platform test.
- Sequential-game quantum strategy demo end-to-end (Alice prefix + Bob binary POVM).
- Čech layer follow-ups: ~~Kochen–Specker covers (18-vector Cabello set)~~
  RESOLVED (SupportCohomology.wl KS section): the Peres–Mermin square (24/24)
  and the CEG 18-ray set (36/36, geometry machine-verified) are both convicted
  with ALL obstruction classes of order EXACTLY 2, and both AvN theories are
  the textbook parity proofs recovered mechanically — with the box models all
  of infinite order, the census now shows a clean TORSION DICHOTOMY between
  parity-type and box-type strong contextuality. ~~relative H¹ as a group~~
  RESOLVED (`CechRelativeCohomology`): H¹(F~) for F~ = ker(F → F|C0) is the
  actual home of γ — Z/2 for the parity models (GHZ, Peres–Mermin, 18 rays),
  Z for the boxes (Wright, PR), and 0 for classical and Hardy (Hardy's false
  negative is structural — its γ lives in the trivial group). Because F~(C0)=0
  the construction is self-validating: the explicit connecting cocycle's order
  provably equals CechObstruction's ObstructionOrder, checked per section.
  ~~AvN over non-prime rings~~ RESOLVED: `AvNArgument[scen, e, d]` now takes any
  d ≥ 2 (Z_d need not be a field) via a Smith-form lattice-solvability test that
  reduces to the GF(d) rank test for prime d; for composite d it retains
  non-unit-coefficient equations (the 2x = 2 mod 4 relations). Demo: the Z₄ shift
  box on the square is AvN over Z₄ with a witness that is CONSISTENT mod 2 — a
  strictly-modular obstruction no prime reduction can see. Čech-layer follow-ups
  are now all closed.
- Pentagon meshes (§6, cis/trans correction): ~~closed form for the trans-ring
  density constant~~ RESOLVED — τ\* = Root[49x³ − 128x² − 75x + 218, 2], exact KKT
  certificate in §6/CaseStudies §D3. ~~Prove ϑ(cis-ring N) = N + ϑ(C_N) and
  α(cis-ring N) = ⌊3N/2⌋~~ RESOLVED — both are theorems now (§6/§D3: subgraph
  monotonicity + one-extra-dimension representation; pentagon window counting).
  ~~Is the extensive trans gap optimal over all gluing words?~~ RESOLVED — NO:
  (cct)^∞ beats it by 61% (gap 0.0698975 per block, §6). ~~Closed form for the
  cct density~~ RESOLVED — negatively: certified global optimum
  1.40323086923899745105894248 (320-digit KKT), but LLL excludes any minimal
  polynomial of degree ≤ 36 with height ≲ 10⁶; the exact characterization is the
  KKT system (§6). Global optimality of (cct)^∞ — PARTIALLY RESOLVED
  (machine-checked lemmas, CaseStudies §D3 key D3_towardsGlobalOptimality):
  LEMMA A, α\* = 3L/2 for every gluing word (uniform ½-packing + a
  word-independent fractional edge cover: ½ on each block's (B,X) edge and its
  two glue-in edges, covering every vertex exactly once) hence ϑ̄ ≤ 3/2
  universally; LEMMA B, ᾱ ≥ 4/3 for every word (potential certificate
  φ = (0,−⅓,−⅔) on the 3-state interface DP: six inequalities, all ≥ 4/3,
  telescoping along any word); PINCH: gap ≤ min(ϑ̄−4/3, 3/2−ᾱ) ≤ 1/6, and any
  cct-beater needs ϑ̄ > 1.40323087 AND ᾱ < 1.4301025 simultaneously;
  EXHAUSTIVE: all aperiodic bracelets p ≤ 9 certified below cct (max 0.0685 at
  cctcctctt; overall runner-up cctcctcctctt at 0.0689 vs 0.0698975). The
  completion — a transfer-SDP sub-action (windowed chordal dual templates ⇒
  density bound on ϑ̄) — yields ε-OPTIMALITY (see the ε-certificate paragraph):
  the exact bracket **sup_w gap̄(w) ∈ [gap(cct)=0.069898, Γ₈=0.075309]**, cct
  optimal to within ε=0.0054. Whether sup = gap(cct) is OPEN (NOT obstructed):
  each Γ_k is rational and gap(cct) irrational, but rationals converge to
  irrationals, so the τ_cct height result rules out only a SINGLE finite exact
  rational certificate — not the limit, not global optimality [ADVERSARIALLY
  CORRECTED: the earlier "obstructed by the τ_cct field" was a non-sequitur].
  ~~α-density/cis-fraction characterization~~ RESOLVED — THEOREM (CaseStudies
  §D3, key D3_alphaCisTheorem): ᾱ(w) ≥ max(4/3, 1 + f_c/2) for every word
  (letter-weighted potential certificate (0,−½,−1) with rates (3/2, 1)); hence
  ᾱ = 4/3 ⟹ f_c ≤ 2/3, with equality iff w = (cct)^k — any ccc gives
  ᾱ ≥ 4/3 + 1/(3p) strictly (adjusted max-plus cube of the cis step has
  min-max exactly 13/3 = 3·(4/3) + ⅓), and f_c = 2/3 without ccc forces all
  cis-runs equal to 2 by the run-average argument. Note the naive converse is
  false: cctt has f_c = 1/2 but ᾱ = 11/8. ~~Construct the explicit ε-optimality
  certificate~~ RESOLVED — CONSTRUCTED (EpsilonCertificate.wl [k=7],
  EpsilonCertificate8.wl [k=8]; keys D3_epsilonCertificate,
  D3_periodicOrbitSufficiency): a window-k transfer-SDP sub-action — per
  de Bruijn-k node a pair of exact rational PSD blocks Q (5×5, glue quad + apex)
  / R (4×4, X-triangle + apex), closure potentials ψ, DP potentials Φ with fixed
  strategy — proving the **DENSITY bound gap̄(w) ≤ Γ_k for EVERY gluing word**
  (Γ₇ = 1541247/20000000 = 0.0770624, Γ₈ = 941357/12500000 = 0.0753086; ε =
  0.0054 above gap(cct) at k=8). IMPORTANT (adversarially corrected): this is an
  L→∞ DENSITY bound, NOT a per-finite-ring bound. θ(ring_L) ≤ Σd is exact per
  ring (Schur on M = [[I+B,e],[eᵀ,σ]] ⪰ 0), but the α side telescopes only up to
  a bounded boundary, α(ring_L) ≥ Σr − 2·max|Φ| — so the EXACT per-ring form
  α(ring) ≥ Σr is FALSE (cctt at L=4: α=5 < Σr=5.488, per-block gap 0.0839 > Γ₇);
  both boundaries (ψ closed-walk-exact, Φ finite-valued) vanish under /L, giving
  gap̄(w) ≤ Γ_k. The rigorous machine-checked core is the POINTWISE per-edge
  bound σ(e) ≤ Γ_k (exact rational, all 256/512 edges). PERIODIC-ORBIT
  SUFFICIENCY (for the certified cocycle, NOT the true functional): σ(e) =
  d(x)−r(e)+ψ(x)−ψ(w) is locally constant on the de Bruijn-k SFT, so sup over ALL
  words of the certified functional = max cycle mean of σ = Γ_k (Karp +
  mean-payoff LP duality; a maximizing invariant measure for a locally-constant
  potential sits on a periodic orbit) — realized at the certificate's BOTTLENECK
  words (cttt)^∞ [k=7] / (ctt)^∞ [k=8], low cis-fraction, NOT cct. Hence no
  aperiodic word beats the best periodic word for the certified bound. Γ_k =
  0.1667, 0.1250, 0.1020, 0.0953, 0.0824, 0.0770624, 0.0753086 (k=2..8;
  decrements non-monotone). Bonus: the Q/R clique family solves the per-cycle
  transfer-SDP EXACTLY (word_density_transfer_sdp; < 10⁻⁶ loss) — position-space,
  no DFT symbol.
  ~~Trans-CHAIN density~~ RESOLVED (key D3_transChainResolved): open trans
  chains have the SAME bulk density τ\* (increments 1.3767178 within
  certificates from m = 50 to 800; boundary constant ≈ 0.995), with
  α(trans-chain m) = ⌊4(m+1)/3⌋ at every computed point — the gap is
  EXTENSIVE ≈ (τ\*−4/3)m, so Case D's "rings beat chains" was never about
  closure: the decaying chains were cis, and orientation is the whole story.
  Small-m accident: ϑ(trans-chain 5) = α = 8 exactly. Durable tools added to
  `lovasz_theta_sparse.py`: pentagon_chain_word, alpha_chain_word,
  word_density_transfer_sdp (exact position-space ϑ-density of any periodic
  word; no symmetry reduction). §6 mesh threads status: the RIGOROUS results are
  gap̄(w) ≤ Γ_k for all words (density bound) and the bracket sup_w gap̄(w) ∈
  [0.069898, 0.075309] (cct optimal to within ε=0.0054); periodic-orbit
  sufficiency holds for the CERTIFIED cocycle. GENUINELY OPEN (not obstructed):
  exact global optimality of (cct)^∞, i.e. whether sup = gap(cct) and whether
  lim_k Γ_k = gap(cct); and periodic-orbit sufficiency for the TRUE gap
  functional θ̄−ᾱ (which is not locally constant). The τ_cct height result
  bears only on single finite exact rational certificates.

## 10. Positioning: the atomic-GE program — reach and boundaries

The organizing premise of this repository is reductive: treat the **pentagon C₅ as
the atom** of contextuality and the **graph-exclusivity (GE) layer** — exclusivity
graph + Lovász ϑ (CSW, arXiv:1010.2163) — as the primary machinery, then try to
*recreate* contextuality by building composites out of pentagon atoms. The accumulated
results let us grade that program precisely: it succeeds completely at the
**quantitative and compositional** face of cyclic contextuality, and it fails — in a
mapped, informative way — at the reductive dream of one atom recreating
contextuality-as-a-single-thing. The value is that the corpus *confirms the program
within its scope and simultaneously charts the scope's three boundaries*, which is a
stronger outcome than a bare "it works."

**Where the program delivers.** (i) C₅ is the atom by theorem, not analogy: minimal
cycle with α = 2 < ϑ = √5 < α\* = 5/2, triangle collapses by Specker (§4–5). (ii) CSW
makes the quantum bound *equal a graph invariant* — "contextuality through the graph"
is a theorem the pentagon is the paradigm of. (iii) It composes and **scales**: pentagon
meshes give ϑ growing linearly (density τ\* ≈ 1.3767, α(ring N) = ⌊4N/3⌋ a theorem, §6)
while any state-vector treatment grows as 2^(5N) — the atomic-graph route makes
arbitrarily large contextual advantage *computable and certifiable* at 10⁵–10⁶ blocks
(LovaszThetaSparse, the word-density transfer-SDP, EpsilonCertificate.wl). (iv) The atom
acts as a *resource under composition*: one quantum pentagon activates a heptagon PR box
that identical copies provably cannot (HeptagonCatalysis.wl). (v) The currency law
CF = (n−1)·ν (kcbs_epilogue.wl) is one non-classicality currency reconstructed from
another using only the cycle's own constant 2α.

**The three boundaries.** (B1) **Composition is bond-dependent, not atom-determined.**
The cis/trans discovery (§6): the same pentagon glued two ways gives an extensive
quantum gap (trans) or *none* (cis saturates α\* classically). The atom under-determines
the molecule; the bonds carry structure the atom doesn't — the gluing-word optimum
(cct)^∞ makes that design space concrete. (B2) **The graph is a lossy projection of a
taller stack** — graph ↦ sheaf ↦ phase-space. α/ϑ/α\* capture bounds but are blind to
the possibilistic/cohomological layer: certifying strong contextuality (Wright box) and
separating models with identical supports needed the AB sheaf and the Čech obstruction
(SupportCohomology.wl), not the exclusivity graph; the harmonic/Laplacian residual is
*blind to contextuality by construction*. (B3) **Non-classicality is not monolithic,**
so one atom cannot recreate all of it: for the single qutrit, Wigner negativity and KCBS
contextuality *come apart* (the noise window (0.494, 0.585), kcbs_ledger.wl), and even
adjoining the pentagon's own phase-space parity witnesses cannot manufacture a stronger
joint violation (the metric-binding no-go, kcbs_epilogue.wl). Even the atom's quantum
bound √5 is a two-copy fact (C₅∨C₅, §5), not a clean single-graph one.

**Practical applications.** Ordered from repo-ready to research-grade:

- **Scalable graph-optimization tooling (ready now).** `LovaszThetaSparse` (chordal/Agler
  decomposition), the Z_N-symmetry DFT route, and the position-space word-density
  transfer-SDP are general large-graph ϑ solvers (10⁵–10⁶ vertices, certified), usable
  well beyond contextuality — Shannon-capacity bracketing (CaseStudies §A), Mycielskian
  chromatic bounds (§B), any sandwich-theorem problem. This is the most immediately
  reusable output.
- **Classical-simulation cost accounting.** Wigner negativity is the sampling overhead of
  classical simulation (Pashayan–Wallman–Bartlett, PRL 115, 070501); the currency law
  turns an easy LP (contextual fraction CF) into ν, i.e. into a *simulation-hardness /
  magic budget* estimate for the whole n-cycle family — practical for benchmarking and
  for resource accounting in magic-state schemes (Howard et al., Nature 510, 351:
  contextuality supplies the magic; the channel ledger prices each gate).
- **Certified randomness.** Contextuality certifies randomness; the scalable meshes yield
  *extensive* certified randomness with linearly-growing certificates rather than the
  exponential cost of a state-space treatment — a near-term device-independent-flavoured
  protocol resource.
- **Platform / hardware tests and dimension witnessing.** The circuits (encodings A/B) are
  genuine contextuality tests *when run on real gate hardware* — qutrit dimension
  witnessing and state self-testing — with the honest caveat (§3, kcbs_simulation.wl)
  that a simulator reproduces statistics, not evidential force. Hardware remains the open
  item (§9).
- **Resource activation / cryptography (speculative).** The catalysis result is a
  resource-theory primitive: individually inert copies made jointly useful by a fixed
  qutrit catalyst — the natural direction is non-locality/contextuality distillation and
  activation-based protocols.
- **Methodological: a "which certificate for which task" map.** Knowing *where* the graph
  layer is blind (B2, B3) is itself the practical payoff — it tells a practitioner to
  reach for the graph invariant for bounds and scaling, the sheaf/Čech layer for
  possibilistic/strong contextuality and paradox (AvN), and the phase-space negativity for
  simulation cost and magic, rather than expecting any one of them to answer all three.
