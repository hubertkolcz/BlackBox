(* ::Package:: *)

(* :Title: BlackBox *)
(* :Context: BlackBox` *)
(* :Author: Hubert Kolcz *)
(* :Summary: Certificates of quantum contextuality from event statistics alone.
   Every algorithm here was extracted verbatim from the kernel-verified pipeline
   of 10 July 2026 (pipeline-2026-07-10, all modules OK -> True); this package
   only deduplicates and names them. Native Wolfram functionality is used
   wherever it exists (SemidefiniteOptimization, LinearOptimization, FindClique,
   FindIndependentVertexSet, GraphProduct, MatrixLog); nothing is reimplemented. *)

BeginPackage["HubertKolcz`BlackBox`"];

(* -- graph invariants: the three theories, three numbers -- *)
IndependenceNumber::usage = "IndependenceNumber[g] gives the independence number \[Alpha](g): the noncontextual (deterministic hidden-variable) bound of the exclusivity graph g.";
LovaszTheta::usage = "LovaszTheta[g] gives the Lov\[AAcute]sz number \[CurlyTheta](g) by semidefinite programming: the quantum bound of the exclusivity graph g (CSW, arXiv:1010.2163).";
LovaszThetaSparse::usage = "LovaszThetaSparse[g] gives the Lov\[AAcute]sz number \[CurlyTheta](g) by chordal decomposition of the dual semidefinite program: the single (n+1)-dimensional cone is split into one block per maximal clique of a chordal extension of g (Grone-Johnson-S\[AAcute]-Wolkowicz 1984 / Agler-Helton-McCullough-Rodman completion), so the cost scales with the treewidth of g instead of its vertex count. LovaszThetaSparse[g, \"Certificate\"] returns an association that adds the eigenvalue-certified upper bound \[Lambda]max(J - B) of the recovered dual witness B and the clique statistics of the extension. Values agree with LovaszTheta to solver tolerance on every graph; prefer the sparse form for meshes with hundreds to thousands of vertices (PentagonChain, pentagon rings). NOT a new algorithm (adversarial novelty audit, 11-12 July 2026): chordal/matrix-completion SDP decomposition dates to Fukuda-Kojima-Murota-Nakata (SIAM J. Optim. 2000/2001), the Lov\[AAcute]sz-theta SDP has been its standard benchmark since Borchers' SDPLIB (1999, instances theta1-theta6), and R. Zhang (arXiv:2306.15288, Math. Programming 2024) already solves theta via this exact route on graphs up to n=13659. What is new here is only the application to pentagon-chain/ring mesh graphs specifically, cross-validated in Wolfram Language and Python/Clarabel (lovasz_theta_sparse.py) at 10^4-10^5 vertices; see that file's header for the DFT/Fourier symmetry-reduction route for Z_N-symmetric graphs, which is likewise prior art (Brimkov-Codenotti-Crespi-Leoncini 2000; Brimkov et al., ECCC TR03-081, 2003; subsumed generally by de Klerk-Pasechnik-Schrijver, Math. Program. 109, 2007).";
FractionalPackingNumber::usage = "FractionalPackingNumber[g] gives the fractional packing number \[Alpha]*(g) as an exact linear program over the maximal cliques: the exclusivity-only (E-principle, single copy) bound.";

(* -- geometry and composition -- *)
KCBSDirections::usage = "KCBSDirections[] gives the five exact pentagram unit vectors of the KCBS construction (cyclically orthogonal, cone axis {0,0,1}).";
GlueGraphs::usage = "GlueGraphs[g, h, ident] glues graph h onto graph g identifying vertices by the rules ident: {hVertex -> gVertex, ...}. Shared edges are deduplicated regardless of orientation.";
PentagonChain::usage = "PentagonChain[n] gives the chain of n single-edge-glued pentagons (3n+2 vertices): the mesh whose \[CurlyTheta] grows linearly while any state-vector treatment grows as 2^(5n).";
CEFilter::usage = "CEFilter[g, p] and CEFilter[g, p, k] apply the Consistent-Exclusivity filter at k copies (default 2) to the probability assignment p (a vector in VertexList order) on the exclusivity graph g: every maximal clique of the k-fold OR (conormal) power must carry total probability at most 1 under the factorization rule P(e1,...,ek) = p(e1)...p(ek). Returns an association with keys \"Passes\", \"ViolatingCliques\", \"Worst\", \"CliqueCount\", \"Omega\".";

(* -- the n-cycle scenario: empirical models, contextual fraction, sheaf layer -- *)
CycleScenario::usage = "CycleScenario[n] gives the n-cycle contextuality scenario as an association: measurements 0..n-1, contexts = edges {i, i+1}, section order per context (00, 01, 10, 11), the Abramsky-Brandenburger incidence matrix \"Incidence\" (4n x 2^n) relating deterministic global assignments to context sections, and \"Assignments\" (the 2^n global assignments).";
CycleModel::usage = "CycleModel[n, p00, p10] gives the symmetric empirical model vector on the n-cycle with edge distribution (p00, p10, p10, 0). CycleModel[n, \"Quantum\"] gives the quantum-maximal model (per-event probability cos(\[Pi]/n)/(1+cos(\[Pi]/n))), CycleModel[n, \"Wright\"] the exclusivity-extremal box (1/2 per event), CycleModel[n, \"Classical\"] the symmetrized classical maximum (\[Alpha]/n per event).";
NoncontextualFraction::usage = "NoncontextualFraction[scen, e] gives the noncontextual fraction NCF of the empirical model e in the scenario scen (Abramsky-Barbosa-Mansfield, PRL 119, 050504): the maximal total weight of a subprobability mixture of deterministic global assignments dominated by e.";
ContextualFraction::usage = "ContextualFraction[scen, e] gives CF = 1 - NoncontextualFraction[scen, e], the contextual resource content of the empirical model e.";
GlobalSectionQ::usage = "GlobalSectionQ[scen, e] gives True if the empirical model e extends to a global probability distribution (a nonnegative global section of the Abramsky-Brandenburger presheaf): the model is noncontextual.";
SignedNegativity::usage = "SignedNegativity[scen, e] gives the negativity of the empirical model e: the minimal total negative weight of a quasi-probability distribution over deterministic global assignments that reproduces e (an exact L1-minimization LP, min (Sum|c|-1)/2 subject to M.c = e). It is 0 exactly when e is noncontextual, and equals CF = 0 iff SignedNegativity = 0. This is a SHEAF-LEVEL resource measure of the empirical model, distinct from the Wigner negativity of a state. The relation to the contextual fraction is scenario-dependent, NOT universal: on the n-cycle CF = (n-1)*SignedNegativity for both the quantum-maximal and Wright models (so the pentagon identity CF = 4 nu is the n = 5 case), while the CHSH PR box and GHZ give CF/nu = 2.";
PossibilisticSupport::usage = "PossibilisticSupport[scen, e] gives the possibilistic global support S_e of the empirical model e: association with \"Size\" (number of global assignments consistent with the support of e) and \"Empty\" (True means strong contextuality, AB Sec. 6).";
CycleCoboundary::usage = "CycleCoboundary[n] gives the cellular-sheaf coboundary \[Delta] (2n x 4n) of the n-cycle cover with marginalization restriction maps (Hansen-Ghrist, arXiv:1808.01513): ker(\[Delta]\[Transpose]\[Delta]) = the no-disturbance models.";
HarmonicResidual::usage = "HarmonicResidual[delta, e] gives Norm[delta . e]: the no-disturbance (signalling) residual of the model e. It vanishes on every no-disturbance model and is provably blind to contextuality - use it as a projector diagnostic, not a contextuality measure.";
CoverScenario::usage = "CoverScenario[X, cover] gives the contextuality scenario of an arbitrary measurement cover as an association: measurements X, contexts = the elements of cover (ordered measurement lists), section order per context (Tuples of the outcome sets in context order), the Abramsky-Brandenburger incidence matrix \"Incidence\" relating deterministic global assignments to context sections, \"Assignments\" (all global assignments), and \"Outcomes\". CoverScenario[X, cover, outcomes] uses the outcome list outcomes for every measurement (default {0, 1}), or per-measurement outcome lists when outcomes is an association over X. CycleScenario[n] is the binary n-cycle special case.";
CechCohomology::usage = "CechCohomology[scen, e] gives the absolute \:010cech cohomology of the Z-linearized support presheaf of the empirical model e over the cover of scen: an association with \"H0Rank\" (rank of the module of compatible Z-linear families = global sections), \"H1FreeRank\" and \"H1Torsion\" (elementary divisors > 1 of the degree-0 coboundary, by Smith normal form), \"CochainRanks\" ({C^0, C^1, C^2} over contexts, pairwise and triple overlaps, each the free Z-module on the restriction image of the support), \"CoboundaryRanks\", \"ComplexCloses\" (the verified identity \[Delta]1 . \[Delta]0 = 0), and \"SupportNoSignalling\". H^1 = ker \[Delta]1 / im \[Delta]0 is computed for arbitrary covers (the C^2 term handles nonempty triple overlaps). These are AMBIENT invariants: the per-section obstruction classes \[Gamma](s) of CechObstruction live in the RELATIVE H^1, so a nonzero absolute H^1 is not itself a contextuality certificate (the PR box and the noncontextual uniform model both have H^1 = Z on the CHSH cover).";
CechRelativeCohomology::usage = "CechRelativeCohomology[scen, e, c0] gives the RELATIVE \:010cech cohomology of the Z-linearized support presheaf of the empirical model e with respect to the distinguished context c0 (an index into scen[\"Contexts\"], or the context itself): the presheaf F~ = ker(F -> F|c0), whose value on U is spanned by differences of support sections agreeing on U \[Intersection] c0 (so F~(c0) = 0). Returns \"H0Rank\", \"H1FreeRank\", \"H1Torsion\", \"CochainRanks\", \"ComplexCloses\", and \"GammaOrders\": for every support section s of c0 the explicit connecting-map cocycle \[Gamma](s) = \[Delta]0(lift of s) is built and its exact order in H^1(F~) is computed by Smith normal form. Because F~(c0) = 0, that order provably equals CechObstruction's \"ObstructionOrder\" - a built-in cross-validation of the construction. H^1(F~) is the group where the obstruction actually lives: Z/2 for GHZ and the Peres-Mermin square (pure 2-torsion), Z for the Wright and PR boxes, and 0 for the Hardy model - its false negative is structural.";
AvNArgument::usage = "AvNArgument[scen, e] and AvNArgument[scen, e, d] give the All-vs-Nothing argument of the empirical model e on the scenario scen over Z_d (default d = 2; d is any integer >= 2, prime or composite), following Abramsky-Barbosa-Kishida-Lal-Mansfield, arXiv:1502.03097 Sec. 6: the theory of e collects every Z_d-affine equation Sum c_m x_m = a (mod d) satisfied by ALL support sections of a context; the model is AvN when the joint theory is inconsistent. Consistency is decided by an exact lattice-solvability test (Smith normal form of the integer coefficient matrix), valid over any Z_d and reducing to the GF(d) rank test when d is prime. For composite d the theory retains equations with NON-unit coefficient vectors (e.g. the 2x = 2 relations mod 4), which no prime-modulus reduction can see; equations are canonicalized only up to multiplication by units. AvN certifies strong contextuality, and every AvN model is cohomologically strongly contextual, so \"AvN\" -> True implies CechObstruction[scen, e][\"CohStronglyContextual\"]. Returns an association with keys \"Modulus\", \"Equations\" (as {context, coefficient tuple, rhs}), \"EquationCount\", \"Consistent\", and \"AvN\". GHZ is the canonical AvN model over Z_2 (the four Mermin parity equations); the Z_3 box on the square is AvN over Z_3; the Z_4 shift box is AvN over Z_4 with a witness invisible mod 2; the Hardy model is not AvN, matching its non-strong contextuality.";
AvNArgument::outs = "AvN over Z_`1` requires every measurement of the scenario to take outcomes {0, ..., `2`}.";
AvNArgument::mod = "The modulus `1` must be an integer >= 2.";
CechObstruction::usage = "CechObstruction[scen, e] gives the \:010cech cohomological obstruction data of the support presheaf of the empirical model e on the scenario scen (Abramsky-Mansfield-Barbosa; Abramsky-Barbosa-Kishida-Lal-Mansfield, arXiv:1502.03097): a support section s over a context is obstructed when its class \[Gamma](s) in the first \:010cech cohomology of the relative Z-linearized support presheaf is nonzero, equivalently (arXiv:1502.03097, Prop. 4.4) when NO compatible family of Z-linear combinations of support sections restricts to s. Returns an association with keys \"Obstructed\"/\"ObstructedCount\"/\"SectionCount\", \"ObstructionOrder\" ({context, section} -> least n >= 1 with n \[Gamma](s) = 0, by Smith normal form: 1 means \[Gamma](s) = 0, Infinity means rationally obstructed, finite n > 1 is pure relative torsion - every GHZ class has order exactly 2), \"NonextendableSections\" (sections with no global support assignment through them) and \"FalseNegatives\", \"GlobalSupportSize\", \"H0Rank\" (rank of the compatible-family module), \"SupportNoSignalling\", and the witness flags \"CohLogicallyContextual\" (some \[Gamma](s) != 0: certifies logical contextuality) and \"CohStronglyContextual\" (every \[Gamma](s) != 0: certifies strong contextuality). Vanishing of \[Gamma] is not conclusive - the Hardy model is the canonical false negative.";

(* -- the Lie-Poisson interface of the KCBS cascade -- *)
CascadeGenerators::usage = "CascadeGenerators[] gives the four so(3) generators (matrix logarithms of the stage-frame transition rotations) of the Lapkiewicz KCBS cascade.";
So3Axis::usage = "So3Axis[m] gives the rotation-axis vector (vee map) of the antisymmetric 3x3 matrix m.";
DLADimension::usage = "DLADimension[gens] gives the dimension of the dynamical Lie algebra generated by the antisymmetric matrices gens after one commutator step: the rank of the generator axes together with all pairwise commutator axes.";

CycleORProduct::usage = "CycleORProduct[{n1, n2, ...}] gives the OR (conormal) product of the cycles C_n1, C_n2, ... on explicit tuple vertices: joint events are exclusive iff exclusive in some factor. The composition primitive for Consistent-Exclusivity tests across independent experiments.";
QuantumEventProbability::usage = "QuantumEventProbability[n] gives the per-event probability cos(Pi/n)/(1+cos(Pi/n)) of the quantum-maximal n-cycle model (Araujo et al., PRA 88, 022118); for n = 5 it is 1/Sqrt[5].";
PentagonRing::usage = "PentagonRing[n] gives the ring of n single-edge-glued pentagons (3n vertices, 4n edges). Theorem (proven 10 July 2026): IndependenceNumber[PentagonRing[n]] == Floor[4n/3].";
CEFilterMixed::usage = "CEFilterMixed[{{g1, p1}, {g2, p2}, ...}] applies the Consistent-Exclusivity filter to the independent composition of DIFFERENT experiments: exclusivity graphs g_i with assignments p_i (vectors in VertexList order); joint events are exclusive iff exclusive in some factor and weights multiply. Same return keys as CEFilter plus \"MaxLoad\" (worst clique load even when passing). Exhaustive clique enumeration - practical for two factors / a few hundred product vertices.";
Begin["`Private`"];

(* ------------------------------------------------------------------ *)
(* graph invariants                                                    *)
(* ------------------------------------------------------------------ *)

IndependenceNumber[g_Graph] := Length[First[FindIndependentVertexSet[g]]];

LovaszTheta[g_Graph] := Module[{h = IndexGraph[g], n, x, X, vars, cons, sol},
  n = VertexCount[h];
  X = Table[If[i <= j, x[i, j], x[j, i]], {i, n}, {j, n}];
  vars = Flatten[Table[x[i, j], {i, n}, {j, i, n}]];
  cons = Join[{Tr[X] == 1, VectorGreaterEqual[{X, 0}, {"SemidefiniteCone", n}]},
    (x[#[[1]], #[[2]]] == 0) & /@ (Sort /@ (List @@@ EdgeList[h]))];
  sol = SemidefiniteOptimization[-Total[X, 2], cons, vars, MaxIterations -> 300];
  Total[X, 2] /. sol];

(* chordal extension by minimum-degree elimination: the bag of each eliminated vertex
   (vertex + current neighbourhood) is a clique of the extension; the subset-maximal
   bags are exactly its maximal cliques *)
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

(* dual program theta(g) = min lambda_max(J - B), B supported on E(g); the rank-one J
   is absorbed into an apex border row (Schur complement), the (n+1)-cone then splits
   clique-by-clique: M = [[t I + B, e],[e^T, 1]] = Sum_j E_j^T S_j E_j with S_j >= 0.
   Fixed entries: diagonal sums to t, border to 1, corner to 1, extension fill to 0. *)
LovaszThetaSparse[g_Graph] := LovaszThetaSparse[g, "Value"];
LovaszThetaSparse[g_Graph, prop : ("Value" | "Certificate")] := Module[
  {h = IndexGraph[g], n, cliques, nc, edgeQ, y, t, vars, blocks, diagTerms, bordTerms,
   cornVars, fillTerms, cons, sol, tval, Bnum, am, upper},
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
  tval = t /. sol;
  If[prop === "Value", Return[tval]];
  Bnum = ConstantArray[0., {n, n}];
  Do[With[{K = cliques[[j]], Sj = blocks[[j]] /. sol},
     Bnum[[K, K]] += Sj[[;; -2, ;; -2]]], {j, nc}];
  am = Normal[AdjacencyMatrix[h]];
  upper = If[n <= 1500, Max[Eigenvalues[ConstantArray[1., {n, n}] - am Bnum]],
    Missing["TooLarge"]];
  <|"Theta" -> tval, "UpperBound" -> upper, "CliqueCount" -> nc,
    "MaxCliqueSize" -> Max[Length /@ cliques],
    "FillEdges" -> Length[fillTerms]|>];

FractionalPackingNumber[g_Graph] := Module[{h = IndexGraph[g], n, cl, w, sol},
  n = VertexCount[h]; cl = FindClique[h, Infinity, All];
  sol = Maximize[{Total[Array[w, n]],
    Join[Table[Total[w /@ c] <= 1, {c, cl}], Table[w[i] >= 0, {i, n}]]}, Array[w, n]];
  First[sol]];

(* ------------------------------------------------------------------ *)
(* geometry and composition                                            *)
(* ------------------------------------------------------------------ *)

KCBSDirections[] := Module[{c2 = Cos[Pi/5]/(1 + Cos[Pi/5])},
  Table[{Sqrt[1 - c2] Cos[4 Pi i/5], Sqrt[1 - c2] Sin[4 Pi i/5], Sqrt[c2]}, {i, 0, 4}]];

GlueGraphs[g_Graph, h_Graph, ident_List] := Module[{hh = VertexReplace[h, ident]},
  Graph[Union[VertexList[g], VertexList[hh]],
    Union[Sort /@ EdgeList[g], Sort /@ EdgeList[hh]]]];

PentagonChain[nblocks_Integer?Positive] := Module[{edges = {}, e0 = {1, 2}, base = 2},
  Do[edges = Join[edges, {UndirectedEdge[e0[[1]], base + 1], UndirectedEdge[base + 1, base + 2],
      UndirectedEdge[base + 2, base + 3], UndirectedEdge[base + 3, e0[[2]]], UndirectedEdge[e0[[2]], e0[[1]]]}];
   e0 = {base + 1, base + 2}; base = base + 3, {nblocks}];
  Graph[Range[3 nblocks + 2], DeleteDuplicates[Sort /@ edges]]];

CEFilter[g_Graph, p_List, k_Integer: 2] := Module[
  {h = IndexGraph[g], n, am, tuples, adjQ, hp, cliques, weight, sums, viol},
  n = VertexCount[h]; am = Normal[AdjacencyMatrix[h]];
  tuples = Tuples[Range[n], k];
  adjQ[u_, v_] := AnyTrue[Range[k], am[[u[[#]], v[[#]]]] == 1 &];
  hp = Graph[tuples, UndirectedEdge @@@ Select[Subsets[tuples, {2}], adjQ @@ # &]];
  cliques = FindClique[hp, Infinity, All];
  weight[t_] := Times @@ (p[[#]] & /@ t);
  sums = Total[weight /@ #] & /@ cliques;
  viol = Select[sums, # > 1 + 10^-9 &];
  <|"Passes" -> viol === {}, "ViolatingCliques" -> Length[viol],
    "Worst" -> If[viol === {}, Missing["NotViolated"], Max[viol]],
    "MaxLoad" -> Max[sums],
    "CliqueCount" -> Length[cliques], "Omega" -> Max[Length /@ cliques]|>];

CEFilterMixed[factors : {{_Graph, _List} ..}] := Module[
  {hs, ams, ns, tuples, adjQ, hp, cliques, weight, sums, viol},
  hs = IndexGraph[#[[1]]] & /@ factors; ams = Normal[AdjacencyMatrix[#]] & /@ hs;
  ns = VertexCount /@ hs; tuples = Tuples[Range /@ ns];
  adjQ[u_, v_] := Or @@ Table[ams[[j]][[u[[j]], v[[j]]]] == 1, {j, Length[ns]}];
  hp = Graph[tuples, UndirectedEdge @@@ Select[Subsets[tuples, {2}], adjQ @@ # &]];
  cliques = FindClique[hp, Infinity, All];
  weight[t_] := Product[factors[[j, 2]][[t[[j]]]], {j, Length[ns]}];
  sums = Total[weight /@ #] & /@ cliques;
  viol = Select[sums, # > 1 + 10^-9 &];
  <|"Passes" -> viol === {}, "ViolatingCliques" -> Length[viol],
    "Worst" -> If[viol === {}, Missing["NotViolated"], Max[viol]],
    "MaxLoad" -> Max[sums],
    "CliqueCount" -> Length[cliques], "Omega" -> Max[Length /@ cliques]|>];

(* ------------------------------------------------------------------ *)
(* the n-cycle scenario                                                *)
(* ------------------------------------------------------------------ *)

(* the n-cycle scenario is the arbitrary-cover scenario over the edge cover - one construction *)
CycleScenario[n_Integer /; n >= 3] := Append[
  CoverScenario[Range[0, n - 1], Table[{i, Mod[i + 1, n]}, {i, 0, n - 1}]], "n" -> n];

CycleModel[n_Integer, p00_, p10_] := Flatten[Table[{p00, p10, p10, 0}, {n}]];
CycleModel[n_Integer, "Quantum"] := With[{p = Simplify[Cos[Pi/n]/(1 + Cos[Pi/n])]}, CycleModel[n, Simplify[1 - 2 p], p]];
CycleModel[n_Integer, "Wright"] := CycleModel[n, 0, 1/2];
CycleModel[n_Integer, "Classical"] := With[{p = Floor[n/2]/n}, CycleModel[n, 1 - 2 p, p]];

NoncontextualFraction[scen_Association, e_List, opts___Rule] := Module[{M = scen["Incidence"], m, d},
  m = Dimensions[M][[2]];
  -First@Quiet@LinearOptimization[-Total[Array[d, m]],
     Join[Thread[M . Array[d, m] <= e], Thread[Array[d, m] >= 0]],
     Array[d, m], {"PrimalMinimumValue"}, opts]];

ContextualFraction[scen_Association, e_List, opts___Rule] := 1 - NoncontextualFraction[scen, e, opts];

GlobalSectionQ[scen_Association, e_List] := Module[{M = scen["Incidence"], m, vars, sol},
  m = Dimensions[M][[2]]; vars = Array[\[FormalD], m];
  sol = Quiet@LinearOptimization[ConstantArray[0., m] . vars,
      Join[Thread[M . vars == e], Thread[vars >= 0]], vars];
  ListQ[sol] && FreeQ[sol, Indeterminate]];

(* min total negative weight of a quasi-probability over deterministic assignments
   reproducing e: min (Sum|c|-1)/2  s.t.  M.c = e, Sum c = 1 (the normalization is
   implied by no-disturbance but is pinned explicitly so nu >= 0 holds exactly) *)
SignedNegativity[scen_Association, e_List, opts___Rule] := Module[
  {M = scen["Incidence"], n, c, t, val},
  n = Dimensions[M][[2]]; c = Array[\[FormalC], n]; t = Array[\[FormalT], n];
  val = Quiet@LinearOptimization[Total[t],
     Join[Thread[M . c == e], {Total[c] == 1}, Thread[t - c >= 0], Thread[t + c >= 0]],
     Join[c, t], {"PrimalMinimumValue"}, opts];
  (val[[1]] - 1)/2];

PossibilisticSupport[scen_Association, e_List] := Module[
  {M = scen["Incidence"], glob = scen["Assignments"], supp, ok},
  supp = Thread[e > 10^-12];
  ok = Select[Range[Length[glob]],
    Function[j, AllTrue[Range[Length[e]], supp[[#]] || M[[#, j]] == 0 &]]];
  <|"Size" -> Length[ok], "Empty" -> ok === {}|>];

(* section order (00,01,10,11): the 1st-observable marginal groups {00,01}/{10,11},
   the 2nd-observable marginal groups {00,10}/{01,11}; measurement i is the 2nd
   observable of context i-1 and the 1st of context i *)
CycleCoboundary[n_Integer /; n >= 3] := Module[
  {m1st = {{1, 1, 0, 0}, {0, 0, 1, 1}}, m2nd = {{1, 0, 1, 0}, {0, 1, 0, 1}}, del},
  del = ConstantArray[0, {2 n, 4 n}];
  Do[del[[2 i + 1 ;; 2 i + 2, 4 Mod[i - 1, n] + 1 ;; 4 Mod[i - 1, n] + 4]] += m2nd;
     del[[2 i + 1 ;; 2 i + 2, 4 i + 1 ;; 4 i + 4]] -= m1st, {i, 0, n - 1}];
  del];

HarmonicResidual[delta_?MatrixQ, e_List] := Norm[delta . e];

(* ------------------------------------------------------------------ *)
(* the support presheaf and its Cech obstruction                       *)
(* ------------------------------------------------------------------ *)

CoverScenario[X_List, cover_List, outcomes_ : {0, 1}] := Module[{outs, glob, pos, secs, M},
  outs = If[AssociationQ[outcomes], outcomes, Association[# -> outcomes & /@ X]];
  pos = AssociationThread[X -> Range[Length[X]]];
  glob = Tuples[outs /@ X];
  secs = Flatten[Table[{c, s}, {c, cover}, {s, Tuples[outs /@ c]}], 1];
  M = Table[Boole[(t[[pos[#]]] & /@ sec[[1]]) === sec[[2]]], {sec, secs}, {t, glob}];
  <|"X" -> X, "Outcomes" -> outs, "Contexts" -> cover, "Sections" -> secs,
    "Incidence" -> M, "Assignments" -> glob|>];

restrictSection[c_, s_, u_] := s[[Flatten[Position[c, #] & /@ u]]];

(* gamma(s) = 0 iff s extends to a compatible family of Z-linear combinations of
   support sections (Abramsky-Mansfield-Barbosa, "The Cohomology of Non-Locality
   and Contextuality," arXiv:1111.3620 (2011/2012) - defines the obstruction and
   computes it by brute-force enumeration for Hardy/PR-box/GHZ/Peres-Mermin/CEG;
   NOT arXiv:1502.03097 "Contextuality, Cohomology and Paradox" [Abramsky-Barbosa-
   Kishida-Lal-Mansfield, 2015], which reformulates the same obstruction via the
   snake lemma and generalizes AvN to arbitrary rings - the two are companion
   papers, easy to conflate, and no "Prop. 4.4" IP-feasibility statement exists in
   either; nearest analogue is 1111.3620's Prop. 6.1, a GCD necessary condition).
   Decision order per section: a deterministic global witness gives order 1;
   exact rank refutation over Q gives order Infinity; otherwise the exact order
   of the class - the least n with n*b in the integer column lattice of the
   pinned system - comes from the Smith normal form: n = LCM_i d_i/gcd(d_i,
   (u.b)_i). Obstructed = order > 1. NOVELTY NOTE (adversarial audit, 11-12 July
   2026): general algorithmic decision procedures for gamma(s) already exist
   (brute force in 1111.3620 itself; a provably-correct joint-model iteration for
   cyclic/CCP covers in G. Caru's Oxford tech report, condensed as arXiv:1701.00656)
   and AvN over composite Z_d is already covered abstractly by 1502.03097's
   arbitrary-ring generalization - what is not found anywhere in that literature
   is computing the exact ORDER of the obstruction via Smith normal form (below),
   not just its vanishing. *)
CechObstruction[scen_Association, e_List] := Module[
  {ctxs = scen["Contexts"], secs = scen["Sections"], glob = scen["Assignments"],
   X, outs, pos, m, ctxIdx, supp, cols, colIdx, pairs, rows, A, e2, Se, SeR,
   colsOf, orderOf, orders, obstructed, nonext},
  X = Lookup[scen, "X", Union @@ ctxs];
  outs = Lookup[scen, "Outcomes", Association[# -> {0, 1} & /@ X]];
  pos = AssociationThread[X -> Range[Length[X]]];
  m = Length[ctxs]; ctxIdx = AssociationThread[ctxs -> Range[m]];
  supp = Table[{}, {m}];
  Do[If[e[[k]] > 10^-12, AppendTo[supp[[ctxIdx[secs[[k, 1]]]]], secs[[k, 2]]]], {k, Length[secs]}];
  cols = Flatten[Table[{i, s}, {i, m}, {s, supp[[i]]}], 1];
  colIdx = AssociationThread[cols -> Range[Length[cols]]];
  pairs = Select[Subsets[Range[m], {2}], Intersection @@ ctxs[[#]] =!= {} &];
  rows = Flatten[Table[
     Module[{i = pr[[1]], j = pr[[2]], U = Intersection @@ ctxs[[pr]]},
      Table[Module[{row = ConstantArray[0, Length[cols]]},
        Do[If[restrictSection[ctxs[[i]], s, U] === u, row[[colIdx[{i, s}]]] += 1], {s, supp[[i]]}];
        Do[If[restrictSection[ctxs[[j]], s, U] === u, row[[colIdx[{j, s}]]] -= 1], {s, supp[[j]]}];
        row], {u, Tuples[outs /@ U]}]], {pr, pairs}], 1];
  A = DeleteDuplicates[DeleteCases[rows, {0 ..}]];
  e2 = AllTrue[pairs, Function[pr, With[{U = Intersection @@ ctxs[[pr]]},
      Sort[DeleteDuplicates[restrictSection[ctxs[[pr[[1]]]], #, U] & /@ supp[[pr[[1]]]]]] ===
      Sort[DeleteDuplicates[restrictSection[ctxs[[pr[[2]]]], #, U] & /@ supp[[pr[[2]]]]]]]]];
  Se = Select[glob, Function[g, AllTrue[Range[m], MemberQ[supp[[#]], g[[pos /@ ctxs[[#]]]]] &]]];
  SeR = Table[DeleteDuplicates[Table[g[[pos /@ ctxs[[i]]]], {g, Se}]], {i, m}];
  colsOf = Table[Flatten[Position[cols, {i, _}, {1}, Heads -> False]], {i, m}];
  Module[{restOf = <||>, AiOf = <||>, rankAi = <||>, smithAi = <||>},
   orderOf[i0_, s0_] := Module[{b, sm, ub, nc},
     If[MemberQ[SeR[[i0]], s0], Return[1]];
     If[A === {}, Return[1]];
     If[! KeyExistsQ[restOf, i0],
      restOf[i0] = Complement[Range[Length[cols]], colsOf[[i0]]];
      AiOf[i0] = A[[All, restOf[i0]]];
      rankAi[i0] = If[restOf[i0] === {}, 0, MatrixRank[AiOf[i0]]]];
     b = -A[[All, colIdx[{i0, s0}]]];
     If[restOf[i0] === {}, Return[If[b === ConstantArray[0, Length[b]], 1, Infinity]]];
     If[MatrixRank[MapThread[Append, {AiOf[i0], b}]] > rankAi[i0], Return[Infinity]];
     If[! KeyExistsQ[smithAi, i0], smithAi[i0] = SmithDecomposition[AiOf[i0]]];
     sm = smithAi[i0]; ub = sm[[1]] . b; nc = Length[restOf[i0]];
     LCM @@ Prepend[Table[With[{di = If[r <= nc, Abs[sm[[2]][[r, r]]], 0]},
         If[di == 0, 1, di/GCD[di, ub[[r]]]]], {r, Length[ub]}], 1]]];
  orders = Association[Table[{ctxs[[cl[[1]]]], cl[[2]]} -> orderOf[cl[[1]], cl[[2]]], {cl, cols}]];
  obstructed = Select[cols, orders[{ctxs[[#[[1]]]], #[[2]]}] =!= 1 &];
  nonext = Select[cols, ! MemberQ[SeR[[#[[1]]]], #[[2]]] &];
  <|"SectionCount" -> Length[cols],
    "SupportSizes" -> Length /@ supp,
    "SupportNoSignalling" -> e2,
    "GlobalSupportSize" -> Length[Se],
    "H0Rank" -> Length[cols] - MatrixRank[A],
    "Obstructed" -> ({ctxs[[#[[1]]]], #[[2]]} & /@ obstructed),
    "ObstructedCount" -> Length[obstructed],
    "ObstructionOrder" -> orders,
    "NonextendableSections" -> ({ctxs[[#[[1]]]], #[[2]]} & /@ nonext),
    "FalseNegatives" -> ({ctxs[[#[[1]]]], #[[2]]} & /@ Complement[nonext, obstructed]),
    "CohLogicallyContextual" -> Length[obstructed] > 0,
    "CohStronglyContextual" -> Length[cols] > 0 && Length[obstructed] == Length[cols],
    "LogicallyContextual" -> nonext =!= {},
    "StronglyContextual" -> Length[cols] > 0 && Se === {}|>];

(* absolute groups of the linearized support presheaf: H^0 = ker d0 (free),
   H^1 = ker d1 / im d0 with free rank c1 - rk d0 - rk d1 and torsion = the
   elementary divisors of d0 exceeding 1 (torsion of C^1/im d0 lies in ker d1
   because C^2 is torsion-free). Signs: (d0 w)_{i<j} = w_j - w_i restricted;
   (d1 h)_{i<j<k} = h_{jk} - h_{ik} + h_{ij} restricted; d1 . d0 = 0 is
   returned as a verified identity, not assumed. *)
CechCohomology[scen_Association, e_List] := Module[
  {ctxs = scen["Contexts"], secs = scen["Sections"], m, ctxIdx, supp,
   cols0, col0Idx, pairs, uOf, sPair, cols1, col1Idx, triples, wOf, sTriple,
   d0, d1, c0, c1, c2, rk0, rk1, torsion, closes, e2},
  m = Length[ctxs]; ctxIdx = AssociationThread[ctxs -> Range[m]];
  supp = Table[{}, {m}];
  Do[If[e[[k]] > 10^-12, AppendTo[supp[[ctxIdx[secs[[k, 1]]]]], secs[[k, 2]]]], {k, Length[secs]}];
  cols0 = Flatten[Table[{i, s}, {i, m}, {s, supp[[i]]}], 1];
  col0Idx = AssociationThread[cols0 -> Range[Length[cols0]]];
  pairs = Select[Subsets[Range[m], {2}], Intersection @@ ctxs[[#]] =!= {} &];
  uOf = Association @@ Table[pr -> Intersection @@ ctxs[[pr]], {pr, pairs}];
  sPair = Association @@ Table[pr -> DeleteDuplicates[
      Flatten[Table[restrictSection[ctxs[[t]], s, uOf[pr]], {t, pr}, {s, supp[[t]]}], 1]], {pr, pairs}];
  cols1 = Flatten[Table[{pr, v}, {pr, pairs}, {v, sPair[pr]}], 1];
  col1Idx = AssociationThread[cols1 -> Range[Length[cols1]]];
  triples = Select[Subsets[Range[m], {3}], Intersection @@ ctxs[[#]] =!= {} &];
  wOf = Association @@ Table[tr -> Intersection @@ ctxs[[tr]], {tr, triples}];
  sTriple = Association @@ Table[tr -> DeleteDuplicates[
      Flatten[Table[restrictSection[ctxs[[t]], s, wOf[tr]], {t, tr}, {s, supp[[t]]}], 1]], {tr, triples}];
  c0 = Length[cols0]; c1 = Length[cols1]; c2 = Total[Length[sTriple[#]] & /@ triples];
  d0 = ConstantArray[0, {c1, c0}];
  Do[With[{i = pr[[1]], j = pr[[2]], U = uOf[pr]},
    Do[d0[[col1Idx[{pr, restrictSection[ctxs[[i]], s, U]}], col0Idx[{i, s}]]] -= 1, {s, supp[[i]]}];
    Do[d0[[col1Idx[{pr, restrictSection[ctxs[[j]], s, U]}], col0Idx[{j, s}]]] += 1, {s, supp[[j]]}]],
   {pr, pairs}];
  d1 = If[triples === {}, {},
    Module[{rows = Flatten[Table[{tr, w}, {tr, triples}, {w, sTriple[tr]}], 1], rowIdx, mat},
     rowIdx = AssociationThread[rows -> Range[Length[rows]]];
     mat = ConstantArray[0, {Length[rows], c1}];
     Do[With[{i = tr[[1]], j = tr[[2]], k = tr[[3]], W = wOf[tr]},
       Do[With[{pr = ps[[1]], sgn = ps[[2]]},
         Do[mat[[rowIdx[{tr, restrictSection[uOf[pr], v, W]}], col1Idx[{pr, v}]]] += sgn,
          {v, sPair[pr]}]], {ps, {{{j, k}, 1}, {{i, k}, -1}, {{i, j}, 1}}}]], {tr, triples}];
     mat]];
  rk0 = If[c1 == 0 || c0 == 0, 0, MatrixRank[d0]];
  rk1 = If[d1 === {} || c1 == 0, 0, MatrixRank[d1]];
  closes = d1 === {} || c0 == 0 || Max[Abs[d1 . d0]] == 0;
  torsion = If[c1 == 0 || c0 == 0, {},
    Select[Abs[Select[Diagonal[SmithDecomposition[d0][[2]]], # =!= 0 &]], # > 1 &]];
  e2 = AllTrue[pairs, Function[pr,
     Sort[DeleteDuplicates[restrictSection[ctxs[[pr[[1]]]], #, uOf[pr]] & /@ supp[[pr[[1]]]]]] ===
     Sort[DeleteDuplicates[restrictSection[ctxs[[pr[[2]]]], #, uOf[pr]] & /@ supp[[pr[[2]]]]]]]];
  <|"CochainRanks" -> {c0, c1, c2}, "CoboundaryRanks" -> {rk0, rk1},
    "H0Rank" -> c0 - rk0, "H1FreeRank" -> c1 - rk0 - rk1, "H1Torsion" -> torsion,
    "ComplexCloses" -> closes, "SupportNoSignalling" -> e2|>];

(* order of the class [b] in coker(A) restricted to ker d1: least n with n b in
   the integer column lattice of A, from the Smith normal form sm of A (nc columns) *)
latticeOrder[sm_, b_, nc_] := Module[{ub = sm[[1]] . b},
  If[AnyTrue[Range[Length[ub]], Function[r, With[{di = If[r <= nc, Abs[sm[[2]][[r, r]]], 0]},
      di == 0 && ub[[r]] != 0]]], Infinity,
   LCM @@ Prepend[Table[With[{di = If[r <= nc, Abs[sm[[2]][[r, r]]], 0]},
       If[di == 0, 1, di/GCD[di, ub[[r]]]]], {r, Length[ub]}], 1]]];

CechRelativeCohomology[scen_Association, e_List, c0spec_] := Module[
  {ctxs = scen["Contexts"], secs = scen["Sections"], m, ctxIdx, supp, c0, C0,
   pairs, uOf, sPair, triples, wOf, sTriple, siteU, siteSecs, repOf, basis,
   relExpand, b0, i0, b1, i1, b2, i2, c0rel, c1rel, c2rel, d0, d1,
   rk0, rk1, torsion, closes, sm, orders, cocyclesOK = True},
  m = Length[ctxs]; ctxIdx = AssociationThread[ctxs -> Range[m]];
  c0 = If[IntegerQ[c0spec], c0spec, ctxIdx[c0spec]]; C0 = ctxs[[c0]];
  supp = Table[{}, {m}];
  Do[If[e[[k]] > 10^-12, AppendTo[supp[[ctxIdx[secs[[k, 1]]]]], secs[[k, 2]]]], {k, Length[secs]}];
  pairs = Select[Subsets[Range[m], {2}], Intersection @@ ctxs[[#]] =!= {} &];
  uOf = Association @@ Table[pr -> Intersection @@ ctxs[[pr]], {pr, pairs}];
  sPair = Association @@ Table[pr -> DeleteDuplicates[
      Flatten[Table[restrictSection[ctxs[[t]], s, uOf[pr]], {t, pr}, {s, supp[[t]]}], 1]], {pr, pairs}];
  triples = Select[Subsets[Range[m], {3}], Intersection @@ ctxs[[#]] =!= {} &];
  wOf = Association @@ Table[tr -> Intersection @@ ctxs[[tr]], {tr, triples}];
  sTriple = Association @@ Table[tr -> DeleteDuplicates[
      Flatten[Table[restrictSection[ctxs[[t]], s, wOf[tr]], {t, tr}, {s, supp[[t]]}], 1]], {tr, triples}];
  siteU = Join[Association @@ Table[{0, i} -> ctxs[[i]], {i, m}],
    Association @@ Table[{1, pr} -> uOf[pr], {pr, pairs}],
    Association @@ Table[{2, tr} -> wOf[tr], {tr, triples}]];
  siteSecs = Join[Association @@ Table[{0, i} -> supp[[i]], {i, m}],
    Association @@ Table[{1, pr} -> sPair[pr], {pr, pairs}],
    Association @@ Table[{2, tr} -> sTriple[tr], {tr, triples}]];
  repOf = <||>; basis = <||>;
  Do[basis[site] = Flatten[Table[
      Do[repOf[{site, s}] = fib[[1]], {s, fib}];
      {site, #} & /@ Rest[fib],
      {fib, With[{U = siteU[site]}, With[{int = Intersection[U, C0]},
         GatherBy[siteSecs[site], restrictSection[U, #, int] &]]]}], 1], {site, Keys[siteU]}];
  {b0, b1, b2} = Table[Flatten[Table[basis[site],
      {site, Select[Keys[siteU], First[#] == deg &]}], 1], {deg, 0, 2}];
  {i0, i1, i2} = AssociationThread[#, Range[Length[#]]] & /@ {b0, b1, b2};
  c0rel = Length[b0]; c1rel = Length[b1]; c2rel = Length[b2];
  SetAttributes[relExpand, HoldFirst];
  relExpand[mat_, tgt_, idx_, sU_, s_, r_, sgn_, col_] := Module[{W = siteU[tgt], a, b},
    a = restrictSection[sU, s, W]; b = restrictSection[sU, r, W];
    If[a =!= b,
     If[a =!= repOf[{tgt, a}], mat[[idx[{tgt, a}], col]] += sgn];
     If[b =!= repOf[{tgt, b}], mat[[idx[{tgt, b}], col]] -= sgn]]];
  d0 = ConstantArray[0, {c1rel, c0rel}];
  Do[With[{site = b0[[col, 1]], s = b0[[col, 2]]},
    With[{i = site[[2]], r = repOf[{site, s}]},
     Do[If[MemberQ[pr, i],
       relExpand[d0, {1, pr}, i1, ctxs[[i]], s, r, If[i == pr[[2]], 1, -1], col]],
      {pr, pairs}]]], {col, c0rel}];
  d1 = If[c2rel == 0, {}, ConstantArray[0, {c2rel, c1rel}]];
  If[c2rel > 0,
   Do[With[{site = b1[[col, 1]], v = b1[[col, 2]]},
     With[{pr = site[[2]], r = repOf[{site, v}]},
      Do[With[{i = tr[[1]], j = tr[[2]], k = tr[[3]]},
        Do[With[{pp = ps[[1]], sgn = ps[[2]]},
          If[pp === pr, relExpand[d1, {2, tr}, i2, uOf[pr], v, r, sgn, col]]],
         {ps, {{{j, k}, 1}, {{i, k}, -1}, {{i, j}, 1}}}]],
       {tr, triples}]]], {col, c1rel}]];
  rk0 = If[c1rel == 0 || c0rel == 0, 0, MatrixRank[d0]];
  rk1 = If[d1 === {} || c1rel == 0, 0, MatrixRank[d1]];
  closes = d1 === {} || c0rel == 0 || Max[Abs[d1 . d0]] == 0;
  torsion = If[c1rel == 0 || c0rel == 0, {},
   Select[Abs[Select[Diagonal[SmithDecomposition[d0][[2]]], # =!= 0 &]], # > 1 &]];
  sm = If[c1rel == 0 || c0rel == 0, None, SmithDecomposition[d0]];
  orders = Association @@ Table[s0 -> Module[{t, z},
      t = Table[With[{int = Intersection[ctxs[[i]], C0]},
         SelectFirst[supp[[i]], restrictSection[ctxs[[i]], #, int] === restrictSection[C0, s0, int] &]], {i, m}];
      If[MemberQ[t, Missing["NotFound"]], Indeterminate,
       z = ConstantArray[0, c1rel];
       Do[With[{U = uOf[pr], a = restrictSection[ctxs[[pr[[2]]]], t[[pr[[2]]]], uOf[pr]],
          b = restrictSection[ctxs[[pr[[1]]]], t[[pr[[1]]]], uOf[pr]]},
         If[a =!= b,
          If[a =!= repOf[{{1, pr}, a}], z[[i1[{{1, pr}, a}]]] += 1];
          If[b =!= repOf[{{1, pr}, b}], z[[i1[{{1, pr}, b}]]] -= 1]]], {pr, pairs}];
       Which[
        c1rel == 0, 1,
        d1 =!= {} && Max[Abs[d1 . z]] != 0, cocyclesOK = False; Indeterminate,
        MatrixRank[MapThread[Append, {d0, z}]] > rk0, Infinity,
        True, latticeOrder[sm, z, c0rel]]]], {s0, supp[[c0]]}];
  <|"Context" -> C0, "CochainRanks" -> {c0rel, c1rel, c2rel},
    "H0Rank" -> c0rel - rk0, "H1FreeRank" -> c1rel - rk0 - rk1, "H1Torsion" -> torsion,
    "ComplexCloses" -> closes, "GammaCocyclesVerified" -> cocyclesOK,
    "GammaOrders" -> orders|>];

(* affine Z_d-solvability of A x = b (mod d) for ANY d >= 2 (Z_d need not be a
   field): from the Smith normal form A = U r V, x exists iff GCD(r_ii, d) | (U b)_i
   for every row (r_ii = 0 past the diagonal, GCD(0, d) = d). Reduces to the GF(d)
   rank test when d is prime. *)
avnSolvableQ[A_, b_, d_] := A === {} || Module[{sm = SmithDecomposition[A], c, rows, cols},
  c = Mod[sm[[1]] . b, d]; rows = Length[A]; cols = Length[A[[1]]];
  AllTrue[Range[rows], Mod[c[[#]], GCD[If[# <= Min[rows, cols], sm[[2]][[#, #]], 0], d]] == 0 &]];

AvNArgument[scen_Association, e_List, d : _Integer : 2] := Module[
  {ctxs = scen["Contexts"], secs = scen["Sections"], X, outs, m, ctxIdx, supp,
   xIdx, units, eqs = {}, A, b, con},
  If[d < 2, Message[AvNArgument::mod, d]; Return[$Failed]];
  X = Lookup[scen, "X", Union @@ ctxs];
  outs = Lookup[scen, "Outcomes", Association[# -> {0, 1} & /@ X]];
  If[! AllTrue[X, Sort[outs[#]] === Range[0, d - 1] &],
   Message[AvNArgument::outs, d, d - 1]; Return[$Failed]];
  m = Length[ctxs]; ctxIdx = AssociationThread[ctxs -> Range[m]];
  xIdx = AssociationThread[X -> Range[Length[X]]];
  units = Select[Range[d - 1], GCD[#, d] == 1 &];
  supp = Table[{}, {m}];
  Do[If[e[[k]] > 10^-12, AppendTo[supp[[ctxIdx[secs[[k, 1]]]]], secs[[k, 2]]]], {k, Length[secs]}];
  (* per context: every nonzero coefficient vector whose support-value is constant
     mod d, canonicalized under multiplication by units (unit multiples are the same
     equation; NON-unit multiples are kept - they carry the extra content of a
     composite ring and reduce to leading-entry-1 exactly when d is prime) *)
  Do[If[supp[[i]] =!= {}, Module[{S = supp[[i]], reps},
    reps = DeleteDuplicates[Cases[Rest[Tuples[Range[0, d - 1], Length[ctxs[[i]]]]],
       c_ /; Length[DeleteDuplicates[Mod[c . #, d] & /@ S]] == 1 :>
        First[Sort[Table[{Mod[u c, d], Mod[u First[Mod[c . #, d] & /@ S], d]}, {u, units}]]]]];
    Do[AppendTo[eqs, {i, ce[[1]], ce[[2]]}], {ce, reps}]]], {i, m}];
  A = Table[Module[{row = ConstantArray[0, Length[X]]},
     MapThread[(row[[xIdx[#1]]] = #2) &, {ctxs[[eq[[1]]]], eq[[2]]}]; row], {eq, eqs}];
  b = eqs[[All, 3]]; con = avnSolvableQ[A, b, d];
  <|"Modulus" -> d, "EquationCount" -> Length[eqs],
    "Equations" -> ({ctxs[[#[[1]]]], #[[2]], #[[3]]} & /@ eqs),
    "Consistent" -> con, "AvN" -> ! con|>];

(* ------------------------------------------------------------------ *)
(* the Lie-Poisson interface                                           *)
(* ------------------------------------------------------------------ *)

So3Axis[m_?MatrixQ] := {m[[3, 2]], m[[1, 3]], m[[2, 1]]};

CascadeGenerators[] := Module[{vecs = KCBSDirections[], frame, sf, transitions},
  frame[a_, b_] := {a, b, Cross[a, b]};
  sf = {frame[vecs[[1]], vecs[[2]]], frame[vecs[[3]], vecs[[2]]], frame[vecs[[3]], vecs[[4]]],
        frame[vecs[[5]], vecs[[4]]], frame[vecs[[5]], vecs[[1]]]};
  transitions = Table[sf[[k + 1]] . Transpose[sf[[k]]], {k, 4}];
  MatrixLog /@ N[transitions]];

DLADimension[gens_List] := Module[{comms},
  comms = Flatten[Table[So3Axis[gens[[i]] . gens[[j]] - gens[[j]] . gens[[i]]],
    {i, Length[gens]}, {j, i + 1, Length[gens]}], 1];
  MatrixRank[Join[So3Axis /@ gens, comms], Tolerance -> 10^-8]];

CycleORProduct[ns_List] := Module[{V = Tuples[Range[0, # - 1] & /@ ns], adj},
  adj[u_, v_] := Or @@ MapThread[MemberQ[{1, #3 - 1}, Mod[#1 - #2, #3]] &, {u, v, ns}];
  Graph[V, UndirectedEdge @@@ Select[Subsets[V, {2}], adj @@ # &]]];

QuantumEventProbability[n_Integer] := Simplify[Cos[Pi/n]/(1 + Cos[Pi/n])];

PentagonRing[nb_Integer /; nb >= 3] := Module[{a, b, x, edges},
  edges = Flatten[Table[{{a[Mod[k - 1, nb]], b[Mod[k - 1, nb]]}, {b[Mod[k - 1, nb]], a[k]},
      {a[k], b[k]}, {b[k], x[k]}, {x[k], a[Mod[k - 1, nb]]}}, {k, 0, nb - 1}], 1];
  Graph[DeleteDuplicates[Flatten[edges]], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];
End[];
EndPackage[];
