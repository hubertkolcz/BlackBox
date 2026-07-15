(* ::Package:: *)

(* ::Title:: *)
(*Contextual Fraction vs Signed Negativity: CF = 4\[Nu] is a Pentagon Accident*)

(* ::Subtitle:: *)
(*Settling an open question of kcbs_ledger.wl at the sheaf level*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Companion to the BlackBox paclet. The phase-space ledger note (kcbs_ledger.wl) found, for the KCBS pentagon, the exact identity CF = 4\[Nu] linking the contextual fraction CF = 2Sqrt[5] - 4 to the minimal-negativity decomposition weight \[Nu] = (Sqrt[5] - 2)/2, and asked (QUANTUM_CONTEXTUALITY.md \[Section]9) whether CF = 4\[Nu] is a theorem. This note answers it at the level of empirical models, using only the sheaf-theoretic LP layer (no phase space): \[Nu] here is SignedNegativity[scen, e], the minimal total negative weight of a quasi-probability over deterministic global assignments reproducing e \[LongDash] a resource measure of the empirical model, related to but distinct from the Wigner negativity of the state. Every heavy LP is evaluated once and reused. Headless verification: wolframscript -file RunSignedNegativity.wl -print all (must end OK -> True).*)

(* ::Section:: *)
(*The Two Measures*)

(* ::Text:: *)
(*CF = 1 - NCF is the contextual fraction (ContextualFraction): 1 minus the maximal weight of a nonnegative sub-model dominated by e. \[Nu] = SignedNegativity is the minimal total negative mass of a SIGNED decomposition e = Sum_g c_g \[Delta]_g over the deterministic global assignments (M.c = e, Sum c = 1): \[Nu] = (min Sum|c| - 1)/2. Both are exact LPs over the incidence matrix; both vanish precisely on noncontextual models.*)

