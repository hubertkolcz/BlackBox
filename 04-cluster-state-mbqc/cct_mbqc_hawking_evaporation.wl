(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_hawking_evaporation.wl -- black-hole information-dynamics module
   built FROM FIRST PRINCIPLES on top of the verified sparse-CHP stabilizer
   simulator (cct_mbqc_sim.wl) and pattern layer (cct_mbqc_patterns.wl).

   FIRST-PRINCIPLES SOURCES (physics only; no reproduced code):
     * Page 1993 (PRL 71, 1291): average entropy of a subsystem of a random
       pure state; the "Page curve" of an evaporating black hole.
     * Lubkin 1978 (J. Math. Phys. 19, 1028): average purity of a random
       subsystem <Tr rho_A^2> = (d_A + d_B)/(d_A d_B + 1).
     * Hayden-Preskill 2007 (JHEP 0709:120): black holes as information
       mirrors; old black holes reveal infalling information quickly.
     * Yoshida-Kitaev 2017 (arXiv:1710.03363): efficient (EPR-projection and
       deterministic) decoding of the Hayden-Preskill protocol.
     * Aaronson-Gottesman 2004 (PRA 70, 052328): the CHP stabilizer tableau
       (provided by cct_mbqc_sim.wl).
     * Fattal-Cubitt-Yamamoto-Bravyi-Chuang 2004 (quant-ph/0406168) /
       Hamma-Ionicioiu-Zanardi 2005: subsystem entanglement entropy of a
       stabilizer state via GF(2) rank of the restricted generator matrix.

   HONESTY DISCIPLINE (project-mandated).  Everything the module does is either
   (i) a genuine single-qubit Pauli MEASUREMENT on the graph-state tableau, or
   (ii) a CIRCUIT-MODEL Clifford unitary applied to the tableau.  Every step of
   category (ii) -- the random-Clifford scrambling that drives the evaporation
   dynamics, the constructed Hayden-Preskill scrambler U and its conjugate U*,
   and the SWAP relabelling of qubits between the black-hole and radiation
   registers -- is CIRCUIT-MODEL dynamics on the stabilizer tableau, NOT a
   measurement pattern carved from the pentagon mesh.  This is declared here
   and re-declared at each use site.  The mesh-MBQC connection (Part 2, model
   (a)) is the ONE place Bell pairs are produced by actual Z-measurement
   carving of the fixed pentagon-mesh graph state; those carves force no
   outcomes.  The EPR-projection decoder (Part 3) uses FORCED-OUTCOME
   post-selection (MeasurePauli ForcedOutcome), declared at its use site; the
   deterministic decoder and the Page-curve dynamics force nothing.

   NO floating point in any correctness comparison: subsystem entropies are
   exact integers (GF(2) rank), purities are exact rationals 2^-S, and every
   PASS/FAIL gate is an exact === test.  Floats appear only in AbsoluteTiming /
   MemoryInUse telemetry and in the statistical mean of the sampled Renyi-2
   curve (whose target is the exact closed form, compared within sampling
   error).  No cloud calls of any kind.

   API SURFACE:
     Part 1 (stabilizer entropy):
       CCTStabEntropy[tab, A]              exact S(A) in bits, GF(2) rank
       CCTStabPurity[tab, A]               exact 2^-S(A)
       CCTvnEntropyFromState[tab, A]       validation-only von Neumann via
                                           StateVectorFromTableau (n<=10)
     Part 2 (Page curve):
       CCTRandom2QClifford[tab, a, b]      circuit-model random 2-qubit Clifford
       CCTScramble[tab, qs, sweeps]        circuit-model scrambler on a qubit set
       CCTPageCurveDirect[n, opts]         single-realization Page curve (model b)
       CCTPageCurveMesh[reps, opts]        mesh-cluster-state Page curve (model a)
       CCTMeshBellPair[reps, edge]         carve+validate a mesh Bell pair (S=1)
       CCTLubkinPurity[dA, dB]             exact (d_A+d_B)/(d_A d_B+1)
       CCTPageRenyi2Closed[n, r]           exact closed-form Renyi-2 S2(N_rad=r)
       CCTPageRenyi2Ensemble[n, shots]     sampled ensemble Renyi-2 curve
     Part 3 (Hayden-Preskill):
       CCTFindMaximalScrambler[m, ...]     search a maximal Clifford scrambler
       CCTApplyScrambler / CCTApplyScramblerConj
       CCTHPDecodeEPR / CCTHPDecodeDeterministic / CCTHPTeleportFidelity

   LOAD-ONLY USE:  CCTHawkingLoadOnly = True; Get[".../cct_mbqc_hawking_evaporation.wl"]
   loads definitions with no side effects.  Running the file directly executes
   a fast self-check.  The FULL validation suite is
   cct_mbqc_hawking_evaporation_tests.wl.
   =========================================================================== *)

