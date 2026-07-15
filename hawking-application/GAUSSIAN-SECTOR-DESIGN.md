# GAUSSIAN-SECTOR-DESIGN.md — build spec for `hawking_gaussian_sector.wl`

**Role:** architecture / build specification. Precise enough for two independent
builders to produce byte-for-anchor-equivalent modules.
**Module being specified:** `hawking-application/hawking_gaussian_sector.wl` (main
deliverable), optional helpers `gaussian_*.wl`, runner
`runners/RunGaussianHawking.wl`, one `runners/RunAll.ps1` registration line.
**Date:** 2026-07-13. **Author:** ARCHITECT pass (this session).

---

## 0. WHAT THIS MODULE IS (honesty header — copy into the `.wl` file head verbatim)

This module implements **Hawking's own 1974–75 semiclassical kinematics**,
discretized per frequency mode, as **exact Gaussian / symplectic linear algebra
on covariance matrices**. It is NOT a derivation of black-hole radiation from the
Einstein equations. Specifically, state up front, in the file header:

- **Parameterized background.** The surface gravity `kappa`, equivalently the
  Hawking temperature `T_H = kappa/(2 Pi)`, is an **INPUT**, not derived. There is
  no dynamical spacetime, no back-reaction, no field equation solved. We take
  Hawking's result that the horizon acts, per frequency, as a **two-mode
  squeezer** between the interior (partner) and exterior (Hawking) modes, with
  squeezing fixed by `tanh(r_w)^2 = Exp[-w/T_H]` (the Boltzmann factor), and
  compute the exact downstream Gaussian consequences.
- **Graybody = beamsplitter.** Greybody/backscatter is modelled as a passive
  beamsplitter of transmissivity `eta(w)` on the exterior arm — a model, not a
  solved potential-barrier scattering problem.
- **Emulability statement (the point of the whole sector).** Gaussian states +
  Gaussian (symplectic) operations + homodyne/heterodyne detection are
  **classically efficiently simulable** — the CV Gottesman–Knill theorem
  (Bartlett, Sanders, Braunstein, Nemoto, PRL 88, 097904 (2002); Bartlett &
  Sanders, PRA 65, 042304 (2002)). Therefore **this entire Hawking sector sits on
  the EMULABLE side of the framework's two-lens boundary**, exactly mirroring the
  Clifford status of the qubit Hawking module
  (`cluster-state-realization/cct_mbqc_hawking_certification.wl`). The interesting
  content (A8) is that the *generator set* is still non-passive: genuine squeezing
  is present (active `sp(4,R)`, not passive `u(2)`), so it is **not** emulable by
  *linear/passive* optics even though it *is* Gaussian-classically simulable — the
  two-tier CV statement.

Ledger tie-ins: constructively confirms **HK-003** (single-context ⇒ CF ≡ 0, A7ii)
and **HK-004**; bridges to the qubit anchors of **HK-002** via A6.

---

## 1. ENGINE SPEC

### 1.1 Convention (FIXED — state once, never deviate)

- `hbar = 1`. Quadrature ordering per mode `(x_j, p_j)`, global vector
  `r = (x_1, p_1, ..., x_n, p_n)`. Commutator `[x_j, p_k] = i delta_{jk}`.
- **Vacuum covariance `sigma_vac = (1/2) I`** (so `Var(x)=Var(p)=1/2` in vacuum).
  This is the Weedbrook/Serafini convention. **Physicality / uncertainty:**
  `sigma + (i/2) Omega >= 0` (PSD), equivalently every Williamson symplectic
  eigenvalue `nu_k >= 1/2`.
- Covariance definition `sigma_{ab} = (1/2) <{ Dr_a, Dr_b }>` with
  `Dr = r - <r>`, `{,}` the anticommutator. A Gaussian state is `(sigma, mean)`.
- **Symplectic form** (one 2x2 block per mode):
  `Omega = BlockDiagonalMatrix[ Table[ {{0,1},{-1,0}}, n ] ]`.
  A symplectic `S` obeys `S . Omega . Transpose[S] == Omega`. Action on a state:
  `sigma -> S . sigma . Transpose[S]`, `mean -> S . mean`.

> The two anchor formulas A2 and A3 are quoted in the task in two *different*
> textbook normalizations. Under the single convention above they reconcile
> cleanly — see A2/A3 below. Do not introduce a second convention to satisfy A3.

