(* Generator SKELETON for the window-k=9 windowed transfer-SDP epsilon-certificate
   (would-be EpsilonCertificate9.wl), following the SAME construction as
   EpsilonCertificate.wl (k=7) and EpsilonCertificate8.wl (k=8): per de-Bruijn-k
   node w, a PSD block Q[w] (5x5, on the glue quad {u,v,A,B,apex}) and a PSD block
   R[w] (4x4, on {v,B,X,apex}); closure potentials Psi[w]; DP potentials Phi[phase,w]
   (phase in {0,1,2} = the interface-DP states {(0,0),(1,0),(0,1)}); and a Strategy
   choosing, for each source phase and each de-Bruijn edge, which target phase the
   potential-method telescoping "aims at". Gamma = max over all 2*2^k edges of
   sigma(e) = d(x) - r(e) + Psi(x) - Psi(w), where d(x) = Q[x][[5,5]] + R[x][[4,4]]
   and r(e) is the mean-payoff-game value derived from Strategy/Phi.

   STATUS / HOW THIS FILE WAS PRODUCED (read before running):
   No generator script for EpsilonCertificate.wl or EpsilonCertificate8.wl exists
   anywhere in this repository or its git history -- both were committed as
   complete, already-solved 13-15 line data files in a single commit each
   (e8b03ed, abc4c3e), with no accompanying construction code. This script is a
   from-scratch reconstruction of a plausible construction pipeline.

     (a) The CONSTRAINT STRUCTURE below (node/edge equalities, 5x5/4x4 PSD shapes,
         dpTransfer) carries over VERBATIM from k=7/8 to any k -- it is exactly
         the same code CaseStudies.wl already uses generically via CE["k"]/
         CE["Nodes"] to verify k=7 and k=8. No new derivation needed here.

     (b) Raw problem size is tractable at k=9 (512 nodes, 1024 edges): the joint
         block-diagonal SDP was timed on synthetic same-shape problems at
         nb = 8..192 blocks (0.28s .. 23.9s), extrapolating to single-digit to
         tens of minutes PER SOLVE at nb=512 -- not intractable by raw compute.

     (c) BUG FOUND AND FIXED (12 July 2026): the original Stage 1 (see git
         history for the broken version) used ONE joint SemidefiniteOptimization
         solve per round to get BOTH the achieved Gamma AND the Phi values fed
         into policy improvement. This converged to Gamma ~ 0.5 regardless of
         two already-applied fixes (guarding against the -Infinity dpTransfer
         entries Td[[2,2]]/Tt[[2,3]], and avoiding a degenerate constant seed).
         Diagnosis, confirmed empirically (not guessed): running the SAME
         algorithm from 9 different seed strategies at k=3 produced THREE
         DISTINCT fixed points (0.5, 0.377, 0.293) -- impossible under correct
         policy iteration for a mean-payoff game, where every improving
         sequence must reach the SAME global optimum. Root cause: Phi is
         entangled with the Q/R choice in the joint solve (they interact only
         through the final Gamma constraint and the shared objective), so the
         Phi that comes back is merely SOME allocation that is optimal for
         THIS SPECIFIC joint problem, not the CANONICAL mean-payoff-game bias
         function for the fixed strategy that policy improvement theory
         requires -- using it for Improve[]'s one-step lookahead is unsound and
         explains the multiple spurious fixed points.

         FIX: decouple. CanonicalPhi[strategy] solves a SEPARATE, cheap LP --
         maximize the worst-case (minimum) mean-payoff value achievable by ANY
         choice of Phi for the FIXED strategy, using ONLY the potCons game
         inequalities (no Q/R, no Psi at all). Improve[] now uses THIS
         canonical Phi (not the joint solve's entangled one) to pick the next
         strategy. The joint SDP is still run once per round, using the SAME
         (now-improved) strategy, purely to report the actually-achieved Gamma
         (Q/R and Psi legitimately need to jointly optimize against whatever
         r(e) profile the strategy achieves -- that part of the original
         design was correct; only the signal driving policy improvement was
         wrong).

         VALIDATED against the documented sequence (QUANTUM_CONTEXTUALITY.md)
         at k=3, k=4, AND k=5, from TWO different deterministic seeds each
         time, both converging to the exact same values in every case:
           k=3: 0.12499997861440139  (documented Gamma_3 = 0.125)
           k=4: 0.10196412702492699  (documented Gamma_4 ~ 0.1020)
           k=5: 0.0952971530959493   (documented Gamma_5 ~ 0.0953)
         Some RANDOM seeds still land on spurious local fixed points (0.5,
         0.29, 0.16, etc. were observed) -- the two DETERMINISTIC seeds below
         (seedA: sig=s where valid; seedB: first valid sig) were the only ones
         tested that converged correctly every time, so Stage 1 below tries
         both (and a couple of random restarts as an extra safety net) and
         keeps the best (smallest) converged Gamma.

     (d) The final exact-rational RATIONALIZE + integer-preserving REPAIR (Stage 2)
         and the exact PSD/edge-equality re-verification (Stage 3) are directly-
         portable adaptations of CaseStudies.wl's own epsilonCertificateCheck /
         posSigma / posCheck logic (so a produced EpsilonCertificate9 association
         is a drop-in for that EXISTING, already k-agnostic verification code --
         no changes needed there). These stages are mechanical given a good
         numeric solution from Stage 1, and were not changed by the Stage-1 fix.

   Run with:  wolframscript -file GenerateEpsilonCertificate9.wl -print all
   (each seed's convergence took 2-4 rounds at k=3/4/5; at k=9 each round's
   joint SDP solve is the expensive part -- budget minutes to hours per round
   per the timing estimate in (b), and consider lowering K below to smoke-test
   first if re-running after any further change).
*)

SetDirectory[DirectoryName[$InputFileName]];

(* ------------------------------------------------------------------------- *)
(* PARAMETERS *)
(* ------------------------------------------------------------------------- *)

K = 4;                    (* window size; try K = 4 or 5 first as a smoke test *)
MAXPOLICYROUNDS = 12;      (* strategy-iteration cap; mean-payoff games converge
                              in a small number of rounds in theory, but cap it
                              so a bad seed cannot loop unboundedly *)
RATIONALTOL = 10^-9;       (* Rationalize tolerance for the numeric -> exact pass *)

(* ------------------------------------------------------------------------- *)
(* STAGE 0: de Bruijn-K graph (MECHANICAL -- identical to CaseStudies.wl's
   posEdges[CE_], just not yet keyed to a loaded certificate association) *)
(* ------------------------------------------------------------------------- *)

nodes = StringJoin /@ Tuples[{"d", "t"}, K];
edges = Select[Tuples[nodes, 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];
Print["de Bruijn-", K, ": ", Length[nodes], " nodes, ", Length[edges], " edges"];

(* index conventions matching EpsilonCertificate.wl / CaseStudies.wl exactly *)
iu = 1; iv = 2; ia = 3; ib = 4; ip = 5;
jv = 1; jb = 2; jx = 3; jp = 4;
edgeLetter[e_] := StringTake[e[[1]], -1];

(* interface-DP transfer matrix, verbatim from CaseStudies.wl *)
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

(* ------------------------------------------------------------------------- *)
(* STAGE 1: joint numeric SDP+LP solve with strategy iteration.
   This is the stage flagged in the header as needing real care/iteration. *)
(* ------------------------------------------------------------------------- *)

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

psdCons = Join[
   Table[VectorGreaterEqual[{Qs[w], 0}, {"SemidefiniteCone", 5}], {w, nodes}],
   Table[VectorGreaterEqual[{Rs[w], 0}, {"SemidefiniteCone", 4}], {w, nodes}]];

(* dpTransfer has genuine -Infinity (invalid-transition) entries -- Td[[2,2]] and
   Tt[[2,3]] specifically. Any strategy, seed or improved, MUST avoid ever
   selecting a sig with T[[s,sig]] == -Infinity, or SemidefiniteOptimization will
   fail outright on the resulting poisoned constraint. *)
validSigs[T_, s_] := Select[Range[3], T[[s, #]] > -Infinity &];

(* DECOUPLED canonical game solve (THE FIX, see header (c)): for the FIXED
   strategy, maximize the worst-case (minimum) mean-payoff value achievable by
   ANY choice of Phi, using ONLY the game inequalities -- no Q/R, no Psi. This
   is a small, cheap LP (no PSD blocks at all) and gives the CANONICAL bias
   function policy improvement theory actually requires. refNode's phi[0,*] is
   pinned to 0 purely to remove the harmless 1-dim additive gauge freedom this
   decoupled solve has on its own (it doesn't touch Q/R, so this has no effect
   on which strategy looks best). *)
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

(* Improve[] now uses the CANONICAL (decoupled) Phi, not the joint solve's
   entangled one -- this is the actual fix; the comparison logic itself
   (maximize T[s,sig]+Phi[sig-1,x] per (s,e)) was already correct. *)
Improve[strategy_, canonSol_] := Association[Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], T, valid, vals},
      T = If[edgeLetter[e] === "d", Td, Tt];
      valid = validSigs[T, s];
      vals = (T[[s, #]] + (phiVar[# - 1, x] /. canonSol)) & /@ valid;
      {s, e} -> valid[[First@Ordering[-vals, 1]]]],
    {e, edges}, {s, 1, 3}]]];

(* Two deterministic seeds validated (k=3/4/5, exact match to the documented
   sequence, both converging identically) plus a couple of random restarts as
   an extra safety net -- keep whichever converges to the smallest Gamma. *)
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
  {strat = strategy0, canonSol, jointSol, gam = $Failed, newStrat, round = 0},
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
      Return[{label, jointSol, strat, gam, round}, Module]];
    strat = newStrat];
  {label, jointSol, strat, gam, round}];

