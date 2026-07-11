(* Test battery: every HubertKolcz`BlackBox` public symbol against the kernel-verified
   pipeline values of 10 July 2026. Run: wolframscript -file BlackBoxTests.wl
   Must print ALL PASS: True. *)
PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName], ".."}]];
Needs["HubertKolcz`BlackBox`"];

c5 = CycleGraph[5];
qv = ConstantArray[N[1/Sqrt[5]], 5];
wv = ConstantArray[.5, 5];

scen5 = CycleScenario[5];
scen7 = CycleScenario[7];
eQ = N@CycleModel[5, "Quantum"]; eW = N@CycleModel[5, "Wright"]; eC = N@CycleModel[5, "Classical"];
del5 = CycleCoboundary[5];
gens = CascadeGenerators[];
ceQ = CEFilter[c5, qv]; ceW = CEFilter[c5, wv];
ce7 = CEFilter[CycleGraph[7], ConstantArray[.5, 7]];

(* Cech obstruction of the support presheaf: exact models throughout *)
chC = CechObstruction[scen5, CycleModel[5, "Classical"]];
chQ = CechObstruction[scen5, CycleModel[5, "Quantum"]];
chW = CechObstruction[scen5, CycleModel[5, "Wright"]];
chQ7 = CechObstruction[scen7, CycleModel[7, "Quantum"]];
chW7 = CechObstruction[scen7, CycleModel[7, "Wright"]];
chW6 = CechObstruction[CycleScenario[6], CycleModel[6, "Wright"]];
scen4 = CycleScenario[4];
ePR = Flatten[{{1/2, 0, 0, 1/2}, {1/2, 0, 0, 1/2}, {1/2, 0, 0, 1/2}, {0, 1/2, 1/2, 0}}];
eHardy = Flatten[{{1/12, 1/12, 1/12, 3/4}, {0, 1/6, 2/3, 1/6}, {1/3, 1/3, 1/3, 0}, {0, 2/3, 1/6, 1/6}}];
chPR = CechObstruction[scen4, ePR];
chH = CechObstruction[scen4, eHardy];
edges5 = Table[{i, Mod[i + 1, 5]}, {i, 0, 4}];
scenProd = CoverScenario[Join[Table[{1, i}, {i, 0, 4}], Table[{2, i}, {i, 0, 4}]],
  Flatten[Table[{{1, ed[[1]]}, {1, ed[[2]]}, {2, f[[1]]}, {2, f[[2]]}}, {ed, edges5}, {f, edges5}], 1]];
prodModel[m1_, m2_] := With[{d1 = AssociationThread[Tuples[{0, 1}, 2] -> m1[[1 ;; 4]]],
    d2 = AssociationThread[Tuples[{0, 1}, 2] -> m2[[1 ;; 4]]]},
  Flatten[Table[d1[s[[1 ;; 2]]] d2[s[[3 ;; 4]]], {c, scenProd["Contexts"]}, {s, Tuples[{0, 1}, 4]}]]];
chWW = CechObstruction[scenProd, prodModel[CycleModel[5, "Wright"], CycleModel[5, "Wright"]]];
chQQ = CechObstruction[scenProd, prodModel[CycleModel[5, "Quantum"], CycleModel[5, "Quantum"]]];
ccC = CechCohomology[scen5, CycleModel[5, "Classical"]];
ccQ = CechCohomology[scen5, CycleModel[5, "Quantum"]];
ccW = CechCohomology[scen5, CycleModel[5, "Wright"]];
ccU = CechCohomology[scen4, ConstantArray[1/4, 16]];
ccPR = CechCohomology[scen4, ePR];
ccH = CechCohomology[scen4, eHardy];
ccWW = CechCohomology[scenProd, prodModel[CycleModel[5, "Wright"], CycleModel[5, "Wright"]]];
ccQQ = CechCohomology[scenProd, prodModel[CycleModel[5, "Quantum"], CycleModel[5, "Quantum"]]];
z3Scen = CoverScenario[Range[0, 3], Table[{i, Mod[i + 1, 4]}, {i, 0, 3}], Range[0, 2]];
z3Model = Flatten[Table[If[Mod[s[[2]] - s[[1]], 3] == If[c == 3, 1, 0], 1/3, 0],
   {c, 0, 3}, {s, Tuples[Range[0, 2], 2]}]];
