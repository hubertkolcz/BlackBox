# NOTES — Extending the Correlation Taxonomy to Signaling and Quantum-Communication Scenarios

Hubert Kołcz — 10 July 2026. Worktree branch `claude/signaling-taxonomy` (base `master` 9f4be1e).
Artifacts: `signaling_taxonomy.py` (executable verifier — every number below computed there;
gates G1/G2/G3 all PASS, exit 0), `signaling_taxonomy.wl` (computational essay, wolframscript-
runnable; no WL kernel was available in the sandbox, so the WL file re-derives the exact layer
and mirrors the executed Python float layer as pinned literals), `RunSignalingTaxonomy.wl`
(headless runner). This note is the compact ledger + doc-merge notes.

## 1. The three axes

| Axis | Object | Status | Statement |
|---|---|---|---|
| 1. Signaling stratum | Harmonic residual ‖δ·e‖ (BlackBox `HarmonicResidual`, `CycleCoboundary`) | **theorem** (AB Thm 5.9, arXiv:1102.0264) + exact computation | signaling ⇔ residual ≠ 0 ⇔ no ℝ-linear global section. Matrix form verified exactly: δ₅·M₅ = 0 and rank M₅ = dim ker δ₅ = 11 ⇒ **im M = ker δ**. The tool pre-registered-REJECTED as a contextuality measure (kernel = whole no-disturbance space) is exactly the detector of the new axis. |
| 2. CbD layer | Kujala–Dzhafarov cyclic-n criterion | **literature-fact** (formula pinned) + exact computation | contextual ⇔ s₁(⟨VᵢW_{i⊕1}⟩) − Δ > n−2, Δ = Σᵢ\|⟨Vᵢ⟩−⟨Wᵢ⟩\|; measure CNTX = max(s₁−Δ−(n−2),0)/2. Pinned from Found. Phys. 46, 282 (2016), arXiv:1503.02181v4 Eqs. (6)/(7)/(13), Thms 13–14; equivalent (their Thm 13) to PRL 115, 150401 criterion; both forms implemented, agree on every instance. |
| 3. Communication cost | Two LPs: signaling fraction SF; one-bit rate μ | **computation** (exact certificates on algebraic rows) | SF = min λ: e = (1−λ)·NC + λ·arbitrary (= 1 − NCF). μ = min bit-fraction mixing 0-bit (noncontextual) with 1-bit context-aware deterministic strategies. Proposition (machine-checked bijection): the 4⁵ = 1024 one-bit strategies = ALL deterministic tables ⇒ conv = full polytope ⇒ **μ = SF**. |

Rank ledger (exact, ℚ): C5: rank δ = 9, dim ker δ = **11** = affine-hull(ND polytope) + 1 = 10+1;
rank M = 11 (AB Prop. 5.7: 2n+1). C4: 7, 9 = 8+1, 9. The "+1" is the global normalization scale.

## 2. Strata table (all values computed; exact where algebraic)

| model | ‖δe‖ | Δ | CbD margin | CNTX | CbD verdict | SF | μ (bits/round) | stratum |
|---|---|---|---|---|---|---|---|---|
| C5 classical | 0 | 0 | 0 (exact) | 0 | noncontextual | 0 (exact) | 0 | S0 classical |
| C5 quantum | 0 | 0 | 4√5−8 ≈ 0.9443 | **2√5−4** = CF (exact) | contextual | **2√5−4** (exact pinch) | **2√5−4** (exact witness) | S1 probabilistically contextual |
| CHSH Tsirelson | 0 | 0 | 2√2−2 ≈ 0.8284 | √2−1 | contextual | √2−1 (float 0.4142135624) | √2−1 | S1 |
| C5 Wright box | 0 | 0 | 2 | 1 | contextual | 1 (exact) | 1 | S2 strongly contextual |
| CHSH PR box | 0 | 0 | 2 | 1 | contextual | 1 (exact) | 1 (2-strategy witness) | S2 |
| C5 pure-signaling box | √2 (‖·‖²=2 exact) | 2 | 0 (exact) | 0 | noncontextual | 1 (exact) | 1 | S3 pure-signaling |
| C5 Lapkiewicz-realistic (V=0.977, +ε/2) | 0.0573 | ε = 0.081 | 0.8919 | 0.4459 | contextual | 0.4864 | 0.4864 | S4 contextual despite signaling |

