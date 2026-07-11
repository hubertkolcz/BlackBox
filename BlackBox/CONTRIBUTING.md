# Contributing BlackBox to the Wolfram ecosystem

Official submission path and requirements, researched 10 July 2026 from
Wolfram's own guidance (URLs inline). Current state of this paclet against the
checklist is marked ☐/☑.

## Target: Wolfram Language Paclet Repository

The Paclet Repository is the official venue for multi-function libraries
(the Function Repository is for single standalone functions — see below).

### 1. Publisher ID (do this first — ~3 business days lead)

☐ Request a Publisher ID at
https://resources.wolframcloud.com/publisher/request-publisher-id
(tied to your Wolfram Cloud account; contact resource-reviewers@wolfram.com if
no confirmation). Workflow:
https://reference.wolfram.com/language/workflow/AcquireAResourceSystemPublisherID.html
This paclet assumes `HubertKolcz`; if the granted ID differs, rename in
PacletInfo.wl ("Name", "PublisherID", "PrimaryContext", Kernel "Context") and
the `BeginPackage` line of Kernel/BlackBox.wl.

### 2. Naming (hard requirements)

☑ Paclet name is `<PublisherID>/<Name>`: `HubertKolcz/BlackBox`.
☑ ALL exported symbols live in the publisher context `HubertKolcz`BlackBox``
  (symbols outside it fail the repository Check tool). Internals are in
  `HubertKolcz`BlackBox`Private``.
☑ Never modify System` symbols.
☑ Semantic version `XX.YY.ZZ`; bump on EVERY release.
☐ Consider the more descriptive name `HubertKolcz/QuantumContextuality` for
  repository discoverability (guidelines favor specific names); `BlackBox`
  matches this repo and the essay's thesis — either is legal.

### 3. Structure

☑ PacletInfo.wl with PacletObject at root: Name, Description, Creator,
  PublisherID, Version, WolframVersion (13.0+ — SemidefiniteOptimization needs
  12.0+, no GraphProduct dependency in the kernel code), License (mandatory),
  Kernel extension.
☑ Kernel/BlackBox.wl — single-context implementation, usage message for every
  exported symbol.
☑ Tests/BlackBoxTests.wl — 56-check battery (SmokeTest) + 3-check dedup layer
  against the kernel-verified pipeline values and the support-cohomology/AvN
  gates (`wolframscript -file BlackBoxTests.wl` → ALL PASS: True and
  DEDUP PASS: True).
☐ PROHIBITED in PacletInfo: `"Updating" -> Automatic`. (Not present ✓ —
  keep it that way.)

### 4. Documentation (pages exist; a polish pass remains before submission)

☑ One reference page (.nb) per exported symbol (all 26) under
  Documentation/English/ReferencePages/Symbols/ — headlessly generated
  skeletons: ObjectName + Usage (full sentences) + one Basic Example each.
  Remaining before submission: Scope sections (one example per input
  pattern), a palette-authoring/formatting pass, and a
  PacletDocumentationBuild run (Wolfram PacletTools) to compile them.
☑ One guide page (Documentation/English/Guides/BlackBox.nb) — intro text +
  one Item per exported symbol.
☑ Documentation extension present in PacletInfo.wl:
  `{"Documentation", "Root" -> "Documentation", "Language" -> "English"}`.
Guidelines: https://resources.wolframcloud.com/PacletRepository/guidelines
Tutorial: https://reference.wolfram.com/language/PacletTools/tutorial/CreatingPaclets.html

### 5. Dev / release loop

1. `PacletDirectoryLoad[<this directory>]` — in-place testing (dev copy wins
   over an installed copy at the same version).
2. `PacletBuild[<this directory>]` — distributable under build/ with manifest.
   Treat .paclet archives as build artifacts; do not commit them.
3. `PacletInstall` the built archive; verify clean install; reset with
   `PacletUninstall` / `PacletDirectoryUnload`.

### 6. Submission

1. `ResourceFunction["CreateResourceNotebook"]["Paclet"]` pointed at this
   directory → a Paclet Resource Definition Notebook.
2. Fill metadata, run the notebook's **Check** tool (this is what enforces the
   context rule), fix findings.
3. **Submit to Repository** in the notebook. Curator review takes a few days;
   feedback arrives as comment cells, tracked in the Resource System
   Contributor Portal.
Workflow: https://reference.wolfram.com/language/workflow/PrepareAPacletForPublication.html

## Alternative: Wolfram Function Repository (single functions)

For standalone contributions (e.g. `LovaszTheta` alone — no Lovász-theta
function exists anywhere in the resource system as of July 2026), the WFR is
lighter weight: one exposed symbol per submission, fully self-contained code,
SetDelayed definitions, imperative-verb description without final period,
usage lines as full sentences with periods, an example for every documented
input pattern, known limitations in Author Notes. Style guidelines:
https://resources.wolframcloud.com/FunctionRepository/style-guidelines
A family of interdependent functions (this library) belongs in the Paclet
Repository instead.

## Validation oracles (already wired into Tests/)

- `GraphData[{"Cycle",5}, "LovaszNumber" | "IndependenceNumber" |
  "FractionalChromaticNumber"]` → √5, 2, 5/2 — free exact oracles.
- SDP: default Tolerance, Method Automatic/"CSDP" (~1e-8 on ϑ(C₅)); do NOT
  tighten Tolerance (CSDP sticks at 1e-12); avoid "SCS" (~1e-3 error) and
  "PolyhedralApproximation" (wrong for ϑ-type SDPs).
- Exact certificates: use LinearOptimization with WorkingPrecision → ∞
  (SDP is machine-precision only).
