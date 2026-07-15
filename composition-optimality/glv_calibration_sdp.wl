(* PLACEHOLDER calibration object, NOT the real "(3,1) cell" -- the actual
   connection set (edges) of the real 3645-vertex graph is not recoverable
   from any saved record this session (confirmed: absent from the repo, the
   BlackBox paclet, and the published compute-services memo). Per explicit
   user decision, this builds a CONCRETE graph with the SAME vertex count
   and automorphism/point-stabilizer STRUCTURE as the real (3,1) cell family
   (Z9^k x Z5, sign-flips x Sk x Z5-sign point stabilizer), at a SMALLER
   scale (k=2, 405 vertices) matching the known "405-vertex calibration
   object" referenced elsewhere this session -- purely to get genuine
   RemoteBatchSubmit timing/credit data for a graph of this SIZE and
   SYMMETRY CLASS. Any SDP bound VALUE this produces is meaningless for the
   actual research question; only the TIMING/COST data transfers. *)

SetDirectory[DirectoryName[$InputFileName]];

n1 = 9; n2 = 9; n3 = 5; (* Z9 x Z9 x Z5 *)
groupElems = Tuples[{Range[0, n1 - 1], Range[0, n2 - 1], Range[0, n3 - 1]}];
nVerts = Length[groupElems];
Print["Group Z9 x Z9 x Z5: ", nVerts, " elements (expect 405)"];

groupAdd[{a1_, b1_, c1_}, {a2_, b2_, c2_}] := {Mod[a1 + a2, n1], Mod[b1 + b2, n2], Mod[c1 + c2, n3]};
groupNeg[{a_, b_, c_}] := {Mod[-a, n1], Mod[-b, n2], Mod[-c, n3]};
v0 = {0, 0, 0};

(* Point stabilizer H (order 16 = 2x2 INDEPENDENT sign-flips on the two Z9
   factors, x 2 permuting them, x 2 sign-flip on the Z5 factor). Built as
   explicit functions -- using Evaluate[] to avoid the exact Table/Function
   substitution (HoldAll) bug found and fixed earlier this session
   (silently collapsing a stabilizer group via un-substituted symbols).
   BUG FOUND AND FIXED (this run): first attempt used a single sgn1 flag to
   flip BOTH Z9 coordinates TOGETHER, giving only 2x2x2=8 elements instead
   of the correct 2x2x2x2=16 (a and b must be flippable INDEPENDENTLY) --
   caught by the very sanity check below before it could propagate into an
   expensive computation. *)
HGenActions = Flatten[Table[
    Function[{a, b, c}, Evaluate[
       Module[{aa, bb},
         aa = If[sgn1 == 1, a, Mod[-a, n1]];
         bb = If[sgn2 == 1, b, Mod[-b, n2]];
         If[perm == 2, {bb, aa, If[sgn3 == 1, c, Mod[-c, n3]]},
                       {aa, bb, If[sgn3 == 1, c, Mod[-c, n3]]}]]]],
    {sgn1, {1, -1}}, {sgn2, {1, -1}}, {perm, {1, 2}}, {sgn3, {1, -1}}], 3];
nH = Length[HGenActions];
Print["Built ", nH, " H group elements (expect 16)."];

(* Verify H really is a group of automorphisms of the AMBIENT structure
   (i.e. these maps, applied to the full vertex set, are all distinct and
   each is a bijection G->G respecting negation/addition structure --
   sanity, not yet tied to any specific edge set).
   BUG FOUND AND FIXED (this run): the first attempt at this check compared
   Sort[image list] across maps -- but Sort[] of ANY bijection's image is
   just Sort[groupElems] again (sorting destroys exactly the information
   that distinguishes one permutation from another), so the check was
   vacuously guaranteed to report "not distinct" regardless of whether H
   was actually correct. Fixed by comparing the UNSORTED (ordered) image
   sequences instead, which genuinely differ between distinct permutations. *)
