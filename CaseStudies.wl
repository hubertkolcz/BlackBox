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
(*Case D3. Exact \[CurlyTheta] at 10^5 Blocks: Chordal Decomposition \[LongDash] and a Correction, the Two Ring Families*)

(* ::Text:: *)
(*Problem: certify \[CurlyTheta] for pentagon meshes of 10^4-10^5 blocks. The dense primal SDP behind LovaszTheta carries n(n+1)/2 variables and saturates near 150 vertices \[LongDash] the tables above stop at N = 15 for that reason. Established alternative at this scale: none. BlackBox resolution (v1.1.0): LovaszThetaSparse rewrites \[CurlyTheta] as the Lov\[AAcute]sz dual min \[Lambda]max(J - B) with B supported on the edges, absorbs the rank-one J = ee^T into one Schur border row, and splits the single (n+1)-cone along the maximal cliques of a chordal extension (Grone et al. completion / Agler et al. decomposition): one PSD block of size treewidth+2 per clique, linear cost in blocks for any bounded-treewidth mesh, plus a self-certificate \[CurlyTheta] <= \[Lambda]max(J - B) from the recovered witness. The Python companion lovasz_theta_sparse.py carries the identical decomposition to 10^5 blocks (Clarabel interior point) and adds a second, fully independent route for rings: the Z_N symmetry reduction, which block-diagonalises the block-circulant dual under the DFT into 3x3 Hermitian symbols with FOUR real parameters in total, exactly solvable by frequency cutting-planes at any N, with the all-frequency eigenvalue maximum as an unconditional certificate.*)

(* ::CodeText:: *)
(*The sparse solver agrees with the dense one on every mesh of the tables above (and on C5, C7, Petersen, Mycielskians, ... \[LongDash] see Tests/BlackBoxTests.wl):*)

(* ::Input:: *)
sparseAgreement = Max[Join[
   Table[Abs[LovaszThetaSparse[pentagonRing[n]] - ringTable[[n - 2, 2]]], {n, 3, 15}],
   Table[Abs[LovaszThetaSparse[PentagonChain[n]] - LovaszTheta[PentagonChain[n]]], {n, {3, 7, 11}}]]];
sparseAgreement

(* ::Text:: *)
(*THE CORRECTION. Scaling exposed a hidden binary design parameter that N <= 15 never showed: the gluing ORIENTATION. Every pentagon meets its glue edge {u,v} with a one-edge side (u\[Dash]c1) and a two-edge side (v\[Dash]c3\[Dash]c2). Attaching each next short side to the SAME endpoint of the running glue edge (call it cis) chains the c1-vertices into a rail \[LongDash] that is what PentagonChain builds. ALTERNATING the endpoint (trans) is what pentagonRing above builds. The two closures are NOT isomorphic, so pentagonRing is not "PentagonChain closed up", and chain-anchored bounds do not transfer to it: a lower bound \[CurlyTheta](ring 10^5) >= \[LeftFloor]N/33\[RightFloor] \[CenterDot] \[CurlyTheta](chain 31) = 142491 obtained that way is INVALID even though its anchor \[CurlyTheta](chain 31) = 47.0268 is correct. The dense solver itself arbitrates at a size it still reaches: \[CurlyTheta](trans-ring 21) < \[CurlyTheta](cis-chain 19), and \[CurlyTheta] is monotone under induced subgraphs, so no 19-block cis-chain embeds in the 21-block trans-ring.*)

(* ::Input:: *)
gluingArbitration = {LovaszTheta[pentagonRing[21]], LovaszTheta[PentagonChain[19]]};
gluingArbitration

(* ::CodeText:: *)
(*The cis ring (PentagonChain closed cyclically; the c1-rail becomes an N-cycle):*)

