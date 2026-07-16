(* ::Package:: *)
(* glue_anatomy_figure.wl -- pentagon-gluing/: the anatomy of the mesh construction.
   THREE LAYERS, kept visually and conceptually distinct:
     1 INPUT   the gluing letters d/t: Z2 ACTIONS, one per joint -- the letter only
               chooses which endpoint of the shared edge precedes the next block's
               first own vertex (d = orientation kept, t = flipped);
     2 OBJECT  identification (quotient): each joint MERGES one rim edge of pentagon k
               with the base edge of pentagon k+1 -- one edge belonging to BOTH
               5-cycles. The word W therefore builds ONE exclusivity graph G_W
               (3L vertices, 4L edges), not L wired-together graphs;
     3 OUTPUT  the invariants alpha(G_W) and theta(G_W): properties of the whole
               graph. alpha is reachable from the letters through the 3-state
               max-plus transfer DP (letter-local, exact rational); theta only
               through one global SDP over all vertices -- no per-letter law.
   Anchors reproduced LIVE in this file, cross-checked independently in
   Python/networkx/SCS (verify_glue_anatomy.py, 2026-07-16, ALL 16 checks OK):
     alpha(ddt^2) = 8, alpha(ddt^3) = 12       (the 4-per-3-blocks staircase),
     maxplus-trace(T_d T_d T_t T_d T_d T_t) = 8 = alpha   (DP factorization, live),
     theta(C5) = Sqrt[5],
     theta(ddt^2) = 8.347042185                (chordal anchor, CaseStudies.wl),
     theta(ddd^2) = alpha(ddd^2) = 9           (direct collapse: gap 0 already at L=6).
   Asymptotic densities cited from the kernel-verified upstream (CaseStudies.wl, D3):
     alpha-bar = 4/3 (both ttt and ddt);  theta-bar(ttt) = tau*;
     theta-bar(ddt) = 1.40323087 (continuum 9x9 symbol minimax).
   Naming: d == direct, t == twisted — the project-wide convention since 2026-07-16.
   (Historical: before 2026-07-16 the letters were c/t for cis/trans; legacy letters
   survive only in git history, *.log files, and the pre-rename .wxf checkpoint.)
   Run: wolframscript -file glue_anatomy_figure.wl  ->  glue_anatomy.png / .pdf *)

(* ------------------------------------------------------------------ *)
(* verified computational core (verbatim origins noted per function)   *)
(* ------------------------------------------------------------------ *)

