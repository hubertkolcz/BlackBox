(* ::Package:: *)

(* essay005_p1_p4.wl --- ESSAY-005 probes P1 (support-census negative control)
   and P4 (torsion-vs-GE-value scan) on the fixed 2-copy product cover.

   Parent spec: bound-derivation-question/ESSAY-005-problem-spec.md (Trap 2; probes
   P1, P4 with acceptance criteria). Design: ESSAY-005-phase23-execution-plan.md
   Sec. 1 (Phase-2 agent A) --- implemented verbatim: paclet functions only, no
   new mathematics. Cover + product model transcribed from SupportCohomology.wl
   Sec. "The Two-Copy Product Cover".

   Run:  wolframscript -file essay005_p1_p4.wl        (~2-3 h, one kernel)
   Env:  ESSAY005_PILOT=1  -> plan Sec. 5 pilot (p in {2/5, 1/Sqrt[5], 1/2})
         ESSAY005_PILOT=2  -> single-copy smoke test only (~2 min)

   Outputs (this module): p1p4_census.csv (P1 deliverable),
   p1p4_torsion.csv (P4 deliverable), printed census + torsion tables, and a
   pre-registered verification association ending OK -> True (house style).

   Pre-registered acceptance (verbatim from the parent spec / plan Sec. 1.4):
   stratum A (path-S products, 0 < p < 1/2, which contains Sigma = 2 classical
   max, Sigma = Sqrt[5] quantum max, and the approach to alpha* = 5/2): every
   support-level invariant IDENTICAL across the stratum --- 225 sections,
   |Se| = 121, H0 = 36, 0 obstructed, all orders 1, no torsion anywhere ---
   while CF moves and GlobalSectionQ flips at p = 2/5. Wright jump at p = 1/2:
   100 sections, |Se| = 0, 100/100 obstructed, all orders Infinity. Path V
   (v < 1) enters the full-support stratum: 400 sections, |Se| = 1024, 0
   obstructed. If ANY support-level column differs between two stratum-A rows,
   Trap 2 is REFUTED and that invariant is the new research object (major
   surprise --- escalate); if none differs, the possibilistic route to S_k is
   CLOSED with this citable computation. *)

$HistoryLength = 0;
startT = AbsoluteTime[];
pilotMode = Environment["ESSAY005_PILOT"];
Print["essay005_p1_p4.wl start ", DateString[], "  pilot=", pilotMode];

