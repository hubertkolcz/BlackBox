(* ::Package:: *)

(* ::Title:: *)
(*\:010cech Cohomology of the Support Presheaf: the Obstruction the Laplacian Could Not See*)

(* ::Subtitle:: *)
(*A pre-registered gate test on the three canonical C5 models \[LongDash] passed, with the method's honest boundary*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Companion to the pipeline's sheaf_laplacian.wl, whose own pre-registered gate REJECTED the cellular-sheaf Laplacian as a contextuality measure (harmonic residuals {0, 0, 0} on classical/quantum/Wright against CF {0, 2 Sqrt[5] - 4, 1}: linear least-squares over signed stalks sees exactly the no-disturbance layer and is provably blind to the cone condition where contextuality lives). That verdict pointed at the successor tool: the \:010cech obstruction of the SUPPORT presheaf (Abramsky-Mansfield-Barbosa, EPTCS 95; Abramsky-Barbosa-Kishida-Lal-Mansfield, "Contextuality, Cohomology and Paradox", arXiv:1502.03097; computed for Ulrey models in Cech-Cohomology-of-Ulrey-Models-AB-Sheaf.nb). This note is the gate test of that successor, now CechObstruction in the BlackBox paclet. Headless verification: wolframscript -file RunSupportCohomology.wl -print all (must end OK -> True).*)