### 1.2 Symplectic operator set (all exact, symbolic entries)

Let `I2 = IdentityMatrix[2]`, `Zx = {{1,0},{0,-1}}`, `c = Cosh[r]`, `s = Sinh[r]`.
Build these as functions returning `2n x 2n` (or `2x2` / `4x4`) exact matrices:

| op | matrix (mode-local blocks) | class |
|---|---|---|
| `TwoModeSqueezer[r]` (2 modes) | `{{c I2, s Zx},{s Zx, c I2}}` | ACTIVE |
| `SingleModeSqueezer[q]` (1 mode) | `DiagonalMatrix[{Exp[-q], Exp[q]}]` | ACTIVE |
| `Beamsplitter[theta]` (2 modes) | `{{Cos[theta] I2, Sin[theta] I2},{-Sin[theta] I2, Cos[theta] I2}}`; transmissivity `eta = Cos[theta]^2` | passive |
| `PhaseRot[phi]` (1 mode) | `{{Cos[phi],Sin[phi]},{-Sin[phi],Cos[phi]}}` | passive |
| `ThermalState[nbar]` (1 mode) | covariance `(nbar + 1/2) I2`, mean `0` | state |
| `VacuumState[n]` | `(1/2) IdentityMatrix[2 n]` | state |
| `EmbedSymplectic[S, modes, n]` | place a k-mode `S` on `modes` inside an n-mode identity | util |
| `ApplySymplectic[S, {sigma,mean}]` | `{S.sigma.Transpose[S], S.mean}` | util |
| `PartialTrace[{sigma,mean}, keep]` | select rows/cols of `keep` modes (Gaussian partial trace = submatrix) | util |
| `TensorState[st1, st2]` | block-diagonal `sigma`, stacked `mean` | util |

Check on construction (assertion inside runner, not in the loadable defs):
`TwoModeSqueezer[r] . VacuumState[2]sigma . Transpose[...] ==`
`(1/2){{Cosh[2r]I2, Sinh[2r]Zx},{Sinh[2r]Zx, Cosh[2r]I2}}` via `FullSimplify`.

### 1.3 Williamson / symplectic eigenvalues

`SymplecticEigenvalues[sigma_]` := positive half of `Abs[Eigenvalues[I Omega . sigma]]`.
The spectrum of `I Omega.sigma` is `{+/- nu_k}`; return the `nu_k >= 0`, sorted.
Physicality: all `nu_k >= 1/2`. **Where algebraic, prove with `FullSimplify`, not
numerics** (e.g. reduced TMSV arm ⇒ single `nu = nbar + 1/2` exactly).

### 1.4 Entropy / negativity / witness formulas

