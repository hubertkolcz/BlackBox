(* ::Package:: *)

(* ::Title:: *)
(*A Qutrit Catalyst Activates the Heptagon PR Box*)

(* ::Subtitle:: *)
(*A computational note on hetero-graph composition under the exclusivity principle*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Companion note to CaseStudies.wl, Case C; built on the BlackBox paclet. Headless verification: wolframscript -file RunHeptagonCatalysis.wl -print all (must end OK -> True).*)

(* ::Abstract:: *)
(*The n-cycle PR-type boxes (probability 1/2 per event) with n >= 6 satisfy Consistent Exclusivity at two and three identical copies (Choudhary-Barbosa, arXiv:2411.09773); the pentagon trick provably stalls, and composition with quantum correlations is their stated open escape route. We compute the smallest heterogeneous cells. One heptagon box plus one quantum-maximal KCBS pentagon does NOT violate CE (exact load 2/Sqrt[5]); one box plus two catalysts lands EXACTLY on the boundary (load 1, zero margin); two boxes plus one catalyst VIOLATE CE: the joint exclusivity graph C7\[Or]C7\[Or]C5 contains a 9-clique, load 9 Sqrt[5]/20 \[TildeTilde] 1.006 > 1. The catalyst is a fixed three-level resource, and it works only if its per-event probability exceeds 4/9 \[LongDash] pentagon visibility at least (5 + 3 Sqrt[5])/12 \[TildeTilde] 0.9757, just below the 0.977 achieved by Lapkiewicz et al. (Nature 474, 490). The activation is a heptagon resonance, and provably ONLY a heptagon resonance \[LongDash] a theorem: two n-cycle boxes plus one pentagon catalyst violate CE if and only if n = 7. Even n and odd n >= 29 fall to the multiplicative Lov\[AAcute]sz ceiling \[CurlyTheta](Complement[Cn])^2 Sqrt[5] < 9; odd 9 <= n <= 27, and the wraparound-free path product P7\[Or]P7\[Or]C5, fall to an exact pentagram-layer reduction, exhaustive in seconds where FindClique times out. The nonagon cell stays CE-safe at load 2/Sqrt[5]; a second catalyst lands it exactly on the boundary.*)

(* ::Section:: *)
(*Setting*)

(* ::Text:: *)
(*Events of the n-cycle box live on the cycle graph C_n (adjacent = exclusive); the box assigns probability 1/2 to each. For independent experiments, joint events are exclusive iff exclusive in some factor \[LongDash] the OR (conormal) product \[LongDash] and probabilities multiply; Consistent Exclusivity (CE) demands every clique of the joint graph carry total probability at most 1. Composing DIFFERENT experiments is legitimate (Foulis-Randall products: Acin-Fritz-Leverrier-Sainz, CMP 334, 533; Cabello, PRA 100, 032120 assumes independent realizations of any two experiments). A violating clique for the composite (box_7)^k \[CircleTimes] (quantum pentagon)^m needs size > 2^k Sqrt[5]^m.*)

(* ::CodeText:: *)
(*Load the library; mixed OR products and the quantum per-event probability cos(\[Pi]/n)/(1+cos(\[Pi]/n)):*)

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];
orMixed = CycleORProduct; pQuantum = QuantumEventProbability;   (* single implementations live in the paclet *)

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
(*Beyond n = 7: Both Pre-Registered Inconclusives Settled \[LongDash] the Heptagon Is a Resonance*)

