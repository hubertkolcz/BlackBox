# Maintenance — git recovery, commit plan, release checklist

Written 2026-07-13 alongside `REVIEW-2026-07-13.md`. Everything here runs on the Windows side (PowerShell in the repo root `C:\Users\cp\Desktop\black-box`), because the review session's sandbox cannot modify `.git`.

## 1. One-time git recovery (do this first)

A stale `.git\index.lock` blocks all git operations (left by an interrupted git process; additionally an empty probe file `.git\_writetest` was left by the 2026-07-13 review session — both are safe to delete):

```powershell
Remove-Item .git\index.lock
Remove-Item .git\_writetest -ErrorAction SilentlyContinue
git status   # should now run clean
```

## 2. Commit the outstanding work (16 files + review artifacts)

`ISSUE-020` was **already fixed in-place on 2026-07-13** (Stage-4 export filename, packaged symbol, and header of `GenerateEpsilonCertificate10_cloud.wl` now all say 10) — verify with `git diff` when staging, and mark `ISSUE-020` resolved in the ledger.

Suggested logical commits:

```powershell
# 1: the emerging MBQC module (spans MESH-007/008, LP-003)
git add 04-cluster-state-mbqc/
git commit -m "Add cluster-state MBQC module: sparse cct-mesh stabilizer, AvN witness, DLA wall (MESH-007/008, LP-003)"

# 2: D2 + MESH additions
git add 01-D2-core-computation/kcbs_circuit_ncycle.wl 01-D2-core-computation/kcbs_sequential_game.wl 03-MESH-pentagon-composition/trans_chain_density_check.wl
git commit -m "Add n-cycle circuit essay, sequential game, trans-chain density check (FOUND-003/004, MESH-009)"

# 3: fixed k=10 generator
git add 05-CERT-epsilon-certificates/GenerateEpsilonCertificate10_cloud.wl
git commit -m "Add k=10 certificate generator with ISSUE-020 filename fix"

# 4: review + reporting layer (this review's additions)
git add README.md RESEARCH.md CITATION.cff requirements.txt docs/ runners/RunAll.sh
git commit -m "Add reporting layer: objectives, review 2026-07-13, related-work, ledger snapshot, maintenance, citation/deps scaffolding"

# 5: remove the byte-identical duplicate
git rm 08-HK-hawking/NOTES-hawking-2-precommit-draft.md
git commit -m "Remove byte-identical precommit draft of NOTES-hawking-2"
```

## 3. Publish (open thread since 2026-07-10)

```powershell
gh auth login                  # token for hubertkolcz was invalid
# decide: hubertkolcz personal vs WaverQ org; then
gh repo create <owner>/black-box --source . --remote origin --public   # or --private
git push -u origin master
```

After pushing: enable the two-tier CI from `REVIEW-2026-07-13.md` §3 (Python verifications + link checks hosted; WL battery local with committed logs).

## 4. Release checklist (per research push)

1. Ledger first: add/update claims in `01-claims-ledger/ledger.json` (project side), regenerate `LEDGER.md`.
2. Run the affected `runners/Run<Name>.wl`; confirm `OK -> True`; save the run log.
3. Refresh `RESEARCH.md` status column; refresh `docs/ledger-snapshot/` if claims changed.
4. Dated pointer note in the project's `07-progress-reports-and-history/` (commits + claim IDs, no restated values).
5. Commit with claim IDs in the message; push.

## 5. Known portability items

- `runners/RunAll.ps1` hardcodes `C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe` — parametrize via `$env:WOLFRAMSCRIPT` (fallback to the current literal). POSIX equivalent: `runners/RunAll.sh`.
- `05-CERT-epsilon-certificates/extract_pdf.wl` has a hardcoded expired path — historical artifact; move to `zz-attic/` when created.
- Python entry points assume `python3` on PATH with `requirements.txt` installed.
