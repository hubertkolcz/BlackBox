# CF = (n−1)·ν on the odd n-cycle — an analytic proof

> **PROVENANCE (read first).** This theorem is **not new**. It is Camillo & Cervantes,
> *"Measures of contextuality in cyclic systems and the negative probability measure
> CNT3"* (arXiv:2305.16574, 2023), Theorem 2.1: `CNTF(R_n) = (n−1)·CNT3(R_n)` for every
> cyclic n-system, where `CNTF` is the Abramsky–Barbosa–Mansfield contextual fraction
> and `CNT3` is the L1-minimal signed-quasiprobability measure — the same object as `ν`
> here. It lives in the **Contextuality-by-Default** literature (Dzhafarov–Cervantes),
> which an earlier novelty pass of this project searched past. The proof below was
> derived independently in this project before the citation was found; it is an
> **independent re-derivation of a published result**, kept for its self-contained,
> machine-verified form, **not** as an original theorem. Cite Camillo–Cervantes (2023).

**Statement.** For odd `n ≥ 3`, every no-disturbance empirical model `e` on the n-cycle
contextuality scenario satisfies

> **CF(e) = (n − 1) · ν(e)**

where `CF` is the contextual fraction and `ν` the signed-decomposition negativity
`ν(e) = min{ ½(‖c‖₁ − 1) : M c = e }` (minimal total negative weight of a
quasi-probability over the deterministic global assignments). This turns the observed
`CF = 4ν` for the KCBS pentagon (`n = 5`) into an instance, with the constant `4 = n − 1`.

Verification companion: `SignedNegativity.wl`. All lemma values below were also checked
in exact arithmetic (n = 5,7,9 and random asymmetric models).

## Setup

