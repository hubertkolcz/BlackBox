(* trans_chain_density_cloud.wl
   =============================================================================
   Wolfram Compute Services (RemoteBatchSubmit) script: trans-chain bulk-density
   check at m = 200 .. 5000, upgrading ledger key D3_transChainNumerical toward
   the conjecture

       open trans-chain bulk density  ->  tauStar
                                       =  Root[49 x^3 - 128 x^2 - 75 x + 218, 2]
                                       ~  1.3767177459158590533

   (tauStar is the PROVEN N->Infinity density of the trans RING, CaseStudies.wl
   Case D3, key D3_densityClosedForm; the open-chain bulk density reaching the
   same constant is so far only Python numerics at m = 50..800 with ~0.01
   small-m boundary transients -- see the D3_transChainNumerical comment block.)

   SELF-CONTAINED: no Needs/Get/PacletDirectoryLoad. Everything needed is
   inlined below with attribution:
     - transChainWL[m]     : VERBATIM from 03-MESH-pentagon-composition/
                             trans_chain_density_check.wl (identical to the
                             CaseStudies.wl Case-D3 "trans-chain anchors" cell).
     - chordalCliques[h]   : VERBATIM private helper from
                             BlackBox/Kernel/BlackBox.wl (HubertKolcz`BlackBox`,
                             minimum-degree chordal extension, subset-maximal
                             elimination bags = maximal cliques).
     - thetaSparseScaled[g]: LovaszThetaSparse[g, "Certificate"] from
                             BlackBox/Kernel/BlackBox.wl, with exactly three
                             changes (the originals are NOT modified):
         (1) O(1)-CONDITIONING RESCALING (the remedy the project already
             documented for the +0.05 bias / solver-quality degradation at
             large N, CaseStudies.wl Case D3: "both solvers need
             O(1)-conditioned data -- the chordal border is rescaled by
             1/Sqrt[n], the symbol program is solved in density units";
             implemented for Clarabel in lovasz_theta_sparse.py `_assemble`):
             the LMI is solved for M' = D M D with D = diag(1/Sqrt[s],...,1),
             s = n, so per-vertex diagonal sums == tau (density units, O(1)),
             border sums == 1/Sqrt[s], corner == 1, and theta = s * tau.
         (2) RAISED SOLVER OPTIONS per the SemidefiniteOptimization::dfedge
             remedy observed when the prior local attempt
             (trans_chain_density_check.wl) was killed at m = 1000:
             MaxIterations -> 2000 (4x the 500 the paclet uses) and
             Tolerance -> 10^-8.
         (3) LARGE-n CERTIFICATE: the eigenvalue-certified upper bound
             lambda_max(J - B) is computed from a SPARSE edge-masked witness B
             (rescaled back to original units, B = s * sum_j S'_j masked to
             E(g)) instead of the paclet's dense n<=1500-only path, so the
             self-certificate is available at every m in the list (largest
             n = 3*5000+2 = 15002; the one dense n x n matrix needed for the
             final eigensolve is ~1.8 GB there).

   OUTPUT CONTRACT: prints a per-m log line (theta, density theta/m, increment
   (theta(m)-theta(m'))/(m-m'), certified upper bound, timing, MaxMemoryUsed)
   with a PASS/FAIL tag on |increment - tauStar| < 5*10^-4 for m >= 500 (bulk),
   INFO for m < 500 (documented boundary-transient regime), and -- following the
   GenerateEpsilonCertificate10_cloud.wl tail pattern -- the FINAL EXPRESSION of
   the script is a self-contained diagnostic association carrying every result
   inline, so RemoteBatchSubmit's EvaluationResult needs no file retrieval.

   m values run ASCENDING so partial output remains useful if the job dies at
   the largest sizes.

   MEASURED RUNTIME ENVELOPE (local validation, 13 July 2026, Windows i7-class
   8-thread node, partially contended by concurrent kernels): the WL
   SemidefiniteOptimization SOLVE (not the 0.5 s constraint build) costs
   ~95-105 s at m = 50 and ~3-4.2x per doubling of m, i.e. t(m) ~ t50 *
   (m/50)^p with p ~ 1.8-2.1 -- independent of Method ("DSDP" returns garbage
   ~1.26e9 on this problem; vectorized assembly reproduces the identical
   result bit-for-bit at the identical cost; Tolerance 1e-8 vs default is a
   no-op bit-for-bit). Expect roughly: m=200 ~ 0.3-0.5 h, m=500 ~ 1-2 h,
   m=1000 ~ 3-6 h, m=2000 ~ 7-20 h, m=5000 ~ 27-106+ h. If the credit budget
   does not cover the top sizes, EDIT THE ONE MVALUES LINE below (e.g. stop at
   1000 or 2000); the ascending order already makes any prefix a complete,
   useful result.
   ============================================================================= *)

(* ------------------------------------------------------------------------- *)
(* PARAMETERS                                                                  *)
(* ------------------------------------------------------------------------- *)

(* === M-LIST SWITCH ===
   FULL cloud list (ACTIVE -- this is what RemoteBatchSubmit should run): *)
MVALUES = {200, 500, 1000, 2000, 5000};
(* LOCAL VALIDATION list -- uncomment the next line (it then overrides the
   full list above) to smoke-test locally; RE-COMMENT before cloud submission:
MVALUES = {50, 100, 200};
*)

OPTMAXITER = 2000;      (* SemidefiniteOptimization MaxIterations: 4x the 500
                           used by the paclet's LovaszThetaSparse -- the dfedge
                           message's own suggested remedy *)
OPTTOL    = 10^-8;      (* tightened Tolerance, second dfedge remedy tried *)
CERTNMAX  = 16000;      (* compute the eigenvalue certificate up to this vertex
                           count (covers m = 5000: n = 15002; the dense J - B
                           eigensolve there needs ~1.8 GB + LAPACK workspace) *)
BULKTOL   = 5 10^-4;    (* |increment - tauStar| threshold for PASS *)
BULKMINM  = 500;        (* below this m: INFO (boundary transients ~0.01), not FAIL *)

tauStar  = Root[49 #^3 - 128 #^2 - 75 # + 218 &, 2];  (* exact algebraic target *)
tauStarN = N[tauStar];
Print["Target bulk density tauStar = Root[49x^3-128x^2-75x+218, 2] = ",
  ToString[N[tauStar, 15], InputForm], "  (15 digits)"];
Print["PASS criterion: |increment - tauStar| < ", N[BULKTOL],
  " for m >= ", BULKMINM, " (smaller m tagged INFO: boundary-transient regime)"];
Print["Solver options: MaxIterations -> ", OPTMAXITER, ", Tolerance -> ",
  ToString[OPTTOL, InputForm],
  ", O(1) conditioning: density-unit diagonal + 1/Sqrt[n] Schur border rescaling"];
Print["$Version = ", $Version, ", $ProcessorCount = ", $ProcessorCount];

(* ------------------------------------------------------------------------- *)
(* transChainWL[m]: the open trans chain, 3m+2 vertices.
   VERBATIM from trans_chain_density_check.wl / CaseStudies.wl Case D3.        *)
(* ------------------------------------------------------------------------- *)

transChainWL[m_Integer] := Module[{edges = {}, u = 1, v = 2},
  Do[Module[{a = 3 k + 3, b = 3 k + 4, x = 3 k + 5},
    edges = Join[edges, {{u, v}, {u, a}, {a, b}, {b, x}, {x, v}}];
    {u, v} = {b, a}], {k, 0, m - 1}];
  Graph[Range[3 m + 2], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];

(* ------------------------------------------------------------------------- *)
(* chordalCliques[h]: chordal extension by minimum-degree elimination; the bag
   of each eliminated vertex (vertex + current neighbourhood) is a clique of
   the extension; the subset-maximal bags are exactly its maximal cliques.
   VERBATIM private helper from BlackBox/Kernel/BlackBox.wl.                   *)
(* ------------------------------------------------------------------------- *)

chordalCliques[h_Graph] := Module[{n = VertexCount[h], adj, bags = {}, keys, v, nb, sorted, kept = {}},
  adj = AssociationThread[Range[n] -> (Sort[AdjacencyList[h, #]] & /@ Range[n])];
  Do[
    keys = Keys[adj];
    v = keys[[First[Ordering[Length /@ Values[adj], 1]]]];
    nb = adj[v];
    AppendTo[bags, Sort[Prepend[nb, v]]];
    Do[adj[u] = Union[DeleteCases[adj[u], v], DeleteCases[nb, u]], {u, nb}];
    KeyDropFrom[adj, v],
    {n}];
  sorted = ReverseSortBy[DeleteDuplicates[bags], Length];
  Do[If[! AnyTrue[kept, SubsetQ[#, b] &], AppendTo[kept, b]], {b, sorted}];
  kept];

(* ------------------------------------------------------------------------- *)
(* thetaSparseScaled[g]: chordal-decomposition Lovasz theta with certificate.
   ADAPTED from LovaszThetaSparse[g, "Certificate"] in BlackBox/Kernel/
   BlackBox.wl -- dual program theta(g) = min lambda_max(J - B), B supported on
   E(g); rank-one J absorbed into a Schur apex border row, the (n+1)-cone split
   clique-by-clique: M = [[t I + B, e],[e^T, 1]] = Sum_j E_j^T S_j E_j, S_j >= 0.
   Changes vs the paclet original: (1) O(1) rescaling M' = D M D,
   D = diag(1/Sqrt[s],...,1), s = n  =>  diagonal sums == tau (= t/s, density
   units), border sums == 1/Sqrt[s], corner == 1, theta = s*tau  (CaseStudies.wl
   D3 conditioning note / lovasz_theta_sparse.py `_assemble`); (2) raised
   MaxIterations/Tolerance (dfedge remedy); (3) sparse edge-masked witness
   recovery so the certified bound lambda_max(J - B) is computed at any
   n <= CERTNMAX instead of the paclet's dense n <= 1500 cap. Fixed entries of
   the rescaled LMI: per-vertex diagonal sums to tau, border to 1/Sqrt[s],
   corner to 1, chordal-extension fill to 0.                                   *)
(* ------------------------------------------------------------------------- *)

thetaSparseScaled[g_Graph] := Module[
  {h = IndexGraph[g], n, s, cliques, nc, edgeQ, y, tau, vars, blocks,
   diagTerms, bordTerms, cornVars, fillTerms, cons, sol, tval, theta,
   acc, rules, mMat, upper},
  n = VertexCount[h];
  s = N[n];                                    (* O(1)-conditioning scale *)
  cliques = chordalCliques[h];
  nc = Length[cliques];
  edgeQ = Association[Thread[(Sort /@ (List @@@ EdgeList[h])) -> True]];
  blocks = Table[With[{mm = Length[cliques[[j]]]},
      Table[If[p <= q, y[j, p, q], y[j, q, p]], {p, mm + 1}, {q, mm + 1}]], {j, nc}];
  vars = Prepend[Flatten[Table[With[{mm = Length[cliques[[j]]]},
      Table[y[j, p, q], {p, mm + 1}, {q, p, mm + 1}]], {j, nc}]], tau];
  diagTerms = GroupBy[Flatten[Table[cliques[[j, p]] -> y[j, p, p],
      {j, nc}, {p, Length[cliques[[j]]]}]], First -> Last];
  bordTerms = GroupBy[Flatten[Table[cliques[[j, p]] -> y[j, p, Length[cliques[[j]]] + 1],
      {j, nc}, {p, Length[cliques[[j]]]}]], First -> Last];
  cornVars = Table[y[j, Length[cliques[[j]]] + 1, Length[cliques[[j]]] + 1], {j, nc}];
  fillTerms = GroupBy[Flatten[Table[With[{K = cliques[[j]], mm = Length[cliques[[j]]]},
      Table[If[! KeyExistsQ[edgeQ, Sort[{K[[p]], K[[q]]}]],
          Sort[{K[[p]], K[[q]]}] -> y[j, p, q], Nothing], {p, mm}, {q, p + 1, mm}]], {j, nc}]],
    First -> Last];
  cons = Join[
    (Total[#] == tau) & /@ Values[diagTerms],          (* diag: density units  *)
    (Total[#] == 1/Sqrt[s]) & /@ Values[bordTerms],    (* border: 1/Sqrt[n]    *)
    {Total[cornVars] == 1},
    (Total[#] == 0) & /@ Values[fillTerms],
    VectorGreaterEqual[{#, 0}, {"SemidefiniteCone", Length[#]}] & /@ blocks];
  sol = Check[SemidefiniteOptimization[tau, cons, vars,
      MaxIterations -> OPTMAXITER, Tolerance -> OPTTOL], $Failed,
    {SemidefiniteOptimization::nsolc, SemidefiniteOptimization::maxit}];
  If[sol === $Failed || ! ListQ[sol],
    Return[<|"Theta" -> $Failed, "UpperBound" -> $Failed, "CertGap" -> $Failed,
      "CliqueCount" -> nc, "MaxCliqueSize" -> Max[Length /@ cliques],
      "FillEdges" -> Length[fillTerms], "Scale" -> s, "TauRaw" -> $Failed|>]];
  tval = tau /. sol;
  theta = s tval;                              (* back to original units *)
  (* certificate: recover B = s * (sum_j S'_j) masked to E(g) -- edge-supported
     by construction, so lambda_max(J - B) >= theta(g) is a rigorous
     self-certificate (up to the floating eigensolve) for ANY such B.
     Dispatch[] is essential here: a plain "/. sol" rule list would rescan all
     O(nc) rules per clique -- O(nc^2) at m = 5000 (the paclet original could
     ignore this behind its n <= 1500 dense-certificate cap).                  *)
  sol = Dispatch[sol];
  acc = <||>;
  Do[With[{K = cliques[[j]], Sj = blocks[[j]] /. sol},
     Do[With[{key = Sort[{K[[p]], K[[q]]}]},
        If[KeyExistsQ[edgeQ, key],
          acc[key] = Lookup[acc, Key[key], 0.] + Sj[[p, q]]]],
       {p, Length[K]}, {q, p + 1, Length[K]}]], {j, nc}];
  upper = If[n <= CERTNMAX,
    rules = Join[KeyValueMap[#1 -> s #2 &, acc],
                 KeyValueMap[Reverse[#1] -> s #2 &, acc]];
    mMat = 1. - Normal[SparseArray[rules, {n, n}, 0.]];   (* J - B, dense once *)
    Max[Eigenvalues[mMat]],
    Missing["TooLarge"]];
  <|"Theta" -> theta,
    "UpperBound" -> upper,
    "CertGap" -> If[NumericQ[upper], upper - theta, upper],
    "CliqueCount" -> nc, "MaxCliqueSize" -> Max[Length /@ cliques],
    "FillEdges" -> Length[fillTerms], "Scale" -> s, "TauRaw" -> tval|>];

(* ------------------------------------------------------------------------- *)
(* lovaszThetaSparseVerbatim[g]: the paclet's LovaszThetaSparse[g, "Value"]
   copied VERBATIM from BlackBox/Kernel/BlackBox.wl (only the name differs, to
   avoid any context shadowing). NOT used by the production scan below -- it is
   carried for provenance and for the local validation driver's transcription-
   fidelity cross-check against the paclet (identical program, identical
   options => identical result). The original file is not modified.            *)
(* ------------------------------------------------------------------------- *)

lovaszThetaSparseVerbatim[g_Graph] := Module[
  {h = IndexGraph[g], n, cliques, nc, edgeQ, y, t, vars, blocks, diagTerms, bordTerms,
   cornVars, fillTerms, cons, sol},
  n = VertexCount[h];
  cliques = chordalCliques[h];
  nc = Length[cliques];
  edgeQ = Association[Thread[(Sort /@ (List @@@ EdgeList[h])) -> True]];
  blocks = Table[With[{m = Length[cliques[[j]]]},
      Table[If[p <= q, y[j, p, q], y[j, q, p]], {p, m + 1}, {q, m + 1}]], {j, nc}];
  vars = Prepend[Flatten[Table[With[{m = Length[cliques[[j]]]},
      Table[y[j, p, q], {p, m + 1}, {q, p, m + 1}]], {j, nc}]], t];
  diagTerms = GroupBy[Flatten[Table[cliques[[j, p]] -> y[j, p, p],
      {j, nc}, {p, Length[cliques[[j]]]}]], First -> Last];
  bordTerms = GroupBy[Flatten[Table[cliques[[j, p]] -> y[j, p, Length[cliques[[j]]] + 1],
      {j, nc}, {p, Length[cliques[[j]]]}]], First -> Last];
  cornVars = Table[y[j, Length[cliques[[j]]] + 1, Length[cliques[[j]]] + 1], {j, nc}];
  fillTerms = GroupBy[Flatten[Table[With[{K = cliques[[j]], m = Length[cliques[[j]]]},
      Table[If[! KeyExistsQ[edgeQ, Sort[{K[[p]], K[[q]]}]],
          Sort[{K[[p]], K[[q]]}] -> y[j, p, q], Nothing], {p, m}, {q, p + 1, m}]], {j, nc}]],
    First -> Last];
  cons = Join[
    (Total[#] == t) & /@ Values[diagTerms],
    (Total[#] == 1) & /@ Values[bordTerms],
    {Total[cornVars] == 1},
    (Total[#] == 0) & /@ Values[fillTerms],
    VectorGreaterEqual[{#, 0}, {"SemidefiniteCone", Length[#]}] & /@ blocks];
  sol = SemidefiniteOptimization[t, cons, vars, MaxIterations -> 500];
  t /. sol];

(* ------------------------------------------------------------------------- *)
(* MAIN LOOP: ascending m, per-m log line, PASS/FAIL/INFO increment tags       *)
(* ------------------------------------------------------------------------- *)

results = {};
prevM = Null; prevTheta = Null;
Do[
  Module[{msgs0, t, res, incr, dev, tag, mem, newMsgs, dfedgeQ},
    msgs0 = Length[$MessageList];
    {t, res} = AbsoluteTiming[thetaSparseScaled[transChainWL[m]]];
    mem = MaxMemoryUsed[];   (* session max -- ascending m, so the current m dominates *)
    newMsgs = ToString /@ Drop[$MessageList, msgs0];
    dfedgeQ = AnyTrue[newMsgs, StringContainsQ[#, "dfedge"] &];
    If[! NumericQ[res["Theta"]],
      tag = "SOLVE-FAILED";
      incr = Missing["SolveFailed"]; dev = Missing["SolveFailed"],
      incr = If[prevM === Null, Missing["FirstPoint"],
        (res["Theta"] - prevTheta)/(m - prevM)];
      dev = If[NumericQ[incr], Abs[incr - tauStarN], Missing["FirstPoint"]];
      tag = Which[
        ! NumericQ[incr], "N/A (first point, no increment)",
        m < BULKMINM, "INFO (m < 500: boundary-transient regime, not scored)",
        dev < BULKTOL, "PASS",
        True, "FAIL"]];
    Print["m = ", m, " (n = ", 3 m + 2, "):"];
    Print["  theta          = ", ToString[res["Theta"], InputForm]];
    Print["  density th/m   = ", If[NumericQ[res["Theta"]],
      ToString[res["Theta"]/m, InputForm], "n/a"]];
    Print["  increment      = ", If[NumericQ[incr], ToString[incr, InputForm],
      ToString[incr]], "   |incr - tauStar| = ",
      If[NumericQ[dev], ToString[dev, InputForm], ToString[dev]]];
    Print["  certified ub   = ", ToString[res["UpperBound"], InputForm],
      "   certgap = ", ToString[res["CertGap"], InputForm]];
    Print["  cliques        = ", res["CliqueCount"], " (max size ",
      res["MaxCliqueSize"], ", fill pairs ", res["FillEdges"], ")"];
    Print["  time           = ", ToString[t, InputForm], " s,  MaxMemoryUsed = ",
      mem, " bytes (", N[mem/2.^30, 4], " GiB)"];
    Print["  solver msgs    = ", If[newMsgs === {}, "none", newMsgs],
      "   dfedge seen = ", dfedgeQ];
    Print["  TAG: ", tag];
    AppendTo[results, <|"m" -> m, "n" -> 3 m + 2,
      "Theta" -> res["Theta"],
      "Density" -> If[NumericQ[res["Theta"]], res["Theta"]/m, res["Theta"]],
      "Increment" -> incr, "AbsDevFromTauStar" -> dev, "Tag" -> tag,
      "UpperBound" -> res["UpperBound"], "CertGap" -> res["CertGap"],
      "CliqueCount" -> res["CliqueCount"], "MaxCliqueSize" -> res["MaxCliqueSize"],
      "FillEdges" -> res["FillEdges"],
      "TimeSeconds" -> t, "MaxMemoryUsedBytes" -> mem,
      "SolverMessages" -> newMsgs, "DfedgeSeen" -> dfedgeQ|>];
    If[NumericQ[res["Theta"]], prevM = m; prevTheta = res["Theta"]]],
  {m, MVALUES}];

(* ------------------------------------------------------------------------- *)
(* SUMMARY                                                                    *)
(* ------------------------------------------------------------------------- *)

bulkScored   = Select[results, MemberQ[{"PASS", "FAIL"}, #Tag] &];
allBulkPass  = bulkScored =!= {} && AllTrue[bulkScored, #Tag === "PASS" &];
anyDfedge    = AnyTrue[results, TrueQ[#DfedgeSeen] &];
anySolveFail = AnyTrue[results, #Tag === "SOLVE-FAILED" &];
Print["=== SUMMARY ==="];
Print["tauStar (15 digits)     = ", ToString[N[tauStar, 15], InputForm]];
Print["bulk (m >= ", BULKMINM, ") increments all PASS: ", allBulkPass,
  "  (", Length[bulkScored], " scored)"];
Print["any dfedge warnings     : ", anyDfedge];
Print["any solve failures      : ", anySolveFail];
Print["session MaxMemoryUsed   = ", MaxMemoryUsed[], " bytes (",
  N[MaxMemoryUsed[]/2.^30, 4], " GiB)"];

(* ------------------------------------------------------------------------- *)
(* FINAL EXPRESSION: self-contained diagnostic association (the pattern of
   GenerateEpsilonCertificate10_cloud.wl's tail) -- RemoteBatchSubmit captures
   this as EvaluationResult, so nothing depends on file retrieval.             *)
(* ------------------------------------------------------------------------- *)

<|
  "LedgerKey" -> "D3_transChainNumerical",
  "Conjecture" -> "open trans-chain bulk density -> tauStar = Root[49x^3-128x^2-75x+218, 2]",
  "TauStar" -> tauStar,
  "TauStarN15" -> N[tauStar, 15],
  "MValues" -> MVALUES,
  "BulkTolerance" -> BULKTOL,
  "BulkMinM" -> BULKMINM,
  "SolverOptions" -> <|"MaxIterations" -> OPTMAXITER, "Tolerance" -> OPTTOL,
    "Conditioning" -> "density-unit diagonal (tau = theta/n) + 1/Sqrt[n] Schur border, theta = n*tau"|>,
  "Results" -> results,
  "AllBulkPass" -> allBulkPass,
  "AnyDfedge" -> anyDfedge,
  "AnySolveFailure" -> anySolveFail,
  "SessionMaxMemoryUsedBytes" -> MaxMemoryUsed[],
  "Version" -> $Version,
  "ProcessorCount" -> $ProcessorCount,
  "Timestamp" -> DateString["ISODateTime"]
|>
