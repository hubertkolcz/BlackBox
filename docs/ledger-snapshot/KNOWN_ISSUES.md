# KNOWN_ISSUES.md -- Data-Integrity Discrepancies Found During the Reorg Audit

Auto-rendered from `ledger.json -> issues` (single source of truth -- edit the JSON, re-run `render_ledger.py`).

These were found while exhaustively reading every file in both repositories for the claims ledger. None of these block using the project's headline results as listed in `LEDGER.md`; they are catalogued here so they can be deliberately resolved (or knowingly accepted) rather than silently forgotten. Severity is the auditor's judgment of how much it could mislead a reader if left unaddressed, not a claim about scientific validity.

| Severity | Count |
|---|---|
| high | 0 |
| medium | 5 |
| low | 8 |
| info | 7 |
| resolved | 6 |

---

## ISSUE-001 -- severity: medium

No generator script for EpsilonCertificate.wl (k=7) or EpsilonCertificate8.wl (k=8) exists anywhere in the repo or its git history -- both were committed as complete, already-solved data files with no accompanying construction code. A reconstructed pipeline (GenerateEpsilonCertificate9.wl) exists but is explicitly labeled a skeleton, not a verified match to whatever originally produced the k=7/8 files. AMENDED 2026-07-13 (per docs/ledger-amendments-2026-07-13.md item 3): FUNCTIONAL provenance is now CLOSED -- the K-parameterized reconstruction (GenerateEpsilonCertificate{7,8}_cloud.wl, run on Wolfram Compute Services) regenerates the same construction, passes the identical exact verification, and converges STRICTLY TIGHTER than the committed files (Gamma_7' = 0.0770205710 exact-rational vs committed 0.07706235; Gamma_8' = 0.0752664136 numeric vs committed 0.07530856 -- committed values remain TRUE upper bounds, ~4.2e-5 / 0.054% suboptimal; all committed denominators divide 1e8, a decimal-grid rounding signature the reconstruction reproduces at 1e-9). BIT-LEVEL provenance of the two originally-committed files remains unrecoverable, which is why this is downgraded high->medium and kept as an accepted residual rather than closed outright. Evidence: 05-CERT-epsilon-certificates/PROVENANCE_K7_K8.md, EpsilonCertificate7_regenerated.wl, EpsilonCertificate8_regenerated.wl; see CERT-001.

**Files involved:** `EpsilonCertificate.wl`, `EpsilonCertificate8.wl`, `GenerateEpsilonCertificate9.wl`

**Related claims:** CERT-001, CERT-002

## ISSUE-002 -- severity: medium

Most essay notebooks (ComputationalEssay.nb, TheBlackBoxGame.nb) have ZERO cached kernel Output cells despite AI Disclosure text implying claims were re-executed in-notebook. Only Cech-Cohomology-of-Ulrey-Models-AB-Sheaf.nb has genuine cached outputs (21 Input / 18 Output cells). Headline numbers in the other essays are either prose-only or reference hardcoded/pasted arrays.

**Files involved:** `ComputationalEssay.nb`, `TheBlackBoxGame.nb`

**Related claims:** ESSAY-001, ESSAY-002, ESSAY-003, ESSAY-004

## ISSUE-003 -- severity: medium

Several of ComputationalEssay.nb's headline claims (the 61% gluing result, 'ten maximal cliques,' the full black-box certificate-stack outcome, the bit-cost decomposition) appear only as prose citing the external code repo [5], with no corresponding code cell in the essay notebook itself.

**Files involved:** `ComputationalEssay.nb`

**Related claims:** ESSAY-001, ESSAY-002

## ISSUE-005 -- severity: medium

Cross-file inconsistency in how rigorously the twisted-chain $\alpha$-density formula is described: twisted_chain_proofs.py presents a full, machine-checked QED proof of $\alpha(\text{open twisted chain of } m \text{ pentagons}) = \lfloor 4(m+1)/3 \rfloor$; CaseStudies.wl calls the SAME formula 'CONJECTURED for all $m$' (only spot-checked $m=3..12$, verified to $m=800$).

**Files involved:** `twisted_chain_proofs.py`, `CaseStudies.wl`

**Related claims:** MESH-005

## ISSUE-024 -- severity: medium

