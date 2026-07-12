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
   NEW, from-scratch reconstruction of a plausible construction pipeline, written
   and partially validated (small-k prototyping, k=3/k=4, plus raw problem-size
   timing tests at the true k=9 scale) via a live Wolfram kernel in the course of
   the investigation that produced this file. Findings from that prototyping:

     (a) The CONSTRAINT STRUCTURE below (node/edge equalities, 5x5/4x4 PSD shapes,
         dpTransfer) is verified to carry over VERBATIM from k=7/8 to any k -- it is
         exactly the same code that CaseStudies.wl already uses generically via
         CE["k"]/CE["Nodes"] to verify k=7 and k=8. This part needed NO new
         derivation; only re.indexing over de-Bruijn-9 strings instead of -7/-8.

     (b) Raw problem size is tractable at k=9 (512 nodes, 1024 edges): enumerating
         the graph takes <1s; the mean-payoff LP (Psi/Gamma, given fixed d/r) solves
         in ~0.15s via LinearOptimization even at 512 vars / 1024 constraints;
         the joint block-diagonal SDP (512 x 5x5 + 512 x 4x4 PSD blocks with linear
         equality coupling) was timed on synthetic same-shape problems at
         nb = 8/16/32/64/128/192 blocks (0.28s / 0.46s / 0.65s / 2.1s / 8.5s / 23.9s),
         scaling worse than linear (~nb^2 to nb^3) but extrapolating to roughly
         single-digit to a few tens of minutes at nb = 512 -- i.e. plausibly within
         "a few hours" total, NOT intractable by raw compute.

     (c) The genuinely nontrivial part is getting the STRATEGY ITERATION (mean-
         payoff game over Phi/Strategy) to converge to a GOOD (small) Gamma rather
         than a degenerate one -- confirmed the hard way by direct prototyping,
         which hit TWO distinct real bugs before producing anything sane:
           (i) A naive constant initial strategy (sig = 1 always) converges
               immediately to a useless fixed point (Gamma ~ 0.5) because an
               under-exercised strategy leaves some Phi[phase,node] entries
               unconstrained, corrupting the policy-improvement comparison.
          (ii) dpTransfer's T matrix has genuinely INVALID (-Infinity) entries
               (Tc[[2,2]] and Tt[[2,3]] specifically -- the interface DP forbids
               those particular state-to-state moves). A seed strategy that
               picks sig "blindly" (e.g. sig = s, "aim for the mirror phase") can
               select one of these invalid transitions, which then poisons a
               constraint with -Infinity and makes SemidefiniteOptimization
               outright FAIL with "...could not be converted to semidefinite
               cone constraints" (confirmed live). The fix used below
               (validSig[]) restricts every strategy choice to sig with
               T[[s,sig]] > -Infinity.
         Even with BOTH fixes applied, a k=4 smoke test in this investigation
         still converged to Gamma ~ 0.5 after one policy-improvement round --
         well above the documented Gamma_4 ~ 0.1020 (QUANTUM_CONTEXTUALITY.md) --
         meaning at least one more real ingredient is missing (candidates: a
         smarter/multiple-restart seed, more policy-iteration rounds than tested,
         or a genuine coupling between the Q/R SDP and the game that the fixed-
         strategy joint solve here does not yet capture correctly). This is
         concrete, first-hand confirmation of the k=7 commit's own admission of
         an "exact-repair subtlety" -- constructing a TIGHT certificate at any
         window k, including k=9, is real algorithm-engineering/derivation work,
         not a push-button rerun, even though the constraint STRUCTURE (point a)
         needs no new derivation at all.
         CONCRETE TAKEAWAY: treat Stage 1 below as a validated-to-run,
         NOT validated-to-converge-well starting point; budget real debugging
         time (better seeding, multiple random restarts, more policy rounds,
         inspecting solver Messages instead of blanket Quiet) before trusting
         its Gamma output, and sanity-check against the known k=2..8 sequence at
         small k before committing to a full k=9 run.

     (d) The final exact-rational RATIONALIZE + integer-preserving REPAIR (Stage 2)
         and the exact PSD/edge-equality re-verification (Stage 3) are written
         here as directly-portable adaptations of CaseStudies.wl's own
         epsilonCertificateCheck / posSigma / posCheck logic (so a produced
         EpsilonCertificate9 association is a drop-in for that EXISTING, already
         k-agnostic verification code -- no changes needed there). These stages are
         mechanical GIVEN a good numeric solution from Stage 1.

   Run with:  wolframscript -file GenerateEpsilonCertificate9.wl -print all
   (expect Stage 1 alone to take from minutes to a few hours at k=9; consider
   lowering K below to 4..6 first to sanity-check the whole pipeline end to end,
   the way this investigation prototyped it, before committing to a full k=9 run).
