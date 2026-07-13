# 01-D2-core-computation

Ledger track `D2` — "primary computational track": the shared KCBS-pentagon computational bedrock. Most other modules in this repository, and the primary `00-BBT-blackbox-protocol/` module itself, import from here. This folder does not answer the project's central question by itself — it supplies the machinery the primary module and several contributing tracks are built from.

## Contents

- `gep.wl`, `qutrit.wl`, `kcbs.wl` — foundational pentagon graph invariants ($\alpha$, $\theta$, $\alpha^*$) and the basic qutrit toolkit the KCBS demonstrations build on (`FOUND-001`).
- `kcbs_circuit.wl`, `kcbs_circuit_ncycle.wl` (generalizes the qutrit circuit encoding from the pentagon to general odd n-cycles, `FOUND-003`), `kcbs_sequential_game.wl` (two-party sequential KCBS game, `FOUND-004`), `kcbs_simulation.wl`/`.py`, `kcbs_epr.wl`, `kcbs_epilogue.wl`, `kcbs_wigner_flow.wl` — circuit-level and simulation realizations of the KCBS cascade.
- `BiphotonSimulator.wl` — biphoton-encoding hardware-run thread on the Wolfram Quantum simulator.
- `CertifyingQuantumness.wl`/`.nb` — the Global Exclusivity (GE) mechanism at 2 identical copies (`GE-001`), the direct statistical anchor the primary module's certification protocol depends on.
- `SignedNegativity.wl`, `CF-negativity-proof.md`, `cf_nu.py`, `kcbs_ledger.wl` — contextual fraction, its relation to signed negativity (`CF-001` through `CF-004`), and the Wigner-negativity/contextuality noise-threshold window.

## Relationship to the primary module

`00-BBT-blackbox-protocol/mbqc_blackbox_test.py` imports the contextual-fraction and GE machinery here directly. This folder has no dependency on the primary module in the other direction.

## Ledger cross-reference

`FOUND-001`, `FOUND-002`, `FOUND-003`, `FOUND-004`, `GE-001`, `CF-001` through `CF-004` in `01-claims-ledger/ledger.json` (track `D2`).
