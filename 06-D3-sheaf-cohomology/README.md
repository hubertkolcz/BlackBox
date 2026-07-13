# 06-D3-sheaf-cohomology

Ledger track `D3` — "conceptual backbone": the Abramsky-Brandenburger sheaf-theoretic framework for "locally true need not be globally true," used both as foundational language and as a source of a cohomological obstruction (Čech cohomology) that succeeds where a naive cellular-sheaf Laplacian failed.

## Contents

`SupportCohomology.wl` — the sheaf Laplacian's pre-registered rejection as a contextuality measure (`SH-004`), and the Čech cohomology of the support presheaf that replaces it, cataloguing exact torsion order of the obstruction class across canonical models (`SH-005`).

Note: the KCBS-cascade so(3)/Lie-Poisson interface that also carries a `D3` tag (`LP-001`) lives inside the `BlackBox/` paclet itself (`Kernel/BlackBox.wl`), not in this folder — it's a paclet-level export used by many modules, not sheaf-specific code.

## Relationship to the primary module

This is the project's own explicitly-flagged priority open question's home: whether this cohomological machinery can *derive* (not merely describe) the GE composed bound for products of KCBS 5-cycles (`ESSAY-005`, still open — see the Quantum Contextuality project's `ROADMAP.md`). Not currently imported by `00-BBT-blackbox-protocol/`.

## Ledger cross-reference

`SH-001` through `SH-008`, `ESSAY-005` (track `D3`).

## ESSAY-005 probe results (2026-07-13)

`ESSAY-005-problem-spec.md` fixes the target (Traps 1/2, probes P1–P4); `ESSAY-005-phase23-execution-plan.md` is the execution design.

**P1 + P4** — `essay005_p1_p4.wl` → `p1p4_census.csv`, `p1p4_torsion.csv` (support-census negative control and torsion scan).

**P3** — `essay005_p3_gluing_lp.wl` → `p3_certificates.json`. The subnormalized-weighting presheaf on the maximal-clique cover of the conormal power glues trivially, so the glued value is the fractional packing LP (E1); certificates settle it exactly (exact rational simplex `LinearOptimization[..., Method -> "Simplex"]`, flat variable list; radicals via `RootReduce`, never floats). **Gate verdict: PASS** — all pre-registered Trap-1 targets reproduced exactly:

| target | exact value | per-copy | primal certificate | dual 0-cochain |
|---|---|---|---|---|
| L₁(C5) = A₁(C5) | 5/2 | 5/2 | p ≡ 1/2 | y = 1/2 on 5 edges |
| L₂(C5) = A₂(C5) | 5 | √5 | p ≡ 1/5 (ω = 5; census 535 = {4:525, 5:10}) | y = 1 on 5 pentads — **exact partition of unity** |
| L₁(C7) = A₁(C7) | 7/2 | 7/2 | p ≡ 1/2 | y = 1/2 on 7 edges |
| L₂(C7) = A₂(C7) | 49/4 | 7/2 — **not** θ(C7)² ≈ 11.008 | p ≡ 1/4 (ω = 4; census 1715 = {4:1715}) | y = 1/4 on 49 edge-squares — properly fractional (4 ∤ 49) |
| L₃(C5) | 25/2 | (25/2)^⅓ ≈ 2.3208 > √5 | p ≡ 1/10 (ω(C5^∨3) = 10) | y = 1/2 on 25 pentad×edge 10-cliques |
| L₃(C7) | 343/8 | 7/2 (Trap-1 control holds at k = 3) | p ≡ 1/8 (ω(C7^∨3) = 8, **new fact**) | y = 1/8 on 343 edge-cube 8-cliques |

New fact fixed this run: **ω(C7^∨3) = 8**, by orbit reduction — WLOG a 9-clique contains (0,0,0); for each of the 10 orbit representatives u of N((0,0,0)) under Stab((0,0,0)) = (Z₂ reflections)³ ⋊ S₃ (order 48), the common neighborhood has clique number exactly 6 < 7 (python-igraph, 9 s); the edge-cube exhibits 8. Hence the C7 per-copy sequence is flat at 7/2 through k = 3, matching Choudhary–Barbosa. E2 product-ansatz witnesses verified in exact radical arithmetic: q ≡ 1/√5 saturates exactly the ten 5-cliques of C5^∨2 (both pentad slope families) at 1; q ≡ 1/2 makes all 1715 maximal cliques of C7^∨2 sum to exactly 1. A₃(C5) ∈ [5^{3/2}, 25/2] — open whether strict; k = 3 clique censuses were never materialized (C5^∨3 has ~1.04·10⁸ maximal cliques).

**Reduced question handed back to the essay (P3 acceptance):** since the gluing LP alone already computes S₂ on both C5 and the C7 control, the derivation question becomes — *which invariant of the weighted (Q≥0-semimodule) presheaf on the product cover computes the optimal fractional partition of unity (the dual Čech 0-cochain), and when is that optimum attained by an exact partition rather than a properly fractional cover?* The exact solver dual at (C5, k = 2) came back supported on precisely the five slope-3 pentads with weight 1 (the reflection-mirror of the slope-2 hand cochain) — the pentad-partition 0-cochain is literally the simplex certificate. The k = 3 discriminator L₃(C5) = 25/2 (per-copy > √5) shows where gluing content and ansatz content separate.
