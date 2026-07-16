(* lever_sdp-decompose_hybrid.wl -- HYBRID pipeline byte-identity test:
   per policy round, the cheap REDUCED (red2) formulation is solved ONLY for
   the progress/diagnostic Gamma readout; when a seed's strategy converges (or
   the round cap is hit), the ORIGINAL fully-coupled SolveJoint is run ONCE on
   the final mutually consistent strategy, and THAT solution/Gamma is what the
   seed returns. The strategy trajectory depends only on CanonicalPhi+Improve
   (untouched), so seed comparison, seed selection, and Stages 2/3 consume
   bit-identical data to the unmodified generator: the certificate must be
   BYTE-IDENTICAL to the testK ground truth. Verifies exactly that.
   Usage: wolframscript -file lever_sdp-decompose_hybrid.wl <K>   (K in 3..6) *)

SetDirectory[DirectoryName[$InputFileName]];
K = ToExpression[$ScriptCommandLine[[-1]]];
MAXPOLICYROUNDS = 20;
RATIONALTOL = 10^-9;
Print["[HYBRID] K = ", K, " (reduced solves for round readouts, ORIGINAL solve once per seed at convergence)"];

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

Qs = Association[Table[w -> Table[Subscript[q, w, Min[i, j], Max[i, j]], {i, 5}, {j, 5}], {w, nodes}]];
Rs = Association[Table[w -> Table[Subscript[rblk, w, Min[i, j], Max[i, j]], {i, 4}, {j, 4}], {w, nodes}]];
dvar[w_] := Qs[w][[ip, ip]] + Rs[w][[jp, jp]];
phiVar[ph_, w_] := Subscript[phi, ph, w];
psiVar[w_] := Subscript[psiv, w];
rVar[e_] := Subscript[rvar, e];
qv[w_, i_, j_] := Subscript[q, w, Min[i, j], Max[i, j]];
rv[w_, i_, j_] := Subscript[rblk, w, Min[i, j], Max[i, j]];
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

(* ---- reduced-formulation machinery (see lever_sdp-decompose_bench.wl) ---- *)
SSlist[x_] := Module[{b = StringTake[x, {K - 1}], rA, rB},
   {rA, rB} = If[b === "d", {iu, iv}, {iv, iu}];
   {qv[x, rA, rA] + If[b === "t", rv[x, jv, jv], 0],
    qv[x, rB, rB] + If[b === "d", rv[x, jv, jv], 0],
    qv[x, rA, ip] + If[b === "t", rv[x, jv, jp], 0],
    qv[x, rB, ip] + If[b === "d", rv[x, jv, jp], 0]}];