2026-07-14 audit (prompted by a visualization pass that needed the real leaf-confinement facts and found one couldn't be substantiated for ddt-word mesh blueprints) found that 09-EMU-optical-compiler/DispatcherEmitter.wl's EmitBlueprint hardcoded "LeafConfined"->True, "Verdict"->"emulable" for every Mesh-layer blueprint regardless of word/reps, sitting directly next to an honest Missing[] for the "Span"/"DLADimension" fields that verdict was supposedly derived from -- i.e. it asserted a conclusion while admitting its own inputs were never computed. VerifyBlueprint's gate A5 for Mesh layer could not catch this: its dlaOK check only compared bp["CertificationVerdict"]["Mesh"]["Layer"]==="Mesh", a tag set by the same hardcode moments earlier, tautological by construction. Independently, 00-BBT-blackbox-protocol/BlackBoxCertifier.wl's blueprintDLA had a SECOND, DIFFERENT content-blind shortcut for Mesh (LeafConfinementAudit[CascadeGenerators[]], called with no arguments, ignoring word/reps entirely) which evaluates to DLA=3/"genuine" -- the OPPOSITE conclusion from DispatcherEmitter's hardcode. The repo contained two disagreeing fabricated mesh verdicts. Investigated whether a real computation exists to wire in instead: the so(3) KCBS-cascade generators are scenario-specific and reusing them for an arbitrary mesh word could not be substantiated anywhere in the repo or git history; the su(2^n) cluster-state DLA route (04-cluster-state-mbqc/ddt_cluster_dla.wl, ddt_cluster_lie_poisson_bridge.wl) is representationally infeasible past ~14 qubits and demo3_ddt_mesh_reps2.wl's own reps=2 case is 18 qubits (SKIPPED_INFEASIBLE); the nearest real computation, fem_study.py's H5-stage per-block Lie closure, is Python (unported to the WL blueprint system) and its own conclusion section calls the compilation-frame gauge it depends on 'a modeling choice, not derived from first-principles coupled-mode coupling constants.' No content-aware, tractable mesh-DLA test currently exists anywhere in this repo. FIXED (honesty, not closure) 2026-07-14: EmitBlueprint's Mesh branch, VerifyBlueprint's gate-A5 Mesh dlaOK, and BlackBoxCertifier.wl's blueprintDLA all now honestly propagate Missing["NotComputed"]/Missing["NotAudited"] instead of a fabricated verdict; the committed demo3_ddt_mesh_reps2.wl data file and docs/essay-src/essay_sections_7_10.wl (prose + its EssaySectionsCVerification gate, which used to assert emuMeshLeafConfined via the same hardcode) were updated to match -- the essay's verification key was split into emuMeshTopologyVerified (genuinely true: the mesh routing/topology IS independently reconstructed and matched) and emuMeshLeafConfinementHonestlyOpen (true because it is honestly recorded as open, not because the question is resolved), mirroring the existing C7_honestly_left_open pattern in 02-D1-theory-frontier/d1_k3_activation.wl. REMAINS OPEN: a real per-block or whole-mesh DLA/leaf-confinement test for arbitrary (word,reps) mesh blueprints does not exist yet; building one is new research (a compilation-frame/gauge choice would need to be made and justified, or a poly-vs-exponential DLA-growth test -- the DESIGN.md 'poly-DLA' category -- would need to be implemented, neither of which exists anywhere in the repo today).

**Files involved:** `09-EMU-optical-compiler/DispatcherEmitter.wl`, `00-BBT-blackbox-protocol/BlackBoxCertifier.wl`, `09-EMU-optical-compiler/blueprints/demo3_ddt_mesh_reps2.wl`, `docs/essay-src/essay_sections_7_10.wl`, `04-cluster-state-mbqc/ddt_cluster_dla.wl`, `04-cluster-state-mbqc/ddt_cluster_lie_poisson_bridge.wl`, `03-MESH-pentagon-composition/fem_study.py`

**Related claims:** EMU-001, MESH-008, LP-003

## ISSUE-004 -- severity: low

'Higher Structures from Splitting Lie Algberas.nb' is an effectively empty stub: byte-identical cell UUIDs to EssayTemplate.nb, containing only one trivial dot-product test (`32=1*4+2*5+3*6`), no content about Lie algebras, splittings, or higher structures. Filename itself has a typo ('Algberas').

**Files involved:** `Higher Structures from Splitting Lie Algberas.nb`

## ISSUE-006 -- severity: low

realizability.py documents a correction to an earlier wrong critical-visibility figure ($v^*=\alpha/\theta \to 0.9685$, which used a wrong noise floor of 0) but still prints that exact superseded number later in the same file's main() without a caveat at that specific print site. The corrected figure is $v^*_{\text{iso}} \to 0.88484$.

**Files involved:** `realizability.py`

**Related claims:** MESH-004

## ISSUE-007 -- severity: low

BlackBox paclet's exported-symbol count is reported as three different numbers in three different places: README.md says 22, QUANTUM_CONTEXTUALITY.md says 27, and a direct count of Kernel/BlackBox.wl's ::usage declarations during this audit gives 29.

**Files involved:** `README.md`, `QUANTUM_CONTEXTUALITY.md`, `Kernel/BlackBox.wl`

## ISSUE-008 -- severity: low

CONTRIBUTING.md's paclet-submission checklist contains two stale claims: it says the test suite (SmokeTest) has 56 checks (actual count: 66); it says zero of the 29 symbol reference pages have a 'Scope' section yet (actual: 1, LovaszThetaSparse.nb, already has one).

**Files involved:** `CONTRIBUTING.md`, `Tests/BlackBoxTests.wl`

## ISSUE-009 -- severity: low

RunAll.ps1 (the repo's 'one command verifies everything' script) and README.md's own command list each independently omit several `Run*.wl` launchers that actually exist in the repo (RunD1GECopiesSweep.wl, RunD1K3Activation.wl, RunSignalingTaxonomy.wl are missing from both; RunAll.ps1 additionally omits none else, README additionally omits RunEpilogue.wl and RunSignedNegativity.wl from its listed commands even though RunAll.ps1 does include those two) -- the automated verification sweep is not actually exhaustive over all runners present. UPDATE 2026-07-13: runners/RunAll.sh was added in the reporting layer as the cross-platform sweep, but the coverage gap persists in new form -- RunAll.sh loops 13 runners + BlackBoxTests and omits the four newest 2026-07-13 runners (RunGaussianHawking.wl, RunGaussianWitnesses.wl, RunIntensityLayer.wl, RunOpticalCompiler.wl) that verification-log-2026-07-13.txt exercises individually (final tally 17/17 OK-gated runners green).

**Files involved:** `RunAll.ps1`, `README.md`

## ISSUE-012 -- severity: low

TheBlackBoxGame.nb's Concluding Remarks cites '[7]' for 'the operational taxonomy' (clearly meaning Ulrey's paper by context) but this notebook's own reference list has Ulrey nowhere in it -- its own [7] is a different paper (Ciliberto et al.). Likely a renumbering slip carried over from ComputationalEssay.nb, where Ulrey genuinely is reference [7].

**Files involved:** `TheBlackBoxGame.nb`

## ISSUE-013 -- severity: low

artifacts-2026-07-06/ (a dated snapshot folder) contains truncated copies of 2 files relative to their top-level originals: WSI-progress-report-2026-07-06.md (snapshot cuts off mid-word, missing the back half of the document) and bottom-up-vocabulary-1210-2988.md (snapshot cuts off mid-table). The other 5 files in the same snapshot are byte-identical to their top-level originals. Top-level originals are authoritative in both cases.

**Files involved:** `artifacts-2026-07-06/WSI-progress-report-2026-07-06.md`, `artifacts-2026-07-06/bottom-up-vocabulary-1210-2988.md`

## ISSUE-014 -- severity: low

WSI-progress-report-2026-07-06.md still contains a literal unfilled bracketed placeholder for a claimed Coq-formalization result ('[fill in: which definitions/results were formalized and what the check showed]'). The snapshot folder's own MANIFEST.md already flagged in July that this was never found in any session and should be filled in or removed before submitting the report to a mentor -- it remains unresolved as of this audit.

**Files involved:** `WSI-progress-report-2026-07-06.md`, `artifacts-2026-07-06/MANIFEST.md`

## ISSUE-015 -- severity: info

'Exercises/Chaos x Code - Challange.nb' is unrelated to the research corpus (a generic Wolfram Dataset-manipulation coding exercise about world records, no physics content). Likely saved into this project folder by accident; recommend confirming with Hubert whether to keep, move, or remove.

**Files involved:** `Exercises/Chaos x Code - Challange.nb`

## ISSUE-016 -- severity: info

ZeroSlackDiagnostic.py's docstring records, as past-tense narrative, that two suspected prompt-injection attempts occurred during the session that produced it (one urging a switch to local wolframscript against the user's real paid Wolfram Cloud account, another urging reliance on Reduce/FindInstance). Both were declined and reported to the user at the time, per the file's own account. This is historical content describing a past, already-handled incident -- not a live instruction, and nothing in it was acted upon during this reorganization.