orderedImages = Table[Apply[f, #] & /@ groupElems, {f, HGenActions}];
Print["All ", nH, " maps give distinct images as functions of the full vertex set: ",
  Length[DeleteDuplicates[orderedImages]] == nH, " (expect True)."];
Print["Each map is a bijection on the ", nVerts, "-element vertex set: ",
  AllTrue[orderedImages, Sort[#] == Sort[groupElems] &], " (expect True)."];

(* PLACEHOLDER connection set: the H-orbit of one generic nonzero element,
   chosen to avoid low-order/degenerate coordinates (all coords nonzero and
   distinct-ish) so the resulting graph has a reasonably generic (not
   accidentally extra-symmetric) edge structure -- automatically symmetric
   since global negation is realized inside H (sgn1=-1,perm=1,sgn3=-1 gives
   (a,b,c)->(-a,-b,-c)). *)
genericGen = {2, 5, 1};
connectionOrbit = DeleteDuplicates[(Apply[#, genericGen]) & /@ HGenActions];
Print["Connection set (H-orbit of ", genericGen, "): ", Length[connectionOrbit],
  " elements. Symmetric (closed under negation): ",
  Sort[connectionOrbit] == Sort[groupNeg /@ connectionOrbit], " (expect True)."];

edges = Select[
   Flatten[Table[{groupElems[[i]], groupElems[[j]]}, {i, nVerts}, {j, i + 1, nVerts}], 1],
   MemberQ[connectionOrbit, groupAdd[#[[1]], groupNeg[#[[2]]]]] &];
Print["Placeholder graph: ", nVerts, " vertices, ", Length[edges], " edges, degree ",
  Length[connectionOrbit], " (regular, by construction)."];

(* H-orbits on UNORDERED PAIRS of V\{v0} via Burnside's lemma -- this is the
   quantity that sets the true number of free variables in one A_{v0}(y)
   moment-matrix block of the GLV L^2 hierarchy (mirrors the 80,780
   derivation for the real k=3 case, at this smaller k=2 scale). *)
others = DeleteCases[groupElems, v0];
pairOrbitCount = Module[{total = 0},
   Do[
    Module[{img, fixedPts, twoCycles, cyc},
      img = Apply[f, #] & /@ others;
      cyc = AssociationThread[others -> img];
      fixedPts = Count[others, w_ /; cyc[w] === w];
      twoCycles = Count[others, w_ /; cyc[w] =!= w && cyc[cyc[w]] === w] / 2;
      total += Binomial[fixedPts, 2] + twoCycles],
    {f, HGenActions}];
   total/Length[HGenActions]];
Print["H-orbits on pairs of V\\{v0} (", Length[others], " elements): ",
  pairOrbitCount, " -- this is the free-variable count for ONE A_{v0}(y) block."];

Print["Moment-matrix block size: ", nVerts + 1, "x", nVerts + 1, " (n+1, per GLV Lemma 2.2)."];

(* ------------------------------------------------------------------------- *)
(* Build the L^2 moment-matrix SDP per GLV Lemma 2.2, T={v0} (re-verified
   directly against the extracted paper text, glv_paper_text.txt, lines
   ~300-420, not from memory): M({v0};y) >= 0  <=>
     (A_empty(y) - A_v0(y)) >= 0  AND  A_v0(y) >= 0
   where A_S(y) is (n+1)x(n+1) with A_S[0,0]=y_S, A_S[0,i]=y_{S union {i}},
   A_S[i,j]=y_{S union {i,j}}.
   Symmetry reduction (vertex-transitivity via translation + point-
   stabilizer H fixing v0):
     y_empty = 1 (normalization); y_i = y1 for all i (single common var);
     y_{i,j} (pairs not nec. containing v0) reduces, via translating
       {i,j} -> {0, j-i}, to H-orbits on G\{0} -- variable p[orbit rep];
     y_{v0,i,j} (triples containing v0) reduces to H-orbits on PAIRS of
       V\{v0} -- variable t[orbit rep] (the 80,780-analog count).
   PLACEHOLDER graph, NOT the real (3,1) cell (see file header) -- built
   purely to get real RemoteBatchSubmit-comparable timing data. *)
(* ------------------------------------------------------------------------- *)

Print["=== Building orbit-reduced variable tables ==="];

singleOrbitRep[g_] := First[Sort[Union[Apply[#, g] & /@ HGenActions]]];
singleReps = DeleteDuplicates[singleOrbitRep /@ others];
nSingleOrbits = Length[singleReps];
Print["H-orbits on G\\{0} (", Length[others], " elements): ", nSingleOrbits,
  " -- free-variable count for pair-type y_{i,j} entries (analog of the ",
  "'104' quantity from earlier, at this smaller scale)."];

pairOrbitRep[{g1_, g2_}] := First[Sort[Union[Sort[{Apply[#, g1], Apply[#, g2]}] & /@ HGenActions]]];
allPairs = Subsets[others, {2}];
Print["Total pairs of V\\{v0} to classify: ", Length[allPairs]];
pairReps = DeleteDuplicates[pairOrbitRep /@ allPairs];
nPairOrbits = Length[pairReps];
Print["H-orbits on pairs of V\\{v0}: ", nPairOrbits, " (cross-check vs Burnside count ",
  pairOrbitCount, ": ", nPairOrbits == pairOrbitCount, ")."];

y1 = Symbol["y1"];
pVars = Association[Table[rep -> Symbol["p" <> ToString[Hash[rep]]], {rep, singleReps}]];
tVars = Association[Table[rep -> Symbol["t" <> ToString[Hash[rep]]], {rep, pairReps}]];

pLookup[g_] := pVars[singleOrbitRep[g]];
tLookup[{g1_, g2_}] := tVars[pairOrbitRep[{g1, g2}]];

Print["Building A_empty (", nVerts + 1, "x", nVerts + 1, ")..."];
{tAEmpty, buildEmpty} = AbsoluteTiming[
   AEmpty = ConstantArray[0, {nVerts + 1, nVerts + 1}];
   AEmpty[[1, 1]] = 1;
   Do[AEmpty[[1, i + 1]] = y1; AEmpty[[i + 1, 1]] = y1; AEmpty[[i + 1, i + 1]] = y1, {i, nVerts}];
   Do[
    Module[{val = pLookup[groupAdd[groupElems[[i]], groupNeg[groupElems[[j]]]]]},
      AEmpty[[i + 1, j + 1]] = val; AEmpty[[j + 1, i + 1]] = val],
    {i, nVerts}, {j, i + 1, nVerts}];
  ];
Print["  built in ", tAEmpty, "s."];

otherIdx = Position[groupElems, v0][[1, 1]];
Print["Building A_v0 (", nVerts + 1, "x", nVerts + 1, ")..."];
{tAv0, buildAv0} = AbsoluteTiming[
   Av0 = ConstantArray[0, {nVerts + 1, nVerts + 1}];
   Av0[[1, 1]] = y1;
   Do[
    If[i != otherIdx,
      Module[{val = pLookup[groupElems[[i]]]},
        Av0[[1, i + 1]] = val; Av0[[i + 1, 1]] = val; Av0[[i + 1, i + 1]] = val]],
    {i, nVerts}];
   Do[
    If[i != otherIdx && j != otherIdx,
      Module[{val = tLookup[{groupElems[[i]], groupElems[[j]]}]},
        Av0[[i + 1, j + 1]] = val; Av0[[j + 1, i + 1]] = val]],
    {i, nVerts}, {j, i + 1, nVerts}];
  ];
Print["  built in ", tAv0, "s."];

allSdpVars = Prepend[Join[Values[pVars], Values[tVars]], y1];
Print["Total free SDP variables: ", Length[allSdpVars]];

Print["=== Solving SDP locally (no cloud cost) -- this is the real timing test ==="];
{tSolve, sdpResult} = AbsoluteTiming[
   Quiet[Check[
     SemidefiniteOptimization[y1,
       {VectorGreaterEqual[{AEmpty - Av0, 0}, {"SemidefiniteCone", nVerts + 1}],
        VectorGreaterEqual[{Av0, 0}, {"SemidefiniteCone", nVerts + 1}]},
       allSdpVars],
     $Failed]]];
Print["Local SDP solve: ", tSolve, "s, result head = ", Head[sdpResult],
  ", y1* = ", If[ListQ[sdpResult], y1 /. sdpResult, sdpResult]];
