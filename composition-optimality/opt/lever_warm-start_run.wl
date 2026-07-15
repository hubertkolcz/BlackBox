(* lever_warm-start_run.wl -- LEVER 2 experiment: warm-start policy iteration at
   window K from the exact converged strategy of window K-1.

   Usage:
     wolframscript -file lever_warm-start_run.wl <K> <map> <prevCertFile> <gtCertFile> [runBaselines]
       K            : target window size (integer)
       map          : "suffix" or "prefix" -- which (K-1)-projection of each
                      K-node keys the lookup into the K-1 strategy
       prevCertFile : path to the K-1 exact certificate (defines EpsilonCertificate9)
       gtCertFile   : path to the K ground-truth certificate for byte-identity check
       runBaselines : optional "baselines" -> also rerun seedA and seedB cold for
                      a same-machine timing baseline

   The Stage-0/1/2/3 machinery below is a VERBATIM functional copy of
   GenerateEpsilonCertificate9.wl (read-only original untouched), with K taken
   from the command line and ONE change under test: the initial strategy fed to
   RunFromSeed is lifted from the K-1 certificate instead of seedA/seedB/random.
   Everything downstream (CanonicalPhi, SolveJoint, Improve, Stage-2 exact
   projection, Stage-3 exact verification) is semantically identical. *)

args = Rest[$ScriptCommandLine];
If[Length[args] < 4, Print["need args: K map prevCert gtCert [baselines]"]; Exit[1]];
K = ToExpression[args[[1]]];
mapType = args[[2]];
prevCertFile = args[[3]];
gtCertFile = args[[4]];
runBaselines = Length[args] >= 5 && args[[5]] === "baselines";

SetDirectory[DirectoryName[$InputFileName]];
MAXPOLICYROUNDS = 20;
RATIONALTOL = 10^-9;

(* ---- load K-1 certificate (its Strategy + Gamma), then the K ground truth ---- *)
Get[prevCertFile];
prevCert = EpsilonCertificate9; Clear[EpsilonCertificate9];
Get[gtCertFile];
gtCert = EpsilonCertificate9; Clear[EpsilonCertificate9];
If[prevCert["k"] =!= K - 1, Print["prevCert k mismatch"]; Exit[1]];
If[gtCert["k"] =!= K, Print["gtCert k mismatch"]; Exit[1]];
prevStrat = prevCert["Strategy"];
prevGamma = prevCert["Gamma"];
Print["[WARM] K = ", K, ", map = ", mapType, ", prev Gamma_", K - 1, " = ", N[prevGamma, 8]];

(* ---- STAGE 0 (verbatim, K parametric) ---- *)
nodes = StringJoin /@ Tuples[{"c", "t"}, K];
edges = Select[Tuples[nodes, 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];
iu = 1; iv = 2; ia = 3; ib = 4; ip = 5;
jv = 1; jb = 2; jx = 3; jp = 4;
edgeLetter[e_] := StringTake[e[[1]], -1];
dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
        ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "c", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];
Tc = dpTransfer["c"]; Tt = dpTransfer["t"];

(* ---- STAGE 1 machinery (verbatim) ---- *)
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
      {rA, rB} = If[b === "c", {iu, iv}, {iv, iu}];
      {
       Qs[w][[ia, ia]] + Qs[x][[rA, rA]] + If[b === "t", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ib, ib]] + Rs[w][[jb, jb]] + Qs[x][[rB, rB]] + If[b === "c", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ia, ip]] + Qs[x][[rA, ip]] + If[b === "t", Rs[x][[jv, jp]], 0] == 1,
       Qs[w][[ib, ip]] + Rs[w][[jb, jp]] + Qs[x][[rB, ip]] + If[b === "c", Rs[x][[jv, jp]], 0] == 1
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
        T = If[edgeLetter[e] === "c", Tc, Tt];
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
         T = If[edgeLetter[e] === "c", Tc, Tt];
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
      T = If[edgeLetter[e] === "c", Tc, Tt];
      valid = validSigs[T, s];
      vals = (T[[s, #]] + (phiVar[# - 1, x] /. canonSol)) & /@ valid;
      {s, e} -> valid[[First@Ordering[-vals, 1]]]],
    {e, edges}, {s, 1, 3}]]];

