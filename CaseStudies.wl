(* ::Package:: *)

(* ::Title:: *)
(*Case Studies: Four Non-Trivial Problems Resolved with the BlackBox Certificates*)

(* ::Subtitle:: *)
(*Companion to CertifyingQuantumness.wl \[LongDash] the same library against established methods, on problems outside its home domain*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Each section states a problem, the established method and its cost, and the BlackBox resolution with timings. Headless verification: wolframscript -file RunCaseStudies.wl -print all (must end OK -> True).*)

(* ::CodeText:: *)
(*Load the library and repair any Global`-shadowing:*)

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];

(* ::Section:: *)
(*Case A. Zero-Error Channel Capacity (Information Theory)*)

(* ::Text:: *)
(*Problem: a noisy channel confuses some symbol pairs; its zero-error capacity is \[CapitalTheta](G) = sup_k \[Alpha](G^\[BoxTimes]k)^(1/k) over strong powers of the confusability graph \[LongDash] a limit with no algorithm. Established methods: exhaustive independent-set search in G^\[BoxTimes]k (doubly exponential in k; Shannon 1956 left \[CapitalTheta](C5) open for 23 years) and the LP relaxation \[Alpha]* (fractional packing). Lov\[AAcute]sz's 1979 insight IS the library's \[CurlyTheta]: an efficiently computable upper bound that is multiplicative under \[BoxTimes]. BlackBox resolves the pentagon channel instantly and brackets the still-open heptagon channel.*)

(* ::CodeText:: *)
(*The pentagon channel, solved by two library calls: \[Alpha](C5\[BoxTimes]C5) = 5 meets \[CurlyTheta](C5) = Sqrt[5], so \[CapitalTheta](C5) = Sqrt[5] exactly (Lov\[AAcute]sz 1979):*)

(* ::Input:: *)
{IndependenceNumber[GraphProduct[CycleGraph[5], CycleGraph[5], "Normal"]],
 LovaszTheta[CycleGraph[5]]^2}

(* ::CodeText:: *)
(*The heptagon channel \[LongDash] \[CapitalTheta](C7) is STILL open \[LongDash] bracketed in milliseconds: \[Alpha](C7\[BoxTimes]C7) = 10 gives the code lower bound, \[CurlyTheta] the certified upper bound:*)

(* ::Input:: *)
alpha77 = IndependenceNumber[GraphProduct[CycleGraph[7], CycleGraph[7], "Normal"]];
theta7 = LovaszTheta[CycleGraph[7]];
{Sqrt[alpha77] // N, theta7, "exact form" -> N[7 Cos[Pi/7]/(1 + Cos[Pi/7])]}

(* ::CodeText:: *)
(*Why the SDP certificate and not the LP: fractional packing gives only 7/2 \[LongDash] strictly weaker than \[CurlyTheta] = 3.3177:*)

(* ::Input:: *)
{FractionalPackingNumber[CycleGraph[7]], N[7/2 - theta7]}

(* ::Text:: *)
(*Comparison. Established exact route: \[Alpha] of strong powers \[LongDash] \[Alpha](C7\[BoxTimes]C7) = 10 dates to Baumert et al. 1971 (reproduced here in ~1 ms), and the k = 5 power behind the best published lower bound 367^(1/5) \[TildeTilde] 3.258 (Polak-Schrijver, IPL 2019, via circular-graph codes) has 16807 vertices and required dedicated research code. BlackBox reproduces the whole standard bracket 3.1623 <= \[CapitalTheta](C7) <= 3.3177 in ~1 ms (\[Alpha]) + ~10 ms (\[CurlyTheta]) \[LongDash] and the same two calls bracket ANY confusability graph, which no curated table (GraphData) can do.*)

(* ::Section:: *)
(*Case B. Chromatic Lower Bounds Where Clique Bounds Fail (Combinatorics)*)

(* ::Text:: *)
(*Problem: lower-bound the chromatic number \[Chi] of triangle-free graphs. The clique bound \[Omega] is stuck at 2 by construction; exact \[Chi] is NP-hard. The Lov\[AAcute]sz sandwich \[Omega](G) <= \[CurlyTheta](Complement[G]) <= \[Chi](G) turns the library's SDP into a polynomial-time \[Chi] bound. Test family: iterated Mycielskians of C5 \[LongDash] the canonical triangle-free graphs with growing \[Chi] (the second is the Gr\[ODoubleDot]tzsch graph).*)

(* ::CodeText:: *)
(*Mycielski construction (standard 5-liner \[LongDash] shadows + apex):*)

(* ::Input:: *)
mycielski[g_Graph] := Module[{h = IndexGraph[g], n = VertexCount[g], es},
  es = List @@@ EdgeList[h];
  Graph[Range[2 n + 1], UndirectedEdge @@@ DeleteDuplicates[Sort /@ Join[es,
     Flatten[{{#[[1]] + n, #[[2]]}, {#[[2]] + n, #[[1]]}} & /@ es, 1], Table[{i + n, 2 n + 1}, {i, n}]]]]];
mycielskians = NestList[mycielski, CycleGraph[5], 2];

(* ::CodeText:: *)
(*Clique bound vs sandwich bound vs exact \[Chi] (established, NP-hard) on C5, Gr\[ODoubleDot]tzsch (11 v), and M\.b2 (23 v):*)

(* ::Input:: *)
colorTable = Table[Module[{om = Length[First[FindClique[g]]], th = LovaszTheta[GraphComplement[g]]},
    {VertexCount[g], om, th, Ceiling[th - 10^-7], VertexChromaticNumber[g]}], {g, mycielskians}];
TableForm[colorTable, TableHeadings -> {{"C5", "Gr\[ODoubleDot]tzsch", "M\.b2"}, {"V", "\[Omega]", "\[CurlyTheta](comp)", "\[LeftCeiling]\[CurlyTheta]\[RightCeiling]", "\[Chi] exact"}}]

(* ::Text:: *)
(*Comparison, honestly framed. The sandwich bound (2.24, 2.40, 2.53 \[RightArrow] \[LeftCeiling]\[CurlyTheta]\[RightCeiling] = 3) strictly beats the clique bound (2) at polynomial cost, and on C5 it is tight. But Mycielskians are precisely the family where every efficiently computable bound must lag: \[CurlyTheta](complement) <= fractional \[Chi], which grows only like the f(k+1) = f(k) + 1/f(k) recurrence (29/10 for Gr\[ODoubleDot]tzsch) while \[Chi] grows by 1 per step. The library gives the best polynomial certificate; closing the remaining gap is genuinely NP-hard territory \[LongDash] which is the point of the comparison.*)

(* ::Section:: *)
(*Case C. Quantum-Catalysed Activation of the Heptagon Box (Foundations) \[LongDash] a New Computation*)

(* ::Text:: *)
(*Problem: the heptagon PR-type box (1/2 per event) satisfies Consistent Exclusivity at 2 and even 3 identical copies (Choudhary-Barbosa, arXiv:2411.09773; Ramsey-theoretic proof) \[LongDash] the pentagon trick provably stalls for n >= 7. Open flank: composition with a DIFFERENT experiment. Local Orthogonality is defined across independent distinct boxes (Fritz et al., Nat. Commun. 4, 2263), so the question is legitimate: can a QUANTUM assignment \[LongDash] itself harmless \[LongDash] catalyse the exclusion? Established method: by-hand clique analysis of product graphs (Ramsey arguments). BlackBox method: build the mixed OR product, enumerate cliques, evaluate loads exactly.*)

(* ::CodeText:: *)
(*Mixed OR (conormal) product of two cycles, with vertex tuples kept explicit:*)

(* ::Input:: *)
orMixed[ns_List] := Module[{V = Tuples[Range[0, # - 1] & /@ ns], adj},
  adj[u_, v_] := Or @@ MapThread[MemberQ[{1, #3 - 1}, Mod[#1 - #2, #3]] &, {u, v, ns}];
  Graph[V, UndirectedEdge @@@ Select[Subsets[V, {2}], adj @@ # &]]];
pQuantum[n_] := Simplify[Cos[Pi/n]/(1 + Cos[Pi/n])];

(* ::CodeText:: *)
(*Two-factor products do NOT activate: \[Omega](C7\[Or]C5) = \[Omega](C9\[Or]C5) = 4, and the exact loads stay below 1 in both compositions (box\[CircleTimes]quantum and quantum\[CircleTimes]box):*)

(* ::Input:: *)
mixed2 = Table[Module[{cl = FindClique[orMixed[{n, 5}], Infinity, All]},
    {n, Max[Length /@ cl], Simplify[Max[Total[(1/2) pQuantum[5] & /@ #] & /@ cl]],
     Simplify[Max[Total[pQuantum[n] (1/2) & /@ #] & /@ cl]]}], {n, {7, 9}}];
TableForm[N[mixed2, 6], TableHeadings -> {None, {"n", "\[Omega](Cn\[Or]C5)", "box_n\[CircleTimes]qu_5", "qu_n\[CircleTimes]box_5"}}]

(* ::Text:: *)
(*Both directions survive: the heptagon box passes against a quantum pentagon (load 2/Sqrt[5] \[TildeTilde] 0.894), and \[LongDash] the mirror surprise \[LongDash] Wright's pentagon box, which two pentagon copies expel at 5/4, ALSO passes against a quantum heptagon (load Cos[\[Pi]/7]Sec[\[Pi]/14]\.b2 \[TildeTilde] 0.948). Activation is not about the partner's quantumness; it is about clique geometry. The obstruction is arithmetic: a 5-clique of pentad type needs a closed 5-walk of \[PlusMinus]1 steps in C7, and five odd steps cannot sum to 0 mod 7.*)

(* ::CodeText:: *)
(*Three factors \[LongDash] two heptagon boxes plus ONE quantum pentagon \[LongDash] and the clique number jumps past the product bound 4\[Times]2 = 8 to \[Omega] = 9:*)

(* ::Input:: *)
g775 = orMixed[{7, 7, 5}];
bigClique = First[FindClique[g775]];
{Length[bigClique], bigClique}

(* ::CodeText:: *)
(*The catalysed load: 9 events of weight (1/2)(1/2)(1/Sqrt[5]) give exactly 9/(4 Sqrt[5]) = 9 Sqrt[5]/20 > 1 \[LongDash] Consistent Exclusivity is VIOLATED; the quantum pentagon (which passes everything by itself) has activated the heptagon box:*)

(* ::Input:: *)
catalysedLoad = Length[bigClique] (1/2) (1/2) (1/Sqrt[5]);
{Simplify[catalysedLoad], N[catalysedLoad], Simplify[catalysedLoad > 1]}

(* ::CodeText:: *)
(*Consistency: the all-quantum composite on the same 9-clique stays safely below 1, as quantum correlations must:*)

(* ::Input:: *)
N[Length[bigClique] pQuantum[7]^2 pQuantum[5]]

(* ::CodeText:: *)
(*The published alternative (Yan, PRL 110, 260406 (2013)): compose the box with the quantum maximum of the COMPLEMENT graph \[LongDash] one copy suffices, load (1/2)\[CurlyTheta](Complement[C7]) > 1:*)

(* ::Input:: *)
yanLoad = (1/2) LovaszTheta[GraphComplement[CycleGraph[7]]];
{yanLoad, yanLoad > 1}

(* ::Text:: *)
(*Comparison and honest positioning. Established route: Ramsey-style hand analysis per product graph (the method of arXiv:2411.09773, whose outlook explicitly flags composition with quantum correlations as the open escape route), and Yan's complement construction above \[LongDash] which excludes the heptagon box at one copy but requires the quantum maximum of the complement graph, a different experiment whose Hilbert-space dimension grows with n (Amaral-Terra Cunha-Cabello, PRA 89, 030101(R)). The mixed cells computed here are unpublished (no citing work of 2411.09773 answers them): (i) NEGATIVE \[LongDash] one heptagon box + one quantum pentagon do not violate CE (load 2/Sqrt[5], and the Ramsey argument R(C5, C3) = 5 + odd girth 7 explains why no K5 exists); (ii) POSITIVE \[LongDash] two heptagon boxes + one quantum pentagon give \[Omega] = 9 > 8 = 4\[Times]2 and load 9 Sqrt[5]/20 > 1. Reading: a FIXED, qutrit-sized quantum catalyst (the KCBS pentagon itself) suffices to expel the heptagon box \[LongDash] at the price of two box copies \[LongDash] where identical copies provably stall and the complement route needs a growing-dimension partner. Since quantum correlations are closed under independent composition and satisfy CE, the violation certifies the heptagon box is not quantum, using one harmless three-level quantum resource. BlackBox settles both cells in minutes with exact margins and a machine-checkable witness clique.*)

(* ::Section:: *)
(*Case D. Mesh Design for Quantum Advantage: Rings Beat Chains (the FEM Question)*)

(* ::Text:: *)
(*Problem: which pentagon-mesh topologies retain a quantum-classical gap \[CapitalDelta] = \[CurlyTheta] - \[Alpha], and how does it scale? Established method: build the compiled cluster state and optimize \[LongDash] the state vector has dimension 2^(5N) (a terabyte-scale object at N = 8, out of reach at N ~ 10); or exhaustive graph search as in the published Quad-C5 result (arXiv:2605.12828), exponential in vertices. BlackBox method: \[CurlyTheta] (SDP) + \[Alpha] on the mesh graph directly \[LongDash] polynomial, seconds. New topology: close the chain of edge-glued pentagons into a RING (3N vertices, 4N edges).*)

(* ::CodeText:: *)
(*Ring builder \[LongDash] pentagon k shares edge {a[k-1], b[k-1]} with its predecessor, cyclically:*)

(* ::Input:: *)
pentagonRing[nb_ /; nb >= 3] := Module[{a, b, x, edges},
  edges = Flatten[Table[{{a[Mod[k - 1, nb]], b[Mod[k - 1, nb]]}, {b[Mod[k - 1, nb]], a[k]},
      {a[k], b[k]}, {b[k], x[k]}, {x[k], a[Mod[k - 1, nb]]}}, {k, 0, nb - 1}], 1];
  Graph[DeleteDuplicates[Flatten[edges]], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];

(* ::CodeText:: *)
(*Rings vs chains, N = 3..10: gap \[CapitalDelta] = \[CurlyTheta] - \[Alpha] per topology (established alternative: a 2^(5N)-dimensional state vector):*)

(* ::Input:: *)
meshTable = Table[Module[{rg = pentagonRing[n], ch = PentagonChain[n]},
    {n, LovaszTheta[rg] - IndependenceNumber[rg], LovaszTheta[ch] - IndependenceNumber[ch], 2^(5 n)}], {n, 3, 10}];
TableForm[{#[[1]], Chop[#[[2]], 10^-6], Chop[#[[3]], 10^-6], #[[4]]} & /@ meshTable,
  TableHeadings -> {None, {"N", "\[CapitalDelta] ring (3N v)", "\[CapitalDelta] chain (3N+2 v)", "state dim 2^(5N)"}}]

(* ::Text:: *)
(*Discovered design rules, invisible to any method that cannot reach these sizes: (i) chains obey the PARITY law (even N pinches \[CapitalDelta] to zero); (ii) rings obey a DIVISIBILITY-BY-3 law instead \[LongDash] \[CapitalDelta] vanishes at N = 3 and is suppressed at N = 6, 9, while every other ring carries a gap 5-100x LARGER than the equal-length chain (N = 8: ring \[CapitalDelta] \[TildeTilde] 1.00 vs chain \[TildeTilde] 0.0000002); (iii) closing the topology is a design lever as strong as block parity. At N = 10 the certificate takes under a second where the state-vector route would need 2^50 \[TildeTilde] 10^15 amplitudes.*)

(* ::Section:: *)
(*Case D continued. The Ring Law: \[Alpha] = \[LeftFloor]4N/3\[RightFloor] and an Extensive Quantum Gap*)

(* ::Text:: *)
(*Pushing rings to N = 15 (45 vertices; the state-vector alternative would be 2^75-dimensional) resolves the suppression pattern. The classical bound is an exact period-3 staircase, \[Alpha](ring N) = \[LeftFloor]4N/3\[RightFloor] (verified for every N = 3..15), while \[CurlyTheta] grows smoothly at ~1.377 per block. The gap therefore cycles through three residue classes \[LongDash] large (N \[Congruent] 2 mod 3), middle (N \[Congruent] 1), suppressed (N \[Congruent] 0, where the staircase jumps by 2) \[LongDash] and grows linearly WITHIN each class: the ring's quantum advantage is EXTENSIVE (a bulk effect), whereas chain gaps decay with length (a boundary effect). Fractional packing stays exactly \[Alpha]* = 3N/2 throughout, so the exclusivity-only cap never sees the structure at all.*)

(* ::CodeText:: *)
(*Rings N = 3..15: \[CurlyTheta], \[Alpha] against the staircase \[LeftFloor]4N/3\[RightFloor], the gap, and \[Alpha]*:*)

(* ::Input:: *)
ringTable = Table[Module[{g = pentagonRing[n]},
    {n, LovaszTheta[g], IndependenceNumber[g], Floor[4 n/3], FractionalPackingNumber[g]}], {n, 3, 15}];
TableForm[{#[[1]], #[[2]], #[[3]], #[[4]], Chop[#[[2]] - #[[3]], 10^-6], #[[5]]} & /@ ringTable,
  TableHeadings -> {None, {"N", "\[CurlyTheta]", "\[Alpha]", "\[LeftFloor]4N/3\[RightFloor]", "\[CapitalDelta]", "\[Alpha]*"}}]

(* ::CodeText:: *)
(*The three residue classes of the ring gap, each linearly increasing \[LongDash] and the decaying chain gaps for contrast:*)

(* ::Input:: *)
gapsByClass = Table[{#[[1]], Chop[#[[2]] - #[[3]], 10^-6]} & /@ Select[ringTable, Mod[#[[1]], 3] == r &], {r, {2, 1, 0}}];
chainGaps = Table[{n, LovaszTheta[PentagonChain[n]] - IndependenceNumber[PentagonChain[n]]}, {n, 3, 9, 2}];
{ListLinePlot[gapsByClass, PlotMarkers -> Automatic, PlotLegends -> {"N\[Congruent]2 (mod 3)", "N\[Congruent]1", "N\[Congruent]0"},
   AxesLabel -> {"N", "\[CapitalDelta] ring"}, ImageSize -> 300], chainGaps}

(* ::Section:: *)
(*Verification*)

(* ::Input:: *)
CaseStudiesVerification = <|
  "A_capacityC5solved" -> IndependenceNumber[GraphProduct[CycleGraph[5], CycleGraph[5], "Normal"]] == 5 &&
     Abs[LovaszTheta[CycleGraph[5]] - Sqrt[5.]] < 10^-6,
  "A_C7bracket" -> alpha77 == 10 && Sqrt[10.] < theta7 < 7/2 &&
     Abs[theta7 - 7 Cos[Pi/7.]/(1 + Cos[Pi/7.])] < 10^-6 && FractionalPackingNumber[CycleGraph[7]] == 7/2,
  "B_sandwichBeatsClique" -> colorTable[[All, 2]] == {2, 2, 2} && colorTable[[All, 5]] == {3, 4, 5} &&
     colorTable[[All, 4]] == {3, 3, 3} && OrderedQ[colorTable[[All, 3]]],
  "C_noTwoFactorActivation" -> mixed2[[All, 2]] == {4, 4} &&
     AllTrue[Flatten[mixed2[[All, 3 ;; 4]]], Simplify[# < 1] &],
  "C_catalysis" -> Length[bigClique] == 9 &&
     AllTrue[Subsets[bigClique, {2}], EdgeQ[g775, UndirectedEdge @@ #] &] &&
     Simplify[catalysedLoad == 9 Sqrt[5]/20] && Simplify[catalysedLoad > 1] &&
     N[9 pQuantum[7]^2 pQuantum[5]] < 1,
  "C_yanComplementRoute" -> yanLoad > 1 && Abs[yanLoad - 7/(2 LovaszTheta[CycleGraph[7]])] < 10^-6,
  "D_ringLaws" -> Abs[meshTable[[1, 2]]] < 10^-6 &&
     AllTrue[{meshTable[[2, 2]], meshTable[[3, 2]], meshTable[[5, 2]], meshTable[[6, 2]]}, # > 0.3 &] &&
     meshTable[[4, 2]] < 0.15 &&
     AllTrue[{meshTable[[2]], meshTable[[4]], meshTable[[6]]}, #[[3]] < 10^-5 &],
  "D2_alphaStaircase" -> ringTable[[All, 3]] == ringTable[[All, 4]],
  "D2_alphaStarExact" -> ringTable[[All, 5]] == Table[3 n/2, {n, 3, 15}],
  "D2_classesMonotone" -> AllTrue[gapsByClass, OrderedQ[#[[All, 2]]] &],
  "D2_chainsDecay" -> OrderedQ[Reverse[chainGaps[[All, 2]]]] && Last[chainGaps][[2]] < 0.1
|>;
Column[{CaseStudiesVerification, "OK" -> And @@ Values[CaseStudiesVerification]}]
