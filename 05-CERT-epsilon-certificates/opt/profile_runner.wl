(* profile_runner.wl -- INSTRUMENTED PROFILING COPY of
   GenerateEpsilonCertificate9.wl (which is byte-identical to the testK3/4/5
   generators and to GenerateEpsilonCertificate10_cloud.wl except for the K
   line / cloud tail). PURPOSE: measure where wall-clock and memory go, per
   stage / per seed / per policy round / per joint-SDP solve, at small K.

   THE ALGORITHM IS UNCHANGED -- only these deltas vs the original:
     1. K is read from the command line ($ScriptCommandLine last argument).
     2. AbsoluteTiming / MemoryInUse / MaxMemoryUsed instrumentation prints
        (all prefixed "[PROFILE]") around: constraint construction, each
        seed, each policy round, the CanonicalPhi LP (build vs solve), the
        joint SDP (potCons build vs SemidefiniteOptimization call), Improve,
        Stage-2 rationalize / CoefficientArrays / LinearSolve / projection,
        and each Stage-3 exact verification check.
     3. The potCons construction inside SolveJoint is factored into
        buildPotCons[strategy] (same expressions, same order) so the build
        can be timed separately and reused by the optional method probe.
     4. Stage 4 exports to opt/profile_cert_K<K>.wl (NEVER touches any
        original file), then byte-compares GammaExact against the committed
        EpsilonCertificate_testK<K>_output.wl ground truth when K is 3/4/5.
     5. Optional method probe (K <= 5 only): re-times the final joint SDP
        with explicit Method -> "CSDP" / "DSDP" for solver comparison.

   Run:  wolframscript -file profile_runner.wl <K>
*)

SetDirectory[DirectoryName[$InputFileName]];

(* ------------------------------------------------------------------------- *)
(* PROFILING HARNESS *)
(* ------------------------------------------------------------------------- *)

$T0 = AbsoluteTime[];
mb[x_] := N[x/2^20, 6];
stamp[label_] := Print["[PROFILE] +", NumberForm[AbsoluteTime[] - $T0, {10, 2}],
   " s  MemoryInUse=", mb[MemoryInUse[]], " MB  MaxMemoryUsed=", mb[MaxMemoryUsed[]],
   " MB  :: ", label];
SetAttributes[tim, HoldRest];
tim[label_, expr_] := Module[{r},
   r = AbsoluteTiming[expr];
   Print["[PROFILE] ", label, " : ", NumberForm[r[[1]], {10, 3}], " s"];
   r[[2]]];

Print["[PROFILE] Wolfram $Version = ", $Version];
Print["[PROFILE] $ScriptCommandLine = ", $ScriptCommandLine];

(* ------------------------------------------------------------------------- *)
(* PARAMETERS (K from command line; everything else identical to original) *)
(* ------------------------------------------------------------------------- *)

K = Module[{a},
   a = If[Length[$ScriptCommandLine] >= 2, Quiet[ToExpression[Last[$ScriptCommandLine]]], $Failed];
   If[IntegerQ[a] && 3 <= a <= 8, a, 4]];
Print["[PROFILE] K = ", K];
MAXPOLICYROUNDS = 20;
RATIONALTOL = 10^-9;

(* ------------------------------------------------------------------------- *)
(* STAGE 0: de Bruijn-K graph *)
(* ------------------------------------------------------------------------- *)

stamp["STAGE 0 start"];
{tGraph, Null} = AbsoluteTiming[
   nodes = StringJoin /@ Tuples[{"c", "t"}, K];
   edges = Select[Tuples[nodes, 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];];
Print["[PROFILE] stage0 graph build : ", NumberForm[tGraph, {10, 3}], " s"];
Print["de Bruijn-", K, ": ", Length[nodes], " nodes, ", Length[edges], " edges"];

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

(* ------------------------------------------------------------------------- *)
(* STAGE 1 setup: variables + static constraints (timed) *)
(* ------------------------------------------------------------------------- *)

{tVars, Null} = AbsoluteTiming[
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
   allVars = Join[qrVars, potVars];];
Print["[PROFILE] stage1 symbolic variable build : ", NumberForm[tVars, {10, 3}], " s"];

{tCons, Null} = AbsoluteTiming[
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
     Table[VectorGreaterEqual[{Rs[w] - PSDMARGIN*IdentityMatrix[4], 0}, {"SemidefiniteCone", 4}], {w, nodes}]];];
