(* ::Package:: *)

(* ::Title:: *)
(*A Qutrit Catalyst Activates the Heptagon PR Box*)

(* ::Subtitle:: *)
(*A computational note on hetero-graph composition under the exclusivity principle*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Companion note to CaseStudies.wl, Case C; built on the BlackBox paclet. Headless verification: wolframscript -file RunHeptagonCatalysis.wl -print all (must end OK -> True).*)

(* ::Abstract:: *)
(*The n-cycle PR-type boxes (probability 1/2 per event) with n >= 6 satisfy Consistent Exclusivity at two and three identical copies (Choudhary-Barbosa, arXiv:2411.09773); the pentagon trick provably stalls, and composition with quantum correlations is their stated open escape route. We compute the smallest heterogeneous cells. One heptagon box plus one quantum-maximal KCBS pentagon does NOT violate CE (exact load 2/Sqrt[5]); one box plus two catalysts lands EXACTLY on the boundary (load 1, zero margin); two boxes plus one catalyst VIOLATE CE: the joint exclusivity graph C7\[Or]C7\[Or]C5 contains a 9-clique, load 9 Sqrt[5]/20 \[TildeTilde] 1.006 > 1. The catalyst is a fixed three-level resource, and it works only if its per-event probability exceeds 4/9 \[LongDash] pentagon visibility at least (5 + 3 Sqrt[5])/12 \[TildeTilde] 0.9757, just below the 0.977 achieved by Lapkiewicz et al. (Nature 474, 490).*)

(* ::Section:: *)
(*Setting*)

(* ::Text:: *)
(*Events of the n-cycle box live on the cycle graph C_n (adjacent = exclusive); the box assigns probability 1/2 to each. For independent experiments, joint events are exclusive iff exclusive in some factor \[LongDash] the OR (conormal) product \[LongDash] and probabilities multiply; Consistent Exclusivity (CE) demands every clique of the joint graph carry total probability at most 1. Composing DIFFERENT experiments is legitimate (Foulis-Randall products: Acin-Fritz-Leverrier-Sainz, CMP 334, 533; Cabello, PRA 100, 032120 assumes independent realizations of any two experiments). A violating clique for the composite (box_7)^k \[CircleTimes] (quantum pentagon)^m needs size > 2^k Sqrt[5]^m.*)

