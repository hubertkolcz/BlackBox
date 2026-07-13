# Research objectives and deliverable map

This file is the repository-level statement of what the research is, verbatim from the *Quantum Contextuality* project definition, and the map from each objective to the modules, ledger claims, and verification commands that answer it. Status here is a pointer layer: exact values and provenance live in the claims ledger (`docs/ledger-snapshot/`, canonical copy in the project's `01-claims-ledger/ledger.json`); narrative history lives in `docs/QUANTUM_CONTEXTUALITY.md`.

## Title

**Evaluating black-box physics through optical emulation.**

## Description (verbatim)

> This research aims to structure the certification of a black box's physics by assessing whether an efficient classical optical emulation of its behavior exists, combining correlation-based classification of measurement statistics with Lie-algebraic criteria for resource scaling. The central question is: given only black-box access, under what conditions is it mathematically impossible to distinguish a genuinely quantum device from a classical optical emulation at the level of input–output behavior? As an application, the framework is illustrated on the classical emulatability of Hawking-radiation dynamics. The research will further assess the feasibility of extending the correlation taxonomy to signaling and quantum-communication scenarios.

**Stated priority question:** can the Abramsky–Brandenburger sheaf be used for deduction over graph-probabilistic settings — calculating local–global relations of Global-Exclusivity graphs built as products of KCBS 5-cycle graphs?

**Deliverable:** a WSRI computational essay (project-side `03-essays-and-notebooks/ComputationalEssay.nb`, following `EssayTemplate.nb` and Wolfram's "What Is a Computational Essay?" guidelines) with all quantitative claims kernel-verified by the modules in this repository.

**Foundations:** Cabello arXiv:1210.2988 (Global Exclusivity); Ulrey IJQF 8 (2022) 31–116 = arXiv:2001.09756 (operational taxonomy, argued here to be EPRB-scenario-bound); Abramsky–Brandenburger arXiv:1102.0264 (sheaf formulation); CSW arXiv:1010.2163 (graph approach). Companion repository: [Lie-Poisson geometric criteria for classical optical emulation in MBQC](https://github.com/hubertkolcz/Lie-Poisson-geometric-criteria-for-classical-optical-emulation-in-MBQC).

## Objective → deliverable map

| # | Objective (from the description) | Module(s) | Ledger claims | Verify with | Status (2026-07-13) |
|---|---|---|---|---|---|
| O1 | Correlation-based classification of measurement statistics | `01-D2-core-computation/` | `FOUND-001..004`, `GE-001`, `CF-001..004` | `RunEssay.wl`, `RunLedger.wl`, `RunSignedNegativity.wl`, `RunEpilogue.wl` | **Delivered** (exact invariants, GE at 2 copies, CF with primal+dual LP certificates, unconditional odd-n-cycle CF=(n−1)ν re-derivation) |
| O2 | Lie-algebraic criteria for resource scaling | `BlackBox/` (`LP-001` interface), `03-MESH/fem_study.py`, `04-cluster-state-mbqc/cct_cluster_dla.wl` | `LP-001`, `LP-002`, `LP-003` | `BlackBoxTests.wl`; `fem_study.py`; `cct_cluster_dla.wl` | **Partial** — interface + headline negative result (DLA and CF decorrelate under composition); DLA wall at ~2 pentagons; claims still need literature-scoped formalization (REVIEW §4) |
| O3 | Central question: conditions for mathematical indistinguishability from classical optical emulation | `00-BBT-blackbox-protocol/` | `BBT-001`, `BBT-002` | `python3 mbqc_blackbox_test.py`; `RunBlackboxProtocol.wl` | **Operationalized + formalized** — pre-registered protocol incl. the geometric gate G7 (DLA audit of claimed compilations); the exact-tuning blind spot (`BBT-002`) stated as Proposition 1 with assumptions A1–A4, plus Proposition 2 (no table functional certifies the DLA) in `00-BBT-blackbox-protocol/PROPOSITION-O3.md`; open: interventional DLA bounding (OQ1), attenuation gate (OQ2) |
| O4 | Illustration on Hawking-radiation dynamics | `08-HK-hawking/` | `HK-001..005` | `hawking_cs_route.py`, `hawking_cf_bridge.py` | **Delivered (structural negative)** — the experiments' Cauchy–Schwarz witness is single-context ⇒ CF ≡ 0; Wigner route foreclosed (Gaussian); unclaimed ground per 2026-07-13 literature pass |
| O5 | Feasibility: taxonomy extension to signaling / quantum communication | `07-SIG-signaling/` | `SIG-001..003` | `RunSignalingTaxonomy.wl` | **Feasibility delivered** — 3-gate taxonomy on 7 exemplars; exact communication-cost identity; one candidate identity refuted (kept as negative result) |
| P | Priority: AB-sheaf derivation of local–global relations for GE products of C₅ | `06-D3-sheaf-cohomology/`, `BlackBox/` Čech layer | `SH-001..008`, `ESSAY-005` | `RunSupportCohomology.wl` | **Open, obstacle identified** — AB Prop. 9.3/9.4 separates Bell covers from CSW covers (`SH-006`); raw material ready (`SH-005`); two acceptable outcomes defined in project `ROADMAP.md` |
| D1 | (Supporting frontier) Does GE-with-copies single out ϑ(G) for every G? | `02-D1-theory-frontier/` | `GE-002..004`, `ERG-001..003` | `RunD1GECopiesSweep.wl`, `RunD1K3Activation.wl`, `RunHeptagonCatalysis.wl` | **Numerics only, by design** — heptagon catalysis proven; nonagon cell open; engage arXiv:2411.09773 (external no-activation theorems for n≥6 cycles) |
| MESH | (Supporting composition theory) pentagon gluing | `03-MESH-pentagon-composition/`, `05-CERT-epsilon-certificates/` | `MESH-001..009`, `CERT-001..002` | `RunCaseStudies.wl`, `trans_chain_proofs.py`, `EpsilonCertificate*.wl` | **Delivered with named open ends** — cis/trans laws, τ\* closed form, (cct)^∞ optimum ε-certified (bracket [0.069898, 0.075309]); global optimality open |
| MBQC | (Emerging) cluster-state realization at scale | `04-cluster-state-mbqc/` | `MESH-007..008`, `LP-003` | `cct_cluster_lie_poisson_bridge.wl` | **Emerging, uncommitted** — commit first (REVIEW P0); stabilizer verified to ~10⁶ qubits, AvN to N=3 (locality confirmed at 1800 qubits), DLA wall real |

## Reporting rules

1. New quantitative claim ⇒ ledger entry first, module verification second, narrative third.
2. Every number printed in the essay must be produced by a kernel-verified module, not restated by hand.
3. Negative results, failed gates, and withdrawn claims stay first-class citizens (they are this project's credibility signature).
4. This file's status column is refreshed with each research push; the review that introduced it: `docs/REVIEW-2026-07-13.md`.
