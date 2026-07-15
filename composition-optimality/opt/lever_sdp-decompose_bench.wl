(* lever_sdp-decompose_bench.wl -- LEVER 3 measurement scaffold (scratch, opt/ only).
   Benchmarks the per-round joint SDP of GenerateEpsilonCertificate9.wl at a FIXED
   converged strategy (seedA, driven by LP-only policy iteration -- the only signal
   Improve[] actually consumes) under several formulations:

     full  : the original fully-coupled SemidefiniteOptimization call, verbatim
             constraint set psdCons+nodeCons+edgeCons+potCons over allVars.
     red   : all 13N nodeCons/edgeCons equalities eliminated EXACTLY by local,
             chain-free variable substitution (11N of 25N Q/R entries removed;
             the equality system has rank 11N -- the 4 shared-successor equations
             per sibling pair are dependent), PSD blocks become affine in the
             free vars. Identical feasible set, identical optimum by construction.
     red2  : red + eliminating the 2N rvar[e] variables (rvar has only 3 upper
             bounds and 1 lower bound per edge -> Fourier-Motzkin exact, 3 ineqs
             replace 4). Identical optimum by construction.
     scsfull / scsred2 : same as full/red2 but Method -> "SCS" probe.

   Prints: formulation sizes, substitution-identity check, solve wall-clock
   (twice, for variance), gamma at machine precision (InputForm), kernel
   MaxMemoryUsed, and OS PeakWorkingSet64 of this kernel process.

   Usage: wolframscript -file lever_sdp-decompose_bench.wl <K> <variant>
*)

K = ToExpression[$ScriptCommandLine[[-2]]];
variant = $ScriptCommandLine[[-1]];
Print["[BENCH] K = ", K, "  variant = ", variant, "  kernel pid = ", $ProcessID];

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

(* warm up the optimization libraries so load time is excluded from timings *)
Quiet[SemidefiniteOptimization[wux,
   {VectorGreaterEqual[{{{wux, 0}, {0, 1}}, 0}, {"SemidefiniteCone", 2}]}, {wux}]];

(* LP-only policy iteration from seedA (Improve consumes ONLY CanonicalPhi) *)
strat = seedA; lpRounds = 0;
While[lpRounds < 25,
  lpRounds++;
  canon = CanonicalPhi[strat];
  If[canon === $Failed, Print["[BENCH] LP FAILED"]; Quit[]];
  newStrat = Improve[strat, canon];
  If[newStrat === strat, Break[]];
  strat = newStrat];
Print["[BENCH] LP-only policy iteration (seedA): fixed point after ", lpRounds, " LP round(s)"];

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

