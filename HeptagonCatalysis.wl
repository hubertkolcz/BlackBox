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
(*Does the pentagon catalyst expel every n-cycle box with n >= 7? The first release of this note reported two searches INCONCLUSIVE at their pre-registered time caps: a 9-clique in C9\[Or]C9\[Or]C5 (405 vertices), and a 9-clique in the path product P7\[Or]P7\[Or]C5 (245 vertices \[LongDash] wraparound-free, so a hit would embed in EVERY C_n\[Or]C_n\[Or]C5 with n >= 7 and settle the question universally). Both are now settled, and both answers are NO. The tool is an exact reduction along the catalyst factor instead of brute clique search: a clique of H\[Or]C5 meets each pentagon layer c in a clique Q_c of H; layers at C5-distance 1 are jointly exclusive for free; each pentagram pair (c, c+2 mod 5) needs Q_c and Q_(c+2) disjoint with their union a clique of H, so |Q_c| + |Q_(c+2)| <= \[Omega](H). Summing around the pentagram cycle 0-2-4-1-3-0 gives the pentagram bound \[Omega](H\[Or]C5) <= Floor[5 \[Omega](H)/2]; and for a 9-clique over \[Omega](H) = 4 no layer can be empty (the other four split into two pentagram pairs, at most 8 events), so all five layer sizes lie in {1, 2, 3} and only 15 size vectors survive. The search below is exhaustive \[LongDash] False is a proof \[LongDash] and runs in seconds where FindClique hit its cap: the path product turns out to pack 233 million maximum cliques, all of size 8.*)

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
(*Lov\[AAcute]sz, IEEE Trans. Inf. Theory 25, 1 (1979) (\[CurlyTheta]: the sandwich \[Omega](G) <= \[CurlyTheta](Complement[G]), multiplicativity over strong products, odd-cycle values).*)

(* ::Item:: *)
(*Lapkiewicz et al., Nature 474, 490 (2011) (pentagon visibility ~0.977); Klyachko, Can, Binicio\[GBreve]lu, Shumovsky, PRL 101, 020403 (2008).*)
