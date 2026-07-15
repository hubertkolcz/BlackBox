# certification-protocol — the primary module

**This module IS the project's central research question, operationalized.** Everything else in this repository is a contributing input to this module, not a peer to it. If you only read one folder, read this one.

Project title: *Evaluating black-box physics through optical emulation.* Central question: given only black-box access, under what conditions is it mathematically impossible to distinguish a genuinely quantum device from a classical optical emulation at the level of input-output behavior?

## Contents

- `mbqc_blackbox_test.py` — the full statistical certification protocol. Combines correlation-based classification of measurement statistics (contextual fraction / Global Exclusivity, from `pentagon-foundations/`) with a Lie-algebraic / DLA resource-scaling hook (from the `LP-001` interface documented in `BlackBox/Kernel/BlackBox.wl`), across 7 pre-registered gates, to distinguish a genuine quantum KCBS device from classical (NCHV) and classical-optics "intensity-emulator" impostors. Has one documented, pre-declared exact blind spot (an intensity emulator tuned exactly to the quantum table is table-level indistinguishable by construction) — see `BBT-002` in the ledger.
- `mbqc_c5.wl` — the MBQC-flow half: validates that the pentagon-ring CZ cluster state is a genuine entangled MBQC resource (stabilizers, gate teleportation) and that it is contextual via a GHZ all-versus-nothing argument. Prints a validation report rather than an `OK -> True` association; read the printed Summary.

## Run it

```
wolframscript -file ../runners/RunBlackboxProtocol.wl -print all   # mbqc_c5.wl
python3 mbqc_blackbox_test.py                                       # full protocol
```

## What feeds this module (dependency direction: inward only)

- `pentagon-foundations/` — the KCBS pentagon graph invariants, GE mechanism, and contextual-fraction machinery this protocol's statistical certificates are built from.
- `BlackBox/` (the paclet) — the DLA/so(3) hook (`LP-001`) that closes this protocol's one blind spot: a classical intensity-redistribution rig is necessarily leaf-confined (DLA<3), which the geometric criteria can detect even when the statistics alone cannot.
- `cluster-state-realization/` — an emerging, not-yet-integrated line of work verifying the same cluster state's stabilizer structure and contextuality witness at much larger mesh sizes. It feeds this module's long-term goal (an MBQC/optical black-box test at scale) but is NOT currently wired into `mbqc_blackbox_test.py` itself — see that module's own README for the honest state of that boundary.

Nothing in this module should import the theory-frontier (D1), certificate/ergodic-optimization (CERT), sheaf-cohomology (D3), signaling (SIG), or Hawking (HK) tracks directly. Those are side investigations that inform the project's broader arguments (see the Quantum Contextuality project's `ROADMAP.md`) but are not inputs this specific protocol depends on.

## Ledger cross-reference

Full claims, exact values, and verification status: `BBT-001`, `BBT-002` in the Quantum Contextuality project's `01-claims-ledger/ledger.json` (track `BBT`, "Black-box certification protocol").