(* instrumented copy of RunFromSeed (only Print/AbsoluteTiming added) *)
RunFromSeed[strategy0_, label_] := Module[
  {strat = strategy0, canonSol, jointSol, gam = $Failed, newStrat, round = 0,
   converged = False, tLP, tSDP, tImp, tTot = 0.},
  Print["  seed ", label, ":"];
  While[round < MAXPOLICYROUNDS,
    round++;
    {tLP, canonSol} = AbsoluteTiming[CanonicalPhi[strat]];
    If[canonSol === $Failed,
      Print["    round ", round, ": canonical-Phi LP FAILED"]; Break[]];
    {tSDP, jointSol} = AbsoluteTiming[Check[SolveJoint[strat], $Failed]];
    If[jointSol === $Failed || Head[jointSol] =!= List,
      Print["    round ", round, ": joint SDP FAILED or returned unevaluated"]; Break[]];
    gam = gammaVar /. jointSol;
    {tImp, newStrat} = AbsoluteTiming[Improve[strat, canonSol]];
    tTot += tLP + tSDP + tImp;
    Print["    round ", round, ": Gamma = ", N[gam, 12], "  [LP ",
      NumberForm[tLP, {6, 2}], " s, SDP ", NumberForm[tSDP, {6, 2}], " s, Improve ",
      NumberForm[tImp, {6, 3}], " s]"];
    If[newStrat === strat,
      Print["    converged at round ", round, "  (seed total ",
        NumberForm[tTot, {8, 2}], " s)"];
      converged = True; Break[]];
    If[round == MAXPOLICYROUNDS,
      Print["    WARNING: MAXPOLICYROUNDS reached without convergence"]; Break[]];
    strat = newStrat];
  {label, jointSol, strat, gam, round, converged, tTot}];

(* ---- THE LEVER: lift the K-1 strategy to a K seed ---- *)
projNode[w_] := If[mapType === "suffix", StringTake[w, -(K - 1)], StringTake[w, K - 1]];
fallbackCount = 0; missingCount = 0;
warmSeed = Association[Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], T, valid, key, sig},
      T = If[edgeLetter[e] === "c", Tc, Tt];
      valid = validSigs[T, s];
      key = ToString[s - 1] <> "|" <> projNode[w] <> ">" <> projNode[x];
      sig = Lookup[prevStrat, key, $Failed];
      If[sig === $Failed, missingCount++];
      If[! (IntegerQ[sig] && MemberQ[valid, sig]),
        If[IntegerQ[sig], fallbackCount++];
        sig = First[valid]];
      {s, e} -> sig],
    {e, edges}, {s, 1, 3}]]];
Print["[WARM] lifted seed built: ", Length[warmSeed], " decisions; missing keys = ",
  missingCount, ", invalid-sig fallbacks = ", fallbackCount];

(* how far is the lifted seed from the K ground-truth optimal strategy? *)
gtStrat = gtCert["Strategy"];
gtAsSeed = Association[Table[
    {s, e} -> gtStrat[ToString[s - 1] <> "|" <> e[[1]] <> ">" <> e[[2]]],
    {e, edges}, {s, 1, 3}]];
