# ESSAY-005 — Bridge C: the tropical-limit / Maslov-dequantization spec

> **INTEGRATOR STATUS (2026-07-13, post-review):** PARTIAL. Within-side leg holds
> numerically (`F_K(β) → Γ_K`, K=3,4,5). The STRONG cross-side bridge (dynamic
> `Γ_K` = T→0 limit of the static GE LP `S_k`) is REFUTED as an identity — a
> category error: the static T→0 falsifier returns the packing number `S(C5)→5/2`,
> not any `Γ_K`, and does not select `cct`. Recorded as an OBSTRUCTION, not an
> achievement. Do NOT cite "connect the two cohomologies via one dequantization"
> as done. Master synthesis: `ESSAY-005-ERGODIC-BRIDGE-2026-07-13.md`.

**Formalizer C. Date 2026-07-13.** Companion to `composition-optimality/GenerateEpsilonCertificate9.wl`,
`CONVERGENCE-ANALYSIS-2026-07-13.md`, `pentagon-gluing/CaseStudies.wl` (keys `D3_*`),
and the static side `bound-derivation-question/essay005_p3_gluing_lp.wl`.

This note defines a temperature-`T` (inverse temperature `β = 1/T`) free-energy softening of the
windowed transfer certificate as a **Ruelle transfer operator**, states the **exact numerically
testable** zero-temperature-limit claim with its anchors, identifies the visibility family `V` as a
function of temperature, and settles honestly whether the maximizing word `cct` is the `T→0`
equilibrium state and where **Bousch–Mairesse** finiteness-property failure could break the bridge.

## 0. Verdict up front (read this before the math)

- **TRUE, testable, and the deliverable core (leg D-adjacent).** The dynamic certificate value
  `Γ_K` on the de Bruijn-`K` graph is *exactly* a topological-pressure zero-temperature limit of a
  genuine `(+,×)` Ruelle transfer operator: `(1/β) log ρ(T_β) ↓ Γ_K` as `β→∞`. This is the Maslov
  dequantization of the certificate's own `(max,+)` transfer matrix. It is a repackaging of classical
  theorems (Perron eigenvalue of `exp(βA)` → max cycle mean; Baraviera–Leplaideur–Lopes pressure →
  ergodic optimization) — new only as *this project's* framing. It reproduces the project's `Γ_K`
  anchors and needs no new mathematics to test.
- **CONJECTURE with a probable OBSTRUCTION (leg C proper).** The stronger claim that the *dynamic*
  `Γ_K` is the zero-temperature limit of the *static* GE weighted-sheaf LP (value `S_k`) is most
  likely a **category error**: the two LPs live on different graphs (de Bruijn `{c,t}` words vs
  conormal powers of `C₅`), and the static side has no shift/ergodic average (finite `k` copies, not
  an orbit length `→∞`). Each side dequantizes *its own* operator; there is no evident operator
  homomorphism carrying one to the other. §7 states this obstruction precisely and gives a numerical
  falsifier. Per project ethos, a clean obstruction is a result.
- **Selection is fragile even where the value is robust.** The *value* leg (`Γ_K → gap(cct)`)
  converges regardless. Whether the `T→0` equilibrium *measure* selects `δ_cct` is **open** and is
  exactly where the observed **orbit-crowding** (a dense family of near-optimal periodic words) can
  trigger Bousch–Mairesse non-selection / non-convergence (§6).

Labels used throughout: **[proj]** established in-project, **[lit]** established in literature,
**[new]** my new claim/packaging, **[conj]** conjecture / plausible-but-unproven.

## 1. The two objects (kept formally separate on purpose)

**Static side (probabilistic, `(+,×)`), `essay005_p3_gluing_lp.wl`.** For `k` copies of `G`,
`S_k(G)` is the exclusivity/fractional-packing LP on the `k`-fold conormal product:
`max Σ_v p_v` s.t. `Σ_{v∈K} p_v ≤ 1` for every maximal clique `K`, `p ≥ 0`. Anchors **[proj]**:
`S₁(C₅)=5/2`, `S₂(C₅)=5` (per-copy `√5`); negative control `S_k(C₇)=7/2` flat for `k=1,2,3`. This is
an LP value over the `[0,1]`-semimodule `(ℝ₊,+,×)`; its dual is a fractional clique cover
(a Čech 0-cochain).

