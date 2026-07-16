# cluster-state-realization

**Emerging module, uncommitted as of 2026-07-12.** Builds and verifies a literal MBQC cluster-state realization of `pentagon-gluing`'s winning `(ddt)^infinity` gluing word — the entanglement graph, not just its exclusivity-graph shadow. This is genuinely new territory that doesn't map cleanly onto one pre-existing ledger track (it spans `MESH` and `D3`); it's kept as its own module rather than forced into either.

## Contents

- `ddt_cluster_stabilizer.wl`, `ddt_mesh_sparse_construction.wl`, `ddt_mesh_sparse_stabilizer.wl` — GF(2) binary-symplectic stabilizer tableau for the ddt-glued pentagon-mesh CZ cluster state; the sparse rewrite scales to millions of pentagons (`MESH-007`).
- `ddt_cluster_avn_witness.wl` — mesh-generalized GHZ All-versus-Nothing contextuality witness verified on the actual cluster state, block by block (`MESH-008`).
- `ddt_cluster_dla.wl` — Dynamical Lie Algebra dimension of the mesh topology; hits the generic $4^n-1$ ceiling with no pentagon-specific reduction, genuinely infeasible past ~2 pentagons by both a time and a memory argument (`LP-003`).
- `ddt_cluster_lie_poisson_bridge.wl` (+ `_cloud_3M` cloud-scale variant) — integrates the three checks above into one self-contained diagnostic with an explicit `HonestGaps` field.
- `ddt_mbqc_scratch_topology.wl` — self-labeled scratch work; not a finished result (see `ISSUE-021`).

## Honest scaling note (read before trusting any result here at large N)

The stabilizer check and the AvN witness do **not** share the same validity radius in N. The stabilizer check is genuinely verified to scale to millions of qubits. The AvN witness is checked only through N=3 blocks with dense matrices, but the *locality property it depends on* was independently re-confirmed at 1800 qubits via the sparse method — its ceiling is a choice of verification method, not a forced barrier. The DLA dimension, by contrast, is a real complexity wall (exponential, confirmed independently at n=2,3): more engineering will not push it past ~2 pentagons.

## Relationship to the primary module

Feeds `certification-protocol/`'s long-term goal of an MBQC/optical black-box test at scale, but is **not currently imported by `mbqc_blackbox_test.py`**. Treat this module as upstream research, not yet part of the certification protocol itself.

## Ledger cross-reference

`MESH-007`, `MESH-008`, `LP-003`, `ISSUE-020`, `ISSUE-021`. Full extraction: Quantum Contextuality project's `01-claims-ledger/raw-extraction/blackbox-ddt-cluster-mbqc-2026-07-12.md`.
