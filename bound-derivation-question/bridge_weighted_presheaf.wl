(* ::Package:: *)

(* bridge_weighted_presheaf.wl --- ESSAY-005 Formalizer A: the WEIGHTED-PRESHEAF
   INVARIANT for S_k, with the degree-0 capacity Lambda_k and the C-A1 H^1
   partition-defect test.

   Parent: bound-derivation-question/ESSAY-005-problem-spec.md (P3 reduction), and
   the P3 certificate run essay005_p3_gluing_lp.wl -> p3_certificates.json (all
   Trap-1 gates PASS). This module re-derives the SAME LP values but frames them
   as Formalizer A's invariant so the claim is stated and validated as an
   invariant, not just an LP value.

   ---------------------------------------------------------------------------
   THE PRESHEAF F (effect-module presheaf over R = Q>=0, NOT a Z-module).
     Objects: maximal cliques K of the conormal power G^vk (the contexts).
     F(K) = { w : K -> [0,1] with Sum_{v in K} w(v) <= 1 }  (subnormalized
            weightings = an effect module / [0,1]-semimodule of sections).
     Restriction rho^K_A(w) = w|_A  (coordinate projection).
   Sections are point-functions, so F GLUES TRIVIALLY: a compatible family is a
   single global p : V_k -> [0,1] with the clique constraints, i.e.
     H^0(F) = PACKING POLYTOPE  P_k = { p : V_k->[0,1] : Sum_{v in K} p_v <= 1
                                        for every maximal clique K }.
   (P1 proved the *support* (Z-module) presheaf is BLIND to S_k; the invariant
   must live on THIS [0,1]-semimodule presheaf. That is why F is over Q>=0.)

   ---------------------------------------------------------------------------
   PRIMARY INVARIANT (NEW, checkable):
     Lambda_k := sup_{p in H^0(F)} mu(p),   mu(p) = Sum_v p_v   (total-mass hom).
   Claim A:  Lambda_k = L_k  (the exclusivity/packing LP value)  and
             per-copy  S_k = Lambda_k^{1/k}.
   By LP duality Lambda_k = min fractional clique cover = a Q>=0-valued Cech
   0-cochain y* (a partition-of-unity softened to coverage >= 1).

   MANDATORY GATES (exact; = the four task anchors + discriminators):
     Lambda_1(C5) = 5/2                       -> S_1(C5) = 5/2
     Lambda_2(C5) = 5   (per-copy Sqrt[5])    -> S_2(C5) = Sqrt[5]   (irrational)
     Lambda_2(C7) = 49/4 (per-copy 7/2)       -> S_2(C7) = 7/2   (NOT theta(C7)^2)
     Lambda_3(C7) = 343/8 (per-copy 7/2)      -> S_3(C7) = 7/2   (control holds)

   ---------------------------------------------------------------------------
   CONJECTURE C-A1 (flagged conjecture, NOT proven here). A semimodule/tropical
   H^1 of the clique-colouring co-presheaf vanishes iff the LP optimum is an
   EXACT partition of unity. Computable REALIZATION tested here (the "partition
   defect"): the optimal dual 0-cochain y* is an exact integer partition of the
   events (weight-1 disjoint cliques covering V exactly once) IFF Lambda_k is an
   integer that equals such a partition's size. We compute the defect exactly:
     H^1-proxy = 0  <=>  Lambda_k in Z AND an exact clique-partition of V of
                         value Lambda_k exists.
   Prediction: 0 only at (C5, k=2) among the anchors; nonzero at (C5,k=1),
   (C7,k=1), (C7,k=2), (C7,k=3) (fractional covers 5/2, 7/2, 49/4, 343/8).
   This REFINES the integrality gap WITHOUT moving Lambda_k off its anchors.
   Explicitly flagged: S_k is DEGREE-0 (the capacity Lambda_k), NOT an
   H^1/torsion class; the H^1 story is a strictly finer, secondary invariant.

   Run:  wolframscript -file bridge_weighted_presheaf.wl   (~3-6 min, 1 kernel)
   Output: bridge_weighted_presheaf.json + printed gate table ending OK -> True.
*)

$HistoryLength = 0;
startT = AbsoluteTime[];
Print["bridge_weighted_presheaf.wl start ", DateString[]];
scriptDir = DirectoryName[ExpandFileName[$InputFileName]];

(* ------------------------------------------------------------------ *)
(* conormal power objects (verbatim from essay005_p3_gluing_lp.wl)     *)
(* ------------------------------------------------------------------ *)

conormalVerts[n_, k_] := Tuples[Range[0, n - 1], k];
adjQ[n_][u_, v_] := AnyTrue[Range[Length[u]],
   MemberQ[{1, n - 1}, Mod[u[[#]] - v[[#]], n]] &];
conormalGraph[n_, k_] := Module[{vs = conormalVerts[n, k], m, edges},
   m = Length[vs];
   edges = Reap[
      Do[If[adjQ[n][vs[[a]], vs[[b]]], Sow[UndirectedEdge[a, b]]],
        {a, 1, m}, {b, a + 1, m}]][[2]];
   edges = If[edges === {}, {}, edges[[1]]];
   {Graph[Range[m], edges], vs, AssociationThread[vs -> Range[m]]}];
cliqueQ[n_][verts_] := AllTrue[Subsets[verts, {2}], adjQ[n][#[[1]], #[[2]]] &];

(* ------------------------------------------------------------------ *)
(* H^0(F): the packing polytope, and Lambda_k = total-mass hom over it *)
(* Exact rational simplex; FLAT variable list (project pitfall).       *)
(* ------------------------------------------------------------------ *)

(* Lambda_k = sup mu(p) over H^0(F): the degree-0 capacity. *)
capacityLP[cliqueIdxLists_, nV_] := Module[{p, vars, cons, sol},
   vars = Array[p, nV];
   cons = Join[Table[Total[vars[[K]]] <= 1, {K, cliqueIdxLists}], Thread[vars >= 0]];
   sol = LinearOptimization[-Total[vars], cons, vars, Method -> "Simplex"];
   <|"value" -> (Total[vars] /. sol), "p" -> (vars /. sol)|>];

(* dual: the Cech 0-cochain y* = min fractional clique cover, coverage >= 1. *)
coverLP[cliqueIdxLists_, nV_] := Module[{y, vars, containing, cons, sol},
   vars = Array[y, Length[cliqueIdxLists]];
   containing = GroupBy[
      Flatten[MapIndexed[Thread[#1 -> #2[[1]]] &, cliqueIdxLists]], First -> Last];
   cons = Join[Table[Total[vars[[containing[v]]]] >= 1, {v, nV}], Thread[vars >= 0]];
   sol = LinearOptimization[Total[vars], cons, vars, Method -> "Simplex"];
   <|"value" -> (Total[vars] /. sol), "y" -> (vars /. sol)|>];

(* exact dual 0-cochain verifier for the k=3 certificate sandwich (no census). *)
verifyDualCochain[n_, k_, cliqueVertLists_, yw_] := Module[
   {vs = conormalVerts[n, k], idx, cov},
   idx = AssociationThread[vs -> Range[Length[vs]]];
   cov = ConstantArray[0, Length[vs]];
   Do[Do[cov[[idx[v]]] += yw, {v, K}], {K, cliqueVertLists}];
   <|"allCliques" -> AllTrue[cliqueVertLists, cliqueQ[n]],
     "coverageMin" -> Min[cov], "coverageMax" -> Max[cov],
     "feasible" -> (AllTrue[cliqueVertLists, cliqueQ[n]] && Min[cov] >= 1),
     "objective" -> yw Length[cliqueVertLists]|>];

(* ------------------------------------------------------------------ *)
(* C-A1 H^1 partition-defect: is the LP optimum an EXACT partition?     *)
(* An exact partition of unity = disjoint weight-1 maximal cliques      *)
(* covering V exactly once, whose count equals Lambda_k.                *)
(* ------------------------------------------------------------------ *)

(* explicit-partition check (used where a census/candidate exists). *)
partitionOfUnityQ[n_, k_, cliqueVertLists_] := Module[{flat = Flatten[cliqueVertLists, 1]},
   AllTrue[cliqueVertLists, cliqueQ[n]] &&
   Sort[flat] === Sort[conormalVerts[n, k]] &&                (* covers each vertex... *)
   Length[flat] === n^k];                                     (* ...exactly once (disjoint) *)

(* H^1-proxy: 0 iff Lambda in Z and an exact partition of that value exists. *)
h1Proxy[lambda_, hasExactPartition_] := If[
   IntegerQ[lambda] && hasExactPartition, 0,
   <|"nonzero" -> True, "value" -> lambda,
     "reason" -> If[! IntegerQ[lambda],
        "Lambda = " <> ToString[lambda, InputForm] <> " is not an integer: "
          <> "no weight-1 clique partition can sum to it (denominator "
          <> ToString[Denominator[lambda]] <> ")",
        "Lambda integer but no exact clique-partition of V achieves it"]|>];

(* ================================================================== *)
(* k = 1, 2: full census + exact capacity/cover LPs                    *)
(* ================================================================== *)

Print["--- k <= 2: census + exact capacity Lambda_k = sup mu over H^0(F) ---"];
res = <||>;
Do[
  {g, vs, idx} = conormalGraph[n, k];
  mc = FindClique[g, Infinity, All];
  hist = Sort@Normal@Counts[Length /@ mc];
  cap = capacityLP[mc, Length[vs]];
  cov = coverLP[mc, Length[vs]];
  res[{n, k}] = <|"verts" -> vs, "idx" -> idx, "cliques" -> mc, "hist" -> hist,
    "omega" -> Max[Length /@ mc], "Lambda" -> cap["value"], "p" -> cap["p"],
    "dualValue" -> cov["value"], "y" -> cov["y"]|>;
  Print["C", n, "^v", k, ": |V|=", Length[vs], " maxCliques=", Length[mc],
    " sizes=", hist, "  Lambda=", ToString[cap["value"], InputForm],
    "  perCopy=", ToString[cap["value"]^(1/k), InputForm]],
  {n, {5, 7}}, {k, {1, 2}}];

lam1c5 = res[{5, 1}]["Lambda"]; lam2c5 = res[{5, 2}]["Lambda"];
lam1c7 = res[{7, 1}]["Lambda"]; lam2c7 = res[{7, 2}]["Lambda"];

(* --- C-A1 at k=2 on C5: the five slope-2 pentads are an exact partition --- *)
pentad[a_, j_] := Table[{i, Mod[a i + j, 5]}, {i, 0, 4}];
pentads2 = Table[pentad[2, j], {j, 0, 4}];
c5k2Partition = partitionOfUnityQ[5, 2, pentads2];
c5k2PartValue = Length[pentads2];                    (* 5, must equal Lambda_2(C5) *)
h1C5k2 = h1Proxy[lam2c5, c5k2Partition && c5k2PartValue === lam2c5];
Print["C-A1 (C5,k=2): 5 slope-2 pentads exact partition of the 25 events: ",
  c5k2Partition, " (value ", c5k2PartValue, " = Lambda_2 ", lam2c5 === c5k2PartValue,
  "); H^1-proxy = ", h1C5k2];

(* k=1: Lambda = n/2 is non-integer -> no partition -> H^1 nonzero. *)
h1C5k1 = h1Proxy[lam1c5, False];
h1C7k1 = h1Proxy[lam1c7, False];
(* C7 k=2: omega=4, |V|=49, 4 does not divide 49 AND Lambda=49/4 non-integer. *)
c7k2DivisObstruction = ! IntegerQ[49/res[{7, 2}]["omega"]];   (* 49/4 not integer *)
h1C7k2 = h1Proxy[lam2c7, False];
Print["C-A1 (C7,k=2): omega=", res[{7, 2}]["omega"], ", |V|=49, exact partition needs ",
  "omega | |V|: 49/", res[{7, 2}]["omega"], " integer? ", IntegerQ[49/res[{7, 2}]["omega"]],
  "; Lambda_2=", ToString[lam2c7, InputForm], " non-integer -> H^1-proxy = ", h1C7k2];

(* ================================================================== *)
(* k = 3 (C7 control): certificate sandwich, NO census                 *)
(* upper: dual 0-cochain (343 edge-cube 8-cliques, y=1/8) verified fresh*)
(* lower: primal p = 1/8 uniform, feasible iff omega(C7^v3) <= 8        *)
(*        (omega(C7^v3) = 8 established in P3, cited)                   *)
(* ================================================================== *)

Print["--- k=3 (C7): certificate sandwich for Lambda_3(C7) ---"];
edgeCubes = Flatten[Table[
    Tuples[{{i, Mod[i + 1, 7]}, {j, Mod[j + 1, 7]}, {l, Mod[l + 1, 7]}}],
    {i, 0, 6}, {j, 0, 6}, {l, 0, 6}], 2];
dualC7k3 = verifyDualCochain[7, 3, edgeCubes, 1/8];
Print["dual 0-cochain (343 edge-cubes, y=1/8): feasible=", dualC7k3["feasible"],
  " objective=", ToString[dualC7k3["objective"], InputForm],
  "  => Lambda_3(C7) <= ", ToString[dualC7k3["objective"], InputForm]];

(* omega(C7^v3) = 8: established-in-project fact (P3 run, orbit-reduced decision,
   p3_certificates.json). Cited, not recomputed here (expensive FindClique). *)
omegaC7v3 = 8;
omegaC7v3Provenance = "omega(C7^v3)=8 established in essay005_p3_gluing_lp.wl / p3_certificates.json (2026-07-13, orbit-reduced 9-clique decision); cited, not recomputed here.";
(* primal p = 1/8 uniform: Total = 343/8; feasible iff every clique <= 8 verts. *)
primalC7k3Feasible = (omegaC7v3 <= 8);
lam3c7 = If[dualC7k3["feasible"] && primalC7k3Feasible, 343/8, Indeterminate];
Print["primal p=1/8 uniform feasible (needs omega<=8; omega=", omegaC7v3, "): ",
  primalC7k3Feasible, "  => Lambda_3(C7) >= 343/8"];
Print["Lambda_3(C7) = ", ToString[lam3c7, InputForm], "  per-copy = ",
  ToString[Simplify[lam3c7^(1/3)], InputForm]];

(* C-A1 (C7,k=3): Lambda=343/8 non-integer (8 does not divide 343=7^3). *)
h1C7k3 = h1Proxy[lam3c7, False];
Print["C-A1 (C7,k=3): omega=8, |V|=343=7^3, 343/8 integer? ", IntegerQ[343/8],
  " -> no exact partition -> H^1-proxy = ", h1C7k3];

(* ================================================================== *)
(* GATES                                                               *)
(* ================================================================== *)

thetaC7 = 7 Cos[Pi/7]/(1 + Cos[Pi/7]);   (* ~3.3177: WRONG value must not appear *)

gates = <|
   (* -- PRIMARY INVARIANT: Lambda_k = L_k = S_k anchors -- *)
   "S1(C5): Lambda_1(C5) == 5/2" -> (lam1c5 === 5/2),
   "S2(C5): Lambda_2(C5) == 5, per-copy Sqrt[5] (exact)" ->
     (lam2c5 === 5 && RootReduce[lam2c5^(1/2)] === Sqrt[5]),
   "S2(C7): Lambda_2(C7) == 49/4, per-copy 7/2" ->
     (lam2c7 === 49/4 && RootReduce[lam2c7^(1/2)] === 7/2),
   "S2(C7) =!= theta(C7)^2 (Trap-1 control, must NOT sag to ~11.008)" ->
     (RootReduce[lam2c7 - thetaC7^2] =!= 0),
   "S3(C7): Lambda_3(C7) == 343/8, per-copy 7/2 (control holds at k=3)" ->
     (lam3c7 === 343/8 && Simplify[lam3c7^(1/3)] === 7/2),
   (* -- capacity = degree-0 total-mass hom = LP duality (dual matches primal) -- *)
   "capacity == dual cover value at (C5,k=1)" -> (lam1c5 === res[{5,1}]["dualValue"]),
   "capacity == dual cover value at (C5,k=2)" -> (lam2c5 === res[{5,2}]["dualValue"]),
   "capacity == dual cover value at (C7,k=2)" -> (lam2c7 === res[{7,2}]["dualValue"]),
   (* -- census cross-checks (encoding sanity) -- *)
   "census C5^v2 == 535 = {4:525,5:10}" ->
     (Length[res[{5,2}]["cliques"]] === 535 && res[{5,2}]["hist"] === {4 -> 525, 5 -> 10}),
   "census C7^v2 == 1715 = {4:1715}" ->
     (Length[res[{7,2}]["cliques"]] === 1715 && res[{7,2}]["hist"] === {4 -> 1715}),
   "k=3(C7) dual 0-cochain feasible (343 edge-cubes, y=1/8)" -> dualC7k3["feasible"],
   (* -- C-A1 H^1 partition-defect: 0 iff exact partition of unity -- *)
   "C-A1: H^1-proxy(C5,k=2) == 0 (five pentads = exact partition of unity)" ->
     (h1C5k2 === 0),
   "C-A1: H^1-proxy(C7,k=2) =!= 0 (49/4 fractional, 4 does not divide 49)" ->
     (h1C7k2 =!= 0),
   "C-A1: H^1-proxy(C7,k=3) =!= 0 (343/8 fractional, 8 does not divide 343)" ->
     (h1C7k3 =!= 0),
   "C-A1: H^1-proxy(C5,k=1) =!= 0 and H^1-proxy(C7,k=1) =!= 0 (5/2, 7/2 fractional)" ->
     (h1C5k1 =!= 0 && h1C7k1 =!= 0)
   |>;

Print["\n--- GATE TABLE ---"];
KeyValueMap[Print["  ", If[TrueQ[#2], "PASS", "FAIL"], "  ", #1] &, gates];
allOK = AllTrue[Values[gates], TrueQ];
Print["OK -> ", allOK];
If[! allOK, Print["GATE FAILURE: the invariant does not reproduce an anchor. ",
   "Per project ethos, report as obstruction; do NOT fudge."]];

(* ================================================================== *)
(* JSON summary                                                        *)
(* ================================================================== *)

s[x_] := ToString[x, InputForm];
summary = <|
  "module" -> "ESSAY-005 Formalizer A: weighted-presheaf invariant",
  "date" -> DateString["ISODate"],
  "presheaf" -> "F(K)={w:K->[0,1], sum<=1} over R=Q>=0 (effect module); "
    <> "H^0(F) = packing polytope (glues trivially, sections are point-functions).",
  "primaryInvariant" -> "Lambda_k = sup_{p in H^0(F)} mu(p) = L_k; S_k = Lambda_k^(1/k).",
  "gateVerdict" -> If[allOK, "PASS", "FAIL"],
  "gates" -> gates,
  "anchors" -> <|
    "S1(C5)" -> <|"Lambda" -> s[lam1c5], "perCopy" -> s[lam1c5], "target" -> "5/2"|>,
    "S2(C5)" -> <|"Lambda" -> s[lam2c5], "perCopy" -> "Sqrt[5]", "target" -> "Sqrt[5]"|>,
    "S2(C7)" -> <|"Lambda" -> s[lam2c7], "perCopy" -> "7/2", "target" -> "7/2",
      "notThetaSq" -> s[N[thetaC7^2]]|>,
    "S3(C7)" -> <|"Lambda" -> s[lam3c7], "perCopy" -> "7/2", "target" -> "7/2",
      "omegaProvenance" -> omegaC7v3Provenance|>|>,
  "CA1_H1_partitionDefect" -> <|
    "conjecture" -> "semimodule/tropical H^1 vanishes iff LP optimum is an exact "
      <> "partition of unity (FLAGGED CONJECTURE; computed proxy below).",
    "C5_k1" -> s[h1C5k1], "C5_k2" -> s[h1C5k2],
    "C7_k1" -> s[h1C7k1], "C7_k2" -> s[h1C7k2], "C7_k3" -> s[h1C7k3],
    "reading" -> "H^1-proxy = 0 ONLY at (C5,k=2) among anchors (five pentads, exact "
      <> "partition); nonzero elsewhere (5/2, 7/2, 49/4, 343/8 are properly "
      <> "fractional covers). Refines the integrality gap without moving Lambda_k."|>,
  "honesty" -> <|
    "established" -> "Lambda_k = L_k reproduces all four anchors exactly (this run "
      <> "+ p3_certificates.json).",
    "newClaim" -> "Lambda_k is the degree-0 capacity (total-mass hom on H^0(F)); "
      <> "S_k = Lambda_k^(1/k). Degree-0, NOT an H^1/torsion class.",
    "conjecture" -> "C-A1 (H^1 iff exact partition): the computed object is a "
      <> "partition-DEFECT PROXY, not a proven semimodule-cohomology H^1.",
    "citedFact" -> omegaC7v3Provenance|>
  |>;
Export[FileNameJoin[{scriptDir, "bridge_weighted_presheaf.json"}], summary, "JSON"];
Print["wrote bridge_weighted_presheaf.json"];
Print["total ", Round[AbsoluteTime[] - startT], " s"];
Print["OK -> ", allOK];
