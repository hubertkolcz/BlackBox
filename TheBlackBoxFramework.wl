(* ::Package:: *)

(* ::Title:: *)
(*Evaluating Black-Box Physics through Optical Emulation*)

(* ::Subtitle:: *)
(*A two-lens certification theory, complete under five named hypotheses -- the master computational essay (assembler over Section Builders A, B, C)*)

(* ::Text:: *)
(*Hubert Kolcz -- July 2026. This is the master computational essay of the black-box repository. It assembles the three commissioned section fragments -- docs/essay-src/essay_sections_1_3.wl (Builder A: the pentagon atom, the located blind spot, the two irreducible lenses), essay_sections_4_6.wl (Builder B: mesh composition, the degree-0 sheaf derivation, the Hawking two-sector illustration), and essay_sections_7_10.wl (Builder C: the constructive mirror, the gates that failed, the named-hypothesis frontier, methods) -- into one Get-loadable, headless-verifiable document. Design contract: docs/ESSAY-OUTLINE.md; layer/hypothesis architecture: docs/FRAMEWORK-2026-07-13.md. Run headless via runners/RunBlackBoxFrameworkEssay.wl.*)

(* ::Text:: *)
(*Abstract (answers the RESEARCH.md description). Given only black-box access, under what conditions is it mathematically impossible to distinguish a genuinely quantum device from a classical optical emulation at the level of input-output behavior? The essay answers by structuring certification as two provably irreducible lenses -- a correlation lens (graph invariants of measurement statistics) and a geometric lens (the dynamical Lie algebra pricing resource scaling) -- and proving neither is derivable from the other. On the KCBS pentagon it computes the atomic hierarchy classical 2 < quantum Sqrt[5] < exclusivity-only 5/2; states the exact indistinguishability blind spot as a proposition; and closes it, class-relatively, with a completeness theorem over the intensity-emulator adversary class. It then develops an exact composition algebra (pentagon-mesh gluing), a degree-0 sheaf derivation of the composed exclusivity bound, and illustrates the framework on the classical emulatability of Hawking-radiation dynamics. It states the framework completely: the established layer unconditionally, then the five named open hypotheses (H1, H1', H2', H3, H4', H5) with proof targets.*)

(* ::Text:: *)
(*THE PRIME DIRECTIVE (WSRI): every quantitative claim in this essay is produced by the kernel at evaluation time -- via Get of the repository's verified section modules (each of which loads the HubertKolcz`BlackBox` paclet, recomputes its probe mathematics, or reads a committed exact-arithmetic certificate) -- never hand-restated. Labeling discipline mirrors the framework: [T] theorem/machine-verified, [C] certified numeric, [R] refuted route (a first-class negative), [H] named hypothesis (open). The essay is a computation that happens to read as prose; it closes on EssayVerification, whose "OK" key must evaluate True and which also reports a global count of the live-computed numbers.*)

(* ::Section:: *)
(*Assembly loader*)

(* ::CodeText:: *)
(*Locate the repository root robustly -- whether this document is opened and evaluated as a notebook (NotebookDirectory[]) or Get-loaded headless (DirectoryName[$InputFileName]) -- by walking up until the BlackBox paclet marker is found. This makes the essay render clean under interactive "Evaluate Notebook" as well as the headless runner. Then load the BlackBox paclet and repair the Global`-shadowing pitfall (documented in CertifyingQuantumness.wl / RunEssay.wl). Each Get-loaded section repeats this defensively; doing it here first lets the master's own verification cell reference paclet symbols directly.*)

(* ::Input:: *)
frameworkRoot = Module[{start, root},
   start = With[{f = $InputFileName},
     If[StringQ[f] && f =!= "" && FileExistsQ[f], DirectoryName[f],
       Quiet@Check[NotebookDirectory[], Directory[]]]];
   If[! StringQ[start] || start === "", start = Directory[]];
   root = NestWhile[ParentDirectory, start,
     (# =!= ParentDirectory[#]) &&
       ! FileExistsQ[FileNameJoin[{#, "BlackBox", "PacletInfo.wl"}]] &];
   If[FileExistsQ[FileNameJoin[{root, "BlackBox", "PacletInfo.wl"}]], root, start]];
PacletDirectoryLoad[FileNameJoin[{frameworkRoot, "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"];
Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];
frameworkRoot

(* ::CodeText:: *)
(*Assemble the essay: Get each section fragment in order. Get (not -file) so each fragment's loader cell de-shadows before its paclet symbols are tokenised. Each fragment leaves its own verification association in the Global context (sectionsVerification, SectionsFourToSixVerification, EssaySectionsCVerification) together with every live-computed quantity it defined -- the master reads those directly below.*)

(* ::Input:: *)
Get[FileNameJoin[{frameworkRoot, "docs", "essay-src", "essay_sections_1_3.wl"}]];
Get[FileNameJoin[{frameworkRoot, "docs", "essay-src", "essay_sections_4_6.wl"}]];
Get[FileNameJoin[{frameworkRoot, "docs", "essay-src", "essay_sections_7_10.wl"}]];

(* ::Section:: *)
(*Global verification (the essay's OK -> True contract)*)

(* ::CodeText:: *)
(*The global count of live-computed numbers. Each entry below is a live kernel object defined by one of the three section fragments (never re-typed here); Flatten reduces lists/tables to their scalar numeric leaves and Select keeps the genuinely numeric ones. This count is the essay's headline WSRI metric: the number of distinct quantities the document computes rather than asserts.*)

(* ::Input:: *)
liveNumberList = Select[Flatten[{
    (* S1 atom *) atomHierarchy, atomOracle, atomAxisSum,
    (* S2 blind spot *) blindSpotDelta, sharedCF, emulatorNodeSum,
    (* S3 geometric lens *) g7AxisRank, g7CascadeDLA, g7LeafDLA,
    oq1RankQuantum, oq1ZColumn, oq1RankBlind,
    oq2tMax, oq2Dmax, oq2Dmax/oq2tMax,
    cvPassive2["dim"], cvActive2["dim"], cvActive1["dim"],
    (* S4 composition *) gluingArbitration, tauStar, gapCct, cctDensity,
    gammaExact, gamma10Numeric, epsCertified, orbitSeeds, cisLawTable, chainGapParity,
    (* S5 sheaf *) lam1c5, lam2c5, lam2c7, lam3c7, supQuantum, supClassical,
    (* S6 Hawking *) chshLimit, rEff225, qubitCF,
    (* S7-S9 *) kcbsAngle, legendreFloor, muCost, Floor[13^(3/2)]
    }], NumericQ];
liveNumberCount = Length[liveNumberList];
liveNumberCount

(* ::CodeText:: *)
(*Merge the three section verification associations (namespaced so no key collides), recompute the three section OK gates live, and fold everything into EssayVerification. The "OK" key is an And of every merged section Boolean and the three gates, guarded by the live-number count being positive and every enumerated live number genuinely numeric. This cell must print OK -> True.*)

(* ::Input:: *)
mergedChecks = Join[
    KeyMap["S13_" <> # &, sectionsVerification],
    KeyMap["S46_" <> # &, KeyDrop[SectionsFourToSixVerification, "OK"]],
    KeyMap["S710_" <> # &, EssaySectionsCVerification]];
gateS1toS3 = And @@ Values[sectionsVerification];
gateS4toS6 = TrueQ[SectionsFourToSixVerification["OK"]];
gateS7toS10 = And @@ Values[EssaySectionsCVerification];
allSectionBooleans = And @@ Values[mergedChecks];
globalOK = allSectionBooleans && gateS1toS3 && gateS4toS6 && gateS7toS10 &&
    liveNumberCount > 0 && AllTrue[liveNumberList, NumericQ];
EssayVerification = Join[mergedChecks, <|
    "sectionGateS1toS3" -> gateS1toS3,
    "sectionGateS4toS6" -> gateS4toS6,
    "sectionGateS7toS10" -> gateS7toS10,
    "liveNumberCount" -> liveNumberCount,
    "OK" -> globalOK|>];
Column[{TableForm[List @@@ Normal[EssayVerification]],
    "liveNumberCount" -> liveNumberCount, "OK" -> EssayVerification["OK"]}]
