(* ::Package:: *)

(* ===========================================================================
   tests_interferometer_layer.wl -- headless gate battery for Builder A
   (InterferometerLayer.wl): anchors A1 (KCBS cascade), A2 (C7/C9 cascade),
   A4 (mesh routing vs wordRingEdgesFast), plus general Reck/Clements
   round-trip self-consistency. Prints an InterferometerLayerVerification
   association whose "OK" must evaluate True (the repo signature).

   Run:  wolframscript -file tests_interferometer_layer.wl
   =========================================================================== *)

Get[FileNameJoin[{DirectoryName[$InputFileName], "InterferometerLayer.wl"}]];

BeginPackage["HubertKolcz`OpticalCompiler`"];  (* re-enter for symbol access *)
EndPackage[];
Needs["HubertKolcz`OpticalCompiler`"];

phi = GoldenRatio;

Print["=================================================================="];
Print["  A1 -- KCBS pentagon reproduces the Lapkiewicz cascade EXACTLY"];
Print["=================================================================="];

bp = CompileInterferometer[<|"Scenario" -> "KCBS"|>];
stages = bp["Stages"];
bsStages = Select[stages, #["Type"] === "BS" &];

(* (i) every BS angle has cos = 1/GoldenRatio, exactly *)
anglesExact = #["Parameter", "Exact"] & /@ bsStages;
a1AngleId = And @@ (RootReduce[Cos[#] - 1/phi] === 0 & /@ anglesExact);
a1SinId = And @@ (RootReduce[Sin[#]^2 - 1/phi] === 0 & /@ anglesExact);
Print["BS angles (Exact): ", anglesExact];
Print["  all Cos[theta] == 1/GoldenRatio (RootReduce) : ", a1AngleId];
Print["  all Sin[theta]^2 == 1/GoldenRatio            : ", a1SinId];
Print["  angle == ArcCos[1/GoldenRatio] each          : ",
  And @@ (RootReduce[# - ArcCos[1/phi]] === 0 & /@ anglesExact)];

(* (ii) period-2 structure T3==T1, T4==T2 ; modes touched ; shared-detector *)
Ts = bp["Ts"];
a1Period = RootReduce[Ts[[3]] - Ts[[1]]] === ConstantArray[0, {3, 3}] &&
           RootReduce[Ts[[4]] - Ts[[2]]] === ConstantArray[0, {3, 3}];
modesList = #["Modes"] & /@ bsStages;
a1Modes = modesList === {{1, 3}, {2, 3}, {1, 3}, {2, 3}};
a1Shared = bp["SharedDetector"] === {2, 1, 2, 1};
labels = #["Label"] & /@ stages;
Print["labels (stage order)           : ", labels];
Print["T3==T1 && T4==T2 (period-2)     : ", a1Period];
Print["BS modes {a,b} per stage        : ", modesList, "  (expect {1,3},{2,3},{1,3},{2,3}) : ", a1Modes];
Print["shared-detector alternation     : ", bp["SharedDetector"], "  == {2,1,2,1} : ", a1Shared];

(* (iii) statistics: context probs, Heisenberg sum, S = 5 - 4 Sqrt5 *)
Uk[k_] := Fold[#2 . #1 &, IdentityMatrix[3],
   RootReduce[#["Matrix", "Exact"]] & /@ Take[stages, k]];
ctxProbs = Table[RootReduce[Abs[Uk[k] . {1, 0, 0}]^2], {k, 5}];
corr = (#[[3]] - #[[1]] - #[[2]]) & /@ ctxProbs;
Sval = RootReduce[Total[corr]];
a1Prob = And @@ (RootReduce[# - {1/Sqrt[5], 1/Sqrt[5], (5 - 2 Sqrt[5])/5}] === {0, 0, 0} & /@ ctxProbs);
a1S = RootReduce[Sval - (5 - 4 Sqrt[5])] === 0;
heisSum = RootReduce[Total[Table[ctxProbs[[k, 1]], {k, 5}]] +
    Total[Table[ctxProbs[[k, 2]], {k, 5}]]]/2;  (* sum of node expectations / 2? *)
(* node expectation per context = p1+p2 shared appropriately; use direct sum of first-slot *)
nodeSum = RootReduce[Total[ctxProbs[[All, 1]]] + Total[ctxProbs[[All, 2]]]]/2;
Print["context prob[1] (Exact)         : ", ctxProbs[[1]]];
Print["all ctx probs == (1/Sqrt5,1/Sqrt5,(5-2Sqrt5)/5) : ", a1Prob];
Print["S = Total[corr] (Exact)          : ", Sval, "  == 5-4Sqrt5 : ", a1S, "  (N: ", N[Sval], ")"];

(* self-consistency: StagesToUnitary reproduces the folded cascade unitary *)
Ufull = StagesToUnitary[stages, 3];
a1Recon = RootReduce[Ufull["Exact"] - Uk[5]] === ConstantArray[0, {3, 3}];
Print["StagesToUnitary == folded cascade unitary : ", a1Recon];

A1 = And[a1AngleId, a1SinId, a1Period, a1Modes, a1Shared, a1Prob, a1S, a1Recon];
Print[">>> A1 PASS : ", A1];

Print[];
Print["=================================================================="];
Print["  A2 -- C7 (and C9) target -> n-cycle cascade"];
Print["=================================================================="];

a2Check[n_] := Module[{b, sts, Tsn, angs, cthetaCF, Svaln, ok, probsn, corrn, ukn},
  b = CompileInterferometer[<|"Scenario" -> "Cn", "n" -> n|>];
  sts = b["Stages"];
  Tsn = N[b["Ts"]];
  angs = #["Parameter", "Exact"] & /@ Select[sts, #["Type"] === "BS" &];
  cthetaCF = N[n Cos[Pi/n]/(1 + Cos[Pi/n])];  (* theta(C_n) closed form *)
  (* statistics evaluated NUMERICALLY (A2 anchor is a numeric match, DESIGN 6) *)
  ukn[k_] := Fold[#2 . #1 &, IdentityMatrix[3],
     #["Matrix", "Numeric"] & /@ Take[sts, k]];
  probsn = Table[Abs[ukn[k] . {1, 0, 0}]^2, {k, n}];
  corrn = (#[[3]] - #[[1]] - #[[2]]) & /@ probsn;
  Svaln = Total[corrn];
  ok = Abs[Svaln - (n - 4 cthetaCF)] < 10^-8;
  <|"n" -> n, "S" -> Svaln, "n-4theta" -> N[n - 4 cthetaCF],
    "match" -> ok, "numBS" -> Length[angs],
    "twoLevel" -> AllTrue[Range[n - 1], Function[k,
       Abs[Tsn[[k, b["SharedDetector"][[k]], b["SharedDetector"][[k]]]] - 1] < 10^-8]]|>];

r7 = a2Check[7]; r9 = a2Check[9];
Print["C7 : S = ", r7["S"], "  n-4theta = ", r7["n-4theta"], "  match : ", r7["match"],
  "  (", r7["numBS"], " BS stages)"];
Print["C9 : S = ", r9["S"], "  n-4theta = ", r9["n-4theta"], "  match : ", r9["match"],
  "  (", r9["numBS"], " BS stages)"];
A2 = r7["match"] && r9["match"] && r7["twoLevel"] && r9["twoLevel"];
Print[">>> A2 PASS : ", A2];

Print[];
Print["=================================================================="];
Print["  A4 -- mesh routing EdgeList == wordRingEdgesFast (word=cct)"];
Print["=================================================================="];

(* independent reference copy of wordRingEdgesFast for the comparison *)
refEdges[word_, reps_] := Module[{w = Characters[StringRepeat[word, reps]], L, blocks},
  L = Length[w];
  blocks = Table[Module[{km = Mod[k - 1, L], u, v},
     {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
     {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2}, {3 k + 2, 3 k + 3}, {3 k + 3, v}}],
    {k, 0, L - 1}];
  DeleteDuplicates[Sort /@ Flatten[blocks, 1]]];

a4Rows = Table[
  Module[{m = CompileMeshRouting["cct", reps], ref = refEdges["cct", reps], match, modeOk, orient},
   match = (Sort[m["EdgeList"]] === Sort[ref]);
   modeOk = (m["ModeCount"] === 3 StringLength[StringRepeat["cct", reps]]);
   orient = #["Orientation"] & /@ m["Routing"];
   <|"reps" -> reps, "L" -> m["L"], "modes" -> m["ModeCount"],
     "nEdges" -> Length[m["EdgeList"]], "EXACT" -> (match && modeOk),
     "orient" -> orient|>], {reps, {1, 2, 3}}];
Do[Print["reps=", r["reps"], "  L=", r["L"], "  modes=", r["modes"],
   "  edges=", r["nEdges"], "  EXACT MATCH=", r["EXACT"], "  orient=", r["orient"]], {r, a4Rows}];
A4 = AllTrue[a4Rows, #["EXACT"] &];
Print[">>> A4 PASS : ", A4];

Print[];
Print["=================================================================="];
Print["  Round-trip self-consistency of GivensDecompose (Reck/Clements)"];
Print["=================================================================="];

SeedRandom[20260713];
rtNumeric[method_] := Module[{u, dec, rec},
  u = Orthogonalize[RandomReal[{-1, 1}, {5, 5}]];
  dec = GivensDecompose[u, method];
  rec = StagesToUnitary[dec, 5]["Numeric"];
  Max@Abs@Flatten[rec - u]];
rtR = rtNumeric["Reck"]; rtC = rtNumeric["Clements"];
Print["Reck    5x5 random O(5) round-trip max dev : ", rtR];
Print["Clements 5x5 random O(5) round-trip max dev : ", rtC];
(* exact round-trip on an algebraic matrix (a KCBS T-matrix) *)
Texact = bp["Ts"][[1]];
decT = GivensDecompose[Texact, "Reck"];
recT = StagesToUnitary[decT, 3]["Exact"];
rtExact = RootReduce[recT - Texact] === ConstantArray[0, {3, 3}];
Print["Reck exact round-trip on T1 (algebraic)     : ", rtExact];
RT = rtR < 10^-10 && rtC < 10^-10 && rtExact;
Print[">>> ROUND-TRIP PASS : ", RT];

Print[];
Print["=================================================================="];
InterferometerLayerVerification = <|
  "A1_KCBS_cascade" -> A1,
  "A1_angle_Exact" -> anglesExact[[1]],
  "A1_S" -> N[Sval], "A1_S_exact_is_5m4sqrt5" -> a1S,
  "A2_C7_match" -> r7["match"], "A2_C9_match" -> r9["match"],
  "A4_mesh_exact" -> A4,
  "RoundTrip_Reck" -> (rtR < 10^-10), "RoundTrip_Clements" -> (rtC < 10^-10),
  "RoundTrip_exact" -> rtExact,
  "OK" -> And[A1, A2, A4, RT]|>;
Print["InterferometerLayerVerification:"];
Print[InterferometerLayerVerification];
Print["=================================================================="];
Print["OK -> ", InterferometerLayerVerification["OK"]];
