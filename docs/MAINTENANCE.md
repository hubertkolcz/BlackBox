# Maintenance — git recovery, commit plan, release checklist

Originally written 2026-07-13 alongside `REVIEW-2026-07-13.md`.
**Refreshed 2026-07-13 (evening)** after the end-of-day research wave (O3 formalization,
04/08/09 module suites, the `TheBlackBoxFramework` master essay) and after the stale-lock
incident that stalled the content-update session. This version supersedes the morning one:
the git recovery is already done, the old commit plan's files are already committed, and the
repo is already published.

## 1. git lock recovery — what happened and how it was fixed

**Status: RESOLVED on 2026-07-13.** The repo was never actually corrupt. `.git/index` is a
valid `DIRC` v2 index (426 entries) that git reads cleanly. What blocked writes was a family
of **stale `*.lock` files** left by interrupted sessions:

- `.git/index.lock` (from the content-update session that hit its model-credit limit mid-`git`)
- `.git/_writetest` (leftover probe file)
- `.git/refs/heads/claude/{dla-cf-fem-study,hawking-emulation,signaling-taxonomy}.lock`
- `.git/worktrees/{dla-cf-fem-study,hawking-emulation,mbqc-blackbox-test,signaling-taxonomy}/HEAD.lock`
  and two `.../index.lock` (all dated 2026-07-10, from the interrupted branch-verification sessions)

All were 0 bytes; no git process held any of them; the four `claude/*` branches are 0 commits
ahead of master, so their ref locks guarded nothing. All were removed and `git status`,
`git add`, `git reset`, and `git fsck --full` now run clean.

### Why it happens (so it can be prevented)

git writes a `<operation>.lock` at the start of any index- or ref-modifying command and
renames it away on completion. If the process is interrupted *before* completion — a model/credit
limit mid-`git`, a sandbox torn down between calls, a killed editor — the lock is orphaned.
Reads (`git status`, `git log`) keep working, but the next write fails with
`Unable to create '.git/index.lock': File exists / Another git process seems to be running`
**even though none is.** That read-works/write-fails split is what reads as "corrupted, not just
locked." (The genuinely garbled-index symptoms seen earlier — `bad signature`, `unknown index
entry format` — were a *different* cause: the cross-view mount serving a truncated snapshot of
the index mid-write. Either way the index is derived state, rebuildable from HEAD.)

**Prevention:** don't interrupt a `git` write; commit in small, quick operations. If a session
is ending, let the current `git` finish before it stops.

### If it recurs — recovery recipe

From the Cowork sandbox (works, as of this session):

```bash
# one-time per folder, if rm reports "Operation not permitted": call allow_cowork_file_delete
find .git -name '*.lock'                 # list every stale lock
rm -f .git/index.lock .git/_writetest    # + any others listed above; safe when no git proc runs
git status                               # should run clean
```

Windows-side (PowerShell in `C:\Users\cp\Desktop\black-box`):

```powershell
Get-ChildItem -Recurse -Filter *.lock .git | Remove-Item
Remove-Item .git\_writetest -ErrorAction SilentlyContinue
git status
```

Only if `.git/index` itself is genuinely garbled (not just locked) — it is derived state, so
rebuild it without touching working-tree files or history:

```bash
rm -f .git/index && git reset            # rebuilds the index from HEAD
```

## 2. Outstanding work to commit

`git log` confirms the earlier plan's files are **already committed** (the MBQC module, the
n-cycle/sequential-game/twisted-chain additions, the k=10 generator with the `ISSUE-020` fix, and
the reporting layer all landed; `ISSUE-020` is resolved). Current outstanding state:

**A. One local commit already made, not yet pushed** — see §3.

- `38d3110` "ASSEMBLER: master computational essay TheBlackBoxFramework (.wl + .nb)"
  (`TheBlackBoxFramework.nb/.wl`, `runners/BuildBlackBoxFrameworkNotebook.wl`,
  `runners/RunBlackBoxFrameworkEssay.wl`, `runners/RunAll.ps1`).

**B. Uncommitted working-tree changes** (confirm claim IDs against `01-claims-ledger/ledger.json` before committing):

```powershell
# 1: regenerated optical-compiler schematics (EMU-001)
git add optical-synthesis/schematics/
git commit -m "Regenerate optical-synthesis schematics (KCBS/C7/ddt-mesh/table demos, L1-L2)"

# 2: new research source — D1 frontier, MESH hull/falsification, k6 cert, D3 sheaf duals
git add open-search-frontier/erg003_verdict.json `
        pentagon-gluing/final_ddt_falsify.py `
        pentagon-gluing/final_ddt_hull.py `
        composition-optimality/GenerateEpsilonCertificate_testK6_fast.wl `
        bound-derivation-question/final_h1_structured_duals.py
git commit -m "Add ddt-mesh hull/falsification, ERG-003 verdict, k6 cert gen, H1 structured duals"

# 3: remove the byte-identical Hawking precommit draft (hash a8cf20a0, == NOTES-hawking-2.md)
git rm hawking-application/NOTES-hawking-2-precommit-draft.md
git commit -m "Remove byte-identical precommit draft of NOTES-hawking-2"
```

**C. Transient logs — gitignore, do not commit.** These are run scratch, not results:
`open-search-frontier/sweep_logs/`, `composition-optimality/k6_gen.log`,
`bound-derivation-question/run2.out`. Extend `.gitignore` (it already ignores `bin/`, `p2_state/`,
`*.bin`, `__pycache__/`):

```
*.log
*.out
open-search-frontier/sweep_logs/
```

(If any run log should be *kept* as an audited artifact per §4.2, commit it explicitly and add a
matching `!path` un-ignore instead.)

## 3. Publish

The repo is already created and wired to a remote — no `gh repo create`/auth step remains:

```
origin  https://github.com/hubertkolcz/BlackBox.git
```

`master` is **1 commit ahead** of `origin/master` (the `TheBlackBoxFramework` essay). After the
§2 commits:

```powershell
git push origin master
```

After pushing: enable the two-tier CI from `REVIEW-2026-07-13.md` §3 (Python verifications +
link checks hosted; WL battery local with committed logs).

## 4. Release checklist (per research push)

1. Ledger first: add/update claims in `01-claims-ledger/ledger.json` (project side), regenerate `LEDGER.md`.
2. Run the affected `runners/Run<Name>.wl`; confirm `OK -> True`; save the run log.
3. Refresh `RESEARCH.md` status column; refresh `docs/ledger-snapshot/` if claims changed.
4. Dated pointer note in the project's `07-progress-reports-and-history/` (commits + claim IDs, no restated values).
5. Commit with claim IDs in the message; push.

## 5. Known portability items

- `runners/RunAll.ps1` hardcodes `C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe` — parametrize via `$env:WOLFRAMSCRIPT` (fallback to the current literal). POSIX equivalent: `runners/RunAll.sh`.
- `composition-optimality/extract_pdf.wl` has a hardcoded expired path — historical artifact; move to `zz-attic/` when created.
- Python entry points assume `python3` on PATH with `requirements.txt` installed.
