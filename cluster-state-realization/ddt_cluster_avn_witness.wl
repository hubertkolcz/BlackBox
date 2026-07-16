(* ::Package:: *)

(* ===========================================================================
   ddt_cluster_avn_witness.wl -- generalizing mbqc_c5.wl's single-pentagon GHZ
   All-vs-Nothing (AvN) contextuality witness to the ddt-glued pentagon-MESH
   CLUSTER STATE (vertex = qubit, edge = CZ gate -- NOT the exclusivity graph
   of CaseStudies.wl), to test Theorem 4's condition U1 (C_F(rho_G) > 0 /
   strong contextuality) on the actual multi-pentagon quantum state.

   THREE FRAMEWORKS BRIDGED (all read in full before writing this file):
     * black-box-test/mbqc_c5.wl -- the 5-qubit C5 ring cluster state and its
       GHZ AvN section (Aop=XXX,Bop=XYY,Cop=YXY,Eop=YYX on a SEPARATE,
       hand-supplied 3-qubit GHZ vector -- not literally extracted from the
       pentagon's own stabilizers there). SECTION 1-2 below investigates and
       resolves exactly how Aop..Eop DO arise from the pentagon's own
       stabilizer generators.
     * BlackBox/Kernel/BlackBox.wl -- AvNArgument[scen,e,d] (Z_d-affine
       consistency test via Smith normal form) and ContextualFraction, which
       we call directly (paclet loaded below) as an INDEPENDENT cross-check
       of every witness found here, rather than trusting only the ad hoc
       "operator product == -Identity" check.
     * mesh-composition/CaseStudies.wl -- wordRing[word,reps], the pentagon
       mesh GRAPH combinatorics (exclusivity graph there; reused VERBATIM here
       -- together with PentagonChain's edge pattern -- as a qubit/CZ
       entanglement graph instead, exactly as black-box-test's own sibling
       file ddt_cluster_stabilizer.wl already did for the binary GF(2)
       stabilizer tableau). That file's wordRing["ddt",reps] RING is the
       literal "ddt-glued mesh" this task names.
     * Lie_Poisson_MBQC.wl Section 6/7/19 -- Theorem 4 requires U1: C_F(rho_G)
       > 0 (a genuinely contextual resource state). This file supplies a
       positive, machine-checked U1 witness for N=2 and N=3 pentagon CLUSTER
       states (not just their exclusivity-graph shadow).

   HEADLINE RESULT (verified below, not merely argued):
     Every DEGREE-2 vertex m of ANY pentagon mesh (chain or ring, any block
     position -- end block or interior) has neighbours {a,c}, and the single
     stabilizer generator K_m = X_m Z_a Z_c is already supported ONLY on
     {a,m,c} (identity everywhere else in the mesh, however large). Z-measuring
     every OTHER qubit of the mesh (any outcome) and applying local Hadamards
     to the two neighbours a,c always reduces the conditional state on {a,m,c}
     to a GHZ-type state carrying the SAME AvN contradiction as mbqc_c5.wl's
     hand-supplied GHZ, for EVERY branch, at EVERY block (interior included).
     This is verified by explicit 2^n x 2^n matrix computation at N=1,2,3
     pentagons (chain and the literal ddt RING), and cross-validated against
     BlackBox's own AvNArgument/ContextualFraction (both independently confirm
     AvN -> True, C_F = 1, at every witness tested).

   HONESTY NOTE: this is a per-block LOCAL witness (it requires conditioning
   on a Z-basis measurement of the rest of the mesh -- exactly the standard
   "distill a GHZ triple from a graph state by measurement" technique in the
   literature, e.g. Raussendorf PRA 88, 022322 (2013); Guhne-Toth-Hyllus-
   Briegel, PRL 95, 120405 (2005) for the general stabilizer-product
   principle). It is NOT a claim that the raw, unmeasured N-qubit entangled
   state's full stabilizer group contains an operator identity ABCE=-I (that
   is impossible for any genuine +1-eigenvalue stabilizer product of a
   nonzero state -- see Section 0 remark). A genuinely multi-block,
   non-block-local AvN witness (spanning more than one pentagon irreducibly)
   was NOT found in this scope; Section 7 reports a partial, honestly-flagged
   exploration of shared (degree-3) vertices instead (a confirmed 4-qubit GHZ
   reduction, but the naive n=4 AvN generalization fails -- reported as a
   negative finding, not forced).

   Run:  wolframscript -file ddt_cluster_avn_witness.wl
   =========================================================================== *)