- **Bosonic g-function** (natural log ⇒ **nats**, to match anchor A2's `Log`):
  `gNats[nu_] := (nu + 1/2) Log[nu + 1/2] - (nu - 1/2) Log[nu - 1/2]`.
  `VonNeumannEntropy[sigma_] := Total[ gNats /@ SymplecticEigenvalues[sigma] ]`.
- **Log-negativity** (bits, `Log2`, to match A3). Partial transpose on mode 2 =
  `P = DiagonalMatrix[{1,1,1,-1}]`, `sigmaPT = P . sigma . P`. Let
  `nuMinusTilde = Min[SymplecticEigenvalues[sigmaPT]]`. Define the A3 quantity
  `nuMinus = 2 nuMinusTilde` (the "normalized" smallest PT eigenvalue), then
  `LogNegativity = Max[0, -Log2[nuMinus]]`. For TMSV this gives
  `nuMinusTilde = (1/2)Exp[-2r]`, `nuMinus = Exp[-2r]`,
  `LogNegativity = Max[0, -Log2[Exp[-2r]]] = 2 r / Log[2]` — matching A3's
  `nu- = Exp[-2r], E_N = Max[0,-Log2[nu-]]` exactly.
- **Wigner positivity check (A7i):** a Gaussian state has a Gaussian (hence
  non-negative) Wigner function iff `sigma` is a valid covariance, i.e.
  `PositiveSemidefiniteMatrixQ[ sigma + (I/2) Omega ]` — state this equivalence and
  verify it, do not compute a Wigner integral.

### 1.5 Photon-number moments from the covariance (needed for A4, A5)

For a zero-mean Gaussian state, all photon-number moments follow from `sigma` by
Wick/Isserlis. Provide:
- `MeanN[sigma, j] := (sigma[[2j-1,2j-1]] + sigma[[2j,2j]])/2 - 1/2` (= `nbar_j`).
- `NumberCovariance` / factorial moments via Wick, OR — since every reduced arm
  here is thermal — use the exact thermal identities and cross-check numerically
  against a Wick expansion: for a thermal marginal, `<n(n-1)> = 2 nbar^2`,
  `Var(n) = nbar(nbar+1)`; for the TMSV pair, `<n_H n_P> = 2 nbar^2 + nbar`.
  These are the A4 targets (see §4, A4).

### 1.6 Homodyne update (OPTIONAL — include only if time permits)

Homodyne of quadrature `x` on mode `k`: standard Gaussian conditional-covariance
update `sigma_A' = sigma_A - sigma_{AB} (Pi sigma_B Pi)^MP sigma_{BA}` with
`Pi = diag(1,0)` and `^MP` the Moore–Penrose pseudoinverse. Not required by any
anchor; ship only behind a flag.

---

## 2. THE HAWKING MAP

### 2.1 Per-frequency Bogoliubov = a two-mode squeezer

For horizon frequency `w > 0` with `T_H = kappa/(2 Pi)`:
```
tanh(r_w)^2 == Exp[-w/T_H]     =>   r_w = ArcTanh[ Sqrt[Exp[-w/T_H]] ]
```
`HawkingSqueezing[w, TH] := ArcTanh[Sqrt[Exp[-w/TH]]]`. The interior/exterior mode
pair is `ApplySymplectic[ TwoModeSqueezer[r_w], VacuumState[2] ]` ⇒ a TMSV. The
exterior-arm occupation is `nbar(w) = Sinh[r_w]^2`, which reduces to the **Planck
spectrum** — this is anchor A1 (proof in §4).

### 2.2 Multi-frequency assembly

Given a frequency grid `ws = {w_1,...,w_m}`: build `m` independent TMSV pairs and
assemble block-diagonally (`no Join in loop` — use `Table` + `ArrayFlatten` /
`SparseArray`, or fold `TensorState`). Mode layout: interleave
`(interior_i, exterior_i)` per frequency, or keep two registers — document the
chosen layout in the header. Each frequency is independent (Hawking's modes do not
couple across `w`), so the global `sigma` is exactly block-diagonal.

### 2.3 Graybody

Exterior arm `i` passes through `Beamsplitter[theta_i]` mixing with an ancilla
(vacuum for a pure environment, or `ThermalState[n_env]` for a warm one),
`eta_i = Cos[theta_i]^2` the transmissivity. Trace out the ancilla afterwards.
This degrades `E_N` and can push `Delta` (A5) across zero — reuse for the A5
thermal-input study.

---

## 3. GKMR PSEUDOSPIN CORRELATORS ON THE TMSV (for A6)

**Goal:** closed forms connecting the TMSV to the qubit-side CHSH anchor
(`2 Sqrt[2]`) as `r -> Infinity`, and a finite-`r` CHSH(r) curve.

**Pseudospin operators (Chen–Pan–Hou–Zhang, PRL 88, 040406 (2002); the "GKMR"
dichotomic observables of Ciliberto et al. 2024, arXiv:2404.16497).** On Fock
space, with `s_- = Sum_m |2m><2m+1|`, `s_+ = s_-^dag`, `s_z = Sum_m (|2m+1><2m+1| -
|2m><2m|)`, and `s_x = s_+ + s_-`, `s_y = -I (s_+ - s_-)`; each has eigenvalues
`+/-1` (a genuine dichotomic, incompatible-with-number observable — this is what
manufactures the second context CHSH needs; see NOTES-hawking-3 §2).

**Derivation route (DERIVE, then verify symbolically).** On
`|TMSV> = Sqrt[1-lam^2] Sum_n lam^n |n,n>`, `lam = Tanh[r]`, using `c_n =
Sqrt[1-lam^2] lam^n` and `s_+|even>=|.+1>, s_-|odd>=|.-1>` (else 0), the only
nonzero two-mode ladder correlators are
```
<s1_+ s2_+> = <s1_- s2_-> = lam/(1 + lam^2)       (geometric sums, closed form)
<s1_+ s2_-> = <s1_- s2_+> = 0
```
Hence the full pseudospin correlation matrix `T_ps[i,j] = <s1_i s2_j>`,
`i,j in {x,y,z}`, is **diagonal**:
```
<s1_x s2_x> =  2 lam/(1+lam^2) =  Tanh[2 r]
<s1_y s2_y> = -2 lam/(1+lam^2) = -Tanh[2 r]
<s1_z s2_z> =  1                                  (perfect number-parity corr.)
=>  T_ps = DiagonalMatrix[{ Tanh[2r], -Tanh[2r], 1 }]
```
The identity `2 Tanh[r]/(1+Tanh[r]^2) == Tanh[2 r]` is exact (verified this
session with `FullSimplify`/`Rewrite->Exp`). **This is the key closed form; prove
it with `FullSimplify`, not numerics.**

**CHSH (Horodecki optimal over measurement angles).** For a diagonal correlation
matrix the optimal CHSH is `S = 2 Sqrt[t1^2 + t2^2]` (two largest of `|t_i|`).
Here `{|t_i|} = {1, Tanh[2r], Tanh[2r]}`, two largest `{1, Tanh[2r]}`:
```
CHSH(r) = 2 Sqrt[ 1 + Tanh[2 r]^2 ]
```
- `r -> Infinity`: `Tanh[2r] -> 1`, `CHSH -> 2 Sqrt[2]` — **the A6 bridge to the
  qubit anchor** (`cct_mbqc_hawking_certification.wl`: CHSH `2 Sqrt[2]`,
  CF `Sqrt[2]-1`). At the ceiling the TMSV literally realizes a qubit EPR pair.
- Place on the CF scale via `CCTCFofS[s] = Max[0,(s-2)/2]` (the qubit module's
  own function, or `hawking_cf_bridge.py`): `CF(r) = Max[0, Sqrt[1+Tanh[2r]^2]-1]`.
- **Literature `B = 2.25` ⇒ effective squeezing (A6, numeric).** Solve
  `2 Sqrt[1+Tanh[2r]^2] == 2.25` ⇒ `Tanh[2 r_eff] = 0.515388...`,
  `r_eff = 0.285020...` (verified this session). Report as an **idealized
  identification** (a pure-TMSV-with-optimal-angles reading of a value that
  Ciliberto et al. compute on a genuine multimode/thermal Bogoliubov state) — flag
  it, do not claim it is the actual state's squeezing.

---

## 4. EXACT API + VALIDATION PLAN (per anchor)

**Module discipline (project law).** Loadable module = **definitions only**; guard
`If[!TrueQ[GaussianHawkingLoadOnly], <self-check>]`. All tests / assertions live
behind the runner. No `Join`-in-loop. Exact symbolic where marked; the anchors
below are **identities** — prove with `Simplify`/`FullSimplify`. End the run in an
association `GaussianHawkingVerification` whose `"OK" -> True` iff every gate
passes. `wolframscript` via Bash, forward slashes; `<= 2` kernels; `<= 8` min.

Public API (top-level symbols; names are the contract for both builders):
`VacuumState, ThermalState, TwoModeSqueezer, SingleModeSqueezer, Beamsplitter,
PhaseRot, ApplySymplectic, EmbedSymplectic, PartialTrace, TensorState,
SymplecticEigenvalues, VonNeumannEntropy, LogNegativity, MeanN, HawkingSqueezing,
HawkingPair, HawkingSpectrum, PseudospinCorrMatrix, CHSHofR, BuschParentaniDelta,
CVLieClosureDim, GaussianHawkingVerification`.

### A1 — Planck spectrum (symbolic + numeric fit)
- **Symbolic:** with `tanh(r_w)^2 = Exp[-w/TH]`, prove
  `FullSimplify[ Sinh[HawkingSqueezing[w,TH]]^2 == 1/(Exp[w/TH]-1) ]` ⇒ `True`
  (assume `w>0, TH>0`). Also verify `nbar` read from the engine covariance
  (`MeanN` of the exterior arm of `HawkingPair[w,TH]`) equals the same.
- **Numeric:** over a grid `ws`, extract `nbar_i` from the engine, form
  `y_i = Log[1 + 1/nbar_i] = w_i/TH`, linear-fit slope ⇒ recover `TH`; gate
  `Abs[TH_fit - TH_in] < 10^-8`.

### A2 — Entanglement entropy = thermal entropy (symbolic)
Reduced arm `sigmaA = PartialTrace[HawkingPair, {exterior}]` has one symplectic
eigenvalue `nu = nbar + 1/2` (prove). Then prove BOTH forms equal
`VonNeumannEntropy[sigmaA]`:
`Cosh[r]^2 Log[Cosh[r]^2] - Sinh[r]^2 Log[Sinh[r]^2]` and, in `nbar`,
`(nbar+1) Log[nbar+1] - nbar Log[nbar]`. Use `FullSimplify` with
`nbar -> Sinh[r]^2`. Natural log (nats). This is the **entanglement = thermality**
identity — flag it as the conceptual core.

### A3 — Log-negativity (exact closed form vs engine)
Prove `Min[SymplecticEigenvalues[sigmaPT]] == (1/2)Exp[-2r]` ⇒
`LogNegativity[TMSV] == 2 r/Log[2]`, and equals `Max[0,-Log2[Exp[-2r]]]`.
Symbolic identity, `FullSimplify`.

### A4 — Cauchy–Schwarz cross-anchor to `hawking_cs_route.py`
From the engine covariance derive (Wick) the factorial moments and reproduce the
committed Python reference numbers: `Gamma_HH = Gamma_PP = 2 nbar^2`,
`Gamma_HP = 2 nbar^2 + nbar`, `theta = Gamma_HP/Sqrt[Gamma_HH Gamma_PP] =
1 + 1/(2 nbar) > 1` (symbolic), diverging as `nbar->0+`, `-> 1+` as
`nbar->Infinity` (match `hawking_cs_route.py` §2 / its summary line
`theta(nbar)=1+1/(2 nbar)`). Numeric table over the same `lam in
{0.05,0.2,0.4,0.6,0.8}` used there; gate agreement `< 10^-6`.

### A5 — Busch–Parentani nonseparability + finite-T death (symbolic threshold)
`BuschParentaniDelta` = `<bH^dag bH><bP^dag bP> - Abs[<bH bP>]^2` from the
engine's second moments. **Vacuum input:** prove `Delta == -Sinh[r]^2 < 0` for all
`r>0` (always nonseparable — Steinhauer 2016 criterion). **Thermal input**
(`ThermalState[n_in]` into each squeezer port): prove the analytic threshold
```
Delta < 0   <=>   n_in < (Exp[2 r] - 1)/2 .
```
(Both roots of `Delta==0` are `{ (Exp[2r]-1)/2, (Exp[-2r]-1)/2 }`; the positive one
is the physical threshold — verified this session.) As `r->0` the threshold `-> 0`:
**violation death at finite temperature / weak pairing** — the fragility
Ciliberto et al. (2404.16497) report qualitatively. Gate: symbolic `Delta(crit)==0`
and a numeric sign-flip table across `n_in`.

### A6 — r→∞ bridge to the qubit module (symbolic limit + finite-r table)
Prove `PseudospinCorrMatrix[r] == DiagonalMatrix[{Tanh[2r],-Tanh[2r],1}]` and
`CHSHofR[r] == 2 Sqrt[1+Tanh[2r]^2]`, `Limit[CHSHofR[r], r->Infinity] == 2 Sqrt[2]`.
Tabulate `CHSH(r)`, `CF(r)=Max[0,(CHSH-2)/2]` on a grid. Numeric: `r_eff` for
`B=2.25` ⇒ `0.285020` (gate `< 10^-5`). Cross-check `CHSHofR` and CF against
`cct_mbqc_hawking_certification.wl` anchors (`2 Sqrt[2]`, `Sqrt[2]-1`).

### A7 — Scope confirmations (constructive)
- **(i) Hudson / Wigner positivity:** for every state the engine produces
  (`HawkingPair`, graybody output, thermal-input case) assert
  `PositiveSemidefiniteMatrixQ[ sigma + (I/2) Omega ]` (⇒ Gaussian ⇒ non-negative
  Wigner). State the equivalence in the header; confirms HK-004 constructively.
- **(ii) Single-context CF blindness (HK-003):** the CS / Delta witnesses are
  jointly-measured single-context data. Build the one-context empirical model (the
  diagonal TMSV joint number distribution, as in `hawking_cs_route.py` §1) and run
  the paclet `ResourceFunction`/`ContextualFraction` (or the repo's LP) on it ⇒
  expect **exactly 0**. Gate `Abs[CF] < 10^-9`. Confirms HK-003.

### A8 — G7-CV DLA audit ON this module's dynamics (reimplement in WL)
Reimplement the tiny commutator-closure of `certification-protocol/
final_o3_cv_dla.py` natively in WL (do NOT shell to Python). Generators
`K = Omega . G` from quadratic Hamiltonians `H=(1/2) r^T G r`; `LieClosure` by
iterated commutators to a fixed point; `dim` via matrix rank (exact). Cross-check
the three validated cases:
```
(i)   phase + beamsplitter, 2 modes            -> dim 4  = u(2)      PASSIVE-CONFINED
(ii)  (i) + two-mode squeezer, 2 modes         -> dim 10 = sp(4,R)   ACTIVE
(iii) single-mode squeezer + phase, 1 mode     -> dim 3  = sp(2,R)   ACTIVE
```
Run the audit on **this module's own two-mode-squeezer generator set** ⇒ must come
out **ACTIVE, dim 10 (sp(4,R), not u(2))**. Verdict sentence for the blueprint
(put in the header + verification association):
> "Hawking mode conversion is NOT passive-linear-optics-emulable, but IS
> Gaussian-classically-simulable" — the exact CV mirror of the qubit module's
> Clifford status.

### Final verification object
```wolfram
GaussianHawkingVerification = <|
  "A1_Planck" -> ..., "A2_EntEqThermal" -> ..., "A3_LogNeg" -> ...,
  "A4_CauchySchwarz" -> ..., "A5_BuschParentani" -> ..., "A6_CHSHbridge" -> ...,
  "A7i_Hudson" -> ..., "A7ii_CFzero" -> ..., "A8_DLAactive" -> ...,
  "OK" -> (* AND of all gates *) |>
```
`"OK" -> True` is the single acceptance criterion the runner prints last.

---

## 5. FILE / RUNNER LAYOUT (hard-rule compliant)

- `hawking-application/hawking_gaussian_sector.wl` — main, Get-loadable, defs only,
  self-check guarded by `GaussianHawkingLoadOnly`.
- optional `hawking-application/gaussian_engine.wl`, `gaussian_pseudospin.wl`,
  `gaussian_cv_dla.wl` — split helpers, same load-guard discipline. (Prefix
  `gaussian_`.)
- `runners/RunGaussianHawking.wl` — sets `GaussianHawkingLoadOnly=False` (or Gets
  then calls a `RunAllGates[]`), prints `GaussianHawkingVerification`.
- `runners/RunAll.ps1` — append ONE registration line for the new runner.
- Append a short section to `hawking-application/README.md` describing the Gaussian
  sector (does NOT touch the existing HK-003 negative-result framing; this sector
  is the *emulable-side* companion, not a contradiction of it).

**Do NOT** touch `optical-synthesis/` (concurrent workflow). **No cloud
calls.** Seat contention ("activate the product") ⇒ wait 60s, retry.

---

## 6. NOTES FOR BUILDERS (pitfalls)

1. **Two normalizations in the anchors.** A2's `g`-function is the `nu>=1/2`
   convention; A3's `nu-=Exp[-2r]` looks like a `nu>=1` convention. §1.4 shows both
   are consistent under `sigma_vac=I/2` once `nuMinus := 2 * min-PT-eigenvalue`.
   Do not switch conventions midstream.
2. **`Tanh[2r]` identity is load-bearing** for A6; if `FullSimplify` stalls, use
   `Rewrite[..., Exp]` then `Simplify` (confirmed to close this session).
3. **Factorial moments (A4)**: each TMSV arm is *thermal*, so
   `<n(n-1)> = 2 nbar^2` exactly — but derive it from the covariance via Wick and
   *check* against that closed form, so A4 genuinely tests the engine, not the
   algebra.
4. **A5 sign of `<bH bP>`** depends on the squeezer phase; `Delta` uses
   `Abs[.]^2`, so the phase is irrelevant — but keep the convention consistent with
   the covariance you built in §1.2.
5. **A8 exact arithmetic**: DLA dimensions are integers; use exact rationals
   (`Omega`, `G` integer-valued), rank over exact matrices — no tolerances.
6. **Perfect `<s_z s_z>=1`** is correct (number-parity is perfectly correlated on
   `|n,n>`); the r-dependence lives entirely in the `x,y` block. Don't "fix" it.
