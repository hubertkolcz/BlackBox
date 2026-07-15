# Positioning note: BlackBoxCertifier.wl + ConstructCertifyLoop.nb (2026-07-14)

What this delivers, checked against the project's stated research goals (`RESEARCH.md`, the
claims ledger) and the literature it cites. Written as a candid self-audit, not a summary.

## What was built

Two new files in `00-BBT-blackbox-protocol/`:

- **BlackBoxCertifier.wl** — a native-Wolfram-Language port of `mbqc_blackbox_test.py`'s
  correlation gates (C1-C5), plus the project's later gate family (G7 DLA hook, eta*, G9, G8,
  OQ1), wired directly onto the 09-EMU blueprint schema (`BlueprintTable`, `CertifyBlueprint`).
  It is the missing bridge that lets a single Wolfram session run 09-EMU's own stated loop
  ("00-BBT certifies; 09-EMU builds") without shelling out to Python.
- **ConstructCertifyLoop.nb** — a computational essay that states the four-category taxonomy
  the user asked to have organized explicitly (device metrics / engine self-validation / engine
  trust boundary / engine access-expansion), diagrams it, and runs the construct-certify-verdict
  loop live on three blueprints: a genuine KCBS cascade, a declared intensity emulator, and a
  mesh-composed device. All quantitative results in the essay's Sections 3, 5, and 7 were
  evaluated in a Wolfram kernel during construction (not asserted); Section 6's G8/G9/OQ1
  anchors are cited from `OQ-PROBE-SPEC-2026-07-13.md`, `g9_antibunching_gate.py`, and this
  project's own earlier kernel sessions, and were cross-checked word-for-word against those
  source files rather than re-derived.

## Fit against the research description

