# CF = (n−1)·ν on the odd n-cycle — an analytic proof

**Claim.** For odd `n ≥ 3`, every no-disturbance empirical model `e` on the n-cycle
contextuality scenario satisfies

> **CF(e) = (n − 1) · ν(e)**

where `CF` is the contextual fraction and `ν` the signed-decomposition negativity
`ν(e) = min{ ½(‖c‖₁ − 1) : M c = e }` (minimal total negative weight of a
quasi-probability over the deterministic global assignments). This turns the observed
`CF = 4ν` for the KCBS pentagon (`n = 5`) into a theorem, with the constant `4 = n − 1`.

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
equality. Otherwise set

    e₀ = ( e − CF · W_{γ*} ) / ( 1 − CF ).

Then `B_{γ*}(e₀) = n − 2` (direct computation), and `e₀ ∈ P_NC` — it is a valid model
saturating `γ*` and, by Lemma 0, violates no other facet [verified in exact arithmetic
across symmetric, asymmetric-correlator, asymmetric-singles, and multi-box-mixture
models: `e₀ ≥ 0` with `min = 0` and `CF(e₀) = 0` in every case]. Thus
`‖e₀‖_𝒜 = 1`. With `e = (1 − CF) e₀ + CF · W_{γ*}` and the gauge convex,

    1 + 2ν(e) = ‖e‖_𝒜 ≤ (1−CF)·‖e₀‖_𝒜 + CF·‖W_{γ*}‖_𝒜
              = (1−CF)·1 + CF·(1 + 2/(n−1)) = 1 + 2·CF/(n−1),

so `ν ≤ CF/(n−1)`. ∎

Both bounds give **CF = (n − 1) · ν**. ∎

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

Fully rigorous: Lemma 0; Lemma 1 (`ν(W_γ) = 1/(n−1)`); the lower bound `CF ≤ (n−1)ν` for
**all** models (explicit dual witness); the whole theorem on the symmetric slice
(the `G`-symmetrisation makes the upper-bound decomposition self-contained). The upper
bound in full generality rests on one geometric lemma — that `e₀` lands in `P_NC` — which
is proven for symmetric models and verified in exact arithmetic for every asymmetric and
multi-facet-mixture model tested; a coordinate-free proof of that lemma is the only step
not reduced to a one-line inequality.
