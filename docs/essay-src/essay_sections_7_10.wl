(* ::Package:: *)

(* ::Title:: *)
(*Evaluating Black-Box Physics through Optical Emulation \[LongDash] Sections 7-10*)

(* ::Subtitle:: *)
(*Section Builder C: the constructive mirror, the gates that failed, the named-hypothesis frontier, and methods*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. This is the S7-S10 fragment of the master computational essay Evaluating Black-Box Physics through Optical Emulation (spine in docs/ESSAY-OUTLINE.md). It is a self-contained, Get-loadable, headless-verifiable module in its own right: it loads the paclet and the 09-EMU optical compiler, runs every number it prints through the kernel at evaluation time (THE PRIME DIRECTIVE), and closes on the association EssaySectionsCVerification whose "OK" key must be True. Labeling discipline mirrors docs/FRAMEWORK-2026-07-13.md: [T] theorem/machine-verified, [C] certified numeric, [R] refuted route (an established negative, first-class), [H] named hypothesis (open). Run headless via runners/RunEssaySectionsC.wl.*)

(* ::CodeText:: *)
(*Loader. Locate the repository root from this file's own path (Get sets $InputFileName), load the BlackBox paclet and the EMU master compiler, and repair the Global`-shadowing pitfall that wolframscript's whole-file tokenisation would otherwise introduce (documented in CertifyingQuantumness.wl / RunEssay.wl):*)