The project description asks for a framework "combining correlation-based classification of
measurement statistics with Lie-algebraic criteria for resource scaling." That sentence is a
near-literal description of what `TwoLensVerdict[ ]` does: `CertifyTable`/`TableVerdict` is the
correlation-based classification (C1-C5); `LeafConfinementAudit`/`blueprintDLA` is the
Lie-algebraic (so(3) DLA) criterion; `TwoLensVerdict` combines them. This is not a new idea —
it is BBT-002/BBT-003 (the ledger's "blind spot" and "two-lens necessity" propositions) — but it
had not previously been exercised through an actual constructed blueprint object end to end.
Section 7b of the notebook is the first place in the repository where Proposition 1 is
reproduced by literally constructing a 09-EMU-style blueprint, reading its table back out, and
watching the correlation lens alone misclassify it. That is a legitimate, if modest, new claim
(candidate ledger entry below) — everything under it (BBT-002, BBT-003, LP-001) is cited, not
re-derived.

Against the primary D2 track ("compute probabilistic exclusivity graphs under GE instead of
Hamiltonians — KCBS 5-cycle as atomic block") this module *is* the atomic-block layer: C3
(`CEFilter`) is a direct k=2 instantiation of Cabello's consistent-exclusivity principle
(arXiv:1210.2988) on the KCBS pentagon specifically. It does not attempt the cluster-state or
Quad-C5 composition layers above it (03-MESH, 04-cluster-state-mbqc already own that ground);
this module's contribution sits underneath those, at the single-block certification level.

## What is explicitly NOT claimed

- **D1 (does GE single out theta(G) for every graph?)** — untouched. Nothing here bears on the
  general question; C3 is exercised only on the pentagon, where the answer is already known.
- **G7-CV** — BBT-004/Prop O3-C's completeness theorem is stated over the gate set
  `{C1-C5, G7, G7-CV, G8}`. This module implements and exercises the discrete G7 (so(3)) hook
  only; G7-CV (the Sp(2n,R) continuous-variable audit, `final_o3_cv_dla.py`) is not ported. The
  essay's Section 8 states this explicitly rather than silently citing the full gate set as if
  it were all implemented here — a real, scoped gap, not an oversight to gloss over.
- **A_IE-maximality (H4')** — the essay repeats, and does not attempt to close, BBT-005's open
  status: whether the gate set remains complete for devices outside the intensity-emulator
  adversary class (heralded sources, PNR detectors, non-fair-sampling adversaries) is left open,
  exactly as the ledger already has it.
- **AB-sheaf local-global question (D3 priority)** — not engaged. The sheaf-theoretic route to
  computing local-global relations of GE graphs built as products of KCBS 5-cycles remains a
  separate, unstarted line of work; this module's CE-filter (C3) is a graph/LP-combinatorial
  tool, not a sheaf-cohomological one, and the two should not be conflated.
- **Hawking / signaling extensions** — untouched by design; those tracks (HK, SIG) have their
  own, already-delivered structural results (HK-003, SIG-003) that this module neither depends
  on nor feeds.

## Consistency with Ulrey's scenario-boundedness critique

The project's stance is that Ulrey's operational taxonomy is derived entirely inside the EPRB
scenario and its implications are scenario-bound. `BlackBoxCertifier.wl`'s gates are, by the
same discipline, explicitly KCBS-pentagon-scenario gates — `CertifyTable` takes a
`CycleScenario[5]` by default and nothing in the module claims the C1-C5/G7 combination
generalizes to an arbitrary exclusivity graph without re-deriving the relevant incidence
structure. That is a deliberate design choice, not a limitation discovered after the fact: it
keeps this module on the correct side of the same critique the project already levels at Ulrey.

## Literature cross-check

Every equation cited in the essay's Sections 3-6 was checked against its named source during
construction: the Glauber bound and the coherent/thermal/Fock g2(0) anchors against
`g9_antibunching_gate.py` (Glauber, *Phys. Rev.* 130, 2529 (1963)); the attenuation-grid,
N_G8, and Delta_min figures (0.041309 / 0.026413 / 0.014881 at z_max=0.20) against
`OQ-PROBE-SPEC-2026-07-13.md` verbatim; the OQ1 theta=0 singular-value anchor (~2.4266, third
singular value <=4e-11) against the same file. No figure in the essay was transcribed from
memory without this check. One number *was* caught and fixed by this check process itself: an
early draft of Section 7a guessed a residual of 6.7e-9 for the reconstructed-cascade-table
comparison without having actually run it; re-running it gave the true value, 1.665e-16
(machine epsilon), which is what the notebook now reports. A second issue caught the same way:
the notebook's Wright-table sanity check originally claimed a single triggering reason
(C5 alone); actually running it against the un-stubbed CE2 gate showed it also trips C3
(Wright's table is a textbook exclusivity-principle violation, not just a node-sum one) — the
essay's Output cell and surrounding text were corrected to show both reasons.

## Candidate ledger entry (proposed, not yet added to LEDGER.md)

| ID | Statement | Value | Tag | Class | Depends on | Status |
|---|---|---|---|---|---|---|
| BBT-006 | Native-WL bridge (`BlackBoxCertifier.wl`) wiring the C1-C5/G7/eta* correlation-plus-geometric certification protocol directly onto 09-EMU's blueprint schema (`BlueprintTable`, `CertifyBlueprint`), closing the "00-BBT certifies; 09-EMU builds" loop the repository's own README names. First live reproduction of Proposition 1 (BBT-002) and the two-lens override (BBT-003) through an actually-constructed blueprint object rather than a bare table. | `BlueprintTable[bpL1]` matches `QuantumTable[1]` to 1.665e-16 (machine epsilon); declared-adversary blueprint `bpL2` reads QUANTUM-CERTIFIED at the correlation level, EMULATION-SUSPECT after `TwoLensVerdict` (G7 override); mesh blueprint reads two-lens-agree QUANTUM-CERTIFIED with auto-audited DLA (span 2, dim 3) | NOVEL implementation; reuses BBT-002/BBT-003/LP-001 mathematics without modification | B (exact/kernel-verified numerics; not a new proof) | BBT-002, BBT-003, LP-001, EMU-001 | built + kernel-verified 2026-07-14; G7-CV not ported (scoped gap, see above); companion notebook ConstructCertifyLoop.nb |

## Bottom line

This is infrastructure, not a new result: it makes an already-proven claim (the two-lens
necessity of BBT-002/BBT-003) checkable end to end from an actual constructed device rather than
a hand-picked table, and it gives the project's growing gate family (C1-C9, G7-G9, OQ1-OQ2, eta*)
a single organizing map instead of a flat list. Every open question the project already had
(D1, A_IE-maximality, the AB-sheaf local-global question, G7-CV portability) is still open after
this work; none of them needed to be closed for this module to do its job.