**Files involved:** `ZeroSlackDiagnostic.py`

## ISSUE-017 -- severity: info

PaperKB (the source-literature audit system) has extracted verified nodes for only 1 of 10 tracked papers (cabello-2012-ge, 8 nodes / 4 kernel-verified overlay records). The other 9 -- including Abramsky-Brandenburger and Ulrey, both central to the D3 track -- have zero extracted nodes despite 2 of them having complete source text on disk. No paper KB is frozen or human-signed-off yet.

**Files involved:** `PaperKB/kb/*`

**Related claims:** SH-006, SH-007

## ISSUE-019 -- severity: info

During this reorg, EpsilonCertificate9.wl was found to exist at repo root, committed (0031a09/715b98f) after the original file inventory for this reorg was taken -- evidence of concurrent activity on this exact repo during the audit/reorg window (also visible as "2 commits ahead of origin/master" that predate the reorg commit). It was folded into certificates/ alongside its siblings once discovered; see CERT-002.

**Files involved:** `EpsilonCertificate9.wl`

**Related claims:** CERT-002

## ISSUE-021 -- severity: info

During verification of the MESH-007/008/009, LP-003, FOUND-003/004 extraction (this same 2026-07-12 session), a fresh `git status` on black-box showed 12 uncommitted working-tree files, not the 11 captured in `blackbox-ddt-cluster-mbqc-2026-07-12.md` -- further evidence of concurrent activity on the repo during this audit window (same pattern as `ISSUE-019`). The 2 additional files are NOT yet extracted or ledgered as claims: `black-box-test/ddt_cluster_lie_poisson_bridge_cloud_3M.wl` (820 lines, byte-identical in structure/length to the already-ledgered `ddt_cluster_lie_poisson_bridge.wl`, with `nPentagonsRequested` set to 3,000,000 -- read only far enough to confirm it is a cloud-scale parameter variant of already-ledgered work, consistent with `MESH-007`'s reported millions-of-pentagons target, not a new method); and `black-box-test/ddt_mbqc_scratch_topology.wl` (82 lines, self-labeled 'scratch' in its own header comment -- mesh-topology printouts at reps=1,2,3 plus an exploratory symbolic check comparing Pauli-product expectation values on a 3-qubit line cluster state (P3) against GHZ3 under local-Clifford (Hadamard) correction; print-based sanity checking with no headline verified conclusion, plausibly early groundwork toward generalizing `MESH-008`'s AvN argument beyond pentagons, but not read closely enough to characterize further). Recommend extracting both properly in a future session before treating either as settled.