Binary outcomes written as `±1`; `A_i = ±1` on measurement `i`, contexts = edges
`{i, i+1}` mod n. A no-disturbance model is fixed by singles `⟨A_i⟩` and edge
correlators `⟨A_i A_{i+1}⟩` (Fine's theorem for the cycle). `M` is the 4n × 2ⁿ incidence
matrix of deterministic assignments; `d_g` (columns of `M`) are the deterministic models.

**Cycle inequalities (Araújo–Quintino–Budroni–Terra Cunha–Cabello, PRA 88, 022118).**
The facets of the noncontextual polytope `P_NC` are exactly the `2^{n−1}` inequalities

    B_γ(e) := Σ_i γ_i ⟨A_i A_{i+1}⟩_e ≤ n − 2,   γ ∈ {±1}ⁿ with an odd number of −1's.

Their no-signalling maximum is `n` (attained by the Wright box `W_γ`, the box with
`⟨A_i A_{i+1}⟩ = γ_i`, all singles 0).

**Gauge identity.** Summing `M c = e` over the four sections of one edge gives
`Σ_g c_g = 1`, so `1 + 2ν(e) = min{ ‖c‖₁ : M c = e } = ‖e‖_𝒜`, the Minkowski gauge of
the symmetric hull `𝒜 = conv{ ±d_g }`. It is a convex, positively-homogeneous function,
zero exactly on `P_NC`.

## Lemma 0 — a model violates at most one facet

Suppose `e` violated two facets `γ ≠ γ'`. Both patterns have odd `−1`-parity, so they
differ in an **even** number `d ≥ 2` of coordinates and agree in `s = n − d ≤ n − 2`.
Writing `c_i = ⟨A_i A_{i+1}⟩_e ∈ [−1,1]`,

    B_γ(e) + B_{γ'}(e) = Σ_i (γ_i + γ'_i) c_i = Σ_{i: γ_i = γ'_i} 2 γ_i c_i ≤ 2s ≤ 2(n−2),

because the `d` disagreeing coordinates contribute 0 and each agreeing one is `≤ 2`.
But two violations would give `B_γ(e) + B_{γ'}(e) > 2(n−2)`. Contradiction. ∎

So every contextual `e` violates a **unique** facet `γ*`, and by the ABM
contextual-fraction theorem (normalised violation; span `n − (n−2) = 2`),

    CF(e) = ( B_{γ*}(e) − (n−2) ) / 2.                                  (1)

## Lemma 1 — the Wright box has ν(W_γ) = 1/(n−1)

`CF(W_γ) = 1`, so the lower bound below already gives `ν ≥ 1/(n−1)`. For the upper bound:
`W_γ` is invariant under the group `G` = cyclic × reflection × global-flip, so the
negativity LP `max{ e·w : |Σ_c w_{c,g|c}| ≤ 1 ∀g }` has a `G`-invariant optimum
`w_{i,(s,t)} = α` if `s ≠ t`, `β` if `s = t`. A deterministic `g` with `k` domain walls
(k even, `0 ≤ k ≤ n−1` since an odd cycle admits at most `n−1` satisfied
anti-correlations) gives `W_g = kα + (n−k)β`, linear in `k`; the constraints bind at
`k = 0` (`nβ ≥ −1`) and `k = n−1` (`(n−1)α + β ≤ 1`). Maximising the objective `nα`
(for the all-minus `W`) gives `β = −1/n`, `α = (n+1)/(n(n−1))`, value
`nα = (n+1)/(n−1) = 1 + 2/(n−1)`. Hence `1 + 2ν(W_γ) = 1 + 2/(n−1)`, i.e.
**ν(W_γ) = 1/(n−1)**. ∎

## Theorem — CF = (n−1)·ν

Fix a contextual `e` with violated facet `γ*` and `β := B_{γ*}(e) ∈ (n−2, n]`, so by (1)
`CF = (β − (n−2))/2`.

**Lower bound `CF ≤ (n−1)ν` (all `e`).** Define the explicit dual witness

    w_{i,(s,t)} = ( 1/n + γ*_i · s t ) / (n − 1).

For any deterministic `g`,  `W_g = Σ_i w_{i,(g_i,g_{i+1})} = ( 1 + B_{γ*}(g) ) / (n−1)`.
Since `B_{γ*}(g) ∈ [−n, n−2]` for deterministic `g` (Lemma 0's bound; the classical
bound above and `≥ −n` trivially), `|W_g| ≤ 1` — the witness is feasible. Its value is

    e · w = ( 1 + B_{γ*}(e) ) / (n−1) = ( 1 + β ) / (n−1) = 1 + 2·CF/(n−1).

By LP duality `1 + 2ν = max_feasible (e·w′) ≥ e·w`, so `ν ≥ CF/(n−1)`. ∎

**Upper bound `CF ≥ (n−1)ν` (all `e`).** If `CF = 1`, `e = W_{γ*}` and Lemma 1 gives
equality. Otherwise set `e₀ = (e − CF·W_{γ*})/(1 − CF)`. By Lemma 2 below, `e₀ ∈ P_NC`,
so `‖e₀‖_𝒜 = 1`. With `e = (1 − CF) e₀ + CF · W_{γ*}` and the gauge convex,

    1 + 2ν(e) = ‖e‖_𝒜 ≤ (1−CF)·‖e₀‖_𝒜 + CF·‖W_{γ*}‖_𝒜
              = (1−CF)·1 + CF·(1 + 2/(n−1)) = 1 + 2·CF/(n−1),

so `ν ≤ CF/(n−1)`. ∎

Both bounds give **CF = (n − 1) · ν**. ∎

## Lemma 2 — e₀ lands in the noncontextual polytope

WLOG (local relabelings `A_i ↦ ±A_i`, a scenario symmetry) take `γ* = (−1,…,−1)`, so the
violated inequality is `Σ_i c_i ≥ −(n−2)` with `c_i = ⟨A_i A_{i+1}⟩_e`, `S := Σ_i c_i`,
and `CF = (−S − (n−2))/2`. `W_{γ*}` is the Wright box (correlators `−1`, singles `0`).
Write `m_i = ⟨A_i⟩_e`. One computes `B_{γ*}(e₀) = n − 2` (e₀ saturates `γ*`).

**(A) e₀ ≥ 0.** For a section `(s,t)` of edge `i`, `4·p⁰_{st}·(1−CF) = 4·pᵉ_{st} + CF(st−1)`.
Correlated sections (`st = +1`) scale by `1/(1−CF) ≥ 0`, so stay ≥ 0. Anti-correlated
sections (`st = −1`) need `pᵉ_{st} ≥ CF/2`, equivalently

    (n−1) ± (m_i − m_{i+1}) + Σ_{j≠i} c_j ≥ 0.                          (‡)

Edge-positivity of `e` at the correlated sections of every edge `j` gives
`c_j ≥ −1 + |m_j + m_{j+1}|`, hence `Σ_{j≠i} c_j ≥ −(n−1) + Σ_{j≠i} |m_j + m_{j+1}|`.
The complementary path (all edges but `i`) has `n−1` edges; because `n` is odd its
alternating sum telescopes exactly to

    Σ_{j≠i} (−1)^… (m_j + m_{j+1}) = m_{i+1} − m_i,

so `|m_i − m_{i+1}| ≤ Σ_{j≠i} |m_j + m_{j+1}|`. Therefore
`Σ_{j≠i} c_j ≥ −(n−1) + |m_i − m_{i+1}|`, and substituting into (‡):
`(n−1) ± (m_i − m_{i+1}) + Σ_{j≠i} c_j ≥ ±(m_i − m_{i+1}) + |m_i − m_{i+1}| ≥ 0`. ✓

**(B) e₀ satisfies every facet.** It saturates `γ*`. For `γ ≠ γ*` let `D = {i : γ_i = −1}`,
`d = |D|` (odd, and `d ≤ n−2` since `γ ≠ γ*`). Then

    B_γ(e₀) = ( B_γ(e) + CF·Γ ) / (1−CF),   Γ = Σ_i γ_i = n − 2d,

and `B_γ(e) = −B_{γ*}(e) − 2 Σ_{i∈D} c_i` (since `γ_i + γ*_i = −2` on `D`, `0` off `D`),
with `B_{γ*}(e) = 2CF + (n−2)`. Substituting, `B_γ(e₀) ≤ n−2` is equivalent to
`−Σ_{i∈D} c_i ≤ (n−2) − CF·(n−2−d)`. But `−Σ_{i∈D} c_i ≤ d` (each `−c_i ≤ 1`), and
`d ≤ (n−2) − CF·(n−2−d)` reduces to `CF ≤ 1` (using `n−2−d ≥ 0`). ✓

Both parts use `n` odd essentially — the telescoping sign in (A), and `d ≤ n−2` in (B).
Hence `e₀ ∈ P_NC`. ∎

## Where the constant comes from

`n − 1` is forced twice by the odd cycle:

- the cycle inequality's classical bound `n−2` versus its no-signalling maximum `n`
  (span 2), and
- the Wright box negativity `1/(n−1)`, itself the reciprocal of the maximal number of
  simultaneously satisfiable anti-correlations in an odd cycle (`n−1`, since a perfect
  2-colouring is obstructed at exactly one edge).

For even cycles the Wright box is noncontextual, and for other scenarios (CHSH, GHZ) the
ratio is different (`CF/ν = 2`), so the identity is genuinely a property of the odd
n-cycle — the pentagon's `4` is the `n = 5` instance.

## Rigour status

**Complete and unconditional** for every no-disturbance model on the odd n-cycle:
Lemma 0 (parity), Lemma 1 (`ν(W_γ) = 1/(n−1)`, by symmetrisation), Lemma 2 (`e₀ ∈ P_NC`,
by edge-positivity + the odd-cycle telescoping identity), the lower bound `CF ≤ (n−1)ν`
(explicit dual witness), and the upper bound `CF ≥ (n−1)ν` (Lemma 2 + gauge convexity).
Every step reduces to a one-line inequality; the LP values `CF` and `ν` are exact
(machine-verified for `n = 5, 7, 9` and random asymmetric models via `SignedNegativity.wl`).

The identity is specific to odd cycles: for even cycles the Wright box is noncontextual,
and other scenarios give a different constant (CHSH and GHZ both give `CF/ν = 2`). The
`n − 1` is the odd cycle's frustration number — the maximal number of simultaneously
satisfiable anti-correlations, one short of a perfect 2-colouring.