disagree = Count[Table[warmSeed[{s, e}] =!= gtAsSeed[{s, e}], {e, edges}, {s, 1, 3}] // Flatten, True];
Print["[WARM] lifted seed vs ground-truth optimal strategy: ", disagree, " / ",
  3*Length[edges], " decisions differ"];

(* ---- run Stage 1 from the warm seed ---- *)
warmResult = RunFromSeed[warmSeed, "warm-" <> mapType];
{finalLabel, finalSol, finalStrategy, finalGamma, roundsUsed, finalConverged, warmTime} = warmResult;
Print["[WARM] warm-", mapType, ": rounds = ", roundsUsed, ", converged = ", finalConverged,
  ", Gamma = ", N[finalGamma, 12], ", Stage1 time = ", NumberForm[warmTime, {8, 2}], " s"];

(* monotonicity guard the warm start enables: Gamma_K <= Gamma_{K-1} *)
Print["[WARM] monotonicity check Gamma_K <= Gamma_{K-1}: ",
  N[finalGamma, 10], " <= ", N[prevGamma, 10], " -> ",
  TrueQ[finalGamma <= prevGamma + 10^-6]];

(* does the converged strategy match the ground-truth one exactly? *)
stratMatch = finalStrategy === gtAsSeed;
Print["[WARM] converged strategy identical to ground-truth strategy: ", stratMatch];

(* ---- optional cold baselines on the same machine/load ---- *)
If[runBaselines,
  seedA = Association[Table[
     Module[{T = If[edgeLetter[e] === "c", Tc, Tt], valid},
       valid = validSigs[T, s];
       {s, e} -> If[MemberQ[valid, s], s, First[valid]]],
     {e, edges}, {s, 1, 3}]];
  seedB = Association[Table[
     Module[{T = If[edgeLetter[e] === "c", Tc, Tt], valid}, valid = validSigs[T, s];
       {s, e} -> First[valid]],
     {e, edges}, {s, 1, 3}]];
  resA = RunFromSeed[seedA, "A (sig=s) cold"];
  resB = RunFromSeed[seedB, "B (first valid) cold"];
  Print["[BASE] seedA: rounds = ", resA[[5]], ", Gamma = ", N[resA[[4]], 12],
    ", time = ", NumberForm[resA[[7]], {8, 2}], " s"];
  Print["[BASE] seedB: rounds = ", resB[[5]], ", Gamma = ", N[resB[[4]], 12],
    ", time = ", NumberForm[resB[[7]], {8, 2}], " s"];
  Print["[BASE] warm vs A Gamma agreement: ",
    Abs[N[resA[[4]] - finalGamma]] < 10^-4];
  (* PROPOSED PRODUCTION CONFIG: seed set {warm, seedA}, selection logic
     verbatim from GenerateEpsilonCertificate9.wl (converged-preferred, then
     smallest Gamma) + the new monotonicity rejection gate. The winner's
     finalSol feeds Stage 2 below, exactly as in the original pipeline. *)
  seedResults = {warmResult, resA};
  monotoneOK = Select[seedResults, TrueQ[#[[4]] <= prevGamma + 10^-6] &];
  If[Length[monotoneOK] < Length[seedResults],
    Print["[SELECT] monotonicity gate rejected ",
      Length[seedResults] - Length[monotoneOK], " seed(s) with Gamma > Gamma_{K-1}"]];
  convergedSeedResults = Select[monotoneOK, #[[6]] &];
  candidateSeedResults = If[Length[convergedSeedResults] > 0, convergedSeedResults, monotoneOK];
  bestIdx = First@Ordering[N[#[[4]], 10] & /@ candidateSeedResults, 1];
  {finalLabel, finalSol, finalStrategy, finalGamma, roundsUsed, finalConverged, tX} =
    candidateSeedResults[[bestIdx]];
  Print["[SELECT] production-config winner: ", finalLabel, ", Gamma = ",
    N[finalGamma, 12], " -- its finalSol feeds Stage 2/3 below"];
];

If[! finalConverged, Print["[WARM] NOT converged -- skipping Stage 2/3"]; Exit[0]];

(* ---- STAGE 2 (verbatim) ---- *)
rat[x_] := Rationalize[x, RATIONALTOL];
x0 = Map[rat, qrVars /. finalSol];
eqLHS = (#[[1]] - #[[2]]) & /@ Join[nodeCons, edgeCons];
{bvec, Amat} = CoefficientArrays[eqLHS, qrVars];
bvec = -bvec;
residual = Amat.x0 - bvec;
lambda = LinearSolve[Amat.Transpose[Amat], residual];
xExact = x0 - Transpose[Amat].lambda;
Print["[WARM] Stage 2 exact projection residual (should be {0}): ", Amat.xExact - bvec // Union];
exactRule = Thread[qrVars -> xExact];
QsExact = Association[Table[w -> (Qs[w] /. exactRule), {w, nodes}]];
RsExact = Association[Table[w -> (Rs[w] /. exactRule), {w, nodes}]];

(* ---- STAGE 3 (verbatim) ---- *)
nodeEqOK = AllTrue[nodes, RsExact[#][[jx, jx]] == 1 && RsExact[#][[jx, jp]] == 1 &&
     QsExact[#][[iv, ia]] == 0 && QsExact[#][[iu, ib]] == 0 &&
     QsExact[#][[iv, ib]] + RsExact[#][[jv, jb]] == 0 &];
edgeEqOK = AllTrue[edges, Module[{w = #[[1]], x = #[[2]], b, rA, rB},
      b = StringTake[w, -1]; {rA, rB} = If[b === "c", {iu, iv}, {iv, iu}];
      QsExact[w][[ia, ia]] + QsExact[x][[rA, rA]] + If[b === "t", RsExact[x][[jv, jv]], 0] == 1 &&
       QsExact[w][[ib, ib]] + RsExact[w][[jb, jb]] + QsExact[x][[rB, rB]] +
         If[b === "c", RsExact[x][[jv, jv]], 0] == 1 &&
       QsExact[w][[ia, ip]] + QsExact[x][[rA, ip]] + If[b === "t", RsExact[x][[jv, jp]], 0] == 1 &&
       QsExact[w][[ib, ip]] + RsExact[w][[jb, jp]] + QsExact[x][[rB, ip]] +
         If[b === "c", RsExact[x][[jv, jp]], 0] == 1] &];
psdOK = AllTrue[nodes, PositiveSemidefiniteMatrixQ[QsExact[#]] && PositiveSemidefiniteMatrixQ[RsExact[#]] &];
Print["[WARM] Stage 3: nodeEqOK = ", nodeEqOK, ", edgeEqOK = ", edgeEqOK, ", psdOK = ", psdOK];

PsiExact = Association[Table[w -> rat[psiVar[w] /. finalSol], {w, nodes}]];
PhiExact = Association[Flatten[Table[
    (ToString[ph] <> "|" <> w) -> rat[phiVar[ph, w] /. finalSol],
    {ph, 0, 2}, {w, nodes}]]];
StrategyExact = Association[Table[
    (ToString[s - 1] <> "|" <> e[[1]] <> ">" <> e[[2]]) -> finalStrategy[{s, e}],
    {e, edges}, {s, 1, 3}]];
posSigma9[e_] := Module[{w = e[[1]], x = e[[2]], T, r},
   T = If[edgeLetter[e] === "c", Tc, Tt];
   r = Min[Table[Module[{sig = StrategyExact[ToString[s - 1] <> "|" <> w <> ">" <> x]},
       T[[s, sig]] + PhiExact[ToString[sig - 1] <> "|" <> x] - PhiExact[ToString[s - 1] <> "|" <> w]],
      {s, 3}]];
   (QsExact[x][[ip, ip]] + RsExact[x][[jp, jp]]) - r + PsiExact[x] - PsiExact[w]];
GammaExact = Max[posSigma9 /@ edges];
targetGamma = rat[gammaVar /. finalSol];
GAMMADRIFTTOL = 10^-4;
pointwiseOK = AllTrue[edges, posSigma9[#] <= targetGamma + GAMMADRIFTTOL &];
gammaCrossCheckOK = Abs[N[GammaExact - targetGamma, 10]] < GAMMADRIFTTOL;
Print["[WARM] Stage 3: pointwiseOK = ", pointwiseOK, ", gammaCrossCheckOK = ", gammaCrossCheckOK];
Print["[WARM] GammaExact = ", GammaExact, " = ", N[GammaExact, 12]];

(* ---- byte-identity vs ground truth ---- *)
gtGamma = gtCert["Gamma"];
byteIdentical = ToString[GammaExact, InputForm] === ToString[gtGamma, InputForm];
Print["[WARM] Gamma byte-identical to ground truth: ", byteIdentical];
If[! byteIdentical,
  Print["[WARM]   warm GammaExact = ", ToString[GammaExact, InputForm]];
  Print["[WARM]   gt   Gamma      = ", ToString[gtGamma, InputForm]];
  Print["[WARM]   numeric diff = ", N[GammaExact - gtGamma, 10]]];
(* full-certificate byte identity (Q, R, Psi, Phi, Strategy) *)
fullMatch = And[
   QsExact === gtCert["Q"], RsExact === gtCert["R"],
   PsiExact === gtCert["Psi"], PhiExact === gtCert["Phi"],
   StrategyExact === gtCert["Strategy"]];
Print["[WARM] FULL certificate (Q/R/Psi/Phi/Strategy) identical to ground truth: ", fullMatch];
Print["[WARM] SUMMARY  K=", K, " map=", mapType, " rounds=", roundsUsed,
  " stage1s=", NumberForm[warmTime, {8, 2}], " gammaByteIdentical=", byteIdentical,
  " fullCertIdentical=", fullMatch];