**Dynamic side (tropical, `(max,+)`), the windowed certificate.** Maximize the per-block gap density
`gap(w) = θ̄(w) − ᾱ(w)` over the shift `{c,t}^ℤ`. On the de Bruijn-`K` graph (nodes = length-`K`
words, edges = length-`K+1` overlaps) the certificate returns
`Γ_K = ` (max cycle mean) `= ` tropical `(max,+)` eigenvalue of a weighted adjacency, with the
per-edge inequality
```
    σ(e) = d(x) − r(e) + ψ(x) − ψ(w) ≤ Γ_K          (edge e: w → x)
```
a **Bousch sub-action** inequality: `ψ` is the sub-action (bias / `(max,+)` eigenvector), and
`ψ(x) − ψ(w)` is a coboundary along the shift transition **[proj]**. Anchors (machine-checked,
`CONVERGENCE-ANALYSIS-2026-07-13.md`, code header of `GenerateEpsilonCertificate9.wl`):

| de Bruijn window `K` | `Γ_K` (certified upper bound) |
|---|---|
| 3 | `0.125` (exactly `1/8`) |
| 4 | `0.10196412702492699` |
| 5 | `0.0952971530959493` |
| 7 | `0.0770206` |
| 8 | `0.0752664` |
| 9 | `0.0720260` |
| 10 | `0.0714575` |

`Γ_K ↓ gap(cct) = 0.0698975` monotonically (achieved lower bound `= cctDensity − 4/3`,
`cctDensity ≈ 1.40323087`). Extremal orbits: pure-**cis** density `3/2` (exact),
pure-**trans** density `τ* = Root[49x³−128x²−75x+218, 2] = 1.37671774591586`.

> **Indexing caution (risk, must resolve before validation).** The task-memory anchor list
> `Γ₃=0.1020, Γ₄=0.0953, Γ₅=0.0824` is shifted by one relative to the code/convergence-doc
> indexing, where **`Γ₄ = 0.10196…`, `Γ₅ = 0.09530…`, `Γ₃ = 1/8`**. The unambiguous index is the
> **de Bruijn window size `K`** (the object the code actually builds). Validate against `K`, not
> against a label. Primary anchors below are stated as `K=3,4,5`.

## 2. The dynamic transfer operator and its Maslov quantization  [new packaging of lit]

Let `A^{(K)}` be the **weighted de Bruijn-`K` adjacency** with real entries
`A^{(K)}_{w→x} = g(w→x)` = the certificate's per-edge gap payoff (the `d(x) − r(e)` term net of the
interface DP; extracted verbatim from `dpTransfer` + the `d`-block of the loaded certificate in
`GenerateEpsilonCertificate9.wl`), and `A^{(K)}_{w→x} = −∞` for forbidden overlaps. Write
`λ_⊕(A) =` max cycle mean `=` tropical `(max,+)` eigenvalue. Then **[proj/lit]**
```
    λ_⊕(A^{(K)}) = Γ_K.
```

**Maslov quantization at inverse temperature `β`.** Define the nonnegative matrix
```
    (T_β)_{w→x} = exp( β · A^{(K)}_{w→x} ),        with  exp(β·(−∞)) := 0.
```
`T_β` is the `(+,×)` Ruelle transfer operator for the local potential `β·g` on the SFT of gluing
words. `T_β` is nonnegative and irreducible (de Bruijn graph strongly connected), so it has a Perron
eigenvalue `ρ(T_β) > 0`. Equivalently `ρ(T_β) = e^{P(β·g)}` with `P` the **topological pressure**.
`T = 1/β` is the temperature; `exp` is the Litvinov–Maslov quantization map, `A ↦ T_β`, whose
dequantization `(1/β) log(·)` sends `⊗ ↦ +`, `⊕ ↦ max` as `β→∞` **[lit]**.

- **Finite `T` (finite `β`): a probabilistic / GE-style object.** `(1/β) log ρ(T_β) = P(β·g)/β` is
  the free energy per block of the Gibbs measure `μ_β` on gluing words with weights
  `∝ exp(β · Σ g)`. This is an ordinary `(+,×)` transfer-operator / statistical-mechanics quantity —
  the same *kind* of object as a softened packing/partition function.
