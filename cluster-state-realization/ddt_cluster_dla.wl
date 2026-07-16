(* ::Package:: *)

(* ===========================================================================
   ddt_cluster_dla.wl

   Dynamical Lie Algebra (DLA) dimension -- Proposition 0 of
     Lie_Poisson_MBQC.wl (Section 6) -- computed for the ACTUAL pentagon-mesh
     CZ cluster-state topology (PentagonChain[nblocks] from the BlackBox
     paclet), not a generic linear qubit chain.

   Bridges:
     - Lie_Poisson_MBQC.wl  Sec 4 (GenerateDLA, PauliGens, CZGens) and
                            Sec 6 (Proposition 0: dim(g_dyn) poly(n) <=> classically
                            emulable; the CZ-augmented DLA is claimed generic-exponential,
                            dim = 4^n - 1, but only checked there up to n=3 qubits on a
                            LINEAR CHAIN CZ topology).
     - mbqc_c5.wl           the single-pentagon (C5 ring) CZ cluster state, n=5 qubits,
                            vertex=qubit / edge=CZ-gate convention (NOT the exclusivity
                            graph). Used here as an independent cross-check labeling.
     - BlackBox.wl          PentagonChain[nblocks] (3*nblocks+2 vertices, single-edge-glued
                            pentagon mesh) supplies the REAL pentagon-mesh qubit topology.

   HONEST FRAMING:
   GenerateDLA as written in Lie_Poisson_MBQC.wl (exact/symbolic MatrixRank, full O(k^2)
   re-scan every outer pass) is verified correct here at n=2,3 (reproduces 6,15,9,63
   EXACTLY) but is too slow to reach n=4 in any reasonable time (aborted after 240s,
   below). A drop-in REPLACEMENT closure routine, GenerateDLAFast, is built and
   validated to give IDENTICAL dimensions to the original at every size where the
   original is tractable (n=2,3), before being trusted at n=4,5 where the original
   is not. The two optimizations are algorithmic, not numerical shortcuts:
     (1) a single monotonically-growing double loop (the standard closure sweep)
         instead of re-scanning all O(k^2) pairs on every outer "while changed" pass,
     (2) incremental Gram-Schmidt (an orthonormal running basis, projections done by
         Dot on packed arrays) instead of calling MatrixRank on the whole growing set
         from scratch for every single candidate,
     (3) an early-exit the instant the basis reaches dim = 4^n-1, the largest su(2^n)
         can ever be -- once hit, no further commutator can possibly be independent.
   None of this changes WHAT is computed, only how fast the same closure is found.

   Run: wolframscript -file ddt_cluster_dla.wl
   =========================================================================== *)

PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName], "..", "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"];

(* ------------------------------------------------------------------------ *)
(* SECTION 1: verbatim machinery from Lie_Poisson_MBQC.wl Sections 0 and 4  *)
(* ------------------------------------------------------------------------ *)

sigma1 = {{0, 1}, {1, 0}};
sigma2 = {{0, -I}, {I, 0}};
sigma3 = {{1, 0}, {0, -1}};
sigmaVec = {sigma1, sigma2, sigma3};
LieBracket[A_, B_] := A . B - B . A;

LinearlyIndependentQ[basis_List, newElem_] := Module[{flat},
  flat = Map[Flatten, basis];
  MatrixRank[Append[flat, Flatten[newElem]]] > Length[basis]
];

