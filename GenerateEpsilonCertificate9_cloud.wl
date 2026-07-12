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
         entries Tc[[2,2]]/Tt[[2,3]], and avoiding a degenerate constant seed).
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


(* ------------------------------------------------------------------------- *)
(* PARAMETERS *)
(* ------------------------------------------------------------------------- *)

K = 9;                    (* window size; try K = 4 or 5 first as a smoke test *)
MAXPOLICYROUNDS = 20;      (* strategy-iteration cap; mean-payoff games converge
                              in a small number of rounds in theory, but cap it
                              so a bad seed cannot loop unboundedly. Raised from
                              12 (12 July 2026, adversarial review): now that
                              hitting the cap means a seed is excluded rather
                              than silently returning a mismatched result (see
                              RunFromSeed/Improve fixes below), a tighter cap
                              would too easily reject a seed that was simply
                              still genuinely converging at K=9's much larger
                              state space (K=3/4/5 converged in 2-4 rounds, but
                              that's ~48 (s,e) decisions vs ~3072 at K=9). *)
RATIONALTOL = 10^-9;       (* Rationalize tolerance for the numeric -> exact pass *)

(* ------------------------------------------------------------------------- *)
(* STAGE 0: de Bruijn-K graph (MECHANICAL -- identical to CaseStudies.wl's
   posEdges[CE_], just not yet keyed to a loaded certificate association) *)
(* ------------------------------------------------------------------------- *)

nodes = StringJoin /@ Tuples[{"c", "t"}, K];
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
      out = If[letter === "c", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];
Tc = dpTransfer["c"]; Tt = dpTransfer["t"];

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
      {rA, rB} = If[b === "c", {iu, iv}, {iv, iu}];
      {
       Qs[w][[ia, ia]] + Qs[x][[rA, rA]] + If[b === "t", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ib, ib]] + Rs[w][[jb, jb]] + Qs[x][[rB, rB]] + If[b === "c", Rs[x][[jv, jv]], 0] == 1,
       Qs[w][[ia, ip]] + Qs[x][[rA, ip]] + If[b === "t", Rs[x][[jv, jp]], 0] == 1,
       Qs[w][[ib, ip]] + Rs[w][[jb, jp]] + Qs[x][[rB, ip]] + If[b === "c", Rs[x][[jv, jp]], 0] == 1
      }],
    {e, edges}]];

(* PSDMARGIN (12 July 2026): the K=4/K=5 Stage-2/3 validation runs showed
   nodeEqOK/edgeEqOK now pass exactly (after the CoefficientArrays swap fix
   above), but psdOK still failed -- every violation was tiny (~1e-9 to
   1e-10), consistent with the optimal Gamma genuinely sitting AT the PSD
   boundary for many blocks (an active PSD constraint at the SDP optimum is
   normal), so the equality-only least-norm correction in Stage 2 (which is
   not itself PSD-aware) can push a boundary block to either side of zero.
   Fix: require every Q/R block to be PSD with a small spectral margin in
   THIS joint solve, so Stage 1's floating solution already sits safely
   inside the cone before Stage 2's rounding/correction ever touches it --
   PSDMARGIN=1e-6 is ~1000x the observed violation size, giving ample
   headroom, while being far too small to visibly affect the reported Gamma
   (which is only compared to the documented sequence at ~4 decimal digits). *)
PSDMARGIN = 10^-6;
psdCons = Join[
   Table[VectorGreaterEqual[{Qs[w] - PSDMARGIN*IdentityMatrix[5], 0}, {"SemidefiniteCone", 5}], {w, nodes}],
   Table[VectorGreaterEqual[{Rs[w] - PSDMARGIN*IdentityMatrix[4], 0}, {"SemidefiniteCone", 4}], {w, nodes}]];