If[!ValueQ[CCTHawkingDir], CCTHawkingDir = DirectoryName[$InputFileName]];
Block[{CCTMBQCPatternsLoadOnly = True, CCTMBQCLoadOnly = True},
  Get[FileNameJoin[{CCTHawkingDir, "cct_mbqc_patterns.wl"}]]];

(* ---------------------------------------------------------------------------
   PART 1.  EXACT STABILIZER SUBSYSTEM ENTROPY.

   Derivation (from first principles).  A stabilizer state on n qubits has
   stabilizer group S = <s_1,...,s_n>, |S| = 2^n.  For a subsystem A with
   complement B, the reduced state rho_A has a FLAT spectrum: its 2^{S(A)}
   nonzero eigenvalues are all equal to 2^{-S(A)}, so the von Neumann entropy
   equals the Renyi-alpha entropy for every alpha and is the integer S(A).

   Let S_A = { g in S : supp(g) subset A } be the subgroup supported entirely
   inside A.  The reduced-state entropy is
        S(A) = |A| - log2 |S_A|.
   The projection pi_B : S -> Paulis(B) that keeps only the B-part of a Pauli
   is a group homomorphism with kernel exactly S_A, so by rank-nullity over
   GF(2)  log2|S_A| = n - rank_GF2(G_B), where G_B is the n x 2|B| binary
   matrix of the n generators restricted to the B columns (X and Z bits).
   Hence  S(A) = |A| - n + rank_GF2(G_B).  Because a pure state has
   S(A) = S(B), this equals the symmetric and more convenient
        S(A) = rank_GF2(G_A) - |A|,                (implemented below)
   with G_A the n x 2|A| restriction of the generators to A.  Phases are
   irrelevant (rank ignores the sign bit).  Sanity: product state -> 0;
   Bell pair, A = one qubit -> rank[[1,0],[0,1]] - 1 = 1.
   --------------------------------------------------------------------------- *)

(* n x 2|A| GF(2) restriction of the n stabilizer generators (tableau rows
   n+1..2n) to the qubits in A; column 2t-1 = X bit, 2t = Z bit for A[[t]]. *)
