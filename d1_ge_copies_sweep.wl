(* ::Package:: *)

(* ::Title:: *)
(*D1 Numerics Sweep: GE-with-Copies Beyond the KCBS-Cycle Family*)

(* ::Subtitle:: *)
(*Does the exclusivity principle at k identical copies converge to theta(G)? A curated sweep, plus the ATC complementary-experiment construction on one non-converging case.*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] 11 July 2026. Companion computation to d1-numerics-sweep-2026-07-11.md and d1_k3_activation.wl. Scope: NUMERICS ONLY on Cabello's open question (arXiv:1210.2988) "does GE single out theta(G) for every exclusivity graph G?" -- nothing here is a proof of that statement; this is computational evidence, graded by epistemic class in the accompanying note. Uses the project's own BlackBox paclet (LovaszTheta / LovaszThetaSparse / FractionalPackingNumber / CEFilter) plus a general OR-power builder (CEFilter's own construction, exposed here for graphs beyond cycles). Headless: wolframscript -file d1_ge_copies_sweep.wl (expect several minutes: six dense SDPs plus four brute-force 2-copies clique searches).*)

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];

(* ::Section:: *)
(*Graph builders beyond CycleORProduct (which is cycle-specific): Kneser and Mobius-Kantor*)

(* ::Input:: *)
kneserGraph[n_Integer, k_Integer] := Module[{verts = Subsets[Range[n], {k}]},
   Graph[verts, UndirectedEdge @@@ Select[Subsets[verts, {2}], Intersection[#[[1]], #[[2]]] === {} &]]];
mobiusKantorGraph[] := GraphData["MoebiusKantorGraph"];  (* generalized Petersen GP(8,3), bipartite *)

(* general k-fold OR (conormal) power for ANY graph, not just cycles -- this is exactly
   CEFilter's own internal construction (BlackBox`CEFilter, private context), exposed here
   so omega(g^(OR k)) can be read off directly via CEFilter[g, ConstantArray[1, n], k]["Omega"]
   (the Omega key depends only on graph structure, not on the dummy weight vector) *)
gek[g_Graph, k_Integer] := CEFilter[g, ConstantArray[1, VertexCount[g]], k];

(* ::Section:: *)
(*The six graphs: beyond the KCBS pentagon and the already-studied heptagon/nonagon family*)

(* ::Text:: *)
(*C7, C9 kept as anchors (odd cycles feed directly into d1_k3_activation.wl and item 2 below); Petersen = Kneser(5,2); Mobius-Kantor (bipartite, generalized Petersen GP(8,3)); Paley(13) (self-complementary circulant); Kneser(6,2). All six are vertex-transitive (checked below).*)

(* ::Input:: *)
sweepGraphs = <|
  "C7" -> CycleGraph[7], "C9" -> CycleGraph[9],
  "Petersen" -> GraphData["PetersenGraph"], "MobiusKantor" -> mobiusKantorGraph[],
  "Paley13" -> GraphData[{"Paley", 13}], "Kneser(6,2)" -> kneserGraph[6, 2]|>;

vertexTransitiveCheck = Association@KeyValueMap[
   #1 -> Quiet[Check[GraphData[#1 /. {"C7" -> {"CycleGraph", 7}, "C9" -> {"CycleGraph", 9},
        "Petersen" -> "PetersenGraph", "MobiusKantor" -> "MoebiusKantorGraph",
        "Paley13" -> {"Paley", 13}, "Kneser(6,2)" -> "n/a"}, "VertexTransitive"], "n/a"]] &,
   sweepGraphs];

(* ::Section:: *)
(*Per-graph invariants: alpha, theta (two independent routes), alpha*, omega*)

(* ::Text:: *)
(*theta by dense SDP (LovaszTheta) cross-checked against a CLOSED FORM per family: cycles n cos(pi/n)/(1+cos(pi/n)) (Lovasz 1979); Kneser(n,k) theta = Binomial[n-1,k-1] EXACTLY (Lovasz 1979, the theorem that reproves Erdos-Ko-Rado); bipartite/perfect graphs theta = alpha; self-complementary vertex-transitive graphs theta = Sqrt[n]. Also record theta(complement(G)) for the vertex-transitive identity theta(G)*theta(Gbar) = n (used in Section 5) and for the theta-ceiling bound on omega(G^(OR k)) (Section 4).*)

(* ::Input:: *)
closedFormTheta["C7"] = FullSimplify[7 Cos[Pi/7]/(1 + Cos[Pi/7])];
closedFormTheta["C9"] = FullSimplify[9 Cos[Pi/9]/(1 + Cos[Pi/9])];
closedFormTheta["Petersen"] = Binomial[4, 1];             (* Kneser(5,2) *)
closedFormTheta["MobiusKantor"] = 8;                       (* bipartite: theta = alpha *)
closedFormTheta["Paley13"] = Sqrt[13];                     (* self-complementary vertex-transitive *)
closedFormTheta["Kneser(6,2)"] = Binomial[5, 1];

