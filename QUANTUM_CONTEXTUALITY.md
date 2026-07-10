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
lifting ϑ/L to 1.4032316(23), i.e. **gap 0.0698982 per block = 1.611× the pure-trans
gap**. Method: exact α densities as max-plus cycle means of a 3-state interface
transfer DP (exact rational arithmetic; the pure-trans staircase is its transfer
matrix's 3-cycle gaining 4 per 3 blocks); certified chordal ϑ at 1200–2400 blocks;
exhaustive sweep of all binary bracelets of period ≤ 6, and over periods ≤ 12 every
word with α-density 4/3 has cis-fraction ≤ 2/3 with equality UNIQUELY for cct (its
best higher-period rivals cctcctctt, cctcctcctctt rank strictly below). Design rule:
trans letters protect the classical bound (each t breaks the cis rail before it can
lift α), cis letters buy quantum value; the optimum is the densest cis packing α
tolerates. Refined conjecture: (cct)^∞ is globally optimal over all gluing words.
Tooling: `lovasz_theta_sparse.py words`; WL anchor wordRing/cct in CaseStudies §D3
(key D3_gluingWordOptimum).

## 7. Wigner negativity toolchain (Wolfram Community, N. Murzin)

Source: "On quantum amplitudes, correlations and negativity"
(https://community.wolfram.com/groups/-/m/t/3026423). Framework tools:
`QuantumWignerTransform`, `QuantumWeylTransform`, `QuantumPhaseSpaceTransform`,
`QuantumWignerMICTransform`. Adopted in essay §11. Open thread: track negativity flow
through the cascade gate-by-gate.

## 8. Key references

- Klyachko, Can, Binicioğlu, Shumovsky, PRL 101, 020403 (2008); arXiv:0706.0126
- Lapkiewicz et al., Nature 474, 490 (2011); arXiv:1106.4481
- Ahrens, Amselem, Cabello, Bourennane, Sci. Rep. 3, 2170 (2013); reply arXiv:1305.5529
- Kujala, Dzhafarov, Larsson, PRL 115, 150401 (2015)
- Cabello, PRL 110, 060402 (2013) ("fundamental inequality", E-principle, two copies)
- Delfosse et al., New J. Phys. 19, 123024 (2017) (negativity ⇔ contextuality, n ≥ 2)
- Budroni, Cabello, Gühne, Kleinmann, Larsson, Rev. Mod. Phys. 94, 045007 (2022)
- Gühne et al., PRA 81, 022121 (2010) (compatibility loophole)
- Markiewicz et al., npj Quantum Inf. 5, 5 (2019); Zhang et al., Sci. Rep. 7, 44467 (2017)

## 9. Open threads

- Push the repo to GitHub (blocked: gh token for `hubertkolcz` invalid; no remote yet).
- Gate-by-gate negativity flow through the cascade (Weyl/MIC transforms).
- n-cycle generalizations (C₇, C₉...) and their circuits; run encoding B on real
  gate hardware as a genuine platform test.
- Sequential-game quantum strategy demo end-to-end (Alice prefix + Bob binary POVM).
- Pentagon meshes (§6, cis/trans correction): ~~closed form for the trans-ring
  density constant~~ RESOLVED — τ\* = Root[49x³ − 128x² − 75x + 218, 2], exact KKT
  certificate in §6/CaseStudies §D3. ~~Prove ϑ(cis-ring N) = N + ϑ(C_N) and
  α(cis-ring N) = ⌊3N/2⌋~~ RESOLVED — both are theorems now (§6/§D3: subgraph
  monotonicity + one-extra-dimension representation; pentagon window counting).
  ~~Is the extensive trans gap optimal over all gluing words?~~ RESOLVED — NO:
  (cct)^∞ beats it by 61% (gap 0.0698982 per block, §6). Still open: prove the
  refined conjecture that (cct)^∞ is globally optimal (ergodic-optimization
  flavor: is the maximizing measure of gap-density supported on the cct orbit?);
  closed form for the cct density 1.4032316 (9×9 symbol KKT, mirroring the τ\*
  derivation); α-density = 4/3 ⟺ cis-fraction ≤ 2/3 characterization (verified
  p ≤ 12, unproven); analogous closed form for the trans-CHAIN density
  (numerically also → τ\*?) — unverified.
