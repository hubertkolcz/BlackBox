(* lever_seeds-parallel_run.wl -- LEVER 1 measurement harness (SCRATCH, new file).
   Algorithm code is VERBATIM from GenerateEpsilonCertificate9.wl; the ONLY
   deltas are: K + seed-subset MODE from the command line, optional
   ParallelMap of the (unchanged) RunFromSeed over subkernels, timing/memory
   instrumentation prints ("[LEVER]"), export into opt/ scratch names, and a
   byte-identity check of GammaExact vs ground truth (testK3/4/5 outputs, or
   opt/profile_cert_K6.wl for K=6).

   Run: wolframscript -file lever_seeds-parallel_run.wl <K> <MODE>
   MODE in: A | B | AB | ALL4 | PAR2 | PAR4      (PARn = parallel on n kernels)
*)

SetDirectory[DirectoryName[$InputFileName]];
$T0 = AbsoluteTime[];
mb[x_] := N[x/2^20, 6];
lev[args___] := Print["[LEVER] +", NumberForm[AbsoluteTime[] - $T0, {8, 2}], "s ", args];

args = $ScriptCommandLine;
K = ToExpression[args[[-2]]];
MODE = args[[-1]];
If[! (IntegerQ[K] && 3 <= K <= 7), Print["bad K"]; Exit[1]];
If[! MemberQ[{"A", "B", "AB", "ALL4", "PAR2", "PAR4"}, MODE], Print["bad MODE"]; Exit[1]];
lev["K = ", K, "  MODE = ", MODE];

MAXPOLICYROUNDS = 20;
RATIONALTOL = 10^-9;

(* ---- STAGE 0 (verbatim) ---- *)
nodes = StringJoin /@ Tuples[{"d", "t"}, K];
edges = Select[Tuples[nodes, 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];
iu = 1; iv = 2; ia = 3; ib = 4; ip = 5;
jv = 1; jb = 2; jx = 3; jp = 4;
edgeLetter[e_] := StringTake[e[[1]], -1];
dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
        ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "d", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];
Td = dpTransfer["d"]; Tt = dpTransfer["t"];

(* ---- STAGE 1 setup (verbatim) ---- *)
Qs = Association[Table[w -> Table[Subscript[q, w, Min[i, j], Max[i, j]], {i, 5}, {j, 5}], {w, nodes}]];
Rs = Association[Table[w -> Table[Subscript[rblk, w, Min[i, j], Max[i, j]], {i, 4}, {j, 4}], {w, nodes}]];
dvar[w_] := Qs[w][[ip, ip]] + Rs[w][[jp, jp]];
phiVar[ph_, w_] := Subscript[phi, ph, w];
psiVar[w_] := Subscript[psiv, w];
rVar[e_] := Subscript[rvar, e];
qrVars = Join[
   Flatten[Table[Subscript[q, w, i, j], {w, nodes}, {i, 5}, {j, i, 5}]],
   Flatten[Table[Subscript[rblk, w, i, j], {w, nodes}, {i, 4}, {j, i, 4}]]];
potVars = Join[
   Flatten[Table[phiVar[ph, w], {ph, 0, 2}, {w, nodes}]],
   Table[psiVar[w], {w, nodes}],
   Table[rVar[e], {e, edges}],
   {gammaVar}];
allVars = Join[qrVars, potVars];
nodeCons = Flatten[Table[
    {Rs[w][[jx, jx]] == 1, Rs[w][[jx, jp]] == 1,
     Qs[w][[iv, ia]] == 0, Qs[w][[iu, ib]] == 0,
     Qs[w][[iv, ib]] + Rs[w][[jv, jb]] == 0},
    {w, nodes}]];
