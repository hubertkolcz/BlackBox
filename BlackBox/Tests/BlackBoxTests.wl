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
  "fourGenerators" -> Length[gens] == 4,
  "generatorSpan" -> MatrixRank[So3Axis /@ gens, Tolerance -> 10^-8] == 2,
  "dlaCloses" -> DLADimension[gens] == 3
|>;
Print[SmokeTest];
Print["ALL PASS: ", And @@ Values[SmokeTest]];
