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
