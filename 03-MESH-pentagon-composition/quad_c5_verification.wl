(* quad_c5_verification.wl -- MESH-006 closure check.

   The project reconstructed the 8-vertex maximum-gap exclusivity graph
   "Quad-C5" (four edge-sharing pentagons, every edge in exactly two) from its
   own composition grammar (fem_study.py::quad_c5_search, results in
   fem_study_results.json) and matched the published gap to printed precision,
   but never fetched the paper's actual adjacency data.  This script closes
   that gap: it builds BOTH graphs -- the project's reconstruction and the
   literal edge list printed in the paper -- and verifies isomorphism, alpha,
   Lovasz theta (paclet SDP + an independent dual-formulation SDP), the gap,
   and the paper's stated four-pentagon two-fold edge cover.

   Published source (fetched 2026-07-13 from arxiv.org/abs/2605.12828 and
   ar5iv.labs.arxiv.org/html/2605.12828):
     Tamer, Mustecaplioglu, Dizdar, Gedik,
     "The Quad-C5 Graph: Maximum Contextuality Gap on Eight Vertices",
     arXiv:2605.12828 (2026).
     Eq. (10): V = {0,...,7},
               E = {(0,3),(0,5),(1,4),(1,6),(2,5),(2,6),(2,7),(3,6),(3,7),(4,7)}
     Degree sequence (2,2,2,2,3,3,3,3); hubs {2,3,6,7}, leaves {0,1,4,5}.
     Table 1:  theta = 3.46784, alpha = 3, Delta = 0.46784
               (Wagner graph comparison: theta = 3.41421, Delta = 0.41421)
     Table 5:  theta bracket [3.46784373, 3.46784378]
     Table 6:  pentagons on {0,2,3,5,6}, {0,2,3,5,7}, {1,2,4,6,7}, {1,3,4,6,7}
     Sec. IV:  qutrit value eta_3 = 1 + Sqrt[5] ~ 3.23607; full theta at d = 4.

   Project reconstruction (fem_study.py stage_sanity / fem_study_results.json):
     edges {0,1},{0,4},{0,5},{1,2},{1,6},{2,3},{2,5},{3,4},{5,7},{6,7}
     alpha = 3, theta = 3.467843730944291, gap = 0.4678437309442911
     (census: 672 pentagon 5-cycles on 8 vertices -> 90 two-fold composites
      -> classes alpha=3: 30 graphs, alpha=4: 60 graphs; winner = alpha 3 class)

   Run:  wolframscript -file quad_c5_verification.wl
   Prints PASS/FAIL per check and "ALL PASS: True/False"; exit code 0 on pass. *)

PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName], "..", "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"];

projEdges  = {{0,1},{0,4},{0,5},{1,2},{1,6},{2,3},{2,5},{3,4},{5,7},{6,7}};
paperEdges = {{0,3},{0,5},{1,4},{1,6},{2,5},{2,6},{2,7},{3,6},{3,7},{4,7}};
paperPentagons = {{0,2,3,5,6},{0,2,3,5,7},{1,2,4,6,7},{1,3,4,6,7}};
projTheta  = 3.467843730944291;   (* fem_study_results.json *)
paperGapPrinted = 46784/100000;   (* Delta = 0.46784, Table 1/2, 5 printed dp *)
paperBracket = {3.46784373, 3.46784378};  (* Table 5 *)

gP = Graph[Range[0, 7], UndirectedEdge @@@ projEdges];
gQ = Graph[Range[0, 7], UndirectedEdge @@@ paperEdges];

results = <||>;
check[name_, cond_, detail_: Null] := Module[{ok = TrueQ[cond]},
  results[name] = ok;
  Print[If[ok, "PASS  ", "FAIL  "], name,
    If[detail === Null, "", "   |   " <> ToString[InputForm[detail]]]]];

