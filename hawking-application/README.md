# hawking-application

Ledger track `HK` — "Hawking-radiation application": illustrates the framework on the classical emulatability of analogue-Hawking-radiation dynamics. **Central finding is structural and negative**: the graph-invariant machinery this whole repository is built on cannot even be posed for the Cauchy-Schwarz-type single-context witnesses real Hawking-pair experiments actually use.

## Contents

`hawking_cf_bridge.py` — bridges a published Hawking-pair CHSH value into this project's contextual-fraction language (`HK-002`). `hawking_cs_route.py` — proves the Cauchy-Schwarz witness is single-context by construction, so contextual fraction is identically zero for it at every discretization (`HK-003`, one of the essay's headline contributions). `NOTES-hawking.md`, `NOTES-hawking-2.md`, `NOTES-hawking-2-precommit-draft.md`, `NOTES-hawking-3.md` — working notes, including the still-open dispute in the primary literature over the 2016 entanglement claim (`HK-005`, explicitly out of scope to resolve here).

## Read this before extending the primary module toward Hawking radiation

`HK-003`'s structural result means the pentagon/MBQC apparatus in `certification-protocol/` and `cluster-state-realization/` cannot, as built, directly host a certification test for the Cauchy-Schwarz witness real Hawking experiments measure. Continued cluster-state engineering is real progress toward `certification-protocol/`'s own stated goal (an MBQC/optical black-box test at scale) but is not currently a path to the Hawking illustration as originally imagined — treat these as two different destinations.

## Relationship to the primary module

Independent application; not imported by `certification-protocol/`.

## Gaussian sector (emulable-side companion)

`gaussian_engine.wl` + `gaussian_hawking_physics.wl` implement **Hawking's own
1974-75 semiclassical kinematics**, discretized per frequency mode, as **exact
Gaussian / symplectic linear algebra on covariance matrices**. This is a
*parameterized-background* model: the Hawking temperature `T_H = kappa/(2 Pi)` is
an **input**, not derived from the Einstein equations; the horizon acts per
frequency as a **two-mode squeezer** with `tanh(r_w)^2 = Exp[-w/T_H]` (the
Boltzmann factor), and greybody is a beamsplitter model. Because Gaussian states
+ Gaussian operations + homodyne are classically efficiently simulable (CV
Gottesman-Knill: Bartlett & Sanders, PRA 65, 042304 (2002)), **this whole sector
sits on the EMULABLE side of the two-lens boundary** — the CV mirror of the qubit
module's Clifford status (`cluster-state-realization/`). It does **not** contradict
`HK-003`; it is the emulable-side companion to that single-context negative
result.

**Entry point — the master assembly.** `hawking_gaussian_sector.wl` loads all
three sub-modules (engine + Hawking physics + witnesses/bridge) and runs the
**unified A1–A8 scoreboard**, cross-confirming the shared anchors A1–A5, A7i
against *both* builders' gate suites and ending in the `GaussianHawkingVerification`
association with `OK -> True`. Run it with
`wolframscript -file runners/RunGaussianHawking.wl -print all`.

The covariance engine (`gaussian_engine.wl`) supplies states, symplectic ops,
Williamson symplectic eigenvalues, von Neumann entropy (nats; the bosonic
`x Log x` uses its removable value `0` at a pure eigenvalue `nu = 1/2`, so a pure
state gives entropy `0`, not `Indeterminate`), logarithmic negativity (bits),
Wick/Isserlis photon-number moments, and Hudson positivity.
The physics layer (`gaussian_hawking_physics.wl`) adds the Hawking map and the
Builder-1 gate suite, each an exact identity proved with `FullSimplify`:

- **A1 Planck spectrum** — `Sinh[r_w]^2 == 1/(Exp[w/T_H]-1)` straight from the
  engine covariance; `T_H` recovered by fitting the engine spectrum.
- **A2 entanglement = thermality** — reduced-arm `S_vN` equals the thermal
  entropy `(nbar+1)Log(nbar+1) - nbar Log nbar` (the conceptual core).
- **A3 log-negativity** — PT symplectic eigenvalue `nu_- = Exp[-2r]`,
  `E_N = 2 r/Log[2]`, closed form vs engine.
- **A4 Cauchy-Schwarz** — Wick moments reproduce `hawking_cs_route.py`'s
  `theta(nbar) = 1 + 1/(2 nbar) > 1` on the same `lambda` grid.
- **A5 Busch-Parentani** — `Delta = -Sinh[r]^2 < 0` (vacuum); analytic
  finite-temperature death threshold `n_in = (Exp[2r]-1)/2`.
- **A7i Hudson** — every engine state has `sigma + (i/2)Omega >= 0` (Gaussian
  Wigner `>= 0`), constructively confirming `HK-004`.

Run: `wolframscript -file runners/RunGaussianHawking.wl -print all` (prints the
literal gate outputs and `GaussianHawkingVerification` with `OK -> True`).
Companion-builder gates A6 (CHSH bridge), A7ii (CF = 0), A8 (CV-DLA audit) merge
into the same association.

### Witnesses, bridge, and certification (`gaussian_witnesses_bridge.wl`)