- **`T→0` (`β→∞`): the tropical certificate.** By the Perron/Maslov limit **[lit]**
  ```
      (1/β) log ρ(T_β)  →  λ_⊕(A^{(K)}) = Γ_K,
  ```
  and the convergence is **monotone from above** with finite-temperature correction
  `(1/β) log ρ(T_β) − Γ_K = O( (log m_K)/β )`, `m_K` = number of near-maximal cycles. In pressure
  language `lim_{β→∞} P(β g)/β = max_μ ∫ g dμ =` the ergodic-optimization value `= Γ_K`
  (Baraviera–Leplaideur–Lopes; Jenkinson survey arXiv:1712.02307) **[lit]**.

This makes precise the requested statements (i)/(ii): at finite `T` a probabilistic Ruelle operator,
and `Γ_K` = topological-pressure zero-temperature limit.

## 3. The exact numerically testable claim + anchor  [new]

> **Claim C-lim.** With `A^{(K)}`, `T_β = exp(β A^{(K)})`, `ρ =` Perron spectral radius:
> ```
>     F_K(β) := (1/β) log ρ(T_β)   is decreasing in β  and   lim_{β→∞} F_K(β) = Γ_K.
> ```
> **Anchors it must hit (de Bruijn window `K`):**
> `F_3(∞) = 1/8 = 0.125` exactly; `F_4(∞) = 0.10196412702492699`;
> `F_5(∞) = 0.0952971530959493`. (Optional stretch: `F_7(∞)=0.0770206`.)

**Test protocol (all local; Python `numpy.linalg.eig` or `scipy`, or WL `Eigenvalues`; no cloud,
no SDP — cheap):**
1. Build `A^{(K)}` for `K=3,4,5` by reusing the exact `dpTransfer` + `d`-block edge payoffs already
   in `GenerateEpsilonCertificate9.wl` (do **not** re-derive the payoff; transcribe it). Cross-check
   `λ_⊕(A^{(K)})` (max cycle mean via Karp / a `(max,+)` power iteration) equals the documented `Γ_K`
   **before** touching `β` — this is the gate that the payoff was transcribed correctly.
2. For `β ∈ {10, 20, 40, 80, 160, 320}` form `T_β = exp(β A^{(K)})` (set `−∞`→`0`), compute
   `ρ(T_β)` (largest-magnitude eigenvalue; Perron guarantees it is real positive), and
   `F_K(β) = log ρ / β`.
3. **Pass criteria:** (a) `F_K(β)` monotone decreasing; (b) `F_K(β) → Γ_K` with residual `≤ C/β`;
   (c) extrapolated limit matches the anchor to the documented digits (`1/8` exactly for `K=3`;
   `1e-6` for `K=4,5`). Numerical guard: at large `β`, `exp(β A)` overflows — factor out
   `exp(β·max A)` (i.e. eigen-decompose `exp(β(A − maxA))` and add `maxA` back) so the computation
   stays in range; this is standard log-sum-exp stabilization and does not change `F_K`.

A **[proj]** consistency check that this is the right operator: the certificate already records
"the worst periodic word's de Bruijn cycle mean `= Γ` (periodic attainment)" (`CaseStudies.wl`
D3 block). At `β→∞` the Gibbs measure concentrates on exactly that maximal cycle, so `F_K(∞)` and the
periodic-attainment value must coincide — they do, both `= Γ_K`.

## 4. Visibility `V` as (a function of) temperature  [conj, calibratable]

The visibility/noise family `V` (CF-004) interpolates classical `→` quantum `→ α*` by mixing signal
with white noise: `ρ_V = V·ρ_ideal + (1−V)·(noise)`, correlations scaling with `V`. The structural
identification:

```
    V = 1  (noiseless, extremal α* point)   ⟷   T = 0  (β = ∞):  ground state / ergodic-optimization regime, Γ_K
    V < 1  (noisy)                          ⟷   T > 0  (β < ∞):  positive-temperature Gibbs / probabilistic-GE regime
```

Noise `(1−V)` plays the role of temperature: it *softens* the hard `max` into a Gibbs average over
sub-optimal configurations, exactly as finite `β` does. A concrete monotone dictionary
`T = h(V)` with `h(1)=0`, `h` decreasing — to be **calibrated against the anchors**, not assumed:
- simplest: `T = 1 − V`, i.e. `β = 1/(1−V)`;
- log-scaled (matches the `O((log m)/β)` correction rate to the value floor):
  `β = −c · log(1 − V)`, so `V→1` gives `β→∞` and `F_K(β(V)) → Γ_K`.