**Files involved:** `black-box-test/ddt_cluster_lie_poisson_bridge_cloud_3M.wl`, `black-box-test/ddt_mbqc_scratch_topology.wl`

**Related claims:** MESH-007, MESH-008

## ISSUE-022 -- severity: info

During the 2026-07-13 goal-based module reorg of black-box (folding topic folders into numbered tracks matching this ledger's own track keys), a third wave of previously-unledgered uncommitted files was found sitting in black-box-test/ (same pattern as ISSUE-019/ISSUE-021, i.e. concurrent research activity during an audit/reorg window): `ddt_mbqc_contextual_nand.wl`, `ddt_mbqc_sim.wl`, and `ddt_mbqc_sim_tests.wl`. None of the three is extracted or ledgered as a claim; read only far enough to characterize, not to verify. `ddt_mbqc_contextual_nand.wl` (~180 lines by its own section structure) claims an exact, exhaustive-enumeration demonstration that the pentagon-mesh graph state carries GHZ triples powering the Anders-Browne (PRL 102, 050502 (2009)) contextual OR gate, plus a Mermin-type all-versus-nothing argument that no noncontextual/affine-GF(2) side-processor reproduces it -- a potentially headline-relevant result for the AB-sheaf/D3 backbone were it kernel-verified. `ddt_mbqc_sim.wl` is a sparse CHP (Aaronson-Gottesman, PRA 70, 052328 (2004)) stabilizer simulator with destabilizers for MBQC patterns on the pentagon mesh, with its own explicit honesty caveat already in its header: since all targeted patterns are Clifford, Gottesman-Knill guarantees efficient classical simulability, so the claim is scale of faithful protocol execution, not quantum speedup -- the same stabilizer/AvN/DLA boundary already flagged in `04-cluster-state-mbqc/README.md`. `ddt_mbqc_sim_tests.wl` is that simulator's validation suite (exact-arithmetic differential testing against a dense statevector reference). All three now physically live in `04-cluster-state-mbqc/` (moved during the reorg, alongside their 12 already-known siblings -- bringing the accurate current count of pre-existing uncommitted black-box research files to 15, not the 12 stated in `ISSUE-021`/`REFERENCE.md` at the time those were written); they remain uncommitted in git, per the reorg being kept separate from pre-existing research content. Recommend extracting and kernel-verifying all three properly in a future session before treating any of them as settled.

**Files involved:** `04-cluster-state-mbqc/ddt_mbqc_contextual_nand.wl`, `04-cluster-state-mbqc/ddt_mbqc_sim.wl`, `04-cluster-state-mbqc/ddt_mbqc_sim_tests.wl`

**Related claims:** MESH-007, MESH-008

## ISSUE-026 -- severity: info

Global naming migration executed 2026-07-16: the gluing alphabet c/t (cis/trans) was renamed to d/t (direct/twisted) across the entire black-box repo and the Quantum Contextuality project folder -- prose, code identifiers (directRing, twistedChainWL, alphaDirectTheorem, ...), WL/Python letter literals where they denote the gluing letter, pure-letter word tokens including all de Bruijn window keys in the EpsilonCertificate* data files (cct -> ddt, cttt -> dttt, ...), filenames (ddt_mbqc_*.wl, ddt_cluster_*.wl, twisted_chain_*.{wl,py}, final_ddt_*.py, ddt_optimality_pilot_*, demo3_ddt_mesh_reps2.*, mesh_ddt2.*, blackbox-ddt-cluster-mbqc-2026-07-12.md), and notebook text/code/output cells (EvaluatingBlackBoxPhysics-Illustrated.nb both copies, TheBlackBoxFramework.nb). Semantics are preserved: c -> d is a pure alphabet relabel, and d < t keeps the same lexicographic order as c < t, so necklace/bracelet canonical representatives are unchanged. Intentionally NOT renamed: "Phil. Trans." / "IEEE Trans." citations; the AvN party/role labels "a"/"b"/"c" in ddt_cluster_avn_witness.wl and ddt_cluster_lie_poisson_bridge*.wl (roleOf / roleCtxLetter -- that "c" is a party name, not a gluing letter); the SCS solver data key "c" (cost vector) in lovasz_theta_sparse.py; geometric vertex labels a/b/c in the glue-anatomy figures. Legacy c/t persists in: git history, *.log run records, EpsilonCertificate10_stage1_checkpoint.wxf (binary checkpoint, now STALE relative to the renamed K10 generator -- regenerate or discard before resuming), .bak/BAK-/pre* notebook snapshots, .claude/worktrees/* branch copies, one undeletable stale __pycache__/trans_chain_proofs.cpython-310.pyc, and the rendered text inside schematic PDF/PNGs (files renamed, content not re-rendered). CAVEAT: the rename is textual; no Wolfram kernel was available in the session, so the .wl/.nb corpus has NOT been re-executed post-rename -- re-run the test suites (ddt_mbqc_sim_tests.wl, ddt_mbqc_patterns_tests.wl, ddt_mbqc_hawking_*_tests.wl, CaseStudies QED checks) in Mathematica before trusting post-rename kernel output, and let the front end repair the notebooks' outline caches on first open. The Python side WAS smoke-tested post-rename: py_compile over all files passes; verify_glue_anatomy.py reports ALL OK (incl. theta(ddt^2)=8.347042185, cycle mean(T_d T_d T_t)=4); word_census.py at Pmax=3 reproduces gap(ddt)=0.0698975 > dtt 0.0603589 > t/tt/ttt 0.0433844 > dd/ddd/dt 0, matching the ledgered values exactly. Same-session ledger reconciliation: MESH-003's certified bracket updated from Gamma_8=0.0753086 to Gamma_10=0.0714575 (width ~0.0016, Gamma_9=0.0720260; source: composition-optimality/CONVERGENCE-ANALYSIS-2026-07-13.md, cf. resolved ISSUE-020), and docs/QUANTUM_CONTEXTUALITY.md's optimal-word section now cites the full period-18 census (~29,000 necklaces, word_census.py Pmax=18) alongside the older period-6/12 sweeps. POST-MIGRATION EXECUTION 2026-07-16 (same-day follow-up, Wolfram kernel available this time): the deferred WL re-execution is DONE and PASSES on the renamed corpus -- ddt_mbqc_sim_tests.wl (ALL SECTIONS PASS: 13,946 exact state comparisons 0 failures, 9M-qubit scale smoke test), ddt_mbqc_patterns_tests.wl (11 PASS 0 FAIL), ddt_mbqc_hawking_certification_tests.wl (ALL CERTIFICATION GATES PASS, 231 s), ddt_mbqc_hawking_evaporation_tests.wl (14 PASS 0 FAIL), and runners/RunCaseStudies.wl ends OK->True with all 28 checks True (renamed identifiers alphaDirectTheorem / directRingLaw / ddtDensityCharacterized execute in-kernel). The stale __pycache__/trans_chain_proofs.cpython-310.pyc was deleted. Census-depth reconciliation completed to its last instance: fem_study.py's H2 conclusion now cites the period-18 census (~29,000 necklaces) and Gamma_10 = 0.0714575 (superseding the stale 'periods <=12 / Gamma_7 = 0.07706235' sentence), and fem_study_results.json was regenerated by a full re-run (all 7 stages, all_ok=True; the executed FEM code itself emits d/t words). EpsilonCertificate10_stage1_checkpoint.wxf (stale: 46,080 c/t window-key strings, zero ddt) was DISCARDED 2026-07-16 via git rm (recoverable from history; any K10 resume must regenerate the checkpoint from the renamed generator). STILL OPEN: only the notebooks' outline-cache repair on first front-end open.

**Files involved:** `repo-wide (200+ files)`, `ddt_mbqc_*.wl`, `ddt_cluster_*.wl`, `twisted_chain_*.wl/.py`, `final_ddt_*.py`, `ddt_optimality_pilot_*`, `demo3_ddt_mesh_reps2.*`, `mesh_ddt2.*`, `EpsilonCertificate* (window keys)`, `EvaluatingBlackBoxPhysics-Illustrated.nb`, `TheBlackBoxFramework.nb`, `blackbox-ddt-cluster-mbqc-2026-07-12.md`

**Related claims:** MESH-001, MESH-002, MESH-003, MESH-007, CERT-001, CERT-002

## ISSUE-010 -- severity: resolved

During THIS reorganization audit, independently compiling and running d1_k3_maxclique.c against d1_k3_graphs.py's own output graphs resolved two brackets that the project's own documents (d1_k3_activation.wl, d1-k3-brackets-2026-07-11.md) still list as open or as witness-only: C7^(OR3) proven exactly 8 (project docs left it at bracket [8,9]); Petersen^(OR3) proven exactly 12 (project docs / d1_k3_verify_witnesses.py call 12 only a 'lower-bound witness'). These resolutions are new findings from this audit, not yet reflected in the project's own tracking documents -- recommend folding back into d1-k3-brackets-2026-07-11.md or a successor note. RESOLVED 2026-07-13 (per docs/ledger-amendments-2026-07-13.md item 4): fold-back complete via 02-D1-theory-frontier/d1-external-reconciliation-2026-07-13.md and the amended GE-003; independently reproduced -- d1_k3_maxclique.c recompiled fresh, omega(C7^OR3)=8 (116,109 nodes) and omega(Petersen^OR3)=12 (10,754,445 nodes) with node counts matching bit-for-bit; RunD1GECopiesSweep.wl ends OK->True after the fold-back fix (verification-log-2026-07-13.txt amendment 20:32: omega(Paley13^OR2)=13 exact, so S2(Paley13)=sqrt(13)=theta exactly).

**Files involved:** `d1_k3_maxclique.c`, `d1_k3_activation.wl`, `d1_k3_verify_witnesses.py`, `d1-k3-brackets-2026-07-11.md`

**Related claims:** GE-003

## ISSUE-011 -- severity: resolved

fem_study_results.json (the persisted results snapshot from the FEM/DLA-vs-CF study) contains ONLY the sanity-check stage, not the H1-H5 hypothesis results -- even though re-executing fem_study.py's main() during this audit successfully runs and prints all five hypotheses. Unclear whether the JSON was regenerated with a partial --stages flag after a full run, or whether a full run was never persisted to disk. RESOLVED 2026-07-13 (per docs/ledger-amendments-2026-07-13.md item 2): root cause was a partial `--stages sanity` invocation leaving a stale 2-key snapshot (1917 B, 2026-07-12 17:33); a full `python fem_study.py` re-run (exit 0, ~2.5 min) now persists all stages {h1,h2,h3,h4,h5,quad_edges,sanity} (20011 B), re-confirming LP-002 (Pearson r(sat_frac,CF) = -0.4294 vs r(AUC,CF) = +0.2662, 9 points, sign flip) and MESH-002 (direct pinch at N=3 & even N>=4; odd-N residual gaps 0.2361/0.3177/0.3601 at N=5/7/9). Source unchanged. Residuals flagged: the docstring-promised `gates` stage is silently ignored; direct-ring N=3 serializes a tiny negative LP epsilon.

**Files involved:** `fem_study.py`, `fem_study_results.json`

**Related claims:** LP-002, MESH-002

## ISSUE-018 -- severity: resolved

RESOLVED 2026-07-12. The black-box repo working tree had a pre-existing CRLF-vs-LF line-ending drift on ~82 files under BlackBox/ plus .gitignore (discovered during the reorg's git-index investigation), and a further 31 files elsewhere in the repo turned out to have been committed with CRLF in the first place. Fix: added .gitattributes at repo root (`* text=auto eol=lf`, with defensive 'binary' markers for common non-text extensions) and renormalized the whole tree (git commits 1c2df4c, 2764285 -- one file, runners/RunAll.ps1, needed a manual follow-up fix since git's own checkout skipped rewriting it once, tracked down via direct byte-level md5 comparison, not just git status). Verified at the byte level (not just via git status, which can report false-clean under eol normalization): every file outside the untouched .claude/worktrees/ copies now hexdumps to actual LF bytes matching its git blob exactly. Going forward, .gitattributes normalizes line endings on both commit and checkout automatically regardless of OS/editor, so this class of drift should not recur; if it ever does, the fix is 'git add --renormalize .' followed by removing and re-checking-out any file that still differs at the byte level (git's clean/smudge optimization can skip a rewrite it thinks is already-equivalent under the active eol policy).

**Files involved:** `BlackBox/*`, `.gitattributes (new)`, `runners/RunAll.ps1`

## ISSUE-020 -- severity: resolved

certificates/GenerateEpsilonCertificate10_cloud.wl (uncommitted, 12 July 2026) sets K=10 but was not fully updated after being copied from the k=9 cloud template: it still names its own output variable EpsilonCertificate9, still prints a k=9 run instruction, and its Stage-4 export target is literally "EpsilonCertificate9.wl" -- if run to completion locally (outside the cloud-submission pattern, which returns a self-contained diagnostic instead of relying on file retrieval) it would silently overwrite the real, already-ledgered CERT-002 certificate file with a k=10 result mislabeled as k=9. Checked and confirmed NOT yet triggered: the real EpsilonCertificate9.wl on disk still reads "k" -> 9 and is byte-identical to the last git commit. No Gamma_10 value exists anywhere in the repo yet. RESOLVED 2026-07-13: the k=10 generator was fixed in place (output variable, printed instruction, and Stage-4 export target all now k=10) during the same-day review pass, before any local run; the K=10 computation subsequently completed with deterministic seeds converging at round 3, giving Gamma_10 = 0.0714575 (numeric) -- see CERT-002/CERT-003 and 05-CERT-epsilon-certificates/CONVERGENCE-ANALYSIS-2026-07-13.md.

**Files involved:** `GenerateEpsilonCertificate10_cloud.wl`, `EpsilonCertificate9.wl`

**Related claims:** CERT-001, CERT-002

## ISSUE-023 -- severity: resolved

ledger.json was observed TRUNCATED on 2026-07-13c (70,972 bytes, ending inside the ESSAY-003 claim object, JSONDecodeError at line 933) while LEDGER.md rendered from the same 2026-07-13b sync was complete -- the 13b sync (65 claims) ran in a parallel session, and the truncation was observed through this session's sandbox view of the folder, so whether the on-disk file was itself cut mid-write or the view was stale for a recently-written file could not be determined post-hoc (the reconstruction overwrote it either way; the truncated-view bytes are preserved verbatim in ledger.json.bak-2026-07-13c-truncated). RESOLVED 2026-07-13c by programmatic reconstruction: 53 complete claims salvaged from the truncated view (including all four claims the 13b sync had UPDATED: CERT-001, CERT-002, GE-003, ERG-003); 9 claims (ESSAY-003/004/005, FOUND-003/004, LP-003, MESH-007/008/009) restored verbatim from ledger.json.bak-2026-07-13b, which the 13b sync had not touched; the 3 claims existing nowhere else in machine-readable form (MESH-010, LP-004, EMU-001) rebuilt from the rendered LEDGER.md rows (statement/value columns render untruncated, so those fields are exact) plus the module docs they cite (status fields re-expanded to match the rendered 137-char prefixes; their full original status/sources text beyond the render is the one thing not recoverable). Issues array restored from the .bak and then synced with black-box docs/ledger-amendments-2026-07-13.md (ISSUE-001 downgraded high->medium, ISSUE-010/ISSUE-011/ISSUE-020 resolved, ISSUE-009 updated). Verified by re-rendering: 65 claims, headline counts unchanged (NOVEL 57 / ESTABLISHED 5 / OPEN 2 / UNCLEAR 1), reconstructed rows byte-identical to the 13b render for all complete columns.

**Files involved:** `ledger.json`, `ledger.json.bak-2026-07-13b`, `ledger.json.bak-2026-07-13c-truncated`, `LEDGER.md`

**Related claims:** MESH-010, LP-004, EMU-001

## ISSUE-025 -- severity: resolved

Same 2026-07-14 audit, batch of smaller hardcoded-value-standing-in-for-computation bugs, all RESOLVED same day (unlike ISSUE-024, none of these had a remaining open research question -- each had a real computation already available one step away that just wasn't being used). (1) 04-cluster-state-mbqc/ddt_mesh_sparse_stabilizer.wl Section 1: the real per-rep edge-set match was computed correctly in a loop but only ever printed, never captured to an outer variable; the summary association asserted "Section1_FastConstructionExactMatch"->True as a disconnected bare literal with no Abort/assert guard anywhere in the file, so a real mismatch at any tested size would have printed False in the log while the scoreboard still claimed True. Fixed: collected into section1Matches/section1AllMatch, summary and print both now reference it. (2) 02-D1-theory-frontier/d1_k3_activation.wl line 99: "directCEFilterAttempted"->True hardcoded unconditionally even though its own comment admitted the underlying attempts can return Missing["NotAttempted-TimedOut"] on a timeout. Fixed: now !MissingQ on both attempts' Passes fields. (3) 04-cluster-state-mbqc/ddt_mbqc_sim.wl lines ~631 and ~673: "AllOK"/"AllPass" were bare True next to genuinely-computed sibling booleans that were never actually conjoined (mitigated in practice since every contributing check is separately wrapped in DDTAssert, which Abort[]s on failure -- so this was tautologically safe today, just structurally misrepresentative). Fixed: real AND expressions, matching the already-correct pattern in the companion file ddt_mbqc_sim_tests.wl. (4) 05-CERT-epsilon-certificates/debug/debug_psd_check.wl Stage 3: pointwiseOK checked posSigma9[e]<=GammaExact where GammaExact:=Max[posSigma9/@edges] -- true by construction for any list, zero protection -- the EXACT bug already found, root-caused, and fixed in the canonical pipeline (../GenerateEpsilonCertificate9.wl's own 'BUG FOUND AND FIXED (12 July 2026, adversarial review...)' comment); this debug copy was never updated to match. Fixed by porting the canonical targetGamma/GAMMADRIFTTOL/gammaCrossCheckOK pattern verbatim; re-verified independently in a fresh kernel run at K=3 (GammaExact and targetGamma both landed within 7e-9 of the documented Gamma_3=0.125, pointwiseOK/gammaCrossCheckOK both True). Also fixed in the same file: the exported certificate's filename/label hardcoded "EpsilonCertificate9" regardless of the K parameter (defaults to K=4 for smoke-testing) -- harmless in that SetDirectory confines it to debug/, never the canonical certificates/ tree, but still a stale-label bug in the same family as ISSUE-020; now genuinely tracks K.

**Files involved:** `04-cluster-state-mbqc/ddt_mesh_sparse_stabilizer.wl`, `02-D1-theory-frontier/d1_k3_activation.wl`, `04-cluster-state-mbqc/ddt_mbqc_sim.wl`, `05-CERT-epsilon-certificates/debug/debug_psd_check.wl`

**Related claims:** MESH-007, MESH-008