chZ3 = CechObstruction[z3Scen, z3Model];
avnZ3 = AvNArgument[z3Scen, z3Model, 3];
chZ3c = CechObstruction[z3Scen, Flatten[Table[If[Mod[s[[2]] - s[[1]], 3] == 0, 1/3, 0],
    {c, 0, 3}, {s, Tuples[Range[0, 2], 2]}]]];
ghzScen = CoverScenario[{"aX", "aY", "bX", "bY", "cX", "cY"},
  {{"aX", "bX", "cX"}, {"aX", "bY", "cY"}, {"aY", "bX", "cY"}, {"aY", "bY", "cX"}}];
ghzModel = Flatten[Table[If[Mod[Total[s], 2] == par, 1/4, 0], {par, {0, 1, 1, 1}}, {s, Tuples[{0, 1}, 3]}]];
chGHZ = CechObstruction[ghzScen, ghzModel];
avnGHZ = AvNArgument[ghzScen, ghzModel];
avnOf[scn_, ee_] := AvNArgument[scn, ee]["AvN"];

SmokeTest = <|
  "alpha" -> IndependenceNumber[c5] == 2,
  "theta" -> Abs[LovaszTheta[c5] - Sqrt[5.]] < 10^-6,
  "alphaStar" -> FractionalPackingNumber[c5] == 5/2,
  "kcbsOrthogonal" -> AllTrue[Table[Simplify[KCBSDirections[][[i]] . KCBSDirections[][[Mod[i, 5] + 1]]], {i, 5}], # === 0 &],
  "kcbsSum" -> Simplify[Total[(#. {0, 0, 1})^2 & /@ KCBSDirections[]] - Sqrt[5]] === 0,
  "glue" -> Through[{VertexCount, EdgeCount}[GlueGraphs[c5, VertexReplace[c5, Thread[Range[5] -> Range[6, 10]]], {6 -> 1, 7 -> 2}]]] == {8, 9},
  "chain" -> Through[{VertexCount, EdgeCount}[PentagonChain[2]]] == {8, 9},
  "chainTheta" -> Abs[LovaszTheta[PentagonChain[3]] - 5.1366] < 10^-3,
  "ceQuantum" -> ceQ["Passes"] && ceQ["CliqueCount"] == 535 && ceQ["Omega"] == 5,
  "ceWright" -> ! ceW["Passes"] && ceW["ViolatingCliques"] == 10 && Abs[ceW["Worst"] - 5/4] < 10^-12,
  "ceC7NoActivation" -> ce7["Passes"] && ce7["Omega"] == 4,
  "scenarioRank5" -> MatrixRank[scen5["Incidence"]] == 11,
  "scenarioRank7" -> MatrixRank[scen7["Incidence"]] == 15,
  "quantumModelIsRoot5" -> Simplify[CycleModel[5, "Quantum"][[2]] - 1/Sqrt[5]] === 0,
  "ncfQuantum" -> Abs[NoncontextualFraction[scen5, eQ] - (5 - 2 Sqrt[5.])] < 10^-8,
  "cfQuantum" -> Abs[ContextualFraction[scen5, eQ] - (2 Sqrt[5.] - 4)] < 10^-8,
  "ncfClassical" -> Abs[NoncontextualFraction[scen5, eC] - 1] < 10^-8,
  "ncfWright" -> Abs[NoncontextualFraction[scen5, eW]] < 10^-8,
  "ncfClassicalC7" -> Abs[NoncontextualFraction[scen7, N@CycleModel[7, "Classical"]] - 1] < 10^-8,
  "sectionClassical" -> GlobalSectionQ[scen5, eC],
  "noSectionQuantum" -> ! GlobalSectionQ[scen5, eQ],
  "noSectionWright" -> ! GlobalSectionQ[scen5, eW],
  "supportQuantumLucas" -> PossibilisticSupport[scen5, eQ]["Size"] == 11,
  "supportWrightEmpty" -> PossibilisticSupport[scen5, eW]["Empty"],
  "coboundaryRank" -> MatrixRank[del5] == 9,
  "kerLaplacian" -> 20 - MatrixRank[Transpose[del5] . del5] == 11,
  "residualsVanish" -> AllTrue[HarmonicResidual[del5, #] & /@ {eC, eQ, eW}, # < 10^-10 &],
  "coverGeneralizesCycle" -> With[{cs = CoverScenario[Range[0, 4], Table[{i, Mod[i + 1, 5]}, {i, 0, 4}]]},
     cs["Incidence"] === scen5["Incidence"] && cs["Sections"] === scen5["Sections"]],
  "cechClassicalUnobstructed" -> chC["ObstructedCount"] == 0 && chC["SectionCount"] == 15 &&
     ! chC["LogicallyContextual"] && chC["SupportNoSignalling"],
  "cechQuantumUnobstructed" -> chQ["ObstructedCount"] == 0 && chQ["SectionCount"] == 15 &&
     chQ["GlobalSupportSize"] == 11 && ! chQ["CohLogicallyContextual"],
  "cechWrightAllObstructed" -> chW["ObstructedCount"] == 10 && chW["SectionCount"] == 10 &&
     chW["CohStronglyContextual"] && chW["StronglyContextual"] && chW["H0Rank"] == 1,
  "cechGateTriple" -> Length[DeleteDuplicates[
       {#["ObstructedCount"] > 0, GlobalSectionQ[scen5, N@CycleModel[5, #2]]} & @@@
       {{chC, "Classical"}, {chQ, "Quantum"}, {chW, "Wright"}}]] == 3,
  "cechC7" -> chW7["ObstructedCount"] == 14 && chW7["CohStronglyContextual"] &&
     chQ7["ObstructedCount"] == 0 && chQ7["SectionCount"] == 21 && chQ7["GlobalSupportSize"] == 29,
  "cechC6WrightParity" -> chW6["ObstructedCount"] == 0 && chW6["SectionCount"] == 12 &&
     chW6["GlobalSupportSize"] == 2 && ! chW6["LogicallyContextual"],
  "cechPRBoxAllObstructed" -> chPR["ObstructedCount"] == 8 && chPR["CohStronglyContextual"] &&
     chPR["StronglyContextual"],
  "cechHardyFalseNegative" -> chH["ObstructedCount"] == 0 && chH["LogicallyContextual"] &&
     ! chH["StronglyContextual"] && chH["FalseNegatives"] === {{{0, 1}, {0, 0}}} &&
     chH["SupportNoSignalling"] && chH["H0Rank"] == 6,
  "cechProductWright" -> chWW["ObstructedCount"] == 100 && chWW["SectionCount"] == 100 &&
     chWW["CohStronglyContextual"],
  "cechProductQuantum" -> chQQ["ObstructedCount"] == 0 && chQQ["SectionCount"] == 225 &&
     chQQ["GlobalSupportSize"] == 121,
  "cechCohomC5" -> ({#["H0Rank"], #["H1FreeRank"], #["H1Torsion"]} & /@ {ccC, ccQ, ccW}) ===
       {{6, 1, {}}, {6, 1, {}}, {1, 1, {}}} &&
     AllTrue[{ccC, ccQ, ccW}, #["ComplexCloses"] &] &&
     ccC["H0Rank"] == chC["H0Rank"] && ccW["H0Rank"] == chW["H0Rank"],
  "cechCohomCHSHCensus" -> ({#["H0Rank"], #["H1FreeRank"], #["H1Torsion"]} & /@ {ccU, ccPR, ccH}) ===
     {{9, 1, {}}, {1, 1, {}}, {6, 1, {}}},
  "cechCohomProduct" -> ccWW["CochainRanks"] == {100, 700, 2200} && ccWW["H0Rank"] == 1 &&
     ccWW["H1FreeRank"] == 0 && ccWW["ComplexCloses"] &&
     ccQQ["H0Rank"] == 36 && ccQQ["H0Rank"] == ccQ["H0Rank"]^2 && ccQQ["ComplexCloses"],
  "cechGHZAllObstructed" -> chGHZ["ObstructedCount"] == 16 && chGHZ["SectionCount"] == 16 &&
     chGHZ["CohStronglyContextual"] && chGHZ["GlobalSupportSize"] == 0 && chGHZ["H0Rank"] == 7,
  "avnGHZMermin" -> avnGHZ["AvN"] && avnGHZ["EquationCount"] == 4 &&
     avnGHZ["Equations"][[All, 2]] === ConstantArray[{1, 1, 1}, 4] &&
     avnGHZ["Equations"][[All, 3]] === {0, 1, 1, 1},
  "avnCensus" -> (avnOf @@@ {{scen5, CycleModel[5, "Classical"]}, {scen5, CycleModel[5, "Wright"]},
       {scen4, ePR}, {scen4, eHardy}, {CycleScenario[6], CycleModel[6, "Wright"]},
       {scenProd, prodModel[CycleModel[5, "Wright"], CycleModel[5, "Wright"]]},
       {scenProd, prodModel[CycleModel[5, "Quantum"], CycleModel[5, "Quantum"]]}}) ===
     {False, True, True, False, False, True, False},
  "avnImpliesCohStrong" -> AllTrue[{{avnGHZ["AvN"], chGHZ}, {avnOf[scen5, CycleModel[5, "Wright"]], chW},
       {avnOf[scen4, ePR], chPR}, {avnOf[scen4, eHardy], chH}},
     Function[p, ! p[[1]] || p[[2]]["CohStronglyContextual"]]],
  "z3BoxAllObstructed" -> chZ3["ObstructedCount"] == 12 && chZ3["SectionCount"] == 12 &&
     chZ3["CohStronglyContextual"] && chZ3["StronglyContextual"] && chZ3["SupportNoSignalling"],
  "z3AvNOverGF3" -> avnZ3["AvN"] && avnZ3["EquationCount"] == 4 &&
     avnZ3["Equations"][[All, 2]] === ConstantArray[{1, 2}, 4] && avnZ3["Equations"][[All, 3]] === {0, 0, 0, 2} &&
     Quiet[AvNArgument[z3Scen, z3Model]] === $Failed,
  "cechObstructionOrders" -> AllTrue[Values[chGHZ["ObstructionOrder"]], # === 2 &] &&
     AllTrue[Values[chW["ObstructionOrder"]], # === Infinity &] &&
     AllTrue[Values[chPR["ObstructionOrder"]], # === Infinity &] &&
     AllTrue[Values[chZ3["ObstructionOrder"]], # === Infinity &] &&
     AllTrue[Values[chH["ObstructionOrder"]], # === 1 &] &&
     AllTrue[Values[chC["ObstructionOrder"]], # === 1 &],
  "z3ControlNoncontextual" -> chZ3c["ObstructedCount"] == 0 && chZ3c["GlobalSupportSize"] == 3 &&
     GlobalSectionQ[z3Scen, N@Flatten[Table[If[Mod[s[[2]] - s[[1]], 3] == 0, 1/3, 0],
        {c, 0, 3}, {s, Tuples[Range[0, 2], 2]}]]],
  "fourGenerators" -> Length[gens] == 4,
  "generatorSpan" -> MatrixRank[So3Axis /@ gens, Tolerance -> 10^-8] == 2,
  "dlaCloses" -> DLADimension[gens] == 3
|>;
Print[SmokeTest];
Print["ALL PASS: ", And @@ Values[SmokeTest]];
