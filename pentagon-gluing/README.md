# pentagon-gluing

Ledger track `MESH` — "pentagon-mesh composition": how gluing many KCBS pentagons together (rings, chains, arbitrary words of two edge-orientations) affects the quantum-classical gap. Central finding: gluing ORIENTATION, not block count, controls whether the gap survives composition (`MESH-002`).

## Contents

`CaseStudies.wl` — trans/cis gluing family theorems, the `(cct)^infinity` optimal gluing word (`MESH-001` through `MESH-003`). `realizability.py`, `qutrit_realization.py` — physical realizability of the trans-chain advantage in a single qutrit (`MESH-004`). `trans_chain_proofs.py`, `trans_chain_density_check.wl` — exact independence/clique-number laws with full proof (`MESH-005`, `MESH-009`). `word_census.py` — exhaustive gluing-word census up to period 18. `lovasz_theta_sparse.py` — sparse Lovász $\theta$ at $10^4$-$10^6$ vertices. `fem_study.py`, `fem_study_results.json` — whether DLA growth under composition correlates with contextual-fraction density (`LP-002`, a headline negative result: it does not, reliably).

Note: `qutrit.wl` moved to `pentagon-foundations/` — it's a shared primitive `kcbs.wl` also depends on, not mesh-specific.

## Relationship to the primary module

Feeds the primary module conceptually (the mesh gluing results are the reason a cluster-state analogue of the pentagon is worth building at all) but `certification-protocol/` does not import from here directly.

## Ledger cross-reference

`MESH-001` through `MESH-006`, `MESH-009`, `LP-002` (track `MESH`).