(* ::CodeText:: *)
(*Load the library and repair any Global`-shadowing:*)

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "..", "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];

(* ::Section:: *)
(*The Census: CF/\[Nu] Is Not a Constant*)

(* ::CodeText:: *)
(*Exact CF and \[Nu] on the canonical models (each LP computed once). The ratio CF/\[Nu] is scenario-dependent \[LongDash] 2 for CHSH and GHZ, 4 for the pentagon, 6 for the heptagon:*)

(* ::Input:: *)
scen5 = CycleScenario[5]; scen7 = CycleScenario[7]; scen4 = CycleScenario[4];
ePR = Flatten[{{1/2, 0, 0, 1/2}, {1/2, 0, 0, 1/2}, {1/2, 0, 0, 1/2}, {0, 1/2, 1/2, 0}}];
ghzScen = CoverScenario[{"aX", "aY", "bX", "bY", "cX", "cY"},
  {{"aX", "bX", "cX"}, {"aX", "bY", "cY"}, {"aY", "bX", "cY"}, {"aY", "bY", "cX"}}];
ghzModel = Flatten[Table[If[Mod[Total[s], 2] == par, 1/4, 0], {par, {0, 1, 1, 1}}, {s, Tuples[{0, 1}, 3]}]];
census = {{"C5 quantum", scen5, CycleModel[5, "Quantum"]}, {"C5 Wright", scen5, CycleModel[5, "Wright"]},
   {"C5 classical", scen5, CycleModel[5, "Classical"]}, {"C7 quantum", scen7, CycleModel[7, "Quantum"]},
   {"C7 Wright", scen7, CycleModel[7, "Wright"]}, {"PR box (CHSH)", scen4, ePR}, {"GHZ", ghzScen, ghzModel}};
cfnu = Table[{Simplify[ContextualFraction[r[[2]], r[[3]]]], Simplify[SignedNegativity[r[[2]], r[[3]]]]}, {r, census}];
censusData = MapThread[{#1[[1]], #2[[1]], #2[[2]], If[#2[[2]] === 0, "\[LongDash]", Simplify[#2[[1]]/#2[[2]]]]} &, {census, cfnu}];
TableForm[censusData, TableHeadings -> {None, {"model", "CF", "\[Nu]", "CF/\[Nu]"}}]

(* ::Text:: *)
(*So CF = 4\[Nu] is NOT a universal theorem: the constant 4 is scenario-specific. But the pattern is exact, not noise. Two facts organize it.*)

(* ::Section:: *)
(*The n-Cycle Law: CF = (n - 1) \[Nu]*)

(* ::CodeText:: *)
(*Within a fixed n-cycle scenario the ratio is EXACTLY n - 1, for BOTH the quantum-maximal and the Wright model \[LongDash] the pentagon's 4 is n - 1 at n = 5. The n = 5 and n = 7 ratios are reused from the census above; the n = 9 Wright point (\[Nu] = 1/8, computed once here) confirms the law at a third length:*)

(* ::Input:: *)
c5q = cfnu[[1]]; c5w = cfnu[[2]]; c7q = cfnu[[4]]; c7w = cfnu[[5]];
c9wNu = Simplify[SignedNegativity[CycleScenario[9], CycleModel[9, "Wright"]]];
cycleTable = {{5, Simplify[c5q[[1]]/c5q[[2]]], Simplify[c5w[[1]]/c5w[[2]]]},
   {7, Simplify[c7q[[1]]/c7q[[2]]], Simplify[c7w[[1]]/c7w[[2]]]},
   {9, "\[LongDash]", Simplify[1/c9wNu]}};
TableForm[cycleTable, TableHeadings -> {None, {"n", "CF/\[Nu] quantum", "CF/\[Nu] Wright"}}]

(* ::Text:: *)
(*Reading. (1) CF = 4\[Nu] is the pentagon (n = 5) instance of CF = (n - 1)\[Nu] on the n-cycle \[LongDash] a scenario identity, not a universal one; the ledger's C5 result stands, its generalization to a fixed "4" does not. (2) The n-cycle ratio is a property of the SCENARIO, shared by the quantum and Wright models on it \[LongDash] consistent with the ledger's observation that CF = 4\[Nu] holds along the entire C5 white-noise family, since mixing quantum with the classical vertex stays inside the pentagon scenario. (3) Across DIFFERENT scenarios the ratio genuinely varies (2 for CHSH/GHZ, 4/6/8 for C5/C7/C9), so no scenario-independent CF-vs-\[Nu] law exists beyond the one universal fact. LITERATURE NOTE (added after an adversarial novelty audit, 11-12 July 2026): the n-cycle law itself \[LongDash] CF = (n - 1)\[Nu] for the family of cyclic scenarios containing KCBS \[LongDash] is NOT new; it is exactly the shape of Camillo & Cervantes' Theorem 2.1 (arXiv:2305.16574, 2023), CNTF(R_n) = (n - 1) CNT3(R_n) for any cyclic n-system, where CNTF is Abramsky-Barbosa-Mansfield's contextual fraction and CNT3 is an L1-minimal signed quasiprobability measure \[LongDash] the same object as \[Nu] = SignedNegativity here, under different vocabulary (Contextuality-by-Default, not the quantum-information/graph literature this project otherwise draws on). It completes a chain of results \[LongDash] Kujala-Dzhafarov, Phil. Trans. R. Soc. A 377, 20190149 (2019) (CNT0 = CNT1 = CNT2) and Cervantes, J. Math. Psychol. 112, 102726 (2023) (CNT2 proportional to CNTF) \[LongDash] that directly answers the question Abramsky-Barbosa-Mansfield's own 2017 PRL left open ("the relationship between the contextual fraction and other possible measures [including] a negative probability measure"). This note's own scenario-dependence finding (CHSH/GHZ ratio 2, genuinely different from any n-cycle) is consistent with, not contradicted by, the CbD theorem: CHSH is not a cyclic n-system in the CbD sense, so the n - 1 law was never claimed to apply there. What remains genuinely this note's own: identifying \[Nu] with SignedNegativity inside the BlackBox LP machinery, the explicit non-universality census across scenario TYPES (not just cycle lengths), and the coincidence-of-vanishing check. The n - 1 law for cyclic scenarios should be cited to Camillo-Cervantes (2023), not presented as newly discovered here.*)

(* ::CodeText:: *)
(*The only scenario-independent statement \[LongDash] both measures detect exactly the same models (CF = 0 iff \[Nu] = 0), on a batch of random no-disturbance models:*)

(* ::Input:: *)
SeedRandom[20260710];
randModels = Table[Module[{p = RandomReal[{0, 1/2}]}, N@CycleModel[5, 1 - 2 p, p]], {8}];
coincide = AllTrue[Join[randModels, {N@CycleModel[5, "Quantum"], N@CycleModel[5, "Classical"]}],
   (Chop[ContextualFraction[scen5, #]] == 0) == (Chop[SignedNegativity[scen5, #]] == 0) &];
coincide

(* ::Section:: *)
(*Verification*)

(* ::Input:: *)
SignedNegativityVerification = <|
  "nuPentagonQuantum" -> Simplify[c5q[[2]] - (Sqrt[5] - 2)/2] === 0,
  "cfIs4NuPentagon" -> Simplify[c5q[[1]] == 4 c5q[[2]]],
  "nuWrightPentagon" -> c5w[[2]] == 1/4,
  "nuVanishesClassical" -> cfnu[[3, 2]] == 0,
  "ratioCHSHandGHZ" -> Simplify[cfnu[[6, 1]]/cfnu[[6, 2]]] == 2 && Simplify[cfnu[[7, 1]]/cfnu[[7, 2]]] == 2,
  "cycleLawExact" -> FullSimplify[c7q[[1]] == 6 c7q[[2]]] && c7w[[1]] == 6 c7w[[2]] &&
     c5w[[2]] == 1/4 && c9wNu == 1/8,
  "notUniversalConstant" -> Simplify[c5w[[1]]/c5w[[2]]] =!= Simplify[cfnu[[6, 1]]/cfnu[[6, 2]]],
  "coincidenceUniversal" -> coincide,
  "verdict" -> "CF = 4 nu is the n=5 case of CF = (n-1) nu on the n-cycle; not a universal theorem"
|>;
SignedNegativityVerification["OK"] = And @@ Cases[Values[SignedNegativityVerification], _?BooleanQ];
SignedNegativityVerification