(* ---------- exact local elimination of ALL nodeCons+edgeCons equalities ------- *)
(* per node x define the successor-side interface sums S_i[x] (b = the shared last
   letter of x's two de Bruijn predecessors = StringTake[x, {K-1}]):
     S1 = Q[x][rA,rA] + (b=t) R[x][jv,jv]      S2 = Q[x][rB,rB] + (b=c) R[x][jv,jv]
     S3 = Q[x][rA,ip] + (b=t) R[x][jv,jp]      S4 = Q[x][rB,ip] + (b=c) R[x][jv,jp]
   Every edge equation w->x reads W_i[w] + S_i[x] == 1 with W_i depending only on w
   and b depending only on w's last letter, hence identical for both out-edges of w
   -> eliminate the 4 W-side entries of every w against its c-successor, and the 4
   S-side head entries of every t-ending node against its c-sibling (the remaining
   4 equations per sibling family are then dependent). Node equalities are local. *)
SSlist[x_] := Module[{b = StringTake[x, {K - 1}], rA, rB},
   {rA, rB} = If[b === "c", {iu, iv}, {iv, iu}];
   {qv[x, rA, rA] + If[b === "t", rv[x, jv, jv], 0],
    qv[x, rB, rB] + If[b === "c", rv[x, jv, jv], 0],
    qv[x, rA, ip] + If[b === "t", rv[x, jv, jp], 0],
    qv[x, rB, ip] + If[b === "c", rv[x, jv, jp], 0]}];

elimRules = Flatten[{
    Table[{rv[w, jx, jx] -> 1, rv[w, jx, jp] -> 1, qv[w, iv, ia] -> 0,
      qv[w, iu, ib] -> 0, qv[w, iv, ib] -> -rv[w, jv, jb]}, {w, nodes}],
    Table[Module[{x1 = StringDrop[w, 1] <> "c", S},
      S = SSlist[x1];
      {qv[w, ia, ia] -> 1 - S[[1]],
       qv[w, ib, ib] -> 1 - S[[2]] - rv[w, jb, jb],
       qv[w, ia, ip] -> 1 - S[[3]],
       qv[w, ib, ip] -> 1 - S[[4]] - rv[w, jb, jp]}], {w, nodes}],
    Table[Module[{x1 = StringDrop[x2, -1] <> "c", S1, b, rA, rB},
      S1 = SSlist[x1];
      b = StringTake[x2, {K - 1}];
      {rA, rB} = If[b === "c", {iu, iv}, {iv, iu}];
      {qv[x2, rA, rA] -> S1[[1]] - If[b === "t", rv[x2, jv, jv], 0],
       qv[x2, rB, rB] -> S1[[2]] - If[b === "c", rv[x2, jv, jv], 0],
       qv[x2, rA, ip] -> S1[[3]] - If[b === "t", rv[x2, jv, jp], 0],
       qv[x2, rB, ip] -> S1[[4]] - If[b === "c", rv[x2, jv, jp], 0]}],
     {x2, Select[nodes, StringTake[#, -1] === "t" &]}]}];

elimVars = First /@ elimRules;
Print["[BENCH] elimination: ", Length[elimVars], " variables eliminated (expect 11N = ",
  11 Length[nodes], "), duplicates = ", Length[elimVars] - Length[DeleteDuplicates[elimVars]]];
disp = Dispatch[elimRules];

(* rule RHSs must not contain eliminated variables (single-pass validity) *)
rhsVars = DeleteDuplicates[Cases[Last /@ elimRules, Subscript[__], Infinity]];
Print["[BENCH] single-pass valid (no eliminated var on any RHS): ",
  Intersection[rhsVars, elimVars] === {}];

(* every original equality must reduce to an identity under the substitution *)
resid = Union[Expand[If[# === True, 0, Subtract @@ #]] & /@ (Join[nodeCons, edgeCons] /. disp)];
Print["[BENCH] equality-substitution residuals (must be {0}): ", resid];
If[resid =!= {0}, Print["[BENCH] ELIMINATION INVALID -- abort"]; Quit[]];

freeQr = Complement[qrVars, elimVars];
psdConsRed = Join[
   Table[VectorGreaterEqual[{(Qs[w] /. disp) - PSDMARGIN*IdentityMatrix[5], 0},
     {"SemidefiniteCone", 5}], {w, nodes}],
   Table[VectorGreaterEqual[{(Rs[w] /. disp) - PSDMARGIN*IdentityMatrix[4], 0},
     {"SemidefiniteCone", 4}], {w, nodes}]];

(* red2: Fourier-Motzkin-eliminate rvar[e] (3 upper bounds, 1 lower bound) *)
potConsNoRvar[strategy_] := Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], sig, T},
      T = If[edgeLetter[e] === "c", Tc, Tt];
      sig = strategy[{s, e}];
      dvar[x] + psiVar[x] - psiVar[w] -
        (T[[s, sig]] + phiVar[sig - 1, x] - phiVar[s - 1, w]) <= gammaVar],
    {e, edges}, {s, 1, 3}]];
potVarsNoRvar = Join[
   Flatten[Table[phiVar[ph, w], {ph, 0, 2}, {w, nodes}]],
   Table[psiVar[w], {w, nodes}],
   {gammaVar}];

method = If[StringStartsQ[variant, "scs"], "SCS", Automatic];
Which[
  StringMatchQ[variant, "full" | "scsfull"],
  cons = Join[psdCons, nodeCons, edgeCons, buildPotCons[strat]]; vars = allVars,
  StringMatchQ[variant, "red"],
  cons = Join[psdConsRed, buildPotCons[strat]]; vars = Join[freeQr, potVars],
  StringMatchQ[variant, "red2" | "scsred2"],
  cons = Join[psdConsRed, potConsNoRvar[strat]]; vars = Join[freeQr, potVarsNoRvar],
  True, Print["[BENCH] unknown variant"]; Quit[]];

nScalarRows = Count[cons, _LessEqual | _GreaterEqual | _Equal, {1}];
Print["[BENCH] formulation: |vars| = ", Length[vars], "  scalar (in)equality rows = ",
  nScalarRows, "  PSD cones = ", Count[cons, _VectorGreaterEqual, {1}]];

memBefore = MaxMemoryUsed[];
{t1, sol} = AbsoluteTiming[Quiet[Check[
    SemidefiniteOptimization[gammaVar, cons, vars, Method -> method], $Failed]]];
If[sol === $Failed || Head[sol] =!= List,
  Print["[BENCH] SOLVE FAILED (variant=", variant, ", Method=", method, ")"]; Quit[]];
gam = gammaVar /. sol;
Print["[BENCH] solve #1: ", NumberForm[t1, {10, 3}], " s   gamma = ", InputForm[gam]];
Print["[BENCH] kernel MaxMemoryUsed = ", N[MaxMemoryUsed[]/2^20, 6],
  " MB (before solve: ", N[memBefore/2^20, 6], " MB)"];
peak = Quiet[Check[RunProcess[{"powershell", "-NoProfile", "-Command",
      "(Get-Process -Id " <> ToString[$ProcessID] <> ").PeakWorkingSet64"}]["StandardOutput"], ""]];
Print["[BENCH] OS PeakWorkingSet64 = ",
  Quiet[Check[N[ToExpression[StringTrim[peak]]/2^20, 6], "n/a"]], " MB"];

{t2, sol2} = AbsoluteTiming[Quiet[Check[
    SemidefiniteOptimization[gammaVar, cons, vars, Method -> method], $Failed]]];
Print["[BENCH] solve #2: ", NumberForm[t2, {10, 3}], " s   gamma = ",
  If[Head[sol2] === List, InputForm[gammaVar /. sol2], "FAILED"]];
Print["[BENCH] DONE  K=", K, " variant=", variant];