Print["Stage 1: strategy iteration (decoupled canonical-Phi fix), cap ",
  MAXPOLICYROUNDS, " rounds per seed..."];
seedResults = {
   RunFromSeed[seedA, "A (sig=s)"],
   RunFromSeed[seedB, "B (first valid)"],
   RunFromSeed[randomSeed[1], "random-1"],
   RunFromSeed[randomSeed[2], "random-2"]};
bestIdx = First@Ordering[N[#[[4]], 10] & /@ seedResults, 1];
{finalLabel, finalSol, finalStrategy, finalGamma, roundsUsed} = seedResults[[bestIdx]];

Print["Stage 1 result: best seed = ", finalLabel, ", Gamma_", K, " (numeric) = ",
  N[finalGamma, 10], " after ", roundsUsed, " strategy-iteration round(s)."];
Print["  All seeds' results: ",
  {#[[1]], N[#[[4]], 10]} & /@ seedResults];
Print["  Compare to the k=2..8 sequence 0.1667, 0.1250, 0.1020, 0.0953, 0.0824, ",
  "0.0770624, 0.0753086 (QUANTUM_CONTEXTUALITY.md) before trusting -- if the best ",
  "seed still looks too large, add more random restarts before proceeding; ",
  "Stages 2/3/4 below assume a genuinely-converged solution."];

(* ------------------------------------------------------------------------- *)
(* STAGE 2: numeric -> exact rational, with equality-preserving REPAIR.
   BUG FOUND (12 July 2026): the original version of this stage only repaired
   the ONE node-level coupling equality (Q[iv,ib]+R[jv,jb]==0) and left a
   comment describing the needed edge-equality repair ("pick one canonical
   in-edge... derive the other") WITHOUT ever actually implementing it --
   Stage 3 then correctly caught this (edgeEqOK/psdOK both False on a K=4
   integration test), since naive independent Rationalize[] of each node's
   block breaks every shared equality by a tiny amount (each Q[x][[rA,rA]]-
   type entry is referenced by BOTH of x's two de-Bruijn predecessors'
   equations simultaneously, and de Bruijn predecessors always share the same
   edge-letter, so the same index pair really is shared, not just similar).

   FIX: don't repair equality-by-equality with ad hoc "pick a side" rules --
   collect EVERY nodeCons/edgeCons equality as one linear system A.x == b over
   the qrVars, and PROJECT the naive independent-Rationalize guess x0 onto the
   exact solution affine subspace {x : A.x == b} (the closest point to x0 in
   that subspace, via the standard minimum-norm correction
   x = x0 - A^T.(A.A^T)^-1.(A.x0 - b), computed in EXACT rational arithmetic
   since x0, A, b are all exact). This satisfies every equality EXACTLY by
   construction, regardless of how many equations any given entry appears in,
   and stays as close as possible (in this correction's sense) to the
   original numeric solution -- the same "round then repair minimally" spirit
   as the k=7 commit's own approach, just generalized to arbitrarily-shared
   equations instead of hand-picking which side to derive. *)
(* ------------------------------------------------------------------------- *)

rat[x_] := Rationalize[x, RATIONALTOL];

x0 = Map[rat, qrVars /. finalSol];
eqLHS = (#[[1]] - #[[2]]) & /@ Join[nodeCons, edgeCons];
(* BUG FOUND AND FIXED (12 July 2026): CoefficientArrays[eqs,vars] returns
   {c0, c1} = {constant-term array, coefficient MATRIX} -- the destructuring
   below was previously {Amat, bvec} = CoefficientArrays[...], backwards,
   silently binding Amat to the (vector) constants and bvec to the (matrix)
   coefficients. Transpose[] of a plain vector is a no-op in Mathematica, so
   Amat.Transpose[Amat] silently collapsed to a bare SCALAR (sum of squares of
   the constants) instead of a matrix, which is exactly what produced the
   observed "LinearSolve::matrix: Argument 160 at position 1 is not a
   nonempty rectangular matrix" crash (and subsequent kernel OOM from the
   resulting garbage symbolic expression) on the K=4 integration test.
   Confirmed via a minimal repro (debug_coefarrays.wl) before fixing. *)
{bvec, Amat} = CoefficientArrays[eqLHS, qrVars];
Amat = Normal[Amat]; bvec = -Normal[bvec];
residual = Amat.x0 - bvec;
Print["Stage 2: ", Length[qrVars], " Q/R variables, ", Length[eqLHS],
  " linear equalities; naive-rounded residual norm = ", N[Norm[residual], 6],
  " (expect small before projection, exactly 0 after)."];
lambda = LinearSolve[Amat.Transpose[Amat], residual];
xExact = x0 - Transpose[Amat].lambda;
Print["Stage 2: exact projection residual (should be exactly 0): ",
  Amat.xExact - bvec // Union];

exactRule = Thread[qrVars -> xExact];
QsExact = Association[Table[w -> (Qs[w] /. exactRule), {w, nodes}]];
RsExact = Association[Table[w -> (Rs[w] /. exactRule), {w, nodes}]];
Print["Stage 2: exact-rational conversion done (Rationalize tol ", RATIONALTOL,
  "), every nodeCons/edgeCons equality satisfied EXACTLY by construction -- ",
  "see Stage 3 for the independent re-derivation check and PSD-ness."];

(* ------------------------------------------------------------------------- *)
(* STAGE 3: exact re-verification, mirroring CaseStudies.wl's
   epsilonCertificateCheck / posSigma / posCheck VERBATIM (this code needs no
   changes for k=9 -- it already only reads CE["k"], CE["Nodes"], etc.) *)
(* ------------------------------------------------------------------------- *)

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

Print["=== PSD DIAGNOSTIC ==="];
Do[
  Module[{minEigQ, minEigR},
    minEigQ = Min[Eigenvalues[N[QsExact[w]]]];
    minEigR = Min[Eigenvalues[N[RsExact[w]]]];
    If[minEigQ < 10^-6 || minEigR < 10^-6,
      Print["  node ", w, ": min eig Q = ", minEigQ, ", min eig R = ", minEigR]]],
  {w, nodes}];
Print["  (worst min eigenvalue over all Q blocks: ", Min[Table[Min[Eigenvalues[N[QsExact[w]]]], {w, nodes}]],
  ", over all R blocks: ", Min[Table[Min[Eigenvalues[N[RsExact[w]]]], {w, nodes}]], ")"];
Print["=== END PSD DIAGNOSTIC ==="];

Print["Stage 3: nodeEqOK = ", nodeEqOK, ", edgeEqOK = ", edgeEqOK, ", psdOK = ", psdOK];
If[! (nodeEqOK && edgeEqOK && psdOK),
  Print["  FAILED exact re-verification -- do not export. Likely causes: the ",
    "shared-edge derivation in Stage 2 was applied inconsistently (see the NOTE ",
    "above), or RATIONALTOL is too coarse and pushed a block just outside the PSD ",
    "cone -- tighten RATIONALTOL, or add a small diagonal safety margin before ",
    "rounding, and rerun Stage 1/2."]];

(* exact Psi/Phi/Strategy: round Phi, Psi from finalSol; recompute an exact Gamma
   as the exact max of sigma(e) over all edges using the ALREADY-EXACT dpTransfer
   (integer) and the rounded-exact Phi, exactly mirroring posSigma/posCheck *)
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
Print["Stage 3: exact Gamma_", K, " (pointwise max over all edges) = ", GammaExact,
  " = ", N[GammaExact, 10]];
(* HONESTY FIX (2026-07-14 repo audit): pointwiseOK used to check
   posSigma9[e] <= GammaExact where GammaExact := Max[posSigma9/@edges] --
   "is every element of a list <= the max of that SAME list", true by
   construction for ANY list, zero protection. This exact bug was already
   found, root-caused, and fixed in the canonical pipeline
   (../GenerateEpsilonCertificate9.wl's own "BUG FOUND AND FIXED (12 July
   2026, adversarial review...)" comment) -- this debug copy was never
   updated to match. Ported the same fix here: gate against targetGamma
   (Stage 1's OWN independently-reported SDP result, not a function of the
   same list being tested) plus a drift cross-check, exactly mirroring the
   canonical file so this debug script can no longer silently "pass" a
   tautology if it's ever run to completion. *)
targetGamma = rat[gammaVar /. finalSol];
GAMMADRIFTTOL = 10^-4;
pointwiseOK = AllTrue[edges, posSigma9[#] <= targetGamma + GAMMADRIFTTOL &];
Print["Stage 3: pointwise sigma(e) <= Gamma for all edges: ", pointwiseOK,
  " (checked against targetGamma = ", targetGamma, " = ", N[targetGamma, 10],
  " + drift tolerance ", GAMMADRIFTTOL,
  ", Stage 1's OWN independently-reported SDP Gamma -- NOT GammaExact itself, ",
  "which would make this check tautological)."];
gammaDrift = N[GammaExact - targetGamma, 10];
gammaCrossCheckOK = Abs[gammaDrift] < GAMMADRIFTTOL;
Print["Stage 3: GammaExact vs Stage-1 targetGamma drift = ", gammaDrift,
  ", within tolerance (", GAMMADRIFTTOL, "): ", gammaCrossCheckOK];

(* ------------------------------------------------------------------------- *)
(* STAGE 4: package into a certificate association and write it out.
   HONESTY FIX (2026-07-14 repo audit): the export filename/label used to
   hardcode "EpsilonCertificate9" regardless of the K parameter above (which
   defaults to K=4 for smoke-testing) -- harmless in that SetDirectory (top
   of file) confines it to debug/, never the canonical certificate files one
   level up, but it would still have mislabeled a K=4 debug run as a "9" the
   moment anyone changed K without noticing this line, exactly the class of
   stale-label bug ISSUE-020 (KNOWN_ISSUES.md) documents for a different
   file. Now the variable name, export filename, and label all genuinely
   track K. *)
If[nodeEqOK && edgeEqOK && psdOK && pointwiseOK && gammaCrossCheckOK,
  Module[{certName = "EpsilonCertificate" <> ToString[K], cert, fname},
   cert = <|
     "k" -> K,
     "Gamma" -> GammaExact,
     "Nodes" -> nodes,
     "Q" -> QsExact,
     "R" -> RsExact,
     "Psi" -> PsiExact,
     "Phi" -> PhiExact,
     "Strategy" -> StrategyExact
    |>;
   fname = certName <> "_debug.wl";
   Export[fname,
     "(* Rational epsilon-optimality certificate, window k = " <> ToString[K] <>
      ". Generated by debug/debug_psd_check.wl (NOT the canonical pipeline -- \
see ../GenerateEpsilonCertificate9.wl for that; this is a debug/smoke-test \
run, kept out of the canonical certificates/ tree by construction). \
*)\n" <> certName <> " = " <> ToString[cert, InputForm] <> ";\n",
     "Text"];
   Print["Wrote ", fname, " -- Gamma_", K, " = ", GammaExact,
     " = ", N[GammaExact, 10]]],
  Print["NOT written: exact re-verification did not fully pass (see Stage 3 above). ",
    "nodeEqOK=", nodeEqOK, ", edgeEqOK=", edgeEqOK, ", psdOK=", psdOK,
    ", pointwiseOK=", pointwiseOK, ", gammaCrossCheckOK=", gammaCrossCheckOK,
    ". Fix Stage 1/2 and rerun before trusting/exporting any Gamma_", K, " value."]
];