(* dpTransfer has genuine -Infinity (invalid-transition) entries -- Tc[[2,2]] and
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

(* Improve[] now uses the CANONICAL (decoupled) Phi, not the joint solve's
   entangled one -- this is the actual fix; the comparison logic itself
   (maximize T[s,sig]+Phi[sig-1,x] per (s,e)) was already correct. *)
(* TRIED AND REVERTED (12 July 2026, adversarial review + empirical
   regression): a reviewer speculated that always switching to the
   best-scoring sig (even on ties) could risk oscillation, since
   CanonicalPhi's LP has no secondary tie-break and Phi is genuinely
   under-determined off the critical cycle. Tried the "standard" fix of
   preferring the incumbent on near-ties -- this IMMEDIATELY regressed: at
   K=3, seed A (previously reliably converging to the documented Gamma_3 =
   0.125) instead converged to the spurious fixed point ~0.5. Root cause:
   because CanonicalPhi returns an ARBITRARY (non-canonical) optimal LP
   vertex rather than a uniquely-determined bias function, an apparent "tie"
   against THIS SPECIFIC Phi is not necessarily a true tie in the underlying
   game -- some genuinely-improving moves can look tied, and refusing to
   switch on those gets the policy stuck. The textbook "no switching on
   ties" discipline only holds for a canonical potential function, which
   this LP does not provide (fixing that would require a proper
   lexicographic/bias-optimal LP, a bigger change than warranted here).
   Reverted to always-switch-to-best, which is what was actually validated
   correct at k=3/4/5 across multiple seeds. Oscillation risk (if it exists
   at K=9) is instead caught by the RunFromSeed round-cap fix below: a
   seed that fails to converge within MAXPOLICYROUNDS is now cleanly
   excluded with an explicit warning rather than silently corrupting the
   certificate. *)
Improve[strategy_, canonSol_] := Association[Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], T, valid, vals},
      T = If[edgeLetter[e] === "c", Tc, Tt];
      valid = validSigs[T, s];
      vals = (T[[s, #]] + (phiVar[# - 1, x] /. canonSol)) & /@ valid;
      {s, e} -> valid[[First@Ordering[-vals, 1]]]],
    {e, edges}, {s, 1, 3}]]];

(* Two deterministic seeds validated (k=3/4/5, exact match to the documented
   sequence, both converging identically) plus a couple of random restarts as
   an extra safety net -- keep whichever converges to the smallest Gamma. *)
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

(* BUG FOUND AND FIXED (12 July 2026, adversarial review): the original
   fallthrough (exiting via the While condition rather than the explicit
   Return) applied `strat = newStrat` BEFORE the While test was re-checked,
   so a seed that exhausted MAXPOLICYROUNDS without converging returned a
   `strat` that was one improvement-step AHEAD of the `jointSol`/`gam`
   computed for the PREVIOUS strategy -- silently pairing mismatched
   Strategy/Phi/Q/R data. Impossible to trigger at K=3/4/5 (documented
   convergence in 2-4 rounds, always via the early Return), but far more
   plausible at K=9's much larger state space. FIX: only apply the pending
   strategy update if there's a next round to use it in; if the cap is
   reached first, stop and return the last MUTUALLY CONSISTENT triple,
   with an explicit non-convergence warning (previously silent). *)
RunFromSeed[strategy0_, label_] := Module[
  {strat = strategy0, canonSol, jointSol, gam = $Failed, newStrat, round = 0, converged = False},
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
      Print["    WARNING: MAXPOLICYROUNDS (", MAXPOLICYROUNDS, ") reached without ",
        "convergence -- returning the last MUTUALLY CONSISTENT (strategy,jointSol,Gamma), ",
        "NOT the one-step-ahead improved strategy. This Gamma may not be optimal; increase ",
        "MAXPOLICYROUNDS or investigate possible oscillation before trusting it."];
      Break[]];
    strat = newStrat];
  {label, jointSol, strat, gam, round, converged}];

Print["Stage 1: strategy iteration (decoupled canonical-Phi fix), cap ",
  MAXPOLICYROUNDS, " rounds per seed..."];
seedResults = {
   RunFromSeed[seedA, "A (sig=s)"],
   RunFromSeed[seedB, "B (first valid)"],
   RunFromSeed[randomSeed[1], "random-1"],
   RunFromSeed[randomSeed[2], "random-2"]};

(* BUG FOUND AND FIXED (12 July 2026, adversarial review): seed selection
   used to pick purely by smallest Gamma with no regard to whether that
   Gamma came from a genuinely converged seed or a cap-exhausted fallback --
   a stale, non-converged Gamma could look smaller (more attractive) and be
   silently preferred. FIX: prefer converged seeds; only fall back to
   non-converged ones (with a loud warning) if none converged at all. *)
