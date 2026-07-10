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
PossibilisticSupport::usage = "PossibilisticSupport[scen, e] gives the possibilistic global support S_e of the empirical model e: association with \"Size\" (number of global assignments consistent with the support of e) and \"Empty\" (True means strong contextuality, AB Sec. 6).";
CycleCoboundary::usage = "CycleCoboundary[n] gives the cellular-sheaf coboundary \[Delta] (2n x 4n) of the n-cycle cover with marginalization restriction maps (Hansen-Ghrist, arXiv:1808.01513): ker(\[Delta]\[Transpose]\[Delta]) = the no-disturbance models.";
HarmonicResidual::usage = "HarmonicResidual[delta, e] gives Norm[delta . e]: the no-disturbance (signalling) residual of the model e. It vanishes on every no-disturbance model and is provably blind to contextuality - use it as a projector diagnostic, not a contextuality measure.";

(* -- the Lie-Poisson interface of the KCBS cascade -- *)
CascadeGenerators::usage = "CascadeGenerators[] gives the four so(3) generators (matrix logarithms of the stage-frame transition rotations) of the Lapkiewicz KCBS cascade.";
So3Axis::usage = "So3Axis[m] gives the rotation-axis vector (vee map) of the antisymmetric 3x3 matrix m.";
DLADimension::usage = "DLADimension[gens] gives the dimension of the dynamical Lie algebra generated by the antisymmetric matrices gens after one commutator step: the rank of the generator axes together with all pairwise commutator axes.";

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
    "CliqueCount" -> Length[cliques], "Omega" -> Max[Length /@ cliques]|>];

(* ------------------------------------------------------------------ *)
(* the n-cycle scenario                                                *)
(* ------------------------------------------------------------------ *)

CycleScenario[n_Integer /; n >= 3] := Module[{ctxs, glob, secs, M},
  ctxs = Table[{i, Mod[i + 1, n]}, {i, 0, n - 1}];
  glob = Tuples[{0, 1}, n];
  secs = Flatten[Table[{c, s}, {c, ctxs}, {s, Tuples[{0, 1}, 2]}], 1];
  M = Table[Boole[{t[[sec[[1, 1]] + 1]], t[[sec[[1, 2]] + 1]]} == sec[[2]]], {sec, secs}, {t, glob}];
  <|"n" -> n, "Contexts" -> ctxs, "Sections" -> secs, "Incidence" -> M, "Assignments" -> glob|>];

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

End[];
EndPackage[];
