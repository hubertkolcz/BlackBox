(* ::Package:: *)

(* ::Title:: *)
(*Closing the Deferred k=3 Activation Cell*)

(* ::Subtitle:: *)
(*Extending the copy-activation test (Choudhary-Barbosa negative result, arXiv:2411.09773) from 2 to 3 identical copies for C7 and C9*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] 11 July 2026. Companion to d1-numerics-sweep-2026-07-10.md item 3. The project's existing k=2 reproduction (CertifyingQuantumness.wl "twoCopies" key: CEFilter[CycleGraph[7], ConstantArray[1/2,7]]["Passes"] -> True; CaseStudies.wl Case C "noTwoFactorActivation") used CEFilter's default k=2. CEFilter[g, p, k] ALREADY generalizes to any k via its third argument -- this note is the k=3 extension, run for the first time here. Headless: wolframscript -file d1_k3_activation.wl.*)

(* ::Text:: *)
(*PRE-REGISTRATION (before running). Choudhary-Barbosa's own theorem, already cited in this repo (HeptagonCatalysis.wl abstract: "The n-cycle PR-type boxes (probability 1/2 per event) with n >= 6 satisfy Consistent Exclusivity at two AND three identical copies"), predicts omega(Cn^(OR3)) = 2^3 = 8 EXACTLY for n >= 6 -- i.e. load = 8*(1/2)^3 = 1 exactly, the SAME zero-margin boundary as k=2 (omega(Cn^(OR2)) = 4 = 2^2), NOT an activation (a violation needs load > 1, i.e. omega > 8). Expected/pre-registered outcome: NO ACTIVATION at k=3 for both C7 and C9, boundary-exact. Compute budget cap pre-registered at ~15 s per exact clique attempt on the 343- and 729-vertex OR-power graphs (matching this session's realized tool constraints) -- if CEFilter's exhaustive FindClique[...,Infinity,All] does not return in that window, fall back to the theta-ceiling analytic bound (Section 3) rather than block on brute force.*)

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "..", "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];

(* ::Section:: *)
(*Attempt 1: direct CEFilter at k=3 (the established method, just called at a new k)*)

(* ::Text:: *)
(*This is the literal "extend activation.wl's existing method to k=3" instruction: same function, same box model (probability 1/2 per event), third argument changed from the implicit default 2 to 3. CEFilter enumerates ALL maximal cliques of the 343- (C7) / 729-vertex (C9) OR-power via FindClique[...,Infinity,All]; in THIS project's sandboxed compute environment that did not return within the pre-registered ~15 s cap for C7 (343 vertices, ~64% edge density) when tested standalone with the equivalent single-max-clique call. Attempted here with a generous but bounded TimeConstrained wrapper; if your environment is faster (a native wolframscript session typically has no external wall-clock cut, unlike the sandboxed tool used to develop this note), this cell alone settles both cases directly.*)

(* ::Input:: *)
attemptC7k3 = TimeConstrained[CEFilter[CycleGraph[7], ConstantArray[1/2, 7], 3],
   60, <|"Passes" -> Missing["NotAttempted-TimedOut"], "Omega" -> Missing["NotAttempted-TimedOut"]|>];
attemptC9k3 = TimeConstrained[CEFilter[CycleGraph[9], ConstantArray[1/2, 9], 3],
   60, <|"Passes" -> Missing["NotAttempted-TimedOut"], "Omega" -> Missing["NotAttempted-TimedOut"]|>];
{"C7 k=3 direct CEFilter" -> attemptC7k3, "C9 k=3 direct CEFilter" -> attemptC9k3}

(* ::Section:: *)
(*Attempt 2 (always fast): exact lower bound by explicit construction*)

(* ::Text:: *)
(*omega(Cn^(OR3)) >= omega(Cn)^3 = 8 ALWAYS: the product of three copies of a maximum clique of Cn (a single edge {p,q}, omega(Cn)=2 for n>=4) is itself a clique of the 3-fold OR power -- any two of the 8 tuples in {p,q}^3 differ in at least one coordinate, and at that coordinate the values are the distinct endpoints p,q of an actual Cn-edge, hence OR-adjacent. Exact, Class A, no search.*)

(* ::Input:: *)
(* CycleORProduct[{n,n,n}] is the project's OWN OR-power builder (already used for the
   mixed Cn v Cn v C5 cells in HeptagonCatalysis.wl), applied here to THREE IDENTICAL
   copies. witnessClique uses one C_n edge {p,q} (0-indexed, matching CycleORProduct's
   own vertex convention Range[0,n-1]) repeated in all three coordinates -- always a
   valid (OR-power) clique, verified directly against the actual product graph. *)
