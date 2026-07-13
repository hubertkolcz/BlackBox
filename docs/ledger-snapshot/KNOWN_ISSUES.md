<!-- SNAPSHOT 2026-07-13 (post-amendment) of the canonical file in the Quantum Contextuality project's 01-claims-ledger/. Reflects the user-authorized 2026-07-13 ledger amendment (GE-002 retype, MESH-006 closure, BBT-002 annotation, BBT-003 addition). Do not edit here; regenerate from ledger.json and re-copy. -->

# KNOWN_ISSUES.md -- Data-Integrity Discrepancies Found During the Reorg Audit

Auto-rendered from `ledger.json -> issues` (single source of truth -- edit the JSON, re-run `render_ledger.py`).

These were found while exhaustively reading every file in both repositories for the claims ledger. None of these block using the project's headline results as listed in `LEDGER.md`; they are catalogued here so they can be deliberately resolved (or knowingly accepted) rather than silently forgotten. Severity is the auditor's judgment of how much it could mislead a reader if left unaddressed, not a claim about scientific validity.

| Severity | Count |
|---|---|
| high | 1 |
| medium | 6 |
| low | 8 |
| info | 6 |
| resolved | 1 |

---

## ISSUE-001 -- severity: high

No generator script for EpsilonCertificate.wl (k=7) or EpsilonCertificate8.wl (k=8) exists anywhere in the repo or its git history -- both were committed as complete, already-solved data files with no accompanying construction code. A reconstructed pipeline (GenerateEpsilonCertificate9.wl) exists but is explicitly labeled a skeleton, not a verified match to whatever originally produced the k=7/8 files.

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

Cross-file inconsistency in how rigorously the trans-chain $\alpha$-density formula is described: trans_chain_proofs.py presents a full, machine-checked QED proof of $\alpha(\text{open trans chain of } m \text{ pentagons}) = \lfloor 4(m+1)/3 \rfloor$; CaseStudies.wl calls the SAME formula 'CONJECTURED for all $m$' (only spot-checked $m=3..12$, verified to $m=800$).

**Files involved:** `trans_chain_proofs.py`, `CaseStudies.wl`

**Related claims:** MESH-005

## ISSUE-010 -- severity: medium

During THIS reorganization audit, independently compiling and running d1_k3_maxclique.c against d1_k3_graphs.py's own output graphs resolved two brackets that the project's own documents (d1_k3_activation.wl, d1-k3-brackets-2026-07-11.md) still list as open or as witness-only: C7^(OR3) proven exactly 8 (project docs left it at bracket [8,9]); Petersen^(OR3) proven exactly 12 (project docs / d1_k3_verify_witnesses.py call 12 only a 'lower-bound witness'). These resolutions are new findings from this audit, not yet reflected in the project's own tracking documents -- recommend folding back into d1-k3-brackets-2026-07-11.md or a successor note.

**Files involved:** `d1_k3_maxclique.c`, `d1_k3_activation.wl`, `d1_k3_verify_witnesses.py`, `d1-k3-brackets-2026-07-11.md`

**Related claims:** GE-003

## ISSUE-011 -- severity: medium

fem_study_results.json (the persisted results snapshot from the FEM/DLA-vs-CF study) contains ONLY the sanity-check stage, not the H1-H5 hypothesis results -- even though re-executing fem_study.py's main() during this audit successfully runs and prints all five hypotheses. Unclear whether the JSON was regenerated with a partial --stages flag after a full run, or whether a full run was never persisted to disk.

**Files involved:** `fem_study.py`, `fem_study_results.json`

**Related claims:** LP-002, MESH-002

## ISSUE-020 -- severity: medium

certificates/GenerateEpsilonCertificate10_cloud.wl (uncommitted, 12 July 2026) sets K=10 but was not fully updated after being copied from the k=9 cloud template: it still names its own output variable EpsilonCertificate9, still prints a k=9 run instruction, and its Stage-4 export target is literally "EpsilonCertificate9.wl" -- if run to completion locally (outside the cloud-submission pattern, which returns a self-contained diagnostic instead of relying on file retrieval) it would silently overwrite the real, already-ledgered CERT-002 certificate file with a k=10 result mislabeled as k=9. Checked and confirmed NOT yet triggered: the real EpsilonCertificate9.wl on disk still reads "k" -> 9 and is byte-identical to the last git commit. No Gamma_10 value exists anywhere in the repo yet.

**Files involved:** `GenerateEpsilonCertificate10_cloud.wl`, `EpsilonCertificate9.wl`

**Related claims:** CERT-001, CERT-002

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

