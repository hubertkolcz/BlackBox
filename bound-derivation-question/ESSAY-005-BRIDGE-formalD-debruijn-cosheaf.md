# ESSAY-005 BRIDGE — Formalizer D: the de Bruijn-k cellular (co)sheaf and the sub-action = 0-cochain correspondence

> **INTEGRATOR STATUS (2026-07-13, post-review):** CONSTRUCTION on the five
> materialized windows k=3,4,5,7,8 (exact `max_e σ = Γ_k` + independent Karp
> cross-check). k=6 (brief Γ_5=0.0824): two strategy-iteration seeds converged to
> 0.08235129 but the certificate did not materialize, so the independent
> cross-check is NOT yet closed. No genuine higher cohomology (graph ⇒ δ^1=0
> vacuously); the cellular-sheaf label is presentational. Master synthesis:
> `ESSAY-005-ERGODIC-BRIDGE-2026-07-13.md`.

Date: 2026-07-13. Track D3 / bridge (D). Companion to
`composition-optimality/GenerateEpsilonCertificate9.wl` (certificate structure),
`composition-optimality/CONVERGENCE-ANALYSIS-2026-07-13.md`, and
`pentagon-gluing/CaseStudies.wl` (keys `D3_epsilonCertificate`,
`posSigma`/`posCheck`).

This note formalizes the **dynamic / ergodic-optimization** certificate (the windowed
transfer-SDP ε-certificate) as a **cellular (co)sheaf on the de Bruijn-k graph with
coefficients in the (max,+) tropical semiring**, in which the sub-action `Ψ` is a
0-cochain, the certificate inequality is a twisted-coboundary bound, and `Γ_k` is the
tropical eigenvalue = the sheaf-cohomological quantity. It states the exact claim to
validate and **draws the honest line between what is a rephrasing of established
mean-payoff duality (rigorous) and what is a genuinely new sheaf statement (a modest
repackaging, no new theorem)**.

This is the cleanest likely-true bridge of the three (D/C/A): mean-payoff duality *is*
cohomological, so (D) should validate cleanly. It does — see §5.

---

## 0. Anchor-indexing warning (read first — prevents scoring against the wrong numbers)

The task brief's anchor list `Γ_3=0.1020, Γ_4=0.0953, Γ_5=0.0824, …` is **shifted one
index** relative to the actual certificates and to `CaseStudies.wl`. The authoritative
sequence (generator header, `QUANTUM_CONTEXTUALITY.md`, and the materialized certificate
files, all machine-checked here) is indexed by window size `k`:

| k | Γ_k (certified upper bound) | source file |
|---|---|---|
| 2 | 0.1666… (=1/6) | — |
| 3 | 0.1250039854 | `EpsilonCertificate_testK3_output.wl` |
| 4 | 0.1019685523 | `EpsilonCertificate_testK4_output.wl` |
| 5 | 0.0953014684 | `EpsilonCertificate_testK5_output.wl` |
| 6 | 0.0824… | (not materialized this run) |
| 7 | 0.0770623500 (=1541247/20000000) | `EpsilonCertificate.wl` |
| 8 | 0.0753085600 (=941357/12500000) | `EpsilonCertificate8.wl` |

Score any invariant against **this** table. "Γ_3 = 0.125", not 0.1020.

---

## 1. The certificate, read as raw data (established in project)

De Bruijn-k graph `X`: vertices `V` = length-`k` words over `{c,t}`; a directed edge
`e = (w → x)` whenever `drop-first(w) = drop-last(x)` (overlap of `k−1`). `|V| = 2^k`,
`|E| = 2^{k+1}`. `X` is strongly connected and every vertex has in/out-degree 2.

Per vertex `w` the certificate carries: PSD blocks `Q[w]` (5×5), `R[w]` (4×4); a closure
potential `Ψ[w] ∈ ℚ`; interface-DP potentials `Φ[φ,w]` for `φ ∈ {0,1,2}` (the three
interface-DP states `{(0,0),(1,0),(0,1)}`); and a `Strategy` picking, per source phase
`s` and edge `e`, a target phase `σ(s,e)`. Define

