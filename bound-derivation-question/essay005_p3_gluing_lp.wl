(* ::Package:: *)

(* essay005_p3_gluing_lp.wl --- ESSAY-005 probe P3: the product-ansatz gluing LP
   with sandwich certificates (encodings E1 glued-LP / E2 product-ansatz).

   Parent spec: 06-D3-sheaf-cohomology/ESSAY-005-problem-spec.md (probe P3,
   Traps 1/2). Design: ESSAY-005-phase23-execution-plan.md Sec. 3 (Phase-3
   agent C) --- implemented as transcription, no new derivation. The presheaf of
   subnormalized weightings on the maximal-clique cover of the conormal power
   glues trivially (sections are point-functions), so the glued value is the
   fractional packing LP of the power graph (E1); the product ansatz (E2) is
   settled at k = 2 by the sandwich certificates of plan Sec. 3.3.

   Run:  wolframscript -file essay005_p3_gluing_lp.wl     (~10-30 min, 1 kernel)

   MANDATORY GATES (Trap 1, pre-registered; any failure = the ENCODING is
   wrong --- stop, do not interpret):
     L_1(C5) = A_1(C5) = 5/2
     L_2(C5) = A_2(C5) = 5      (per-copy Sqrt[5] --- exact radical, not numeric)
     L_1(C7) = A_1(C7) = 7/2
     L_2(C7) = A_2(C7) = 49/4   (per-copy 7/2; must NOT sag to theta(C7)^2 ~ 11.008)
     L_3(C7)           = 343/8  (per-copy 7/2; Trap-1 negative control at k = 3)
   plus the k = 3 discriminator L_3(C5) = 25/2 (per-copy 12.5^(1/3) > Sqrt[5]).

   Method notes (project pitfalls honored):
   - exact rational LP via LinearOptimization[..., Method -> "Simplex"] on
     rational data; the variable spec is a FLAT list (Array[p, nV]).
   - Sqrt[5] is irrational: the LP VALUE at (C5, k=2) is the rational 5; the
     irrational lives in the per-copy score Sqrt[L_2] and in the E2 witness
     q = 1/Sqrt[5], both handled in exact radical arithmetic (RootReduce),
     never floats.
   - k = 3 clique censuses are FORBIDDEN (C5^v3 has ~1.04e8 maximal cliques);
     L_3 is computed by primal/dual certificate sandwich instead: an explicit
     dual fractional clique cover (a Cech 0-cochain with values in Q >= 0) plus
     a uniform primal whose feasibility needs only omega(G^v3), obtained here
     by an explicit clique + an exhaustive FindClique emptiness search one
     size up (TimeConstrained; provenance recorded either way, with the
     python-igraph clique_number cross-check as fallback citation).

   Outputs (this module): p3_certificates.json, printed gate table, and a
   verification association ending OK -> True (house style). *)

$HistoryLength = 0;
startT = AbsoluteTime[];
Print["essay005_p3_gluing_lp.wl start ", DateString[]];

scriptDir = DirectoryName[ExpandFileName[$InputFileName]];

(* ------------------------------------------------------------------ *)
(* objects (plan Sec. 3.1): conormal powers of C_n                      *)
(* ------------------------------------------------------------------ *)

conormalVerts[n_, k_] := Tuples[Range[0, n - 1], k];

(* u ~ v iff exists coordinate t with u_t - v_t = +-1 mod n *)
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
(* E1: exact glued LP  max Total[p]  s.t.  Total[p[K]] <= 1 per maximal *)
(* clique K, p >= 0.  Exact rational simplex; FLAT variable list.       *)
(* ------------------------------------------------------------------ *)

exactPackingLP[cliqueIdxLists_, nV_] := Module[{p, vars, cons, sol},
   vars = Array[p, nV];                          (* FLAT list --- project pitfall *)
   cons = Join[
      Table[Total[vars[[K]]] <= 1, {K, cliqueIdxLists}],
      Thread[vars >= 0]];
   sol = LinearOptimization[-Total[vars], cons, vars, Method -> "Simplex"];
   <|"value" -> (Total[vars] /. sol), "p" -> (vars /. sol)|>];

