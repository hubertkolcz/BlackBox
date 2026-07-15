(* ::Package:: *)

(* ===========================================================================
   InterferometerLayer.wl  --  Layer 1 (Builder A) of optical-synthesis.

   The CONSTRUCTIVE mirror of certification-protocol certification, interferometer layer:
   given a target unitary (matrix form) or a contextuality scenario (spec form),
   synthesize the Givens / beamsplitter MESH that realizes it, plus the
   pentagon-mesh routing of a (word, reps) target.

   Honest scope (verbatim in spirit from DESIGN.md / module header): this layer
   emits emulators of BLOCK-LOCAL statistics -- the Givens cascade of a single
   indivisible qutrit (Lapkiewicz) and the shared-mode routing of a pentagon
   mesh -- exactly what Prop. 1 / the certification map says classical linear
   optics CAN do. It does NOT construct globally entangled cluster states
   (single-photon linear optics cannot, absent exponential modes or KLM
   nonlinearity). Cite: Prop. 1 / BBT-002, BBT-003, MESH-004, MESH-008,
   Frustaglia et al. PRL 116 250404 (2016), Lapkiewicz et al. Nature 474 490
   (2011), Reck et al. PRL 73 58 (1994), Clements et al. Optica 3 1460 (2016).

   Loadability discipline: definitions ONLY; every demo / the A1,A2,A4 battery
   lives in the companion runner tests_interferometer_layer.wl. This file is
   Get-loadable on its own.

   Numeric/exact convention: algebraic inputs (KCBS geometry lives in Q(Sqrt5))
   stay exact end-to-end; Givens angles are kept as ArcCos[1/GoldenRatio] and
   matrix entries RootReduce'd, never N-collapsed on the exact path. N[] fills
   only the "Numeric" twin field. Any value feeding an == anchor is exact.

   Run the gates:  wolframscript -file tests_interferometer_layer.wl
   =========================================================================== *)

(* Best-effort load of the BlackBox paclet (native-first: reuse KCBSDirections
   as a cross-check; the exact geometry below is self-contained so this file
   still loads if the paclet path differs). *)
Quiet[Check[
  PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName], "..", "BlackBox"}]];
  Needs["HubertKolcz`BlackBox`"], Null]];

BeginPackage["HubertKolcz`OpticalCompiler`"];

CompileInterferometer::usage =
  "CompileInterferometer[u_?MatrixQ, opts] decomposes a unitary/special-orthogonal u into a StageMesh association (Method->\"Reck\" default, or \"Clements\"): <|ModeCount, Method, Stages, Unitary-><|Exact,Numeric|>, ResidualDiagonal|>. The exact path is taken automatically when u has algebraic (non-machine-real) entries. CompileInterferometer[spec_Association] with spec = <|\"Scenario\"->\"KCBS\"|> or <|\"Scenario\"->\"Cn\",\"n\"->n|> (n odd) reproduces the Lapkiewicz qutrit cascade [P,T1..T(n-1)] verbatim from the geometry; option Encoding->\"Qutrit\"|\"BiphotonQubit\".";
GivensDecompose::usage =
  "GivensDecompose[u_?MatrixQ, method_String] gives the ordered list of stage associations (two-level \"BS\" rotations + a residual \"Phase\" diagonal) whose product (StagesToUnitary) is u. method is \"Reck\" (lower-triangular elimination by left two-level unitaries) or \"Clements\" (column elimination by right two-level unitaries).";
StagesToUnitary::usage =
  "StagesToUnitary[stages_List, n_Integer] re-multiplies a stage list back into the n x n unitary it realizes, returning <|\"Exact\"->matrix,\"Numeric\"->matrix|>. Stages are read in APPLICATION order (first stage applied first to the state), matching kcbs_circuit.wl's circuit semantics.";