- **local head payoff** `d(x) = Q[x][5,5] + R[x][4,4]`  (the θ-side / Lovász-θ SDP density contribution at window `x`);
- **inner (min,+) value** `r(e) = min_{s∈{1,2,3}} ( T_ℓ[s, σ(s,e)] + Φ[σ(s,e)−1, x] − Φ[s−1, w] )`, where `ℓ = last letter of w`, `T_c,T_t` the (max,+) interface-DP transfer matrices (`dpTransfer`, with genuine `−∞` invalid-transition entries);
- **per-edge slack** `σ(e) = d(x) − r(e) + Ψ(x) − Ψ(w)`;
- `Γ_k = max_{e∈E} σ(e)`  (`CaseStudies.wl`: `GammaExact = Max[posSigma /@ edges]`).

The certified guarantee (`posCheck`) is the pair: `σ(e) ≤ Γ_k` for **all** edges, and the
worst periodic word's de Bruijn cycle-mean equals `Γ_k` up to the rationalization sliver.

---

## 2. The tropical cellular cosheaf (the new packaging)

Let `𝕋 = ℝ_max = (ℝ ∪ {−∞}, ⊕=max, ⊙=+)` be the max-plus semiring. Note `⊙` is ordinary
addition, so it is a **group** on `ℝ`; tropical "division" `a ⊘ b` is ordinary `a − b`.

**Cellular sheaf `𝓕` on `X`.** Cells: 0-cells = vertices (windows), 1-cells = edges
(transitions). Stalks `𝓕(w) = 𝓕(e) = 𝕋` (all rank-1 tropical). For an edge `e=(w→x)` the
two restriction maps are `id` (tail) and `id` (head). Cochains:

- `C^0(X;𝓕) = 𝕋^V` — a 0-cochain is exactly a **potential field** `Ψ: V → ℝ`.
- `C^1(X;𝓕) = 𝕋^E` — a 1-cochain is an **edge field** (e.g. the weight `c`).

**Coboundary.** `(δΨ)(e) := Ψ(x) ⊘ Ψ(w) = Ψ(head) − Ψ(tail)` — the ordinary graph
coboundary of `Ψ`. On a graph there is only `δ^0`; `δ^1 = 0` trivially, so `δ∘δ = 0`
holds vacuously (this is why there is no genuine higher cohomology — see §4).

**Edge-weight 1-cochain.** `c ∈ C^1`, `c(e) := d(x) − r(e)`. Everything the SDP produced
enters here; `c` is the "per-transition gap payoff". (The inner `r(e)` already contains a
*second, stacked* tropical sub-action `Φ` — see §4 caveat.)

**Twisted (weighted) coboundary / transfer operator.** Define the zero-temperature
Bousch–Ruelle transfer operator `L: C^0 → C^0`,
```
(L Ψ)(w) = max_{x : w→x} ( c(w→x) + Ψ(x) )   =   ⊕_{x} c(w→x) ⊙ Ψ(x).
```
`L` is the `⊙`-linear operator with matrix `M[w,x] = c(w→x)` (`−∞` off-edges): the
**(max,+) weighted transfer/adjacency operator of `X`**.

**The certificate inequality = a super-eigenvector bound.** Rewrite `σ(e) ≤ Γ_k`:
```
c(e) + Ψ(x) − Ψ(w) ≤ Γ_k   ∀e
⇔  c(w→x) + Ψ(x) ≤ Γ_k + Ψ(w)   ∀(w→x)
⇔  (L Ψ)(w) ≤ Γ_k ⊙ Ψ(w)   ∀w
⇔  L Ψ  ≤  Γ_k ⊙ Ψ    (Ψ is a Γ_k-SUPER-eigenvector of L).
```
So **`Ψ` is a tropical super-eigenvector (calibrated sub-action) and `Γ_k` the scalar it
certifies.** The certificate inequality is *exactly* the coboundary/consistency condition
of the tropical cosheaf: `c ⊙ δΨ ≤ Γ_k · 1` in `C^1`.

---

## 3. `Γ_k` as the tropical eigenvalue = the cohomological quantity