(* ::Abstract:: *)
(*Linearize the support of an empirical model over the ring Z: over each context C, the free Z-module on the support sections; restriction = Z-linear extension of section restriction. A support section s is OBSTRUCTED when its class \[Gamma](s) in the first relative \:010cech cohomology is nonzero \[LongDash] equivalently (arXiv:1502.03097, Prop. 4.4) when no compatible family of Z-linear combinations of support sections restricts to s. \[Gamma](s) != 0 certifies that s extends to no global assignment (logical contextuality at s); \[Gamma] != 0 everywhere certifies strong contextuality. Pre-registered gate (semantics fixed before computation, attack-catalog style): ADOPT if the classical C5 model (1/5, 2/5, 2/5, 0) carries no obstruction, the Wright box a nonzero obstruction, and the quantum-maximal model is classified probabilistically contextual \[LongDash] the three models pairwise separated \[LongDash] where the Laplacian residual was blind ({0, 0, 0}); REJECT otherwise. Result: ADOPT. Classical 0/15 obstructed, quantum 0/15 (its support EQUALS the classical support \[LongDash] no support functional may separate them; the LP layer does), Wright 10/10: a cohomological certificate of strong contextuality. Corroboration: C7 (0/21 vs 14/14, |Se| = LucasL[7] = 29), even-cycle parity control (C6 Wright: 0/12, noncontextual), CHSH cross-validation against the literature (PR box 8/8; Hardy 0/13 with exactly one genuinely nonextendable section \[LongDash] the documented false negative of the Z-linear witness), and the two-copy product cover of ab_sheaf.wl (Wright\[CircleTimes]Wright 100/100, quantum\[CircleTimes]quantum 0/225, |Se| = 11^2). The absolute groups are computed too (CechCohomology, arbitrary covers, torsion by Smith normal form): the CHSH census reproduces the Ulrey-models notebook exactly, H^0 is multiplicative on the product cover (36 = 6^2), and the ambient H^1 \[LongDash] Z alike for the PR box and the noncontextual uniform model \[LongDash] confirms that the contextuality lives in the RELATIVE classes \[Gamma](s), nowhere else. The exact order of each class (\"ObstructionOrder\", by Smith normal form) sharpens the census: GHZ's sixteen classes all have order EXACTLY 2 \[LongDash] rationally invisible, pure relative 2-torsion, the homological face of Mermin's mod-2 argument \[LongDash] while the odd-cycle boxes are obstructed with infinite order and Hardy's false negative is integral (order 1).*)

(* ::Section:: *)
(*Setting*)

(* ::Text:: *)
(*CechObstruction[scen, e] decides \[Gamma](s) per support section by three exact steps: a deterministic global witness (a global assignment through s consistent with the whole support) forces \[Gamma](s) = 0, order 1; failing that, exact rank of the compatibility system refutes rational solvability \[LongDash] order Infinity; the residual cases get the EXACT ORDER of the class (the least n with n \[Gamma](s) = 0) from the Smith normal form of the pinned system, reported under "ObstructionOrder" \[LongDash] a finite order > 1 is pure relative torsion, invisible to any rational method. Everything is exact arithmetic; no floating point enters any verdict.*)

(* ::CodeText:: *)
(*Load the library and repair any Global`-shadowing:*)

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];

(* ::Section:: *)
(*The Pre-Registered Gate on C5*)

(* ::CodeText:: *)
(*The three canonical models, exact; the rejected Laplacian's residuals recomputed alongside for contrast:*)

(* ::Input:: *)
scen5 = CycleScenario[5];
{chC, chQ, chW} = CechObstruction[scen5, CycleModel[5, #]] & /@ {"Classical", "Quantum", "Wright"};
{gsC, gsQ, gsW} = GlobalSectionQ[scen5, N@CycleModel[5, #]] & /@ {"Classical", "Quantum", "Wright"};
cfs = ContextualFraction[scen5, N@CycleModel[5, #]] & /@ {"Classical", "Quantum", "Wright"};
residuals = HarmonicResidual[CycleCoboundary[5], N@CycleModel[5, #]] & /@ {"Classical", "Quantum", "Wright"};
klass[ch_, gs_] := Which[ch["CohStronglyContextual"], "strongly contextual (Cech certificate)",
  ch["CohLogicallyContextual"], "logically contextual (Cech certificate)",
  ! gs, "probabilistically contextual (LP layer; Cech silent)", True, "noncontextual"];
gateTable = MapThread[{#1, Row[{#2["ObstructedCount"], "/", #2["SectionCount"]}], Chop[#3, 10^-10], #4, Chop[#5, 10^-8], klass[#2, #4]} &,
  {{"classical", "quantum", "Wright"}, {chC, chQ, chW}, residuals, {gsC, gsQ, gsW}, cfs}];
TableForm[gateTable, TableHeadings -> {None, {"model", "\[Gamma] != 0", "Laplacian residual", "global section?", "CF", "classification"}}]

(* ::Text:: *)
(*The gate resolves exactly as pre-registered. Classical: no obstruction, global section exists. Wright: EVERY section obstructed \[LongDash] the parity mechanism is visible by hand: with support {01, 10} per context, compatibility at each overlap forces the coefficient swap (a, b) -> (b, a), and an odd cycle of swaps returns (b, a) = (a, b) with a = 1, b = 0 \[LongDash] a contradiction over every ring, so \[Gamma](s) != 0 certifies strong contextuality with no LP call. Quantum: 0/15, and this is the THEOREM, not a disappointment \[LongDash] the quantum support {00, 01, 10} per context is identical to the classical support, so every functional of the support agrees on the two models; the quantum model's contextuality is genuinely probabilistic (global section over R>=0 fails, CF = 2 Sqrt[5] - 4), which is the LP layer's jurisdiction (NoncontextualFraction). The pair (\[Gamma], GlobalSectionQ) separates the triple pairwise; the Laplacian column is {0, 0, 0} on the same three models.*)

(* ::Section:: *)
(*The Heptagon, and the Parity Control*)

(* ::CodeText:: *)
(*n = 7: same stratification (quantum support extends, |Se| = LucasL[7] = 29 global assignments; Wright box 14/14 obstructed). n = 6 control: the even-cycle Wright box is 2-colorable, hence noncontextual \[LongDash] the obstruction must and does vanish:*)

(* ::Input:: *)
scen7 = CycleScenario[7];
{chC7, chQ7, chW7} = CechObstruction[scen7, CycleModel[7, #]] & /@ {"Classical", "Quantum", "Wright"};
chW6 = CechObstruction[CycleScenario[6], CycleModel[6, "Wright"]];
TableForm[{
  {"C7 classical", Row[{chC7["ObstructedCount"], "/", chC7["SectionCount"]}], chC7["GlobalSupportSize"]},
  {"C7 quantum", Row[{chQ7["ObstructedCount"], "/", chQ7["SectionCount"]}], chQ7["GlobalSupportSize"]},
  {"C7 Wright", Row[{chW7["ObstructedCount"], "/", chW7["SectionCount"]}], chW7["GlobalSupportSize"]},
  {"C6 Wright", Row[{chW6["ObstructedCount"], "/", chW6["SectionCount"]}], chW6["GlobalSupportSize"]}},
 TableHeadings -> {None, {"model", "\[Gamma] != 0", "|Se|"}}]

(* ::Text:: *)
(*The odd/even dichotomy is the cohomology doing what cohomology does: the Wright support is the twisted double cover of the cycle, nontrivial exactly when the cycle is odd. The heptagon numbers matter beyond the control: the heptagon box is the model that Consistent Exclusivity cannot expel at 2-3 identical copies (Choudhary-Barbosa, arXiv:2411.09773; HeptagonCatalysis.wl) \[LongDash] yet the single-copy \:010cech certificate convicts it outright, at all 14 sections.*)

(* ::Section:: *)
(*CHSH Cross-Validation: the PR Box, and Hardy as the Documented False Negative*)

(* ::CodeText:: *)
(*The 4-cycle is the CHSH scenario (measurements a1, b1, a2, b2 around the cycle). The PR box must come out obstructed at all 8 sections (arXiv:1502.03097, Sec. 4); the Hardy model \[LongDash] exact rationals from the state (|00> + |01> + |10>)/Sqrt[3] with X/Z measurements \[LongDash] is the canonical FALSE NEGATIVE: logically contextual (its (a1, b1) = (0, 0) section extends to no global assignment), yet \[Gamma] vanishes everywhere:*)

(* ::Input:: *)
scen4 = CycleScenario[4];
ePR = Flatten[{{1/2, 0, 0, 1/2}, {1/2, 0, 0, 1/2}, {1/2, 0, 0, 1/2}, {0, 1/2, 1/2, 0}}];
eHardy = Flatten[{{1/12, 1/12, 1/12, 3/4}, {0, 1/6, 2/3, 1/6}, {1/3, 1/3, 1/3, 0}, {0, 2/3, 1/6, 1/6}}];
chPR = CechObstruction[scen4, ePR]; chH = CechObstruction[scen4, eHardy];
{Row[{"PR: ", chPR["ObstructedCount"], "/", chPR["SectionCount"], ", strong certificate: ", chPR["CohStronglyContextual"]}],
 Row[{"Hardy: ", chH["ObstructedCount"], "/", chH["SectionCount"], ", nonextendable: ", chH["NonextendableSections"], ", false negatives: ", chH["FalseNegatives"]}]}

(* ::Text:: *)
(*Both agree with the published census (and with the Ulrey-models notebook, including rank H^0 = 6 for Hardy against 5 consistent global assignments). The Hardy false negative is the method's honest boundary, stated up front: \[Gamma](s) = 0 means a Z-LINEAR compatible family exists, and integer coefficients of mixed sign can conspire where no possibilistic (Boolean) extension does. The witness is one-directional \[LongDash] \[Gamma] != 0 convicts; \[Gamma] = 0 acquits nobody. CechObstruction therefore also reports "NonextendableSections" (ground truth by exhaustive check) and "FalseNegatives" as machine-checkable bookkeeping.*)

(* ::Section:: *)
(*The Two-Copy Product Cover of ab_sheaf.wl*)

(* ::CodeText:: *)
(*The product scenario: 10 measurements, 25 contexts edge x edge \[LongDash] the FIXED product cover of ab_sheaf.wl Sec. 3, the one that cannot expel the Wright product at the probabilistic no-disturbance level. CoverScenario handles the arbitrary cover; the product model multiplies edge distributions:*)

(* ::Input:: *)
edges5 = Table[{i, Mod[i + 1, 5]}, {i, 0, 4}];
scenProd = CoverScenario[Join[Table[{1, i}, {i, 0, 4}], Table[{2, i}, {i, 0, 4}]],
  Flatten[Table[{{1, ed[[1]]}, {1, ed[[2]]}, {2, f[[1]]}, {2, f[[2]]}}, {ed, edges5}, {f, edges5}], 1]];
prodModel[m1_, m2_] := With[{d1 = AssociationThread[Tuples[{0, 1}, 2] -> m1[[1 ;; 4]]],
   d2 = AssociationThread[Tuples[{0, 1}, 2] -> m2[[1 ;; 4]]]},
  Flatten[Table[d1[s[[1 ;; 2]]] d2[s[[3 ;; 4]]], {c, scenProd["Contexts"]}, {s, Tuples[{0, 1}, 4]}]]];
chWW = CechObstruction[scenProd, prodModel[CycleModel[5, "Wright"], CycleModel[5, "Wright"]]];
chQQ = CechObstruction[scenProd, prodModel[CycleModel[5, "Quantum"], CycleModel[5, "Quantum"]]];
{Row[{"Wright\[CircleTimes]Wright: ", chWW["ObstructedCount"], "/", chWW["SectionCount"], ", strong certificate: ", chWW["CohStronglyContextual"]}],
 Row[{"quantum\[CircleTimes]quantum: ", chQQ["ObstructedCount"], "/", chQQ["SectionCount"], ", |Se| = ", chQQ["GlobalSupportSize"]}]}

(* ::Text:: *)
(*Reading. On the fixed product cover \[LongDash] no pentad extension, no composite observable \[LongDash] the cohomological layer already expels the Wright product at every one of the 100 product sections: any compatible Z-linear product family would marginalize (sum coefficients over one copy's outcomes) to a single-copy compatible family, which the single-copy obstruction forbids. This is complementary to ab_sheaf.wl Sec. 3, where the QM-certified pentad extension kills the same model one level lower (local existence at C^0, remainder -1/4); and it is invisible to the GE/CE single-copy cap alpha* = 5/2, which admits the Wright box. The quantum product stays clean: 0/225 obstructed, |Se| = 121 = 11^2 \[LongDash] the product of the two Lucas-11 independent-set families, exactly as product structure demands.*)

(* ::Section:: *)
(*The GHZ Model, and the All-vs-Nothing Layer*)

(* ::Text:: *)
(*The other half of arXiv:1502.03097 (Sec. 6) is the All-vs-Nothing argument: collect every Z2-affine equation satisfied by ALL support sections of a context; the model is AvN when the joint theory is inconsistent. AvN certifies strong contextuality, and every AvN model is cohomologically strongly contextual \[LongDash] so AvN implies the \[Gamma]-certificate, and the two layers must agree wherever AvN fires. GHZ is the canonical AvN model and the canonical NON-CYCLE cover \[LongDash] three parties, X or Y each: exactly what CoverScenario exists for.*)

(* ::CodeText:: *)
(*The Mermin scenario and the GHZ model (parity 0 on XXX, parity 1 on the three XYY permutations); the theory is the four textbook equations, and their sum is 0 = 1:*)

(* ::Input:: *)
ghzScen = CoverScenario[{"aX", "aY", "bX", "bY", "cX", "cY"},
  {{"aX", "bX", "cX"}, {"aX", "bY", "cY"}, {"aY", "bX", "cY"}, {"aY", "bY", "cX"}}];
ghzModel = Flatten[Table[If[Mod[Total[s], 2] == par, 1/4, 0], {par, {0, 1, 1, 1}}, {s, Tuples[{0, 1}, 3]}]];
chGHZ = CechObstruction[ghzScen, ghzModel]; avnGHZ = AvNArgument[ghzScen, ghzModel];
{Row[{"GHZ \[Gamma]: ", chGHZ["ObstructedCount"], "/", chGHZ["SectionCount"], ", strong certificate: ", chGHZ["CohStronglyContextual"], ", |Se| = ", chGHZ["GlobalSupportSize"]}],
 Row[{"GHZ AvN: ", avnGHZ["AvN"], ", equations: "}], avnGHZ["Equations"],
 Row[{"GHZ obstruction orders (tally): ", Tally[Values[chGHZ["ObstructionOrder"]]]}]}

(* ::Text:: *)
(*The order column is the sharpest number in this note: every GHZ class has order EXACTLY 2 \[LongDash] \[Gamma](s) != 0 but 2 \[Gamma](s) = 0. The pinned compatibility system is rationally solvable (a rational method sees nothing), and the obstruction is pure 2-torsion of the relative cohomology: the mod-2 heart of the Mermin argument, now as an exact homological invariant. Contrast the whole rest of the census: Wright, PR and the Z3 box have infinite order (already obstructed over Q \[LongDash] the parity contradictions survive in every characteristic 0 ring), and Hardy's classes have order 1 (its Z-linear extension is genuinely integral). GHZ is the only model here that NEEDS the ring Z: over Q its obstruction is invisible, over Z_2 it is the AvN argument above.*)

(* ::CodeText:: *)
(*AvN across the whole census, with the cohomological strong certificate alongside \[LongDash] the implication AvN \[Implies] CSC holds row by row (the converse direction is not claimed: CSC models without parity structure exist outside this census):*)

(* ::Input:: *)
avnRows = {{"C5 classical", scen5, CycleModel[5, "Classical"], chC}, {"C5 quantum", scen5, CycleModel[5, "Quantum"], chQ},
   {"C5 Wright", scen5, CycleModel[5, "Wright"], chW}, {"C6 Wright", CycleScenario[6], CycleModel[6, "Wright"], chW6},
   {"PR box", scen4, ePR, chPR}, {"Hardy", scen4, eHardy, chH}, {"GHZ", ghzScen, ghzModel, chGHZ},
   {"Wright\[CircleTimes]Wright", scenProd, prodModel[CycleModel[5, "Wright"], CycleModel[5, "Wright"]], chWW},
   {"quantum\[CircleTimes]quantum", scenProd, prodModel[CycleModel[5, "Quantum"], CycleModel[5, "Quantum"]], chQQ}};
avnTable = Module[{a}, Table[a = AvNArgument[r[[2]], r[[3]]];
    {r[[1]], a["EquationCount"], a["AvN"], r[[4]]["CohStronglyContextual"], ! a["AvN"] || r[[4]]["CohStronglyContextual"]}, {r, avnRows}]];
TableForm[avnTable, TableHeadings -> {None, {"model", "equations", "AvN", "CSC", "AvN \[Implies] CSC"}}]

(* ::Text:: *)
(*Reading. The AvN layer is the cheap end of the hierarchy \[LongDash] no cohomology, no LP, just parity bookkeeping over GF(2) \[LongDash] and it convicts GHZ, the Wright boxes (odd cycles and their products; the 5 equations x_i + x_{i+1} = 1 around C5 are the parity argument verbatim), and the PR box. It correctly refuses the Hardy model (no nontrivial equations survive its support), whose strong contextuality fails and whose \[Gamma] is the documented false negative one level up. The even-cycle control C6 carries 6 equations that ARE jointly satisfiable \[LongDash] AvN distinguishes odd from even for the same local data, exactly as the cohomology does.*)

(* ::Section:: *)
(*Beyond Binary: a Z3 Box on the Square*)

(* ::Text:: *)
(*CoverScenario accepts per-measurement outcome sets, and both \:010cech functions are outcome-agnostic (the obstruction's overlap equations range over the declared outcomes; the cohomology is built from restriction images). The demonstration model: three-outcome measurements on the 4-cycle, support y - x = 0 (mod 3) on three edges and y - x = 1 on the fourth \[LongDash] the Z3 analogue of the PR box. One honest scope note: the pentad-extended cover of ab_sheaf.wl Sec. 3 is NOT the multi-outcome showcase, deliberately \[LongDash] its composite 6-outcome context shares no measurement with the product contexts, so the Wright product dies there at local existence (C^0, remainder -1/4), before any gluing question; that phenomenon is already settled in ab_sheaf.wl.*)

(* ::Input:: *)
z3Scen = CoverScenario[Range[0, 3], Table[{i, Mod[i + 1, 4]}, {i, 0, 3}], Range[0, 2]];
z3Model = Flatten[Table[If[Mod[s[[2]] - s[[1]], 3] == If[c == 3, 1, 0], 1/3, 0],
   {c, 0, 3}, {s, Tuples[Range[0, 2], 2]}]];
chZ3 = CechObstruction[z3Scen, z3Model]; avnZ3 = AvNArgument[z3Scen, z3Model, 3];
z3Ctl = Flatten[Table[If[Mod[s[[2]] - s[[1]], 3] == 0, 1/3, 0], {c, 0, 3}, {s, Tuples[Range[0, 2], 2]}]];
chZ3c = CechObstruction[z3Scen, z3Ctl];
{Row[{"Z3 box \[Gamma]: ", chZ3["ObstructedCount"], "/", chZ3["SectionCount"], ", strong certificate: ", chZ3["CohStronglyContextual"]}],
 Row[{"Z3 box AvN over GF(3): ", avnZ3["AvN"], ", equations: "}], avnZ3["Equations"],
 Row[{"unshifted control: \[Gamma] ", chZ3c["ObstructedCount"], "/", chZ3c["SectionCount"], ", |Se| = ", chZ3c["GlobalSupportSize"], ", global section: ", GlobalSectionQ[z3Scen, N@z3Ctl]}]}

(* ::Text:: *)
(*The shifted box is convicted twice over: every one of the 12 support sections is \[Gamma]-obstructed (the compatibility system forces the coefficient vector around the cycle through one shift, and a pinned generator cannot return to itself), and the GF(3) theory {x + 2y \[Congruent] 0, 0, 0, 2} sums to 0 \[Congruent] 2. The unshifted control extends (|Se| = 3, a nonnegative global section exists) \[LongDash] same local outcome sets, same marginals, opposite verdict, which is what a certificate is for.*)

(* ::Section:: *)
(*The Kochen-Specker Covers: the Peres-Mermin Square and the 18-Vector Set*)

(* ::Text:: *)
(*State-INDEPENDENT contextuality through the same stack. The Peres-Mermin square: nine binary measurements on a 3x3 grid, six contexts (rows and columns), support parities (0,0,0) on rows and (0,0,1) on columns \[LongDash] the magic square. The Cabello-Estebaranz-Garc\[IAcute]a-Alcaine 18-vector set (PLA 212, 183 (1996)): eighteen rays of R^4 in nine orthogonal tetrads, each ray in exactly two tetrads; measurements = rays (does it fire?), support = the exactly-one-fires sections. The geometry is machine-verified before anything is computed. The 18-ray scenario association is built directly (its incidence matrix, 144 x 2^18, is never needed by the \:010cech layer).*)

(* ::Input:: *)
pmX = Flatten[Table[{i, j}, {i, 3}, {j, 3}], 1];
pmCover = Join[Table[Table[{i, j}, {j, 3}], {i, 3}], Table[Table[{i, j}, {i, 3}], {j, 3}]];
pmParity = {0, 0, 0, 0, 0, 1};
pmScen = CoverScenario[pmX, pmCover];
pmModel = Flatten[Table[If[Mod[Total[s], 2] == pmParity[[k]], 1/4, 0], {k, 6}, {s, Tuples[{0, 1}, 3]}]];
chPM = CechObstruction[pmScen, pmModel]; avnPM = AvNArgument[pmScen, pmModel]; ccPM = CechCohomology[pmScen, pmModel];
tetrads = {
  {{0,0,0,1},{0,0,1,0},{1,1,0,0},{1,-1,0,0}}, {{0,0,0,1},{0,1,0,0},{1,0,1,0},{1,0,-1,0}},
  {{1,-1,1,-1},{1,-1,-1,1},{1,1,0,0},{0,0,1,1}}, {{1,-1,1,-1},{1,1,1,1},{1,0,-1,0},{0,1,0,-1}},
  {{0,0,1,0},{0,1,0,0},{1,0,0,1},{1,0,0,-1}}, {{1,-1,-1,1},{1,1,1,1},{1,0,0,-1},{0,1,-1,0}},
  {{1,1,-1,1},{1,1,1,-1},{1,-1,0,0},{0,0,1,1}}, {{1,1,-1,1},{-1,1,1,1},{1,0,1,0},{0,1,0,-1}},
  {{1,1,1,-1},{-1,1,1,1},{1,0,0,1},{0,1,-1,0}}};
canon[v_] := With[{w = v/GCD @@ v}, If[First[DeleteCases[w, 0]] < 0, -w, w]];
ctxs18 = Map[canon, tetrads, {2}]; rays = DeleteDuplicates[Flatten[ctxs18, 1]];
cegGeometry = Length[rays] == 18 &&
   AllTrue[ctxs18, AllTrue[Subsets[#, {2}], #[[1]] . #[[2]] == 0 &] &] &&
   Union[Tally[Flatten[ctxs18, 1]][[All, 2]]] === {2};
scen18 = <|"X" -> rays, "Outcomes" -> Association[# -> {0, 1} & /@ rays], "Contexts" -> ctxs18,
   "Sections" -> Flatten[Table[{c, s}, {c, ctxs18}, {s, Tuples[{0, 1}, 4]}], 1],
   "Assignments" -> Tuples[{0, 1}, 18]|>;
e18 = Flatten[Table[If[Total[s] == 1, 1/4, 0], {c, ctxs18}, {s, Tuples[{0, 1}, 4]}]];
ch18 = CechObstruction[scen18, e18]; avn18 = AvNArgument[scen18, e18]; cc18 = CechCohomology[scen18, e18];
ksTable = MapThread[{#1, cegGeometry, Row[{#2["ObstructedCount"], "/", #2["SectionCount"]}],
    Tally[Values[#2["ObstructionOrder"]]], #2["GlobalSupportSize"], #3["AvN"], #3["EquationCount"], #4["ComplexCloses"]} &,
  {{"Peres-Mermin", "CEG 18-ray"}, {chPM, ch18}, {avnPM, avn18}, {ccPM, cc18}}];
TableForm[ksTable, TableHeadings -> {None, {"model", "geometry ok", "\[Gamma] != 0", "orders", "|Se|", "AvN", "eqs", "\[Delta]1\[Delta]0 = 0"}}]

(* ::Text:: *)
(*Both are convicted at every level, and both AvN theories are the TEXTBOOK proofs recovered mechanically: the six magic-square equations (row sums 0, column sums 0,0,1 \[LongDash] total 0 = 1) and the nine tetrad equations Sum x = 1 (each ray counted twice, nine odd right-hand sides \[LongDash] 0 = 1 again). The order column extends the GHZ discovery to a DICHOTOMY across this whole census: every state-independent parity model (GHZ, Peres-Mermin, the 18 rays) has all its obstruction classes of order EXACTLY 2 \[LongDash] rationally invisible, pure relative 2-torsion \[LongDash] while every box model (Wright, PR, Z3) is obstructed with infinite order, visible already over Q. The certificate stack separates the two known mechanisms of strong contextuality without being told about them.*)

(* ::Section:: *)
(*The Absolute Groups: H^0 and H^1 of the Linearized Support Presheaf*)

(* ::Text:: *)
(*CechCohomology[scen, e] computes the ambient groups themselves: H^0 = the module of compatible Z-linear families (its rank counts independent global sections of the linearization), and H^1 = ker \[Delta]1 / im \[Delta]0 with torsion read off the Smith normal form of \[Delta]0 \[LongDash] valid on ARBITRARY covers, because the C^2 term over triple overlaps is included and the identity \[Delta]1 . \[Delta]0 = 0 is verified, not assumed (key "ComplexCloses"). Two cautions frame the numbers. First, the obstruction classes \[Gamma](s) of CechObstruction live in the RELATIVE H^1, not here: on the CHSH cover the strongly contextual PR box and the noncontextual uniform model BOTH have H^1 = Z, so the absolute group is not a contextuality certificate. Second, H^0 is the sharper ambient invariant: 6 for both C5 supports, 1 for the Wright box, and multiplicative on products.*)

(* ::CodeText:: *)
(*The census, one row per model of this note (CHSH rows reproduce the Ulrey-models notebook exactly, including rank H^0 = 6 for Hardy and H^1 = Z with no torsion throughout):*)

(* ::Input:: *)
ccC = CechCohomology[scen5, CycleModel[5, "Classical"]];
ccQ = CechCohomology[scen5, CycleModel[5, "Quantum"]];
ccW = CechCohomology[scen5, CycleModel[5, "Wright"]];
ccU = CechCohomology[scen4, ConstantArray[1/4, 16]];
ccPR = CechCohomology[scen4, ePR]; ccH = CechCohomology[scen4, eHardy];
ccW6 = CechCohomology[CycleScenario[6], CycleModel[6, "Wright"]];
ccG = CechCohomology[ghzScen, ghzModel];
ccWW = CechCohomology[scenProd, prodModel[CycleModel[5, "Wright"], CycleModel[5, "Wright"]]];
ccQQ = CechCohomology[scenProd, prodModel[CycleModel[5, "Quantum"], CycleModel[5, "Quantum"]]];
cohomTable = MapThread[{#1, #2["CochainRanks"], #2["H0Rank"], #2["H1FreeRank"], #2["H1Torsion"], #2["ComplexCloses"]} &,
  {{"C5 classical", "C5 quantum", "C5 Wright", "C6 Wright", "CHSH uniform", "PR box", "Hardy", "GHZ", "Wright\[CircleTimes]Wright", "quantum\[CircleTimes]quantum"},
   {ccC, ccQ, ccW, ccW6, ccU, ccPR, ccH, ccG, ccWW, ccQQ}}];
TableForm[cohomTable, TableHeadings -> {None, {"model", "{C0, C1, C2}", "rk H0", "rk H1", "H1 torsion", "\[Delta]1\[Delta]0 = 0"}}]

(* ::Text:: *)
(*Structure worth recording: (i) H^0 is multiplicative on the product cover \[LongDash] 36 = 6^2 for quantum\[CircleTimes]quantum, 1 = 1^2 for Wright\[CircleTimes]Wright; (ii) on every single-cycle cover of this census H^1 has free rank 1 (the nerve circle) except C6 Wright where it is 2 \[LongDash] the group remembers the support, not just the nerve; (iii) on the product cover the C^2 correction kills H^1 entirely (free rank 0), so all the contextuality information there sits in the relative layer, exactly where CechObstruction reads it; (iv) no torsion appears anywhere in this ABSOLUTE census, but the RELATIVE classes do carry it: every GHZ obstruction class has order exactly 2 (\"ObstructionOrder\" in CechObstruction), while Hardy's nonextendable section has order 1 \[LongDash] its false negative is integral, not an artifact of working over Q.*)

(* ::Section:: *)
(*Beyond Prime Moduli: AvN over Z4*)

(* ::Text:: *)
(*The All-vs-Nothing layer works over any Z_d, d >= 2 \[LongDash] not only prime fields. For composite d, Z_d is not a field and \"rank over Z_d\" is ill-posed; consistency of the theory is decided instead by exact lattice solvability (Smith normal form of the integer coefficient matrix), which reduces to the GF(d) rank test exactly when d is prime. Two things change for composite d: the theory keeps equations with NON-unit coefficient vectors \[LongDash] the 2x = 2 (mod 4) relations that a prime reduction cannot express \[LongDash] and the resulting witness can be genuinely modular. The demonstration: the Z4 shift box on the square, support y - x = 0 (mod 4) on three edges and y - x = 2 on the fourth.*)

(* ::Input:: *)
z4Scen = CoverScenario[Range[0, 3], Table[{i, Mod[i + 1, 4]}, {i, 0, 3}], Range[0, 3]];
z4Model = Flatten[Table[If[Mod[s[[2]] - s[[1]], 4] == If[c == 3, 2, 0], 1/4, 0], {c, 0, 3}, {s, Tuples[Range[0, 3], 2]}]];
avnZ4 = AvNArgument[z4Scen, z4Model, 4];
z4A = Table[Module[{row = ConstantArray[0, 4]}, MapThread[(row[[#1 + 1]] = #2) &, {eq[[1]], eq[[2]]}]; row], {eq, avnZ4["Equations"]}];
z4b = avnZ4["Equations"][[All, 3]];
z4Mod2 = MatrixRank[z4A, Modulus -> 2] == MatrixRank[MapThread[Append, {z4A, z4b}], Modulus -> 2];
{Row[{"Z4 shift box AvN over Z4: ", avnZ4["AvN"], ", ", avnZ4["EquationCount"], " equations"}],
 Row[{"contains a non-unit (all-even) coefficient equation: ", AnyTrue[avnZ4["Equations"], #[[2]] =!= {0, 0} && AllTrue[#[[2]], EvenQ] &]}],
 Row[{"same equation system is CONSISTENT mod 2 (the witness is genuinely Z4): ", z4Mod2}],
 Row[{"unshifted control extends: ", ! AvNArgument[z4Scen, Flatten[Table[If[Mod[s[[2]] - s[[1]], 4] == 0, 1/4, 0], {c, 0, 3}, {s, Tuples[Range[0, 3], 2]}]], 4]["AvN"]}]}

(* ::Text:: *)
(*The certificate is a strict Z4 phenomenon: the shift sum around the cycle equals 2, so the theory is inconsistent mod 4 (0 = 2), yet reducing the SAME integer equation system mod 2 turns the right-hand side to 0 and the system becomes solvable \[LongDash] no prime-modulus AvN argument could have detected it. The unit-coefficient equations alone would give only the mod-2 shadow; the all-even equations 2x = 2 (mod 4), which the prime path discards, are exactly what carries the obstruction. AvN over composite rings is therefore strictly stronger than the union of its prime-field reductions.*)

(* ::Section:: *)
(*The Relative Group, Where \[Gamma] Actually Lives*)

(* ::Text:: *)
(*The final layer: H^1 of the relative presheaf F~ = ker(F -> F|C0) itself, as a group (CechRelativeCohomology). Its cochain modules are spanned by DIFFERENCES of support sections agreeing on the overlap with the distinguished context, so F~(C0) = 0 \[LongDash] and that single fact makes the construction self-validating: a lift of a section s of C0 to a compatible family must have C0-component exactly s, so the order of the explicit connecting cocycle \[Gamma](s) = \[Delta]0(lift) in H^1(F~) MUST equal CechObstruction's independently computed \"ObstructionOrder\". The table checks this for every section, at two different choices of C0 per model.*)

(* ::Input:: *)
relRows = {{"C5 classical", scen5, CycleModel[5, "Classical"], chC, 1}, {"C5 Wright", scen5, CycleModel[5, "Wright"], chW, 1},
   {"PR box", scen4, ePR, chPR, 4}, {"Hardy", scen4, eHardy, chH, 2}, {"GHZ", ghzScen, ghzModel, chGHZ, 1},
   {"Peres-Mermin", pmScen, pmModel, chPM, 6}, {"CEG 18-ray", scen18, e18, ch18, 1}};
relTable = Table[Module[{rel = CechRelativeCohomology[r[[2]], r[[3]], r[[5]]], match},
    match = And @@ Table[rel["GammaOrders"][s0] === r[[4]]["ObstructionOrder"][{r[[2]]["Contexts"][[r[[5]]]], s0}],
       {s0, Keys[rel["GammaOrders"]]}];
    {r[[1]], rel["H1FreeRank"], rel["H1Torsion"], Tally[Values[rel["GammaOrders"]]],
     rel["GammaCocyclesVerified"] && rel["ComplexCloses"], match}], {r, relRows}];
TableForm[relTable, TableHeadings -> {None, {"model (c0)", "rk H1(F~)", "torsion", "\[Gamma] orders", "cocycles+closes", "= ObstructionOrder"}}]

(* ::Text:: *)
(*The relative group is the contextuality group of the model, exactly. For the parity models \[LongDash] GHZ, the Peres-Mermin square, the 18 rays \[LongDash] H^1(F~) \[TildeEqual] Z/2: one two-torsion class, and every \[Gamma](s) hits it. For the box models H^1(F~) \[TildeEqual] Z and the classes have infinite order. For the classical model and for Hardy the group answer is even sharper than the false-negative bookkeeping: H^1(F~) = 0 \[LongDash] Hardy's \[Gamma] does not merely happen to vanish, it lives in a TRIVIAL group; no choice of coefficients in this presheaf could ever have detected it. The census of absolute groups was topology plus support; the relative group is the obstruction theory itself, and its dichotomy Z/2 vs Z is the torsion dichotomy of the orders section restated structurally.*)

(* ::Section:: *)
(*Verification*)

(* ::Input:: *)
SupportCohomologyVerification = <|
  "gateClassicalNoObstruction" -> chC["ObstructedCount"] == 0 && chC["SectionCount"] == 15 && gsC,
  "gateQuantumProbabilisticOnly" -> chQ["ObstructedCount"] == 0 && ! gsQ && Abs[cfs[[2]] - (2 Sqrt[5.] - 4)] < 10^-8,
  "gateWrightObstructed" -> chW["ObstructedCount"] == 10 && chW["CohStronglyContextual"] && ! gsW,
  "gateTripleDistinguished" -> Length[DeleteDuplicates[
      {#1["ObstructedCount"] > 0, #2} & @@@ {{chC, gsC}, {chQ, gsQ}, {chW, gsW}}]] == 3,
  "laplacianBlindOnSameTriple" -> AllTrue[residuals, # < 10^-10 &],
  "quantumClassicalSupportsEqual" -> chQ["SupportSizes"] == chC["SupportSizes"] == {3, 3, 3, 3, 3},
  "heptagon" -> chW7["ObstructedCount"] == 14 && chQ7["ObstructedCount"] == 0 &&
     chC7["ObstructedCount"] == 0 && chQ7["GlobalSupportSize"] == LucasL[7],
  "parityControlC6" -> chW6["ObstructedCount"] == 0 && chW6["GlobalSupportSize"] == 2,
  "prBoxMatchesCCP" -> chPR["ObstructedCount"] == 8 && chPR["CohStronglyContextual"],
  "hardyFalseNegative" -> chH["ObstructedCount"] == 0 && chH["LogicallyContextual"] &&
     chH["FalseNegatives"] === {{{0, 1}, {0, 0}}} && chH["H0Rank"] == 6,
  "productWrightExpelled" -> chWW["ObstructedCount"] == 100 && chWW["CohStronglyContextual"],
  "productQuantumSilent" -> chQQ["ObstructedCount"] == 0 && chQQ["GlobalSupportSize"] == 121,
  "ghzAllObstructed" -> chGHZ["ObstructedCount"] == 16 && chGHZ["CohStronglyContextual"] &&
     chGHZ["GlobalSupportSize"] == 0,
  "ghzOrderExactlyTwo" -> AllTrue[Values[chGHZ["ObstructionOrder"]], # === 2 &],
  "ordersElsewhere" -> AllTrue[Values[chW["ObstructionOrder"]], # === Infinity &] &&
     AllTrue[Values[chPR["ObstructionOrder"]], # === Infinity &] &&
     AllTrue[Values[chZ3["ObstructionOrder"]], # === Infinity &] &&
     AllTrue[Values[chH["ObstructionOrder"]], # === 1 &],
  "ghzAvNMermin" -> avnGHZ["AvN"] && avnGHZ["EquationCount"] == 4 &&
     avnGHZ["Equations"][[All, 3]] === {0, 1, 1, 1},
  "avnCensusPattern" -> avnTable[[All, 3]] === {False, False, True, False, True, False, True, True, False},
  "avnImpliesCSC" -> AllTrue[avnTable[[All, 5]], TrueQ],
  "z3BoxConvictedTwice" -> chZ3["ObstructedCount"] == 12 && chZ3["CohStronglyContextual"] &&
     avnZ3["AvN"] && avnZ3["Equations"][[All, 3]] === {0, 0, 0, 2},
  "ksGeometryVerified" -> cegGeometry,
  "ksPeresMermin" -> chPM["ObstructedCount"] == 24 && chPM["CohStronglyContextual"] &&
     chPM["GlobalSupportSize"] == 0 && avnPM["AvN"] && avnPM["EquationCount"] == 6 &&
     AllTrue[Values[chPM["ObstructionOrder"]], # === 2 &],
  "ksCEG18" -> ch18["ObstructedCount"] == 36 && ch18["CohStronglyContextual"] &&
     ch18["GlobalSupportSize"] == 0 && avn18["AvN"] && avn18["EquationCount"] == 9 &&
     AllTrue[Values[ch18["ObstructionOrder"]], # === 2 &],
  "torsionDichotomy" -> AllTrue[Join[Values[chGHZ["ObstructionOrder"]], Values[chPM["ObstructionOrder"]],
       Values[ch18["ObstructionOrder"]]], # === 2 &] &&
     AllTrue[Join[Values[chW["ObstructionOrder"]], Values[chPR["ObstructionOrder"]],
       Values[chZ3["ObstructionOrder"]]], # === Infinity &],
  "z3ControlExtends" -> chZ3c["ObstructedCount"] == 0 && chZ3c["GlobalSupportSize"] == 3 &&
     GlobalSectionQ[z3Scen, N@z3Ctl],
  "avnCompositeZ4" -> avnZ4["AvN"] && avnZ4["EquationCount"] == 8 && z4Mod2 &&
     AnyTrue[avnZ4["Equations"], #[[2]] =!= {0, 0} && AllTrue[#[[2]], EvenQ] &],
  "cohomCensusMatchesUlreyNotebook" -> ({#["H0Rank"], #["H1FreeRank"], #["H1Torsion"]} & /@ {ccU, ccPR, ccH}) ===
     {{9, 1, {}}, {1, 1, {}}, {6, 1, {}}},
  "cohomComplexCloses" -> AllTrue[{ccC, ccQ, ccW, ccW6, ccU, ccPR, ccH, ccG, ccWW, ccQQ}, #["ComplexCloses"] &],
  "cohomH0Multiplicative" -> ccQQ["H0Rank"] == ccQ["H0Rank"]^2 && ccWW["H0Rank"] == ccW["H0Rank"]^2,
  "cohomProductH1Vanishes" -> ccWW["H1FreeRank"] == 0 && ccQQ["H1FreeRank"] == 0 &&
     ccWW["CochainRanks"] == {100, 700, 2200},
  "cohomNoTorsionInCensus" -> AllTrue[{ccC, ccQ, ccW, ccW6, ccU, ccPR, ccH, ccG, ccWW, ccQQ}, #["H1Torsion"] === {} &],
  "relativeGroupDichotomy" -> relTable[[All, 2 ;; 3]] ===
     {{0, {}}, {1, {}}, {1, {}}, {0, {}}, {0, {2}}, {0, {2}}, {0, {2}}},
  "relativeOrdersMatchObstruction" -> AllTrue[relTable[[All, 6]], TrueQ] &&
     AllTrue[relTable[[All, 5]], TrueQ],
  "verdict" -> "ADOPT: the support-presheaf Cech obstruction joins the core as the possibilistic-layer certificate; the Laplacian stays a no-disturbance projector only"
|>;
SupportCohomologyVerification["OK"] = And @@ Cases[Values[SupportCohomologyVerification], _?BooleanQ];
SupportCohomologyVerification