edgeCons = Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], b, rA, rB},
      b = StringTake[w, -1];
      {rA, rB} = If[b === "d", {iu, iv}, {iv, iu}];
      {
       Qs[w][[ia, ia]] + Qs[x][[rA, rA]] + If[b === "t", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ib, ib]] + Rs[w][[jb, jb]] + Qs[x][[rB, rB]] + If[b === "d", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ia, ip]] + Qs[x][[rA, ip]] + If[b === "t", Rs[x][[jv, jp]], 0] == 1,
       Qs[w][[ib, ip]] + Rs[w][[jb, jp]] + Qs[x][[rB, ip]] + If[b === "d", Rs[x][[jv, jp]], 0] == 1
      }],
    {e, edges}]];
PSDMARGIN = 10^-6;
psdCons = Join[
   Table[VectorGreaterEqual[{Qs[w] - PSDMARGIN*IdentityMatrix[5], 0}, {"SemidefiniteCone", 5}], {w, nodes}],
   Table[VectorGreaterEqual[{Rs[w] - PSDMARGIN*IdentityMatrix[4], 0}, {"SemidefiniteCone", 4}], {w, nodes}]];

validSigs[T_, s_] := Select[Range[3], T[[s, #]] > -Infinity &];
refNode = First[nodes];
CanonicalPhi[strategy_] := Module[{potCons, tVar},
   potCons = Flatten[Table[
      Module[{w = e[[1]], x = e[[2]], sig, T},
        T = If[edgeLetter[e] === "d", Td, Tt];
        sig = strategy[{s, e}];
        tVar <= T[[s, sig]] + phiVar[sig - 1, x] - phiVar[s - 1, w]],
      {e, edges}, {s, 1, 3}]];
   Quiet[Check[
     LinearOptimization[-tVar, Join[potCons, {phiVar[0, refNode] == 0}],
       Append[Flatten[Table[phiVar[ph, w], {ph, 0, 2}, {w, nodes}]], tVar]],
     $Failed]]];
SolveJoint[strategy_] := Module[{potCons},
   potCons = Join[
     Flatten[Table[
       Module[{w = e[[1]], x = e[[2]], sig, T},
         T = If[edgeLetter[e] === "d", Td, Tt];
         sig = strategy[{s, e}];
         rVar[e] <= T[[s, sig]] + phiVar[sig - 1, x] - phiVar[s - 1, w]],
       {e, edges}, {s, 1, 3}]],
     Table[
      Module[{w = e[[1]], x = e[[2]]},
        dvar[x] - rVar[e] + psiVar[x] - psiVar[w] <= gammaVar],
      {e, edges}]];
   SemidefiniteOptimization[gammaVar, Join[psdCons, nodeCons, edgeCons, potCons], allVars]];
Improve[strategy_, canonSol_] := Association[Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], T, valid, vals},
      T = If[edgeLetter[e] === "d", Td, Tt];
      valid = validSigs[T, s];
      vals = (T[[s, #]] + (phiVar[# - 1, x] /. canonSol)) & /@ valid;
      {s, e} -> valid[[First@Ordering[-vals, 1]]]],
    {e, edges}, {s, 1, 3}]]];

seedA = Association[Table[
   Module[{T = If[edgeLetter[e] === "d", Td, Tt], valid},
     valid = validSigs[T, s];
     {s, e} -> If[MemberQ[valid, s], s, First[valid]]],
   {e, edges}, {s, 1, 3}]];
seedB = Association[Table[
   Module[{T = If[edgeLetter[e] === "d", Td, Tt], valid}, valid = validSigs[T, s];
     {s, e} -> First[valid]],
   {e, edges}, {s, 1, 3}]];
randomSeed[seedNum_] := (SeedRandom[seedNum];
   Association[Table[
     Module[{T = If[edgeLetter[e] === "d", Td, Tt], valid}, valid = validSigs[T, s];
       {s, e} -> RandomChoice[valid]],
     {e, edges}, {s, 1, 3}]]);

RunFromSeed[strategy0_, label_] := Module[
  {strat = strategy0, canonSol, jointSol, gam = $Failed, newStrat, round = 0,
   converged = False, t0 = AbsoluteTime[]},
  Print["  seed ", label, ":"];
  While[round < MAXPOLICYROUNDS,
    round++;
    canonSol = CanonicalPhi[strat];
    If[canonSol === $Failed,
      Print["    round ", round, ": canonical-Phi LP FAILED"]; Break[]];
    jointSol = Check[SolveJoint[strat], $Failed];
    If[jointSol === $Failed || Head[jointSol] =!= List,
      Print["    round ", round, ": joint SDP FAILED or returned unevaluated"]; Break[]];
    gam = gammaVar /. jointSol;
    Print["    round ", round, ": Gamma = ", N[gam, 8]];
    newStrat = Improve[strat, canonSol];
    If[newStrat === strat,
      Print["    converged at round ", round];
      converged = True; Break[]];
    If[round == MAXPOLICYROUNDS,
      Print["    WARNING: MAXPOLICYROUNDS reached without convergence"];
      Break[]];
    strat = newStrat];
  Print["[LEVER]   SEED ", label, " wall: ", NumberForm[AbsoluteTime[] - t0, {8, 2}],
    " s, rounds ", round, ", kernel $KernelID=", $KernelID];
  {label, jointSol, strat, gam, round, converged}];

(* ---- seed subset / parallel dispatch (the ONLY structural change) ---- *)
seedSpecs = Switch[MODE,
   "A", {{seedA, "A (sig=s)"}},
   "B", {{seedB, "B (first valid)"}},
   "AB" | "PAR2", {{seedA, "A (sig=s)"}, {seedB, "B (first valid)"}},
   "ALL4" | "PAR4", {{seedA, "A (sig=s)"}, {seedB, "B (first valid)"},
     {randomSeed[1], "random-1"}, {randomSeed[2], "random-2"}}];
parallelQ = StringStartsQ[MODE, "PAR"];

pws[pid_] := Module[{r},
   r = Quiet[Check[RunProcess[{"powershell", "-NoProfile", "-Command",
        "(Get-Process -Id " <> ToString[pid] <> ").PeakWorkingSet64"}], $Failed]];
   If[r === $Failed, $Failed, Quiet[ToExpression[StringTrim[r["StandardOutput"]]]]]];

lev["STAGE 1 begin (", Length[seedSpecs], " seed(s), parallel=", parallelQ, ")"];
tS1 = AbsoluteTime[];
If[parallelQ,
  Module[{nk = Min[4, Length[seedSpecs]], tL, tD, subPids},
    {tL, Null} = AbsoluteTiming[LaunchKernels[nk]];
    lev["LaunchKernels[", nk, "] : ", NumberForm[tL, {8, 2}], " s"];
    {tD, Null} = AbsoluteTiming[DistributeDefinitions["Global`"]];
    lev["DistributeDefinitions : ", NumberForm[tD, {8, 2}], " s"];
    seedResults = ParallelMap[RunFromSeed[#[[1]], #[[2]]] &, seedSpecs,
      Method -> "FinestGrained"];
    subPids = ParallelEvaluate[$ProcessID];
    subMaxMem = ParallelEvaluate[{$KernelID, mb[MaxMemoryUsed[]]}];
    lev["subkernel MaxMemoryUsed (MB): ", subMaxMem];
    subPeakWS = {#, mb[pws[#]]} & /@ subPids;
    lev["subkernel OS PeakWorkingSet (MB): ", subPeakWS];
    lev["subkernel PeakWS TOTAL (MB): ", Total[subPeakWS[[All, 2]] /. $Failed -> 0]];
    CloseKernels[]],
  seedResults = RunFromSeed[#[[1]], #[[2]]] & /@ seedSpecs];
lev["STAGE 1 wall: ", NumberForm[AbsoluteTime[] - tS1, {8, 2}], " s"];
lev["main kernel MaxMemoryUsed = ", mb[MaxMemoryUsed[]], " MB, OS PeakWS = ",
  mb[pws[$ProcessID]], " MB"];

(* ---- seed selection + agreement (verbatim semantics, subset-aware) ---- *)
convergedSeedResults = Select[seedResults, #[[6]] &];
candidateSeedResults = If[Length[convergedSeedResults] > 0, convergedSeedResults, seedResults];
If[Length[convergedSeedResults] == 0, Print["  WARNING: NO seed converged"]];
bestIdx = First@Ordering[N[#[[4]], 10] & /@ candidateSeedResults, 1];
{finalLabel, finalSol, finalStrategy, finalGamma, roundsUsed, finalConverged} = candidateSeedResults[[bestIdx]];
Print["Stage 1 result: best seed = ", finalLabel, ", Gamma_", K, " (numeric) = ",
  N[finalGamma, 10], ", converged = ", finalConverged];
Print["  All seeds: ", {#[[1]], N[#[[4]], 10], #[[6]]} & /@ seedResults];
If[Length[seedResults] >= 2 && seedResults[[1, 1]] === "A (sig=s)" && seedResults[[2, 1]] === "B (first valid)",
  Module[{ga, gb},
    ga = If[TrueQ[seedResults[[1, 6]]], N[seedResults[[1, 4]], 10], Missing["NotConverged"]];
    gb = If[TrueQ[seedResults[[2, 6]]], N[seedResults[[2, 4]], 10], Missing["NotConverged"]];
    Print["  A-vs-B agreement: A = ", ga, ", B = ", gb, ", agree = ",
      NumericQ[ga] && NumericQ[gb] && Abs[ga - gb] < 10^-4]],
  Print["  A-vs-B agreement: NOT AVAILABLE in mode ", MODE]];

(* ---- STAGE 2 (verbatim) ---- *)
tS2 = AbsoluteTime[];
rat[x_] := Rationalize[x, RATIONALTOL];
x0 = Map[rat, qrVars /. finalSol];
eqLHS = (#[[1]] - #[[2]]) & /@ Join[nodeCons, edgeCons];
{bvec, Amat} = CoefficientArrays[eqLHS, qrVars];
bvec = -bvec;
residual = Amat.x0 - bvec;
lambda = LinearSolve[Amat.Transpose[Amat], residual];
xExact = x0 - Transpose[Amat].lambda;
exactRule = Thread[qrVars -> xExact];
QsExact = Association[Table[w -> (Qs[w] /. exactRule), {w, nodes}]];
RsExact = Association[Table[w -> (Rs[w] /. exactRule), {w, nodes}]];
lev["STAGE 2 wall: ", NumberForm[AbsoluteTime[] - tS2, {8, 2}], " s"];

(* ---- STAGE 3 (verbatim, plus timed serial vs parallel PSD check) ---- *)
tS3 = AbsoluteTime[];
nodeEqOK = AllTrue[nodes, RsExact[#][[jx, jx]] == 1 && RsExact[#][[jx, jp]] == 1 &&
     QsExact[#][[iv, ia]] == 0 && QsExact[#][[iu, ib]] == 0 &&
     QsExact[#][[iv, ib]] + RsExact[#][[jv, jb]] == 0 &];
edgeEqOK = AllTrue[edges, Module[{w = #[[1]], x = #[[2]], b, rA, rB},
      b = StringTake[w, -1]; {rA, rB} = If[b === "d", {iu, iv}, {iv, iu}];
      QsExact[w][[ia, ia]] + QsExact[x][[rA, rA]] + If[b === "t", RsExact[x][[jv, jv]], 0] == 1 &&
       QsExact[w][[ib, ib]] + RsExact[w][[jb, jb]] + QsExact[x][[rB, rB]] +
         If[b === "d", RsExact[x][[jv, jv]], 0] == 1 &&
       QsExact[w][[ia, ip]] + QsExact[x][[rA, ip]] + If[b === "t", RsExact[x][[jv, jp]], 0] == 1 &&
       QsExact[w][[ib, ip]] + RsExact[w][[jb, jp]] + QsExact[x][[rB, ip]] +
         If[b === "d", RsExact[x][[jv, jp]], 0] == 1] &];
{tPsdSer, psdOK} = AbsoluteTiming[
   AllTrue[nodes, PositiveSemidefiniteMatrixQ[QsExact[#]] && PositiveSemidefiniteMatrixQ[RsExact[#]] &]];
lev["stage3 exact PSD check SERIAL: ", NumberForm[tPsdSer, {8, 3}], " s (", 2 Length[nodes], " blocks)"];

PsiExact = Association[Table[w -> rat[psiVar[w] /. finalSol], {w, nodes}]];
PhiExact = Association[Flatten[Table[
    (ToString[ph] <> "|" <> w) -> rat[phiVar[ph, w] /. finalSol],
    {ph, 0, 2}, {w, nodes}]]];
StrategyExact = Association[Table[
    (ToString[s - 1] <> "|" <> e[[1]] <> ">" <> e[[2]]) -> finalStrategy[{s, e}],
    {e, edges}, {s, 1, 3}]];
posSigma9[e_] := Module[{w = e[[1]], x = e[[2]], T, r},
   T = If[edgeLetter[e] === "d", Td, Tt];
   r = Min[Table[Module[{sig = StrategyExact[ToString[s - 1] <> "|" <> w <> ">" <> x]},
       T[[s, sig]] + PhiExact[ToString[sig - 1] <> "|" <> x] - PhiExact[ToString[s - 1] <> "|" <> w]],
      {s, 3}]];
   (QsExact[x][[ip, ip]] + RsExact[x][[jp, jp]]) - r + PsiExact[x] - PsiExact[w]];
GammaExact = Max[posSigma9 /@ edges];
targetGamma = rat[gammaVar /. finalSol];
GAMMADRIFTTOL = 10^-4;
pointwiseOK = AllTrue[edges, posSigma9[#] <= targetGamma + GAMMADRIFTTOL &];
gammaDrift = N[GammaExact - targetGamma, 10];
gammaCrossCheckOK = Abs[gammaDrift] < GAMMADRIFTTOL;
lev["STAGE 3 wall: ", NumberForm[AbsoluteTime[] - tS3, {8, 2}], " s"];
Print["Stage 3: nodeEqOK=", nodeEqOK, " edgeEqOK=", edgeEqOK, " psdOK=", psdOK,
  " pointwiseOK=", pointwiseOK, " gammaCrossCheckOK=", gammaCrossCheckOK];
Print["Stage 3: exact Gamma_", K, " = ", GammaExact, " = ", N[GammaExact, 10]];

allPass = nodeEqOK && edgeEqOK && psdOK && pointwiseOK && gammaCrossCheckOK && finalConverged;
If[allPass,
  Export["lever_seeds-parallel_cert_K" <> ToString[K] <> "_" <> MODE <> ".wl",
   "EpsilonCertificateLever = " <> ToString[GammaExact, InputForm] <> ";\n", "Text"]];

(* ---- ground-truth byte-identity ---- *)
gtGamma = Which[
   MemberQ[{3, 4, 5}, K],
   Module[{f = "../EpsilonCertificate_testK" <> ToString[K] <> "_output.wl"},
     Get[f]; EpsilonCertificate9["Gamma"]],
   K == 6 && FileExistsQ["profile_cert_K6.wl"],
   Module[{}, Get["profile_cert_K6.wl"]; EpsilonCertificate9["Gamma"]],
   True, Missing["NoGroundTruth"]];
If[! MissingQ[gtGamma],
  Print["[LEVER] GROUND TRUTH: Gamma byte-identical = ", GammaExact === gtGamma,
    "  (mine = ", GammaExact, ", gt = ", gtGamma, ")"],
  Print["[LEVER] no ground truth for K=", K]];
lev["ALL DONE  allPass=", allPass];