By the **(max,+) spectral theorem** (Cuninghame-Green; Baccelli–Cohen–Olsder–Quadrat;
Akian–Bapat–Gaubert) on the strongly connected `X`, `L` has a **unique eigenvalue**
```
λ(L) = max_{cycles C ⊆ X}  ( Σ_{e∈C} c(e) ) / |C|     (the max cycle mean of c),
```
and a tropical eigenvector `Ψ*` (the **bias vector**, computable by Karp / policy
iteration) with `L Ψ* = λ(L) ⊙ Ψ*`. Mean-payoff LP-duality gives the min–max identity
```
λ(L)  =  min_{Ψ ∈ C^0}  max_{e∈E} ( c(e) + Ψ(x) − Ψ(w) )  =  max cycle mean,
```
i.e. `Γ_k = min_Ψ ‖c ⊙ δΨ‖_∞`. The certificate's `Ψ` **attains this min** (§5:
`max_e σ = Γ_k` exactly), so `Γ_k` = tropical eigenvalue of the de Bruijn-k transfer
cosheaf, and `Ψ` = its eigenvector/sub-action.

**Cohomological reading (order-theoretic, not homological).** In the Ghrist–Riess Tarski
/ lattice-valued cellular-sheaf Hodge theory, `H^0` = global sections and the spectral
data of the tropical Laplacian carry the obstruction. Here: a *global flat section*
(`c` cohomologous to something `≤ 0`, i.e. no positive cycle) exists **iff** `λ(L) ≤ 0`.
`Γ_k` is the **minimal shift** making `c − Γ_k·1` admit a sub-action dominating it — the
tropical `H^1`-obstruction "a positive cycle exists" measured on the nose. Thus `Γ_k` is
a bona fide cohomological quantity of the tropical cosheaf, and `Ψ` a 0-cochain
witnessing it. This is the (D) statement.

---

## 4. Honest split — rigorous rephrasing vs genuinely new; category errors named

**Rigorous, and NOT new mathematics (a dictionary onto established theory).**
1. `Γ_k = max cycle mean of c` on de Bruijn-k. — Karp 1978.
2. Certificate inequality `σ(e) ≤ Γ_k` = **sub-action inequality** `c + δΨ ≤ Γ_k`; `Ψ` =
   calibrated sub-action. — Mañé–Conze–Guivarc'h / Bousch "revelation"; Jenkinson survey
   arXiv:1712.02307.