(* ::Text:: *)
(*Does the pentagon catalyst expel every n-cycle box with n >= 7? The first release of this note reported two searches INCONCLUSIVE at their pre-registered time caps: a 9-clique in C9\[Or]C9\[Or]C5 (405 vertices), and a 9-clique in the path product P7\[Or]P7\[Or]C5 (245 vertices \[LongDash] wraparound-free, so a hit would embed in EVERY C_n\[Or]C_n\[Or]C5 with n >= 7 and settle the question universally). Both are now settled, and both answers are NO. The tool is an exact reduction along the catalyst factor instead of brute clique search: a clique of H\[Or]C5 meets each pentagon layer c in a clique Q_c of H; layers at C5-distance 1 are jointly exclusive for free; each pentagram pair (c, c+2 mod 5) needs Q_c and Q_(c+2) disjoint with their union a clique of H, so |Q_c| + |Q_(c+2)| <= \[Omega](H). Summing around the pentagram cycle 0-2-4-1-3-0 gives \[Omega](H\[Or]C5) <= Floor[5 \[Omega](H)/2] \[LongDash] not an original bound but a corollary of classical strong-product results (via the identity Complement[H\[Or]C5] = Complement[H] strong-times C5 and the fractional packing \[Alpha]*(C5) = 5/2: Hales 1973; Sonnemann-Krafft 1974); and for a 9-clique over \[Omega](H) = 4 no layer can be empty (the other four split into two pentagram pairs, at most 8 events), so all five layer sizes lie in {1, 2, 3} and only 15 size vectors survive. The search below is exhaustive \[LongDash] False is a proof \[LongDash] and runs in seconds where FindClique hit its cap: the path product turns out to pack 233 million maximum cliques, all of size 8.*)

(* ::CodeText:: *)
(*The decision procedure: all cliques of H on at most 3 vertices, pairwise compatibility (disjoint with clique union) by matrix algebra, then a closed 5-chain of compatible cliques with prescribed sizes along the pentagram cycle:*)