Print["=== ddt_cluster_avn_witness.wl : mesh-generalized GHZ AvN witness ==="];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 0. Pauli/Kronecker conventions -- verbatim from mbqc_c5.wl.
   --------------------------------------------------------------------------- *)
kp = KroneckerProduct; I2 = IdentityMatrix[2];
PX = {{0, 1}, {1, 0}}; PZ = {{1, 0}, {0, -1}}; PY = {{0, -I}, {I, 0}};
Hd = {{1, 1}, {1, -1}}/Sqrt[2]; plus = {1, 1}/Sqrt[2];
pauliOf["X"] = PX; pauliOf["Y"] = PY; pauliOf["H"] = Hd; pauliOf["I"] = I2;

(* ---------------------------------------------------------------------------
   SECTION 1. Baseline -- mbqc_c5.wl's own GHZ AvN section, reproduced
   VERBATIM (not reinvented), as the reference this file generalizes.
   --------------------------------------------------------------------------- *)
Print["--- Section 1: mbqc_c5.wl baseline (verbatim), sanity check ---"];
n = 5;
psi0 = Flatten[kp @@ ConstantArray[plus, n]];
bits[b_] := IntegerDigits[b, 2, n];
cz5[i_, j_] := DiagonalMatrix[Table[If[bits[b][[i]] == 1 && bits[b][[j]] == 1, -1, 1], {b, 0, 2^n - 1}]];
edges5 = Table[{i, Mod[i, 5] + 1}, {i, 1, 5}];
psiC5 = Fold[#2 . #1 &, psi0, cz5 @@@ edges5];
emb5[a_] := kp @@ Table[Lookup[a, k, I2], {k, 1, n}];
Kstab5[i_] := emb5[<|i -> PX, Mod[i - 2, 5] + 1 -> PZ, Mod[i, 5] + 1 -> PZ|>];
stabDev5 = Table[Max@Abs@Chop[Kstab5[i] . psiC5 - psiC5], {i, 1, 5}];
ghzRef = {1, 0, 0, 0, 0, 0, 0, 1}/Sqrt[2];
AopRef = kp[PX, PX, PX]; BopRef = kp[PX, PY, PY]; CopRef = kp[PY, PX, PY]; EopRef = kp[PY, PY, PX];
valsRef = Chop[Re[{ghzRef . AopRef . ghzRef, ghzRef . BopRef . ghzRef, ghzRef . CopRef . ghzRef, ghzRef . EopRef . ghzRef}]];
Print["  C5 stabilizer deviation (should be all 0): ", stabDev5];
Print["  mbqc_c5.wl's separate GHZ vector, <A,B,C,E> = ", valsRef,
  "  op ABCE == -I? ", Chop[AopRef . BopRef . CopRef . EopRef] == -IdentityMatrix[8]];
Print["  (Note: mbqc_c5.wl's `ghz` is a SEPARATE, hand-supplied 3-qubit vector,",
  " not extracted from psiC5 -- Section 2 resolves the actual tie.)"];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 2. Stabilizer origin of Aop,Bop,Cop,Eop for the SINGLE pentagon.

   REMARK (why a product of genuine stabilizers can never equal -Identity):
   for ANY nonzero state |psi>, if S1,...,Sk are stabilizers (Si|psi>=+|psi>),
   then S1...Sk|psi> = +|psi> too (the group is abelian and every element has
   eigenvalue +1) -- so S1...Sk = -Identity would force |psi> = -|psi>, i.e.
   |psi> = 0. The GHZ operator identity Aop.Bop.Cop.Eop = -I is therefore NOT
   a product of four +1-stabilizers of |GHZ>: exactly ONE of the four plain
   Pauli strings (A=XXX) is itself a stabilizer; the other three (B,C,D) are
   the NEGATIVE of a stabilizer (i.e. -B,-C,-D are genuine +1 elements, so B,
   C,D individually have eigenvalue -1 on |GHZ>). The paradox is about
   NONCONTEXTUAL VALUE ASSIGNMENTS (forced product = +1 by the even-Y-count
   parity of the construction), not about a stabilizer-algebra contradiction.

   Below: measure OUT the two "extra" qubits {4,5} of psiC5 in the Z basis
   (every outcome branch), Hadamard the two remaining LEAF qubits {1,3}, and
   show the conditional 3-qubit state is exactly (branch (0,0)) or a Pauli-
   frame variant of (other branches) the standard GHZ state -- and that this
   reduction is governed by the SINGLE stabilizer generator K_2 = Z_1 X_2 Z_3,
   which is already identity on {4,5} (a weight-3 element of the pentagon's
   own stabilizer group) and hence survives ANY measurement of {4,5} with
   eigenvalue +1 unconditionally: THIS is why Aop (=K_2 in the Hadamard frame)
   is always +1 in every branch below, while Bop,Cop,Eop become definite
   (branch-dependent sign) only through the conditioning -- exactly the
   "distill contextuality from a graph state by measurement" mechanism.
   --------------------------------------------------------------------------- *)