3. `Γ_k` = unique (max,+) eigenvalue of `L`, `Ψ` = bias vector / tropical eigenvector,
   with min–max duality. — Cuninghame-Green; BCOQ; Akian–Gaubert bias-vector /
   policy-iteration (arXiv:0912.2462). The project's `posCheck` is a numerically-solved
   instance of exactly this. The generator's "strategy iteration" **is** Howard/Akian–
   Gaubert policy iteration for a mean-payoff game (`CONVERGENCE-ANALYSIS` even reads the
   spurious fixed points as periodic-orbit densities — the game's other cycle means).

**Genuinely new to the project, but MODEST (a repackaging, not a theorem).**
Casting 1–3 as a **cellular (co)sheaf on de Bruijn-k with `ℝ_max` stalks** — `Ψ ∈ C^0`,
`c ∈ C^1`, certificate = twisted-coboundary bound, `Γ_k` = tropical-Laplacian /
eigenvalue invariant (Ghrist–Riess arXiv:2007.04099; Hansen–Ghrist). This is a real
change of *object*: `SH-004` pre-registered the rejection of the **real-valued** sheaf
Laplacian as a contextuality measure; the **tropical** cellular sheaf is a *distinct,
viable* object (idempotent Hodge theory, `H^0` = global sections). Its payoff is not a
new number — it produces **nothing beyond mean-payoff duality** — but two things:
(a) it upgrades `Ψ` from an ad hoc SDP potential to a genuine cohomological object
(0-cochain = tropical eigenvector), and (b) it is the **exact right-hand target for
bridge (C)**: the de Bruijn tropical cosheaf is what a `T→0` Maslov dequantization of the
static weighted-GE sheaf (P3's ℚ≥0-semimodule gluing presheaf) must limit onto.

**Category errors to avoid (the main risk).**
- **Semiring ≠ ring.** `ℝ_max` has no additive inverses ⇒ **no derived-functor /
  abelian `H^1`**. Do NOT write `H^1(X;𝓕)` as an abelian group. The cohomology here is
  order-theoretic (Tarski/lattice), and its "class" is a value in `ℝ_max`, not a torsion
  group. (Contrast `SupportCohomology.wl`, whose Čech `H^1` **is** an honest ℤ-module —
  a different object on a different presheaf.)
- **Graph ⇒ trivial higher cohomology.** All content lives in degrees 0/1 (the
  sub-action duality). Claiming a "deep" cohomological invariant overstates it.
- **Two stacked tropical problems.** `r(e)` already hides an inner (min,+) sub-action
  `Φ` on the product graph (de Bruijn-k × 3-phase interface automaton) computing the
  α-side (independence) density. The clean "0-cochain = sub-action" story is the **outer**
  one (`Ψ`, weight `c=d−r`). Honest formalization presents the outer cosheaf with `c`
  as given weights and notes `Φ` as a *second, stacked* tropical cochain — do not
  conflate the two potentials.
- **Certified bound ≠ exact eigenvalue.** The rational `Γ_k` is a certified **upper**
  bound sitting a rationalization sliver above the true max cycle mean (§5). The exact
  tropical eigenvalue is the cycle mean; `Γ_k` is its rational over-approximation.

---

## 5. Validation — the precise claim, and what was checked this run

**Claim (D).** For each window `k`, the de Bruijn-k tropical cosheaf of §2 recovers the
certificate: (i) `Ψ` is a valid sub-action, `σ(e) ≤ Γ_k` for **all** `e`; (ii) `Ψ`
attains the dual optimum, `max_e σ(e) = Γ_k` **exactly**; (iii) an **independent** Karp
max-cycle-mean of `c` equals `Γ_k` up to the rationalization sliver (`Γ_k − mcm ≥ 0`,
`< 10^{-7}`, matching `posCheck`). Together: `Γ_k` = tropical eigenvalue and `Ψ` = its
eigenvector.

**Checked this run** (pure-Python exact `Fraction`, no Wolfram; script
`scratchpad/validate_D.py`, reusing `CertificateLoader.py` + a from-scratch Karp routine),
on the five materialized certificates `k ∈ {3,4,5,7,8}`:

| k | Γ_k | max_e σ = Γ_k (exact) | σ ≤ Γ_k ∀e | Γ_k − maxcyclemean |
|---|---|---|---|---|
| 3 | 0.1250039854 | ✓ | ✓ | 2.0e-9 |
| 4 | 0.1019685523 | ✓ | ✓ | 1.7e-9 |
| 5 | 0.0953014684 | ✓ | ✓ | 1.2e-9 |
| 7 | 0.0770623500 | ✓ | ✓ | 2.5e-9 |
| 8 | 0.0753085600 | ✓ | ✓ | 1.33e-8 |

All slivers `< 1.3e-8 < 10^{-7}` (the project's `posCheck` tolerance). **The (D)
correspondence holds on every materialized window.** `k=6` was not materialized as a
certificate file; it is generated identically (`GenerateEpsilonCertificate` with `K=6`,
64 nodes / 128 edges — cheap) and must reproduce `Γ_6 ≈ 0.0824` with the same three
properties. That is the one remaining item to close the requested `Γ_3..6` set.

**Implementation validation plan (for the essay/tooling):** reproduce the table for
`k = 3,4,5,6,7,8`; the required, non-negotiable gates are (ii) exact `max_e σ = Γ_k` and
(iii) `0 ≤ Γ_k − Karp-mcm < 10^{-7}`, plus (i) the pointwise sub-action bound — i.e. the
tropical-eigenvector identity and the sub-action property, recomputed from the cosheaf
data alone. Anchors are the §0 table (NOT the shifted brief list).

---

## 6. One-line summary

`Γ_k` is the (max,+) tropical eigenvalue of the weighted transfer operator of the de
Bruijn-k graph, `Ψ` its eigenvector (Bousch calibrated sub-action) packaged as a cellular
0-cochain, and the ε-certificate inequality its coboundary bound. The mathematics is
established mean-payoff / tropical spectral duality (rigorous); the *sheaf* packaging is
new to the project but adds no new number — its worth is making `Ψ` cohomological and
supplying the concrete `T→0` target for bridge (C).