CompileMeshRouting::usage =
  "CompileMeshRouting[word_String, reps_Integer] gives the pentagon-mesh routing of the cct-style word: <|Word,Reps,L,ModeCount->3L, Blocks, Routing, EdgeList|>. EdgeList is exactly wordRingEdgesFast[word,reps] (O(L), no Join-in-loop). Each Blocks[[k]] is a 3-mode Lapkiewicz block stage; Routing[[k]] glues block k to block k-1 on SharedModes {3(k-1)+1,3(k-1)+2} with Orientation \"trans\" iff the FROM-block letter w[[k]] (block k-1's letter) is not \"c\" (matching wordRingEdgesFast's glue-pair swap).";
KCBSCascadeStages::usage =
  "KCBSCascadeStages[n_Integer] (n odd) gives {stages, Ts, P, geometry} of the exact Lapkiewicz n-cycle qutrit cascade, extracted (exact version) from kcbs_circuit.wl and kcbs_circuit_ncycle.wl.";

Begin["`Private`"];

Options[CompileInterferometer] = {Method -> "Reck", "Encoding" -> "Qutrit", "Exact" -> Automatic};

(* ------------------------------------------------------------------ *)
(* helpers: exactness detection, two-level embedding                   *)
(* ------------------------------------------------------------------ *)

exactMatrixQ[u_] := MatrixQ[u] && FreeQ[u, _Real];

(* embed a 2x2 block v on modes {a,b} (a<b assumed) into an n x n identity *)
embed2[v_, {a_, b_}, n_] := Module[{g = IdentityMatrix[n]},
  g[[a, a]] = v[[1, 1]]; g[[a, b]] = v[[1, 2]];
  g[[b, a]] = v[[2, 1]]; g[[b, b]] = v[[2, 2]]; g];

(* the 2x2 special-orthogonal rotation by theta (cos on the diagonal) *)
rot2[theta_] := {{Cos[theta], -Sin[theta]}, {Sin[theta], Cos[theta]}};

(* a stage carries its full n x n action in "Matrix" (Exact+Numeric) so
   StagesToUnitary is an exact fold; "Parameter" is the faithful annotation. *)
bsStage[{a_, b_}, theta_, mat_, label_] := <|
  "Type" -> "BS", "Modes" -> {a, b},
  "Parameter" -> <|"Exact" -> theta, "Numeric" -> N[theta]|>,
  "Matrix" -> <|"Exact" -> mat, "Numeric" -> N[mat]|>, "Label" -> label|>;

prepStage[mat_, label_] := <|
  "Type" -> "Prep", "Modes" -> Range[Length[mat]], "Parameter" -> None,
  "Matrix" -> <|"Exact" -> mat, "Numeric" -> N[mat]|>, "Label" -> label|>;

phaseStage[i_, ph_, n_] := <|
  "Type" -> "Phase", "Modes" -> {i},
  "Parameter" -> <|"Exact" -> ph, "Numeric" -> N[ph]|>,
  "Matrix" -> <|"Exact" -> ReplacePart[IdentityMatrix[n], {i, i} -> Exp[I ph]],
                "Numeric" -> ReplacePart[IdentityMatrix[n], {i, i} -> N[Exp[I ph]]]|>,
  "Label" -> Row[{"\[Phi]", i}]|>;

(* ------------------------------------------------------------------ *)
(* StagesToUnitary : fold in APPLICATION order (U = M_last ... M_1)     *)
(* ------------------------------------------------------------------ *)

stageMat[stage_, which_] := stage["Matrix", which];