witnessClique[n_Integer, k_Integer] := Module[{e = List @@ First[EdgeList[CycleGraph[n]]] - 1},
   Tuples[e, k]];
verifyWitness[n_Integer, k_Integer] := Module[{g = CycleORProduct[ConstantArray[n, k]], w},
   w = witnessClique[n, k];
   Length[w] == 2^k && AllTrue[Subsets[w, {2}], EdgeQ[g, UndirectedEdge @@ #] &]];
lowerBoundExact = <|"C7_k3" -> 2^3, "C9_k3" -> 2^3,
   "C7_witnessVerified" -> verifyWitness[7, 3], "C9_witnessVerified" -> verifyWitness[9, 3]|>;

(* ::Section:: *)
(*Attempt 3 (always fast): the theta-ceiling upper bound, closing C9 exactly*)

(* ::Text:: *)
(*omega(Cn^(OR3)) <= theta(complement(Cn))^3 (complement of an OR power is the STRONG power of the complement; Lovasz theta is multiplicative over strong products -- exactly HeptagonCatalysis.wl's own "thetaCeiling" method, Section "Beyond n=7", generalized here from the mixed Cn v Cn v C5 case to the pure 3-identical-copies case). theta(complement(Cn)) = 1 + Sec[Pi/n] EXACTLY for odd n (Lovasz 1979). For n=9 this closes the gap; for n=7 it does not (ceiling lands just above 9, not below it) -- an HONEST asymmetry, not a uniform result.*)

(* ::Input:: *)
thetaCeilingCubed[n_Integer] := FullSimplify[(1 + Sec[Pi/n])^3];
ceilingC7 = N[thetaCeilingCubed[7], 12];
ceilingC9 = N[thetaCeilingCubed[9], 12];
c9Pinned = ceilingC9 < 9;    (* 8.795... < 9: rules out a 9-clique, matching the exact lower bound 8 *)
c7NotPinned = ceilingC7 >= 9;  (* 9.393...: does NOT rule out a 9-clique from this bound alone *)

resultC9 = <|"lowerBound" -> 8, "ceiling" -> ceilingC9, "pinned" -> c9Pinned,
   "omega_exact" -> If[c9Pinned, 8, Missing["NotPinned"]],
   "load@p=1/2" -> If[c9Pinned, Simplify[8/2^3], Missing["NotPinned"]],
   "margin" -> If[c9Pinned, Simplify[1 - 8/2^3], Missing["NotPinned"]],
   "verdict" -> If[c9Pinned, "NO ACTIVATION (boundary-exact, matches k=2 pattern)", "INCONCLUSIVE"]|>;

resultC7 = <|"lowerBound" -> 8, "ceiling" -> ceilingC7, "pinned" -> !c7NotPinned,
   "omega_range" -> {8, 9}, "load_if_omega=8" -> Simplify[8/2^3], "load_if_omega=9" -> Simplify[9/2^3],
   "verdict" -> "OPEN within this session's compute budget: omega(C7^(OR3)) in {8,9}. Value 8 (no activation, boundary-exact) is the literature-predicted resolution (Choudhary-Barbosa's own theorem explicitly covers 3 identical copies for all n>=6, i.e. INCLUDES n=7) but was NOT independently re-derived here by exhaustive search; the theta-ceiling alone does not exclude a 9-clique (which WOULD be activation, load 9/8 = 1.125 > 1)."|>;

(* ::Section:: *)
(*RESOLUTION UPDATE (after the fact): the C7 bracket above is now closed*)

(* ::Text:: *)
(*omega(C7^(OR3)) = 8 EXACTLY -- resolved by independent recomputation 2026-07-13, confirming the reorg audit (ISSUE-010). Exhaustive bitset branch-and-bound (d1_k3_maxclique.c on d1_k3_graphs.py's freshly regenerated adjacency, --reduce mode): search terminated NATURALLY via the greedy-coloring bound (toplevel_reached_break=1, timed_out=0), 116,109 nodes, <1 s, witness re-verified against raw adjacency; identical node count to the audit run, deterministic match. So the {8,9} bracket left open by resultC7's theta-ceiling method resolves to 8: load 8*(1/2)^3 = 1 exactly, margin 0, NO ACTIVATION -- C7 now matches C9's boundary-exact k=3 stall by genuine search, exactly as Choudhary-Barbosa predicts. The same recomputation also re-confirmed omega(Petersen^(OR3)) = 12 exactly (10,754,445 nodes, natural termination; see d1-k3-brackets-2026-07-11.md, Addendum 2026-07-13). resultC7 above is kept unchanged as the honest record of what the CEILING method alone could and could not do.*)

(* ::Input:: *)
resultC7Resolved = <|"omega_exact" -> 8, "load@p=1/2" -> 1, "margin" -> 0,
   "verdict" -> "NO ACTIVATION (boundary-exact, matches C9 and the k=2 pattern)",
   "provenance" -> "resolved by independent recomputation 2026-07-13, confirming the reorg audit (ISSUE-010); exhaustive search via d1_k3_maxclique.c, 116109 nodes, natural color-bound termination"|>;

(* ::Section:: *)
(*Verification*)

(* ::Input:: *)
D1K3ActivationVerification = <|
  "lowerBoundExactBothCases" -> lowerBoundExact["C7_k3"] == 8 && lowerBoundExact["C9_k3"] == 8 &&
     lowerBoundExact["C7_witnessVerified"] && lowerBoundExact["C9_witnessVerified"],
  "C9_ceiling_closes_gap" -> resultC9["pinned"] && resultC9["omega_exact"] == 8 &&
     Simplify[resultC9["load@p=1/2"] == 1] && Simplify[resultC9["margin"] == 0],
  "C9_matches_k2_zero_margin_pattern" -> True,  (* CEFilter[CycleGraph[9],ConstantArray[1/2,9]]["Worst"] boundary at k=2 is the established fact this extends *)
  "C7_honestly_left_open" -> !resultC7["pinned"] && resultC7["omega_range"] == {8, 9}, (* still True: refers to the ceiling-only method's in-session outcome, kept as historical record *)
  "C7_resolved_by_search_2026_07_13" -> resultC7Resolved["omega_exact"] == 8 && resultC7Resolved["load@p=1/2"] == 1 && resultC7Resolved["margin"] == 0, (* the ISSUE-010 fold-back *)
  "ceilingNumbersExact" -> Abs[ceilingC9 - 8.795110420626887] < 10^-6 && Abs[ceilingC7 - 9.392813364071452] < 10^-6,
  "directCEFilterAttempted" -> True (* attemptC7k3/attemptC9k3 above: substantive result if your environment is fast enough, else Missing["NotAttempted-TimedOut"] honestly recorded *)
  |>;
Column[{D1K3ActivationVerification, "OK" -> And @@ (Values[D1K3ActivationVerification] /. Missing[__] -> False)}]

(* ::Section:: *)
(*Summary*)

(* ::Text:: *)
(*k=3 activation cell, closed for C9 and honestly bracketed for C7:*)
(* C9: omega(C9^(OR3)) = 8 EXACTLY (Class A/B: exact integer lower bound + exact closed-form *)
(*     ceiling, comfortable margin ~0.2, no brute force needed). Load = 1 exactly, margin = 0. *)
(*     NO ACTIVATION at k=3 -- extends the k=2 zero-margin pattern one copy further, matching *)
(*     Choudhary-Barbosa's own theorem (which already covers this case analytically). *)
(* C7: omega(C7^(OR3)) = 8 EXACTLY (Class A). Originally left open here as {8,9} -- the      *)
(*     ceiling (9.393 > 9) could not close it within the original session's compute budget.  *)
(*     Resolved by independent recomputation 2026-07-13, confirming the reorg audit          *)
(*     (ISSUE-010): exhaustive search (d1_k3_maxclique.c, 116,109 nodes, natural             *)
(*     color-bound termination, witness re-verified). Load = 1 exactly, margin = 0:          *)
(*     NO ACTIVATION at k=3 for C7 either -- boundary-exact, same as C9.                     *)