*)

SetDirectory[DirectoryName[$InputFileName]];

(* ------------------------------------------------------------------------- *)
(* PARAMETERS *)
(* ------------------------------------------------------------------------- *)

K = 9;                    (* window size; try K = 4 or 5 first as a smoke test *)
MAXPOLICYROUNDS = 12;      (* strategy-iteration cap; mean-payoff games converge
                              in a small number of rounds in theory, but cap it
                              so a bad seed cannot loop unboundedly *)
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

psdCons = Join[
   Table[VectorGreaterEqual[{Qs[w], 0}, {"SemidefiniteCone", 5}], {w, nodes}],
   Table[VectorGreaterEqual[{Rs[w], 0}, {"SemidefiniteCone", 4}], {w, nodes}]];

(* Given a FIXED strategy (source-phase, edge) -> target-phase in {1,2,3}, the
   whole problem (Q,R feasibility/PSD AND the mean-payoff-game potential
   inequalities) is jointly convex (SDP+LP) in (Q,R,Phi,Psi,r,Gamma), because d(x)
   enters the Gamma-constraints linearly. Solve it in ONE SemidefiniteOptimization
   call rather than decoupling Q/R from Phi/Psi (a decoupled two-stage pass was
   tried during prototyping and gave a much worse Gamma, because minimizing
   Mean[d(x)] alone does not account for how d(x) is used in the worst-case max). *)
(* dpTransfer has genuine -Infinity (invalid-transition) entries -- Tc[[2,2]] and
   Tt[[2,3]] specifically. Any strategy, seed or improved, MUST avoid ever
   selecting a sig with T[[s,sig]] == -Infinity, or SemidefiniteOptimization will
   fail outright on the resulting poisoned constraint (confirmed live in
   prototyping -- see finding (c)(ii) in the header). *)