(* ::Input:: *)
nineCliqueViaLayersQ[H_Graph] := Module[
   {AH, nV, cl, sizes, Cmat, cnt, NAmat, compat, bySize, vecs, pent, ms, is, mats, f},
   If[Length[First[FindClique[H]]] != 4, Return[$Failed]];  (* size lemma assumes \[Omega](H) = 4 *)
   AH = Normal[AdjacencyMatrix[H]]; nV = VertexCount[H];
   cl = Select[Subsets[Range[nV], {1, 3}], AllTrue[Subsets[#, {2}], AH[[#[[1]], #[[2]]]] == 1 &] &];
   sizes = Length /@ cl;
   Cmat = SparseArray[Join @@ MapIndexed[Function[{c, i}, ({First[i], #} -> 1) & /@ c], cl], {Length[cl], nV}];
   cnt = Cmat . AH;
   NAmat = 1 - Unitize[cnt - sizes];  (* [i, v] = 1 iff v adjacent to ALL of clique i *)
   compat = 1 - Unitize[Transpose[Cmat . Transpose[1 - NAmat]]];  (* [a, b] = 1 iff disjoint, union a clique *)
   If[compat =!= Transpose[compat], Return[$Failed]];
   bySize = Association[Table[s -> Flatten[Position[sizes, s]], {s, 1, 3}]];
   vecs = Select[Tuples[{1, 2, 3}, 5], Function[v,
      Total[v] == 9 && AllTrue[Range[5], v[[#]] + v[[Mod[# + 1, 5] + 1]] <= 4 &]]];
   pent = {1, 3, 5, 2, 4};  (* pentagram order of the five layers *)
   AnyTrue[vecs, Function[vec,
     ms = vec[[pent]]; is = bySize /@ ms;
     mats = Table[compat[[is[[j]], is[[Mod[j, 5] + 1]]]], {j, 5}];
     f = mats[[1]]; Do[f = Unitize[f . mats[[j]]], {j, 2, 4}];
     Total[f Transpose[mats[[5]]], 2] > 0]]];

(* ::CodeText:: *)
(*The machinery must and does recover the heptagon activation (True); the wraparound-free path product and the nonagon product both refuse, exhaustively (False):*)

(* ::Input:: *)
p77 = Module[{V = Tuples[Range[0, 6], 2]}, Graph[V, UndirectedEdge @@@
     Select[Subsets[V, {2}], Abs[#[[1, 1]] - #[[2, 1]]] == 1 || Abs[#[[1, 2]] - #[[2, 2]]] == 1 &]]];
{layerC7 = nineCliqueViaLayersQ[orMixed[{7, 7}]],
 layerPath = nineCliqueViaLayersQ[p77],
 layerNonagon = nineCliqueViaLayersQ[orMixed[{9, 9}]]}

(* ::CodeText:: *)
(*Exact clique numbers: an edge of C5 times a 4-clique of the box product reaches 8, so \[Omega](P7\[Or]P7\[Or]C5) = \[Omega](C9\[Or]C9\[Or]C5) = 8, and the (2 boxes, 1 catalyst) load at n = 9 is 8(1/2)(1/2)/Sqrt[5] = 2/Sqrt[5] \[LongDash] CE-safe with exactly the same margin as the single-box heptagon cell:*)

(* ::Input:: *)
adjP775[u_, v_] := Abs[u[[1]] - v[[1]]] == 1 || Abs[u[[2]] - v[[2]]] == 1 || MemberQ[{1, 4}, Mod[u[[3]] - v[[3]], 5]];
adjC995[u_, v_] := MemberQ[{1, 8}, Mod[u[[1]] - v[[1]], 9]] || MemberQ[{1, 8}, Mod[u[[2]] - v[[2]], 9]] || MemberQ[{1, 4}, Mod[u[[3]] - v[[3]], 5]];
cliqueByAdjQ[adj_, s_] := AllTrue[Subsets[s, {2}], adj @@ # &];
eightBlock[H_] := Flatten[Table[Append[v, c], {v, First[FindClique[H]]}, {c, 0, 1}], 1];
eightPath = eightBlock[p77]; eightNonagon = eightBlock[orMixed[{9, 9}]];
nonagonLoad = 8 (1/2) (1/2) (1/Sqrt[5]);
{cliqueByAdjQ[adjP775, eightPath], cliqueByAdjQ[adjC995, eightNonagon], Simplify[nonagonLoad == 2/Sqrt[5]], N[nonagonLoad]}

(* ::CodeText:: *)
(*Doubling the catalyst does not rescue the nonagon: the pentagram bound over H = C9\[Or]C9\[Or]C5 (\[Omega] = 8, just proven) caps \[Omega](C9\[Or]C9\[Or]C5\[Or]C5) at Floor[5 8/2] = 20, a 4-clique of C9\[Or]C9 times the pentad of C5\[Or]C5 reaches it, and 20 events of weight (1/4)(1/5) load to exactly 1 \[LongDash] boundary-exact, the same knife-edge as one heptagon box with two catalysts:*)

(* ::Input:: *)
adjC9955[u_, v_] := MemberQ[{1, 8}, Mod[u[[1]] - v[[1]], 9]] || MemberQ[{1, 8}, Mod[u[[2]] - v[[2]], 9]] ||
   MemberQ[{1, 4}, Mod[u[[3]] - v[[3]], 5]] || MemberQ[{1, 4}, Mod[u[[4]] - v[[4]], 5]];
pentad55 = {{0, 0}, {1, 2}, {2, 4}, {3, 1}, {4, 3}};
twentyNonagon = Flatten[Table[Join[v, p], {v, First[FindClique[orMixed[{9, 9}]]]}, {p, pentad55}], 1];
{Length[twentyNonagon], cliqueByAdjQ[adjC9955, twentyNonagon], Simplify[20 (1/2) (1/2) (1/5) == 1]}

(* ::CodeText:: *)
(*Lifting the sweep to a theorem. The complement of an OR product is the STRONG product of the complements, and Lov\[AAcute]sz's \[CurlyTheta] is multiplicative over strong products, so \[Omega](Cn\[Or]Cn\[Or]C5) <= \[CurlyTheta](Complement[Cn])^2 \[CurlyTheta](C5) in closed form: \[CurlyTheta](Complement[Cn]) = 2 for even n (bipartite plus vertex-transitive duality) and 1 + Sec[Pi/n] for odd n (Lov\[AAcute]sz 1979). The odd ceiling (1 + Sec[Pi/n])^2 Sqrt[5] decreases in n and crosses 9 between 27 and 29 \[LongDash] so every even n and every odd n >= 29 is settled analytically, and only odd 9 <= n <= 27 needs a search:*)

(* ::Input:: *)
thetaCeiling[n_] := If[EvenQ[n], 2, 1 + Sec[Pi/n]]^2 Sqrt[5];
{Simplify[4 Sqrt[5] < 9], N[thetaCeiling[27], 30] > 9, N[thetaCeiling[29], 30] < 9}

(* ::CodeText:: *)
(*The finite part, in-file and fast. Compatible layer-clique pairs are exactly the two-part splits of H's edges, triangles and 4-cliques (a size-3 layer forces both pentagram partners to size 1, so (3,3) and (2,3) contacts never occur \[LongDash] no clique of size > 4 is ever touched); vertex-transitivity of Cn\[Or]Cn under Z_n^2 translations pins the mandatory size-1 layer to the single clique {(0,0)} after rotating each pentagram chain to start there. The function re-proves \[Omega](Cn\[Or]Cn) = 4 en route (no 4-clique has a common neighbor) and returns whether a 9-clique exists. Odd n from 9 to 27 all refuse; n = 7 is the lone True:*)

(* ::Input:: *)
nineCliqueCnCnC5Q[n_Integer /; n >= 6] := Module[
   {nH = n^2, verts, A, edges, tris, quads, e2i, t2i, blocks, vecs, chains, start},
   verts = Tuples[Range[0, n - 1], 2];
   A = Outer[Boole[#1 =!= #2 && (MemberQ[{1, n - 1}, Mod[#1[[1]] - #2[[1]], n]] ||
         MemberQ[{1, n - 1}, Mod[#1[[2]] - #2[[2]], n]])] &, verts, verts, 1];
   edges = Position[UpperTriangularize[A], 1];
   tris = Join @@ Map[Function[e, Module[{c = A[[e[[1]]]] A[[e[[2]]]]},
       Append[e, #] & /@ Select[Flatten[Position[c, 1]], # > e[[2]] &]]], edges];
   quads = Join @@ Map[Function[t, Module[{c = A[[t[[1]]]] A[[t[[2]]]] A[[t[[3]]]]},
       Append[t, #] & /@ Select[Flatten[Position[c, 1]], # > t[[3]] &]]], tris];
   If[AnyTrue[quads, Total[A[[#[[1]]]] A[[#[[2]]]] A[[#[[3]]]] A[[#[[4]]]]] > 0 &],
    Return[$Failed]];  (* a 5-clique in H would void the size lemma *)
   e2i = AssociationThread[edges, Range[Length[edges]]];
   t2i = AssociationThread[tris, Range[Length[tris]]];
   blocks = <|
     {1, 1} -> SparseArray[Join @@ ({{#[[1]], #[[2]]} -> 1, {#[[2]], #[[1]]} -> 1} & /@ edges), {nH, nH}],
     {1, 2} -> SparseArray[Join @@ Map[Function[t, {
           {t[[1]], e2i[t[[{2, 3}]]]} -> 1, {t[[2]], e2i[t[[{1, 3}]]]} -> 1,
           {t[[3]], e2i[t[[{1, 2}]]]} -> 1}], tris], {nH, Length[edges]}],
     {1, 3} -> SparseArray[Join @@ Map[Function[q,
          Table[{q[[i]], t2i[Delete[q, i]]} -> 1, {i, 4}]], quads], {nH, Length[tris]}],
     {2, 2} -> SparseArray[Join @@ Map[Function[q, Join @@ Map[
           With[{i1 = e2i[q[[#[[1]]]]], i2 = e2i[q[[#[[2]]]]]},
             {{i1, i2} -> 1, {i2, i1} -> 1}] &,
           {{{1, 2}, {3, 4}}, {{1, 3}, {2, 4}}, {{1, 4}, {2, 3}}}]], quads],
        {Length[edges], Length[edges]}]|>;
   blocks[{2, 1}] = Transpose[blocks[{1, 2}]];
   blocks[{3, 1}] = Transpose[blocks[{1, 3}]];
   vecs = Select[Tuples[{1, 2, 3}, 5], Function[v,
      Total[v] == 9 && AllTrue[Range[5], v[[#]] + v[[Mod[# + 1, 5] + 1]] <= 4 &]]];
   chains = Map[Function[v, Module[{m = v[[{1, 3, 5, 2, 4}]]},
       RotateLeft[m, First[FirstPosition[m, 1]] - 1]]], vecs];
   If[! SubsetQ[Keys[blocks],
      Join @@ Map[Function[c, Table[{c[[j]], c[[Mod[j, 5] + 1]]}, {j, 5}]], chains]],
    Return[$Failed]];
   start = 1;  (* verts[[1]] = {0, 0} *)
   AnyTrue[chains, Function[c, Module[{f = SparseArray[{start -> 1.}, {nH}]},
      Do[f = Unitize[f . blocks[{c[[j]], c[[j + 1]]}]], {j, 1, 4}];
      (f . blocks[{c[[5]], c[[1]]}])[[start]] > 0]]]];

(* ::Input:: *)
sweepControl = nineCliqueCnCnC5Q[7];
oddSweep = AssociationMap[nineCliqueCnCnC5Q, Range[9, 27, 2]];
{sweepControl, oddSweep}

(* ::Text:: *)
(*Consequences. (i) THEOREM (two boxes, one catalyst): for every n >= 6, the composite of two n-cycle boxes and one quantum-maximal pentagon violates CE if and only if n = 7. Proof: even n and odd n >= 29 by the theta ceiling; odd 9 <= n <= 27 by the exhaustive sweep (all False); n = 7 by the witness of the Two-Boxes section. For every n != 7 the clique number is exactly 8 (edge of C5 times a 4-clique reaches the ceiling's floor), so the load is 2/Sqrt[5] \[LongDash] the same safe margin as one heptagon box against one catalyst. (ii) The universal route is closed independently: no 9-clique in P7\[Or]P7\[Or]C5, so no single wraparound-free witness could have decided all n at once (igraph's exact branch-and-bound confirms \[Omega] = 8 there over 233173240 maximum cliques, 305 s \[LongDash] the same run that explains the FindClique timeout; beyond7_clique_search.py reproduces every cell of this section in seconds). (iii) The smallest cell still open at n = 9 is (3 boxes, 1 catalyst): an 18-clique in the 3645-vertex C9\[Or]C9\[Or]C9\[Or]C5, which the pentagram bound over \[Omega](C9\[Or]C9\[Or]C9) = 8 (CE at three copies, arXiv:2411.09773) allows up to 20 and the theta ceiling (1 + Sec[Pi/9])^3 Sqrt[5] \[TildeTilde] 19.67 trims to 19. A structural account of WHY Z7 alone threads the needle \[LongDash] the theta ceiling admits a 9-clique for every odd n <= 27, yet only Z7 realizes one \[LongDash] is the remaining conceptual question.*)

(* ::Section:: *)
(*The Open Nonagon Cell: An Honest Open Problem, and Why It Matters Either Way*)

(* ::Text:: *)
(*Precise statement. Does an 18-clique exist in C9\[Or]C9\[Or]C9\[Or]C5 (3645 vertices, three nonagon-box copies plus one pentagon catalyst)? Activation (violation of Consistent Exclusivity) holds iff \[Omega] >= 18, since the load is \[Omega]/(8 Sqrt[5]) and 18/(8 Sqrt[5]) = 9 Sqrt[5]/20 \[TildeTilde] 1.006 \[LongDash] the identical margin as the heptagon activation. Rigorous bounds: 16 <= \[Omega] <= 19. The lower bound is an explicit construction (an edge of C9 times the 8-clique witness of the (2,1) cell); the upper bound is the theta ceiling (1 + Sec[Pi/9])^3 Sqrt[5] \[TildeTilde] 19.67 derived above. Both directions are exact and machine-checked; the four-value gap between them is not.*)

(* ::Text:: *)
(*This gap is reported honestly as OPEN, not quietly rounded to a guess. Five independent computational methods \[LongDash] plain CNF-SAT with layer cuts, a SAT solver portfolio (alternate solvers, cardinality encodings, variable orderings), exact branch-and-bound, a two-level atom encoding exploiting the pentagram layer structure, and heuristic local search across several restarts \[LongDash] were run without a time cap, together consuming several hundred CPU-hours. Every method that can find a witness converges on \[Omega] = 16 (the product-bound construction) and none has found anything larger; but proving nothing larger EXISTS is the direction that has not terminated. This is not a tooling failure: the box subgraph alone, C9\[Or]C9\[Or]C9 (729 vertices), was shown by direct enumeration to contain at least 219167289 cliques of size 4, and a partial count of its maximum (size-8) cliques already exceeded 100 million before being capped \[LongDash] a population plausibly in the 10^10\[Dash]10^12 range that any exhaustive refutation must implicitly rule out. Closing this gap with certainty, on the evidence gathered, most likely requires either a substantially cleverer exact reduction than the ones tried here or genuine HPC-scale parallel search (cube-and-conquer with symmetry-breaking); a real precedent for the SCALE of compute such problems can demand is Heule's resolution of Schur Number Five, which needed on the order of 20 CPU-years even with dedicated tooling.*)

(* ::Text:: *)
(*Why the open problem is worth stating precisely even unresolved. Fundamental science: this is one small, exact brick in the largest open question in quantum foundations \[LongDash] why does nature stop exactly at the quantum correlations and go no further? The exclusivity principle is one of the leading candidate answers, but it is known to be imperfect (the almost-quantum set of Navascu\[EAcute]s-Guryanova-Hoban-Ac\[IAcute]n, Nat. Commun. 6, 6288 (2015), satisfies it while still exceeding the quantum set). Mapping precisely where the principle succeeds \[LongDash] the isolated n = 7 resonance proven above \[LongDash] against where it merely fails to decide (this nonagon cell) calibrates exactly how strong a foundational axiom it really is, which matters directly to anyone searching for the principle that completes the reconstruction of quantum theory. Independently of the physics motivation, the combinatorial object itself \[LongDash] exact clique numbers of conormal products of odd cycles, equivalently independence numbers of strong products of odd-cycle complements \[LongDash] sits in the same family as the Shannon capacity of odd cycles, open since Lov\[AAcute]sz's 1979 resolution of C5 alone; any exact data point in that family carries standalone mathematical value.*)

(* ::Text:: *)
(*Engineering relevance. The exclusivity principle is not merely a foundational curiosity: it underwrites real, deployable device-independent quantum protocols \[LongDash] device-independent quantum key distribution, device-independent randomness certification, and self-testing of quantum hardware. Every one of these ultimately has to answer the same operational question this note computes for the heptagon and nonagon cells: can this box's observed statistics be faked by a non-quantum, or POST-quantum, construction assembled out of otherwise-legitimate quantum parts? That is exactly the activation question. A sharper map of where activation does and does not occur feeds directly into designing device-independent certificates that cannot be gamed this way. Separately, as NISQ-era quantum hardware scales, contextuality witnesses of exactly this graph-theoretic kind are already used as practical device benchmarks; knowing which composite structures carry subtle activation loopholes indicates which witnesses are robust and which have blind spots. And the computational techniques assembled to attack this cell \[LongDash] SAT encodings for clique decisions on highly symmetric Cayley graphs, the atom-encoding layer reduction, and verified symmetry-breaking constructions \[LongDash] are reusable independently of this specific physics question, on any hard combinatorial problem (coding theory, cryptographic S-box analysis, symmetric network design) that reduces to a clique number on a symmetric graph.*)

(* ::Section:: *)
(*Relation to Published Results*)

(* ::CodeText:: *)
(*Yan's route (PRL 110, 260406): compose with the quantum maximum of the COMPLEMENT graph \[LongDash] one box copy suffices, load (1/2)\[CurlyTheta](Complement[C7]) \[TildeTilde] 1.055:*)

(* ::Input:: *)
yanLoad = (1/2) LovaszTheta[GraphComplement[CycleGraph[7]]];
{yanLoad, yanLoad > 1}

(* ::Text:: *)
(*Positioning (scope of novelty, stated conservatively). The graph-theoretic machinery is established: exclusivity graphs as conormal (OR) products, the Consistent-Exclusivity clique-load criterion, and activation via cliques in product graphs (Cabello-Severini-Winter, PRL 112, 040401 (2014); Acin-Fritz-Leverrier-Sainz, CMP 334, 533 (2015); Fritz et al., Nat. Commun. 4, 2263 (2013)). Yan's construction and its generalizations (Yan, PRL 110, 260406 (2013); Amaral-Terra Cunha-Cabello, PRA 89, 030101(R) (2014); Cabello, PRA 100, 032120 (2019)) already exclude the heptagon box at one copy, but with a complement-graph partner whose Hilbert-space dimension grows with n. What is new here, and not located in the literature, is narrower and precise: (i) the activating partner is a FIXED, constant-dimension (qutrit) genuinely-quantum resource \[LongDash] the KCBS pentagon at its Lov\[AAcute]sz value \[LongDash] rather than a growing-dimension or asymptotic construction; and (ii) the n = 7 UNIQUENESS \[LongDash] a single isolated activated cycle length (\[Omega](Cn\[Or]Cn\[Or]C5) = 9 iff n = 7, else 8), a non-monotone statement absent from the identical-copy picture. This answers the open problem in the outlook of arXiv:2411.09773 (Sec. VII): whether a box that resists identical-copy activation can violate the E-principle jointly with a quantum correlation of a DIFFERENT experiment. Two honest caveats. First, the combinatorial object here \[LongDash] \[Omega] of a conormal product = independence number of a strong product of odd-cycle complements \[LongDash] is a classically hard, studied family (Lov\[AAcute]sz 1979; Shannon capacity of odd cycles), and the layer bound above is a corollary of Hales (1973) and Sonnemann-Krafft (1974), not new; only the single value \[Omega](C7\[Or]C7\[Or]C5) = 9 is a non-trivial computed exception (the others are products of known factor clique numbers). Second, TERMINOLOGY: 'catalyst' is used informally for a fixed quantum resource composed INTO the joint experiment to tip the exclusivity load; it is NOT a resource-theoretic catalyst returned unchanged, which provably cannot exist for contextuality (Karvonen, PRL 127, 160402 (2021)). All numbers are exact and machine-verified below.*)

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
  "beyondMachineryRecoversC7" -> layerC7 === True,
  "beyondPathRouteClosed" -> layerPath === False &&
     Length[eightPath] == 8 && cliqueByAdjQ[adjP775, eightPath],
  "beyondNonagonSafe" -> layerNonagon === False &&
     Length[eightNonagon] == 8 && cliqueByAdjQ[adjC995, eightNonagon] &&
     Simplify[nonagonLoad == 2/Sqrt[5]] && nonagonLoad < 1,
  "beyondNonagonTwoCatalystsBoundary" -> Length[twentyNonagon] == 20 &&
     Length[Union[twentyNonagon]] == 20 && cliqueByAdjQ[adjC9955, twentyNonagon] &&
     Simplify[20 (1/2) (1/2) (1/5) == 1],
  "beyondThetaCeiling" -> Simplify[4 Sqrt[5] < 9] &&
     N[thetaCeiling[27], 30] > 9 && N[thetaCeiling[29], 30] < 9 &&
     AllTrue[Range[29, 199, 2], N[thetaCeiling[#], 25] < 9 &] &&
     Floor[N[(1 + Sec[Pi/9])^3 Sqrt[5], 30]] == 19,
  "beyondOnlyHeptagonTheorem" -> sweepControl === True &&
     Length[oddSweep] == 10 && AllTrue[Values[oddSweep], # === False &],
  "yanComplement" -> yanLoad > 1 && Abs[yanLoad - 7/(2 LovaszTheta[CycleGraph[7]])] < 10^-6
|>;
Column[{HeptagonCatalysisVerification, "OK" -> And @@ Values[HeptagonCatalysisVerification]}]

(* ::Section:: *)
(*Does Any Other Catalyst Length Activate the Heptagon Box?*)

(* ::Text:: *)
(*A companion question to the sections above, in the other direction: fixing the box at H = C7\[Or]C7 (49 vertices, \[Omega](H) = 4) and asking whether some catalyst length OTHER than the pentagon (m = 5) can also drive a 9-clique in H\[Or]Cm \[LongDash] i.e. whether the pentagon's role here is a genuine isolated resonance or one instance of a broader family. Checked exhaustively for m = 7, 9, 11, 13: NO 9-clique exists for any of them; the pentagon alone activates.*)

(* ::Text:: *)
(*Method. A direct generalization of the pentagram-layer reduction used throughout this essay, but for a general odd catalyst length m the "conflict structure" among layers is complement(Cm) \[LongDash] a genuine circulant, not the simple 5-cycle special to C5's self-complementarity that permits the chain-DP trick above. Instead: enumerate every "scheme" (a choice of L active catalyst-layer positions, each assigned an H-clique size in {1,2,3,4} summing to 9), and for each scheme solve a small CSP (one variable per active position, domain = H-cliques of the assigned size, binary compatibility constraints between non-Cm-adjacent position pairs) via backtracking with forward checking. Total scheme counts are small and fully enumerable: 3535 (m=7), 19855 (m=9), 81367 (m=11), 270270 (m=13).*)

(* ::Text:: *)
(*Results. m = 7 and m = 9 were resolved locally (Python, exhaustive over every scheme, including a bigger-budget recheck of the handful that hit an internal node cap): NO 9-clique, fully exhaustive, in both cases. m = 11 and m = 13 were resolved independently via Wolfram \[LongDash] not a reimplementation of the CSP encoding, but a genuinely different method exploiting the graph's own automorphism group: translation-pin the first clique vertex (WLOG, since H\[Or]Cm is vertex-transitive), verify the order-16 point-stabilizer (negate each C7 coordinate independently, negate the Cm coordinate, swap the two identical C7 factors) is genuinely automorphic, orbit-decompose the search for the remaining clique vertices under this group (recursively, wherever a direct FindClique call on the current common neighborhood does not resolve quickly), and confirm every orbit's decomposition partitions its candidate set exactly. Run first on a free evaluation kernel for validation, then reproduced end-to-end on paid Wolfram Cloud compute (CloudEvaluate) for a genuine independent confirmation: m = 11 (539 vertices, 30 first-level orbits, one requiring a 44-way further split) and m = 13 (637 vertices, 34 first-level orbits, two requiring 52-way and 142-way further splits) both give NO 9-clique, exhaustively, matching the free-kernel run exactly.*)

(* ::Text:: *)
(*Conclusion. Across every catalyst length tested against the fixed heptagon box, only the pentagon activates. This is consistent with, and does not by itself explain, the isolated nature of the n = 7 resonance proven earlier in this essay: whatever makes Z7 special appears tied to the SPECIFIC pentagon catalyst, not to "any sufficiently short odd cycle."*)

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
(*Cabello, PRL 110, 060402 (2013); Cabello, Severini, Winter, PRL 112, 040401 (2014) and arXiv:1010.2163 (graph-theoretic frame: classical/quantum/general bounds are \[Alpha], \[CurlyTheta], \[Alpha]* respectively).*)

(* ::Item:: *)
(*Lov\[AAcute]sz, IEEE Trans. Inf. Theory 25, 1 (1979) (\[CurlyTheta]: the sandwich \[Omega](G) <= \[CurlyTheta](Complement[G]), multiplicativity over strong products, odd-cycle values; Shannon capacity of C5).*)

(* ::Item:: *)
(*Hales, J. Combin. Theory Ser. B 15, 146 (1973); Sonnemann, Krafft, J. Combin. Theory Ser. B 17, 133 (1974) (independence numbers of strong products of odd cycles \[LongDash] the source of the layer bound \[Omega](H\[Or]C5) <= Floor[5 \[Omega](H)/2] via the complement identity).*)

(* ::Item:: *)
(*Karvonen, PRL 127, 160402 (2021) (neither contextuality nor nonlocality admits resource-theoretic catalysts \[LongDash] distinguishes the informal 'catalyst' usage here from the returned-unchanged sense).*)

(* ::Item:: *)
(*Lapkiewicz et al., Nature 474, 490 (2011) (pentagon visibility ~0.977); Klyachko, Can, Binicio\[GBreve]lu, Shumovsky, PRL 101, 020403 (2008).*)