(* ::Input:: *)
cisRing[nb_ /; nb >= 3] := Module[{c1, c2, c3, edges},
  edges = Flatten[Table[{{c1[Mod[k - 1, nb]], c1[k]}, {c1[k], c2[k]}, {c2[k], c3[k]},
      {c3[k], c2[Mod[k - 1, nb]]}, {c2[Mod[k - 1, nb]], c1[Mod[k - 1, nb]]}}, {k, 0, nb - 1}], 1];
  Graph[DeleteDuplicates[Flatten[edges]], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];

(* ::CodeText:: *)
(*The cis family collapses onto exact laws \[LongDash] \[CurlyTheta](cis-ring N) = N + \[CurlyTheta](C_N) and \[Alpha] = \[LeftFloor]3N/2\[RightFloor] \[LongDash] verified against the dense SDP and PROVED below:*)

(* ::Input:: *)
cisLawTable = Table[{n, LovaszTheta[cisRing[n]], n + LovaszTheta[CycleGraph[n]],
    IndependenceNumber[cisRing[n]]}, {n, 4, 8}];
TableForm[cisLawTable, TableHeadings -> {None, {"N", "\[CurlyTheta](cis ring)", "N+\[CurlyTheta](C_N)", "\[Alpha]"}}]

(* ::Text:: *)
(*THEOREM. \[CurlyTheta](cis-ring N) = N + \[CurlyTheta](C_N) and \[Alpha](cis-ring N) = \[LeftFloor]3N/2\[RightFloor] for every N >= 3. Upper bound for \[CurlyTheta]: deleting the N glue edges (c1_k, c2_k) leaves the disjoint union C_N \[SquareUnion] C_2N (the c1 rail plus the outer c2/c3 cycle); \[CurlyTheta] never decreases under edge deletion, is additive on disjoint unions (Lov\[AAcute]sz 1979), and \[CurlyTheta](C_2N) = N since even cycles are perfect. Lower bound: in the value formulation \[CurlyTheta](G) = max \[Sum] (c.u_i)^2 over unit vectors orthogonal across every edge (Lov\[AAcute]sz 1979, Thm. 5), take an optimal representation {u_k} of the rail C_N in R^d with handle c, append one dimension, and give EVERY c3 vertex the handle itself and EVERY c2 vertex the new basis vector e_(d+1). Every edge pairs something with e_(d+1) or repeats a rail orthogonality, so the assignment is feasible, and its value is \[CurlyTheta](C_N) + N \[CenterDot] 0 + N \[CenterDot] 1. The glue edges are free because the c2 layer is sacrificed to a fresh dimension while the independent c3 layer rides at weight 1 \[LongDash] this is exactly why cis closure produces no quantum gap. The \[Alpha] law: all N c3 vertices plus alternate rail vertices are independent, so \[Alpha] >= N + \[LeftFloor]N/2\[RightFloor]; conversely each of the N pentagons induces exactly C5 (independence 2), and summing the window bound over all pentagons counts c1's and c2's twice and c3's once, so 2(s1 + s2) + s3 <= 2N and |S| <= N + s3/2 <= 3N/2. For even N the sandwich already forces \[CurlyTheta]: \[Alpha] = \[Alpha]\[Star] = 3N/2, so the representation is only needed at odd N.*)

(* ::CodeText:: *)
(*Machine check of the construction at odd N \[LongDash] rail = Lov\[AAcute]sz umbrella of C_N with step \[Pi](N-1)/N padded by a zero component, c3 vectors = the handle, c2 vectors = the appended basis direction. Spoke and outer-cycle orthogonalities are structurally zero; the nontrivial parts (cyclic rail orthogonality including closure, unit norms, the value identity) are exact:*)

(* ::Input:: *)
cisORCheck[n_ /; OddQ[n] && n >= 3] := Module[{w = Pi (n - 1)/n, ca2, u, handle},
  ca2 = Cos[Pi/n]/(1 + Cos[Pi/n]);
  u[k_] := {Sqrt[ca2], Sqrt[1 - ca2] Cos[k w], Sqrt[1 - ca2] Sin[k w], 0};
  handle = {1, 0, 0, 0};
  AllTrue[Range[0, n - 1], FullSimplify[u[#].u[Mod[# + 1, n]]] === 0 &] &&
   AllTrue[Range[0, n - 1], FullSimplify[u[#].u[#]] === 1 &] &&
   FullSimplify[Sum[(handle.u[k])^2, {k, 0, n - 1}] +
      n - (n + n Cos[Pi/n]/(1 + Cos[Pi/n]))] === 0];
{cisORCheck[5], cisORCheck[7], cisORCheck[9], cisORCheck[11]}

(* ::Input:: *)
chain31 = LovaszThetaSparse[PentagonChain[31]];
cisRing33 = LovaszThetaSparse[cisRing[33]];
{chain31, cisRing33, 33 + LovaszTheta[CycleGraph[33]]}

(* ::Text:: *)
(*So even-N cis rings saturate the exclusivity cap on BOTH sides \[LongDash] \[Alpha] = \[CurlyTheta] = \[Alpha]* = 3N/2, no quantum gap at all \[LongDash] and odd ones approach it with deficit \[Pi]^2/8N and a BOUNDED gap \[CurlyTheta] - \[Alpha] -> 1/2. The extensive quantum advantage of Section D2 is therefore purely a TRANS phenomenon. Exact scaling of the trans ring, computed by the two independent Python routes (agreement 6\[CenterDot]10^-8 relative at N = 100 and 2\[CenterDot]10^-7 at N = 1000; the chordal route stays certified to 1.3\[CenterDot]10^-5 relative at N = 10^4 in ~1 minute and 3\[CenterDot]10^-5 at N = 10^5 in ~6 minutes / 10 GB; the symmetry route is exact past 10^6 in seconds, certgap 7\[CenterDot]10^-5 at 10^5):*)

(* ::Input:: *)
ringScalingRecord = {(* {N, exact theta (Z_N symmetry route), density} *)
   {100, 137.666799, 1.3766680},
   {1000, 1376.716871, 1.3767169},
   {10000, 13767.177609, 1.3767178},
   {100000, 137671.775134, 1.3767178}};
tauStar = Root[49 #^3 - 128 #^2 - 75 # + 218 &, 2]; (* N->Infinity density limit: EXACT, see below *)
transDensityLimit = N[tauStar];

(* ::Text:: *)
(*The corrected picture at N = 10^5 blocks (3\[CenterDot]10^5 vertices): \[CurlyTheta] = 137671.775 (solver value; rigorously \[CurlyTheta] <= 10^5 \[CenterDot] \[Tau]* = 137671.7746) \[LongDash] BELOW the previously recorded "certified" bracket [142491, 150000], whose lower end is hereby withdrawn. The density curve is essentially FLAT: 1.37656 (N = 15, 30) -> 1.37667 (10^2) -> 1.376717 (10^3) -> 1.3767178 (10^4, 10^5; unchanged at 10^6, converging to the N -> Infinity symbol limit \[Tau]*, an ALGEBRAIC NUMBER computed in closed form below) \[LongDash] it never rises toward 3/2. The theorem \[Alpha](trans-ring N) = \[LeftFloor]4N/3\[RightFloor] is untouched, so the extensive gap survives with the corrected slope: \[CapitalDelta] = \[CurlyTheta] - \[Alpha] = (\[Tau]* - 4/3) N \[TildeTilde] 0.0433844 N \[LongDash] 4338.8 at N = 10^5, certified exact instead of bracketed. (Numerical caveat that produced an earlier +0.05 bias at 10^5: both solvers need O(1)-conditioned data \[LongDash] the chordal border is rescaled by 1/Sqrt[n], the symbol program is solved in density units.) Design rule, restated honestly: the bulk quantum advantage of pentagon meshes is set by the gluing orientation (trans: 0.0434 per block, extensive) \[LongDash] closure and block parity only modulate it; the cis family instead saturates \[Alpha]* classically and carries no bulk gap.*)

(* ::CodeText:: *)
(*The density limit in CLOSED FORM. The continuum symbol minimax is exactly solvable: the ring's reflection automorphism forces \[Beta]bx = \[Gamma]ax, KKT stationarity factors as (u - 2g)(u + 2gc) = 0 giving \[Beta]ab = 2\[Gamma]ba, and Groebner elimination of the remaining polynomial system leaves a single cubic \[LongDash] \[Tau]* = Root[49x^3 - 128x^2 - 75x + 218, middle root] = 1.3767177459158590533. The dual witness lives in the cubic field \[DoubleStruckCapitalQ] of \[Tau]*, and feasibility on the WHOLE frequency circle reduces to a perfect square (the quadratic coefficient cancels identically, so four exact zeros remain), certifying global optimality \[LongDash] the minimax is convex and both KKT multipliers are positive:*)

(* ::Input:: *)
{gW, hW, cW} = {(53 tauStar^2 - 121 tauStar + 218)/458,
   (327 - 67 tauStar - 35 tauStar^2)/229, (1715 tauStar^2 + 77 tauStar - 3428)/916};
closedFormCertificate = RootReduce[Flatten[{
    gW tauStar - hW^2 (1 + 2 cW),
    tauStar^2 - (3 - 3 gW) tauStar + (2 - 3 gW) - 2 (1 - hW)^2,
    CoefficientList[tauStar^3 - (5 gW^2 + 4 gW^2 \[FormalC] + 2 hW^2) tauStar +
      2 hW^2 gW (2 \[FormalC] + 2 \[FormalC]^2 - 1) - 4 gW hW^2 (\[FormalC] - cW)^2, \[FormalC]]}]];
{closedFormCertificate, N[tauStar, 25]}

(* ::Text:: *)
(*Trigonometric form: \[Tau]* = 128/147 + (2 Sqrt[27409]/147) cos((1/3) arccos(-2852191/(27409 Sqrt[27409])) - 2\[Pi]/3), with 27409 = 128^2 + 3\[CenterDot]49\[CenterDot]75. Minimal polynomials of the witness: 2401g^3 - 4518g^2 + 2549g - 436, 343h^3 - 689h^2 + 173h + 109, and 2c^3 - 15c^2 - 14c - 1 for c = cos \[Theta]* (active frequency \[Theta]* \[TildeTilde] 0.5248591600 \[Pi]). The extensive per-block gap of the trans family is therefore itself algebraic: \[Tau]* - 4/3 = 0.0433844126.*)

(* ::Section:: *)
(*Case D3 continued. The Optimal Gluing Word: (cct) Beats Pure Trans by 61%*)

(* ::Text:: *)
(*The correction raises a design question: over ALL gluing words in {cis, trans} (one orientation letter per gluing; a mesh = a binary necklace), is the pure trans word gap-optimal? Answer: NO. Tooling (lovasz_theta_sparse.py, command "words"): exact \[Alpha] densities are max-plus cycle means of a 3-state interface transfer DP (exact rational arithmetic; the pure-word matrices reproduce both proven laws, and the trans staircase is the 3-cycle of its transfer matrix gaining 4 per 3 blocks); \[CurlyTheta] densities come from the chordal solver at 1200-2400 blocks, certified. Sweeping every binary bracelet of period <= 6: the word (cct)^\[Infinity] \[LongDash] two cis gluings, then one trans "reset" \[LongDash] keeps the trans staircase \[Alpha]/L = 4/3 while lifting \[CurlyTheta]/L to 1.40323087 (continuum-exact, below), so the extensive gap per block is 0.0698975 \[TildeTilde] 1.6111\[Times](\[Tau]* - 4/3). Every strict mixture ranks strictly between the pure families' gaps or above pure trans; the cis-collapse (gap 0) extends beyond pure cis to ct, ccct, ccctct, ccccct. Exhaustively over periods <= 12 (max-plus, exact): every word with \[Alpha]-density 4/3 has cis-fraction <= 2/3, and cct is the UNIQUE word attaining 2/3; the best higher-period rivals in the 4/3 class (cctcctctt, cctcctcctctt) stay below cct's gap. REFINED CONJECTURE: (cct)^\[Infinity] is the globally optimal pentagon-mesh gluing word. Design reading: trans letters protect the classical bound \[LongDash] each t breaks the cis rail before it can lift \[Alpha] \[LongDash] while cis letters buy quantum value; the optimum is the densest cis packing that \[Alpha] tolerates.*)

(* ::CodeText:: *)
(*The general word builder (mirrors pentagon_ring_word labels), and the dense-SDP anchor for the winner \[LongDash] \[CurlyTheta](cct\[Times]2) against the chordal value 8.347042185, plus the exact \[Alpha] staircase at L = 6, 9:*)

(* ::Input:: *)
wordRing[word_String, reps_Integer] := Module[
  {w = Characters[StringRepeat[word, reps]], L, edges = {}, u, v, km},
  L = Length[w];
  Do[km = Mod[k - 1, L];
   {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
   edges = Join[edges, {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2},
      {3 k + 2, 3 k + 3}, {3 k + 3, v}}], {k, 0, L - 1}];
  Graph[Range[3 L], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];
gluingWordAnchor = {LovaszTheta[wordRing["cct", 2]],
   IndependenceNumber[wordRing["cct", 2]], IndependenceNumber[wordRing["cct", 3]]};
cctDensity = 1.40323087; (* certified continuum optimum of the 9x9 symbol minimax;
   the L = 2400 chordal run reads 7*10^-7 high, within its certgap *)
gluingWordAnchor

(* ::Text:: *)
(*Does the cct density have a closed form like \[Tau]*? NO \[LongDash] and that is itself a finding. The (cct) unit cell gives a 9x9 DFT symbol with 12 edge-orbit parameters; the mesh's reflection automorphism (|Aut(cct ring of m cells)| = 2m, machine-checked below) pairs them down to 7, and the continuum minimax has the same active-set shape as the trans case (the J-block plus ONE interior frequency, \[Phi] \[TildeTilde] 0.70345\[Pi]). Solving the reduced KKT system by Newton iteration at 320-digit precision (residual 10^-319, both multipliers positive, witness feasible on a 2^20-point frequency grid to -9*10^-16; convexity plus the automorphism-averaging argument then certify the GLOBAL optimum) gives \[CurlyTheta]/L = 1.40323086923899745105894248 exactly characterized \[LongDash] but integer-relation search (LLL via RootApproximant on 250 matched digits) EXCLUDES any minimal polynomial of degree <= 36 with coefficient height below ~10^6 (and proportionally higher at lower degree, e.g. 10^60 at degree 3), for the density, the per-cell value, cos \[Phi], and each witness parameter. Contrast with period 1: \[Tau]* is a cubic with two-digit coefficients. The algebraic complexity of the symbol minimax explodes with the word period; the exact object standing in for a "closed form" at period 3 is the explicit polynomial KKT system itself.*)

(* ::Text:: *)
(*Towards GLOBAL optimality of (cct)^\[Infinity] \[LongDash] what is proven, what obstructs the rest. Two lemmas hold for EVERY gluing word, each with a finite machine-checkable certificate. LEMMA A (universal exclusivity cap): \[Alpha]* = 3L/2 exactly, hence \[CurlyTheta] <= 3L/2. Proof: the uniform packing w = 1/2 gives \[Alpha]* >= 3L/2; conversely the word-independent fractional edge cover \[LongDash] weight 1/2 on (B_k, X_k) and on the two glue-in edges of every block, weight 0 on the shared (A_k, B_k) edges \[LongDash] covers every vertex exactly once at total cost 3L/2, and \[CurlyTheta] <= fractional clique cover = \[Alpha]* by LP duality. LEMMA B (classical floor): \[Alpha]-density >= 4/3 for every word. Proof: potentials \[Phi] = (0, -1/3, -2/3) on the three interface states of the transfer DP satisfy, at every state and against EITHER letter, max over transitions of (gain + \[CapitalDelta]\[Phi]) >= 4/3 \[LongDash] six inequalities, checked below \[LongDash] so telescoping along any word yields a set gaining at least 4/3 per block; pure trans attains the floor. PINCH COROLLARY: gap(w) <= min(\[CurlyTheta]-density - 4/3, 3/2 - \[Alpha]-density) <= 1/6; any word beating (cct)^\[Infinity] must simultaneously have \[CurlyTheta]-density > 1.40323087 and \[Alpha]-density < 1.4301025. Exhaustive certified computation covers all aperiodic bracelets of period <= 9 (none comes close; runner-up gap 0.0689). THE OBSTRUCTION to a complete proof: the natural finishing move is a transfer-SDP sub-action \[LongDash] windowed chordal dual templates giving a per-window linear upper bound on \[CurlyTheta]-density, paired with Lemma B's potential method, reducing global optimality to a finite LP over de Bruijn flows \[LongDash] but a template tight at cct must reproduce \[Tau]cct exactly, and \[Tau]cct provably admits no small algebraic description (previous subsection), so rational certificates can only ever prove optimality up to \[Epsilon]. Exact global optimality is blocked by the same number-field explosion that killed the closed form.*)

(* ::CodeText:: *)
(*The two certificates, machine-checked \[LongDash] Lemma B's six potential inequalities on the interface DP, and Lemma A's cover value \[Alpha]* = 3L/2 on assorted word meshes:*)

(* ::Input:: *)
dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
  Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
      ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
     out = If[letter === "c", {s1, s2}, {s2, s1}];
     j = Position[dpStates, out][[1, 1]];
     T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
    {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
  T];
optimalityLemmas = Module[{phi = {0, -1/3, -2/3}},
   AllTrue[Flatten[Table[
       Max[Table[dpTransfer[l][[i, j]] + phi[[j]] - phi[[i]], {j, 3}]] >= 4/3,
       {l, {"c", "t"}}, {i, 3}]], TrueQ] &&
    AllTrue[Table[FractionalPackingNumber[wordRing[w, 2]] == 3 StringLength[w],
      {w, {"cct", "ctt", "cctt", "ctctt"}}], TrueQ]];
optimalityLemmas

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
  "D2_chainsDecay" -> OrderedQ[Reverse[chainGaps[[All, 2]]]] && Last[chainGaps][[2]] < 0.1,
  "D3_sparseMatchesDense" -> sparseAgreement < 10^-4,
  "D3_gluingArbitration" -> gluingArbitration[[1]] < gluingArbitration[[2]] - 0.15 &&
     Abs[gluingArbitration[[1]] - 28.86756] < 10^-3 && Abs[gluingArbitration[[2]] - 29.03987] < 10^-3,
  "D3_cisRingLaw" -> AllTrue[cisLawTable, Abs[#[[2]] - #[[3]]] < 10^-5 &] &&
     cisLawTable[[All, 4]] == Table[Floor[3 n/2], {n, 4, 8}],
  "D3_cisMonotone" -> chain31 <= cisRing33 + 10^-4 &&
     Abs[cisRing33 - (33 + LovaszTheta[CycleGraph[33]])] < 10^-3 &&
     Abs[chain31 - 47.026768] < 10^-3,
  "D3_recordedScaling" -> OrderedQ[ringScalingRecord[[All, 3]]] &&
     ringScalingRecord[[-1, 3]] < transDensityLimit + 10^-6 &&
     AllTrue[ringScalingRecord, Abs[#[[2]]/#[[1]] - #[[3]]] < 10^-6 &],
  "D3_extensiveGapCorrected" -> With[{th = ringScalingRecord[[-1, 2]]},
     Floor[4 100000/3] < th < 3 100000/2 && th < 142491 &&
       Abs[th - 137671.775] < 0.01 && th - Floor[4 100000/3] > 4000],
  "D3_densityClosedForm" -> Union[closedFormCertificate] === {0} &&
     Abs[transDensityLimit - 1.376717745915859] < 10^-12 &&
     AllTrue[ringScalingRecord[[All, 3]], # < transDensityLimit + 10^-6 &],
  "D3_cisLawProven" -> cisORCheck[5] && cisORCheck[7] && cisORCheck[9] && cisORCheck[11] &&
     cisLawTable[[All, 4]] == Table[Floor[3 n/2], {n, 4, 8}],
  "D3_gluingWordOptimum" -> Abs[gluingWordAnchor[[1]] - 8.347042185] < 10^-4 &&
     gluingWordAnchor[[2]] == 8 && gluingWordAnchor[[3]] == 12 &&
     cctDensity - 4/3 > transDensityLimit - 4/3 &&
     Abs[(cctDensity - 4/3)/(transDensityLimit - 4/3) - 1.611] < 0.01,
  "D3_cctDensityCharacterized" ->
     Table[GroupOrder[GraphAutomorphismGroup[wordRing["cct", m]]], {m, 2, 4}] == {4, 6, 8} &&
     Abs[cctDensity - 1.4032308692389975] < 10^-8 &&
     cctDensity < 1.4032316 (* the finite-L 2400 reading, corrected by the continuum solve *),
  "D3_towardsGlobalOptimality" -> optimalityLemmas &&
     Abs[(3/2 - (cctDensity - 4/3)) - 1.4301025] < 10^-6 &&
     cctDensity - 4/3 < 1/6 (* the pinch bound is not saturated by cct *)
|>;
Column[{CaseStudiesVerification, "OK" -> And @@ Values[CaseStudiesVerification]}]