The calibration `[conj]`: pick `h` so that the `F_K(β(V))` curve reproduces the *measured* visibility
dependence of the KCBS/gap value along the `V`-family. This is falsifiable — if no monotone `h`
reconciles the two, the `V`-as-temperature identification is wrong on the dynamic side and only
survives (if at all) on the static side (§7). **Flag:** the `V`-family was built on the *static*
KCBS side; asserting the *same* `V` is the dynamic temperature is precisely the unproven cross-side
leap of §7 — keep `V`-as-temperature separate for each side until §7's obstruction is resolved.

## 5. Where the free energy lives (finite-`T` interpretation)  [new]

`F_K(β) = P(β g)/β` is the per-block free energy; its Legendre/entropy structure is
`P(β g) = max_μ ( β ∫ g dμ + H(μ) )` (`H` = Kolmogorov–Sinai entropy) **[lit]**. So
```
    F_K(β) = max_μ ( ∫ g dμ + H(μ)/β ).
```
At `β=∞` the entropy term vanishes and `F_K(∞) = max_μ ∫ g dμ = Γ_K` (pure ergodic optimization).
At finite `β` the `H(μ)/β` term **rewards spread** over many gluing words — this is the exact
mechanism by which the finite-`K` certificate over-counts near-optimal orbits, and it is the
thermodynamic reading of the project's observed **orbit-crowding**. The `−1` "spurious baseline"
values in the convergence doc are the `β`-finite Gibbs contributions of individual periodic orbits
before the entropy term is annealed away.

## 6. Is `cct` the `T→0` equilibrium state? Selection and the Bousch–Mairesse caveat

**Value convergence: robust [proj/lit].** `F_K(∞) = Γ_K` and `Γ_K ↓ gap(cct)`; the *value* leg of
the bridge holds independently of any selection subtlety.

**Measure selection: open, and fragile [conj].** The zero-temperature question is whether the Gibbs
measures `μ_β` converge, and if so to `δ_cct` (the period-3 `cct` orbit measure). Theory **[lit]**:
- For a *generic* (open-dense in Lipschitz) potential the maximizing measure is a single periodic
  orbit with the **finiteness property** (Yuan–Hunt; Bousch; Contreras), and then `μ_β → ` the
  maximizing orbit measure — selection holds.
- But the gluing-density potential is **not generic**: `CONVERGENCE-ANALYSIS-2026-07-13.md`
  documents a dense family of near-optimal periodic orbits (`16/11, 19/13, 25/17, …`) whose gaps
  crowd toward the *irrational* `gap(cct)` from a set of *rationals*. This is exactly the regime
  where **Bousch–Mairesse** / **Chazottes–Hochman** show the `T→0` limit of `μ_β` **need not
  converge** (it can oscillate among competing near-maximizers) and the finiteness property **fails**.

**Consequence for the bridge.** Conditional statement, honestly bracketed:
```
  IF  gap(cct) is attained by cct as the UNIQUE maximizing measure with the finiteness property,
  THEN  μ_β → δ_cct  and  T=0 selects cct.
  ELSE (finiteness fails — orbit-crowding is direct evidence it may) selection can fail:
       μ_β may not converge, or may select a competitor, even though F_K(∞)=Γ_K → gap(cct) still holds.
```
The global optimality of `cct` is itself **open in-project** ("near-optimal, long-period competitors",
convergence doc §4). So: the **selection leg is the fragile one**; the seed oscillation observed in
the certificate runs is a *direct visualization* of the Bousch–Mairesse competitor set. The bridge C
value statement survives this; the "T=0 equilibrium = cct" statement is **conjectural and at risk**
precisely here.

## 7. The static side, and the honest cross-side obstruction  [obstruction, likely-true]

One can soften the **static** GE packing LP too: entropy-regularize
`S_k(T) = max_p ( Σ p + T·H(p) )` s.t. the clique constraints, whose `T→0` limit is trivially
`S_k` (the LP optimum). So *each* side has a clean Maslov/entropy dequantization:
`static S_k(T) → S_k`, `dynamic F_K(β) → Γ_K`.

**Bridge C as literally posed** ("dynamic `Γ_K` = zero-temperature limit of the static GE sheaf")
requires `S_k` and `Γ_K` to be two temperatures of **one** parametrized operator. They are not,
and the obstruction is structural, not numerical:

1. **Different base spaces.** Static index set = vertices of `C₅^{∨k}` (conormal power); dynamic
   index set = de Bruijn-`K` words over `{c,t}`. No natural map identifies them.
