(* GenerateEpsilonCertificate_opt.wl -- OPTIMIZED generator for the windowed
   transfer-SDP epsilon-certificate (Gamma_K upper bound on the pentagon-mesh
   gluing-word density gap), targeting K = 11 on Memory8x64-class hardware.

   This is a PROTOTYPE combining the three measured-and-adopted levers on top of
   the read-only original GenerateEpsilonCertificate9.wl (whose Stage-2 exact
   projection and Stage-3 exact verification are copied VERBATIM -- the
   certificate's validity rests entirely on those unchanged exact checks):

   LEVER 1 (seed reduction, K-gated): for K <= 3 the ORIGINAL 4-seed Stage 1
     is kept unchanged (measured: the committed K=3 ground truth descends from
     random-2's float, so dropping the random seeds provably breaks
     byte-identity at K=3). For K >= 4 the two random-restart seeds are
     dropped (measured at K=4/5/6: they only ever converge to spurious HIGHER
     fixed points or burn the 20-round cap; byte-identity preserved). No seed
     -level parallelism anywhere (measured: subkernel CSDP solves are
     float-divergent and 2 concurrent K=11 solves would OOM Memory8x64).

   LEVER 2 (warm start): for K >= 4, if an exact (K-m)-certificate is
     available, its Strategy is lifted node-wise via the SUFFIX projection
     (letter-preserving graph homomorphism) into a warm seed which replaces
     seedB; seedA is retained as the independent cross-check (measured
     REQUIRED for byte-identity: warm alone converges to an alternate fixed
     point at K=3->4). A certified monotonicity gate Gamma_K <= Gamma_{K-m}
     + 10^-5 discards spurious converged candidates before the original
     selection logic (justification: any exact K-m certificate suffix-lifts
     to a feasible K certificate with identical Gamma, so Gamma_K <=
     Gamma_{K-1} <= ... exactly). If no previous certificate is found the
     seed set falls back to {seedA, seedB} (lever-1 configuration, measured
     byte-identical at K=4/5/6).

   LEVER 3 (hybrid SDP reduction): the exact presolve elimination of all
     13N nodeCons/edgeCons equality rows (rank 11N) + Fourier-Motzkin
     elimination of the 2N rvar variables gives a reduced solve (31N+1 ->
     18N+1 vars, 21N -> 6N scalar rows, ~2.3x faster, ~7.5x less
     solve-attributable memory). The reduced form is used ONLY for per-round
     diagnostic Gamma readouts; the certificate-feeding solution is ALWAYS
     one ORIGINAL fully-coupled SolveJoint run per seed on its final
     mutually consistent strategy (measured: reduced-as-final lands ~1e-8
     away on the degenerate optimal face and breaks byte-identity; the
     hybrid is measured byte-identical at K=3/4/5/6). The exact
     substitution-identity gate (every original equality must reduce to
     0 == 0 in exact arithmetic) is a hard abort at every K.
     Additional provably-neutral tweak vs. the measured hybrid harness: the
     reduced readout is SKIPPED on the round where Improve[] reports
     convergence (the readout is print-only -- nothing from it is ever used
     -- and the immediately following original full solve reports the
     load-bearing Gamma), saving one solve per seed.

   EMERGENCY MEMORY FALLBACK (default OFF): FINALSOLVEMODE = "reduced" makes
     the final per-seed solve use the reduced form + exact reconstruction of
     the eliminated variables. The resulting certificate still passes every
     exact Stage-2/3 check (measured at K=3..6 in the e2e lever run) but is
     NOT byte-identical to the original pipeline (~1e-8 on the same optimal
     face) -- use only if the full-form final solve cannot fit in RAM.

   Usage:
     wolframscript -file GenerateEpsilonCertificate_opt.wl [K] [prevCert|auto|none] [gtCert|none] [full|reduced]
       K        : window size (default: the K = ... parameter below)
       prevCert : path to an exact lower-window certificate for the warm
                  start ("auto" searches standard locations; "none" disables
                  the warm start -> {seedA, seedB} fallback)
       gtCert   : optional ground-truth certificate; if given, an exact
                  rational byte-identity comparison is printed at the end.

   Output: EpsilonCertificate_opt_K<K>.wl in this directory (originals are
   never touched), exported ONLY if every exact Stage-3 gate passes. *)

SetDirectory[DirectoryName[$InputFileName]];

(* ------------------------------------------------------------------------- *)
(* PARAMETERS (identical to the original where they exist there) *)
(* ------------------------------------------------------------------------- *)

K = 5;                    (* window size; overridden by 1st command-line arg *)
MAXPOLICYROUNDS = 20;      (* strategy-iteration cap, verbatim original *)
RATIONALTOL = 10^-9;       (* Rationalize tolerance, verbatim original *)
PSDMARGIN = 10^-6;         (* Stage-1 spectral buffer, verbatim original *)
MONOTOL = 10^-5;           (* monotonicity-gate tolerance (lever 2): absorbs the
                              ~4e-6 solver offset seen in round-1 gammaVar values
                              while rejecting all observed spurious fixed points
                              (0.5/0.377/0.29/0.16, each >> Gamma_{K-1}) *)
FINALSOLVEMODE = "full";   (* "full" (byte-identical, default) | "reduced"
                              (memory-fallback, valid but not byte-comparable) *)
PREVCERTSPEC = Automatic;  (* Automatic | None | path, overridden by 2nd arg *)
GTCERTFILE = None;         (* overridden by 3rd arg *)

args = {};
If[Length[args] >= 1, K = ToExpression[args[[1]]]];
If[Length[args] >= 2,
  PREVCERTSPEC = Switch[args[[2]], "auto", Automatic, "none", None, _, args[[2]]]];
If[Length[args] >= 3 && args[[3]] =!= "none", GTCERTFILE = args[[3]]];
If[Length[args] >= 4 && args[[4]] === "reduced", FINALSOLVEMODE = "reduced"];
If[! (IntegerQ[K] && K >= 2), Print["bad K"]; Exit[1]];

tPipelineStart = AbsoluteTime[];

(* ------------------------------------------------------------------------- *)
(* certificate loader: the committed certificate files bind different symbol
   names (EpsilonCertificate9 / EpsilonCertificate8 / EpsilonCertificate / ...);
   load into a local value regardless, and clear the globals afterwards *)
(* ------------------------------------------------------------------------- *)

certSymbolNames = {"EpsilonCertificate9", "EpsilonCertificate8",
   "EpsilonCertificate7", "EpsilonCertificate"};
LoadCert[file_] := Module[{cert = None},
   If[! FileExistsQ[file], Return[None]];
   Clear /@ certSymbolNames;
   Quiet[Check[Get[file], Return[None]]];
   Do[Module[{v = ToExpression[nm]},
      If[AssociationQ[v] && KeyExistsQ[v, "k"] && KeyExistsQ[v, "Strategy"],
        cert = v]],
     {nm, certSymbolNames}];
   Clear /@ certSymbolNames;
   cert];

prevCert = None;
If[K >= 4 && PREVCERTSPEC =!= None,
  If[StringQ[PREVCERTSPEC],
    prevCert = LoadCert[PREVCERTSPEC];
    If[prevCert === None, Print["[WARM] could not load prev cert ", PREVCERTSPEC]];
    If[prevCert =!= None && ! (IntegerQ[prevCert["k"]] && prevCert["k"] < K),
      Print["[WARM] prev cert k = ", prevCert["k"], " not < K -- ignoring"];
      prevCert = None],
    (* Automatic: search m = K-1, K-2, K-3 in standard locations *)
    Do[If[prevCert === None,
       Module[{cand = {
           "EpsilonCertificate_opt_K" <> ToString[m] <> ".wl",
           "baseline_cert_K" <> ToString[m] <> ".wl",
           "profile_cert_K" <> ToString[m] <> ".wl",
           "../EpsilonCertificate_testK" <> ToString[m] <> "_output.wl",
           "../EpsilonCertificate" <> ToString[m] <> ".wl",
           If[m == 7, "../EpsilonCertificate7_regenerated.wl", Nothing],
           If[m == 7, "../EpsilonCertificate.wl", Nothing]}},
         Do[If[prevCert === None,
            Module[{c = LoadCert[f]},
              If[c =!= None && c["k"] === m, prevCert = c;
                Print["[WARM] auto-loaded previous certificate: ", f, " (k = ", m, ")"]]]],
           {f, cand}]]],
      {m, K - 1, Max[2, K - 3], -1}]]];
useWarm = K >= 4 && prevCert =!= None;
prevGamma = If[useWarm, prevCert["Gamma"], None];
kPrev = If[useWarm, prevCert["k"], None];
If[K >= 4 && ! useWarm,
  Print["[WARM] no previous certificate available -- falling back to the ",
    "{seedA, seedB} lever-1 seed set."]];

gtCert = If[GTCERTFILE =!= None, LoadCert[GTCERTFILE], None];
If[GTCERTFILE =!= None && gtCert === None,
  Print["[GT] WARNING: could not load ground-truth file ", GTCERTFILE]];

(* ------------------------------------------------------------------------- *)
(* STAGE 0: de Bruijn-K graph (verbatim original) *)
(* ------------------------------------------------------------------------- *)

nodes = StringJoin /@ Tuples[{"c", "t"}, K];
edges = Select[Tuples[nodes, 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];
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
(* STAGE 1 machinery (constraint construction verbatim original) *)
(* ------------------------------------------------------------------------- *)

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

(* ORIGINAL fully-coupled joint solve, verbatim -- this (and ONLY this, in the
   default FINALSOLVEMODE) produces the certificate-feeding finalSol *)
SolveJointFull[strategy_] := Module[{potCons},
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

(* ---- LEVER 3: exact presolve elimination (reduced formulation) ---- *)
(* every edge equality is W_i(source) + S_i(target) == 1 with the S-side keyed
   only by the target's (K-1)-th letter; 5 nodeCons entries per node eliminate
   locally; the c-successor's S-entries express each node's W-entries; the
   t-sibling's S-entries alias the c-sibling's. rank(equalities) = 11N. *)
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
elimRHS = Last /@ elimRules;
disp = Dispatch[elimRules];
(* HARD GATE: the elimination must reduce EVERY original equality to 0 == 0 in
   exact arithmetic -- structural, O(N), abort otherwise *)
residChk = Union[Expand[If[# === True, 0, Subtract @@ #]] & /@ (Join[nodeCons, edgeCons] /. disp)];
If[residChk =!= {0},
  Print["[LEVER3] ELIMINATION IDENTITY GATE FAILED at K = ", K, " -- ABORT ",
    "(reduced formulation would not be an exact reparametrization)"]; Exit[1]];
Print["[LEVER3] exact substitution-identity gate passed (all ",
  Length[nodeCons] + Length[edgeCons], " equalities reduce to 0 == 0)"];
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

(* reduced solve: per-round DIAGNOSTIC readouts only (rvar eliminated by
   Fourier-Motzkin: sigma(e) - min-of-3-bounds <= gamma, 3 rows per edge) *)
SolveJointReduced[strategy_] := Module[{potConsR2},
   potConsR2 = Flatten[Table[
      Module[{w = e[[1]], x = e[[2]], sig, T},
        T = If[edgeLetter[e] === "c", Tc, Tt];
        sig = strategy[{s, e}];
        dvar[x] + psiVar[x] - psiVar[w] -
          (T[[s, sig]] + phiVar[sig - 1, x] - phiVar[s - 1, w]) <= gammaVar],
      {e, edges}, {s, 1, 3}]];
   SemidefiniteOptimization[gammaVar, Join[psdConsRed, potConsR2], varsRed2]];

(* final per-seed solve: original full form by default; the "reduced" fallback
   reconstructs the eliminated Q/R entries exactly (their RHS is linear in the
   FREE variables only -- the elimination is depth-1 by construction) so the
   verbatim Stage 2/3 below run unchanged on it. NOT byte-comparable. *)
FinalSolve[strategy_] := If[FINALSOLVEMODE === "full",
   SolveJointFull[strategy],
   Module[{redSol = SolveJointReduced[strategy]},
     If[Head[redSol] =!= List, redSol,
       Join[redSol, Thread[elimVars -> (elimRHS /. Dispatch[redSol])]]]]];

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

(* ---- LEVER 2: warm seed lifted from the previous exact certificate via the
   SUFFIX projection (letter-preserving; generalizes to any kPrev < K, so a
   double lift K-2 -> K works if the K-1 certificate does not exist yet) ---- *)
If[useWarm,
  Module[{missingCount = 0, fallbackCount = 0, prevStrat = prevCert["Strategy"]},
    projNode[w_] := StringTake[w, -kPrev];
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
    Print["[WARM] lifted seed from k = ", kPrev, " certificate (suffix map): ",
      Length[warmSeed], " decisions; missing keys = ", missingCount,
      ", invalid-sig fallbacks = ", fallbackCount]]];

(* ---- HYBRID RunFromSeed (lever 3): cheap reduced readouts per round, ONE
   original-form solve per seed on its final mutually consistent strategy.
   The strategy trajectory depends only on CanonicalPhi + Improve (verbatim
   original), so the converged strategy -- and hence the final solve and
   everything downstream -- is bit-identical to the unmodified generator.
   The readout is skipped on the converged round (it is print-only). ---- *)
