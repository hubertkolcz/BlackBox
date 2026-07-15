# 10-VIZ-visual-gallery

New module, added 2026-07-14. Purely a presentation layer: every figure here re-renders a fact that is already kernel-verified elsewhere in the repo (`03-MESH-pentagon-composition` / GE-002 for the hypergraph, `00-BBT-blackbox-protocol` / G7 for the leaf-confinement sphere) — this module adds no new claims, only visualizations of existing ones, plus a restyle pass over a couple of pre-existing figures in other modules. Two matched themes run through everything: **Paper** (white background, muted ink, for embedding in the essay/PDF) and **Gallery** (dark cinematic background, for a standalone showcase).

## Contents

- `ge_pentad_hypergraph.wl` → `figures/hypergraph_{paper,gallery}.{png,pdf}` — the GE two-copy exclusivity graph for KCBS (Cabello arXiv:1210.2988) rendered as its own hypergraph object: 25 vertices (C5×C5), 200 exclusivity edges, 10 maximal 5-cliques ("pentads") drawn as translucent overlapping stars in a pentagon-of-pentagons layout. Structural facts are re-derived and gated (`structureOK`) against the project's own prior count, not assumed. Ledger: GE-002, MESH-006.
- `so3_leaf_confinement_sphere.wl` → `figures/leaf_sphere_{paper,gallery}.{png,pdf}` — the geometric content of the so(3) dynamical-Lie-algebra rank test that gates "emulable" vs "genuine" for the KCBS cascade. A single so(3) generator's orbit is a circle (red "leaf", DLA=1); the actual 4-generator cascade's orbit fills the 2-sphere (blue cloud, DLA=3). Both numbers, plus the intermediate span=2 fact, are recomputed from the verbatim `KCBSDirections`/`CascadeGenerators`/`So3Axis`/`DLADimension` functions in `BlackBox/Kernel/BlackBox.wl` and hard-gated (`factsOK`) before export. Ledger: G7 (`LeafConfinementAudit`, `BlackBoxCertifier.wl`), Corollary 2 / the "2→3 anchor" (`PROPOSITION-O3.md`).
- `VisualGallery.nb` — computational-essay notebook (per `EssayTemplate.nb` / Wolfram's "What Is a Computational Essay?" conventions) walking through both pieces above: narrative text, the actual verification code as live input cells, and the rendered figures with captions tying each back to its ledger ID.
- `figures/` — the exported PNG/PDF pairs for both pieces above, both themes.

Two other, older figures were restyled in place as part of this same visual-quality pass but **live in their own modules, not here**: `05-CERT-epsilon-certificates/orbit_spectrum_figure.wl` and `09-EMU-optical-compiler/DemoBlueprints.wl`. They're cross-referenced from `VisualGallery.nb` rather than duplicated.

## Honest framing note (read before extending this module)

Every quantitative fact drawn on these figures (25/200/10-pentad counts; nGenerators=4, span=2, dlaFull=3, dlaLeaf=1) is recomputed in-script from source and hard-gated with `Abort[]` on mismatch — the scripts refuse to export a figure whose numbers disagree with the project's own prior verification. Colors, layout, and theme choices carry no data significance.

Deployed PNGs in `figures/` received one additional post-export step not expressed in the `.wl` source: a deterministic whitespace-only crop (documented in each script's header comment) removing Mathematica's default large `PlotLabel`-to-scene gap. Deployed PDFs received a plain `CropBox` restriction only (no content-stream edits). Re-running a `.wl` script reproduces the physics and the untrimmed figure; it will not by itself reproduce the tight crop — see the header comment in each script for the exact parameters used.

While building the leaf-confinement sphere, cross-referencing `09-EMU-optical-compiler/blueprints/demo3_cct_mesh_reps2.wl` found that cct-mesh demo blueprints hardcoded `LeafConfined -> True` rather than computing it via `DLADimension`, and a second, disagreeing content-blind shortcut existed in `BlackBoxCertifier.wl`. This figure deliberately recomputes leaf-confinement from first principles instead of resting on either. **Update 2026-07-14, same day:** followed up as a full repo audit (user request) and fixed — `EmitBlueprint`, `VerifyBlueprint`, and `blueprintDLA` now honestly propagate `Missing["NotComputed"]` for Mesh blueprints instead of a fabricated verdict; no real mesh-DLA test exists yet to replace it with (that's new research, not a code fix — see ledger `ISSUE-024`). Logged as `ISSUE-024` (open item) and `ISSUE-025` (a batch of smaller, now fully-resolved hardcoded-value bugs found in the same audit) in `01-claims-ledger/ledger.json`.

Considered and deliberately **not** built in this pass, given the effort already spent resolving a base64-relay/large-payload issue with the remote kernel this session: a genuine Wolfram multiway-system rendering of the pentagon-chain `{c,t}`-word composition space, a cluster-state MBQC graph piece, and a shared `BlackBoxVisualTheme.wl` factoring out the Paper/Gallery palette logic currently duplicated between the two `.wl` scripts here. Reasonable follow-ups, not started.

## Relationship to the primary module

Feeds the essay's illustration needs (`docs/ESSAY-OUTLINE.md`) and `00-BBT-blackbox-protocol`'s G7 gate narrative. Not imported by any certifier or test code — this module is presentation-only and has no downstream computational dependents.

## Ledger cross-reference

GE-002, MESH-006, G7, Corollary 2 (`PROPOSITION-O3.md`). Figures re-verify, and do not extend, these results.