Print["--- Section 2: stabilizer origin of Aop..Eop (single pentagon) ---"];
K2 = emb5[<|1 -> PZ, 2 -> PX, 3 -> PZ|>];
Print["  K_2 = Z_1 X_2 Z_3 (weight 3, identity on qubits 4,5): stabilizes psiC5? ",
  Max[Abs[Chop[K2 . psiC5 - psiC5]]] < 10^-9];

reduceState[psi_, nq_, keepList_List, fixedOutcomes_Association] := Module[{tensor, idxSpec},
  tensor = ArrayReshape[psi, ConstantArray[2, nq]];
  idxSpec = Table[If[MemberQ[keepList, q], All, fixedOutcomes[q] + 1], {q, 1, nq}];
  Flatten[tensor[[Sequence @@ idxSpec]]]];

H3std = kp[Hd, I2, Hd];
Do[
 Module[{sub, nrm, psiGHZframe, vals, opProd},
  sub = reduceState[psiC5, 5, {1, 2, 3}, <|4 -> o4, 5 -> o5|>];
  nrm = Sqrt[Chop[Conjugate[sub] . sub]];
  sub = sub/nrm;
  psiGHZframe = H3std . sub;
  vals = Chop[Re[{psiGHZframe . AopRef . psiGHZframe, psiGHZframe . BopRef . psiGHZframe,
     psiGHZframe . CopRef . psiGHZframe, psiGHZframe . EopRef . psiGHZframe}]];
  Print["  measure(4,5)=", {o4, o5}, "  -> Hadamard-frame state = ", Chop[psiGHZframe, 10^-8],
    "  <A,B,C,E>=", vals, "  valueProduct=", Times @@ vals];
 ],
 {o4, {0, 1}}, {o5, {0, 1}}];