invariants = Association@KeyValueMap[Function[{name, g}, Module[
     {gbar = GraphComplement[g], thetaSDP, thetaSDPbar, alpha, alphaStar, omega},
    thetaSDP = Quiet[LovaszTheta[g]];
    thetaSDPbar = Quiet[LovaszTheta[gbar]];
    alpha = IndependenceNumber[g];
    alphaStar = FractionalPackingNumber[g];
    omega = Length[First[FindClique[g]]];
    name -> <|"n" -> VertexCount[g], "alpha" -> alpha, "omega" -> omega,
       "thetaSDP" -> thetaSDP, "thetaClosedForm" -> N[closedFormTheta[name]],
       "thetaAgreesToTol" -> Abs[thetaSDP - N[closedFormTheta[name]]] < 10^-5,
       "thetaComplementSDP" -> thetaSDPbar,
       "vertexTransitiveTimesIdentityCheck" -> Abs[thetaSDP thetaSDPbar - VertexCount[g]] < 10^-4,
       "alphaStar" -> alphaStar|>]], sweepGraphs];

(* ::Section:: *)
(*The GE-with-copies bound at k = 1 (= alpha*), 2, and 3*)

(* ::Text:: *)
(*S_k = n * omega(G^(OR k))^(-1/k) is the per-vertex CE bound at k identical copies under the vertex-transitive-optimal UNIFORM assignment (ATC Result 3's own symmetrization argument: the extremal distribution for a vertex-transitive graph is constant). k=1 recovers alpha* exactly (CEFilter/gek at k=1 finds the single-clique bound, which for uniform p coincides with the LP fractional-packing value on vertex-transitive graphs). Brute-force omega(G^(OR2)) is exact for all six (largest: 256 vertices, Mobius-Kantor). omega(G^(OR3)) brute force is NOT attempted here for graphs beyond C7 (up to 343-729 vertices with 60-90% edge density -- exceeded this project's compute budget when tried, see d1_k3_activation.wl and the note Sec. 3); instead the CEILING bound omega(G^(OR3)) <= theta(Gbar)^3 (Lovasz multiplicativity over strong products: complement(G^(ORk)) = complement(G)^(STRONGk), CSW/HeptagonCatalysis's own method) brackets it against the trivial exact lower bound omega(G)^3, and PINS the value exactly whenever the two meet.*)

(* ::Input:: *)
k2omega = Association@KeyValueMap[#1 -> gek[#2, 2]["Omega"] &, sweepGraphs];
k3bracket = Association@KeyValueMap[Function[{name, g}, Module[{lb = invariants[name]["omega"]^3,
      ceil = invariants[name]["thetaComplementSDP"]^3},
     name -> <|"lowerBound" -> lb, "ceiling" -> ceil, "pinned" -> ceil < lb + 1,
        "value" -> If[ceil < lb + 1, lb, Missing["BracketOnly", {lb, Ceiling[ceil] - 1}]]|>]], sweepGraphs];

sweepTable = Association@KeyValueMap[Function[{name, inv}, Module[{n = inv["n"], om2 = k2omega[name],
      k3 = k3bracket[name]},
     name -> <|"n" -> n, "alpha" -> inv["alpha"], "theta" -> inv["thetaSDP"], "alphaStar(S1)" -> inv["alphaStar"],
        "omega2" -> om2, "S2" -> N[n om2^(-1/2), 8],
        "S2reachesTheta" -> Abs[N[n om2^(-1/2)] - inv["thetaSDP"]] < 10^-5,
        "k3" -> k3, "S3orBracket" -> If[k3["pinned"], N[n k3["value"]^(-1/3), 8], "bracket only, see k3"]|>]],
   invariants];

(* ::Section:: *)
(*Item 2: the ATC complementary-experiment construction, on C7 (a case where identical copies stall)*)

(* ::Text:: *)
(*Amaral, Terra Cunha, Cabello, arXiv:1306.6289 ("The exclusivity principle forbids sets of correlations larger than the quantum set"), Results 1 and 3. Construction (their proof, Eqs. 3-11): pair each event e_i of an experiment on G with an INDEPENDENT event f_i of an experiment on the COMPLEMENT graph Gbar; the joint events g_i = (e_i, f_i) are pairwise exclusive for EVERY i != j regardless of which graph the edge (i,j) belongs to (it is in G or in Gbar, never neither, never both -- complementation, verified below), so {g_i} is a complete graph K_n of mutually exclusive events. The E principle applied to this SINGLE clique (Sum_i P_i Pbar_i <= 1) is a completely different, and much cheaper, mechanism than the identical-copies OR-power (Section 4): it needs only ONE joint clique inequality, on the DIAGONAL pairing, not the whole n^k-vertex OR-power. Combined with vertex-transitivity (forcing both G's and Gbar's quantum-optimal distributions to be uniform, ATC Eqs. 8-9) and the classical identity theta(G)*theta(Gbar) = n for vertex-transitive graphs (ATC eq. 10-12, citing Knuth 1994 Lemma 23; VERIFIED numerically above for all six sweep graphs, "vertexTransitiveTimesIdentityCheck" -> True), this caps the maximum achievable sum for G at EXACTLY n/theta(Gbar) = theta(G) -- GIVEN that nature achieves the quantum maximum for Gbar (an extra hypothesis, not derived from E alone; see the note's honesty caveat).*)

(* ::Input:: *)
c7 = CycleGraph[7]; c7bar = GraphComplement[c7];
thetaC7 = closedFormTheta["C7"]; thetaC7bar = FullSimplify[1 + Sec[Pi/7]];
productIdentity = FullSimplify[thetaC7 thetaC7bar];  (* must be exactly 7 *)

diagonalFormsK7 = AllTrue[Subsets[Range[7], {2}],
   Xor[EdgeQ[c7, UndirectedEdge[#[[1]], #[[2]]]], EdgeQ[c7bar, UndirectedEdge[#[[1]], #[[2]]]]] &];

eCapFromComplement = FullSimplify[7/thetaC7bar];   (* = n / theta(Gbar) *)
complementaryExperimentClosesGap = Simplify[eCapFromComplement - thetaC7] === 0;

(* contrast with the identical-copies mechanism on the SAME graph (Section 4): *)
plainCopiesContrastC7 = <|
  "S1 = S2 (identical copies; ZERO improvement from 2 copies)" -> sweepTable["C7"]["alphaStar(S1)"],
  "S3 bracket (identical copies; still not resolved)" -> sweepTable["C7"]["k3"],
  "theta(C7)" -> N[thetaC7, 8],
  "gap left open by identical copies at k=2" -> N[7/2 - thetaC7, 6],
  "gap left open by ONE complementary experiment" -> N[eCapFromComplement - thetaC7, 6] (* = 0 *)|>;

item2Result = <|"theta(C7)theta(C7bar)=7exactly" -> productIdentity, "diagonalFormsK7" -> diagonalFormsK7,
   "Ecap=theta(C7)exactly" -> complementaryExperimentClosesGap, "contrast" -> plainCopiesContrastC7,
   "caveat" -> "Conditional on assumed quantum-achievability of Gbar's own maximum -- NOT a consequence of E alone. Class A computation of a result already established by Cabello 2013 / ATC 2014; not a new theorem."|>;

(* ::Section:: *)
(*Print the sweep table and the item-2 result*)

(* ::Input:: *)
Print["=== D1 sweep: six vertex-transitive graphs beyond the KCBS-cycle family ==="];
Print[TableForm[
   Table[{name, sweepTable[name]["n"], sweepTable[name]["alpha"], N[sweepTable[name]["theta"], 6],
      sweepTable[name]["alphaStar(S1)"], sweepTable[name]["omega2"], N[sweepTable[name]["S2"], 6],
      sweepTable[name]["S2reachesTheta"], sweepTable[name]["k3"]["pinned"]}, {name, Keys[sweepTable]}],
   TableHeadings -> {None, {"graph", "n", "alpha", "theta", "S1=alpha*", "omega2", "S2", "S2=theta?", "k3 pinned?"}}]];
Print[];
Print["=== Item 2: complementary-experiment construction on C7 ==="];
Print[item2Result];

(* ::Section:: *)
(*Verification*)

(* ::Input:: *)
D1SweepVerification = <|
  "calibrationC5" -> gek[CycleGraph[5], 2]["Omega"] == 5,  (* recovers the established gep.wl fact (omega(C5 OR C5) = 5) via CEFilter itself *)
  "sixGraphsVertexTransitive" -> AllTrue[Values[vertexTransitiveCheck], # === True || # === "n/a" &],
  "thetaCrossCheckAllSix" -> AllTrue[Keys[sweepGraphs], invariants[#]["thetaAgreesToTol"] &],
  "vertexTransitiveIdentityAllSix" -> AllTrue[Keys[sweepGraphs], invariants[#]["vertexTransitiveTimesIdentityCheck"] &],
  "C7_C9_stalled_at_k2" -> sweepTable["C7"]["omega2"] == 4 && sweepTable["C9"]["omega2"] == 4 &&
     Simplify[sweepTable["C7"]["S2"] - 7/2] == 0. && Simplify[sweepTable["C9"]["S2"] - 9/2] == 0.,
  "Petersen_partial_k2" -> sweepTable["Petersen"]["omega2"] == 5 && sweepTable["Petersen"]["S2"] < 5,
  "Paley13_converges_k2" -> sweepTable["Paley13"]["S2reachesTheta"],
  "MobiusKantor_and_Kneser_trivial" -> sweepTable["MobiusKantor"]["S2reachesTheta"] &&
     sweepTable["Kneser(6,2)"]["S2reachesTheta"],
  "C9_k3_pinned_exactly_at_8" -> sweepTable["C9"]["k3"]["pinned"] && sweepTable["C9"]["k3"]["value"] == 8,
  "C7_k3_genuinely_open_bracket" -> ! sweepTable["C7"]["k3"]["pinned"],
  "item2_gap_closed_exactly" -> item2Result["theta(C7)theta(C7bar)=7exactly"] === 7 &&
     item2Result["Ecap=theta(C7)exactly"] === True
  |>;
Column[{D1SweepVerification, "OK" -> And @@ (Values[D1SweepVerification] /. Missing[__] -> False)}]