(* wordRing: CaseStudies.wl lines 281-288, letters renamed c -> d *)
wordRing[word_String, reps_Integer] := Module[
   {w = Characters[StringRepeat[word, reps]], L, edges = {}, u, v, km},
   L = Length[w];
   Do[km = Mod[k - 1, L];
    {u, v} = If[w[[km + 1]] === "d", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
    edges = Join[edges, {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2},
       {3 k + 2, 3 k + 3}, {3 k + 3, v}}], {k, 0, L - 1}];
   Graph[Range[3 L], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];

(* LovaszTheta: BlackBox/Kernel/BlackBox.wl lines 62-69, verbatim *)
lovaszTheta[g_Graph] := Module[{h = IndexGraph[g], n, x, X, vars, cons, sol},
   n = VertexCount[h];
   X = Table[If[i <= j, x[i, j], x[j, i]], {i, n}, {j, n}];
   vars = Flatten[Table[x[i, j], {i, n}, {j, i, n}]];
   cons = Join[{Tr[X] == 1, VectorGreaterEqual[{X, 0}, {"SemidefiniteCone", n}]},
     (x[#[[1]], #[[2]]] == 0) & /@ (Sort /@ (List @@@ EdgeList[h]))];
   sol = SemidefiniteOptimization[-Total[X, 2], cons, vars, MaxIterations -> 300];
   Total[X, 2] /. sol];

(* dpTransfer: runners/BuildMeshGlueNotebook.wl lines 506-514, verbatim.
   States = occupancy of the two current interface vertices; (1,1) impossible
   because interface endpoints are adjacent (the shared edge itself). *)
dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
       ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "d", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];
mpMul[A_, B_] := Table[Max[Table[A[[i, k]] + B[[k, j]], {k, 3}]], {i, 3}, {j, 3}];

(* ------------------------------------------------------------------ *)
(* live values                                                         *)
(* ------------------------------------------------------------------ *)

word6 = Characters["ddtddt"];
g6 = wordRing["ddt", 2]; g9 = wordRing["ddt", 3];
gT = wordRing["ttt", 2]; gD = wordRing["ddd", 2];

alpha6 = Length[First[FindIndependentVertexSet[g6]]];
alpha9 = Length[First[FindIndependentVertexSet[g9]]];
alphaT = Length[First[FindIndependentVertexSet[gT]]];
alphaD = Length[First[FindIndependentVertexSet[gD]]];
indepWitness = First[FindIndependentVertexSet[g6]];

theta5 = lovaszTheta[CycleGraph[5]];
theta6 = lovaszTheta[g6];
thetaT = lovaszTheta[gT];
thetaD = lovaszTheta[gD];

mWord = Fold[mpMul, dpTransfer[First[word6]], dpTransfer /@ Rest[word6]];
dpTrace = Max[Diagonal[mWord]];                    (* == alpha6: the DP factorization *)

tauStar = N[Root[49 #^3 - 128 #^2 - 75 # + 218 &, 2], 12];  (* CaseStudies.wl D3 *)
thetaBarDdt = 1.40323087;                          (* continuum symbol minimax, cited *)

gapsAsym = {0., N[tauStar] - 4/3, thetaBarDdt - 4/3};        (* asymptotic densities *)
gapsLive = {thetaD/6 - alphaD/6, thetaT/6 - alphaT/6,
   theta6/6 - alpha6/6};                           (* this file's L = 6 SDP readings *)

sanity = <|
   "alpha(ddt^2)=8" -> alpha6 == 8,
   "alpha(ddt^3)=12 (staircase 4/3)" -> alpha9 == 12,
   "DP maxplus-trace == alpha (letter-local factorization)" -> dpTrace == alpha6,
   "alpha(ttt^2)=8, alpha(ddd^2)=9" -> alphaT == 8 && alphaD == 9,
   "theta(C5)=Sqrt[5]" -> Abs[theta5 - Sqrt[5.]] < 10^-5,
   "theta(ddt^2) chordal anchor 8.347042185" -> Abs[theta6 - 8.347042185] < 10^-3,
   "direct collapse: theta(ddd^2)=alpha(ddd^2)=9" -> Abs[thetaD - 9.] < 10^-3,
   "witness is independent" -> IndependentVertexSetQ[g6, indepWitness],
   "asymptotic ratio 1.611 (+61%)" ->
     Abs[gapsAsym[[3]]/gapsAsym[[2]] - 1.611] < 10^-2|>;

(* ------------------------------------------------------------------ *)
(* palette (house: MeshGlue coral for shared edges; orbit_spectrum tones) *)
(* ------------------------------------------------------------------ *)

coral = RGBColor[0.60, 0.24, 0.11];   (* the SHARED (identified) edges  -- layer 2 *)
cAct  = RGBColor[0.20, 0.34, 0.64];   (* the ACTIONS / d letters        -- layer 1 *)
cOpt  = RGBColor[0.87, 0.58, 0.11];   (* t letters, ddt highlight *)
cLine = RGBColor[0.68, 0.70, 0.75];
gray  = RGBColor[0.55, 0.55, 0.53];
ink   = GrayLevel[0.14];

(* ------------------------------------------------------------------ *)
(* PANEL 1 -- INPUT: the two actions, close-up on a single joint       *)
(* ------------------------------------------------------------------ *)

pentLpts = Table[{-0.809 + Cos[a Degree], Sin[a Degree]}, {a, {36, 108, 180, 252, 324}}];
pentRpts = Table[{0.809 - Cos[a Degree], Sin[a Degree]}, {a, {36, 108, 180, 252, 324}}];
(* index 1 = U = (0, .588) and index 5 = V = (0, -.588) in both lists *)

jointCloseup[letter_String, xoff_] := Module[
   {sh = {xoff, 0}, L5, R5, U, V, a, b, c, entry, capCol},
   L5 = (# + sh) & /@ pentLpts; R5 = (# + sh) & /@ pentRpts;
   U = L5[[1]]; V = L5[[5]];
   b = R5[[3]];
   {a, c} = If[letter === "d", {R5[[2]], R5[[4]]}, {R5[[4]], R5[[2]]}];
   entry = If[letter === "d", U, V];
   capCol = If[letter === "d", cAct, cOpt];
   {CapForm["Round"], JoinForm["Round"],
    (* the two pentagon rims *)
    {gray, Thickness[0.0032], Line[Append[L5, L5[[1]]]], Line[Append[R5, R5[[1]]]]},
    (* the shared edge: ONE edge of BOTH pentagons *)
    {coral, Thickness[0.010], Line[{U, V}]},
    Text[Style["u", 10, coral, Bold], U + {-0.14, 0.13}],
    Text[Style["v", 10, coral, Bold], V + {-0.14, -0.13}],
    (* traversal of the new block's 5-cycle:  entry -> a -> b -> c -> exit *)
    {capCol, Thickness[0.006], Arrowheads[{{0.045, 0.62}}], Arrow[{entry, a}]},
    {gray, Thickness[0.0032], Arrowheads[{{0.030, 0.58}}],
     Arrow[{a, b}], Arrow[{b, c}], Arrow[{c, If[letter === "d", V, U]}]},
    Text[Style["a", 10, ink, Bold], a + 0.16 Normalize[a - (sh + {0.809, 0})]],
    Text[Style["b", 10, ink], b + {0.15, 0}],
    Text[Style["c", 10, ink], c + 0.16 Normalize[c - (sh + {0.809, 0})]],
    Text[Style[If[letter === "d", "u precedes a", "v precedes a"], 9, capCol, Italic],
     sh + {0.95, If[letter === "d", 1.22, -1.22]}],
    Text[Style[If[letter === "d",
       "d \[LongDash] orientation kept (rotation)",
       "t \[LongDash] orientation flipped (reflection)"], 11, capCol, Bold],
     sh + {0, -1.42}]}];

panelIn = Graphics[{jointCloseup["d", -2.75], jointCloseup["t", 2.75],
    {cLine, Thickness[0.002], Line[{{0, -1.55}, {0, 1.25}}]}},
   PlotRange -> {{-5.35, 5.35}, {-1.72, 1.42}}, ImageSize -> 760,
   PlotLabel -> Style[
     "1 \[CenterDot] INPUT \[LongDash] the gluing ACTION: one letter per joint, an element of Z2 = Aut(shared edge)",
     12, ink, Bold],
   ImagePadding -> {{8, 8}, {6, 24}}, Background -> White];

(* ------------------------------------------------------------------ *)
(* PANEL 2 -- OBJECT: the word (ddt)^2 builds ONE graph G_W            *)
(* ------------------------------------------------------------------ *)

rIn = 1.45; rOut = 2.08; rMid = 1.76; rTag = 2.40;
posV[m_] := Module[{k = Quotient[m - 1, 3], aa},
   Switch[Mod[m, 3],
    1, aa = Pi k/3; rIn {Cos[aa], Sin[aa]},
    2, aa = Pi k/3; rOut {Cos[aa], Sin[aa]},
    0, aa = Pi k/3 - Pi/6; rMid {Cos[aa], Sin[aa]}]];
edges6 = Sort /@ (List @@@ EdgeList[g6]);
sharedQ[e_] := Mod[e[[1]], 3] == 1 && e[[2]] == e[[1]] + 1;

necklacePrims[fillSet_List, haloQ_] := Join[
   {CapForm["Round"], JoinForm["Round"]},
   If[haloQ, {{Opacity[0.15], cAct, PointSize[0.052], Point[posV /@ Range[18]]}}, {}],
   Table[With[{e = edges6[[i]]},
     If[sharedQ[e],
      {coral, Thickness[0.0085], Line[{posV[e[[1]]], posV[e[[2]]]}]},
      {gray, Thickness[0.0032], Line[{posV[e[[1]]], posV[e[[2]]]}]}]],
    {i, Length[edges6]}],
   Table[With[{p = posV[m]},
     If[MemberQ[fillSet, m],
      {FaceForm[ink], EdgeForm[{ink, Thickness[0.0018]}], Disk[p, 0.070]},
      {FaceForm[White], EdgeForm[{ink, Thickness[0.0018]}], Disk[p, 0.052]}]],
    {m, 18}]];

letterPrims = Table[With[{aa = Pi j/3, ch = word6[[j + 1]]},
    Text[Style[ch, 14, Bold, If[ch === "t", cOpt, cAct]], rTag {Cos[aa], Sin[aa]}]],
   {j, 0, 5}];

panelObj = Graphics[Join[necklacePrims[{}, False], letterPrims,
    {{coral, Thickness[0.0022], Line[{{2.95, 0.62}, {2.14, 0.10}}]},
     Text[Style["shared edge = ONE edge of BOTH\nadjacent pentagons (identified)", 9, coral],
      {3.05, 0.80}, {-1, 0}],
     Text[Style["own vertices per block:\n3k+1 (in) \[CenterDot] 3k+2 (out) \[CenterDot] 3k+3 (mid)", 8, gray],
      {3.05, -0.85}, {-1, 0}],
     Text[Style["at t the two strands\ninto the block cross", 8, cOpt, Italic],
      {-3.02, -0.75}, {1, 0}]}],
   PlotRange -> {{-3.15, 5.75}, {-2.72, 2.72}}, ImageSize -> 760,
   PlotLabel -> Style[
     "2 \[CenterDot] OBJECT \[LongDash] W = (ddt)^2 builds ONE exclusivity graph G_W: 3L = 18 vertices, 4L = 24 edges",
     12, ink, Bold],
   ImagePadding -> {{8, 8}, {6, 24}}, Background -> White];

(* ------------------------------------------------------------------ *)
(* PANEL 3 -- OUTPUT: alpha and theta, computed on the WHOLE graph     *)
(* ------------------------------------------------------------------ *)

gAlpha = Graphics[Join[necklacePrims[indepWitness, False],
    {Text[Style[Row[{"\[Alpha](G_W) = ", alpha6, "   \[RightArrow]   4/3 per block"}],
       11, ink, Bold], {0, -3.05}],
     Text[Style["classical bound \[LongDash] reached from the letters by the\n3-state max-plus transfer DP:  trace(T_d T_d T_t T_d T_d T_t) = 8\nletter-local, exact  (filled = a maximum independent set, live)",
       8.5, GrayLevel[0.32]], {0, -3.62}]}],
   PlotRange -> {{-2.95, 2.95}, {-4.15, 2.72}}, ImageSize -> 372, Background -> White];

gTheta = Graphics[Join[necklacePrims[{}, True],
    {Text[Style[Row[{"\[CurlyTheta](G_W) = ", NumberForm[theta6, {8, 5}],
        "   \[RightArrow]   1.40323 per block (L \[RightArrow] \[Infinity])"}],
       11, ink, Bold], {0, -3.05}],
     Text[Style["quantum bound \[LongDash] ONE semidefinite program over all 18\nvertices jointly; the optimal witness is delocalized (halo);\nno per-letter factorization exists in the pipeline",
       8.5, GrayLevel[0.32]], {0, -3.62}]}],
   PlotRange -> {{-2.95, 2.95}, {-4.15, 2.72}}, ImageSize -> 372, Background -> White];

(* ------------------------------------------------------------------ *)
(* PANEL 4 -- the invariant that results: gap density per word         *)
(* ------------------------------------------------------------------ *)

barLabs = {"ddd  (pure direct)", "ttt  (pure twisted)", "ddt  (optimum found)"};
barCols = {gray, cAct, cOpt};

panelBars = Graphics[{CapForm["Round"], JoinForm["Round"],
    {ink, Thickness[0.0030], Line[{{0.45, 0}, {3.75, 0}}]},
    Table[{barCols[[i]], Opacity[0.82],
      Rectangle[{i - 0.27, 0}, {i + 0.27, Max[gapsAsym[[i]], 0.0004]}]}, {i, 3}],
    Table[Text[Style[NumberForm[gapsAsym[[i]], {5, 4}], 9, barCols[[i]], Bold],
      {i, gapsAsym[[i]] + 0.0052}], {i, 3}],
    Table[Text[Style[barLabs[[i]], 9, ink], {i, -0.0068}], {i, 3}],
    (* live finite-size readings from THIS file's SDPs *)
    Table[{ink, PointSize[0.011], Point[{i + 0.19, Max[gapsLive[[i]], 0.]}]}, {i, 3}],
    Text[Style["\[FilledCircle] = live L = 6 reading (finite-size, from below)", 8,
      GrayLevel[0.35]], {1.06, 0.070}, {-1, 0}],
    (* the +61% bracket *)
    {cLine, Dashing[{0.010, 0.008}], Thickness[0.0024],
     Line[{{2.30, gapsAsym[[2]]}, {3.44, gapsAsym[[2]]}}]},
    {cOpt, Thickness[0.0036], Arrowheads[0.028],
     Arrow[{{3.44, gapsAsym[[2]]}, {3.44, gapsAsym[[3]]}}]},
    Text[Style["\[Times]1.611\n(+61% per pentagon,\nasymptotic)", 9, cOpt, Bold],
     {3.52, 0.057}, {-1, 0}]},
   PlotRange -> {{0.38, 4.42}, {-0.013, 0.082}}, AspectRatio -> 0.40, ImageSize -> 760,
   PlotLabel -> Style[
    "3 \[CenterDot] OUTPUT (continued) \[LongDash] gap density \[CurlyTheta]/L \[Minus] \[Alpha]/L: a function of the WHOLE word, not of any letter",
    12, ink, Bold],
   ImagePadding -> {{8, 8}, {6, 24}}, Background -> White];

(* ------------------------------------------------------------------ *)
(* assemble + export                                                   *)
(* ------------------------------------------------------------------ *)

fig = Column[{
    Style["Anatomy of the pentagon mesh \[LongDash] action, object, invariant", 15, ink, Bold],
    panelIn,
    Style["\[DownArrow]   gluing = IDENTIFICATION (quotient): the coral edge is one edge of both blocks \[LongDash] pentagons overlap, they are not wired together",
     9.5, GrayLevel[0.35], Italic],
    panelObj,
    Style["\[DownArrow]   invariants live on the WHOLE composite graph \[LongDash] \[Alpha] composes letter-by-letter (transfer DP), \[CurlyTheta] does not (global SDP only)",
     9.5, GrayLevel[0.35], Italic],
    GraphicsRow[{gAlpha, gTheta}],
    panelBars},
   Spacings -> 1.0, Alignment -> Center];

Export["glue_anatomy.png", fig, ImageResolution -> 200];
Export["glue_anatomy.pdf", fig];
Print["WROTE glue_anatomy.png (", FileByteCount["glue_anatomy.png"], " bytes) and .pdf"];
Print["sanity: ", sanity];
Print["ALL OK: ", AllTrue[Values[sanity], TrueQ]];
Print["theta(ddt^2) = ", theta6, " | theta(ttt^2) = ", thetaT, " | theta(ddd^2) = ", thetaD];
Print["gap densities live L=6: ", gapsLive, " | asymptotic: ", gapsAsym];