scriptDir = DirectoryName[ExpandFileName[$InputFileName]];
PacletDirectoryLoad[FileNameJoin[{scriptDir, "..", "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"];

(* ------------------------------------------------------------------ *)
(* objects: verbatim from SupportCohomology.wl                          *)
(* ------------------------------------------------------------------ *)

scen5 = CycleScenario[5];
edges5 = Table[{i, Mod[i + 1, 5]}, {i, 0, 4}];
scenProd = CoverScenario[Join[Table[{1, i}, {i, 0, 4}], Table[{2, i}, {i, 0, 4}]],
  Flatten[Table[{{1, ed[[1]]}, {1, ed[[2]]}, {2, f[[1]]}, {2, f[[2]]}}, {ed, edges5}, {f, edges5}], 1]];
prodModel[m1_, m2_] := With[{d1 = AssociationThread[Tuples[{0, 1}, 2] -> m1[[1 ;; 4]]],
   d2 = AssociationThread[Tuples[{0, 1}, 2] -> m2[[1 ;; 4]]]},
  Flatten[Table[d1[s[[1 ;; 2]]] d2[s[[3 ;; 4]]], {c, scenProd["Contexts"]}, {s, Tuples[{0, 1}, 4]}]]];

(* ------------------------------------------------------------------ *)
(* model families (plan Sec. 1.1, exact arithmetic)                     *)
(* ------------------------------------------------------------------ *)

e[p_] := CycleModel[5, 1 - 2 p, p];                    (* path S: edge dist (1-2p, p, p, 0) *)
eV[v_] := Simplify[v CycleModel[5, "Quantum"] + (1 - v) ConstantArray[1/4, 20]];  (* path V *)

pGrid = {1/5, 3/10, 2/5, 21/50, 1/Sqrt[5], 23/50, 12/25, 49/100, 499/1000, 1/2};
vGrid = {1/2, 9/10, 99/100, 1};
Which[
 pilotMode === "1", (pGrid = {2/5, 1/Sqrt[5], 1/2}; vGrid = {}),
 pilotMode === "2", (pGrid = {2/5, 1/Sqrt[5], 1/2}; vGrid = {1/2})];

(* sanity assert before the sweep (plan Sec. 1.1) *)
sanityQuantum = Simplify[CycleModel[5, "Quantum"] == e[1/Sqrt[5]]] === True;
Print["sanity: CycleModel[5,\"Quantum\"] == e[1/Sqrt[5]]  ->  ", sanityQuantum];

(* KCBS Sigma of a single-copy model: sum of first-observable marginals
   P(x_i = 1) = m[[4i+3]] + m[[4i+4]]  (section order 00,01,10,11) *)
sigma1[m_] := Simplify[Sum[m[[4 i + 3]] + m[[4 i + 4]], {i, 0, 4}]];

(* row descriptors: single-copy cover (5 contexts) and product cover (25) *)
singleRows = Join[
  Table[<|"family" -> "S1", "cover" -> "C5-edge(5ctx)", "param" -> p, "m" -> e[p],
    "sig" -> sigma1[e[p]], "stratum" -> If[p === 1/2, "W1", "A1"]|>, {p, pGrid}],
  Table[<|"family" -> "V1", "cover" -> "C5-edge(5ctx)", "param" -> v, "m" -> eV[v],
    "sig" -> sigma1[eV[v]], "stratum" -> If[v === 1, "A1x", "F1"]|>, {v, vGrid}]];

prodRows = Join[
  Table[<|"family" -> "S2", "cover" -> "C5vC5(25ctx)", "param" -> p,
    "m" -> prodModel[e[p], e[p]], "sig" -> sigma1[e[p]],
    "stratum" -> If[p === 1/2, "W", "A"]|>, {p, pGrid}],
  Table[<|"family" -> "V2", "cover" -> "C5vC5(25ctx)", "param" -> v,
    "m" -> prodModel[eV[v], eV[v]], "sig" -> sigma1[eV[v]],
    "stratum" -> If[v === 1, "Ax", "F"]|>, {v, vGrid}],
  If[pilotMode === "1" || pilotMode === "2", {},
   {<|"family" -> "M2", "cover" -> "C5vC5(25ctx)", "param" -> "QxW",
     "m" -> prodModel[CycleModel[5, "Quantum"], CycleModel[5, "Wright"]],
     "sig" -> {Sqrt[5], 5/2}, "stratum" -> "M"|>,
    <|"family" -> "M2", "cover" -> "C5vC5(25ctx)", "param" -> "CxW",
     "m" -> prodModel[e[2/5], CycleModel[5, "Wright"]],
     "sig" -> {2, 5/2}, "stratum" -> "M"|>}]];
If[pilotMode === "2", prodRows = {}];

(* ------------------------------------------------------------------ *)
(* per-row computation (plan Sec. 1.2: paclet calls verbatim)           *)
(* ------------------------------------------------------------------ *)

computeRow[desc_, scen_, relC2_] := Module[
  {m = desc["m"], ch, cc, r1, r2, gs, cf, t0, match1, match2},
  t0 = AbsoluteTime[];
  ch = CechObstruction[scen, m];                (* support census + ObstructionOrder *)
  cc = CechCohomology[scen, m];                 (* absolute H0/H1, torsion *)
  r1 = CechRelativeCohomology[scen, m, 1];      (* relative group, first context *)
  r2 = CechRelativeCohomology[scen, m, relC2];  (* second base context *)
  gs = GlobalSectionQ[scen, N@m];               (* LP layer *)
  cf = ContextualFraction[scen, N@m];           (* LP layer: the thing that MOVES *)
  match1 = And @@ Table[r1["GammaOrders"][s0] === ch["ObstructionOrder"][{scen["Contexts"][[1]], s0}],
     {s0, Keys[r1["GammaOrders"]]}];
  match2 = And @@ Table[r2["GammaOrders"][s0] === ch["ObstructionOrder"][{scen["Contexts"][[relC2]], s0}],
     {s0, Keys[r2["GammaOrders"]]}];
  <|"family" -> desc["family"], "cover" -> desc["cover"],
    "paramRaw" -> desc["param"], "param" -> ToString[desc["param"], InputForm],
    "Sigma" -> ToString[desc["sig"], InputForm], "SigmaN" -> N[desc["sig"]],
    "stratum" -> desc["stratum"],
    "SectionCount" -> ch["SectionCount"],
    "SupportSizesTally" -> Sort[Tally[ch["SupportSizes"]]],
    "GlobalSupportSize" -> ch["GlobalSupportSize"],
    "H0obstr" -> ch["H0Rank"],
    "ObstructedCount" -> ch["ObstructedCount"],
    "CSC" -> ch["CohStronglyContextual"],
    "FalseNegCount" -> Length[ch["FalseNegatives"]],
    "OrderTally" -> Sort[Tally[Values[ch["ObstructionOrder"]]]],
    "ccH0" -> cc["H0Rank"], "ccH1free" -> cc["H1FreeRank"], "ccH1torsion" -> cc["H1Torsion"],
    "ComplexCloses" -> TrueQ[cc["ComplexCloses"] && r1["ComplexCloses"] && r2["ComplexCloses"]],
    "rel1H1free" -> r1["H1FreeRank"], "rel1H1torsion" -> r1["H1Torsion"],
    "rel1GammaTally" -> Sort[Tally[Values[r1["GammaOrders"]]]],
    "relBH1free" -> r2["H1FreeRank"], "relBH1torsion" -> r2["H1Torsion"],
    "relBGammaTally" -> Sort[Tally[Values[r2["GammaOrders"]]]],
    "GammaCocyclesVerified" -> TrueQ[r1["GammaCocyclesVerified"] && r2["GammaCocyclesVerified"]],
    "OrdersMatchObstruction" -> TrueQ[match1 && match2],
    "GlobalSectionQ" -> gs, "CF" -> cf,
    "seconds" -> Round[AbsoluteTime[] - t0, 1/10]|>];

(* the support-level invariant tuple: everything the possibilistic layer can see *)
suppTuple[r_] := {r["SectionCount"], r["SupportSizesTally"], r["GlobalSupportSize"],
  r["H0obstr"], r["ObstructedCount"], r["CSC"], r["FalseNegCount"], r["OrderTally"],
  r["ccH0"], r["ccH1free"], r["ccH1torsion"], r["rel1H1free"], r["rel1H1torsion"],
  r["rel1GammaTally"], r["relBH1free"], r["relBH1torsion"], r["relBGammaTally"]};

(* ------------------------------------------------------------------ *)
(* CSV writers (rewritten after every row: crash-safe)                  *)
(* ------------------------------------------------------------------ *)

csvCell[x_] := Module[{s = If[StringQ[x], x, ToString[x, InputForm]]},
  "\"" <> StringReplace[s, "\"" -> "\"\""] <> "\""];
censusHeader = {"family", "cover", "param", "SigmaPerCopy", "SigmaPerCopyN", "stratum",
  "SectionCount", "SupportSizesTally", "GlobalSupportSize", "H0Rank_obstr",
  "ObstructedCount", "CohStronglyContextual", "FalseNegativesCount",
  "ccH0", "ccH1free", "ccH1torsion", "ComplexCloses", "GlobalSectionQ", "CF"};
torsionHeader = {"family", "cover", "param", "SigmaPerCopy", "SigmaPerCopyN", "stratum",
  "OrderTally", "rel1_H1free", "rel1_H1torsion", "rel1_GammaTally",
  "relB_H1free", "relB_H1torsion", "relB_GammaTally",
  "GammaCocyclesVerified", "OrdersMatchObstruction", "CF"};
cfString[cf_] := ToString[NumberForm[Chop[N[cf], 10^-9], 12, ExponentFunction -> (Null &)]];
censusLine[r_] := StringRiffle[csvCell /@ {r["family"], r["cover"], r["param"], r["Sigma"],
   r["SigmaN"], r["stratum"], r["SectionCount"], r["SupportSizesTally"],
   r["GlobalSupportSize"], r["H0obstr"], r["ObstructedCount"], r["CSC"],
   r["FalseNegCount"], r["ccH0"], r["ccH1free"], r["ccH1torsion"],
   r["ComplexCloses"], r["GlobalSectionQ"], cfString[r["CF"]]}, ","];
torsionLine[r_] := StringRiffle[csvCell /@ {r["family"], r["cover"], r["param"], r["Sigma"],
   r["SigmaN"], r["stratum"], r["OrderTally"], r["rel1H1free"], r["rel1H1torsion"],
   r["rel1GammaTally"], r["relBH1free"], r["relBH1torsion"], r["relBGammaTally"],
   r["GammaCocyclesVerified"], r["OrdersMatchObstruction"], cfString[r["CF"]]}, ","];
writeCSVs[results_] := (
  Export[FileNameJoin[{scriptDir, "p1p4_census.csv"}],
   StringRiffle[Prepend[censusLine /@ results, StringRiffle[censusHeader, ","]], "\n"], "Text"];
  Export[FileNameJoin[{scriptDir, "p1p4_torsion.csv"}],
   StringRiffle[Prepend[torsionLine /@ results, StringRiffle[torsionHeader, ","]], "\n"], "Text"]);

(* ------------------------------------------------------------------ *)
(* the sweep                                                            *)
(* ------------------------------------------------------------------ *)

results = {};
refTupleA = None;   (* inline stratum-A deviation alarm (plan Sec. 1.4 escalation) *)
allDescs = Join[({#, scen5, 3} & /@ singleRows), ({#, scenProd, 13} & /@ prodRows)];
Do[Module[{desc = allDescs[[i, 1]], scen = allDescs[[i, 2]], rc = allDescs[[i, 3]], r},
   r = computeRow[desc, scen, rc];
   AppendTo[results, r];
   writeCSVs[results];
   Print["row ", i, "/", Length[allDescs], "  ", r["family"], " param=", r["param"],
    " stratum=", r["stratum"], "  sections=", r["SectionCount"],
    " obstructed=", r["ObstructedCount"], " orders=", ToString[r["OrderTally"], InputForm],
    " ccH0=", r["ccH0"], " gs=", r["GlobalSectionQ"], " CF=", cfString[r["CF"]],
    "  (", N[r["seconds"]], " s)"];
   If[r["family"] === "S2" && r["stratum"] === "A",
    If[refTupleA === None, refTupleA = suppTuple[r],
     If[suppTuple[r] =!= refTupleA,
      Print["*** WARNING: stratum-A support-level invariant MOVED at param ", r["param"],
       " --- Trap 2 candidate REFUTATION --- ESCALATE (parent spec P1 acceptance) ***"]]]]],
  {i, Length[allDescs]}];

(* ------------------------------------------------------------------ *)
(* printed tables                                                       *)
(* ------------------------------------------------------------------ *)

Print["\n================ P1 CENSUS TABLE (support layer vs LP layer) ================"];
Print[StringRiffle[{"family", "param", "SigmaPerCopy", "stratum", "Sections", "SuppTally",
   "|Se|", "H0obstr", "Obstructed", "CSC", "ccH0", "ccH1free", "ccH1tors", "gs", "CF"}, " | "]];
Do[Print[StringRiffle[ToString[#, InputForm] & /@ {r["family"], r["param"], r["SigmaN"],
     r["stratum"], r["SectionCount"], r["SupportSizesTally"], r["GlobalSupportSize"],
     r["H0obstr"], r["ObstructedCount"], r["CSC"], r["ccH0"], r["ccH1free"],
     r["ccH1torsion"], r["GlobalSectionQ"], cfString[r["CF"]]}, " | "]], {r, results}];

Print["\n================ P4 TORSION-vs-SIGMA TABLE (relative layer) ================"];
Print[StringRiffle[{"family", "param", "SigmaPerCopy", "stratum", "OrderTally", "rel1H1free",
   "rel1tors", "rel1Gamma", "relBH1free", "relBtors", "relBGamma", "cocyclesOK",
   "=ObstrOrder", "CF"}, " | "]];
Do[Print[StringRiffle[ToString[#, InputForm] & /@ {r["family"], r["param"], r["SigmaN"],
     r["stratum"], r["OrderTally"], r["rel1H1free"], r["rel1H1torsion"], r["rel1GammaTally"],
     r["relBH1free"], r["relBH1torsion"], r["relBGammaTally"], r["GammaCocyclesVerified"],
     r["OrdersMatchObstruction"], cfString[r["CF"]]}, " | "]], {r, results}];

(* ------------------------------------------------------------------ *)
(* pre-registered verification (plan Sec. 1.4; house style OK -> True)  *)
(* ------------------------------------------------------------------ *)

sel[f_, s_] := Select[results, #["family"] === f && #["stratum"] === s &];
first1[l_] := If[l === {}, None, First[l]];
tol = 10^-9;

sA1 = sel["S1", "A1"]; sW1 = first1[sel["S1", "W1"]]; sF1 = sel["V1", "F1"];
sA1x = first1[sel["V1", "A1x"]];
pA = sel["S2", "A"]; pW = first1[sel["S2", "W"]]; pF = sel["V2", "F"];
pAx = first1[sel["V2", "Ax"]]; pM = sel["M2", "M"];
pAsorted = SortBy[pA, N[#["paramRaw"]] &];
pAq = first1[Select[pA, #["paramRaw"] === 1/Sqrt[5] &]];
pAc = first1[Select[pA, #["paramRaw"] === 2/5 &]];

fullRun = ! (pilotMode === "1" || pilotMode === "2");

P1P4Verification = <|
  "sanityQuantumPoint" -> sanityQuantum,

  (* --- single-copy cover: the three strata --- *)
  "singleA1identical" -> Length[DeleteDuplicates[suppTuple /@ sA1]] == 1,
  "singleA1values" -> With[{r = first1[sA1]}, r =!= None && r["SectionCount"] == 15 &&
     r["GlobalSupportSize"] == 11 && r["ObstructedCount"] == 0 && r["ccH0"] == 6 &&
     r["OrderTally"] === {{1, 15}}],
  "singleW1wrightJump" -> sW1 =!= None && sW1["SectionCount"] == 10 &&
    sW1["GlobalSupportSize"] == 0 && sW1["ObstructedCount"] == 10 && sW1["CSC"] &&
    sW1["OrderTally"] === {{Infinity, 10}},
  "singleF1identical" -> If[sF1 === {}, True,
    Length[DeleteDuplicates[suppTuple /@ sF1]] == 1 &&
     With[{r = First[sF1]}, r["SectionCount"] == 20 && r["GlobalSupportSize"] == 32 &&
       r["ObstructedCount"] == 0]],
  "singleXcheckV1equalsQuantum" -> If[! fullRun, True,
    sA1x =!= None && MemberQ[suppTuple /@ sA1, suppTuple[sA1x]] &&
     With[{q = first1[Select[sA1, #["paramRaw"] === 1/Sqrt[5] &]]},
      q =!= None && Abs[sA1x["CF"] - q["CF"]] < 10^-8]],

  (* --- P1 GATE: product-cover stratum A (Sigma = 2, Sqrt[5], -> 5/2 inside) --- *)
  "prodStratumArowCount" -> Length[pA] == If[fullRun, 9, 2],
  "prodStratumAidenticalSupportInvariants" -> Length[DeleteDuplicates[suppTuple /@ pA]] == 1,
  "prodStratumAexpectedValues" -> With[{r = first1[pA]}, r =!= None &&
     r["SectionCount"] == 225 && r["SupportSizesTally"] === {{9, 25}} &&
     r["GlobalSupportSize"] == 121 && r["H0obstr"] == 36 && r["ccH0"] == 36 &&
     r["ObstructedCount"] == 0 && r["OrderTally"] === {{1, 225}} &&
     r["ccH1free"] == 0 && r["ccH1torsion"] === {} &&
     r["rel1H1torsion"] === {} && r["relBH1torsion"] === {}],
  "prodStratumAgsIffClassical" -> AllTrue[pA,
    #["GlobalSectionQ"] === (N[#["paramRaw"]] <= 2/5 + tol) &],
  "prodStratumACFmovesWhereSupportConstant" -> pAq =!= None && pAc =!= None &&
    pAq["CF"] - pAc["CF"] > 1/100,
  "prodStratumACFmonotone" -> And @@ Thread[Differences[#["CF"] & /@ pAsorted] > -tol],

  (* --- Wright jump at p = 1/2 (support boundary; matches SupportCohomology chWW) --- *)
  "prodWrightJump" -> pW =!= None && pW["SectionCount"] == 100 &&
    pW["GlobalSupportSize"] == 0 && pW["ObstructedCount"] == 100 && pW["CSC"] &&
    pW["OrderTally"] === {{Infinity, 100}},

  (* --- path V full-support stratum (v < 1) --- *)
  "prodStratumFidentical" -> If[pF === {}, True,
    Length[DeleteDuplicates[suppTuple /@ pF]] == 1 &&
     With[{r = First[pF]}, r["SectionCount"] == 400 && r["GlobalSupportSize"] == 1024 &&
       r["ObstructedCount"] == 0 && r["OrderTally"] === {{1, 400}}]],
  "prodXcheckV1equalsQuantumRow" -> If[! fullRun, True,
    pAx =!= None && pAq =!= None && suppTuple[pAx] === suppTuple[pAq] &&
     Abs[pAx["CF"] - pAq["CF"]] < 10^-8],

  (* --- internal consistency of the cohomology stack, every row --- *)
  "allComplexesClose" -> AllTrue[results, #["ComplexCloses"] &],
  "allGammaCocyclesVerified" -> AllTrue[results, #["GammaCocyclesVerified"] &],
  "allRelativeOrdersMatchObstruction" -> AllTrue[results, #["OrdersMatchObstruction"] &],

  (* --- P4: movement located ONLY at support-stratum boundaries --- *)
  "p4orderSpectraFlatWithinStrata" -> And[
    Length[DeleteDuplicates[#["OrderTally"] & /@ pA]] <= 1,
    Length[DeleteDuplicates[#["OrderTally"] & /@ pF]] <= 1,
    Length[DeleteDuplicates[#["OrderTally"] & /@ sA1]] <= 1],
  "p4movementAtBoundaries" -> If[! fullRun, True,
    pW =!= None && first1[pA] =!= None &&
     first1[pA]["OrderTally"] =!= pW["OrderTally"] &&
     suppTuple[first1[pA]] =!= suppTuple[pW]],

  (* --- mixed stratum controls: recorded (marginalization argument check) --- *)
  "mixedRowsRecorded" -> If[pM === {}, "not run (pilot)",
    StringRiffle[Table[r["param"] <> ": sections=" <> ToString[r["SectionCount"]] <>
       " obstructed=" <> ToString[r["ObstructedCount"]] <>
       " orders=" <> ToString[r["OrderTally"], InputForm] <>
       " CF=" <> cfString[r["CF"]], {r, pM}], " ; "]],
  "mixedAllWrightFactorSectionsObstructed" -> If[pM === {}, True,
    AllTrue[pM, #["SectionCount"] == 150 && #["ObstructedCount"] == 150 &]]
|>;

trap2Confirmed = TrueQ[P1P4Verification["prodStratumAidenticalSupportInvariants"] &&
   P1P4Verification["singleA1identical"] && P1P4Verification["prodStratumFidentical"] &&
   P1P4Verification["p4orderSpectraFlatWithinStrata"]];
P1P4Verification["verdict"] = If[trap2Confirmed,
  "TRAP 2 CONFIRMED: every support-level invariant (obstruction census, obstruction orders, absolute and relative Cech groups, torsion) is constant across classical -> quantum -> alpha* wherever supports coincide; only the LP layer (GlobalSectionQ, CF) moves. The possibilistic route to S_k is CLOSED with this citable table; movement occurs exactly at the support-stratum boundaries (p = 1/2 Wright jump, v < 1 full-support entry).",
  "TRAP 2 REFUTED --- MAJOR SURPRISE: some support-level invariant moved inside a support stratum. That invariant is promoted to research object. ESCALATE."];
P1P4Verification["OK"] = And @@ Cases[Values[P1P4Verification], _?BooleanQ];

Print["\n================ PRE-REGISTERED VERIFICATION ================"];
Do[Print[k, " -> ", P1P4Verification[k]], {k, Keys[P1P4Verification]}];
Print["\nOK -> ", P1P4Verification["OK"]];
Print["total ", Round[AbsoluteTime[] - startT], " s, ", Length[results], " rows; CSVs: p1p4_census.csv, p1p4_torsion.csv"];