2. **No shift on the static side.** `S_k` is a *finite-`k`* optimization; the dynamic `Γ_K` is an
   *ergodic average over an infinite orbit* (`k`-copies is not an orbit length under a shift). The
   dynamic side's `β` softens a *transfer operator of a dynamical system*; the static side's `T`
   softens a *one-shot LP* with no dynamics. Their `T→0` limits are different *kinds* of object
   (mean-payoff vs packing number).
3. **The one place they rhyme (and why it is not enough).** The static per-copy score is a
   *multiplicative-in-`k`* limit: `Θ(C₅) = lim_k α(C₅^{⊠k})^{1/k} = √5`, and
   `(1/k) log S_k → log Θ` is itself a pressure-like growth rate in the copy-number axis `k`.
   So the static side *does* have a hidden "dynamical" axis (`k`), but it is a **different** shift
   (Cabello product of copies of `C₅`) from the gluing shift `{c,t}^ℤ`. Unifying them would need a
   common base system, which does not evidently exist — **[conj]**, offered as a research direction,
   not a construction.

**Numerical falsifier for the strong bridge (cheap, do it to close the leg honestly):** compute the
static softened value `S_2(C₅; T)` for `T→0` and confirm it returns `√5` (the packing value), *not*
any `Γ_K`. If — as expected — it returns `√5` and shows no mean-payoff/de-Bruijn structure, the
strong bridge C is **refuted as an identity**, and the defensible surviving statement is the narrow
one of §§2–3: *each side is a Maslov dequantization of its own Ruelle operator; the dynamic `Γ_K` is
a genuine topological-pressure zero-temperature limit.* Name the failure explicitly as a
**category error** (packing-LP object vs mean-payoff object), per the project's "category errors are
the main risk" discipline.

## 8. Summary: what is TRUE / CONJECTURE / OBSTRUCTION

| Statement | Status |
|---|---|
| `Γ_K = λ_⊕(A^{(K)})` = max cycle mean = tropical eigenvalue | **[proj/lit]** |
| `F_K(β) = (1/β) log ρ(exp(β A^{(K)})) ↓ Γ_K` as `β→∞` (Claim C-lim) | **[new]**, directly testable |
| `Γ_K` = topological-pressure zero-temperature limit of a `(+,×)` Ruelle operator | **[new packaging of lit]** |
| `V=1 ⟷ T=0`, noise `(1−V)` = temperature (dynamic side) | **[conj]**, calibratable §4 |
| `μ_β → δ_cct` (cct is the `T=0` equilibrium) | **[conj], fragile** — Bousch–Mairesse, §6 |
| Dynamic `Γ_K` = `T→0` limit of the *static* GE LP `S_k` | **OBSTRUCTION [conj, likely-false]** — category error, §7 |

## 9. Validation checklist for the implementer

1. Reproduce `λ_⊕(A^{(K)}) = Γ_K` for `K=3,4,5` from the transcribed certificate payoff (gate).
2. Confirm `F_K(β)` monotone-decreasing and `→ Γ_K`; hit `1/8` (K=3, exact), `0.10196412702492699`
   (K=4), `0.0952971530959493` (K=5) to documented precision (§3).
3. Use log-sum-exp / `exp(β(A−maxA))` stabilization; no cloud, no SDP; `numpy`/WL local only.
4. Run the §7 static falsifier: `S_2(C₅;T→0) = √5`, exhibiting the category error.
5. Report the selection question (§6) as **open**, with orbit-crowding as the honest risk to `T=0`
   selection of `cct`. Do **not** claim `μ_β → δ_cct` without a finiteness-property proof.

## References (Phase-1 leads used)

Litvinov–Maslov dequantization (arXiv:math/0507014); Cuninghame-Green / Karp (max cycle mean =
tropical eigenvalue); Baccelli–Cohen–Olsder–Quadrat, Akian–Bapat–Gaubert (max-plus spectral theorem,
eigenvector = sub-action); Baraviera–Leplaideur–Lopes, Jenkinson arXiv:1712.02307 (pressure →
ergodic optimization); Li–Sun arXiv:2408.10169 (tropical thermodynamic formalism, Bousch operator =
zero-temperature dequantization of Ruelle operator); Bousch–Mairesse, Chazottes–Hochman (non-selection
/ non-convergence at `T→0`); Yuan–Hunt, Contreras (finiteness property, periodic-orbit selection);
Montanhano arXiv:2104.11411 (`R`-contextuality, tropical coefficient home for the static side).