(* -- 1. both graphs are 8 vertices / 10 edges with the paper's degree sequence -- *)
degSeq = {2, 2, 2, 2, 3, 3, 3, 3};
check["sizes: both graphs have 8 vertices, 10 edges",
  VertexCount[gP] == VertexCount[gQ] == 8 && EdgeCount[gP] == EdgeCount[gQ] == 10,
  {VertexCount[gP], EdgeCount[gP], VertexCount[gQ], EdgeCount[gQ]}];
check["degree sequences both equal paper's (2,2,2,2,3,3,3,3)",
  Sort[VertexDegree[gP]] === degSeq && Sort[VertexDegree[gQ]] === degSeq,
  {Sort[VertexDegree[gP]], Sort[VertexDegree[gQ]]}];

(* -- 2. THE MESH-006 QUESTION: is the reconstruction the published graph? -- *)
isoQ = IsomorphicGraphQ[gP, gQ];
isoMap = If[isoQ, First[FindGraphIsomorphism[gP, gQ]], "none"];
check["ISOMORPHIC: project reconstruction == published Quad-C5 (Eq. 10)", isoQ, isoMap];

(* -- 3. classical bound alpha -- *)
aP = IndependenceNumber[gP]; aQ = IndependenceNumber[gQ];
check["alpha = 3 for both (paper Table 1: alpha = 3)", aP == 3 && aQ == 3, {aP, aQ}];

(* -- 4. quantum bound theta: paclet SDP (primal, SemidefiniteOptimization) -- *)
thP = LovaszTheta[gP]; thQ = LovaszTheta[gQ];
check["theta(project) == theta(paper graph) to 1e-6", Abs[thP - thQ] < 10^-6, {thP, thQ}];
check["theta inside paper Table 5 bracket [3.46784373, 3.46784378] (tol 1e-6)",
  paperBracket[[1]] - 10^-6 <= thQ <= paperBracket[[2]] + 10^-6, thQ];
check["theta matches project's recorded 3.467843730944291 to 1e-6",
  Abs[thP - projTheta] < 10^-6, thP];

(* -- 5. independent theta route: Lovasz DUAL, theta = min lambda_max-style SDP
      min t  s.t.  t I + B - J >= 0 (PSD),  B symmetric, supported on edges only.
      Shares no code with the paclet's primal trace formulation. -- *)
thetaDual[g_Graph] := Module[{n = VertexCount[g], h = IndexGraph[g], ed, B, t, b, vars, cons, sol},
  ed = Sort /@ (List @@@ EdgeList[h]);
  B = ConstantArray[0, {n, n}];
  Do[B[[e[[1]], e[[2]]]] = b @@ e; B[[e[[2]], e[[1]]]] = b @@ e, {e, ed}];
  vars = Prepend[b @@@ ed, t];
  cons = {VectorGreaterEqual[
    {t IdentityMatrix[n] + B - ConstantArray[1, {n, n}], 0}, {"SemidefiniteCone", n}]};
  sol = SemidefiniteOptimization[t, cons, vars, MaxIterations -> 300];
  t /. sol];
thDual = thetaDual[gQ];
check["independent dual SDP reproduces theta to 1e-5", Abs[thDual - thQ] < 10^-5, thDual];

(* -- 6. the gap Delta = theta - alpha vs project number and paper's print -- *)
gap = thQ - aQ;
check["gap matches project's 0.4678437309442911 to 1e-6",
  Abs[gap - (projTheta - 3)] < 10^-6, gap];
check["gap rounds to paper's printed Delta = 0.46784 (5 dp)",
  Abs[gap - paperGapPrinted] < 5 10^-6, {gap, N[paperGapPrinted]}];
check["gap exceeds paper's Wagner-graph benchmark Delta = 0.41421",
  gap > 0.41421, gap];

(* -- 7. paper's structural claim: four pentagons, every edge in exactly two -- *)
pentEdges = (Sort /@ (List @@@ EdgeList[Subgraph[gQ, #]])) & /@ paperPentagons;
check["each of paper's four vertex sets (Table 6) induces a C5 in Eq.-10 graph",
  AllTrue[paperPentagons, IsomorphicGraphQ[Subgraph[gQ, #], CycleGraph[5]] &],
  Length /@ pentEdges];
tal = Tally[Flatten[pentEdges, 1]];
check["the four pentagons cover each of the 10 edges EXACTLY twice",
  Sort[tal[[All, 1]]] === Sort[Sort /@ (List @@@ EdgeList[gQ])] &&
    Union[tal[[All, 2]]] === {2}, Union[tal[[All, 2]]]];

(* -- 8. isomorphism-invariant cross-check: identical 5-cycle census -- *)
c5P = Length[FindCycle[gP, {5}, All]]; c5Q = Length[FindCycle[gQ, {5}, All]];
check["same number of 5-cycles in both graphs", c5P == c5Q, {c5P, c5Q}];

(* -- 9. consistency of the paper's qutrit value with theta (Sec. IV) -- *)
check["paper's qutrit value eta_3 = 1+Sqrt[5] = 3.23607 < theta (d=4 needed)",
  N[1 + Sqrt[5]] < thQ, {N[1 + Sqrt[5]], thQ}];

allOK = And @@ Values[results];
Print["ALL PASS: ", allOK];
If[!allOK, Print["failed: ", Keys[Select[results, ! # &]]]];
Exit[If[allOK, 0, 1]];