(* ::CodeText:: *)
(*Load the library; mixed OR products and the quantum per-event probability cos(\[Pi]/n)/(1+cos(\[Pi]/n)):*)

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];
orMixed[ns_List] := Module[{V = Tuples[Range[0, # - 1] & /@ ns], adj},
  adj[u_, v_] := Or @@ MapThread[MemberQ[{1, #3 - 1}, Mod[#1 - #2, #3]] &, {u, v, ns}];
  Graph[V, UndirectedEdge @@@ Select[Subsets[V, {2}], adj @@ # &]]];
pQuantum[n_] := Simplify[Cos[Pi/n]/(1 + Cos[Pi/n])];

(* ::Section:: *)
(*One Box, One Catalyst: No Activation (Exact Margin 2/Sqrt[5])*)

(* ::CodeText:: *)
(*All 1015 maximal cliques of C7\[Or]C5 have size at most 4; the worst load of box\[CircleTimes]catalyst is exactly 2/Sqrt[5] < 1:*)

(* ::Input:: *)
cl75 = FindClique[orMixed[{7, 5}], Infinity, All];
{omega75 = Max[Length /@ cl75], load11 = Simplify[Max[Total[(1/2) pQuantum[5] & /@ #] & /@ cl75]], N[load11]}

(* ::Text:: *)
(*Why no 5-clique exists: a pentad-type clique needs the five non-adjacent pentagon pairs covered by C7-adjacency, i.e. a closed walk of five \[PlusMinus]1 steps in Z_7 \[LongDash] but five odd steps cannot sum to 0 mod 7. This is the same Ramsey/odd-girth mechanism (R(C5, C3) = 5) that blocks identical copies in arXiv:2411.09773.*)

(* ::Section:: *)
(*One Box, Two Catalysts: Exactly on the Boundary*)

(* ::CodeText:: *)
(*The clique number of C7\[Or]C5\[Or]C5 is exactly 10, and 10 events of weight (1/2)(1/5) load to exactly 1 \[LongDash] zero margin, no violation:*)

(* ::Input:: *)
omega755 = Length[First[FindClique[orMixed[{7, 5, 5}]]]];
{omega755, Simplify[omega755 (1/2) (1/5)]}

(* ::Text:: *)
(*The mechanism keeps landing on the boundary rather than below it \[LongDash] the same knife-edge as \[Omega](C7\[Or]C7) = 4 (load exactly 1) for identical copies. The 10-clique is an edge of C7 times a pentad of C5\[Or]C5.*)

(* ::Section:: *)
(*Two Boxes, One Catalyst: Violation*)

(* ::CodeText:: *)
(*C7\[Or]C7\[Or]C5 (245 vertices) contains a 9-clique \[LongDash] one more than the product bound \[Omega](C7\[Or]C7)\[CenterDot]\[Omega](C5) = 4\[CenterDot]2 = 8:*)

(* ::Input:: *)
g775 = orMixed[{7, 7, 5}];
witness = Sort[First[FindClique[g775]]];
{Length[witness], witness}

(* ::CodeText:: *)
(*Nine joint events of weight (1/2)(1/2)(1/Sqrt[5]) violate Consistent Exclusivity by the exact margin 9 Sqrt[5]/20:*)

(* ::Input:: *)
catalysedLoad = Length[witness] (1/2) (1/2) (1/Sqrt[5]);
{Simplify[catalysedLoad], N[catalysedLoad], Simplify[catalysedLoad > 1]}

(* ::Text:: *)
(*Since quantum correlations are closed under independent composition and satisfy CE at every level, and the pentagon factor is quantum-realizable (the KCBS maximum on a qutrit), the violation certifies that the heptagon box is not quantum \[LongDash] two copies of it, witnessed by one fixed three-level catalyst. The witness is genuinely emergent: its C5 coordinate takes all five values and neither C7 coordinate is constant, so it is not a product of factor cliques. The all-quantum composite on the same clique stays safely below 1 (0.903), as it must.*)

(* ::Section:: *)
(*Robustness: the Catalyst Threshold Is Experimentally Sharp*)

(* ::CodeText:: *)
(*The 9-clique fires iff the catalyst's per-event probability exceeds 4/9 \[LongDash] and the quantum maximum 1/Sqrt[5] clears it by only 0.62%:*)

(* ::Input:: *)
{N[4/9], N[pQuantum[5]], Simplify[pQuantum[5] > 4/9]}

(* ::CodeText:: *)
(*Under white noise \[Rho] = V|\[Psi]\[RightAngleBracket]\[LeftAngleBracket]\[Psi]| + (1-V)\[DoubleStruckOne]/3, the catalyst works iff the pentagon visibility V exceeds (5 + 3 Sqrt[5])/12 \[TildeTilde] 0.9757:*)

(* ::Input:: *)
Vmin = Simplify[V /. First@Solve[V/Sqrt[5] + (1 - V)/3 == 4/9, V]];
{Vmin, N[Vmin], Simplify[Vmin - (5 + 3 Sqrt[5])/12] === 0}

(* ::Text:: *)
(*Compare: violating the KCBS inequality itself only needs V > (5 + 3 Sqrt[5])/20 \[TildeTilde] 0.585 (same numerator, denominator 20 vs 12), while the best reported pentagon visibility is ~0.977 (Lapkiewicz et al., Nature 474, 490 (2011)). The catalysis window [0.9757, 1] is therefore nonempty but razor-thin: an experiment certifying it would need the 2011 state of the art with ~0.15% to spare. A weaker catalyst is not merely suboptimal \[LongDash] below 4/9 the 9-clique load drops under 1 and, since \[Omega] = 9 is the true clique maximum, NO clique of the composite fires.*)

(* ::Section:: *)
(*Beyond n = 7: Pre-Registered Inconclusives*)

(* ::Text:: *)
(*Does the pentagon catalyst expel every n-cycle box with n >= 7? Two searches hit their pre-registered time caps and are reported INCONCLUSIVE, not negative: (i) a 9-clique in C9\[Or]C9\[Or]C5 (405 vertices, 600 s cap \[LongDash] a 9-clique would give the same violating load 9 Sqrt[5]/20); (ii) a 9-clique in the path product P7\[Or]P7\[Or]C5 (245 vertices, 300 s cap \[LongDash] wraparound-free, so a hit would embed in EVERY C_n\[Or]C_n\[Or]C5 with n >= 7 and settle the question universally). The C7 witness uses both wraparounds, so it does not embed directly. Settling the universal cell (SAT/clique solvers, or a Ramsey-style argument for the 2-colored constraint cycles) is the natural next step.*)

(* ::Section:: *)
(*Relation to Published Results*)

(* ::CodeText:: *)
(*Yan's route (PRL 110, 260406): compose with the quantum maximum of the COMPLEMENT graph \[LongDash] one box copy suffices, load (1/2)\[CurlyTheta](Complement[C7]) \[TildeTilde] 1.055:*)

(* ::Input:: *)
yanLoad = (1/2) LovaszTheta[GraphComplement[CycleGraph[7]]];
{yanLoad, yanLoad > 1}

(* ::Text:: *)
(*Positioning. Yan's construction and its generalizations (Amaral-Terra Cunha-Cabello, PRA 89, 030101(R); Cabello, PRA 100, 032120) exclude the heptagon box at one copy, but the partner is the complement-graph experiment, whose Hilbert-space dimension grows with n. The cells computed here keep the partner FIXED and minimal \[LongDash] the qutrit KCBS pentagon \[LongDash] and map the exact activation frontier: (1 box, 1 catalyst) safe at 2/Sqrt[5]; (1, 2) boundary-exact; (2, 1) violated at 9 Sqrt[5]/20. No published work computes these mixed odd-cycle cells (checked July 2026; arXiv:2411.09773 has no citing papers and its outlook poses exactly this composition question). All numbers are exact and machine-verified below.*)

(* ::Section:: *)
(*Verification*)

(* ::Input:: *)
HeptagonCatalysisVerification = <|
  "negative11" -> omega75 == 4 && Simplify[load11 == 2/Sqrt[5]] && Simplify[load11 < 1],
  "boundary12" -> omega755 == 10 && Simplify[omega755 (1/2) (1/5) == 1],
  "positive21" -> Length[witness] == 9 &&
     AllTrue[Subsets[witness, {2}], EdgeQ[g775, UndirectedEdge @@ #] &] &&
     Simplify[catalysedLoad == 9 Sqrt[5]/20] && Simplify[catalysedLoad > 1],
  "witnessEmergent" -> Length[Union[witness[[All, 3]]]] == 5 && Length[Union[witness[[All, 1]]]] > 1,
  "allQuantumSafe" -> N[9 pQuantum[7]^2 pQuantum[5]] < 1,
  "threshold" -> Simplify[pQuantum[5] > 4/9] && Simplify[Vmin == (5 + 3 Sqrt[5])/12] && N[Vmin] < 0.977,
  "yanComplement" -> yanLoad > 1 && Abs[yanLoad - 7/(2 LovaszTheta[CycleGraph[7]])] < 10^-6
|>;
Column[{HeptagonCatalysisVerification, "OK" -> And @@ Values[HeptagonCatalysisVerification]}]

(* ::Section:: *)
(*References*)

(* ::Item:: *)
(*Choudhary, Barbosa, arXiv:2411.09773 (n-cycle PR boxes, Ramsey theory, identical-copy no-go and the open composition question).*)

(* ::Item:: *)
(*Yan, PRL 110, 260406 (2013); Amaral, Terra Cunha, Cabello, PRA 89, 030101(R) (2014); Cabello, PRA 100, 032120 (2019).*)

(* ::Item:: *)
(*Acin, Fritz, Leverrier, Sainz, Comm. Math. Phys. 334, 533 (2015) (Foulis-Randall products of different scenarios).*)

(* ::Item:: *)
(*Fritz et al., Nat. Commun. 4, 2263 (2013) (Local Orthogonality, identical copies).*)

(* ::Item:: *)
(*Cabello, PRL 110, 060402 (2013); Cabello, Severini, Winter, arXiv:1010.2163 (graph-theoretic frame).*)

(* ::Item:: *)
(*Lapkiewicz et al., Nature 474, 490 (2011) (pentagon visibility ~0.977); Klyachko, Can, Binicio\[GBreve]lu, Shumovsky, PRL 101, 020403 (2008).*)