RunAll.ps1 (the repo's 'one command verifies everything' script) and README.md's own command list each independently omit several `Run*.wl` launchers that actually exist in the repo (RunD1GECopiesSweep.wl, RunD1K3Activation.wl, RunSignalingTaxonomy.wl are missing from both; RunAll.ps1 additionally omits none else, README additionally omits RunEpilogue.wl and RunSignedNegativity.wl from its listed commands even though RunAll.ps1 does include those two) -- the automated verification sweep is not actually exhaustive over all runners present.

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

During verification of the MESH-007/008/009, LP-003, FOUND-003/004 extraction (this same 2026-07-12 session), a fresh `git status` on black-box showed 12 uncommitted working-tree files, not the 11 captured in `blackbox-cct-cluster-mbqc-2026-07-12.md` -- further evidence of concurrent activity on the repo during this audit window (same pattern as `ISSUE-019`). The 2 additional files are NOT yet extracted or ledgered as claims: `black-box-test/cct_cluster_lie_poisson_bridge_cloud_3M.wl` (820 lines, byte-identical in structure/length to the already-ledgered `cct_cluster_lie_poisson_bridge.wl`, with `nPentagonsRequested` set to 3,000,000 -- read only far enough to confirm it is a cloud-scale parameter variant of already-ledgered work, consistent with `MESH-007`'s reported millions-of-pentagons target, not a new method); and `black-box-test/cct_mbqc_scratch_topology.wl` (82 lines, self-labeled 'scratch' in its own header comment -- mesh-topology printouts at reps=1,2,3 plus an exploratory symbolic check comparing Pauli-product expectation values on a 3-qubit line cluster state (P3) against GHZ3 under local-Clifford (Hadamard) correction; print-based sanity checking with no headline verified conclusion, plausibly early groundwork toward generalizing `MESH-008`'s AvN argument beyond pentagons, but not read closely enough to characterize further). Recommend extracting both properly in a future session before treating either as settled.

**Files involved:** `black-box-test/cct_cluster_lie_poisson_bridge_cloud_3M.wl`, `black-box-test/cct_mbqc_scratch_topology.wl`

**Related claims:** MESH-007, MESH-008

## ISSUE-022 -- severity: info

During the 2026-07-13 goal-based module reorg of black-box (folding topic folders into numbered tracks matching this ledger's own track keys), a third wave of previously-unledgered uncommitted files was found sitting in black-box-test/ (same pattern as ISSUE-019/ISSUE-021, i.e. concurrent research activity during an audit/reorg window): `cct_mbqc_contextual_nand.wl`, `cct_mbqc_sim.wl`, and `cct_mbqc_sim_tests.wl`. None of the three is extracted or ledgered as a claim; read only far enough to characterize, not to verify. `cct_mbqc_contextual_nand.wl` (~180 lines by its own section structure) claims an exact, exhaustive-enumeration demonstration that the pentagon-mesh graph state carries GHZ triples powering the Anders-Browne (PRL 102, 050502 (2009)) contextual OR gate, plus a Mermin-type all-versus-nothing argument that no noncontextual/affine-GF(2) side-processor reproduces it -- a potentially headline-relevant result for the AB-sheaf/D3 backbone were it kernel-verified. `cct_mbqc_sim.wl` is a sparse CHP (Aaronson-Gottesman, PRA 70, 052328 (2004)) stabilizer simulator with destabilizers for MBQC patterns on the pentagon mesh, with its own explicit honesty caveat already in its header: since all targeted patterns are Clifford, Gottesman-Knill guarantees efficient classical simulability, so the claim is scale of faithful protocol execution, not quantum speedup -- the same stabilizer/AvN/DLA boundary already flagged in `04-cluster-state-mbqc/README.md`. `cct_mbqc_sim_tests.wl` is that simulator's validation suite (exact-arithmetic differential testing against a dense statevector reference). All three now physically live in `04-cluster-state-mbqc/` (moved during the reorg, alongside their 12 already-known siblings -- bringing the accurate current count of pre-existing uncommitted black-box research files to 15, not the 12 stated in `ISSUE-021`/`REFERENCE.md` at the time those were written); they remain uncommitted in git, per the reorg being kept separate from pre-existing research content. Recommend extracting and kernel-verifying all three properly in a future session before treating any of them as settled.

**Files involved:** `04-cluster-state-mbqc/cct_mbqc_contextual_nand.wl`, `04-cluster-state-mbqc/cct_mbqc_sim.wl`, `04-cluster-state-mbqc/cct_mbqc_sim_tests.wl`

**Related claims:** MESH-007, MESH-008

## ISSUE-018 -- severity: resolved

RESOLVED 2026-07-12. The black-box repo working tree had a pre-existing CRLF-vs-LF line-ending drift on ~82 files under BlackBox/ plus .gitignore (discovered during the reorg's git-index investigation), and a further 31 files elsewhere in the repo turned out to have been committed with CRLF in the first place. Fix: added .gitattributes at repo root (`* text=auto eol=lf`, with defensive 'binary' markers for common non-text extensions) and renormalized the whole tree (git commits 1c2df4c, 2764285 -- one file, runners/RunAll.ps1, needed a manual follow-up fix since git's own checkout skipped rewriting it once, tracked down via direct byte-level md5 comparison, not just git status). Verified at the byte level (not just via git status, which can report false-clean under eol normalization): every file outside the untouched .claude/worktrees/ copies now hexdumps to actual LF bytes matching its git blob exactly. Going forward, .gitattributes normalizes line endings on both commit and checkout automatically regardless of OS/editor, so this class of drift should not recur; if it ever does, the fix is 'git add --renormalize .' followed by removing and re-checking-out any file that still differs at the byte level (git's clean/smudge optimization can skip a rewrite it thinks is already-equivalent under the active eol policy).

**Files involved:** `BlackBox/*`, `.gitattributes (new)`, `runners/RunAll.ps1`