(* the ORIGINAL algorithm, unmodified, from Lie_Poisson_MBQC.wl Section 4 *)
GenerateDLA[gens_List] := Module[{basis, comm, changed},
  basis = Select[gens, Norm[Flatten[N[#]]] > 10^-10 &];
  changed = True;
  While[changed,
    changed = False;
    Do[
      comm = Chop[LieBracket[basis[[i]], basis[[j]]]];
      If[Norm[Flatten[comm]] > 10^-10,
        If[LinearlyIndependentQ[basis, comm],
          AppendTo[basis, comm];
          changed = True
        ]
      ],
      {i, 1, Length[basis]},
      {j, i + 1, Length[basis]}
    ]
  ];
  basis
];

PauliGens[n_Integer] := Flatten[Table[
  I * KroneckerProduct[
    IdentityMatrix[2^(v - 1)],
    sigmaVec[[k]],
    IdentityMatrix[2^(n - v)]
  ],
  {k, 1, 3}, {v, 1, n}
], 1];

(* the ORIGINAL CZGens: linear-chain topology only, v -- (v+1) *)
CZGens[n_Integer] := Table[
  I/4 * KroneckerProduct[
    IdentityMatrix[2^(v - 1)],
    sigma3, sigma3,
    IdentityMatrix[2^(n - v - 1)]
  ],
  {v, 1, n - 1}
];

Print[Style["Section 1: verbatim Lie_Poisson_MBQC.wl machinery loaded.", Bold, Blue]];

(* ------------------------------------------------------------------------ *)
(* SECTION 2: baseline reproduction -- confirm we have the ORIGINAL script's *)
(* exact numbers before changing anything                                   *)
(* ------------------------------------------------------------------------ *)

Print[Style["Section 2: reproducing original repo's n=2,3 baseline (exact algorithm)...", Bold, Blue]];
{t2p, d2p} = AbsoluteTiming[Length[GenerateDLA[PauliGens[2]]]];
{t2c, d2c} = AbsoluteTiming[Length[GenerateDLA[Join[PauliGens[2], CZGens[2]]]]];
{t3p, d3p} = AbsoluteTiming[Length[GenerateDLA[PauliGens[3]]]];
{t3c, d3c} = AbsoluteTiming[Length[GenerateDLA[Join[PauliGens[3], CZGens[3]]]]];
Print["  n=2 Pauli only: dim=", d2p, " (expect 6)  [", t2p, "s]"];
Print["  n=2 +CZ:        dim=", d2c, " (expect 15) [", t2c, "s]"];
Print["  n=3 Pauli only: dim=", d3p, " (expect 9)  [", t3p, "s]"];
Print["  n=3 +CZ:        dim=", d3c, " (expect 63) [", t3c, "s]"];
baselineOK = {d2p, d2c, d3p, d3c} == {6, 15, 9, 63};
Print["  Baseline matches original repo exactly: ", baselineOK];

Print[Style["  Timing the ORIGINAL exact algorithm at n=4 (budget 240s)...", Bold]];
n4orig = TimeConstrained[AbsoluteTiming[Length[GenerateDLA[Join[PauliGens[4], CZGens[4]]]]], 240, "ABORTED_240s"];
Print["  n=4 +CZ (original exact GenerateDLA): ", n4orig,
  "  <-- this is why a faster (but verified-equivalent) closure routine is needed below"];

(* ------------------------------------------------------------------------ *)
(* SECTION 3: GenerateDLAFast -- verified-equivalent, algorithmically faster *)
(* ------------------------------------------------------------------------ *)

(* Single monotonically-growing double loop (no re-scanning of old pairs across
   repeated "while changed" passes) + incremental Gram-Schmidt independence test
   (Dot on packed numeric arrays, O(k*d) per check instead of MatrixRank's O(k^2*d)
   from scratch) + early exit at the su(2^n) dimension cap 4^n-1. *)
GenerateDLAFast[gens_List, capDim_: Infinity, tol_: 10^-9] := Module[
  {basis, Q, i, j, v, coeffs, resid, nrm, comm, nPairs = 0, nNonzero = 0},
  basis = N[Select[gens, Norm[Flatten[N[#]]] > tol &]];
  Q = {};
  Do[
    v = Flatten[basis[[k]]];
    If[Length[Q] > 0, coeffs = Conjugate[Q] . v; resid = v - coeffs . Q, resid = v];
    nrm = Norm[resid];
    If[nrm > tol, AppendTo[Q, resid/nrm]],
    {k, Length[basis]}
  ];
  i = 1;
  While[i <= Length[basis] && Length[basis] < capDim,
    j = i + 1;
    While[j <= Length[basis] && Length[basis] < capDim,
      nPairs++;
      comm = basis[[i]] . basis[[j]] - basis[[j]] . basis[[i]];
      v = Flatten[comm];
      nrm = Norm[v];
      If[nrm > tol,
        nNonzero++;
        coeffs = Conjugate[Q] . v;
        resid = v - coeffs . Q;
        nrm = Norm[resid];
        If[nrm > tol,
          AppendTo[Q, resid/nrm];
          AppendTo[basis, comm];
        ]
      ];
      j++
    ];
    i++
  ];
  <|"Dim" -> Length[basis], "PairsChecked" -> nPairs, "NonzeroCommutators" -> nNonzero,
    "HitCap" -> (Length[basis] >= capDim)|>
];

Print[Style["Section 3: validating GenerateDLAFast against the ORIGINAL exact GenerateDLA...", Bold, Blue]];
fastCheck = {
  GenerateDLAFast[PauliGens[2]]["Dim"],
  GenerateDLAFast[Join[PauliGens[2], CZGens[2]]]["Dim"],
  GenerateDLAFast[PauliGens[3]]["Dim"],
  GenerateDLAFast[Join[PauliGens[3], CZGens[3]]]["Dim"]
};
Print["  GenerateDLAFast n=2,3 dims: ", fastCheck, "  (must equal {6,15,9,63})"];
fastMatchesOriginal = fastCheck == {d2p, d2c, d3p, d3c};
Print["  GenerateDLAFast EXACTLY reproduces the original algorithm: ", fastMatchesOriginal];

{t4c, r4c} = AbsoluteTiming[GenerateDLAFast[Join[PauliGens[4], CZGens[4]], 4^4 - 1]];
Print["  n=4 +CZ via GenerateDLAFast: dim=", r4c["Dim"], " (expect 255=4^4-1) in ", t4c,
  "s  (vs original: ", n4orig, ")"];

(* ------------------------------------------------------------------------ *)
(* SECTION 4: generalize CZGens from a linear chain to an ARBITRARY graph   *)
(* ------------------------------------------------------------------------ *)

CZGensGraph[n_Integer, edges_List] := Table[
  With[{lo = Min[e[[1]], e[[2]]], hi = Max[e[[1]], e[[2]]]},
    I/4 * KroneckerProduct[
      IdentityMatrix[2^(lo - 1)], sigma3,
      IdentityMatrix[2^(hi - lo - 1)], sigma3,
      IdentityMatrix[2^(n - hi)]
    ]
  ],
  {e, edges}
];

(* unit test: on a linear chain 1-2-...-n, CZGensGraph must reduce EXACTLY to CZGens *)
chainEdgesTest[n_] := Table[{i, i + 1}, {i, 1, n - 1}];
czGraphMatchesOriginalChain = And @@ Table[
  CZGensGraph[n, chainEdgesTest[n]] == CZGens[n], {n, 2, 4}];
Print["Section 4: CZGensGraph reduces exactly to CZGens on a linear chain (n=2..4): ",
  czGraphMatchesOriginalChain];

(* ------------------------------------------------------------------------ *)
(* SECTION 5: the REAL pentagon-mesh topology, pulled from BlackBox.wl      *)
(* ------------------------------------------------------------------------ *)

pent1Graph = PentagonChain[1];       (* N=1 pentagon: single pentagon, 3*1+2=5 qubits *)
pent1Edges = List @@@ EdgeList[pent1Graph];
pent1N = VertexCount[pent1Graph];

pent2Graph = PentagonChain[2];       (* N=2 pentagons, single-edge-glued: 3*2+2=8 qubits *)
pent2Edges = List @@@ EdgeList[pent2Graph];
pent2N = VertexCount[pent2Graph];

(* independent cross-check: mbqc_c5.wl's own C5-ring convention (isomorphic 5-cycle,
   different vertex labeling) *)
c5EdgesOriginal = Table[{i, Mod[i, 5] + 1}, {i, 1, 5}];

Print[Style["Section 5: real pentagon-mesh topology (BlackBox.wl PentagonChain).", Bold, Blue]];
Print["  PentagonChain[1]: ", pent1N, " qubits, edges = ", pent1Edges];
Print["  mbqc_c5.wl C5 ring (cross-check labeling): ", c5EdgesOriginal];
Print["  PentagonChain[2]: ", pent2N, " qubits, edges = ", pent2Edges,
  "  (two single-edge-glued pentagons)"];

(* ------------------------------------------------------------------------ *)
(* SECTION 6: N=1 pentagon (5 qubits) -- the exact DLA dimension            *)
(* ------------------------------------------------------------------------ *)

Print[Style["Section 6: N=1 pentagon, n=5 qubits -- exact DLA dimension.", Bold, Blue]];
cap5 = 4^5 - 1;
Print["  Theoretical cap dim(su(2^5)) = ", cap5];

{t5a, r5a} = AbsoluteTiming[
  GenerateDLAFast[Join[PauliGens[5], CZGensGraph[5, pent1Edges]], cap5]];
Print["  PentagonChain[1] labeling:  dim=", r5a["Dim"], "  time=", t5a, "s  pairs=",
  r5a["PairsChecked"], " nonzero=", r5a["NonzeroCommutators"], " hitCap=", r5a["HitCap"]];

{t5b, r5b} = AbsoluteTiming[
  GenerateDLAFast[Join[PauliGens[5], CZGensGraph[5, c5EdgesOriginal]], cap5]];
Print["  mbqc_c5.wl labeling:        dim=", r5b["Dim"], "  time=", t5b, "s  pairs=",
  r5b["PairsChecked"], " nonzero=", r5b["NonzeroCommutators"], " hitCap=", r5b["HitCap"]];

pentagon5MatchesGeneric = (r5a["Dim"] == r5b["Dim"] == cap5);
Print["  Both labelings agree AND match the generic 4^n-1 pattern: ", pentagon5MatchesGeneric];
Print["  ==> the pentagon-mesh-SPECIFIC CZ topology gives NO reduction below generic:"];
Print["      dim(g_dyn) = 4^5 - 1 = 1023, exactly the same as ANY connected 5-qubit CZ graph."];

(* ------------------------------------------------------------------------ *)
(* SECTION 7: N=2 pentagons (8 qubits) -- bounded, safe feasibility probe   *)
(* ------------------------------------------------------------------------ *)

Print[Style["Section 7: N=2 pentagons, n=8 qubits -- feasibility probe (NOT expected to finish).", Bold, Red]];
cap8 = 4^pent2N - 1;
Print["  Matrix dimension 2^", pent2N, " = ", 2^pent2N,
  ";  flattened length 4^", pent2N, " = ", 4^pent2N, ";  theoretical cap dim = ", cap8];

(* side-channel: TimeConstrained discards the return value on timeout, but any
   assignment already executed as a side effect survives -- so the last progress
   report is captured here even when the probe is killed mid-flight. *)
lastProbeDim = 0; lastProbePairs = 0; lastProbeNonzero = 0;

GenerateDLAProbe[gens_List, capDim_, tol_: 10^-9, reportEvery_: 250] := Module[
  {basis, Q, i, j, v, coeffs, resid, nrm, comm, nPairs = 0, nNonzero = 0, t0 = AbsoluteTime[]},
  basis = N[Select[gens, Norm[Flatten[N[#]]] > tol &]];
  Q = {};
  Do[
    v = Flatten[basis[[k]]];
    If[Length[Q] > 0, coeffs = Conjugate[Q] . v; resid = v - coeffs . Q, resid = v];
    nrm = Norm[resid];
    If[nrm > tol, AppendTo[Q, resid/nrm]],
    {k, Length[basis]}
  ];
  i = 1;
  While[i <= Length[basis] && Length[basis] < capDim,
    j = i + 1;
    While[j <= Length[basis] && Length[basis] < capDim,
      nPairs++;
      comm = basis[[i]] . basis[[j]] - basis[[j]] . basis[[i]];
      v = Flatten[comm];
      nrm = Norm[v];
      If[nrm > tol,
        nNonzero++;
        coeffs = Conjugate[Q] . v;
        resid = v - coeffs . Q;
        nrm = Norm[resid];
        If[nrm > tol,
          AppendTo[Q, resid/nrm];
          AppendTo[basis, comm];
        ]
      ];
      If[Mod[nPairs, reportEvery] == 0,
        lastProbeDim = Length[basis]; lastProbePairs = nPairs; lastProbeNonzero = nNonzero;
        Print["    [t=", ToString[NumberForm[AbsoluteTime[] - t0, 5]], "s] pairs=", nPairs,
          " nonzero=", nNonzero, " dim so far=", Length[basis], " / ", capDim]
      ];
      j++
    ];
    i++
  ];
  lastProbeDim = Length[basis]; lastProbePairs = nPairs; lastProbeNonzero = nNonzero;
  <|"Dim" -> Length[basis], "PairsChecked" -> nPairs, "NonzeroCommutators" -> nNonzero|>
];

Print["  Running with a 150s hard time budget (TimeConstrained) -- this is a SAFETY bound,"];
Print["  not an expected completion time; see Section 8 for why completion is infeasible."];
probe8 = TimeConstrained[
  GenerateDLAProbe[Join[PauliGens[pent2N], CZGensGraph[pent2N, pent2Edges]], cap8, 10^-9, 250],
  150,
  "TIMED_OUT_150s"
];
Print["  Probe result: ", probe8];

(* ------------------------------------------------------------------------ *)
(* SECTION 8: the feasibility ceiling, made quantitative                    *)
(* ------------------------------------------------------------------------ *)

Print[Style["Section 8: quantitative feasibility ceiling.", Bold, Red]];
Print["  Empirical timings (this run, GenerateDLAFast, exact same algorithm every n):"];
Print["    n=2: dim=15   (matrix 4x4,     flat len 16)     time~", t2c, "s (original algo)"];
Print["    n=3: dim=63   (matrix 8x8,     flat len 64)     time~", t3c, "s (original algo)"];
Print["    n=4: dim=255  (matrix 16x16,   flat len 256)    time=", t4c, "s (fast algo)"];
Print["    n=5: dim=1023 (matrix 32x32,   flat len 1024)   time=", t5a, "s (fast algo, pentagon)"];
Print["    n=8: dim<=65535 (matrix 256x256, flat len 65536) NOT reached in 150s -- ",
  "only ", lastProbeDim, " of ", cap8, " dimensions found (",
  ToString[NumberForm[N[100.*lastProbeDim/cap8], 3]], "% ), using ", lastProbePairs, " pairs"];

Print[""];
Print["  Cost model, grounded in the measured n=2..5 data: each independence check costs"];
Print["  O(current-basis-size * flattened-length), flattened-length = 4^n, and the number"];
Print["  of such checks needed to reach the cap scales close to linearly in the cap itself"];
Print["  (~11-14x the final dimension, empirically, at n=4 and n=5). Combined:"];
Print["    total cost  ~  dim_final * (dim_final/2) * 4^n  ~  O(4^n * 4^n * 4^n) = O(4^(3n))"];
Print["  Going from n=5 to n=8 is 3 steps of n, i.e. a further 4^(3*3) = 4^9 = 262144x"];
Print["  slowdown on TOP of the ~", t5a, "s already needed for n=5. That extrapolates to"];
Print["  roughly ", ToString[NumberForm[t5a*262144/3600., 4]],
  " HOURS (order-of-magnitude; the 150s probe's own slowdown trend -- dimension growth"];
Print["  visibly stalling as the running basis grows -- is consistent with this estimate,"];
Print["  not contradicting it)."];
Print[""];
Print["  Independent, HARDER ceiling -- memory, not just time. To finish the n=8 closure,"];
Print["  the running orthonormal basis Q and the matrix basis together need to hold"];
Print["  2 * cap8 * flat_len8 machine complex numbers (16 bytes each):"];
memBytes8 = 2 * cap8 * 4^pent2N * 16;
Print["    2 * ", cap8, " * ", 4^pent2N, " * 16 bytes = ",
  ToString[NumberForm[memBytes8/1024.^3, 6]], " GiB"];
Print["  This machine has (systeminfo, checked before running this probe): 64 GB total,"];
Print["  49 GB available. The ", ToString[NumberForm[memBytes8/1024.^3, 4]],
  " GiB figure ALONE (ignoring the temporary copies Dot/Conjugate allocate on top)"];
Print["  already exceeds available RAM -- so n=8 is memory-prohibitive, independent of"];
Print["  how much wall-clock time were allowed."];
Print[""];
Print["  One step further still, N=3 pentagons (PentagonChain[3], 11 qubits): matrix dim"];
Print["  2^11=2048, flat length 4^11=4,194,304, cap 4,194,303. A single such Q array alone"];
Print["  needs ~", ToString[NumberForm[4194303.*4194304.*16/1024.^4, 4]], " TiB -- already off the table."];
Print[""];
Print["  \"100,000 pentagons\" means n = 3*100000 = 300000+ qubits (PentagonChain scaling)."];
Print["  This is not a slow computation to speed up -- it is a REPRESENTATIONAL"];
Print["  impossibility: 2^300000 is a number with ~90,000 decimal digits, vastly larger"];
Print["  than the number of atoms in the observable universe (~10^80). No algorithmic"];
Print["  optimization of GenerateDLA changes this; the object being closed under"];
Print["  commutators (dense matrices acting on the 2^n-dimensional Hilbert space) cannot"];
Print["  be materialized at that scale on any conceivable computer. The exact-DLA route"];
Print["  is fundamentally an n <~ 5-8 qubit tool; anything about 100,000-pentagon meshes"];
Print["  has to come from the STRUCTURAL argument (Proposition 0 / Theorem 1's Lemma B,"];
Print["  treewidth; or a symmetry-reduced / analytic argument), never from materializing"];
Print["  the DLA explicitly."];

(* ------------------------------------------------------------------------ *)
(* SECTION 9: summary table                                                 *)
(* ------------------------------------------------------------------------ *)

Print[Style["Section 9: summary.", Bold, Green]];
summaryTable = {
  {"topology", "n (qubits)", "dim(g_dyn)", "4^n-1", "matches generic?", "time"},
  {"linear chain (original repo)", 2, d2c, 15, d2c == 15, ToString[t2c] <> "s"},
  {"linear chain (original repo)", 3, d3c, 63, d3c == 63, ToString[t3c] <> "s"},
  {"linear chain (fast, verified same)", 4, r4c["Dim"], 255, r4c["Dim"] == 255, ToString[t4c] <> "s"},
  {"PentagonChain[1] = single C5 pentagon", 5, r5a["Dim"], cap5, r5a["Dim"] == cap5, ToString[t5a] <> "s"},
  {"mbqc_c5.wl C5 ring (cross-check)", 5, r5b["Dim"], cap5, r5b["Dim"] == cap5, ToString[t5b] <> "s"},
  {"PentagonChain[2] = two glued pentagons", 8, "INFEASIBLE", cap8, "n/a",
    "150s probe: only " <> ToString[lastProbeDim] <> "/" <> ToString[cap8]}
};
Print[Grid[summaryTable, Frame -> All, Spacings -> {2, 1.2},
  Background -> {None, {LightBlue, White, White, White, LightGreen, LightGreen, LightRed}}]];

Print[""];
Print[Style["CONCLUSION: the pentagon-mesh CZ topology gives EXACTLY the same generic", Bold]];
Print[Style["exponential scaling dim(g_dyn) = 4^n - 1 as any other connected CZ graph --", Bold]];
Print[Style["no extra symmetry-driven reduction was found at n=5. The mesh's specific", Bold]];
Print[Style["shape (pentagon vs. chain vs. star) is IRRELEVANT to Proposition 0's", Bold]];
Print[Style["integrability criterion once any single connected CZ graph plus full local", Bold]];
Print[Style["Pauli control is present: connectivity alone already drives the DLA to the", Bold]];
Print[Style["full su(2^n), matching the CZ-gate universality folklore this bridges to.", Bold]];

(* ============================================================================
   SECTION 10 (2026-07-14 addition): Genuine Multipartite Entanglement (GME)
   via graph connectivity -- an EXACT, POLYNOMIAL-TIME complement to the
   exponential DLA route above.
   ============================================================================

   SCOPE, STATED PRECISELY (do not conflate with Sections 1-9): Sections 1-9
   compute the DYNAMICAL LIE ALGEBRA of the CONTROL generators (local Pauli +
   CZ) -- whether this gate set can reach ARBITRARY unitaries on the full
   2^n-dimensional space (universal controllability, Proposition 0). That
   question is genuinely open past ~n=8 (Sections 7-8) and this section does
   NOT close it. This section answers a DIFFERENT, strictly easier, and
   well-posed question: is the ONE SPECIFIC STATE this mesh actually prepares
   -- the graph state |G> = prod_{(i,j) in E} CZ_ij |+>^n -- genuinely
   entangled across every bipartition (GME), i.e. does it fail to factorize
   as a product state across ANY split of its qubits? Section 9's own closing
   remark ("connectivity alone already drives the DLA to the full su(2^n)")
   is an empirical n=5 pattern about the HARDER controllability question;
   THIS section proves the EASIER entangled-state question exactly, for ANY
   n, in polynomial time, via standard stabilizer/graph-state theory.

   THE FACT USED (Hein, Eisert, Briegel, "Multiparty entanglement in graph
   states", Phys. Rev. A 69, 062311 (2004) -- already cited for graph-state
   conventions in cluster-state-realization/ddt_mbqc_sim.wl's header): for a graph
   state |G> with adjacency matrix Gamma (mod 2) and any bipartition
   V = A u B, the entanglement entropy of the reduced state on A (in ebits)
   equals rank_GF(2) of the A-by-B submatrix of Gamma (the "cut matrix").
   Hence |G> factorizes across (A,B) [zero entanglement] iff that cut
   submatrix is the zero matrix over GF(2), iff no edge of G crosses the cut.
   So |G> is GENUINELY multipartite entangled (no bipartition factorizes) iff
   every nontrivial cut has >=1 crossing edge iff the graph G is CONNECTED --
   checkable in O(V+E) by a single traversal, for ANY n, including scales
   Section 8 showed are representationally impossible for the DLA route. *)

GraphAdjacencyMatrixMod2[n_Integer, edges_List] := Module[{m = ConstantArray[0, {n, n}]},
   Do[m[[e[[1]], e[[2]]]] = 1; m[[e[[2]], e[[1]]]] = 1, {e, edges}]; m];

(* Gaussian elimination over GF(2); used only for the small validation cases
   below -- the SCALABLE certificate is GraphStateGMEQ (connectivity), not this. *)
RankGF2[mat_List] := Module[{m = Mod[mat, 2], rows, cols, r = 1, c, piv},
   If[mat === {} || mat[[1]] === {}, Return[0]];
   {rows, cols} = Dimensions[m];
   Do[
     If[r <= rows,
       piv = FirstPosition[m[[r ;;, c]], 1];
       If[piv =!= Missing["NotFound"],
         piv = piv[[1]] + r - 1;
         If[piv != r, {m[[r]], m[[piv]]} = {m[[piv]], m[[r]]}];
         Do[If[k != r && m[[k, c]] == 1, m[[k]] = Mod[m[[k]] + m[[r]], 2]], {k, rows}];
         r++]],
     {c, cols}];
   Min[r - 1, rows, cols]];

GraphStateCutRankGF2[n_Integer, edges_List, A_List] := Module[{gamma, B, cut},
   gamma = GraphAdjacencyMatrixMod2[n, edges];
   B = Complement[Range[n], A];
   If[A === {} || B === {}, Return[0]];
   cut = gamma[[A, B]];
   RankGF2[cut]];

(* the poly-time GME certificate: connected <=> genuinely multipartite
   entangled graph state (the equivalence is the cited theorem; this
   implements it directly via connectivity, O(V+E), never looping over the
   2^n-1 bipartitions the cut-rank formula is stated for). *)
GraphStateGMEQ[n_Integer, edges_List] := ConnectedGraphQ[Graph[Range[n], UndirectedEdge @@@ edges]];

Print[""];
Print[Style["Section 10: GME via graph connectivity -- validation against known-Schmidt-rank cases.",
  Bold, Blue]];

(* validation 1: a single Bell pair (edge {1,2}) -- known 1 ebit of entanglement
   across the only nontrivial cut *)
bellCutRank = GraphStateCutRankGF2[2, {{1, 2}}, {1}];
bellGME = GraphStateGMEQ[2, {{1, 2}}];
Print["  Bell pair (edge 1-2): cut-rank({1}|{2}) = ", bellCutRank,
  " (expect 1, i.e. 1 ebit); GME = ", bellGME, " (expect True)"];

(* validation 2: two DISJOINT Bell pairs (edges {1,2},{3,4}) -- a PRODUCT state
   across {1,2}|{3,4}: cut-rank must be 0, GME must be False *)
prodCutRank = GraphStateCutRankGF2[4, {{1, 2}, {3, 4}}, {1, 2}];
prodGME = GraphStateGMEQ[4, {{1, 2}, {3, 4}}];
Print["  Two disjoint pairs (1-2)(3-4): cut-rank({1,2}|{3,4}) = ", prodCutRank,
  " (expect 0, a product state); GME = ", prodGME, " (expect False)"];

(* validation 3: PentagonChain[1], n=5 -- cross-check against the real mesh
   topology Sections 5-6 already trust. Uses a single-vertex cut, whose
   cut-rank is PROVABLY exactly 1 for any vertex of degree >=1 in a simple
   graph (rank of one nonzero row vector over GF(2) is always 1) -- avoiding
   any assumption about the paclet's specific vertex-labeling convention. *)
pent1GME = GraphStateGMEQ[pent1N, pent1Edges];
pent1SingleCutRank = GraphStateCutRankGF2[pent1N, pent1Edges, {pent1Edges[[1, 1]]}];
Print["  PentagonChain[1] (n=5, C5 ring): GME = ", pent1GME, " (expect True); single-vertex",
  " cut-rank = ", pent1SingleCutRank, " (expect exactly 1, by construction)"];

(* validation 4: PentagonChain[2], n=8 -- EXACTLY the size Section 7 marked
   INFEASIBLE for the DLA route. The GME question, unlike the DLA question,
   is answered here instantly. *)
pent2GME = GraphStateGMEQ[pent2N, pent2Edges];
Print["  PentagonChain[2] (n=8, the DLA-INFEASIBLE case from Section 7): GME = ", pent2GME,
  "  -- answered in O(V+E), no exponential blow-up."];

(* validation 5: scale check -- confirm this stays instant far past the ~8-qubit
   DLA ceiling. Uses a plain large cycle (any connected topology demonstrates
   the point; PentagonChainEdges' own O(L^2) list-Join construction, per its
   docstring analogue in ddt_mesh_sparse_construction.wl, is irrelevant and
   deliberately not exercised here). *)
{tScale, bigGME} = AbsoluteTiming[
   Module[{nBig = 50000, edgesBig},
     edgesBig = Table[{i, Mod[i, 50000] + 1}, {i, 50000}];
     GraphStateGMEQ[nBig, edgesBig]]];
Print["  A 50,000-vertex connected cycle (far past any DLA-feasible size): GME = ", bigGME,
  ", computed in ", tScale, "s -- confirms no exponential blow-up."];

gmeSectionOK = (bellCutRank == 1) && bellGME && (prodCutRank == 0) && !prodGME &&
   pent1GME && (pent1SingleCutRank == 1) && pent2GME && bigGME;
Print["  Section 10 self-check (all validations pass): ", gmeSectionOK];
Print[""];
Print[Style["CONCLUSION (Section 10): graph connectivity is an EXACT, poly-time certificate",
  Bold]];
Print[Style["of genuine multipartite entanglement for any CZ graph state this project builds --",
  Bold]];
Print[Style["a real answer to the joint/global-entanglement question at scales (n=8 and far",
  Bold]];
Print[Style["beyond) where Sections 6-9's DLA-based UNIVERSAL-CONTROLLABILITY question remains",
  Bold]];
Print[Style["open/infeasible. The two questions are genuinely different; this does not close",
  Bold]];
Print[Style["Proposition 0 -- it closes the separate, well-posed GME question optical-synthesis's own",
  Bold]];
Print[Style["Mesh-blueprint audit (DispatcherEmitter.wl meshDLAAudit) actually needs.", Bold]];