CCTStabRestrict[tab_Symbol, A_List] := Module[{n = tab["n"], pos},
  pos = AssociationThread[A -> Range[Length[A]]];
  Table[Module[{rx = tab["rowX", n + v], rz = tab["rowZ", n + v],
      row = ConstantArray[0, 2 Length[A]]},
     Scan[If[KeyExistsQ[pos, #], row[[2 pos[#] - 1]] = 1] &, rx];
     Scan[If[KeyExistsQ[pos, #], row[[2 pos[#]]] = 1] &, rz];
     row], {v, n}]];

CCTStabEntropy[tab_Symbol, A_List] :=
  If[A === {}, 0, MatrixRank[CCTStabRestrict[tab, A], Modulus -> 2] - Length[A]];

CCTStabPurity[tab_Symbol, A_List] := 2^(-CCTStabEntropy[tab, A]);

(* VALIDATION-ONLY exact reference (n<=10): reduced density matrix from the
   exact Gaussian-integer statevector; S(A) = Log2[rank rho_A] (flat spectrum,
   so this IS the von Neumann entropy).  Also returns the (normalized, sorted)
   nonzero eigenvalues so the caller can assert flatness. *)
CCTReducedRhoState[tab_Symbol, A_List] := Module[
  {n = tab["n"], v, B, dA, dB, M, bits},
  v = StateVectorFromTableau[tab];
  B = Complement[Range[n], A];
  dA = 2^Length[A]; dB = 2^Length[B];
  M = ConstantArray[0, {dA, dB}];
  Do[bits = IntegerDigits[k, 2, n];
     M[[FromDigits[bits[[A]], 2] + 1, FromDigits[bits[[B]], 2] + 1]] = v[[k + 1]],
    {k, 0, 2^n - 1}];
  M . ConjugateTranspose[M]];

CCTvnEntropyFromState[tab_Symbol, A_List] := Log2[MatrixRank[CCTReducedRhoState[tab, A]]];

(* exact flatness + entropy: returns <|"S"->integer, "Flat"->bool|>.
   A stabilizer reduced state has a FLAT spectrum: rhoN = rho/Tr[rho] equals
   (1/rk) Pi for the rank-rk support projector Pi, so rhoN.rhoN === (1/rk) rhoN
   iff the nonzero eigenvalues are all equal to 1/rk.  This exact idempotent
   test avoids the (catastrophic) exact eigendecomposition of the 2^|A|-dim
   Gaussian-integer matrix; rank + one matrix multiply are both cheap and
   exact.  S(A) = log2(rk). *)
CCTStateEntropyReport[tab_Symbol, A_List] := Module[{rho, rhoN, rk},
  rho = CCTReducedRhoState[tab, A];
  rhoN = rho/Tr[rho];                        (* exact, normalized *)
  rk = MatrixRank[rhoN];                      (* exact von Neumann support dim *)
  <|"S" -> Log2[rk], "Flat" -> (rhoN . rhoN === (1/rk) rhoN)|>];

(* ---------------------------------------------------------------------------
   PART 2.  PAGE CURVE.

   CIRCUIT-MODEL DECLARATION: CCTRandom2QClifford and CCTScramble apply
   Clifford UNITARIES to the tableau (Apply* gates), not measurement patterns.
   This is the black-hole scrambling dynamics and is declared circuit-model.
   --------------------------------------------------------------------------- *)

(* a depth-8 random Clifford WORD on {a,b}: 8 random generators from
   {H,S,CNOT(both directions)}.  This is NOT a uniform 2-qubit-Clifford group
   element; it is a cheap mixing block that, composed over many CCTScramble
   sweeps, drives the whole register to a Clifford 2-design (verified against
   the Lubkin closed form in CCTPageRenyi2Ensemble).  Depth 8 trades per-block
   uniformity for speed -- essential for the n=200 scale point. *)
CCTCliffordWordLen = 8;
CCTRandom2QClifford[tab_Symbol, a_Integer, b_Integer] := (
  Do[Switch[RandomInteger[{1, 6}],
     1, ApplyH[tab, a], 2, ApplyH[tab, b], 3, ApplyS[tab, a],
     4, ApplyS[tab, b], 5, ApplyCNOT[tab, a, b], 6, ApplyCNOT[tab, b, a]],
    {CCTCliffordWordLen}]; tab);

(* one scrambling "sweep" = random 2-qubit Cliffords on a random perfect
   matching of the qubit set qs (odd qubit sits out that sweep). *)
CCTScramble[tab_Symbol, qs_List, sweeps_Integer] := (
  Do[Module[{perm = RandomSample[qs]},
     Do[CCTRandom2QClifford[tab, perm[[2 j - 1]], perm[[2 j]]],
       {j, Floor[Length[perm]/2]}]], {sweeps}];
  tab);

(* MODEL (b): DIRECT-TABLEAU single-realization Page curve.
   n qubits start in the product state |+>^n (empty-edge graph state).  The
   whole register is the young black hole.  Each emission: scramble the
   remaining black-hole qubits (circuit-model), then RELABEL one qubit as
   radiation (a bookkeeping move -- the global pure state is untouched).  We
   record S(radiation) after each emission via the exact GF(2) formula.  The
   curve rises ~+1/step, turns over at the Page time k ~ n/2, and returns to 0
   at full evaporation (global state is pure).  Returns the length-(n+1) list
   S(rad) for k = 0..n radiation qubits, plus timing/telemetry. *)
Options[CCTPageCurveDirect] = {"Sweeps" -> 6, "Seed" -> Automatic};
CCTPageCurveDirect[n_Integer?Positive, OptionsPattern[]] := Module[
  {sweeps = OptionValue["Sweeps"], seed = OptionValue["Seed"],
   tab, bh, rad = {}, curve, t},
  If[seed =!= Automatic, SeedRandom[seed]];
  {t, curve} = AbsoluteTiming[Module[{cv},
    tab = NewGraphStateTableau[n, {}];
    bh = Range[n];
    cv = {CCTStabEntropy[tab, rad]};                (* S({}) = 0 *)
    Do[
      CCTScramble[tab, bh, sweeps];
      rad = Append[rad, First[bh]]; bh = Rest[bh];  (* emit one qubit *)
      AppendTo[cv, CCTStabEntropy[tab, rad]],
      {n}];
    cv]];
  <|"n" -> n, "curve" -> curve, "pageTime" -> Ceiling[n/2],
    "peak" -> Max[curve], "final" -> Last[curve],
    "maxWeight" -> TableauStats[tab]["MaxRowWeight"],
    "time" -> t|> // (FreeTableau[tab]; #) &];

(* MODEL (a): MESH-CLUSTER Page curve.  The initial black-hole microstate IS
   the pentagon-mesh graph state |G> = prod CZ |+>^{9 reps} from the fixed
   wordRingEdgesFast["cct",reps] edge list -- a genuinely entangled stabilizer
   state produced by the MBQC substrate, not a product state.  Evaporation
   then proceeds exactly as model (b) (circuit-model scramble + relabel).  The
   emitted-qubit entropy still traces the Page curve back to 0.  This ties the
   evaporation to the mesh at small scale. *)
Options[CCTPageCurveMesh] = {"Sweeps" -> 2, "Seed" -> Automatic};
CCTPageCurveMesh[reps_Integer?Positive, OptionsPattern[]] := Module[
  {sweeps = OptionValue["Sweeps"], seed = OptionValue["Seed"],
   n = CCTMeshN[reps], edges = CCTMeshEdges[reps], tab, bh, rad = {}, curve, t},
  If[seed =!= Automatic, SeedRandom[seed]];
  {t, curve} = AbsoluteTiming[Module[{cv},
    tab = NewGraphStateTableau[n, edges];
    bh = Range[n];
    cv = {CCTStabEntropy[tab, rad]};
    Do[CCTScramble[tab, bh, sweeps];
       rad = Append[rad, First[bh]]; bh = Rest[bh];
       AppendTo[cv, CCTStabEntropy[tab, rad]], {n}];
    cv]];
  <|"reps" -> reps, "n" -> n, "curve" -> curve, "pageTime" -> Ceiling[n/2],
    "peak" -> Max[curve], "final" -> Last[curve], "time" -> t|> //
   (FreeTableau[tab]; #) &];

(* SCALE-DEMO Page curve (single realization, large n).  CIRCUIT-MODEL /
   FRONT-LOADED-SCRAMBLING DECLARATION: re-scrambling the whole remaining
   register at every one of n emissions costs O(n^4) on this sparse tableau and
   is intractable at n = 200.  By Page 1993 the emission-by-emission Page curve
   and the subsystem-entropy profile of a SINGLE deeply-scrambled random pure
   state coincide in distribution: for a random pure state of n qubits,
   S(first r qubits) ~ min(r, n-r) - O(1).  So the scale demonstration prepares
   ONE random stabilizer state (a deep circuit-model scramble of |+>^n, which
   front-loads all the inter-emission scrambling) and reads S(radiation = first
   r qubits) for r = 0..n.  This is the exact Page curve of a random pure state;
   it rises, peaks near n/2, and returns to 0.  Only the scheduling of the
   (circuit-model) scrambling differs from CCTPageCurveDirect. *)
Options[CCTPageCurveScrambledState] = {"Sweeps" -> 14, "Seed" -> Automatic};
CCTPageCurveScrambledState[n_Integer?Positive, OptionsPattern[]] := Module[
  {sweeps = OptionValue["Sweeps"], seed = OptionValue["Seed"], tab, curve, t},
  If[seed =!= Automatic, SeedRandom[seed]];
  {t, curve} = AbsoluteTiming[
    tab = NewGraphStateTableau[n, {}];
    CCTScramble[tab, Range[n], sweeps];
    Table[CCTStabEntropy[tab, Range[r]], {r, 0, n}]];
  <|"n" -> n, "curve" -> curve, "pageTime" -> Ceiling[n/2],
    "peak" -> Max[curve], "final" -> Last[curve],
    "maxWeight" -> TableauStats[tab]["MaxRowWeight"], "sweeps" -> sweeps,
    "time" -> t|> // (FreeTableau[tab]; #) &];

(* MESH-CARVED BELL PAIR (model (a) resource validation).  On the fixed mesh
   graph state, Z-measure every vertex except the two endpoints of `edge`.
   By the Hein Z-rule the survivors are left in the edge graph state |CZ>|++>
   -- a Bell pair up to a local Hadamard -- so S(one endpoint) = 1 exactly.
   Returns the measured entropy of one endpoint (must be 1) and the survivors.
   These Z-carves force NO outcomes. *)
CCTMeshBellPair[reps_Integer, edge_List] := Module[
  {n = CCTMeshN[reps], edges = CCTMeshEdges[reps], tab, others, s},
  CCTAssert[MemberQ[edges, Sort[edge]], "CCTMeshBellPair: edge not in mesh", edge];
  tab = NewGraphStateTableau[n, edges];
  others = Complement[Range[n], edge];
  Scan[MeasurePauli[tab, #, "Z"] &, others];
  s = CCTStabEntropy[tab, {First[edge]}];
  FreeTableau[tab];
  <|"reps" -> reps, "edge" -> Sort[edge], "entropy" -> s, "isBellPair" -> (s === 1)|>];

(* Lubkin/Page average purity of a random subsystem (derived closed form):
   <Tr rho_A^2> = (d_A + d_B)/(d_A d_B + 1).  Exact rational. *)
CCTLubkinPurity[dA_Integer, dB_Integer] := (dA + dB)/(dA dB + 1);

(* Closed-form Renyi-2 Page curve for n qubits, r radiation qubits:
   A = radiation (d_A = 2^r), B = black hole (d_B = 2^{n-r});
   S2(r) = -log2 <Tr rho_rad^2> = -log2 (2^r + 2^{n-r})/(2^n + 1). *)
CCTPageRenyi2Closed[n_Integer, r_Integer] :=
  -Log2[CCTLubkinPurity[2^r, 2^(n - r)]];

(* SAMPLED ensemble Renyi-2 curve.  For each of `shots` realizations: build a
   random full-Clifford pure state on n qubits (deep circuit-model scramble of
   |+>^n), then for every r = 0..n take purity_i(r) = 2^{-S(rad=first r qubits)}
   (exact rational -- flat stabilizer spectrum).  The ensemble Renyi-2 is
   S2(r) = -log2( mean_i purity_i(r) ).  Because the Clifford group is an exact
   unitary 2-design, E[purity] equals the Lubkin closed form EXACTLY; the
   finite-sample mean approximates it within sampling error.  All purities are
   exact rationals; only the final -log2(mean) is evaluated numerically for the
   comparison. *)
Options[CCTPageRenyi2Ensemble] = {"Sweeps" -> 16, "Seed" -> Automatic};
CCTPageRenyi2Ensemble[n_Integer, shots_Integer, OptionsPattern[]] := Module[
  {sweeps = OptionValue["Sweeps"], seed = OptionValue["Seed"],
   acc, t, means, s2},
  If[seed =!= Automatic, SeedRandom[seed]];
  {t, acc} = AbsoluteTiming[Module[{sum = ConstantArray[0, n + 1], tab},
    Do[tab = NewGraphStateTableau[n, {}];
       CCTScramble[tab, Range[n], sweeps];
       sum = sum + Table[CCTStabPurity[tab, Range[r]], {r, 0, n}];
       FreeTableau[tab], {shots}];
    sum]];
  means = acc/shots;                                (* exact rational means *)
  s2 = Table[-Log2[N[means[[r + 1]]]], {r, 0, n}];
  <|"n" -> n, "shots" -> shots, "meanPurity" -> means, "S2sampled" -> s2,
    "S2closed" -> Table[N[CCTPageRenyi2Closed[n, r]], {r, 0, n}],
    "time" -> t|>];

(* ---------------------------------------------------------------------------
   PART 3.  HAYDEN-PRESKILL DECODING.

   CIRCUIT-MODEL DECLARATION: the scrambler U, its complex conjugate U* (used
   on the decoder side), and all reference/EPR preparation are circuit-model
   Clifford unitaries on the tableau.  The EPR-PROJECTION decoder additionally
   uses FORCED-OUTCOME post-selection (MeasurePauli ForcedOutcome), declared
   here.  The deterministic decoder and the maximal-scrambler search force
   nothing.

   STANDARD INSTANCE (fixed): n_A = 1 diary qubit, n_B = 3 black-hole qubits
   (scrambler size m = 4), n_C = 2 radiation qubits collected.  Qubit layout
   (10 qubits total, so exact statevector fidelities are available):
     A  = 1        (diary)             A' = 5        (reference of A)
     B  = {2,3,4}  (rest of BH)        B' = {6,7,8}  (Bob's Bell partners of B)
     P  = 9        (decoder input)     R  = 10       (Bob's output, ref of P)
   EPR pairs |Phi+> on (1,5),(2,6),(3,7),(4,8),(9,10).  U acts on positions
   (1,2,3,4) -> black-hole qubits (1,2,3,4); U* acts on the same positions ->
   decoder qubits (9,6,7,8) (position 1 = P, positions 2..4 = B').  Radiation =
   output positions {3,4}: black-hole qubits {3,4}, decoder qubits {7,8}; the
   decoder Bell-projects (3,7) and (4,8).  On success the reference A'=5 is
   left maximally entangled with Bob's output R=10 -- the diary is recovered.
   --------------------------------------------------------------------------- *)

CCTHPidmap = Association[Table[i -> i, {i, 1, 12}]];    (* U side: position=qubit *)
CCTHPdecmap = Association[1 -> 9, 2 -> 6, 3 -> 7, 4 -> 8]; (* U* side remap *)

(* apply one gate g = {"H",q}|{"S",q}|{"CNOT",a,b}|{"CZ",a,b} at positions
   mapped by qmap; conj=True realises U* (S -> Sdg, all others real);
   p>0 injects per-gate depolarizing noise (each touched qubit gets a random
   X/Y/Z with probability p) -- a single stabilizer trajectory of the channel. *)
CCTHPGateApply[tab_Symbol, g_, qmap_, conj_, p_] := Module[{qs},
  Switch[g[[1]],
    "H", ApplyH[tab, qmap[g[[2]]]],
    "S", If[conj, ApplySdg[tab, qmap[g[[2]]]], ApplyS[tab, qmap[g[[2]]]]],
    "CNOT", ApplyCNOT[tab, qmap[g[[2]]], qmap[g[[3]]]],
    "CZ", ApplyCZ[tab, qmap[g[[2]]], qmap[g[[3]]]]];
  If[p > 0,
    qs = If[Length[g] >= 3, {qmap[g[[2]]], qmap[g[[3]]]}, {qmap[g[[2]]]}];
    Do[If[RandomReal[] < p,
       Switch[RandomInteger[{1, 3}], 1, ApplyX[tab, q], 2, ApplyY[tab, q],
         3, ApplyZ[tab, q]]], {q, qs}]];
  tab];

CCTHPRowWeight[tab_Symbol, h_Integer] := Length[Union[tab["rowX", h], tab["rowZ", h]]];

(* CONSTRUCT a MAXIMAL Clifford scrambler on m qubits: search random depth-4m
   Clifford words until EVERY conjugated single-qubit Pauli image -- the image
   of X_i, of Z_i, AND of Y_i under conjugation by U -- has PAULI WEIGHT >= 3,
   i.e. no single-qubit Pauli stays local; each of the 3m images spreads onto
   >= 3 qubits.  Read off the tableau after applying the word to |+>^m: the
   stabilizer row m+i carries the X_i image, the destabilizer row i carries
   the Z_i image, and the Y_i image is their product, whose support is the set
   of qubits where the XOR of the two rows' (x,z) bit pairs is nonzero (the
   phase is irrelevant to the weight).  Checking X and Z alone is NOT
   sufficient: Y = iXZ can collapse to weight 2 even when both factors have
   weight >= 3 (adversarial-review finding R3c, fixed 2026-07-13).  Verified
   exactly on the tableau and re-verified densely by the review probe.
   Returns the gate word and the minimum image weight over all 3m images
   (which must be >= 3). *)
Options[CCTFindMaximalScrambler] = {"Seed" -> 123, "MaxTries" -> 4000};
CCTHPYImageWeight[tab_Symbol, i_Integer, m_Integer] := Length[Union[
  SymDiff[tab["rowX", i], tab["rowX", m + i]],
  SymDiff[tab["rowZ", i], tab["rowZ", m + i]]]];
CCTFindMaximalScrambler[m_Integer, OptionsPattern[]] := Module[
  {gates, tab, weights, minw = 0, tries = 0},
  SeedRandom[OptionValue["Seed"]];
  While[True, tries++;
    gates = Table[Switch[RandomInteger[{1, 4}],
       1, {"H", RandomInteger[{1, m}]}, 2, {"S", RandomInteger[{1, m}]},
       3, With[{pp = RandomSample[Range[m], 2]}, {"CNOT", pp[[1]], pp[[2]]}],
       4, With[{pp = RandomSample[Range[m], 2]}, {"CZ", pp[[1]], pp[[2]]}]], {4 m}];
    tab = NewGraphStateTableau[m, {}];
    Do[CCTHPGateApply[tab, g, CCTHPidmap, False, 0], {g, gates}];
    weights = Flatten[Table[{CCTHPRowWeight[tab, i], CCTHPRowWeight[tab, m + i],
       CCTHPYImageWeight[tab, i, m]}, {i, m}]];
    minw = Min[weights];
    FreeTableau[tab];
    If[minw >= 3 || tries > OptionValue["MaxTries"], Break[]]];
  <|"m" -> m, "gates" -> gates, "minImageWeight" -> minw,
    "isMaximal" -> (minw >= 3), "tries" -> tries|>];

(* build the standard 10-qubit HP instance (all five |Phi+> EPR pairs). *)
CCTHPBuildInstance[] := Module[{tab},
  tab = NewGraphStateTableau[10, {{1, 5}, {2, 6}, {3, 7}, {4, 8}, {9, 10}}];
  Scan[ApplyH[tab, #] &, {5, 6, 7, 8, 10}];            (* edge graph state -> |Phi+> *)
  tab];

(* two-qubit Pauli correlator matrices on the (A',R)=(5,10) pair *)
CCTHPxx = KroneckerProduct[{{0, 1}, {1, 0}}, {{0, 1}, {1, 0}}];
CCTHPzz = KroneckerProduct[{{1, 0}, {0, -1}}, {{1, 0}, {0, -1}}];
CCTHPyy = KroneckerProduct[{{0, -I}, {I, 0}}, {{0, -I}, {I, 0}}];

(* EPR-PROJECTION (probabilistic) decoder.  Runs U, U*, Bell-projects the two
   radiation pairs (3,7),(4,8) by forcing their disentangled Z outcomes to 0.
   successProb = product of the four Born probabilities (= 1/d_A^2 for a
   maximal scrambler).  Fe = <Phi+|rho_{5,10}|Phi+> on the FIXED (uncorrected)
   frame (= 1 for a maximal scrambler; degrades under noise).  p>0 injects a
   depolarizing trajectory (call inside a sampling loop for the mixed channel). *)
Options[CCTHPDecodeEPR] = {"NoiseP" -> 0};
CCTHPDecodeEPR[gates_List, OptionsPattern[]] := Module[
  {p = OptionValue["NoiseP"], tab, pr, rho, tr, XX, ZZ, YY},
  tab = CCTHPBuildInstance[];
  Do[CCTHPGateApply[tab, g, CCTHPidmap, False, p], {g, gates}];
  Do[CCTHPGateApply[tab, g, CCTHPdecmap, True, p], {g, gates}];
  ApplyCNOT[tab, 3, 7]; ApplyH[tab, 3];
  pr = MeasurePauli[tab, 3, "Z", "ForcedOutcome" -> 0]["Probability"] *
       MeasurePauli[tab, 7, "Z", "ForcedOutcome" -> 0]["Probability"];
  ApplyCNOT[tab, 4, 8]; ApplyH[tab, 4];
  pr = pr * MeasurePauli[tab, 4, "Z", "ForcedOutcome" -> 0]["Probability"] *
            MeasurePauli[tab, 8, "Z", "ForcedOutcome" -> 0]["Probability"];
  rho = CCTReducedRhoState[tab, {5, 10}]; tr = Tr[rho];
  FreeTableau[tab];
  If[tr === 0, Return[<|"successProb" -> pr, "Fe" -> Missing["ProjFail"]|>]];
  rho = rho/tr;
  XX = Re[Tr[rho . CCTHPxx]]; ZZ = Re[Tr[rho . CCTHPzz]]; YY = Re[Tr[rho . CCTHPyy]];
  <|"successProb" -> pr, "Fe" -> (1 + XX + ZZ - YY)/4|>];

(* DETERMINISTIC decoder.  Same circuit but UNFORCED (random) Bell
   measurements -- no post-selection.  For a maximal scrambler the reference
   pair (A',R)=(5,10) is left in a PURE maximally-entangled (Bell) state whose
   frame is an outcome-determined Pauli, so an outcome-conditioned Pauli
   correction recovers |Phi+> with fidelity 1 and success probability 1.  We
   certify recoverability by the exact stabilizer entropies:
     S({5,10}) == 0   (the pair is pure -- disentangled from everything else)
     S({5})    == 1   (its two qubits are maximally entangled = Bell). *)
CCTHPDecodeDeterministic[gates_List] := Module[{tab, sJoint, sHalf},
  tab = CCTHPBuildInstance[];
  Do[CCTHPGateApply[tab, g, CCTHPidmap, False, 0], {g, gates}];
  Do[CCTHPGateApply[tab, g, CCTHPdecmap, True, 0], {g, gates}];
  ApplyCNOT[tab, 3, 7]; ApplyH[tab, 3]; MeasurePauli[tab, 3, "Z"]; MeasurePauli[tab, 7, "Z"];
  ApplyCNOT[tab, 4, 8]; ApplyH[tab, 4]; MeasurePauli[tab, 4, "Z"]; MeasurePauli[tab, 8, "Z"];
  sJoint = CCTStabEntropy[tab, {5, 10}]; sHalf = CCTStabEntropy[tab, {5}];
  FreeTableau[tab];
  <|"S_pair" -> sJoint, "S_half" -> sHalf,
    "recovered" -> (sJoint === 0 && sHalf === 1)|>];

(* build the instance with a DEFINITE diary state on A=1 (no A' Bell pair) for
   the Pauli-basis teleportation test.  basisState in {"0","1","+","-","+i","-i"}. *)
CCTHPketPrep[tab_Symbol, q_Integer, s_String] := Switch[s,
  "0", ApplyH[tab, q],                                  (* |+> -> H -> |0> *)
  "1", (ApplyH[tab, q]; ApplyX[tab, q]),                (* |1> *)
  "+", Null,                                            (* already |+> *)
  "-", ApplyZ[tab, q],                                  (* |-> *)
  "+i", ApplyS[tab, q],                                 (* |+i> *)
  "-i", ApplySdg[tab, q]];                              (* |-i> *)
CCTHPinputBasis = <|"0" -> "Z", "1" -> "Z", "+" -> "X", "-" -> "X", "+i" -> "Y", "-i" -> "Y"|>;

(* TELEPORTATION of a definite Pauli-basis diary.  Diary |psi> on A=1; run
   U,U*, unforced Bell-measure radiation; then the recovered qubit R=10 holds
   P|psi> with P an outcome-determined Pauli.  The diary is recoverable with
   fidelity 1 (after the Pauli frame) IFF the defining Pauli sigma of |psi> is
   DETERMINISTIC on R (P|psi> is always a sigma-eigenstate, so determinism is
   the fidelity-1 criterion).  Returns True/False per input. *)
CCTHPTeleportInput[gates_List, s_String] := Module[{tab, det},
  tab = NewGraphStateTableau[10, {{2, 6}, {3, 7}, {4, 8}, {9, 10}}];
  Scan[ApplyH[tab, #] &, {6, 7, 8, 10}];               (* B-B', P-R Bell pairs *)
  CCTHPketPrep[tab, 1, s];                              (* diary on A=1 *)
  Do[CCTHPGateApply[tab, g, CCTHPidmap, False, 0], {g, gates}];
  Do[CCTHPGateApply[tab, g, CCTHPdecmap, True, 0], {g, gates}];
  ApplyCNOT[tab, 3, 7]; ApplyH[tab, 3]; MeasurePauli[tab, 3, "Z"]; MeasurePauli[tab, 7, "Z"];
  ApplyCNOT[tab, 4, 8]; ApplyH[tab, 4]; MeasurePauli[tab, 4, "Z"]; MeasurePauli[tab, 8, "Z"];
  det = MeasurePauli[tab, 10, CCTHPinputBasis[s]]["Deterministic"];
  FreeTableau[tab]; det];

(* basis-averaged teleportation fidelity, all six Pauli eigenstates.  For a
   maximal scrambler every input is deterministic (fidelity 1 after frame);
   the fraction deterministic is reported. *)
CCTHPTeleportFidelity[gates_List] := Module[{res},
  res = CCTHPTeleportInput[gates, #] & /@ {"0", "1", "+", "-", "+i", "-i"};
  <|"perInput" -> AssociationThread[{"0", "1", "+", "-", "+i", "-i"} -> res],
    "allRecovered" -> (And @@ res),
    "fracRecovered" -> N[Count[res, True]/6]|>];

(* Pauli-depolarizing NOISE SWEEP on the EPR-projection decoder via mixed-
   stabilizer sampling: for each per-gate error rate p, average Fe over `shots`
   independent trajectories (seeded).  Fe(0) = 1; degrades monotonically. *)
CCTHPNoiseSweep[gates_List, ps_List, shots_Integer, seed_Integer] := Module[{},
  SeedRandom[seed];
  Table[Module[{sum = 0, cnt = 0, fail = 0, f},
    Do[f = CCTHPDecodeEPR[gates, "NoiseP" -> p]["Fe"];
       If[MissingQ[f], fail++, sum += f; cnt++], {shots}];
    <|"p" -> p, "meanFe" -> N[sum/Max[cnt, 1]], "valid" -> cnt, "projFail" -> fail|>],
   {p, ps}]];

(* ---------------------------------------------------------------------------
   SELF-CHECK (skipped when CCTHawkingLoadOnly = True).
   --------------------------------------------------------------------------- *)
If[!TrueQ[CCTHawkingLoadOnly],
  Module[{v0, okE, tab, bp, pc, r2},
    Print["=== cct_mbqc_hawking_evaporation.wl self-check ==="];
    Print["--- Part 1: stabilizer entropy vs exact statevector (n<=8) ---"];
    SeedRandom[7];
    okE = And @@ Table[Module[{nn = RandomInteger[{2, 8}], t2, A, sG, sV},
       t2 = NewGraphStateTableau[nn, {}];
       CCTScramble[t2, Range[nn], 4];
       A = Sort[RandomSample[Range[nn], RandomInteger[{0, nn}]]];
       sG = CCTStabEntropy[t2, A];
       sV = CCTStateEntropyReport[t2, A];
       FreeTableau[t2];
       (sG === sV["S"]) && sV["Flat"]], {60}];
    Print["    60 random stabilizer states x random subsets: GF(2) == statevec, flat spectrum? ", okE];
    Print["--- Part 2a: mesh-carved Bell pair S=1 ---"];
    bp = CCTMeshBellPair[1, {2, 3}];
    Print["    carve mesh reps=1 survivors {2,3}: S(one endpoint)=", bp["entropy"], "  Bell? ", bp["isBellPair"]];
    Print["--- Part 2b: direct Page curve n=12 ---"];
    pc = CCTPageCurveDirect[12, "Seed" -> 20260713];
    Print["    curve=", pc["curve"]];
    Print["    peak=", pc["peak"], " at Page time~", pc["pageTime"], "  final=", pc["final"]];
    Print["--- Part 2c: Renyi-2 ensemble n=8, 150 shots vs Lubkin closed form ---"];
    r2 = CCTPageRenyi2Ensemble[8, 150, "Seed" -> 99];
    Print["    S2 sampled = ", NumberForm[r2["S2sampled"], 4]];
    Print["    S2 closed  = ", NumberForm[r2["S2closed"], 4]];
    Print["    max|diff|  = ", Max[Abs[r2["S2sampled"] - r2["S2closed"]]]];
    Print["--- Part 3: Hayden-Preskill (maximal scrambler m=4) ---"];
    Module[{sc, epr, det, tele, idepr, sweep},
      sc = CCTFindMaximalScrambler[4, "Seed" -> 123];
      Print["    maximal scrambler: minImageWeight=", sc["minImageWeight"],
        " (>=3? ", sc["isMaximal"], ") tries=", sc["tries"]];
      epr = CCTHPDecodeEPR[sc["gates"]];
      Print["    EPR-projection: successProb=", epr["successProb"],
        " (1/d_A^2=1/4?)  Fe=", epr["Fe"]];
      det = CCTHPDecodeDeterministic[sc["gates"]];
      Print["    deterministic decoder: S_pair=", det["S_pair"], " S_half=", det["S_half"],
        " recovered=", det["recovered"]];
      tele = CCTHPTeleportFidelity[sc["gates"]];
      Print["    Pauli-input teleport: fracRecovered=", tele["fracRecovered"],
        " all=", tele["allRecovered"]];
      idepr = CCTHPDecodeEPR[{}];
      Print["    identity control: Fe=", idepr["Fe"], " -> avg teleport fidelity=",
        (2 idepr["Fe"] + 1)/3];
      sweep = CCTHPNoiseSweep[sc["gates"], {0.01, 0.02}, 150, 5];
      Print["    noise sweep (150 shots): ", {#["p"], #["meanFe"]} & /@ sweep];
    ];
    Print["SELF-CHECK complete."];
  ]
]