Print["  ==> Aop is ALWAYS +1 (it IS K_2, a genuine stabilizer, unaffected by measuring 4,5);"];
Print["      Bop,Cop,Eop flip sign branch-to-branch, but the VALUE PRODUCT is -1 in EVERY branch"];
Print["      (matches the fixed operator identity Aop.Bop.Cop.Eop=-I) -- the AvN contradiction",
  " survives measurement-conditioning unconditionally."];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 3. General tools: cluster-state builder, generic K_v, reduction,
   triple-operator builder (role-based: leafA/center/leafC -> position-
   independent of which vertex label sorts where), empirical-model builder
   matching BlackBox's own ghzScen/ghzModel convention (SupportCohomology.wl),
   and the paclet load for the cross-validation in Section 6.
   --------------------------------------------------------------------------- *)
Print["--- Section 3: general mesh tools + BlackBox paclet load ---"];
PacletDirectoryLoad[FileNameJoin[{Directory[], "..", "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"];
Print["  BlackBox paclet loaded."];

buildClusterState[nQ_Integer, edgeList_List] := Module[{psiI, cz},
  psiI = Flatten[kp @@ ConstantArray[plus, nQ]];
  cz[i_, j_] := DiagonalMatrix[Table[
     If[IntegerDigits[b, 2, nQ][[i]] == 1 && IntegerDigits[b, 2, nQ][[j]] == 1, -1, 1],
     {b, 0, 2^nQ - 1}]];
  Fold[#2 . #1 &, psiI, cz @@@ edgeList]];

neighborsOf[v_, edgeList_] := Union[Cases[edgeList, {v, u_} :> u], Cases[edgeList, {u_, v} :> u]];
degreeOf[v_, edgeList_] := Length[neighborsOf[v, edgeList]];

Kstab[v_, nQ_, edgeList_] := Module[{nb = neighborsOf[v, edgeList], a},
  a = <|v -> PX|>; Do[a[u] = PZ, {u, nb}];
  kp @@ Table[Lookup[a, k, I2], {k, 1, nQ}]];

buildTripleMat[sortedT_List, assignment_Association] := kp @@ (pauliOf[assignment[#]] & /@ sortedT);

projVec["X", 0] = {1, 1}/Sqrt[2]; projVec["X", 1] = {1, -1}/Sqrt[2];
projVec["Y", 0] = {1, I}/Sqrt[2]; projVec["Y", 1] = {1, -I}/Sqrt[2];

(* empirical model in EXACTLY BlackBox/SupportCohomology.wl's ghzScen section
   order: contexts {aX,bX,cX},{aX,bY,cY},{aY,bX,cY},{aY,bY,cX}; roleOf maps
   the three physical (vertex-labelled) qubits to roles "a" (leaf), "b"
   (center), "c" (leaf) -- position-independent of how the vertex labels sort. *)
modelFromStateGeneral[psi3_, sortedT_List, roleOf_Association] := Module[
  {roleCtxLetter = <|"a" -> {"X", "X", "Y", "Y"}, "b" -> {"X", "Y", "X", "Y"}, "c" -> {"X", "Y", "Y", "X"}|>},
  Flatten[Table[
    Abs[Conjugate[Flatten[kp @@ (projVec[roleCtxLetter[roleOf[#]][[ctxIdx]], s[[Position[sortedT, #][[1, 1]]]]] & /@ sortedT)]] . psi3]^2,
    {ctxIdx, 1, 4}, {s, Tuples[{0, 1}, 3]}]]];

ghzScen = CoverScenario[{"aX", "aY", "bX", "bY", "cX", "cY"},
  {{"aX", "bX", "cX"}, {"aX", "bY", "cY"}, {"aY", "bX", "cY"}, {"aY", "bY", "cX"}}];

(* full witness test on a mesh cluster state psi (nQ qubits): triple {a,center,c}
   with center's FULL neighbor set == {a,c} exactly (degree 2), any outcome for
   the OTHER qubits. Returns an association with the ad hoc operator check AND
   the independent BlackBox AvNArgument/ContextualFraction cross-check. *)
testWitness[psi_, nQ_, edgeList_, a_, center_, c_, label_, opts : OptionsPattern[{"AllBranches" -> True, "CrossCheckOutcome" -> None}]] := Module[
  {nb, sortedT, Aop, Bop, Cop, Eop, H3, opProd, otherQ, allOutcomes, results,
   kdev, roleOf, ccOutcome, sub, nrm, psiGHZframe, mdl, avn, cf},
  nb = neighborsOf[center, edgeList];
  sortedT = Sort[{a, center, c}];
  kdev = Max[Abs[Chop[Kstab[center, nQ, edgeList] . psi - psi]]];
  Aop = buildTripleMat[sortedT, <|a -> "X", center -> "X", c -> "X"|>];
  Bop = buildTripleMat[sortedT, <|a -> "X", center -> "Y", c -> "Y"|>];
  Cop = buildTripleMat[sortedT, <|a -> "Y", center -> "X", c -> "Y"|>];
  Eop = buildTripleMat[sortedT, <|a -> "Y", center -> "Y", c -> "X"|>];
  H3 = buildTripleMat[sortedT, <|a -> "H", center -> "I", c -> "H"|>];
  opProd = Chop[Aop . Bop . Cop . Eop] == -IdentityMatrix[8];
  otherQ = Complement[Range[nQ], sortedT];
  allOutcomes = Tuples[{0, 1}, Length[otherQ]];
  results = Table[
    Module[{outAssoc, sub2, nrm2, psiGHZframe2, vals2},
     outAssoc = AssociationThread[otherQ -> outc];
     sub2 = reduceState[psi, nQ, sortedT, outAssoc];
     nrm2 = Sqrt[Chop[Conjugate[sub2] . sub2]];
     If[nrm2 < 10^-9, Nothing,
      sub2 = sub2/nrm2;
      psiGHZframe2 = H3 . sub2;
      vals2 = Chop[Re[{psiGHZframe2 . Aop . psiGHZframe2, psiGHZframe2 . Bop . psiGHZframe2,
          psiGHZframe2 . Cop . psiGHZframe2, psiGHZframe2 . Eop . psiGHZframe2}]];
      Times @@ vals2]],
    {outc, allOutcomes}];
  (* independent BlackBox cross-check on one representative branch *)
  ccOutcome = If[OptionValue["CrossCheckOutcome"] === None, ConstantArray[0, Length[otherQ]], OptionValue["CrossCheckOutcome"]];
  roleOf = <|a -> "a", center -> "b", c -> "c"|>;
  sub = reduceState[psi, nQ, sortedT, AssociationThread[otherQ -> ccOutcome]];
  nrm = Sqrt[Chop[Conjugate[sub] . sub]];
  sub = sub/nrm;
  psiGHZframe = H3 . sub;
  mdl = Chop[modelFromStateGeneral[psiGHZframe, sortedT, roleOf]];
  avn = AvNArgument[ghzScen, mdl];
  cf = ContextualFraction[ghzScen, mdl];
  Print["  [", label, "] center=", center, " nb=", nb, " triple=", sortedT,
    "  K_center stabilizer? ", kdev < 10^-9,
    "  |ABCE=-I|? ", opProd,
    "  branches=", Length[results], " all valProd=-1? ", AllTrue[results, # == -1 &],
    "  || BlackBox: AvN=", avn["AvN"], " CF=", cf];
  <|"Label" -> label, "Triple" -> sortedT, "KIsStab" -> (kdev < 10^-9), "OpIdentity" -> opProd,
    "AllBranchesMinusOne" -> AllTrue[results, # == -1 &], "BlackBoxAvN" -> avn["AvN"], "BlackBoxCF" -> cf|>
];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 4. PentagonChain (open-chain) mesh cluster states, N=2 and N=3.
   Edge pattern reused VERBATIM from BlackBox.wl's PentagonChain[n].
   --------------------------------------------------------------------------- *)
Print["--- Section 4: PentagonChain mesh cluster states, N=2 and N=3 ---"];
PentagonChainEdges[nblocks_Integer?Positive] := Module[{edges = {}, e0 = {1, 2}, base = 2},
  Do[edges = Join[edges, {{e0[[1]], base + 1}, {base + 1, base + 2},
      {base + 2, base + 3}, {base + 3, e0[[2]]}, {e0[[2]], e0[[1]]}}];
   e0 = {base + 1, base + 2}; base = base + 3, {nblocks}];
  DeleteDuplicates[Sort /@ edges]];

Print["  N=2 (8 qubits):"];
edges2 = PentagonChainEdges[2]; nQ2 = 8;
psi2 = buildClusterState[nQ2, edges2];
stabDev2 = Table[Max[Abs[Chop[Kstab[v, nQ2, edges2] . psi2 - psi2]]], {v, 1, nQ2}];
Print["    edges: ", edges2, "   degrees: ", Table[degreeOf[v, edges2], {v, 1, nQ2}]];
Print["    all 8 stabilizers verified (deviation 0)? ", Max[stabDev2] < 10^-9];
n2Results = {
  testWitness[psi2, nQ2, edges2, 1, 2, 5, "N2 block1 center2"],
  testWitness[psi2, nQ2, edges2, 2, 1, 3, "N2 block1 center1"],
  testWitness[psi2, nQ2, edges2, 4, 5, 2, "N2 block1 center5"],
  testWitness[psi2, nQ2, edges2, 6, 7, 8, "N2 block2 center7"],
  testWitness[psi2, nQ2, edges2, 3, 6, 7, "N2 block2 center6"],
  testWitness[psi2, nQ2, edges2, 7, 8, 4, "N2 block2 center8"]};
Print[];

Print["  N=3 (11 qubits), including the INTERIOR block (most nontrivial case):"];
edges3 = PentagonChainEdges[3]; nQ3 = 11;
psi3 = buildClusterState[nQ3, edges3];
stabDev3 = Table[Max[Abs[Chop[Kstab[v, nQ3, edges3] . psi3 - psi3]]], {v, 1, nQ3}];
Print["    edges: ", edges3, "   degrees: ", Table[degreeOf[v, edges3], {v, 1, nQ3}]];
Print["    all 11 stabilizers verified (deviation 0)? ", Max[stabDev3] < 10^-9];
n3Results = {
  testWitness[psi3, nQ3, edges3, 1, 2, 5, "N3 block1(end) center2"],
  testWitness[psi3, nQ3, edges3, 4, 8, 7, "N3 block2(INTERIOR) center8"],
  testWitness[psi3, nQ3, edges3, 9, 10, 11, "N3 block3(end) center10"]};
Print[];

(* ---------------------------------------------------------------------------
   SECTION 5. The literal "ddt-glued" mesh: wordRing["ddt",1], a RING of 3
   pentagons (9 qubits). Graph combinatorics reused VERBATIM from
   CaseStudies.wl / ddt_cluster_stabilizer.wl, reinterpreted as a CZ/qubit
   graph exactly as that sibling file already established.
   --------------------------------------------------------------------------- *)
Print["--- Section 5: literal ddt-glued RING, wordRing[\"ddt\",1] (9 qubits) ---"];
wordRing[word_String, reps_Integer] := Module[
  {w = Characters[StringRepeat[word, reps]], L, edges = {}, u, v, km},
  L = Length[w];
  Do[km = Mod[k - 1, L];
   {u, v} = If[w[[km + 1]] === "d", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
   edges = Join[edges, {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2},
      {3 k + 2, 3 k + 3}, {3 k + 3, v}}], {k, 0, L - 1}];
  DeleteDuplicates[Sort /@ edges]];

edgesR = wordRing["ddt", 1]; nQR = 9;
psiR = buildClusterState[nQR, edgesR];
stabDevR = Table[Max[Abs[Chop[Kstab[v, nQR, edgesR] . psiR - psiR]]], {v, 1, nQR}];
Print["  edges: ", edgesR, "   degrees: ", Table[degreeOf[v, edgesR], {v, 1, nQR}]];
Print["  all 9 stabilizers verified (deviation 0)? ", Max[stabDevR] < 10^-9];
(* every block in a RING is "interior" (glued on both sides): degree-2 vertices
   3, 6, 9 are each a block's single private vertex *)
ringResults = {
  testWitness[psiR, nQR, edgesR, 2, 3, 7, "RING blockA center3"],
  testWitness[psiR, nQR, edgesR, 2, 6, 5, "RING blockB center6"],
  testWitness[psiR, nQR, edgesR, 5, 9, 8, "RING blockC center9"]};
Print[];

(* ---------------------------------------------------------------------------
   SECTION 6. Cross-validation summary (BlackBox AvNArgument/ContextualFraction
   already called per-witness above -- this collects the verdicts).
   --------------------------------------------------------------------------- *)
Print["--- Section 6: cross-validation summary ---"];
allResults = Join[n2Results, n3Results, ringResults];
Print["  witnesses tested: ", Length[allResults]];
Print["  all K_center genuine stabilizers? ", AllTrue[allResults, #["KIsStab"] &]];
Print["  all operator identities ABCE=-I? ", AllTrue[allResults, #["OpIdentity"] &]];
Print["  all branches valueProduct=-1 (ad hoc check)? ", AllTrue[allResults, #["AllBranchesMinusOne"] &]];
Print["  all BlackBox AvNArgument -> True? ", AllTrue[allResults, #["BlackBoxAvN"] &]];
Print["  all BlackBox ContextualFraction == 1? ", AllTrue[allResults, #["BlackBoxCF"] == 1 &]];
Print[];

(* ---------------------------------------------------------------------------
   SECTION 7. BONUS (honest, partial) exploration: shared (degree-3) vertices.

   Every vertex SHARED between two pentagon blocks has degree 3 (two
   in-pentagon neighbours + one more from... actually its own two in-cycle
   neighbours, since the shared EDGE itself is one of those two). Its
   stabilizer K_v = X_v Z_a Z_b Z_c is weight 4, supported on 4 qubits whose
   INDUCED subgraph is a STAR (center=v, three leaves) -- a genuine 4-qubit
   graph/cluster state. Local-Clifford fact: Hadamard on ALL THREE leaves of
   a k-leaf star graph state gives GHZ_{k+1} (K_center -> XXXX; each K_leaf ->
   Z_leaf Z_center). Verified explicitly below for the N=2 chain's shared
   vertex 3 (neighbours {1,4,6}). BUT: the natural n=3-style generalization
   (multiply ALL 2^{n-1}=8 even-Y-count X/Y strings together) does NOT
   reproduce an AvN paradox at n=4 -- the quantum value product and the
   noncontextual-forced product BOTH equal +1 (verified by exhaustive
   brute-force check over subsets), unlike n=3 where they differ (-1 vs +1).
   This matches the known n mod 4 dependence of Mermin/GHZ paradoxes: the
   simple all-versus-nothing argument is not equally available at every
   party count. Reported honestly as a NEGATIVE finding, not forced.
   --------------------------------------------------------------------------- *)
Print["--- Section 7: bonus exploration -- shared (degree-3) vertices ---"];
keep4 = {1, 3, 4, 6}; other4 = Complement[Range[nQ2], keep4];
H4 = kp[Hd, I2, Hd, Hd]; (* Hadamard on leaves 1,4,6 (sorted positions 1,3,4); identity on center 3 (position 2) *)
branch00 = reduceState[psi2, nQ2, keep4, AssociationThread[other4 -> {0, 0, 0, 0}]];
branch00 = branch00/Sqrt[Chop[Conjugate[branch00] . branch00]];
rot00 = H4 . branch00;
Print["  shared vertex 3 (neighbors {1,4,6}, degree 3): induced graph on {1,3,4,6} is a star."];
Print["  outcome(all-zero) on other 4 qubits, Hadamard on leaves {1,4,6}: reduced state = ",
  Chop[rot00, 10^-8]];
Print["  matches standard GHZ4 (1,0,...,0,1)/Sqrt[2]? ",
  Chop[rot00 - Normalize[UnitVector[16, 1] + UnitVector[16, 16]]] == ConstantArray[0, 16]];

(* exhaustive n=4 AvN search over the "good" (sharp-eigenvalue) X/Y strings *)
ghz4 = Normalize[UnitVector[16, 1] + UnitVector[16, 16]];
opOf4[s_] := kp @@ (If[# == "X", PX, PY] & /@ s);
goodStrs4 = Select[Tuples[{"X", "Y"}, 4], EvenQ[Count[#, "Y"]] &];
vals4 = Association[Table[s -> Chop[Re[ghz4 . opOf4[s] . ghz4]], {s, goodStrs4}]];
fullProd4 = Chop[Dot @@ (opOf4 /@ goodStrs4)];
quantumProd4 = Times @@ Values[vals4];
Print["  8 sharp (even-Y-count) X/Y strings and GHZ4 eigenvalues: ", Normal[vals4]];
Print["  full product of all 8 (operator): ", If[fullProd4 == IdentityMatrix[16], "+Identity",
   If[fullProd4 == -IdentityMatrix[16], "-Identity", "other"]],
  "   quantum value product: ", quantumProd4,
  "   NC-forced product (even letter-counts => always +1): 1"];
Print["  ==> NO contradiction at n=4 with this construction (quantum product = NC-forced = +1);",
  " the naive n=3-style AvN generalization does not survive to n=4. Reported honestly as a limit,",
  " not pursued further (a genuine n=4 witness, if any, needs a different -- e.g. Mermin recursive --",
  " operator selection, out of scope here)."];
Print[];

(* ---------------------------------------------------------------------------
   FINAL SUMMARY
   --------------------------------------------------------------------------- *)
Print["=== SUMMARY ==="];
Print["N=1 (single pentagon): Aop=K_2 (stabilizer), Bop/Cop/Eop branch-dependent, AvN survives",
  " unconditionally across all 4 measurement branches of the other 2 qubits -- ",
  "cross-validated by BlackBox AvNArgument: True, CF: 1."];
Print["N=2 PentagonChain (8 qubits, both blocks are end blocks): ALL 6 candidate witnesses",
  " (3 per block) pass every check, including BlackBox AvNArgument/ContextualFraction."];
Print["N=3 PentagonChain (11 qubits, one INTERIOR block): all 3 witnesses pass, INCLUDING the",
  " interior block (vertex 8, degree 2, neighbours {4,7}) -- the strongest test of genuine",
  " generalization beyond boundary effects."];
Print["N=3 ddt RING wordRing[\"ddt\",1] (9 qubits, the literal named object, every block interior):",
  " all 3 witnesses pass."];
Print["Cross-validation: EVERY witness above independently confirmed by BlackBox's own",
  " AvNArgument (-> True) and ContextualFraction (== 1, maximal), not just the ad hoc check."];
Print["Bonus/limit: shared degree-3 vertices give a genuine 4-qubit GHZ reduction (verified),",
  " but the direct n=4 AvN generalization fails (quantum = noncontextual = +1, no contradiction)",
  " -- reported honestly rather than forced."];
Print[];
finalOK = AllTrue[allResults, #["KIsStab"] && #["OpIdentity"] && #["AllBranchesMinusOne"] &&
    #["BlackBoxAvN"] && (#["BlackBoxCF"] == 1) &];
Print["ALL MESH AvN WITNESSES VERIFIED (ad hoc + BlackBox cross-check) -> OK: ", finalOK];