`gaussian_witnesses_bridge.wl` carries the witness / bridge / certification
anchors and is independently acceptance-tested by
`runners/RunGaussianWitnesses.wl` (also `OK -> True`). Its Section-0 engine
symbols are provided **only if undefined**, so loading `gaussian_engine.wl`
first makes every gate exercise the real engine (verified: all gates pass
against Builder 1's engine). New public symbols: `PseudospinCorrMatrix`,
`CHSHofR`, `CHSHCFofR`, `CauchySchwarzTheta`, `FactorialMomentsHP`,
`BuschParentaniDelta`, `SingleContextScenario`/`SingleContextCF`,
`CVLieClosureDim`, `CVDLAAudit`, `HawkingGenerators`.

- **A6 CHSH bridge to the qubit module** — the GKMR pseudospin correlation
  matrix is `DiagonalMatrix[{Tanh[2r], -Tanh[2r], 1}]`, the Horodecki-optimal
  `CHSH(r) = 2 Sqrt[1+Tanh[2r]^2]`, and `Limit[CHSH(r), r->Infinity] = 2 Sqrt[2]`
  — at the ceiling the TMSV realizes the qubit Bell pair of
  `cluster-state-realization/cct_mbqc_hawking_certification.wl` (`CF = Sqrt[2]-1`).
  The literature value `B = 2.25` maps to effective squeezing
  `r_eff = 0.285020` (flagged as an idealized pure-TMSV identification). The gate
  is **non-circular**: the pseudospin correlation matrix and `CHSH(r)` are
  *derived* from the truncated TMSV number-state expansion and the Horodecki
  criterion (agreement to `~1e-15`), then compared to the closed forms — it does
  not merely restate the definitions. **Binning caveat (honest boundary):** the
  GKMR parity pseudospin is **one particular dichotomization** of the
  infinite-dimensional CV pair (even/odd number-parity blocks). It is *not* the
  CV state's intrinsic nonlocality — other binnings (on/off photodetection,
  quadrature-sign / Gisin–Peres) give different `CHSH(r)` curves and generally
  weaker violation. The `2 Sqrt[2]` ceiling is specific to this binning at the
  `r -> Infinity` EPR limit; it is the natural bridge to the qubit module because
  parity is exactly the pseudospin the qubit Bell pair carries.
- **A7ii single-context CF == 0 (`HK-003`, constructive)** — the density-density
  (`n_H`, `n_P`) correlator is jointly-measured, one-context data; running the
  BlackBox paclet `ContextualFraction` on the constructed one-context empirical
  model (including the real truncated TMSV diagonal joint distribution) returns
  exactly 0, confirming the negative result of `hawking_cs_route.py` inside the
  Gaussian engine.
- **A8 CV dynamical-Lie-algebra audit** — a native-WL reimplementation of
  `certification-protocol/final_o3_cv_dla.py` (exact integer commutator
  closure). Validates `u(2)` (dim 4, passive-confined), `sp(4,R)` (dim 10,
  active), `sp(2,R)` (dim 3, active), then audits the Hawking generator set
  (phase + graybody beamsplitter + two-mode squeezer) → **dim 10 = `sp(4,R)`,
  ACTIVE**. Verdict: *"Hawking mode conversion is NOT
  passive-linear-optics-emulable, but IS Gaussian-classically-simulable"* — the
  two-tier CV statement, the exact mirror of the qubit module's Clifford status.

Run: `wolframscript -file runners/RunGaussianWitnesses.wl -print all` (standalone
Builder-2 acceptance), or the master `runners/RunGaussianHawking.wl` for the full
A1–A8 assembly.

## The two-sector bridge (the gap this module fills)

The qubit Hawking module (`cluster-state-realization/`) reaches the **information
dynamics** of black-hole evaporation — Page-curve / Hayden–Preskill scrambling on
Clifford-simulable cluster states — but it *cannot* reach Hawking's own 1974–75
**thermal/Bogoliubov** mathematics: temperature, the Planck spectrum, the
entanglement = thermality identity, and the CS/Δ nonseparability witnesses the
analogue-gravity literature actually measures. This Gaussian sector fills exactly
that gap, on the covariance-matrix side.

The two sectors **join at the `r -> Infinity` EPR limit**: the GKMR-pseudospin
discretization of the two-mode-squeezed-vacuum Hawking pair converges to the
qubit Bell pair (`CHSH -> 2 Sqrt[2]`, `CF -> Sqrt[2]-1`), the exact anchors of
`cct_mbqc_hawking_certification.wl`. And both sectors sit on the **same
(classically emulable) side** of the framework's two-lens boundary: the qubit
sector by the Gottesman–Knill theorem (Clifford), the Gaussian sector by the CV
Gottesman–Knill theorem (Gaussian states + symplectic ops + homodyne). The A8
audit sharpens the CV side to a two-tier statement — *"Hawking mode conversion is
NOT passive-linear-optics-emulable, but IS Gaussian-classically-simulable"* — the
exact mirror of the qubit module's Clifford status. **No gravity, a parameterized
background, and one pseudospin binning** are the standing honesty boundaries.

## Ledger cross-reference

`HK-001` through `HK-005` (track `HK`).