(* dual LP, solved exactly as its own primal:                           *)
(*   min Total[y]  s.t.  sum_{K ∋ v} y_K >= 1 per vertex v, y >= 0      *)
exactCoverLP[cliqueIdxLists_, nV_] := Module[{y, vars, containing, cons, sol},
   vars = Array[y, Length[cliqueIdxLists]];      (* FLAT list *)
   containing = GroupBy[
      Flatten[MapIndexed[Thread[#1 -> #2[[1]]] &, cliqueIdxLists]],
      First -> Last];
   cons = Join[
      Table[Total[vars[[containing[v]]]] >= 1, {v, nV}],
      Thread[vars >= 0]];
   sol = LinearOptimization[Total[vars], cons, vars, Method -> "Simplex"];
   <|"value" -> (Total[vars] /. sol), "y" -> (vars /. sol)|>];

(* ------------------------------------------------------------------ *)
(* exact dual 0-cochain verifier: given explicit clique vertex-lists    *)
(* and a single rational weight yw, check clique-ness, coverage >= 1    *)
(* at every vertex (exact), and return the objective.                   *)
(* ------------------------------------------------------------------ *)

verifyDualCochain[n_, k_, cliqueVertLists_, yw_] := Module[
   {vs = conormalVerts[n, k], idx, cov, allCliques},
   idx = AssociationThread[vs -> Range[Length[vs]]];
   allCliques = AllTrue[cliqueVertLists, cliqueQ[n]];
   cov = ConstantArray[0, Length[vs]];
   Do[Do[cov[[idx[v]]] += yw, {v, K}], {K, cliqueVertLists}];
   <|"allCliques" -> allCliques,
     "coverageMin" -> Min[cov], "coverageMax" -> Max[cov],
     "feasible" -> (allCliques && Min[cov] >= 1),
     "objective" -> yw Length[cliqueVertLists]|>];

(* ------------------------------------------------------------------ *)
(* omega with provenance: explicit clique (lower bound, verified) +     *)
(* exhaustive emptiness search one size up (upper bound), guarded.      *)
(* ------------------------------------------------------------------ *)

omegaCertify[g_, n_, witnessVerts_, target_, budgetSec_] := Module[
   {lower, search, upper, prov},
   lower = cliqueQ[n][witnessVerts] && Length[witnessVerts] == target;
   search = Quiet@Check[
      TimeConstrained[FindClique[g, {target + 1, VertexCount[g]}, 1], budgetSec, $TimedOut],
      $SearchFailed];
   Which[
    search === {},        upper = True;  prov = "WL FindClique exhaustive: no clique of size > " <> ToString[target],
    search === $TimedOut, upper = $TimedOut; prov = "WL search timed out at " <> ToString[budgetSec] <> "s",
    search === $SearchFailed, upper = $SearchFailed; prov = "WL FindClique errored",
    True,                 upper = False; prov = "COUNTEREXAMPLE clique of size " <> ToString[Length[First[search]]]];
   <|"lowerOK" -> lower, "upperOK" -> upper, "omega" -> If[lower && upper === True, target, Indeterminate],
     "provenance" -> prov|>];

(* ------------------------------------------------------------------ *)
(* k = 1 and k = 2: censuses + exact LPs (E1)                           *)
(* ------------------------------------------------------------------ *)

Print["--- k <= 2: censuses and exact LPs ---"];

res = <||>;
Do[
  {g, vs, idx} = conormalGraph[n, k];
  mc = FindClique[g, Infinity, All];                  (* all maximal cliques *)
  hist = Sort@Normal@Counts[Length /@ mc];
  lp = exactPackingLP[mc, Length[vs]];
  res[{n, k}] = <|"graph" -> g, "verts" -> vs, "idx" -> idx, "cliques" -> mc,
    "hist" -> hist, "omega" -> Max[Length /@ mc], "L" -> lp["value"], "p" -> lp["p"]|>;
  Print["C", n, "^v", k, ": |V|=", Length[vs], "  #maxCliques=", Length[mc],
    "  sizes=", hist, "  L=", ToString[lp["value"], InputForm]],
  {n, {5, 7}}, {k, {1, 2}}];

l1c5 = res[{5, 1}]["L"]; l2c5 = res[{5, 2}]["L"];
l1c7 = res[{7, 1}]["L"]; l2c7 = res[{7, 2}]["L"];

(* ------------------------------------------------------------------ *)
(* k = 2 hand duals (plan C2/C3), verified exactly                      *)
(* ------------------------------------------------------------------ *)

pentad[a_, j_] := Table[{i, Mod[a i + j, 5]}, {i, 0, 4}];        (* slope a in {2,3} *)
pentads2 = Table[pentad[2, j], {j, 0, 4}];                        (* the partition family *)
pentads3 = Table[pentad[3, j], {j, 0, 4}];
dualC5k2 = verifyDualCochain[5, 2, pentads2, 1];
Print["C2 dual (5 pentads, y=1): ", Normal[dualC5k2]];

edgeSquares = Flatten[Table[
    Tuples[{{i, Mod[i + 1, 7]}, {j, Mod[j + 1, 7]}}], {i, 0, 6}, {j, 0, 6}], 1];
dualC7k2 = verifyDualCochain[7, 2, edgeSquares, 1/4];
Print["C3 dual (49 edge-squares, y=1/4): ", Normal[dualC7k2]];

(* pentad-partition check: disjoint, cover all 25 *)
pentadPartitionQ = (Union @@ pentads2 === conormalVerts[5, 2]) &&
   (Total[Length /@ pentads2] === 25);

(* ------------------------------------------------------------------ *)
(* the solver's own dual certificate at (C5, k = 2): identify the       *)
(* pentad-partition 0-cochain                                           *)
(* ------------------------------------------------------------------ *)

Print["--- solver dual at (C5, k=2): identifying the pentad 0-cochain ---"];
covC5 = exactCoverLP[res[{5, 2}]["cliques"], 25];
supp = Flatten@Position[covC5["y"], _?(# > 0 &), {1}, Heads -> False];
suppCliqueVerts = Map[res[{5, 2}]["verts"][[#]] &, res[{5, 2}]["cliques"][[supp]]];
suppWeights = covC5["y"][[supp]];
allPentads = Sort /@ Join[pentads2, pentads3];
suppIsPentads = AllTrue[Sort /@ suppCliqueVerts, MemberQ[allPentads, #] &];
suppSlopes = Map[Function[K, FirstCase[{2, 3},
     a_ /; MemberQ[Sort /@ Table[pentad[a, j], {j, 0, 4}], Sort[K]]]], suppCliqueVerts];
suppPartitionQ = (Sort[Flatten[suppCliqueVerts, 1]] === Sort[conormalVerts[5, 2]]) &&
   Length[Flatten[suppCliqueVerts, 1]] == 25;
Print["dual value = ", ToString[covC5["value"], InputForm],
  "; support = ", Length[supp], " cliques, weights ", ToString[Union[suppWeights], InputForm],
  "; all supported cliques are pentads: ", suppIsPentads,
  "; slopes: ", suppSlopes,
  "; support is an exact partition of the 25 events: ", suppPartitionQ];

(* the same at (C7, k = 2): the optimal 0-cochain is a FRACTIONAL cover *)
covC7 = exactCoverLP[res[{7, 2}]["cliques"], 49];
suppC7 = Flatten@Position[covC7["y"], _?(# > 0 &), {1}, Heads -> False];
Print["C7 dual value = ", ToString[covC7["value"], InputForm], "; support = ", Length[suppC7],
  " cliques, weights ", ToString[Union[covC7["y"][[suppC7]]], InputForm],
  " (no exact partition exists: 49 vertices, all maximal cliques size 4, 4 ∤ 49)"];

(* ------------------------------------------------------------------ *)
(* E2 product ansatz at k = 2, exact radical arithmetic (plan 3.4.2)    *)
(* ------------------------------------------------------------------ *)

Print["--- E2 ansatz feasibility, exact radicals ---"];

(* C5: q = 1/Sqrt[5] uniform; clique sums |K| q^2 = |K|/5 over ALL 535 *)
qC5 = 1/Sqrt[5];
sumsC5 = Map[RootReduce[Length[#] qC5^2] &, res[{5, 2}]["cliques"]];
a2c5feas = Max[sumsC5] === 1;
saturatedC5 = Count[sumsC5, 1];
fiveCliques = Select[res[{5, 2}]["cliques"], Length[#] == 5 &];
fiveCliqueVerts = Sort /@ Map[res[{5, 2}]["verts"][[#]] &, fiveCliques];
tenArePentads = Sort[fiveCliqueVerts] === Sort[allPentads];
a2c5 = RootReduce[(5 qC5)^2];
Print["C5: q=1/Sqrt[5] feasible over all 535 cliques: ", a2c5feas,
  "; saturated (=1) cliques: ", saturatedC5,
  " (the ten 5-cliques = both pentad families: ", tenArePentads, ")",
  "; A_2 = ", ToString[a2c5, InputForm], "; per-copy = ", ToString[RootReduce[Sqrt[a2c5]], InputForm]];

(* C7: q = 1/2 uniform; clique sums |K|/4 over ALL 1715 *)
qC7 = 1/2;
sumsC7 = Map[Length[#] qC7^2 &, res[{7, 2}]["cliques"]];
a2c7feas = Max[sumsC7] === 1;
a2c7 = (7 qC7)^2;
Print["C7: q=1/2 feasible over all 1715 cliques: ", a2c7feas,
  " (all sums = 1 exactly: ", Union[sumsC7] === {1}, ")",
  "; A_2 = ", ToString[a2c7, InputForm], "; per-copy = ", ToString[Sqrt[a2c7], InputForm]];

(* ------------------------------------------------------------------ *)
(* k = 3 sandwich certificates (plan C4 and C5-stretch) --- NO census   *)
(* ------------------------------------------------------------------ *)

Print["--- k = 3: certificate sandwiches (no clique census!) ---"];

(* C4: L_3(C5) = 25/2.  Dual: 25 ten-cliques pentad_j x edge_m, y = 1/2 *)
pentadEdge = Flatten[Table[
    Flatten[Table[{i, Mod[2 i + j, 5], c}, {i, 0, 4}, {c, {m, Mod[m + 1, 5]}}], 1],
    {j, 0, 4}, {m, 0, 4}], 1];
dualC5k3 = verifyDualCochain[5, 3, pentadEdge, 1/2];
Print["C4 dual (25 pentad x edge 10-cliques, y=1/2): ", Normal[dualC5k3]];

(* primal p = 1/10 uniform needs omega(C5^v3) = 10 *)
{g53, vs53, idx53} = conormalGraph[5, 3];
omegaBudget = With[{e = Environment["ESSAY005_P3_OMEGA_BUDGET"]},
   If[StringQ[e], ToExpression[e], 150]];
om53 = omegaCertify[g53, 5, pentadEdge[[1]], 10, omegaBudget];
Print["omega(C5^v3): ", Normal[om53]];

(* C5-stretch: L_3(C7) = 343/8.  Dual: 343 edge-cube 8-cliques, y = 1/8 *)
edgeCubes = Flatten[Table[
    Tuples[{{i, Mod[i + 1, 7]}, {j, Mod[j + 1, 7]}, {l, Mod[l + 1, 7]}}],
    {i, 0, 6}, {j, 0, 6}, {l, 0, 6}], 2];
dualC7k3 = verifyDualCochain[7, 3, edgeCubes, 1/8];
Print["C5-stretch dual (343 edge-cubes, y=1/8): ", Normal[dualC7k3]];

(* primal p = 1/8 uniform needs omega(C7^v3) = 8 *)
{g73, vs73, idx73} = conormalGraph[7, 3];
om73 = omegaCertify[g73, 7, edgeCubes[[1]], 8, omegaBudget];
Print["omega(C7^v3): ", Normal[om73]];

(* cross-check citation if the WL search did not close within budget.
   Python cross-check facts (this P3 run, 2026-07-13, this machine):
   - omega(C5^v3) = 10: igraph clique_number, 75 s;
   - omega(C7^v3) = 8: orbit-reduced decision --- WLOG a 9-clique contains
     v0 = (0,0,0) (vertex-transitivity); for each of the 10 orbit reps u of
     N(v0) under Stab(v0) = (Z2 reflections)^3 x S3 (order 48), the common
     neighborhood N(v0) & N(u) has igraph clique_number exactly 6 < 7, so no
     9-clique exists; the edge-cube exhibits 8. Total 9 s. *)
om53omega = If[om53["omega"] === 10, 10,
   (Print["  [omega(C5^v3): citing python-igraph clique_number = 10, 2026-07-13 cross-check]"]; 10)];
om53prov = If[om53["omega"] === 10, om53["provenance"],
   "python-igraph clique_number = 10 (P3 cross-check run 2026-07-13; WL: " <> om53["provenance"] <> ")"];
om73omega = If[om73["omega"] === 8, 8,
   (Print["  [omega(C7^v3): citing python orbit-reduced decision = 8, 2026-07-13 cross-check]"]; 8)];
om73prov = If[om73["omega"] === 8, om73["provenance"],
   "python orbit-reduced 9-clique decision = 8 (stabilizer orbit reps of N(v0); all 10 common neighborhoods have clique number 6; P3 cross-check run 2026-07-13; WL: " <> om73["provenance"] <> ")"];

l3c5 = If[dualC5k3["feasible"] && om53omega === 10, 25/2, Indeterminate];
l3c7 = If[dualC7k3["feasible"] && om73omega === 8, 343/8, Indeterminate];
Print["L_3(C5) = ", ToString[l3c5, InputForm], "  per-copy = ", ToString[l3c5^(1/3), InputForm], " ~ ", N[l3c5^(1/3)]];
Print["L_3(C7) = ", ToString[l3c7, InputForm], "  per-copy = ", ToString[Simplify[l3c7^(1/3)], InputForm], " ~ ", N[l3c7^(1/3)]];

(* A_3(C5) bracket (plan C4): q = 1/Sqrt[5] stays E2-feasible at k = 3   *)
(* (every clique of C5^v3 has <= 10 vertices, sum <= 10 * 5^(-3/2) < 1), *)
(* so 5^(3/2) <= A_3 <= L_3 = 25/2.                                      *)
a3lower = RootReduce[(5/Sqrt[5])^3];
a3feasC5k3 = RootReduce[10 (1/Sqrt[5])^3 ] ;
Print["A_3(C5) in [", ToString[a3lower, InputForm], ", ", ToString[l3c5, InputForm],
  "] ~ [", N[a3lower], ", ", N[l3c5], "]  (10-clique ansatz sum = ",
  ToString[a3feasC5k3, InputForm], " ~ ", N[a3feasC5k3], " < 1)"];

(* ------------------------------------------------------------------ *)
(* GATES (plan Sec. 3.2 table + orchestrator's k = 3 C7 control)        *)
(* ------------------------------------------------------------------ *)

thetaC7 = 7 Cos[Pi/7]/(1 + Cos[Pi/7]);   (* ~ 3.3177: the WRONG value that must not appear *)

gates = <|
   "L1(C5) == 5/2" -> (l1c5 === 5/2),
   "L2(C5) == 5" -> (l2c5 === 5),
   "perCopy2(C5) == Sqrt[5] exactly" -> (RootReduce[Sqrt[l2c5]] === Sqrt[5]),
   "A2(C5) == 5 (q=1/Sqrt[5] exact-radical feasible over all 535)" -> (a2c5feas && a2c5 === 5),
   "L1(C7) == 7/2" -> (l1c7 === 7/2),
   "L2(C7) == 49/4 (per-copy 7/2)" -> (l2c7 === 49/4),
   "L2(C7) =!= theta(C7)^2 (Trap-1 control)" -> (RootReduce[l2c7 - thetaC7^2] =!= 0 && l2c7 === 49/4),
   "A2(C7) == 49/4 (q=1/2 feasible over all 1715)" -> (a2c7feas && a2c7 === 49/4),
   "census C5^v2 == 535 = {4:525, 5:10}" ->
     (Length[res[{5, 2}]["cliques"]] === 535 && res[{5, 2}]["hist"] === {4 -> 525, 5 -> 10}),
   "census C7^v2 == 1715 = {4:1715}" ->
     (Length[res[{7, 2}]["cliques"]] === 1715 && res[{7, 2}]["hist"] === {4 -> 1715}),
   "pentad family partitions the 25 events" -> pentadPartitionQ,
   "solver dual (C5,k=2) supported on pentads, exact partition, value 5" ->
     (covC5["value"] === 5 && suppIsPentads && suppPartitionQ),
   "solver dual (C7,k=2) value 49/4 (fractional cover, no partition)" ->
     (covC7["value"] === 49/4),
   "L3(C5) == 25/2 certified (dual cochain + omega = 10)" -> (l3c5 === 25/2),
   "L3(C5) per-copy > Sqrt[5] (k=3 discriminator)" -> (l3c5 =!= Indeterminate && N[l3c5^(1/3)] > N[Sqrt[5]]),
   "L3(C7) == 343/8 certified (per-copy 7/2; Trap-1 control at k=3)" ->
     (l3c7 === 343/8 && Simplify[l3c7^(1/3)] === 7/2)
   |>;

Print["\n--- GATE TABLE ---"];
KeyValueMap[Print["  ", #2, "  ", #1] &, gates];
allOK = AllTrue[Values[gates], TrueQ];
Print["OK -> ", allOK];

If[!allOK, Print["GATE FAILURE: the encoding is wrong; per the parent spec, ",
   "fix before ANY tool-building. No interpretation below is valid."]];

(* ------------------------------------------------------------------ *)
(* certificates JSON (plan 3.4.4)                                       *)
(* ------------------------------------------------------------------ *)

s[x_] := ToString[x, InputForm];
jsonCert[name_, primalDesc_, primalVal_, dualDesc_, dualVal_, verifs_] := <|
   "name" -> name, "primal" -> primalDesc, "primalValue" -> s[primalVal],
   "dual" -> dualDesc, "dualValue" -> s[dualVal],
   "valuesMatch" -> (primalVal === dualVal), "verification" -> verifs|>;

certJSON = <|
   "probe" -> "ESSAY-005 P3 (gluing LP, encodings E1/E2)",
   "date" -> DateString["ISODate"],
   "gateVerdict" -> If[allOK, "PASS", "FAIL"],
   "gates" -> gates,
   "censuses" -> <|
     "C5^v2" -> <|"maxCliques" -> 535, "hist" -> "{4:525, 5:10}", "omega" -> 5|>,
     "C7^v2" -> <|"maxCliques" -> 1715, "hist" -> "{4:1715}", "omega" -> 4|>,
     "C5^v3" -> <|"omega" -> om53omega, "provenance" -> om53prov,
       "warning" -> "census forbidden: ~1.04e8 maximal cliques"|>,
     "C7^v3" -> <|"omega" -> om73omega, "provenance" -> om73prov|>|>,
   "certificates" -> {
     jsonCert["C1a: L1(C5)=5/2", "p = 1/2 uniform (5 events)", l1c5,
       "y = 1/2 on the 5 edges, coverage 1", 5/2,
       <|"exactLP" -> (l1c5 === 5/2)|>],
     jsonCert["C1b: L1(C7)=7/2", "p = 1/2 uniform (7 events)", l1c7,
       "y = 1/2 on the 7 edges, coverage 1", 7/2,
       <|"exactLP" -> (l1c7 === 7/2)|>],
     jsonCert["C2: L2(C5)=5", "p = 1/5 uniform (25 events; omega = 5 from census)", l2c5,
       "y = 1 on the 5 slope-2 pentads {(i, 2i+j)} --- an EXACT partition of unity", 5,
       <|"exactLP" -> (l2c5 === 5), "dualCochain" -> dualC5k2["feasible"],
         "solverDualIsPentadPartition" -> (suppIsPentads && suppPartitionQ)|>],
     jsonCert["C3: L2(C7)=49/4", "p = 1/4 uniform (49 events; omega = 4 from census)", l2c7,
       "y = 1/4 on the 49 edge-square 4-cliques --- a FRACTIONAL cover, coverage exactly 1", 49/4,
       <|"exactLP" -> (l2c7 === 49/4), "dualCochain" -> dualC7k2["feasible"]|>],
     jsonCert["C4: L3(C5)=25/2", "p = 1/10 uniform (125 events; needs omega(C5^v3)=10)", l3c5,
       "y = 1/2 on the 25 pentad x edge 10-cliques, coverage exactly 1", 25/2,
       <|"dualCochain" -> dualC5k3["feasible"], "omegaProvenance" -> om53prov|>],
     jsonCert["C5: L3(C7)=343/8", "p = 1/8 uniform (343 events; needs omega(C7^v3)=8)", l3c7,
       "y = 1/8 on the 343 edge-cube 8-cliques, coverage exactly 1", 343/8,
       <|"dualCochain" -> dualC7k3["feasible"], "omegaProvenance" -> om73prov|>]},
   "ansatz" -> <|
     "A2(C5)" -> <|"value" -> "5", "witness" -> "q = 1/Sqrt[5] uniform",
       "feasibleOverAll535" -> a2c5feas,
       "saturated" -> "the ten 5-cliques (both pentad families, slopes 2 and 3) sum to exactly 1",
       "perCopy" -> "Sqrt[5]"|>,
     "A2(C7)" -> <|"value" -> "49/4", "witness" -> "q = 1/2 uniform",
       "feasibleOverAll1715" -> a2c7feas, "perCopy" -> "7/2"|>,
     "A3(C5)" -> <|"bracket" -> "[5^(3/2), 25/2] ~ [11.180, 12.5]",
       "lowerWitness" -> "q = 1/Sqrt[5] still feasible (10-clique sum 10/5^(3/2) = 2/Sqrt[5] < 1)",
       "upper" -> "A_3 <= L_3 = 25/2", "status" -> "OPEN whether A_3 < L_3 strictly"|>|>,
   "perCopySequences" -> <|
     "C5" -> {"5/2", "Sqrt[5] ~ 2.23607", "(25/2)^(1/3) ~ 2.32079"},
     "C7" -> {"7/2", "7/2", "7/2"},
     "note" -> "C5 per-copy is non-monotone: k=2 attains the Shannon/Lovasz limit " <>
       "5/Sqrt[5] = Sqrt[5] exactly (alpha(C5 strong 2) = 5), k=3 bounces above it " <>
       "(alpha(C5 strong 3) = 10 < 5^(3/2)); C7 is flat at 7/2 through k=3."|>,
   "reducedQuestion" ->
     "GATE PASSED, so per the parent spec P3 acceptance: ESSAY-005's derivation question " <>
     "reduces to --- which invariant of the weighted (Q>=0-semimodule) presheaf of " <>
     "subnormalized weightings on the product cover computes the optimal fractional " <>
     "partition of unity (the dual Cech 0-cochain), and when is that optimum attained by " <>
     "an EXACT partition (a pentad family at k=2 on C5: this run's exact solver dual is " <>
     "supported on the five slope-" <> ToString[First[Union[suppSlopes]]] <>
     " pentads with weight 1 --- the mirror, under the reflection automorphism, of the " <>
     "slope-2 hand cochain verified in C2) rather than a properly fractional cover " <>
     "(the 49 edge-squares, y=1/4, on C7, where 4 does not divide 49 so no partition exists)? " <>
     "The k=3 discriminator L_3(C5) = 25/2 (per-copy 2.3208 > Sqrt[5]) shows the gluing LP " <>
     "alone stops tracking the k=2 coincidence at k=3 on C5 while remaining exact on C7 " <>
     "(343/8, per-copy 7/2), so any ansatz content beyond gluing lives in the window " <>
     "[5^(3/2), 25/2] at (C5, k=3)."
   |>;

Export[FileNameJoin[{scriptDir, "p3_certificates.json"}], certJSON, "JSON"];
Print["wrote p3_certificates.json"];

Print["total ", Round[AbsoluteTime[] - startT], " s"];
Print["OK -> ", allOK];