Realistic variants (Δ = ε = 0.081 imposed as the maximal marginal reading of the published ε,
since Δ = |⟨A1⟩−⟨A1′⟩| ≤ 2P(A1≠A1′) = ε): Σ = −3.811 (p′=p−ε/2), −3.973 (p′=p+ε/2) — bracketing
the measured −3.893 — and V = 0.9419 calibrated to Σ = −3.893 exactly; CbD margins 0.7299 /
0.8919 / 0.8120, i.e. always the Δ-ignoring margin minus exactly ε. All three CONTEXTUAL,
matching the Kujala–Dzhafarov–Larsson PRL 115, 150401 reanalysis of the real data.
Honesty note: per-edge correlations are NOT recoverable from the published aggregates (Σ, ε) —
five unknowns, two equations — hence the pre-registered fallback to the `kcbs_simulation.py`
noise model. The C5 quantum row uses p = 1/√5 per event; correlations 1−4/√5 per edge.

## 3. Key exact values

- s₁(quantum C5) = 4√5−5; equivalently Σ⟨Pᵢ⟩ = (s₁+5)/4 = √5 — the CbD layer reduces to the
  standard KCBS verdict at Δ = 0. CNTX = 2√5−4 = CF **exactly** (Axis-2/Axis-3 lock at Δ=0).
- NCF(C5 quantum) = 5−2√5, SF = CF = 2√5−4, pinched by exact certificates over ℚ[√5]:
  primal = weight 1−2/√5 on each of the 5 non-adjacent-pair assignments; dual = y = (1,0,0,1)
  per context (feasible because an odd cycle has no proper 2-coloring), y·e = 5−2√5.
- **Decomposition identity** (new, exact): e_quantum = (5−2√5)·e_classical + (2√5−4)·e_Wright.
  The CF-optimal noncontextual part of the quantum pentagon is exactly the classical-maximal
  model; the residue is exactly the Wright box.
- Communication witness: e_Wright = uniform mixture of the 32 one-bit strategies
  {x ∈ {0,1}⁵, y_j = 1−x_{j−1}} ⇒ μ(quantum C5) = 2√5−4 ≈ 0.4721 bits/round exactly: the
  communication a classical (e.g. optical) emulation must spend to fake the quantum table.
- PR box: μ = 1 with the exact two-strategy witness (x=0000/y=1000 and its global flip).
  Contrast (scope): Toner–Bacon (PRL 91, 187904) simulate the singlet for ALL directions at
  1 bit/round — state simulation, not table simulation; only the latter is priced here.
- Pure-signaling box: ‖δe‖² = 2 exact, CbD margin exactly 0 (books everything as signaling),
  SF = μ = 1. Same cost as PR, opposite CbD verdict — the reason SF alone is not a classifier.
- Observation, refuted generically: SF = Δ_min (= ½max{s₁−(n−2), Δ}) holds on all seven
  exemplar rows but FAILS on random C5 tables (max gap 2.015 over 200 samples; Δ_min is not
  even bounded by 1). Recorded as an open question about the low-signaling corner, not a theorem.

## 4. Scope and open items

- **"Ulrey-taxonomy extension" means here:** the Ulrey census cross-validated by
  SupportCohomology.wl is EPRB-bound (its dividing lines live on the CHSH cover); the strata
  above are the scenario-unbound refinement — residual, CbD-cyclic, SF, μ are defined for any
  cyclic rank (and residual/SF for arbitrary covers via `CoverScenario`).
