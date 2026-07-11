(* ::Package:: *)

(* ::Title:: *)
(*\:010cech Cohomology of the Support Presheaf: the Obstruction the Laplacian Could Not See*)

(* ::Subtitle:: *)
(*A pre-registered gate test on the three canonical C5 models \[LongDash] passed, with the method's honest boundary*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Companion to the pipeline's sheaf_laplacian.wl, whose own pre-registered gate REJECTED the cellular-sheaf Laplacian as a contextuality measure (harmonic residuals {0, 0, 0} on classical/quantum/Wright against CF {0, 2 Sqrt[5] - 4, 1}: linear least-squares over signed stalks sees exactly the no-disturbance layer and is provably blind to the cone condition where contextuality lives). That verdict pointed at the successor tool: the \:010cech obstruction of the SUPPORT presheaf (Abramsky-Mansfield-Barbosa, EPTCS 95; Abramsky-Barbosa-Kishida-Lal-Mansfield, "Contextuality, Cohomology and Paradox", arXiv:1502.03097; computed for Ulrey models in Cech-Cohomology-of-Ulrey-Models-AB-Sheaf.nb). This note is the gate test of that successor, now CechObstruction in the BlackBox paclet. Headless verification: wolframscript -file RunSupportCohomology.wl -print all (must end OK -> True).*)

(* ::Abstract:: *)
(*Linearize the support of an empirical model over the ring Z: over each context C, the free Z-module on the support sections; restriction = Z-linear extension of section restriction. A support section s is OBSTRUCTED when its class \[Gamma](s) in the first relative \:010cech cohomology is nonzero \[LongDash] equivalently (arXiv:1502.03097, Prop. 4.4) when no compatible family of Z-linear combinations of support sections restricts to s. \[Gamma](s) != 0 certifies that s extends to no global assignment (logical contextuality at s); \[Gamma] != 0 everywhere certifies strong contextuality. Pre-registered gate (semantics fixed before computation, attack-catalog style): ADOPT if the classical C5 model (1/5, 2/5, 2/5, 0) carries no obstruction, the Wright box a nonzero obstruction, and the quantum-maximal model is classified probabilistically contextual \[LongDash] the three models pairwise separated \[LongDash] where the Laplacian residual was blind ({0, 0, 0}); REJECT otherwise. Result: ADOPT. Classical 0/15 obstructed, quantum 0/15 (its support EQUALS the classical support \[LongDash] no support functional may separate them; the LP layer does), Wright 10/10: a cohomological certificate of strong contextuality. Corroboration: C7 (0/21 vs 14/14, |Se| = LucasL[7] = 29), even-cycle parity control (C6 Wright: 0/12, noncontextual), CHSH cross-validation against the literature (PR box 8/8; Hardy 0/13 with exactly one genuinely nonextendable section \[LongDash] the documented false negative of the Z-linear witness), and the two-copy product cover of ab_sheaf.wl (Wright\[CircleTimes]Wright 100/100, quantum\[CircleTimes]quantum 0/225, |Se| = 11^2). The absolute groups are computed too (CechCohomology, arbitrary covers, torsion by Smith normal form): the CHSH census reproduces the Ulrey-models notebook exactly, H^0 is multiplicative on the product cover (36 = 6^2), and the ambient H^1 \[LongDash] Z alike for the PR box and the noncontextual uniform model \[LongDash] confirms that the contextuality lives in the RELATIVE classes \[Gamma](s), nowhere else.*)

(* ::Section:: *)
(*Setting*)

(* ::Text:: *)
(*CechObstruction[scen, e] decides \[Gamma](s) per support section by three exact steps: a deterministic global witness (a global assignment through s consistent with the whole support) forces \[Gamma](s) = 0; failing that, exact rank of the compatibility system refutes rational solvability (hence Z-solvability); the residual rational-but-integer? cases go to FindInstance over the integers. Everything is exact arithmetic; no floating point enters any verdict.*)

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
ccWW = CechCohomology[scenProd, prodModel[CycleModel[5, "Wright"], CycleModel[5, "Wright"]]];
ccQQ = CechCohomology[scenProd, prodModel[CycleModel[5, "Quantum"], CycleModel[5, "Quantum"]]];
cohomTable = MapThread[{#1, #2["CochainRanks"], #2["H0Rank"], #2["H1FreeRank"], #2["H1Torsion"], #2["ComplexCloses"]} &,
  {{"C5 classical", "C5 quantum", "C5 Wright", "C6 Wright", "CHSH uniform", "PR box", "Hardy", "Wright\[CircleTimes]Wright", "quantum\[CircleTimes]quantum"},
   {ccC, ccQ, ccW, ccW6, ccU, ccPR, ccH, ccWW, ccQQ}}];
TableForm[cohomTable, TableHeadings -> {None, {"model", "{C0, C1, C2}", "rk H0", "rk H1", "H1 torsion", "\[Delta]1\[Delta]0 = 0"}}]

(* ::Text:: *)
(*Structure worth recording: (i) H^0 is multiplicative on the product cover \[LongDash] 36 = 6^2 for quantum\[CircleTimes]quantum, 1 = 1^2 for Wright\[CircleTimes]Wright; (ii) on every single-cycle cover of this census H^1 has free rank 1 (the nerve circle) except C6 Wright where it is 2 \[LongDash] the group remembers the support, not just the nerve; (iii) on the product cover the C^2 correction kills H^1 entirely (free rank 0), so all the contextuality information there sits in the relative layer, exactly where CechObstruction reads it; (iv) no torsion appears anywhere in this census; where the integral question was genuinely live (Hardy's nonextendable section, rationally solvable) the vanishing class is witnessed by an explicit integer family through CechObstruction's FindInstance branch.*)

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
  "cohomCensusMatchesUlreyNotebook" -> ({#["H0Rank"], #["H1FreeRank"], #["H1Torsion"]} & /@ {ccU, ccPR, ccH}) ===
     {{9, 1, {}}, {1, 1, {}}, {6, 1, {}}},
  "cohomComplexCloses" -> AllTrue[{ccC, ccQ, ccW, ccW6, ccU, ccPR, ccH, ccWW, ccQQ}, #["ComplexCloses"] &],
  "cohomH0Multiplicative" -> ccQQ["H0Rank"] == ccQ["H0Rank"]^2 && ccWW["H0Rank"] == ccW["H0Rank"]^2,
  "cohomProductH1Vanishes" -> ccWW["H1FreeRank"] == 0 && ccQQ["H1FreeRank"] == 0 &&
     ccWW["CochainRanks"] == {100, 700, 2200},
  "cohomNoTorsionInCensus" -> AllTrue[{ccC, ccQ, ccW, ccW6, ccU, ccPR, ccH, ccWW, ccQQ}, #["H1Torsion"] === {} &],
  "verdict" -> "ADOPT: the support-presheaf Cech obstruction joins the core as the possibilistic-layer certificate; the Laplacian stays a no-disturbance projector only"
|>;
SupportCohomologyVerification["OK"] = And @@ Cases[Values[SupportCohomologyVerification], _?BooleanQ];
SupportCohomologyVerification