Print["[PROFILE] stage1 static constraint build (nodeCons+edgeCons+psdCons) : ",
  NumberForm[tCons, {10, 3}], " s"];
Print["[PROFILE] FORMULATION: |qrVars|=", Length[qrVars], "  |potVars|=", Length[potVars],
  "  |allVars|=", Length[allVars], "  |nodeCons eqs|=", Length[nodeCons],
  "  |edgeCons eqs|=", Length[edgeCons], "  |psd blocks|=", Length[psdCons],
  " (", Length[nodes], "x 5x5 Q + ", Length[nodes], "x 4x4 R)"];
stamp["STAGE 1 setup done"];

validSigs[T_, s_] := Select[Range[3], T[[s, #]] > -Infinity &];

refNode = First[nodes];
CanonicalPhi[strategy_] := Module[{potCons, tVar, tB, tS, sol},
   {tB, potCons} = AbsoluteTiming[Flatten[Table[
       Module[{w = e[[1]], x = e[[2]], sig, T},
         T = If[edgeLetter[e] === "c", Tc, Tt];
         sig = strategy[{s, e}];
         tVar <= T[[s, sig]] + phiVar[sig - 1, x] - phiVar[s - 1, w]],
       {e, edges}, {s, 1, 3}]]];
   {tS, sol} = AbsoluteTiming[Quiet[Check[
      LinearOptimization[-tVar, Join[potCons, {phiVar[0, refNode] == 0}],
        Append[Flatten[Table[phiVar[ph, w], {ph, 0, 2}, {w, nodes}]], tVar]],
      $Failed]]];
   Print["[PROFILE]       CanonicalPhi: build ", NumberForm[tB, {10, 3}],
     " s, LinearOptimization ", NumberForm[tS, {10, 3}], " s (",
     Length[potCons], " ineqs)"];
   sol];

(* potCons construction factored out of SolveJoint UNCHANGED (same exprs,
   same order) so the build is separately timable and reusable below *)
buildPotCons[strategy_] := Join[
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

SolveJoint[strategy_] := Module[{potCons, tB, tS, sol},
   {tB, potCons} = AbsoluteTiming[buildPotCons[strategy]];
   {tS, sol} = AbsoluteTiming[
     SemidefiniteOptimization[gammaVar, Join[psdCons, nodeCons, edgeCons, potCons], allVars]];
   Print["[PROFILE]       SolveJoint: potCons build ", NumberForm[tB, {10, 3}],
     " s (", Length[potCons], " ineqs), SemidefiniteOptimization ",
     NumberForm[tS, {10, 3}], " s   MemoryInUse=", mb[MemoryInUse[]],
     " MB  MaxMemoryUsed=", mb[MaxMemoryUsed[]], " MB"];
   sol];

Improve[strategy_, canonSol_] := Association[Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], T, valid, vals},
      T = If[edgeLetter[e] === "c", Tc, Tt];
      valid = validSigs[T, s];
      vals = (T[[s, #]] + (phiVar[# - 1, x] /. canonSol)) & /@ valid;
      {s, e} -> valid[[First@Ordering[-vals, 1]]]],
    {e, edges}, {s, 1, 3}]]];

seedA = Association[Table[
   Module[{T = If[edgeLetter[e] === "c", Tc, Tt], valid},
     valid = validSigs[T, s];
     {s, e} -> If[MemberQ[valid, s], s, First[valid]]],
   {e, edges}, {s, 1, 3}]];
seedB = Association[Table[
   Module[{T = If[edgeLetter[e] === "c", Tc, Tt], valid}, valid = validSigs[T, s];
     {s, e} -> First[valid]],
   {e, edges}, {s, 1, 3}]];
randomSeed[seedNum_] := (SeedRandom[seedNum];
   Association[Table[
     Module[{T = If[edgeLetter[e] === "c", Tc, Tt], valid}, valid = validSigs[T, s];
       {s, e} -> RandomChoice[valid]],
     {e, edges}, {s, 1, 3}]]);

RunFromSeed[strategy0_, label_] := Module[
  {strat = strategy0, canonSol, jointSol, gam = $Failed, newStrat, round = 0,
   converged = False, tSeed0 = AbsoluteTime[], tt},
  Print["  seed ", label, ":"];
  While[round < MAXPOLICYROUNDS,
    round++;
    Print["[PROFILE]     seed ", label, " ROUND ", round, " begin"];
    tt = AbsoluteTiming[CanonicalPhi[strat]];
    canonSol = tt[[2]];
    Print["[PROFILE]     seed ", label, " round ", round, " CanonicalPhi total: ",
      NumberForm[tt[[1]], {10, 3}], " s"];
    If[canonSol === $Failed,
      Print["    round ", round, ": canonical-Phi LP FAILED"]; Break[]];
    tt = AbsoluteTiming[Check[SolveJoint[strat], $Failed]];
    jointSol = tt[[2]];
    Print["[PROFILE]     seed ", label, " round ", round, " SolveJoint total: ",
      NumberForm[tt[[1]], {10, 3}], " s"];
    If[jointSol === $Failed || Head[jointSol] =!= List,
      Print["    round ", round, ": joint SDP FAILED or returned unevaluated"]; Break[]];
    gam = gammaVar /. jointSol;
    Print["    round ", round, ": Gamma = ", N[gam, 8]];
    tt = AbsoluteTiming[Improve[strat, canonSol]];
    newStrat = tt[[2]];
    Print["[PROFILE]     seed ", label, " round ", round, " Improve: ",
      NumberForm[tt[[1]], {10, 3}], " s"];
    If[newStrat === strat,
      Print["    converged at round ", round];
      converged = True; Break[]];
    If[round == MAXPOLICYROUNDS,
      Print["    WARNING: MAXPOLICYROUNDS (", MAXPOLICYROUNDS, ") reached without ",
        "convergence -- returning the last MUTUALLY CONSISTENT (strategy,jointSol,Gamma), ",
        "NOT the one-step-ahead improved strategy. This Gamma may not be optimal; increase ",
        "MAXPOLICYROUNDS or investigate possible oscillation before trusting it."];
      Break[]];
    strat = newStrat];
  Print["[PROFILE]   SEED ", label, " TOTAL: ",
    NumberForm[AbsoluteTime[] - tSeed0, {10, 3}], " s over ", round, " round(s)"];
  {label, jointSol, strat, gam, round, converged}];

Print["Stage 1: strategy iteration (decoupled canonical-Phi fix), cap ",
  MAXPOLICYROUNDS, " rounds per seed..."];
stamp["STAGE 1 iteration start"];
{tStage1, seedResults} = AbsoluteTiming[{
    RunFromSeed[seedA, "A (sig=s)"],
    RunFromSeed[seedB, "B (first valid)"],
    RunFromSeed[randomSeed[1], "random-1"],
    RunFromSeed[randomSeed[2], "random-2"]}];
Print["[PROFILE] STAGE 1 TOTAL (all 4 seeds): ", NumberForm[tStage1, {10, 3}], " s"];
stamp["STAGE 1 done"];

convergedSeedResults = Select[seedResults, #[[6]] &];
candidateSeedResults = If[Length[convergedSeedResults] > 0, convergedSeedResults, seedResults];
If[Length[convergedSeedResults] == 0,
  Print["  WARNING: NONE of the ", Length[seedResults], " seeds converged within ",
    "MAXPOLICYROUNDS -- falling back to the best NON-CONVERGED result, which is NOT ",
    "trustworthy as-is."]];
bestIdx = First@Ordering[N[#[[4]], 10] & /@ candidateSeedResults, 1];
{finalLabel, finalSol, finalStrategy, finalGamma, roundsUsed, finalConverged} = candidateSeedResults[[bestIdx]];

Print["Stage 1 result: best seed = ", finalLabel, ", Gamma_", K, " (numeric) = ",
  N[finalGamma, 10], " after ", roundsUsed, " strategy-iteration round(s), converged = ",
  finalConverged, "."];
Print["  All seeds' results: ",
  {#[[1]], N[#[[4]], 10], "converged->" <> ToString[#[[6]]]} & /@ seedResults];

seedAResult = seedResults[[1]]; seedBResult = seedResults[[2]];
seedAGamma = If[TrueQ[seedAResult[[6]]], N[seedAResult[[4]], 10], Missing["NotConverged"]];
seedBGamma = If[TrueQ[seedBResult[[6]]], N[seedBResult[[4]], 10], Missing["NotConverged"]];
seedAgreementOK = NumericQ[seedAGamma] && NumericQ[seedBGamma] && Abs[seedAGamma - seedBGamma] < 10^-4;
Print["  Cross-seed agreement check (A vs B): A = ", seedAGamma, ", B = ", seedBGamma,
  ", agree = ", seedAgreementOK];

(* ------------------------------------------------------------------------- *)
(* STAGE 2: numeric -> exact rational, equality-preserving repair (timed) *)
(* ------------------------------------------------------------------------- *)

stamp["STAGE 2 start"];
rat[x_] := Rationalize[x, RATIONALTOL];

x0 = tim["stage2 rationalize x0", Map[rat, qrVars /. finalSol]];
eqLHS = tim["stage2 eqLHS assembly", (#[[1]] - #[[2]]) & /@ Join[nodeCons, edgeCons]];
{tCA, {bvec, Amat}} = AbsoluteTiming[CoefficientArrays[eqLHS, qrVars]];
Print["[PROFILE] stage2 CoefficientArrays : ", NumberForm[tCA, {10, 3}], " s;  Amat dims = ",
  Dimensions[Amat], ",  nnz = ", Length[Amat["NonzeroValues"]], ",  density = ",
  N[Length[Amat["NonzeroValues"]]/Times @@ Dimensions[Amat], 4]];
bvec = -bvec;
residual = tim["stage2 residual Amat.x0-bvec (exact)", Amat.x0 - bvec];
Print["Stage 2: ", Length[qrVars], " Q/R variables, ", Length[eqLHS],
  " linear equalities; naive-rounded residual norm = ", N[Norm[residual], 6]];
gram = tim["stage2 Gram Amat.Transpose[Amat] (exact)", Amat.Transpose[Amat]];
lambda = tim["stage2 LinearSolve[A.A^T, residual] (exact rational)", LinearSolve[gram, residual]];
xExact = tim["stage2 projection x0 - A^T.lambda (exact)", x0 - Transpose[Amat].lambda];
Print["Stage 2: exact projection residual (should be exactly 0): ",
  tim["stage2 residual re-check", Amat.xExact - bvec // Union]];

exactRule = tim["stage2 Thread exactRule", Thread[qrVars -> xExact]];
{tSub, Null} = AbsoluteTiming[
   QsExact = Association[Table[w -> (Qs[w] /. exactRule), {w, nodes}]];
   RsExact = Association[Table[w -> (Rs[w] /. exactRule), {w, nodes}]];];
Print["[PROFILE] stage2 substitute exactRule into Q/R blocks : ", NumberForm[tSub, {10, 3}], " s"];
stamp["STAGE 2 done"];

(* ------------------------------------------------------------------------- *)
(* STAGE 3: exact re-verification (timed per check) *)
(* ------------------------------------------------------------------------- *)

stamp["STAGE 3 start"];
nodeEqOK = tim["stage3 nodeEqOK exact check",
   AllTrue[nodes, RsExact[#][[jx, jx]] == 1 && RsExact[#][[jx, jp]] == 1 &&
      QsExact[#][[iv, ia]] == 0 && QsExact[#][[iu, ib]] == 0 &&
      QsExact[#][[iv, ib]] + RsExact[#][[jv, jb]] == 0 &]];

edgeEqOK = tim["stage3 edgeEqOK exact check",
   AllTrue[edges, Module[{w = #[[1]], x = #[[2]], b, rA, rB},
       b = StringTake[w, -1]; {rA, rB} = If[b === "c", {iu, iv}, {iv, iu}];
       QsExact[w][[ia, ia]] + QsExact[x][[rA, rA]] + If[b === "t", RsExact[x][[jv, jv]], 0] == 1 &&
        QsExact[w][[ib, ib]] + RsExact[w][[jb, jb]] + QsExact[x][[rB, rB]] +
          If[b === "c", RsExact[x][[jv, jv]], 0] == 1 &&
        QsExact[w][[ia, ip]] + QsExact[x][[rA, ip]] + If[b === "t", RsExact[x][[jv, jp]], 0] == 1 &&
        QsExact[w][[ib, ip]] + RsExact[w][[jb, jp]] + QsExact[x][[rB, ip]] +
          If[b === "c", RsExact[x][[jv, jp]], 0] == 1] &]];

psdOK = tim["stage3 psdOK exact PositiveSemidefiniteMatrixQ (all 2*2^K blocks)",
   AllTrue[nodes, PositiveSemidefiniteMatrixQ[QsExact[#]] && PositiveSemidefiniteMatrixQ[RsExact[#]] &]];

Print["Stage 3: nodeEqOK = ", nodeEqOK, ", edgeEqOK = ", edgeEqOK, ", psdOK = ", psdOK];

{tPsiPhi, Null} = AbsoluteTiming[
   PsiExact = Association[Table[w -> rat[psiVar[w] /. finalSol], {w, nodes}]];
   PhiExact = Association[Flatten[Table[
       (ToString[ph] <> "|" <> w) -> rat[phiVar[ph, w] /. finalSol],
       {ph, 0, 2}, {w, nodes}]]];
   StrategyExact = Association[Table[
       (ToString[s - 1] <> "|" <> e[[1]] <> ">" <> e[[2]]) -> finalStrategy[{s, e}],
       {e, edges}, {s, 1, 3}]];];
Print["[PROFILE] stage3 Psi/Phi/Strategy exactification : ", NumberForm[tPsiPhi, {10, 3}], " s"];

posSigma9[e_] := Module[{w = e[[1]], x = e[[2]], T, r},
   T = If[edgeLetter[e] === "c", Tc, Tt];
   r = Min[Table[Module[{sig = StrategyExact[ToString[s - 1] <> "|" <> w <> ">" <> x]},
       T[[s, sig]] + PhiExact[ToString[sig - 1] <> "|" <> x] - PhiExact[ToString[s - 1] <> "|" <> w]],
      {s, 3}]];
   (QsExact[x][[ip, ip]] + RsExact[x][[jp, jp]]) - r + PsiExact[x] - PsiExact[w]];

GammaExact = tim["stage3 GammaExact = Max[posSigma9 /@ edges] (exact)", Max[posSigma9 /@ edges]];
Print["Stage 3: exact Gamma_", K, " (pointwise max over all edges) = ", GammaExact,
  " = ", N[GammaExact, 10]];

targetGamma = rat[gammaVar /. finalSol];
GAMMADRIFTTOL = 10^-4;
pointwiseOK = tim["stage3 pointwise sigma(e)<=target check (exact, all edges)",
   AllTrue[edges, posSigma9[#] <= targetGamma + GAMMADRIFTTOL &]];
Print["Stage 3: pointwise sigma(e) <= Gamma for all edges: ", pointwiseOK];

gammaDrift = N[GammaExact - targetGamma, 10];
gammaCrossCheckOK = Abs[gammaDrift] < GAMMADRIFTTOL;
Print["Stage 3: GammaExact vs Stage-1 targetGamma drift = ", gammaDrift,
  ", within tolerance (", GAMMADRIFTTOL, "): ", gammaCrossCheckOK];
stamp["STAGE 3 done"];

(* ------------------------------------------------------------------------- *)
(* STAGE 4: package + export (INTO opt/ ONLY), then ground-truth compare *)
(* ------------------------------------------------------------------------- *)

allPass = nodeEqOK && edgeEqOK && psdOK && pointwiseOK && gammaCrossCheckOK && finalConverged;
If[allPass,
  EpsilonCertificate9 = <|
     "k" -> K, "Gamma" -> GammaExact, "Nodes" -> nodes,
     "Q" -> QsExact, "R" -> RsExact, "Psi" -> PsiExact,
     "Phi" -> PhiExact, "Strategy" -> StrategyExact|>;
  {tExp, Null} = AbsoluteTiming[
    Export["profile_cert_K" <> ToString[K] <> ".wl",
      "(* PROFILING run output, k = " <> ToString[K] <> " -- from opt/profile_runner.wl *)\n" <>
       "EpsilonCertificate9 = " <> ToString[EpsilonCertificate9, InputForm] <> ";\n",
      "Text"];];
  Print["[PROFILE] stage4 Export : ", NumberForm[tExp, {10, 3}], " s"];
  Print["Wrote profile_cert_K", K, ".wl -- Gamma_", K, " = ", GammaExact, " = ", N[GammaExact, 10]],
  Print["NOT written: checks failed. nodeEqOK=", nodeEqOK, ", edgeEqOK=", edgeEqOK,
    ", psdOK=", psdOK, ", pointwiseOK=", pointwiseOK, ", gammaCrossCheckOK=",
    gammaCrossCheckOK, ", finalConverged=", finalConverged]];

(* ground-truth byte-identity check vs the committed testK outputs *)
If[MemberQ[{3, 4, 5}, K],
  Module[{gtFile = "../EpsilonCertificate_testK" <> ToString[K] <> "_output.wl", myGamma = GammaExact},
    If[FileExistsQ[gtFile],
      Get[gtFile];  (* re-binds Global`EpsilonCertificate9 to the ground truth *)
      Print["[PROFILE] GROUND TRUTH check vs ", gtFile, " : Gamma byte-identical = ",
        myGamma === EpsilonCertificate9["Gamma"], "  (mine = ", myGamma,
        ", ground truth = ", EpsilonCertificate9["Gamma"], ")"],
      Print["[PROFILE] ground-truth file not found: ", gtFile]]]];

(* ------------------------------------------------------------------------- *)
(* OPTIONAL METHOD PROBE (K <= 5 only): re-time the FINAL joint SDP with
   explicit Method choices -- measurement only, does not affect the pipeline *)
(* ------------------------------------------------------------------------- *)

If[K <= 5,
  Module[{potConsF = buildPotCons[finalStrategy], consAll},
    consAll = Join[psdCons, nodeCons, edgeCons, potConsF];
    Do[Module[{res},
       res = Quiet[Check[
          AbsoluteTiming[SemidefiniteOptimization[gammaVar, consAll, allVars, Method -> m]],
          $Failed]];
       If[res === $Failed || Head[res[[2]]] =!= List,
         Print["[PROFILE] method probe ", m, " : FAILED/unavailable"],
         Print["[PROFILE] method probe ", m, " : ", NumberForm[res[[1]], {10, 3}],
           " s, gamma = ", N[gammaVar /. res[[2]], 10]]]],
      {m, {"CSDP", "DSDP"}}]]];

stamp["ALL DONE"];
Print["[PROFILE] FINAL MaxMemoryUsed = ", mb[MaxMemoryUsed[]], " MB"];