- **Why three axes and not one number:** Tezzin–Wolfe–Amaral–Jones (arXiv:2212.06976) prove no
  single disturbing-systems contextuality measure satisfies determinism-noncontextuality +
  three monotonicity/composition desiderata. CbD keeps determinism-noncontextuality (our
  deterministic signaling box: margin exactly 0); SF is a cost, not a classifier; residual is a
  detector. Division of labor, by design.
- Open: (a) CbD closed forms beyond cyclic covers (no Δ-corrected AvN/GHZ layer);
  (b) SF vs Δ_min geometry (identity refuted; inequality structure unexplored);
  (c) capacity-style asymptotics for signaling strata — the zero-error bridge Θ(C5) = √5 = ϑ
  (CaseStudies.wl Case A; Lovász 1979) prices the quantum channel, μ prices one-shot classical
  table simulation; a many-round theory (strategy polytopes under OR-product composition,
  a signaling analogue of Θ) is not formalized;
  (d) reconcile with Amaral–Duarte extended-contextuality quantifiers (PRA 100, 062103,
  arXiv:1902.02413) on these exemplars.

## 5. Doc-merge notes (do not edit QUANTUM_CONTEXTUALITY.md / README.md from this branch)

- QUANTUM_CONTEXTUALITY.md §6 (artifacts): add the three files + runner with one line each;
  the headline fact for §1 is the decomposition identity and CNTX = CF at Δ=0.
- QUANTUM_CONTEXTUALITY.md §3 (Lapkiewicz): the CbD margin ledger (0.7299/0.8919/0.8120,
  penalty exactly ε) quantifies the Kujala–Dzhafarov–Larsson row already cited there.
- §9 (open threads): items (a)–(d) above.
- CertifyingQuantumness.wl's "rejected Laplacian" remark gains a forward pointer: rejected as a
  contextuality measure, adopted as the signaling detector (AB 5.9). Handled here as a note only.

## 6. References (pinned)

1. S. Abramsky, A. Brandenburger, NJP 13, 113036 (2011); arXiv:1102.0264 (Thm 5.9, Prop 5.7).
2. J. V. Kujala, E. N. Dzhafarov, Found. Phys. 46, 282–299 (2016); arXiv:1503.02181;
   DOI 10.1007/s10701-015-9964-8 (pinned criterion + CNTX formula; Thms 13–14).
3. J. V. Kujala, E. N. Dzhafarov, J.-Å. Larsson, PRL 115, 150401 (2015); arXiv:1412.4724;
   DOI 10.1103/PhysRevLett.115.150401 (criterion (8); Lapkiewicz CbD reanalysis).
4. E. N. Dzhafarov, J. V. Kujala, J.-Å. Larsson, Found. Phys. 45, 762–782 (2015);
   arXiv:1411.2244 (the conjecture; CbD).
5. R. Lapkiewicz et al., Nature 474, 490 (2011); DOI 10.1038/nature10119 (Σ=−3.893(6), ε=0.081(2)).
6. S. Abramsky, R. S. Barbosa, S. Mansfield, PRL 119, 050504 (2017); arXiv:1705.07918 (CF LP).
7. J. Hansen, R. Ghrist, J. Appl. Comput. Topol. 3 (2019); arXiv:1808.01513 (cellular sheaf δ).
8. A. Tezzin, E. Wolfe, B. Amaral, M. Jones, arXiv:2212.06976 (impossibility theorem).
9. B. Amaral, C. Duarte, PRA 100, 062103 (2019); arXiv:1902.02413 (extended-contextuality quantifiers).
10. B. F. Toner, D. Bacon, PRL 91, 187904 (2003); DOI 10.1103/PhysRevLett.91.187904.
11. L. Lovász, IEEE Trans. Inf. Theory 25, 1 (1979); A. Cabello, S. Severini, A. Winter,
    arXiv:1010.2163 (Θ(C5) = √5 bridge, CaseStudies.wl Case A).