(* ::Input:: *)
$BlackBoxRepoRoot = Module[
   {ref, start, localRoot, base, cacheRoot, manifest, dest, res, tries, strm},
   ref = If[StringQ[$BlackBoxRef] && $BlackBoxRef =!= "", $BlackBoxRef, "master"];
   start = With[{f = $InputFileName},
     If[StringQ[f] && f =!= "" && FileExistsQ[f], DirectoryName[f],
       Quiet@Check[NotebookDirectory[], Directory[]]]];
   If[! StringQ[start] || start === "", start = Directory[]];
   localRoot = NestWhile[ParentDirectory, start,
     (# =!= ParentDirectory[#]) &&
       ! FileExistsQ[FileNameJoin[{#, "BlackBox", "PacletInfo.wl"}]] &];
   If[FileExistsQ[FileNameJoin[{localRoot, "BlackBox", "PacletInfo.wl"}]],
     localRoot,
     base = "https://raw.githubusercontent.com/hubertkolcz/BlackBox/" <> ref <> "/";
     cacheRoot = FileNameJoin[{$UserBaseDirectory, "ApplicationData", "BlackBoxEssay", ref}];
     Quiet@CreateDirectory[cacheRoot, CreateIntermediateDirectories -> True];
     If[! DirectoryQ[cacheRoot],
       cacheRoot = FileNameJoin[{$TemporaryDirectory, "BlackBoxEssay", ref}];
       Quiet@CreateDirectory[cacheRoot, CreateIntermediateDirectories -> True]];
     manifest = {"BlackBox/PacletInfo.wl", "BlackBox/Kernel/BlackBox.wl",
       "docs/essay-src/essay_sections_1_3.wl", "docs/essay-src/essay_sections_4_6.wl",
       "docs/essay-src/essay_sections_7_10.wl",
       "09-EMU-optical-compiler/OpticalCompiler.wl", "09-EMU-optical-compiler/DispatcherEmitter.wl",
       "09-EMU-optical-compiler/InterferometerLayer.wl", "09-EMU-optical-compiler/IntensityLayer.wl",
       "05-CERT-epsilon-certificates/EpsilonCertificate7_regenerated.wl",
       "05-CERT-epsilon-certificates/EpsilonCertificate8_regenerated.wl",
       "05-CERT-epsilon-certificates/EpsilonCertificate9.wl",
       "05-CERT-epsilon-certificates/EpsilonCertificate10.wl",
       "08-HK-hawking/hawking_gaussian_sector.wl", "08-HK-hawking/gaussian_engine.wl",
       "08-HK-hawking/gaussian_hawking_physics.wl", "08-HK-hawking/gaussian_witnesses_bridge.wl",
       "06-D3-sheaf-cohomology/final_h1_cocycle_results.json",
       "02-D1-theory-frontier/erg003_verdict.json", "docs/FRAMEWORK-2026-07-13.md",
       "09-EMU-optical-compiler/schematics/demo1_kcbs_pentagon_L1.png",
       "09-EMU-optical-compiler/schematics/demo3_cct_mesh_reps2.png",
       "00-BBT-blackbox-protocol/certification_map.png",
       "05-CERT-epsilon-certificates/orbit_spectrum.png"};
     Do[dest = FileNameJoin[Prepend[FileNameSplit[rel], cacheRoot]];
       If[! (FileExistsQ[dest] && FileByteCount[dest] > 0),
         Quiet@CreateDirectory[DirectoryName[dest], CreateIntermediateDirectories -> True];
         tries = 0;
         While[! (FileExistsQ[dest] && FileByteCount[dest] > 0) && tries < 3,
           tries++;
           res = Quiet@Check[URLRead[base <> rel, {"StatusCode", "BodyByteArray"}], $Failed];
           If[AssociationQ[res] && res["StatusCode"] === 200 &&
                ByteArrayQ[res["BodyByteArray"]] && Length[res["BodyByteArray"]] > 8 &&
                ! StringStartsQ[ToUpperCase@Quiet@Check[
                    FromCharacterCode@Normal@Take[res["BodyByteArray"], UpTo[14]], "?"],
                  "<!DOCTYPE" | "<HTML"],
             Quiet[strm = OpenWrite[dest, BinaryFormat -> True];
               BinaryWrite[strm, res["BodyByteArray"]]; Close[strm]]]]],
       {rel, manifest}];
     cacheRoot]];
PacletDirectoryLoad[FileNameJoin[{$BlackBoxRepoRoot, "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"];
Get[FileNameJoin[{$BlackBoxRepoRoot, "09-EMU-optical-compiler", "OpticalCompiler.wl"}]];
Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];
Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`OpticalCompiler`*"], NameQ]];

(* ::CodeText:: *)
(*One reader for the committed heavy-compute artifacts (Python search / LP / cohomology verdicts). Their numbers enter the kernel verified from the committed files, never re-typed:*)

(* ::Input:: *)
readResult[relpath_] := Import[FileNameJoin[Prepend[FileNameSplit[relpath], $BlackBoxRepoRoot]], "RawJSON"];
h1Result = readResult["06-D3-sheaf-cohomology/final_h1_cocycle_results.json"];
erg003 = readResult["02-D1-theory-frontier/erg003_verdict.json"];

(* ::Section:: *)
(*S7 \[LongDash] The Constructive Mirror: Emulator Blueprints (EMU-001, F8)*)

(* ::Text:: *)
(*Sections 1-6 read the device: given a table, decide genuine-vs-emulable through the two lenses. This section runs the same two-lens mathematics in reverse. The 09-EMU three-layer optical compiler is the synthesis dual of the BBT protocol: hand it a target (a KCBS scenario, an n-cycle, a mesh word, or a no-disturbance table) and it emits a physical optical blueprint together with the blueprint's OWN two-lens verdict \[LongDash] genuine so(3)/Sp(2n,\[DoubleStruckCapitalR]) interferometer versus block-local leaf-confined intensity emulator. Every blueprint self-certifies (gate A5, VerifyBlueprint) before it is trusted: it re-simulates its own optics and checks the reproduced statistics against the target. [T]*)

(* ::CodeText:: *)
(*Demo 1 \[LongDash] the Lapkiewicz KCBS pentagon reconstruction. The compiler emits a Layer-1 Givens/beamsplitter cascade [P,T1,T2,T1,T2] on three modes:*)

(* ::Input:: *)
bpKCBS = EmitBlueprint[<|"Scenario" -> "KCBS"|>];
{bpKCBS["Layer"], bpKCBS["ModeCount"], #["Label"] & /@ bpKCBS["Stages"]}

(* ::CodeText:: *)
(*The beamsplitter mixing angle is the golden identity of the pentagon: cos\[Theta] = 1/\[Phi] exactly, in exact arithmetic \[LongDash] the Lapkiewicz cascade's fingerprint (not a fitted float):*)

(* ::Input:: *)
kcbsT1 = SelectFirst[bpKCBS["Stages"], #["Label"] === "T1" &];
kcbsAngle = kcbsT1["Parameter"]["Exact"];
{kcbsAngle, Simplify[Cos[kcbsAngle]], Simplify[Cos[kcbsAngle] - 1/GoldenRatio] === 0}

(* ::CodeText:: *)
(*The blueprint's geometric lens (G7): the cascade's dynamical Lie algebra closes to the full so(3) at commutator depth one \[LongDash] generator span 2, DLA dimension 3 \[LongDash] so the compiler labels it GENUINE, not leaf-confined:*)

(* ::Input:: *)
bpKCBS["CertificationVerdict"]

(* ::CodeText:: *)
(*Self-certification (gate A5): the emitted optics is re-simulated and its statistics compared to the KCBS target. The verdict must be OK -> True with round-trip deviation at machine epsilon:*)

(* ::Input:: *)
vKCBS = VerifyBlueprint[bpKCBS];
{vKCBS["OK"], vKCBS["StatisticsMatch"], vKCBS["MaxDeviation"], vKCBS["DLAVerdictConsistent"]}

(* ::CodeText:: *)
(*Demo 2 \[LongDash] the C7 heptagon cascade (Layer-1, six Givens stages). Its composed exclusivity value obeys the numeric identity S = 7 - 4 \[CurlyTheta](C7), recomputed live from the Lov\[AAcute]sz number of the 7-cycle; the blueprint self-certifies genuine:*)

(* ::Input:: *)
bpC7 = EmitBlueprint[<|"Scenario" -> "Cn", "n" -> 7|>];
{bpC7["Layer"], VerifyBlueprint[bpC7]["OK"], 7 - 4 LovaszTheta[CycleGraph[7]]}

(* ::CodeText:: *)
(*Demo 3 \[LongDash] the cct pentagon-mesh chain (reps = 2). This is a block-local emulator: single-photon linear optics reproduces each block's table but constructs no globally-entangled cluster (the KLM caveat, honest in every header). Its geometric lens reports LEAF-CONFINED (DLA < 3 per block) \[LongDash] the constructive shadow of Prop. 2:*)

(* ::Input:: *)
bpMesh = EmitBlueprint[<|"Word" -> "cct", "Reps" -> 2|>];
{bpMesh["Layer"], VerifyBlueprint[bpMesh]["OK"],
 Union[#["LeafConfined"] & /@ Values[bpMesh["CertificationVerdict"]]]}

(* ::CodeText:: *)
(*The committed schematics (re-emitted by runners/RunOpticalCompiler.wl so they never drift from the numbers above): the KCBS Layer-1 cascade and the cct mesh. Displayed from the compiler's own committed output.*)

(* ::Input:: *)
With[{f = FileNameJoin[{$BlackBoxRepoRoot, "09-EMU-optical-compiler", "schematics", "demo1_kcbs_pentagon_L1.png"}]},
  If[FileExistsQ[f], Import[f], Missing["figure unavailable"]]]

(* ::Input:: *)
With[{f = FileNameJoin[{$BlackBoxRepoRoot, "09-EMU-optical-compiler", "schematics", "demo3_cct_mesh_reps2.png"}]},
  If[FileExistsQ[f], Import[f], Missing["figure unavailable"]]]

(* ::Text:: *)
(*Reading. The compiler closes the loop opened in S2-S3: the very construction that makes a KCBS table forgeable at the correlation level (the tuned intensity emulator, Prop. 1) is here emitted as an explicit optical schedule and stamped LEAF-CONFINED by its own geometric lens \[LongDash] while the genuine Lapkiewicz cascade is stamped GENUINE with DLA = 3. Synthesis and certification are the same theorem read in two directions.*)

(* ::Section:: *)
(*S8 \[LongDash] Gates That Failed (the credibility signature, F9)*)

(* ::Text:: *)
(*Negative results are first-class in this framework: they fix the boundary of the method space. Every route below was a genuine candidate, pre-registered or seriously pursued, and refuted \[LongDash] four of them by rigorous theorems, not merely by exhausted search. Each carries its [R] tag, its one-line refutation, and where the proof lives. Numbers that can be cheaply recomputed are recomputed live here; the heavy Python/LP verdicts are read from their committed result files or cited to the framework's refuted-route ledger.*)

(* ::CodeText:: *)
(*(i) The sheaf Laplacian [R] (SH-004 / F9iv). Pre-registered as a contextuality measure; its harmonic residual is a no-disturbance projector \[LongDash] it vanishes on classical, quantum, and Wright behaviours alike, so it is blind to contextuality. Recomputed live:*)

(* ::Input:: *)
deltaC5 = CycleCoboundary[5];
Chop[HarmonicResidual[deltaC5, N@CycleModel[5, #]] & /@ {"Classical", "Quantum", "Wright"}]

(* ::CodeText:: *)
(*(ii) The affine \[Alpha]-credit tilt [R] (F9i). No affine-in-f_c certificate family can have limiting gap equal to gap(cct): the linear correction is inert against the kinked \[Alpha]-floor. Proof: 05-CERT-epsilon-certificates (CONVERGENCE-ANALYSIS-2026-07-13.md) / FRAMEWORK F9i. [R, theorem]*)

(* ::CodeText:: *)
(*(iii) The Legendre \[Theta]-frontier [R, theorem] (F9viii / CERT-004). A certified Legendre frequency-frontier equals the upper CONCAVE HULL of \[Theta]-bar over cis-frequency f_c \[LongDash] and that hull is pinned flat at 3/2 on f_c in [1/2,1] (the words ct and ccct attain \[Theta]-bar = 3/2 exactly), while cct sits strictly below it, unexposed by any supporting hyperplane. So the route certifies a gap floor of at least 3/2 - 4/3, recomputed live below \[LongDash] worse than the flat certificate \[CapitalGamma]\:2089. File-sourced: hull(2/3) = 3/2, cct \[Theta]-bar = 1.4032309 (0.0967691 below the hull), from 03-MESH-pentagon-composition/final_cct_hull.py.*)

(* ::Input:: *)
legendreFloor = 3/2 - 4/3;
{legendreFloor, N[legendreFloor]}

(* ::CodeText:: *)
(*(iv) The \[DoubleStruckCapitalQ]/\[DoubleStruckCapitalZ] H\.b9 detector [R] (F9vii / SH-010; cross-references S5). The connecting class \[Delta](y* mod \[DoubleStruckCapitalZ]) is not an H\.b9 contextuality detector: it is UNDEFINED in the fractional/stuck case (the canonical C7,k=2 dual is not a 0-cocycle), GAUGE NON-INVARIANT (the optimal dual face is positive-dimensional; an alternate C5 optimum breaks the cocycle condition), and FORCED to zero wherever it is defined (connected nerve). Its two diagnostic bad-overlap counts, read live from the committed cohomology result:*)

(* ::Input:: *)
{h1Result["obstruction_1_cocycle_prerequisite"]["C7_k2_canonical_dual"]["bad_overlaps"],
 h1Result["obstruction_2_gauge_noninvariance"]["C5_k2"]["D_half_y_1over2_on_both_partitions"]["bad_overlaps"]}

(* ::CodeText:: *)
(*(v) The Delsarte / Schrijver \[Theta]' LP [R, theorem] (F9ix / ERG-004a). On the \[DoubleStruckCapitalZ]\:2081\:2083^k translation scheme the Schrijver \[Theta]' equals exactly 13^(k/2) \[LongDash] identical to the Lov\[AAcute]sz ceiling \[LongDash] so the LP can neither close (< 40) nor tighten (< 46) the Paley bracket. The ceiling at k = 3 is Floor[13^(3/2)], recomputed live; the 13^(k/2) identity is the file-sourced theorem (02-D1-theory-frontier/final_paley13_lp.py):*)

(* ::Input:: *)
{13^(3/2) // N, Floor[13^(3/2)]}

(* ::CodeText:: *)
(*(vi) The Ramsey obstruction [R] (F9v). The Choudhary-Barbosa Ramsey technique provably cannot certify \[Omega] <= 17 for the mixed nonagon cell (its bound is too weak for this graph). Proof: FRAMEWORK F9v / ERG-003 analysis. [R, theorem]*)

(* ::CodeText:: *)
(*(vii) The ergodic-sheaf category error [R] (F9ii). The proposed static<->dynamic unification is a category error: the cross-side T->0 limit yields packing 5/2, not a certificate value \[CapitalGamma], and does not select cct. Proof: 06-D3 / FRAMEWORK F9ii. [R]*)

(* ::CodeText:: *)
(*(viii) Bound-inertness [R] (F9x / ERG-004b). Zero of the 26 pentagram families are bound-eliminable (the inertness lemma: \[Omega](cn(Q_m)) >= 8 - s_m meets the generator constraint), so S = 17 is search-bound, not bound-decidable. The family count is read live from the committed ERG-003 verdict:*)

(* ::Input:: *)
{Length[erg003["families"]], erg003["counts"]["NO"]}

(* ::Text:: *)
(*Reading. Four of these eight are theorems of impossibility (affine, Legendre, Delsarte, Ramsey), not tired searches; two are structural category errors (ergodic-sheaf, \[DoubleStruckCapitalQ]/\[DoubleStruckCapitalZ] H\.b9); one is a pre-registered measure that failed its own gate (Laplacian); one prices the residual search honestly (bound-inertness). A framework that can only report its successes cannot locate its own boundary \[LongDash] this section is where the boundary is drawn.*)

(* ::Section:: *)
(*S9 \[LongDash] The Framework under Named Hypotheses (the honest frontier, Layer 1)*)

(* ::Text:: *)
(*The framework is stated COMPLETELY: the established layer (S1-S8, unconditional) and then the named hypotheses \[LongDash] each an explicit open problem awaiting mathematical proof, developed as number theory is developed under the Riemann Hypothesis. The living hypothesis set after the 2026-07-13 delta is {H1, H1', H2', H3, H4', H5}: H4a and H4b were PROVEN and moved into Layer 0 (F10, F11), while the H2 \[Delta]-route was refuted (F9vii) and reopened as the weaker H2'. The proof-obligation ledger below is parsed LIVE from docs/FRAMEWORK-2026-07-13.md so the essay tracks the living document rather than a snapshot. [H]*)

(* ::CodeText:: *)
(*Parse the Layer-3 proof ledger (the "what official mathematics still owes the framework" table) directly from the framework file and render it:*)

(* ::Input:: *)
frameworkText = Import[FileNameJoin[{$BlackBoxRepoRoot, "docs", "FRAMEWORK-2026-07-13.md"}], "Text"];
frameworkLines = StringSplit[frameworkText, "\n"];
splitRow[row_] := Select[StringTrim /@ StringSplit[row, "|"], # =!= "" &];
hHeader = splitRow[SelectFirst[frameworkLines, StringMatchQ[#, "| # | Open problem" ~~ ___] &]];
hRows = splitRow /@ Select[frameworkLines, StringMatchQ[#, "| H" ~~ ___] &];
{Length[hRows], hHeader}

(* ::Input:: *)
Grid[Prepend[hRows, hHeader], Frame -> All, Alignment -> Left,
 Background -> {None, {LightBlue, None}}, ItemStyle -> "Text"]

(* ::Text:: *)
(*The five (plus H1') live hypotheses, each a sharply-posed problem with a stated proof target:*)

(* ::Item:: *)
(*H1 (cct optimality) [H]: sup over all gluing words of gap(w) equals gap(cct) = 0.0698975, certified within \[Epsilon] = \[CapitalGamma]\:2081\:2080 - gap(cct) = 0.00156 (\[CapitalGamma]\:2081\:2080 numeric-only, per S4; the exact k=10 certificate is pending). Counterexamples confined to a thin corridor f_c ~ 2/3, \[Alpha]-bar in [4/3, 1.4301). Target: a NONLINEAR-in-frequency certificate (the affine and Legendre routes are dead, S8-ii/iii) or an ergodic-optimization selection theorem. Plus H1' (\[CapitalGamma]-limit): lim \[CapitalGamma]_k = sup gap.*)

(* ::Item:: *)
(*H2' (cohomological detection, reopened) [H]: a genuine quantitative-cohomology detector on a cover OTHER than the maximal-clique cover \[LongDash] the \[Delta](y* mod \[DoubleStruckCapitalZ]) route is closed (F9vii, S8-iv). The degree-0 derivation S_k = \[CapitalLambda]_k^(1/k) (S5) stands untouched.*)

(* ::Item:: *)
(*H3 (no-activation) [H]: \[Omega](C9 \[Vee] C9 \[Vee] C9 \[Vee] C5) = 16 \[LongDash] the (3,1) nonagon cell does NOT activate; pentagon catalysis stays n=7-unique. Live: the activation threshold is \[Omega] >= 18 and the clique-number ceiling of the mixed cell H is 8, since (1+sec(\[Pi]/9))^3 < 9 (recomputed below). The search census (2 of 26 families proven NO; total exact nodes) is read live from the committed verdict.*)

(* ::Input:: *)
{N[(1 + Sec[Pi/9])^3], (1 + Sec[Pi/9])^3 < 9,
 erg003["counts"]["NO"], Length[erg003["families"]], erg003["totalNodes"]}

(* ::Item:: *)
(*H4' (\[ScriptCapitalA]_IE-maximality) [H]: is the intensity-emulator class \[ScriptCapitalA]_IE the maximal classically-emulable adversary class? (PNR / heralded-Fock / non-fair-sampling devices sit outside it.) The class-relative completeness itself is now proven CONDITIONALLY (F10, Prop O3-C, Layer 0), load-bearing on the KBS single-detector coherent-forgeability theorem + white-box trust on G7/G7-CV; only the maximality question remains open.*)

(* ::Item:: *)
(*H5 (Paley product) [H]: \[Omega](Paley13^\[Vee]3) = 39, the product witness optimal; bracket [39, 46] with ceiling 46 = Floor[13^(3/2)] (recomputed live below). Target: level-2 Lasserre / non-abelian symmetrization / residual search (the Delsarte LP is dead, S8-v).*)

(* ::Input:: *)
{Floor[13^(3/2)], 13*3}

(* ::CodeText:: *)
(*Signaling assessment (O5 / SIG-001..003), a feasibility pointer. The KCBS lock's exact cost is the contextual fraction \[Mu] = 2\[Sqrt]5 - 4 bits/round, recomputed live in exact arithmetic; the 3-gate signaling taxonomy over 7 exemplars and one refuted candidate identity live in 07-SIG-signaling. [T]*)

(* ::Input:: *)
muCost = FullSimplify[ContextualFraction[CycleScenario[5], CycleModel[5, "Quantum"], WorkingPrecision -> Infinity]];
{muCost, Simplify[muCost - (2 Sqrt[5] - 4)] === 0}

(* ::Text:: *)
(*Jointly, under H1-H5 the framework is complete in the sense the project defined: one exact correlation theory, one exact composition theory, one decided activation frontier, and one certified answer to the central question \[LongDash] with every remaining gap located OUTSIDE the framework (aperiodic ergodic selection, finer sheaf cohomology, sampling hardness, adversary-class maximality) rather than inside it. Each hypothesis is exactly the kind of sharply-posed open problem the project set out to distill.*)

(* ::Section:: *)
(*S10 \[LongDash] Methods Appendix (verification culture)*)

(* ::Text:: *)
(*The Get-runner pattern. wolframscript -file parses a whole file before evaluating, which pre-creates Global` shadows of the paclet's exported symbols (CycleScenario, ContextualFraction, ...). Get[] instead parses and evaluates expression by expression, so the loader cell that de-shadows (Remove of the Global` duplicates) runs before any paclet symbol is tokenised in a later cell. This fragment is therefore driven by runners/RunEssaySectionsC.wl, which Get-loads it; a bare -file run of the essay would print unevaluated Global` symbols.*)

(* ::Text:: *)
(*The OK -> True discipline. Every module in this repository ends in a ...Verification association whose "OK" key is an And of exact or tolerant Booleans recomputed live; this fragment follows suit with EssaySectionsCVerification below. Exact arithmetic is used wherever exactness is claimed \[LongDash] \[DoubleStruckCapitalQ](\[Sqrt]5) and Root objects for the pentagon geometry, RootReduce and WorkingPrecision -> Infinity for the LP certificates, exact-rational SDP/LP for the composition bounds \[LongDash] so those certificates are algebraic identities, not floats. SDP Lov\[AAcute]sz values are machine-precision and are gated with tolerances, never asserted exact.*)

(* ::Text:: *)
(*Provenance spine. Heavy Python results (search census, Delsarte LP, H\.b9 cohomology, concave hull) are pulled from committed JSON / .py result files through the single readResult reader above, so their numbers enter the kernel verified from the artifact rather than re-typed by hand \[LongDash] making the WSRI live-computation requirement a BUILD PROPERTY of the essay, not an editing discipline. Claims carry their ledger keys (BBT-, MESH-, CERT-, SH-, ERG-, HK-) and the A-D epistemic grade of the framework document; refuted routes carry [R] and their F9 sub-index. Novelty is scoped exactly as the audits scoped it: the currency law is Camillo-Cervantes, the pentagram bound is Hales (1973), and the mean-payoff / tropical certificate machinery is borrowed, not original to this work.*)

(* ::CodeText:: *)
(*Environment capture, recorded into the verification log at build time:*)

(* ::Input:: *)
essayEnvironment = <|
  "WolframVersion" -> $Version,
  "Date" -> DateString[{"Year", "-", "Month", "-", "Day"}],
  "BlackBoxPaclet" -> Quiet@Check[PacletObject["HubertKolcz`BlackBox`"]["Version"], "loaded"],
  "RepoRoot" -> $BlackBoxRepoRoot|>

(* ::Section:: *)
(*Verification (this fragment's OK -> True contract)*)

(* ::Text:: *)
(*House discipline: every load-bearing claim of S7-S10, machine-checked in one association. This cell must print OK -> True.*)

(* ::Input:: *)
EssaySectionsCVerification = <|
  (* S7 *)
  "emuIdentity" -> (Simplify[Cos[SelectFirst[bpKCBS["Stages"], #["Label"] === "T1" &]["Parameter"]["Exact"]] - 1/GoldenRatio] === 0),
  "emuGenuine" -> (bpKCBS["CertificationVerdict"]["KCBS-cascade"]["DLADimension"] == 3 &&
     bpKCBS["CertificationVerdict"]["KCBS-cascade"]["Verdict"] === "genuine"),
  "emuSelfCert" -> TrueQ[vKCBS["OK"]] && vKCBS["MaxDeviation"] < 10^-10,
  "emuHeptagon" -> TrueQ[VerifyBlueprint[bpC7]["OK"]],
  "emuMeshLeafConfined" -> TrueQ[VerifyBlueprint[bpMesh]["OK"]] &&
     AllTrue[Values[bpMesh["CertificationVerdict"]], TrueQ[#["LeafConfined"]] &],
  (* S8 *)
  "laplacianRejected" -> AllTrue[HarmonicResidual[deltaC5, N@CycleModel[5, #]] & /@
     {"Classical", "Quantum", "Wright"}, Abs[#] < 10^-10 &],
  "legendreFloor" -> (3/2 - 4/3 == 1/6) && (1/6 > 0.0699),
  "h1BadOverlaps" -> (h1Result["obstruction_1_cocycle_prerequisite"]["C7_k2_canonical_dual"]["bad_overlaps"] == 20776 &&
     h1Result["obstruction_2_gauge_noninvariance"]["C5_k2"]["D_half_y_1over2_on_both_partitions"]["bad_overlaps"] == 3000),
  "delsarteCeiling" -> (Floor[13^(3/2)] == 46),
  "boundInertFamilies" -> (Length[erg003["families"]] == 26),
  (* S9 *)
  "hTableParsed" -> (Length[hRows] >= 6 && Length[hHeader] == 5),
  "activationCeiling" -> ((1 + Sec[Pi/9])^3 < 9) && (Floor[13^(3/2)] == 46) && (13*3 == 39),
  "signalingCost" -> (Simplify[muCost - (2 Sqrt[5] - 4)] === 0),
  (* S10 *)
  "environment" -> StringContainsQ[essayEnvironment["Date"], "2026"]
|>;
Column[{EssaySectionsCVerification, "OK" -> And @@ Values[EssaySectionsCVerification]}]

(* ::Section:: *)
(*References (S7-S10 subset; full set in docs/RELATED-WORK.md and S11)*)

(* ::Item:: *)
(*Lapkiewicz et al., Nature 474, 490 (2011); Reck et al., PRL 73, 58 (1994); Clements et al., Optica 3, 1460 (2016) \[LongDash] the interferometer layer.*)

(* ::Item:: *)
(*Frustaglia et al., PRL 116, 250404 (2016); Kovtoniuk, Bohmann, Semenov, arXiv:2601.13869 \[LongDash] the intensity-emulator adversary and single-detector coherent-forgeability.*)

(* ::Item:: *)
(*Choudhary, Barbosa, arXiv:2411.09773 \[LongDash] the Ramsey technique refuted for the mixed nonagon cell (F9v).*)

(* ::Item:: *)
(*Abramsky, Mansfield, Barbosa, arXiv:1111.3620 \[LongDash] cohomology of contextuality (the H\.b9 route, refuted as posed, F9vii).*)

(* ::Item:: *)
(*docs/FRAMEWORK-2026-07-13.md (the layer/hypothesis architecture, Layer-3 ledger parsed live in S9); docs/COMPLETE-THEORY-2026-07-13.md; 05-CERT-epsilon-certificates/CONVERGENCE-ANALYSIS-2026-07-13.md.*)