elimRules = Flatten[{
    Table[{rv[w, jx, jx] -> 1, rv[w, jx, jp] -> 1, qv[w, iv, ia] -> 0,
      qv[w, iu, ib] -> 0, qv[w, iv, ib] -> -rv[w, jv, jb]}, {w, nodes}],
    Table[Module[{x1 = StringDrop[w, 1] <> "d", S},
      S = SSlist[x1];
      {qv[w, ia, ia] -> 1 - S[[1]],
       qv[w, ib, ib] -> 1 - S[[2]] - rv[w, jb, jb],
       qv[w, ia, ip] -> 1 - S[[3]],
       qv[w, ib, ip] -> 1 - S[[4]] - rv[w, jb, jp]}], {w, nodes}],
    Table[Module[{x1 = StringDrop[x2, -1] <> "d", S1, b, rA, rB},
      S1 = SSlist[x1];
      b = StringTake[x2, {K - 1}];
      {rA, rB} = If[b === "d", {iu, iv}, {iv, iu}];
      {qv[x2, rA, rA] -> S1[[1]] - If[b === "t", rv[x2, jv, jv], 0],
       qv[x2, rB, rB] -> S1[[2]] - If[b === "d", rv[x2, jv, jv], 0],
       qv[x2, rA, ip] -> S1[[3]] - If[b === "t", rv[x2, jv, jp], 0],
       qv[x2, rB, ip] -> S1[[4]] - If[b === "d", rv[x2, jv, jp], 0]}],
     {x2, Select[nodes, StringTake[#, -1] === "t" &]}]}];
elimVars = First /@ elimRules;
elimRHS = Last /@ elimRules;
disp = Dispatch[elimRules];
residChk = Union[Expand[If[# === True, 0, Subtract @@ #]] & /@ (Join[nodeCons, edgeCons] /. disp)];
If[residChk =!= {0}, Print["[E2E] ELIMINATION INVALID -- abort"]; Quit[]];
freeQr = Complement[qrVars, elimVars];
psdConsRed = Join[
   Table[VectorGreaterEqual[{(Qs[w] /. disp) - PSDMARGIN*IdentityMatrix[5], 0},
     {"SemidefiniteCone", 5}], {w, nodes}],
   Table[VectorGreaterEqual[{(Rs[w] /. disp) - PSDMARGIN*IdentityMatrix[4], 0},
     {"SemidefiniteCone", 4}], {w, nodes}]];
potVarsNoRvar = Join[
   Flatten[Table[phiVar[ph, w], {ph, 0, 2}, {w, nodes}]],
   Table[psiVar[w], {w, nodes}],
   {gammaVar}];
varsRed2 = Join[freeQr, potVarsNoRvar];

(* reduced solve: used ONLY for the per-round diagnostic Gamma readout (only
   gammaVar is ever read from it), so no reconstruction of eliminated vars *)
SolveJointReduced[strategy_] := Module[{potConsR2},
   potConsR2 = Flatten[Table[
      Module[{w = e[[1]], x = e[[2]], sig, T},
        T = If[edgeLetter[e] === "d", Td, Tt];
        sig = strategy[{s, e}];
        dvar[x] + psiVar[x] - psiVar[w] -
          (T[[s, sig]] + phiVar[sig - 1, x] - phiVar[s - 1, w]) <= gammaVar],
      {e, edges}, {s, 1, 3}]];
   SemidefiniteOptimization[gammaVar, Join[psdConsRed, potConsR2], varsRed2]];

(* ORIGINAL fully-coupled SolveJoint, verbatim from GenerateEpsilonCertificate9.wl:
   run once per seed, on the seed's final mutually consistent strategy *)
SolveJointFull[strategy_] := Module[{potCons},
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
  {strat = strategy0, prevStrat = None, solveStrat = None, canonSol, redSol,
   jointSol = $Failed, gam = $Failed, newStrat, round = 0, converged = False},
  Print["  seed ", label, ":"];
  While[round < MAXPOLICYROUNDS,
    round++;
    canonSol = CanonicalPhi[strat];
    If[canonSol === $Failed,
      Print["    round ", round, ": canonical-Phi LP FAILED"];
      solveStrat = prevStrat;  (* original returns the PREVIOUS round's jointSol here *)
      Break[]];
    redSol = Check[SolveJointReduced[strat], $Failed];
    If[redSol === $Failed || Head[redSol] =!= List,
      Print["    round ", round, ": reduced readout SDP FAILED"]; Break[]];
    Print["    round ", round, ": Gamma (reduced readout) = ", N[gammaVar /. redSol, 8]];
    newStrat = Improve[strat, canonSol];
    If[newStrat === strat,
      Print["    converged at round ", round];
      converged = True; solveStrat = strat; Break[]];
    If[round == MAXPOLICYROUNDS,
      Print["    WARNING: MAXPOLICYROUNDS reached without convergence -- ",
        "final ORIGINAL solve uses the last MUTUALLY CONSISTENT strategy."];
      solveStrat = strat; Break[]];
    prevStrat = strat; strat = newStrat];
  If[solveStrat =!= None,
    jointSol = Check[SolveJointFull[solveStrat], $Failed];
    If[jointSol === $Failed || Head[jointSol] =!= List,
      Print["    final ORIGINAL joint SDP FAILED"]; jointSol = $Failed; gam = $Failed,
      gam = gammaVar /. jointSol;
      Print["    final ORIGINAL joint solve: Gamma = ", N[gam, 8]]]];
  {label, jointSol, strat, gam, round, converged}];

Print["Stage 1 (HYBRID: reduced readouts + one original solve per seed), cap ",
  MAXPOLICYROUNDS, " rounds per seed..."];
t1 = AbsoluteTime[];
seedResults = {
   RunFromSeed[seedA, "A (sig=s)"],
   RunFromSeed[seedB, "B (first valid)"],
   RunFromSeed[randomSeed[1], "random-1"],
   RunFromSeed[randomSeed[2], "random-2"]};
Print["[E2E] Stage 1 total: ", NumberForm[AbsoluteTime[] - t1, {10, 2}], " s"];

convergedSeedResults = Select[seedResults, #[[6]] &];
candidateSeedResults = If[Length[convergedSeedResults] > 0, convergedSeedResults, seedResults];
bestIdx = First@Ordering[N[#[[4]], 10] & /@ candidateSeedResults, 1];
{finalLabel, finalSol, finalStrategy, finalGamma, roundsUsed, finalConverged} = candidateSeedResults[[bestIdx]];
Print["Stage 1 result: best seed = ", finalLabel, ", Gamma (numeric) = ", N[finalGamma, 10],
  ", converged = ", finalConverged];
Print["  All seeds: ", {#[[1]], N[#[[4]], 10], #[[6]]} & /@ seedResults];

(* ---- Stage 2 verbatim ---- *)
rat[x_] := Rationalize[x, RATIONALTOL];
x0 = Map[rat, qrVars /. finalSol];
eqLHS = (#[[1]] - #[[2]]) & /@ Join[nodeCons, edgeCons];
{bvec, Amat} = CoefficientArrays[eqLHS, qrVars];
bvec = -bvec;
residual = Amat.x0 - bvec;
Print["Stage 2: naive-rounded residual norm = ", N[Norm[residual], 6]];
lambda = LinearSolve[Amat.Transpose[Amat], residual];
xExact = x0 - Transpose[Amat].lambda;
Print["Stage 2: exact projection residual (should be {0}): ", Amat.xExact - bvec // Union];
exactRule = Thread[qrVars -> xExact];
QsExact = Association[Table[w -> (Qs[w] /. exactRule), {w, nodes}]];
RsExact = Association[Table[w -> (Rs[w] /. exactRule), {w, nodes}]];

(* ---- Stage 3 verbatim ---- *)
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
psdOK = AllTrue[nodes, PositiveSemidefiniteMatrixQ[QsExact[#]] && PositiveSemidefiniteMatrixQ[RsExact[#]] &];
Print["Stage 3: nodeEqOK = ", nodeEqOK, ", edgeEqOK = ", edgeEqOK, ", psdOK = ", psdOK];

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
Print["Stage 3: exact Gamma_", K, " = ", GammaExact, " = ", N[GammaExact, 10]];
targetGamma = rat[gammaVar /. finalSol];
GAMMADRIFTTOL = 10^-4;
pointwiseOK = AllTrue[edges, posSigma9[#] <= targetGamma + GAMMADRIFTTOL &];
gammaDrift = N[GammaExact - targetGamma, 10];
gammaCrossCheckOK = Abs[gammaDrift] < GAMMADRIFTTOL;
Print["Stage 3: pointwiseOK = ", pointwiseOK, ", gammaCrossCheckOK = ", gammaCrossCheckOK,
  " (drift ", gammaDrift, ")"];
Print["[E2E] ALL STAGE-3 GATES: ",
  nodeEqOK && edgeEqOK && psdOK && pointwiseOK && gammaCrossCheckOK && finalConverged];

If[MemberQ[{3, 4, 5, 6}, K],
  Module[{gtFile = If[K == 6, "profile_cert_K6.wl",
      "../EpsilonCertificate_testK" <> ToString[K] <> "_output.wl"], myGamma = GammaExact},
    If[FileExistsQ[gtFile],
      Get[gtFile];
      Print["[E2E] GROUND TRUTH byte-identity vs ", gtFile, " : ",
        myGamma === EpsilonCertificate9["Gamma"],
        "  (mine = ", N[myGamma, 12], ", ground truth = ", N[EpsilonCertificate9["Gamma"], 12], ")"];
      Print["[E2E] exact difference mine - groundtruth = ",
        N[myGamma - EpsilonCertificate9["Gamma"], 6]],
      Print["[E2E] ground-truth file not found"]]]];
Print["[E2E] DONE"];