validSigs[T_, s_] := Select[Range[3], T[[s, #]] > -Infinity &];

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

Improve[strategy_, sol_] := Association[Flatten[Table[
    Module[{w = e[[1]], x = e[[2]], T, valid, vals},
      T = If[edgeLetter[e] === "c", Tc, Tt];
      valid = validSigs[T, s];
      vals = (T[[s, #]] + (phiVar[# - 1, x] /. sol)) & /@ valid;
      {s, e} -> valid[[First@Ordering[-vals, 1]]]],
    {e, edges}, {s, 1, 3}]]];

(* Seed: sig = s ("aim for the mirror phase") wherever that is a VALID transition,
   else the first valid alternative. During prototyping, a constant seed (sig = 1
   always) converged immediately to a useless fixed point (Gamma ~ 0.5, leaving
   some Phi[phase,*] unconstrained and corrupting Improve[]'s comparison), and an
   unguarded "sig = s" seed crashed SemidefiniteOptimization outright whenever it
   landed on one of the two invalid (s,sig) pairs above. THIS seed avoids both
   known failure modes, but still only reached Gamma ~ 0.5 at k=4 in testing
   (versus the documented Gamma_4 ~ 0.1020) -- see finding (c) in the header.
   Try several different/randomized valid seeds and keep the best-converged
   Gamma; do not trust a single run's output without comparing against the
   known k=2..8 sequence at small k first. *)
strategy0 = Association[Table[
   Module[{T = If[edgeLetter[e] === "c", Tc, Tt], valid},
     valid = validSigs[T, s];
     {s, e} -> If[MemberQ[valid, s], s, First[valid]]],
   {e, edges}, {s, 1, 3}]];

Print["Stage 1: strategy iteration (cap ", MAXPOLICYROUNDS, " rounds)..."];
{finalSol, finalStrategy, finalGamma, roundsUsed} = Module[
   {strat = strategy0, sol, gam, prevStrat, round = 0, converged = False},
   While[round < MAXPOLICYROUNDS && ! converged,
    round++;
    sol = Check[SolveJoint[strat], $Failed];
    If[sol === $Failed || Head[sol] =!= List,
     Print["  round ", round, ": SDP solve FAILED or returned unevaluated -- ",
       "inspect solver Messages (remove Quiet if present) before retrying."];
     Break[]];
    gam = gammaVar /. sol;
    Print["  round ", round, ": Gamma = ", N[gam, 8]];
    prevStrat = strat;
    strat = Improve[strat, sol];
    If[strat === prevStrat, converged = True]];
   {sol, strat, gam, round}];

Print["Stage 1 result: Gamma_", K, " (numeric) = ", N[finalGamma, 10],
  " after ", roundsUsed, " strategy-iteration round(s)."];
Print["  If roundsUsed == MAXPOLICYROUNDS without convergence, or Gamma looks too ",
  "large (compare to the k=2..8 sequence 0.1667, 0.1250, 0.1020, 0.0953, 0.0824, ",
  "0.0770624, 0.0753086 in QUANTUM_CONTEXTUALITY.md), re-seed and rerun Stage 1 ",
  "before proceeding -- Stages 2/3/4 below assume a genuinely-converged solution."];

(* ------------------------------------------------------------------------- *)
(* STAGE 2: numeric -> exact rational, with equality-preserving REPAIR.
   Naive independent Rationalize[] of both sides of a shared-sum equality (e.g.
   Q[w][[iv,ib]] + R[w][[jv,jb]] == 0, or the four per-edge sum equalities) breaks
   that equality by a tiny amount, which then breaks exact PSD-ness downstream.
   The fix (flagged in the k=7 commit message): round ONE side freely, DERIVE the
   other side exactly from the equality. *)
(* ------------------------------------------------------------------------- *)

rat[x_] := Rationalize[x, RATIONALTOL];

QsExact = Association[]; RsExact = Association[];
Do[
  Module[{Qn = Qs[w] /. finalSol, Rn = Rs[w] /. finalSol, Qe, Re},
    Qe = Map[rat, Qn, {2}];
    Re = Map[rat, Rn, {2}];
    (* repair the one node-level coupling equality: Q[iv,ib] + R[jv,jb] == 0 *)
    Re[[jv, jb]] = -Qe[[iv, ib]]; Re[[jb, jv]] = -Qe[[iv, ib]];
    Qe[[iv, ia]] = 0; Qe[[ia, iv]] = 0;
    Qe[[iu, ib]] = 0; Qe[[ib, iu]] = 0;
    Re[[jx, jx]] = 1; Re[[jx, jp]] = 1; Re[[jp, jx]] = 1;
    QsExact[w] = Qe; RsExact[w] = Re],
  {w, nodes}];

(* repair the four per-edge sum equalities: round the w-side term (already fixed
   above via QsExact/RsExact), DERIVE the matching x-side term as the exact
   residual against the required RHS = 1, rather than independently rounding it.
   NOTE: each of Q[x][[rA,rA]] etc. is shared by TWO edges in general (x's two
   in-edges from its de-Bruijn predecessors) at k=9 exactly as at k=7/8, so this
   derivation must be applied consistently -- pick one canonical in-edge per
   (x, role) to derive from and verify the OTHER in-edge's equality holds as a
   consequence (this is exactly epsilonCertificateCheck's Do-loop check below). *)
Print["Stage 2: exact-rational conversion done (Rationalize tol ", RATIONALTOL, "). ",
  "NOT yet verified consistent across shared edges -- see Stage 3."];

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
pointwiseOK = AllTrue[edges, posSigma9[#] <= GammaExact &];
Print["Stage 3: pointwise sigma(e) <= Gamma for all edges: ", pointwiseOK];

(* ------------------------------------------------------------------------- *)
(* STAGE 4: package into the EpsilonCertificate9 association, matching the exact
   field layout of EpsilonCertificate.wl / EpsilonCertificate8.wl, and write it out. *)
(* ------------------------------------------------------------------------- *)

If[nodeEqOK && edgeEqOK && psdOK && pointwiseOK,
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
    "Fix Stage 1/2 and rerun before trusting/exporting any Gamma_9 value."]
];