convergedSeedResults = Select[seedResults, #[[6]] &];
candidateSeedResults = If[Length[convergedSeedResults] > 0, convergedSeedResults, seedResults];
If[Length[convergedSeedResults] == 0,
  Print["  WARNING: NONE of the ", Length[seedResults], " seeds converged within ",
    "MAXPOLICYROUNDS -- falling back to the best NON-CONVERGED result, which is NOT ",
    "trustworthy as-is. Increase MAXPOLICYROUNDS or investigate oscillation before ",
    "trusting any exported certificate."]];
bestIdx = First@Ordering[N[#[[4]], 10] & /@ candidateSeedResults, 1];
{finalLabel, finalSol, finalStrategy, finalGamma, roundsUsed, finalConverged} = candidateSeedResults[[bestIdx]];

Print["Stage 1 result: best seed = ", finalLabel, ", Gamma_", K, " (numeric) = ",
  N[finalGamma, 10], " after ", roundsUsed, " strategy-iteration round(s), converged = ",
  finalConverged, "."];
Print["  All seeds' results: ",
  {#[[1]], N[#[[4]], 10], "converged->" <> ToString[#[[6]]]} & /@ seedResults];
Print["  Compare to the k=2..8 sequence 0.1667, 0.1250, 0.1020, 0.0953, 0.0824, ",
  "0.0770624, 0.0753086 (QUANTUM_CONTEXTUALITY.md) before trusting -- if the best ",
  "seed still looks too large, add more random restarts before proceeding; ",
  "Stages 2/3/4 below assume a genuinely-converged solution."];

(* Cross-seed agreement check (adversarial review finding: at K=9 there is no
   documented ground-truth Gamma_9 to eyeball against, unlike k<=8 -- this is
   the best available automated proxy: the two TRUSTED deterministic seeds
   (A, B) should independently converge to the SAME global optimum if both
   are genuinely on it. Disagreement (or either failing to converge) is a
   real red flag that the "best" Gamma found may just be a good-looking local
   fixed point, not the true value. *)
seedAResult = seedResults[[1]]; seedBResult = seedResults[[2]];
seedAGamma = If[TrueQ[seedAResult[[6]]], N[seedAResult[[4]], 10], Missing["NotConverged"]];
seedBGamma = If[TrueQ[seedBResult[[6]]], N[seedBResult[[4]], 10], Missing["NotConverged"]];
seedAgreementOK = NumericQ[seedAGamma] && NumericQ[seedBGamma] && Abs[seedAGamma - seedBGamma] < 10^-4;
Print["  Cross-seed agreement check (A vs B, the two trusted deterministic seeds): A = ",
  seedAGamma, ", B = ", seedBGamma, ", agree = ", seedAgreementOK];
If[! seedAgreementOK,
  Print["  WARNING: trusted seeds A and B do not agree (or one/both failed to converge) -- ",
    "with no documented ground truth for Gamma_", K, " to check against, this is a real risk ",
    "that the selected result is a spurious local fixed point, not the true optimum. Do not ",
    "trust this certificate without manually reviewing all seeds' round-by-round histories above."]];

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
(* PERFORMANCE FIX (12 July 2026, adversarial review): CoefficientArrays
   already returns Amat/bvec as SparseArray, and this constraint matrix is
   extremely (and increasingly, with K) sparse -- density halves with every
   +1 to K, projected ~0.018% nonzero at K=9. The Normal[] calls previously
   here forced a dense ~650MB+ matrix for no benefit (LinearSolve and Dot
   both accept SparseArray natively); removing them was verified by the
   review to produce bit-identical exact results at every tested K. *)
{bvec, Amat} = CoefficientArrays[eqLHS, qrVars];
bvec = -bvec;
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
      b = StringTake[w, -1]; {rA, rB} = If[b === "c", {iu, iv}, {iv, iu}];
      QsExact[w][[ia, ia]] + QsExact[x][[rA, rA]] + If[b === "t", RsExact[x][[jv, jv]], 0] == 1 &&
       QsExact[w][[ib, ib]] + RsExact[w][[jb, jb]] + QsExact[x][[rB, rB]] +
         If[b === "c", RsExact[x][[jv, jv]], 0] == 1 &&
       QsExact[w][[ia, ip]] + QsExact[x][[rA, ip]] + If[b === "t", RsExact[x][[jv, jp]], 0] == 1 &&
       QsExact[w][[ib, ip]] + RsExact[w][[jb, jp]] + QsExact[x][[rB, ip]] +
         If[b === "c", RsExact[x][[jv, jp]], 0] == 1] &];

psdOK = AllTrue[nodes, PositiveSemidefiniteMatrixQ[QsExact[#]] && PositiveSemidefiniteMatrixQ[RsExact[#]] &];

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
   T = If[edgeLetter[e] === "c", Tc, Tt];
   r = Min[Table[Module[{sig = StrategyExact[ToString[s - 1] <> "|" <> w <> ">" <> x]},
       T[[s, sig]] + PhiExact[ToString[sig - 1] <> "|" <> x] - PhiExact[ToString[s - 1] <> "|" <> w]],
      {s, 3}]];
   (QsExact[x][[ip, ip]] + RsExact[x][[jp, jp]]) - r + PsiExact[x] - PsiExact[w]];

GammaExact = Max[posSigma9 /@ edges];
Print["Stage 3: exact Gamma_", K, " (pointwise max over all edges) = ", GammaExact,
  " = ", N[GammaExact, 10]];

(* BUG FOUND AND FIXED (12 July 2026, adversarial review, found independently
   by two reviewer angles): pointwiseOK previously checked posSigma9[e] <=
   GammaExact where GammaExact := Max[posSigma9/@edges] -- i.e. "is every
   element of a list <= the max of that SAME list", which is true by
   construction for ANY list and can never fail. It provided ZERO protection
   against a bug anywhere in posSigma9/PhiExact/StrategyExact/QsExact/RsExact
   (e.g. the round-cap Strategy/jointSol mismatch bug fixed above), unlike
   CaseStudies.wl's actual posCheck, which compares against an INDEPENDENTLY
   fixed Gamma, not one derived from the same data being tested. FIX: derive
   an independent target from Stage 1's own SDP-reported Gamma (exactified
   the same way, via rat[]) and check against THAT instead -- now genuinely
   falsifiable -- plus an explicit drift check between the two independently
   -derived values, gating export on both. *)
targetGamma = rat[gammaVar /. finalSol];
GAMMADRIFTTOL = 10^-4;
(* Zero-tolerance posSigma9[#]<=targetGamma is too strict in practice: Stage
   2's rounding/projection always introduces SOME nonzero (if tiny, ~1e-9
   scale in testing) exact discrepancy between Stage 1's reported Gamma and
   the exact recomputation, which would make this fail even for a perfectly
   legitimate result. Allow the SAME drift tolerance used below for the
   summary drift check, so this still catches a genuine large mismatch (e.g.
   the round-cap Strategy/jointSol bug, which would misalign sigma(e) far
   beyond rounding-noise scale) while tolerating ordinary rounding drift. *)
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
(* STAGE 4: package into the EpsilonCertificate9 association, matching the exact
   field layout of EpsilonCertificate.wl / EpsilonCertificate8.wl, and write it out. *)
(* ------------------------------------------------------------------------- *)

If[nodeEqOK && edgeEqOK && psdOK && pointwiseOK && gammaCrossCheckOK && finalConverged,
  EpsilonCertificate9 = <|
     "k" -> K,
     "Gamma" -> GammaExact,
     "Nodes" -> nodes,
     "Q" -> QsExact,
     "R" -> RsExact,
     "Psi" -> PsiExact,
     "Phi" -> PhiExact,
     "Strategy" -> StrategyExact
    |>;
  Export["EpsilonCertificate9.wl",
    "(* Rational epsilon-optimality certificate, window k = " <> ToString[K] <>
     ". Generated by GenerateEpsilonCertificate9.wl -- SEE THAT FILE'S HEADER for \
what is/isn't yet independently re-verified beyond the in-script Stage 3 checks. \
*)\nEpsilonCertificate9 = " <> ToString[EpsilonCertificate9, InputForm] <> ";\n",
    "Text"];
  Print["Wrote EpsilonCertificate9.wl -- Gamma_", K, " = ", GammaExact,
    " = ", N[GammaExact, 10]],
  Print["NOT written: exact re-verification did not fully pass (see Stage 3 above). ",
    "nodeEqOK=", nodeEqOK, ", edgeEqOK=", edgeEqOK, ", psdOK=", psdOK,
    ", pointwiseOK=", pointwiseOK, ", gammaCrossCheckOK=", gammaCrossCheckOK,
    ", finalConverged=", finalConverged,
    ". Fix Stage 1/2 (or increase MAXPOLICYROUNDS if finalConverged=False) and rerun ",
    "before trusting/exporting any Gamma_9 value."]
];

(* CLOUD-SUBMISSION ADDITION (not in the local file): the Export[] above
   writes to the remote machine's ephemeral disk, which is not directly
   retrievable -- so make the FINAL value of this expression (what
   RemoteBatchSubmit captures as EvaluationResult) a self-contained
   diagnostic association with everything needed to judge the run, plus the
   full certificate INLINE if it passed, so nothing depends on file
   retrieval. *)
<|
  "k" -> K,
  "checksPass" -> (nodeEqOK && edgeEqOK && psdOK && pointwiseOK && gammaCrossCheckOK && finalConverged),
  "nodeEqOK" -> nodeEqOK, "edgeEqOK" -> edgeEqOK, "psdOK" -> psdOK,
  "pointwiseOK" -> pointwiseOK, "gammaCrossCheckOK" -> gammaCrossCheckOK,
  "finalConverged" -> finalConverged, "finalLabel" -> finalLabel,
  "roundsUsed" -> roundsUsed, "gammaDrift" -> gammaDrift,
  "seedAgreementOK" -> seedAgreementOK,
  "allSeedsResults" -> ({#[[1]], N[#[[4]], 10], #[[6]]} & /@ seedResults),
  "GammaExact" -> GammaExact, "GammaExactN" -> N[GammaExact, 12],
  "targetGamma" -> targetGamma,
  "Certificate" -> If[nodeEqOK && edgeEqOK && psdOK && pointwiseOK && gammaCrossCheckOK && finalConverged,
     <|"k" -> K, "Gamma" -> GammaExact, "Nodes" -> nodes, "Q" -> QsExact, "R" -> RsExact,
       "Psi" -> PsiExact, "Phi" -> PhiExact, "Strategy" -> StrategyExact|>,
     Missing["ChecksFailed"]]
|>

