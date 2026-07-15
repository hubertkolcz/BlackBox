(* ::Package:: *)
(* ge_pentad_hypergraph.wl -- showcase figure: the GE exclusivity hypergraph for
   two copies of KCBS (Cabello's GE two-copy construction, arXiv:1210.2988), rendered
   as its own object rather than just a Hamiltonian/graph-coloring diagram.

   Construction (kernel-verified, see checks below): vertex set = C5 x C5 (25 events,
   one per ordered pair of KCBS-pentagon contexts); edge iff the first OR the second
   coordinate is C5-adjacent (the "OR-product" that realizes GE's two-copy exclusivity
   graph). This reproduces the project's own previously-documented facts: 25 vertices,
   200 edges, exactly 10 maximal cliques of size 5 ("pentads"), 16-regular.

   Each pentad is a transversal: one vertex per outer C5-cluster, i = 0..4 in order --
   so its convex hull is a non-self-intersecting 5-pointed star when the 25 vertices are
   laid out in the "pentagon-of-pentagons" arrangement below. Rendering all 10 pentad
   hulls translucently over a faint 200-edge backdrop is the point of the figure: it
   makes the GE-002 combinatorial fact (ten pentads tile the two-copy exclusivity graph)
   directly visible instead of just tabulated.

   Ledger: GE-002 (two-copy GE construction), MESH-006 (pentagon-composition context
   this module sits alongside). Run: wolframscript -file ge_pentad_hypergraph.wl ->
   figures/hypergraph_{paper,gallery}.{png,pdf}. *)

(* ============ combinatorics (kernel-verified before any styling) ============ *)
c5Adj[i_, j_] := Mod[i - j, 5] == 1 || Mod[j - i, 5] == 1;
verts = Tuples[Range[0, 4], 2];
edgeType[{i1_, j1_}, {i2_, j2_}] := Module[{ai = c5Adj[i1, i2], aj = c5Adj[j1, j2]},
   Which[ai && aj, "both", ai, "i", aj, "j", True, "none"]];
edges = Select[Subsets[verts, {2}], edgeType @@ # =!= "none" &];
g = Graph[verts, UndirectedEdge @@@ edges];
pentads = Select[FindClique[g, Infinity, All], Length[#] == 5 &];
pentadsSorted = SortBy[#, First] & /@ pentads;

(* structural sanity gate -- must match GE-002 / prior session verification exactly *)
structureOK = And[
   Length[verts] == 25, Length[edges] == 200, Length[pentadsSorted] == 10,
   Union[VertexDegree[g]] == {16}];
If[! structureOK,
   Print["STRUCTURE CHECK FAILED -- aborting export. verts=", Length[verts],
     " edges=", Length[edges], " pentads=", Length[pentadsSorted],
     " degrees=", Union[VertexDegree[g]]];
   Abort[]];

(* ============ pentagon-of-pentagons layout ============ *)
coord[{i_, j_}] := Module[{outerAng = 2 Pi i/5 + Pi/2, innerAng = 2 Pi j/5 + Pi/2,
    Rr = 3.1, rr = 0.85},
   Rr {Cos[outerAng], Sin[outerAng]} + rr {Cos[innerAng], Sin[innerAng]}];
coords = AssociationMap[coord, verts];

(* ============ render (Paper / Gallery themes) ============ *)
hyperGraphV1[theme_String] := Module[
   {t, bg, ink, edgeCol, nodeCol, pentColors, edgePrims, pentPrims, nodePrims},
   t = theme;
   bg = If[t == "Paper", White, RGBColor[0.047, 0.055, 0.086]];
   ink = If[t == "Paper", GrayLevel[0.15], GrayLevel[0.94]];
   edgeCol = If[t == "Paper", GrayLevel[0.65], GrayLevel[0.45]];
   nodeCol = If[t == "Paper", RGBColor[0.14, 0.40, 0.70], RGBColor[0.40, 0.74, 0.99]];
   pentColors = ColorData[If[t == "Paper", "Rainbow", "BrightBands"]] /@
     Rescale[Range[10], {1, 10}, {0, 1}];
   edgePrims = Table[{edgeCol, Opacity[0.1], Thickness[0.0012],
      Line[{coords[edges[[k, 1]]], coords[edges[[k, 2]]]}]}, {k, Length[edges]}];
   pentPrims = Table[
     {Opacity[0.16], pentColors[[p]], Polygon[coords /@ pentadsSorted[[p]]],
      Opacity[0.55], pentColors[[p]], Thickness[0.0028],
      Line[Append[coords /@ pentadsSorted[[p]], coords[pentadsSorted[[p, 1]]]]]},
     {p, Length[pentadsSorted]}];
   nodePrims = Table[With[{c = coords[v]},
      {EdgeForm[None], {Opacity[0.18], nodeCol, Disk[c, 0.30]}, nodeCol, Disk[c, 0.115],
       White, Opacity[0.9], Disk[c, 0.038]}], {v, verts}];
   Graphics[{edgePrims, pentPrims, nodePrims},
     PlotRange -> 4.3, ImageSize -> 680, Background -> bg,
     PlotLabel -> Style[
       "GE exclusivity hypergraph  C5(OR)\[TensorProduct]C5   (25 events, 200 exclusivity edges, 10 pentad hyperedges)",
       11, ink, FontFamily -> "Helvetica"]]];

figPaper = hyperGraphV1["Paper"];
figGallery = hyperGraphV1["Gallery"];

figDir = FileNameJoin[{DirectoryName[$InputFileName], "figures"}];
If[! DirectoryQ[figDir], CreateDirectory[figDir, CreateIntermediateDirectories -> True]];
Export[FileNameJoin[{figDir, "hypergraph_paper.png"}], figPaper, ImageResolution -> 200];
Export[FileNameJoin[{figDir, "hypergraph_paper.pdf"}], figPaper];
Export[FileNameJoin[{figDir, "hypergraph_gallery.png"}], figGallery, ImageResolution -> 200];
Export[FileNameJoin[{figDir, "hypergraph_gallery.pdf"}], figGallery];

Print["structureOK = ", structureOK, "  |V|=", Length[verts], " |E|=", Length[edges],
  " pentads=", Length[pentadsSorted]];
Print["Wrote hypergraph_{paper,gallery}.{png,pdf} to ", figDir];