StagesToUnitary[stages_List, n_Integer] := Module[{ex, nu},
  (* exact fold left symbolic (not RootReduce'd) so this stays fast for
     higher-degree fields, e.g. Q(Cos[Pi/7]); callers RootReduce at the point
     of an == comparison. The Numeric twin is always populated. *)
  ex = Fold[#2 . #1 &, IdentityMatrix[n], stageMat[#, "Exact"] & /@ stages];
  nu = Fold[#2 . #1 &, IdentityMatrix[n], stageMat[#, "Numeric"] & /@ stages];
  <|"Exact" -> ex, "Numeric" -> nu|>];

(* ------------------------------------------------------------------ *)
(* exact KCBS n-cycle cascade geometry                                 *)
(* extracted (exact version) from kcbs_circuit.wl Sec. 2-4 and         *)
(* kcbs_circuit_ncycle.wl (buildNCycleCircuit) -- N[] removed so the    *)
(* whole pipeline stays in Q(Sqrt5), per repo convention.              *)
(* ------------------------------------------------------------------ *)

frameOf[a_, b_] := {a, b, Cross[a, b]};

KCBSCascadeStages[n_Integer /; OddQ[n] && n >= 3] := KCBSCascadeStages[n] = Module[
  {c2, vecs, psi, stageFrames, Ts, sharedDetector, prepCol, P, stages, tsStages, red},
  (* canonicalize (RootReduce) only for n=5, whose field Q(Sqrt5) is degree 2
     and cheap; for higher n the field is Q(Cos[Pi/n]) (degree grows) and
     RootReduce is expensive, so keep entries symbolic-exact (still exact, N[]
     fills the numeric twin). A2's anchor is a numeric match, per DESIGN. *)
  red = If[n === 5, RootReduce, Identity];
  (* geometry (verbatim reasoning from kcbs_circuit_ncycle.wl lines 34-51) *)
  c2 = Cos[Pi/n]/(1 + Cos[Pi/n]);
  vecs = Table[{Sqrt[1 - c2] Cos[(n - 1) Pi i/n], Sqrt[1 - c2] Sin[(n - 1) Pi i/n],
      Sqrt[c2]}, {i, 0, n - 1}];
  psi = {0, 0, 1};
  stageFrames = Table[
    If[OddQ[k], frameOf[vecs[[k]], vecs[[Mod[k, n] + 1]]],
      frameOf[vecs[[Mod[k, n] + 1]], vecs[[k]]]], {k, 1, n}];
  Ts = Table[red[stageFrames[[k + 1]] . Transpose[stageFrames[[k]]]], {k, n - 1}];
  sharedDetector = Table[If[OddQ[k], 2, 1], {k, n - 1}];
  (* P-gate completion (verbatim from kcbs_circuit.wl lines 100-102) *)
  prepCol = stageFrames[[1]] . psi;
  P = red@Transpose@Select[Orthogonalize[Join[{prepCol}, IdentityMatrix[3]]],
      N[Norm[#]] > 1/2 &];
  (* each T_k is a two-level (Givens) rotation fixing sharedDetector[[k]];
     it acts on the other two modes {a,b}, a<b, as a proper 2x2 rotation. *)
  tsStages = Table[
    Module[{fixed = sharedDetector[[k]], modes, a, b, cth, sth, theta, mat},
      modes = Sort@Complement[{1, 2, 3}, {fixed}]; {a, b} = modes;
      cth = Ts[[k, a, a]]; sth = Ts[[k, b, a]];
      theta = red@ArcCos[cth];      (* canonical angle: cos = 1/GoldenRatio at n=5 *)
      mat = embed2[{{cth, -sth}, {sth, cth}}, {a, b}, 3];
      bsStage[{a, b}, theta, red[mat], "T" <> ToString[k]]], {k, n - 1}];
  stages = Prepend[tsStages, prepStage[P, "P"]];
  <|"stages" -> stages, "Ts" -> Ts, "P" -> P,
    "geometry" -> <|"vecs" -> vecs, "c2" -> c2, "stageFrames" -> stageFrames,
       "sharedDetector" -> sharedDetector|>|>];

(* --- biphoton (spin-1) u(x)u lift, n=5 only ---
   helpers extracted verbatim from pentagon-foundations/BiphotonSimulator.wl
   (Encoding B, Sec. 9 of kcbs_circuit.wl). Numeric by construction (ZYZ). *)
uzB[t_] := DiagonalMatrix[{Exp[-I t/2], Exp[I t/2]}];
uyB[t_] := {{Cos[t/2], -Sin[t/2]}, {Sin[t/2], Cos[t/2]}};
uFromSO3B[R_] := Module[{ea = EulerAngles[N[R]]}, uzB[ea[[1]]] . uyB[ea[[2]]] . uzB[ea[[3]]]];

biphotonStages[stageFramesN_] := Module[{xS, yS, zS, sS, Ddis, prep, ctx},
  xS = {-1, 0, 0, 1}/Sqrt[2.]; yS = -I {1, 0, 0, 1}/Sqrt[2.];
  zS = {0, 1, 1, 0}/Sqrt[2.]; sS = {0, 1, -1, 0}/Sqrt[2.];
  Ddis = Conjugate /@ {xS, yS, zS, sS};
  prep = {<|"Type" -> "Prep", "Modes" -> {1, 2}, "Parameter" -> None,
      "Matrix" -> <|"Exact" -> None, "Numeric" -> None|>,
      "Label" -> "X\[CenterDot]H\[CenterDot]CNOT"|>};
  ctx = Table[
    Module[{u = uFromSO3B[stageFramesN[[k]]]},
     {<|"Type" -> "BS", "Modes" -> {1}, "Parameter" -> <|"Exact" -> None, "Numeric" -> u|>,
        "Matrix" -> <|"Exact" -> None, "Numeric" -> u|>, "Label" -> Row[{"u", k}]|>,
      <|"Type" -> "BS", "Modes" -> {2}, "Parameter" -> <|"Exact" -> None, "Numeric" -> u|>,
        "Matrix" -> <|"Exact" -> None, "Numeric" -> u|>, "Label" -> Row[{"u", k}]|>}], {k, 5}];
  <|"Prep" -> prep, "ContextRotations" -> ctx,
    "Disentangler" -> <|"Type" -> "BS", "Modes" -> {1, 2}, "Parameter" -> None,
      "Matrix" -> <|"Exact" -> None, "Numeric" -> Ddis|>, "Label" -> "D"|>,
    "Flag" -> <|"Type" -> "Flag", "Modes" -> {1, 2}, "Parameter" -> None,
      "Matrix" -> <|"Exact" -> None, "Numeric" -> None|>, "Label" -> "singlet"|>|>];

(* ------------------------------------------------------------------ *)
(* CompileInterferometer -- spec form (the A1/A2 anchor path)          *)
(* ------------------------------------------------------------------ *)

CompileInterferometer[spec_Association, opts : OptionsPattern[]] := Module[
  {scenario, n, enc, casc, stages, U, framesN},
  scenario = Lookup[spec, "Scenario", Missing[]];
  enc = OptionValue["Encoding"];
  n = Which[
    scenario === "KCBS", 5,
    scenario === "Cn" || scenario === "cn", Lookup[spec, "n", 5],
    True, Return[$Failed]];
  If[! (IntegerQ[n] && OddQ[n] && n >= 3),
    Message[CompileInterferometer::badn, n]; Return[$Failed]];
  casc = KCBSCascadeStages[n];
  If[enc === "BiphotonQubit",
    If[n =!= 5, Message[CompileInterferometer::bipn]; Return[$Failed]];
    framesN = N[casc["geometry", "stageFrames"]];
    Return[<|"ModeCount" -> 2, "Encoding" -> "BiphotonQubit", "Scenario" -> scenario,
       "n" -> n, "Biphoton" -> biphotonStages[framesN], "Method" -> "Cascade"|>]];
  stages = casc["stages"];
  U = StagesToUnitary[stages, 3];
  <|"ModeCount" -> 3, "Encoding" -> "Qutrit", "Scenario" -> scenario, "n" -> n,
    "Method" -> "Cascade", "Stages" -> stages,
    "Ts" -> casc["Ts"], "Prep" -> casc["P"],
    "Unitary" -> U, "SharedDetector" -> casc["geometry", "sharedDetector"]|>];

CompileInterferometer::badn = "Scenario n = `1` must be an odd integer >= 3.";
CompileInterferometer::bipn = "BiphotonQubit encoding is spin-1 specific and supported only for n = 5.";

(* ------------------------------------------------------------------ *)
(* CompileInterferometer -- matrix form (general Reck/Clements)        *)
(* ------------------------------------------------------------------ *)

CompileInterferometer[u_?MatrixQ, opts : OptionsPattern[]] := Module[
  {n = Length[u], method, stages, recon, exactQ},
  method = OptionValue[Method];
  exactQ = TrueQ[OptionValue["Exact"]] || (OptionValue["Exact"] === Automatic && exactMatrixQ[u]);
  stages = GivensDecompose[If[exactQ, u, N[u]], method];
  recon = StagesToUnitary[stages, n];
  <|"ModeCount" -> n, "Method" -> method, "Encoding" -> "Modes",
    "Stages" -> stages,
    "Unitary" -> <|"Exact" -> If[exactQ, RootReduce[u], recon["Exact"]], "Numeric" -> N[u]|>,
    "ResidualDiagonal" -> Cases[stages, s_ /; s["Type"] === "Phase"]|>];

(* ------------------------------------------------------------------ *)
(* GivensDecompose : general two-level elimination (real or complex),  *)
(* exact when the input is algebraic.                                  *)
(*                                                                     *)
(* two-level unitary that maps {a,b} -> {r,0}:                          *)
(*   V = 1/Sqrt[|a|^2+|b|^2] {{Conj a, Conj b},{-b, a}}  (unitary)      *)
(* left-multiplying its embedding on modes {j,i} zeroes work[[i,j]].    *)
(* Reck: zero strictly-below-diagonal column by column -> diagonal D.  *)
(* ------------------------------------------------------------------ *)

zeroingBlock[a_, b_] := Module[{r = RootReduce@Sqrt[Abs[a]^2 + Abs[b]^2]},
  If[RootReduce[r] === 0, IdentityMatrix[2],
    {{Conjugate[a], Conjugate[b]}, {-b, a}}/r]];

(* recover a real rotation angle from a real 2x2 (for the "Parameter" twin) *)
angleFromBlock[v_] := If[FreeQ[v, Complex], RootReduce@ArcTan[Re@v[[1, 1]], Re@v[[2, 1]]], Missing["Complex"]];

GivensDecompose[u_?MatrixQ, method_String : "Reck"] := Module[
  {n = Length[u], work, steps = {}, diag, stages, exQ},
  exQ = exactMatrixQ[u];
  work = If[exQ, u, N[u]];
  If[method === "Clements",
    (* RIGHT elimination: for target above diagonal (i<j) zero work[[i,j]] using
       columns i and j. work -> work . G^dagger. Reduces to lower triangular. *)
    Do[Module[{ii = e[[1]], jj = e[[2]], av, bv, Vv, Gg},
       av = work[[ii, ii]]; bv = work[[ii, jj]];
       Vv = zeroingBlock[av, bv];
       Gg = embed2[Vv, {ii, jj}, n];
       work = work . ConjugateTranspose[Gg];
       AppendTo[steps, {"R", {ii, jj}, Gg}]],
     {e, Flatten[Table[{i, j}, {i, 1, n - 1}, {j, i + 1, n}], 1]}],
    (* LEFT elimination (Reck): for target below diagonal (i>j) zero work[[i,j]]
       using rows j and i. work -> G . work. Reduces to upper triangular. *)
    Do[Module[{ii = e[[1]], jj = e[[2]], av, bv, Vv, Gg},
       av = work[[jj, jj]]; bv = work[[ii, jj]];
       Vv = zeroingBlock[av, bv];
       Gg = embed2[Vv, {jj, ii}, n];
       work = Gg . work;
       AppendTo[steps, {"L", {jj, ii}, Gg}]],
     {e, Flatten[Table[{i, j}, {j, 1, n - 1}, {i, j + 1, n}], 1]}]];
  diag = If[exQ, RootReduce@Diagonal[work], Diagonal[work]];
  (* assemble APPLICATION-order stage list so StagesToUnitary == u.
     LEFT case: D = G_last...G_1 . u  =>  u = G_1^d...G_last^d . D
       application order (first applied = rightmost factor): {D, G_last^d,...,G_1^d}
     RIGHT case: D = u . G_1^d...G_last^d  (each step u<-u.G^d) => wrong; recompute:
       we did work <- work . Gg^d sequentially: D = u . G_1^d . G_2^d ... G_last^d
       => u = D . G_last . ... . G_1
       application order: {G_1, G_2, ..., G_last, D}?  fold gives M_last..M_1;
       want product = D . G_last ... G_1 (leftmost=D applied last).
       => list first->last = {G_1, ..., G_last, D}. *)
  stages = Which[
    method === "Clements",
     Append[
      MapIndexed[
       Module[{modes = #1[[2]], Gg = #1[[3]], v, th},
         v = Gg[[modes, modes]]; th = angleFromBlock[v];
         bsStage[modes, th, If[exQ, RootReduce[Gg], Gg], "R" <> ToString[#2[[1]]]]] &,
       steps],
      diagStage[diag, n, exQ]],
    True,
     Prepend[
      Reverse@MapIndexed[
       Module[{modes = #1[[2]], Gg = ConjugateTranspose[#1[[3]]], v, th},
         v = Gg[[modes, modes]]; th = angleFromBlock[v];
         bsStage[modes, th, If[exQ, RootReduce[Gg], Gg], "L" <> ToString[#2[[1]]]]] &,
       steps],
      diagStage[diag, n, exQ]]];
  stages];

diagStage[diag_, n_, exQ_] := <|
  "Type" -> "Phase", "Modes" -> Range[n], "Parameter" -> None,
  "Matrix" -> <|"Exact" -> If[exQ, RootReduce@DiagonalMatrix[diag], DiagonalMatrix[diag]],
                "Numeric" -> DiagonalMatrix[N[diag]]|>, "Label" -> "D"|>;

(* ------------------------------------------------------------------ *)
(* CompileMeshRouting                                                  *)
(* wordRingEdgesFast copied VERBATIM from                              *)
(* cluster-state-realization/cct_mesh_sparse_construction.wl (Section 1),  *)
(* the O(L) single-Table + one-Flatten construction (no Join-in-loop). *)
(* ------------------------------------------------------------------ *)

wordRingEdgesFast[word_String, reps_Integer] := Module[{w, L, edgeBlocks},
   w = Characters[StringRepeat[word, reps]];
   L = Length[w];
   edgeBlocks = Table[
     Module[{km = Mod[k - 1, L], u, v},
       {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
       {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2}, {3 k + 2, 3 k + 3}, {3 k + 3, v}}],
     {k, 0, L - 1}];
   DeleteDuplicates[Sort /@ Flatten[edgeBlocks, 1]]];

CompileMeshRouting[word_String, reps_Integer /; reps >= 1] := Module[
  {w, L, edges, blocks, routing},
  w = Characters[StringRepeat[word, reps]];
  L = Length[w];
  edges = wordRingEdgesFast[word, reps];
  (* one 3-mode Lapkiewicz block-stage per pentagon; O(L) via a single Table *)
  blocks = Table[
    <|"Type" -> "Block", "Index" -> k, "Modes" -> {3 k + 1, 3 k + 2, 3 k + 3},
      "Letter" -> w[[k + 1]], "Label" -> "P" <> ToString[k + 1]|>, {k, 0, L - 1}];
  (* routing glues block k to block k-1 on the shared pair.  The glue orientation
     INTO block k comes from the FROM-block letter w[[k]] (block k-1's letter):
     wordRingEdgesFast swaps the glue pair {u,v} on block km = k-1 iff
     w[[km+1]] = w[[k]] is not "c", so cis iff w[[k]] === "c". *)
  routing = Table[
    <|"From" -> k - 1, "To" -> k, "SharedModes" -> {3 (k - 1) + 1, 3 (k - 1) + 2},
      "Orientation" -> If[w[[k]] === "c", "cis", "trans"]|>, {k, 1, L - 1}];
  <|"Word" -> word, "Reps" -> reps, "L" -> L, "ModeCount" -> 3 L,
    "Blocks" -> blocks, "Routing" -> routing, "EdgeList" -> edges|>];

End[];
EndPackage[];
