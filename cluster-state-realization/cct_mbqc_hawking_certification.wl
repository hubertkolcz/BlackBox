(* ::Package:: *)

(* ===========================================================================
   cct_mbqc_hawking_certification.wl -- CHSH / contextual-fraction (CF)
   CERTIFICATION STACK for mesh-carved analogue-Hawking pairs, built FROM FIRST
   PRINCIPLES on top of the verified repo stack (cct_mbqc_sim.wl sparse CHP
   tableau; cct_mbqc_patterns.wl mesh carving; cct_mesh_sparse_construction.wl
   the "cct" pentagon mesh).  No external literature was consulted in building
   this file (agnostic-implementation discipline); the ONLY project-internal
   anchor read is hawking-application/hawking_cf_bridge.py for the CF conventions and
   the pinned CF values CF(2)=0, CF(2 sqrt2)=sqrt2-1, CF(2.25)=0.125.

   WHAT IS CERTIFIED (all five stages of the task):
     (1) MESH-CARVED HAWKING PAIRS.  A Bell pair is carved from the real "cct"
         mesh by Z-measuring the mesh neighbours of an adjacent vertex pair
         {a,b}={3k+2, 3k+3}: this isolates the edge {a,b} as a disconnected
         2-vertex graph state, which is a Bell pair up to a local Hadamard on
         one qubit.  DESIGNATION: Hawking mode (exterior/outgoing) = the tip
         b=3k+3; partner mode (interior) = a=3k+2.  M>=1 disjoint pairs are
         produced from disjoint mesh regions by a greedy induced-matching
         selector.  Correspondence verified EXACTLY against StateVectorFromTableau
         at small reps.
     (2) NO-DISTURBANCE CHECK (the project's C1 discipline) FIRST.  From genuine
         seeded measurement statistics (real random outcomes through the
         tableau) the mean occupation n-bar_H (Hawking) and n-bar_P (partner)
         are estimated by Z-basis sampling and shown equal within pre-registered
         Hoeffding bounds BEFORE any entanglement claim.
     (3) PAULI TOMOGRAPHY through MBQC single-qubit measurements.  All 15
         two-qubit Pauli expectations are estimated from frame-corrected
         single-qubit measurement samples and the 2-qubit state is reconstructed;
         compared to the EXACT reduced density matrix extracted from stabilizer
         data (exact 2-qubit RDM implemented here: <P> = +-1 iff +-P is in the
         stabilizer group, 0 otherwise, decided by the destabilizer-subset
         membership test -- no Gaussian elimination, no floating point).
     (4) CHSH from the EXACT Paulis at the optimal angles.  The optimal CHSH of
         the reconstructed 2x2 correlation matrix is the Horodecki value
         S = 2 sqrt(s1^2+s2^2) (s1>=s2 = two largest singular values); for the
         ideal carved pair S = 2 sqrt2 EXACTLY.  CF scale CF(S)=(S-2)/2 on the
         isotropic Bell family; GATES CF(2 sqrt2)=sqrt2-1 and CF(2)=0 are
         reproduced two independent ways: closed form AND a native-WL
         Abramsky-Brandenburger LP (LinearProgramming) rebuilt from scratch.
     (5) NOISE / TEMPERATURE MODEL.  Two-qubit depolarizing channel on the pair
         as a seeded mixed-stabilizer ensemble (each realization applies a
         uniformly random 2-qubit Pauli with probability p); exact per-realization
         Paulis are ensemble-averaged to give CHSH(p), CF(p) over p in [0,0.3].
         The violation-death crossing CHSH=2 and the CHSH=2.25 landing (CF=0.125)
         are located, and cross-checked against the exact closed form
         CHSH(p) = (1-p) 2 sqrt2.

   ------------------------------------------------------------------------------
   DECLARED NON-MBQC / FORCED / ANALYTIC STEPS (honesty discipline, per the
   repo's TeleportWire caveat convention -- every deviation from pure random
   single-qubit measurement is named here):

     [A-ANGLES]  The CHSH optimal-angle EVALUATION (stage 4) is an EXACT LINEAR
                 COMBINATION of measured/exact Pauli expectations at NON-CLIFFORD
                 measurement angles.  The angles are analytic (a(a)B(b) sums via
                 the Horodecki singular-value formula); this is NOT sampled and
                 NOT a Clifford measurement.  It is the one deliberately analytic
                 step, exactly as the task mandates.

     [B-EXACT-RDM] The exact 2-qubit reduced density matrix / 15 Pauli
                 expectations (stage 3 ground truth, stage 4 & 5 inputs) are read
                 directly from the stabilizer tableau via group membership --
                 an exact linear-algebra readout, not a measurement sample.
                 (The SAMPLED tomography of the SAME quantities IS genuine random
                 measurement and is what is compared against this.)

     [C-FORCED-CARVE] The library self-check and the exact-RDM / CHSH stages
                 build the carved pair with "Forced"->0 Z-carve outcomes (a
                 post-selected, byproduct-free preparation) purely so the EXACT
                 comparison targets the canonical frame.  Every SAMPLING stage
                 (no-disturbance stage 2, tomography stage 3) instead uses
                 "Forced"->Automatic: GENUINE random carve outcomes with the Hein
                 Z-rule byproduct frame tracked and corrected classically (XOR of
                 the carved neighbours' outcomes) -- no forced outcomes anywhere
                 in the sampled statistics.

     [D-NOISE-TWIRL] The depolarizing ensemble (stage 5) applies random Pauli
                 gates (Apply X/Y/Z) to model the channel; these are Clifford
                 gates, not measurements.  This is the standard Pauli-twirl
                 realization of the depolarizing channel and is declared as a
                 circuit-model (gate) step, not an MBQC measurement.

     Everything else -- carving (Z-measurements), occupation sampling (Z),
     tomography sampling (X/Y/Z single-qubit measurements) -- is pure
     measurement-pattern MBQC executed through the verified tableau.

   ------------------------------------------------------------------------------
   PRE-REGISTERED CONFIDENCE BUDGET (Bonferroni; fixed BEFORE any sampling).
     Family-wise error alpha = 0.01, split across the sampled hypothesis tests:
       - no-disturbance (stage 2): 3 tests  (n_H=1/2, n_P=1/2, n_H=n_P)
       - tomography     (stage 3): 15 tests (one per two-qubit Pauli expectation)
     => K = 18 tests, per-test delta = alpha/K = 0.01/18.
     Hoeffding two-sided half-width at N shots depends on the observable RANGE
     (Hoeffding: P(|m-t|>=eps) <= 2 exp(-2 N eps^2 / range^2)):
       - occupation Z-outcome in {0,1} (range 1): eps01(N)  = sqrt(ln(2/delta)/(2N))
       - Pauli correlator/marginal in {-1,+1} (range 2): epsPM(N) = 2 eps01(N)
     A single empirical mean m with true value t PASSES iff |m - t| <= eps.
     The two-mean occupation difference n_H-n_P PASSES iff
     |n_H - n_P| <= eps01(N_H) + eps01(N_P).  Stage 2 (occupation) uses eps01;
     stage 3 (tomography, +-1 correlators) uses epsPM.  Bounds printed/enforced.

   NO floating point in the tableau core, the exact Pauli readout, or any exact
   comparison.  Floats appear only in sampled means, Hoeffding bounds, the LP,
   the singular-value CHSH, and timing.  All local; no cloud calls.

   LOAD-ONLY:  CCTHawkingCertLoadOnly = True; Get[...]  (defs only, no self-check)
   Run:        wolframscript -file cct_mbqc_hawking_certification.wl   (fast self-check)
   Full stack: cct_mbqc_hawking_certification_tests.wl  (M=100 @ reps=1000, N>=10^4)
   =========================================================================== *)

If[!ValueQ[CCTHawkingCertDir],
  CCTHawkingCertDir = DirectoryName[$InputFileName]];
Block[{CCTMBQCPatternsLoadOnly = True},
  Get[FileNameJoin[{CCTHawkingCertDir, "cct_mbqc_patterns.wl"}]]];

(* ---------------------------------------------------------------------------
   SECTION H0.  Pre-registered budget constants (fixed before sampling).
   --------------------------------------------------------------------------- *)
CCTHawkAlpha = 1/100;                 (* family-wise error *)
CCTHawkNTests = 18;                   (* 3 no-disturbance + 15 tomography *)
CCTHawkDelta = N[CCTHawkAlpha/CCTHawkNTests];
CCTHawkEps[nn_]   := Sqrt[Log[2/CCTHawkDelta]/(2 nn)];    (* range-1 (0/1) obs *)
CCTHawkEpsPM[nn_] := 2 Sqrt[Log[2/CCTHawkDelta]/(2 nn)];  (* range-2 (+-1) obs *)

(* ---------------------------------------------------------------------------
   SECTION H1.  Mesh-carved Hawking pairs.

   CCTHawkingSelectPairs[reps, maxM] greedily selects up to maxM disjoint
   Bell-pair sites {a=3k+2 (partner/interior), b=3k+3 (Hawking/exterior)} whose
   CLOSED mesh neighbourhoods are pairwise disjoint (an induced matching in the
   mesh).  Disjoint closed regions guarantee (i) no shared carve vertex and
   (ii) no mesh edge between distinct pairs, so after carving each pair is an
   isolated 2-vertex component (a genuine independent Bell pair).
   carveA/carveB = the mesh neighbours of a/b that must be Z-carved
   (= N(a)\{b} and N(b)\{a}); their outcome-parities are the Hein Z-rule
   byproduct frame on a and b.
   --------------------------------------------------------------------------- *)
CCTHawkingSelectPairs[reps_Integer, maxM_Integer] := Module[
  {edges = CCTMeshEdges[reps], n = CCTMeshN[reps], adj, used = Association[],
   pairs = {}, k = 1, a, b, cA, cB, region},
  adj = CCTAdjacency[edges, n];
  While[Length[pairs] < maxM && k <= 3 reps - 2,
   a = 3 k + 2; b = 3 k + 3;                (* partner (interior), Hawking (tip) *)
   cA = Complement[adj[[a]], {b}];          (* a's carve neighbours *)
   cB = Complement[adj[[b]], {a}];          (* b's carve neighbours *)
   region = Union[{a, b}, cA, cB];
   If[NoneTrue[region, KeyExistsQ[used, #] &],
     AppendTo[pairs, <|"k" -> k, "partner" -> a, "hawking" -> b,
        "carveA" -> cA, "carveB" -> cB, "carve" -> Union[cA, cB]|>];
     Scan[(used[#] = True) &, region]];
   k++];
  pairs];

(* Build a fresh mesh tableau and carve the given pairs.  "Forced"->0 gives the
   canonical byproduct-free preparation (exact-comparison mode, decl [C]);
   "Forced"->Automatic gives genuine random carve outcomes and returns, per
   pair, the tracked Z-byproduct frame {fa,fb} (Hein rule: XOR of the carved
   neighbours' outcomes).  Returns <|"tab","frames"|>; CALLER frees the tab. *)
Options[CCTHawkingBuildCarved] = {"Forced" -> 0};
CCTHawkingBuildCarved[reps_Integer, pairs_List, OptionsPattern[]] := Module[
  {edges = CCTMeshEdges[reps], n = CCTMeshN[reps], forced = OptionValue["Forced"],
   tab, out, frames},
  tab = NewGraphStateTableau[n, edges];
  out = Association[];
  Scan[Function[p,
     Scan[(out[#] = MeasurePauli[tab, #, "Z", "ForcedOutcome" -> forced]["Outcome"]) &,
        p["carve"]]], pairs];
  frames = Table[<|
     "partner" -> p["partner"], "hawking" -> p["hawking"],
     "fPartner" -> Mod[Total[Lookup[out, p["carveA"], 0]], 2],
     "fHawking" -> Mod[Total[Lookup[out, p["carveB"], 0]], 2]|>, {p, pairs}];
  <|"tab" -> tab, "frames" -> frames|>];

(* ---------------------------------------------------------------------------
   SECTION H2.  EXACT 2-qubit Pauli expectations and reduced density matrix
   from stabilizer data (declared [B-EXACT-RDM]).

   CCTPauliExp[tab, xs, zs] returns the exact expectation <Q> of the Hermitian
   Pauli Q with X-support xs and Z-support zs (Y at a qubit = that qubit in BOTH
   xs and zs, matching the (x,z)=(1,1)->Y convention of the tableau).  Method
   (destabilizer-subset membership test, exact; same algebra as the sim's
   deterministic-measurement CASE B, generalized to multi-qubit Q):
     T = { destabilizer i : d_i anticommutes with Q }
         (only destabilizers touching supp(Q) can; found via incidence maps)
     scratch = product over i in T of stabilizer row (n+i)   [exact rowsum]
     Q in stabilizer group  <=>  supp(scratch) == supp(Q);  then <Q> = (-1)^sr,
     else <Q> = 0.  (A Pauli with any destabilizer component has different
     support from every group element, so the support test is an exact
     membership test.)
   --------------------------------------------------------------------------- *)
CCTPauliExp[tab_Symbol, xs_List, zs_List] := Module[
  {nn = tab["n"], xsQ = Sort[xs], zsQ = Sort[zs], destTouch, T,
   sx = {}, sz = {}, sr = 0},
  destTouch = Union[
     Flatten[tab["xincD", #] & /@ zsQ],    (* Q has Z at q, dest has X at q *)
     Flatten[tab["zincD", #] & /@ xsQ]];    (* Q has X at q, dest has Z at q *)
  T = Select[destTouch, Function[d,
     OddQ[Length[Intersection[xsQ, tab["rowZ", d]]] +
          Length[Intersection[zsQ, tab["rowX", d]]]]]];
  Scan[Function[i, Module[
     {rid = nn + i, rx, rz, rr, js, rxA, rzA, sxA, szA, s},
     rx = tab["rowX", rid]; rz = tab["rowZ", rid]; rr = tab["r", rid];
     js = Union[rx, rz];
     rxA = CCTBitLookup[rx]; rzA = CCTBitLookup[rz];
     sxA = CCTBitLookup[sx]; szA = CCTBitLookup[sz];
     s = Mod[2 sr + 2 rr +
         Total[gPhase[Boole[KeyExistsQ[rxA, #]], Boole[KeyExistsQ[rzA, #]],
             Boole[KeyExistsQ[sxA, #]], Boole[KeyExistsQ[szA, #]]] & /@ js], 4];
     If[!(s === 0 || s === 2),
       Print["*** CCTPauliExp PARITY VIOLATION (corrupt tableau) i=", i]; Abort[]];
     sr = s/2; sx = SymDiff[sx, rx]; sz = SymDiff[sz, rz]]], T];
  If[Sort[sx] === xsQ && Sort[sz] === zsQ, (-1)^sr, 0]];

(* single-qubit Pauli label -> {contributes to xs?, contributes to zs?} *)
CCTPauliBits["I"] = {False, False}; CCTPauliBits["X"] = {True, False};
CCTPauliBits["Z"] = {False, True};  CCTPauliBits["Y"] = {True, True};

(* exact expectation of Pa (x) Pb on qubits a,b, Pa,Pb in {I,X,Y,Z} *)
CCTPairExp[tab_Symbol, a_Integer, b_Integer, pa_String, pb_String] := Module[
  {ba = CCTPauliBits[pa], bb = CCTPauliBits[pb], xs = {}, zs = {}},
  If[ba[[1]], AppendTo[xs, a]]; If[ba[[2]], AppendTo[zs, a]];
  If[bb[[1]], AppendTo[xs, b]]; If[bb[[2]], AppendTo[zs, b]];
  CCTPauliExp[tab, xs, zs]];

CCTPauliLabels = {"I", "X", "Y", "Z"};

(* 3x3 correlation matrix T[i,j] = <sigma_i^a sigma_j^b>, i,j in {X,Y,Z} order.
   Row index = a-basis, column index = b-basis. *)
CCTPairCorrMatrix[tab_Symbol, a_Integer, b_Integer] :=
  Table[CCTPairExp[tab, a, b, pa, pb], {pa, {"X", "Y", "Z"}}, {pb, {"X", "Y", "Z"}}];

(* exact 4x4 reduced density matrix on {a,b}: (1/4) sum_{Pa,Pb} <Pa Pb> Pa(x)Pb *)
CCTHawkPauliMat["I"] = {{1, 0}, {0, 1}};   CCTHawkPauliMat["X"] = {{0, 1}, {1, 0}};
CCTHawkPauliMat["Y"] = {{0, -I}, {I, 0}};  CCTHawkPauliMat["Z"] = {{1, 0}, {0, -1}};
CCTExactRDM[tab_Symbol, a_Integer, b_Integer] := Module[{acc},
  acc = Sum[
     CCTPairExp[tab, a, b, pa, pb] *
       KroneckerProduct[CCTHawkPauliMat[pa], CCTHawkPauliMat[pb]],
     {pa, CCTPauliLabels}, {pb, CCTPauliLabels}];
  acc/4];

(* the 15 non-identity two-qubit Pauli labels {pa,pb}, pa,pb in {I,X,Y,Z}\{II} *)
CCTHawk15 = DeleteCases[
   Flatten[Table[{pa, pb}, {pa, CCTPauliLabels}, {pb, CCTPauliLabels}], 1],
   {"I", "I"}];

(* ---------------------------------------------------------------------------
   SECTION H3.  NO-DISTURBANCE CHECK (stage 2, the C1 discipline).

   Occupation number operator n = (I - Z)/2 (qubit |1> = one quantum);
   mean occupation = P(Z-outcome 1).  Both Bell-pair qubits have maximally
   mixed 1-qubit marginals, so n_H = n_P = 1/2 exactly.  Sampling (genuine
   random carve + Z read; Z outcomes are frame-INVARIANT, so no correction is
   needed here) estimates n_H, n_P; PASS within the pre-registered Hoeffding
   bounds.  Pooled across all pairs and across `builds` fresh seeded meshes.
   --------------------------------------------------------------------------- *)
CCTHawkingNoDisturbance[reps_Integer, pairs_List, builds_Integer] := Module[
  {hSum = 0, pSum = 0, nShots, bundle},
  nShots = builds * Length[pairs];
  Do[
    bundle = CCTHawkingBuildCarved[reps, pairs, "Forced" -> Automatic];
    Scan[Function[p,
       hSum += MeasurePauli[bundle["tab"], p["hawking"], "Z"]["Outcome"];
       pSum += MeasurePauli[bundle["tab"], p["partner"], "Z"]["Outcome"]], pairs];
    FreeTableau[bundle["tab"]],
    {builds}];
  Module[{nH = N[hSum/nShots], nP = N[pSum/nShots], epsH, epsP},
   epsH = CCTHawkEps[nShots]; epsP = CCTHawkEps[nShots];
   <|"nShots" -> nShots, "nBarHawking" -> nH, "nBarPartner" -> nP,
     "eps" -> epsH, "epsDiff" -> epsH + epsP,
     "passHawkingHalf" -> (Abs[nH - 1/2] <= epsH),
     "passPartnerHalf" -> (Abs[nP - 1/2] <= epsP),
     "passEqual" -> (Abs[nH - nP] <= epsH + epsP),
     "pass" -> (Abs[nH - 1/2] <= epsH && Abs[nP - 1/2] <= epsP &&
                Abs[nH - nP] <= epsH + epsP)|>]];

(* ---------------------------------------------------------------------------
   SECTION H4.  PAULI TOMOGRAPHY through single-qubit MBQC measurements
   (stage 3).  For each of the 9 joint settings (a-basis, b-basis) in
   {X,Y,Z}^2, both qubits are measured (genuine random outcomes); the Hein
   Z-frame is corrected (X/Y outcomes flip under a Z byproduct, Z outcomes do
   not).  The two-qubit correlator is the mean of (-1)^(cA+cB); the single-qubit
   marginals come from the same samples.  All 15 expectations are assembled,
   the RDM reconstructed, and compared to the exact RDM (decl [B]) within the
   pre-registered Hoeffding bounds.  Pooled across pairs and `builds`.
   --------------------------------------------------------------------------- *)
CCTHawkingTomography[reps_Integer, pairs_List, buildsPerSetting_Integer] := Module[
  {settings = Flatten[Table[{pa, pb}, {pa, {"X", "Y", "Z"}}, {pb, {"X", "Y", "Z"}}], 1],
   jointSum = Association[], aSum = Association[], bSum = Association[],
   cnt = Association[], nShots},
  nShots = buildsPerSetting * Length[pairs];
  Do[Module[{pa = st[[1]], pb = st[[2]]},
    jointSum[{pa, pb}] = 0; aSum[{pa, pb}] = 0; bSum[{pa, pb}] = 0;
    Do[Module[{bundle = CCTHawkingBuildCarved[reps, pairs, "Forced" -> Automatic]},
      MapThread[Function[{p, fr},
        Module[{ra, rb, ca, cb},
         ra = MeasurePauli[bundle["tab"], p["partner"], pa]["Outcome"];
         rb = MeasurePauli[bundle["tab"], p["hawking"], pb]["Outcome"];
         ca = Mod[ra + If[pa =!= "Z", fr["fPartner"], 0], 2];
         cb = Mod[rb + If[pb =!= "Z", fr["fHawking"], 0], 2];
         jointSum[{pa, pb}] += (-1)^(ca + cb);
         aSum[{pa, pb}] += (-1)^ca; bSum[{pa, pb}] += (-1)^cb]],
        {pairs, bundle["frames"]}];
      FreeTableau[bundle["tab"]]], {buildsPerSetting}]],
   {st, settings}];
  (* assemble the 15 expectations.  a-basis pa (x) I: from aSum[{pa,*}] (any
     column; use pa paired with "X").  I (x) pb: from bSum[{*,pb}]. *)
  Module[{est = Association[], epsN = CCTHawkEpsPM[nShots]},  (* +-1 correlators *)
   Do[est[{pa, pb}] = N[jointSum[{pa, pb}]/nShots],
     {pa, {"X", "Y", "Z"}}, {pb, {"X", "Y", "Z"}}];
   Do[est[{pa, "I"}] = N[aSum[{pa, "X"}]/nShots], {pa, {"X", "Y", "Z"}}];
   Do[est[{"I", pb}] = N[bSum[{"X", pb}]/nShots], {pb, {"X", "Y", "Z"}}];
   <|"nShots" -> nShots, "eps" -> epsN, "est" -> est|>]];

(* reconstruct RDM from estimated expectations (with <II>=1) *)
CCTReconstructRDM[est_Association] := Module[{acc},
  acc = KroneckerProduct[CCTHawkPauliMat["I"], CCTHawkPauliMat["I"]];  (* <II>=1 *)
  acc = acc + Sum[
     Lookup[est, Key[{pa, pb}], 0] *
       KroneckerProduct[CCTHawkPauliMat[pa], CCTHawkPauliMat[pb]],
     {pa, CCTPauliLabels}, {pb, CCTPauliLabels}];
  acc/4];

(* ---------------------------------------------------------------------------
   SECTION H5.  CHSH from the exact correlation matrix + CF scale.

   Optimal CHSH of a 2x2 correlation matrix T (Horodecki-Horodecki-Horodecki,
   PLA 200, 340 (1995)):  S_opt = 2 sqrt(s1^2 + s2^2), s1>=s2 the two largest
   singular values of T.  This is the max over ALL (generally non-Clifford)
   measurement-angle choices (decl [A-ANGLES]); the EVALUATION here is an exact
   function of the exact/measured Pauli expectations.  For the ideal carved pair
   T is a signed permutation (singular values 1,1,1) so S_opt = 2 sqrt2 exactly.
   An explicit optimal angle set is also evaluated as a cross-check.
   --------------------------------------------------------------------------- *)
CCTCHSHOptimal[T_] := Module[{sv = SingularValueList[N[T]]},
  2 Sqrt[sv[[1]]^2 + sv[[2]]^2]];

(* explicit optimal directions for the ideal graph-state T (X<->Z swap, Y->Y).
   Horodecki construction with a0=X, a1=Z on partner:  b0 ~ (T^T a0 + T^T a1),
   b1 ~ (T^T a0 - T^T a1).  T^T X = Z, T^T Z = X  =>  b0=(X+Z)/sqrt2,
   b1=(Z-X)/sqrt2 = {-1,0,1}/sqrt2 (in {X,Y,Z} components).
   S = <a0 b0> + <a0 b1> + <a1 b0> - <a1 b1>, each <a b> = a.T.b.  This is a
   LINEAR functional of T at FIXED (ideal-optimal, generally non-Clifford)
   angles -- exactly a real Bell test's protocol, and (unlike re-optimizing the
   angles per noisy matrix) it is UNBIASED under ensemble averaging, so it is
   what the noise curve uses. *)
CCTCHSHExplicit[T_] := Module[
  {a0 = {1, 0, 0}, a1 = {0, 0, 1},
   b0 = {1, 0, 1}/Sqrt[2], b1 = {-1, 0, 1}/Sqrt[2], e},
  e[u_, v_] := u . T . v;
  e[a0, b0] + e[a0, b1] + e[a1, b0] - e[a1, b1]];

(* CF closed form on the isotropic Bell family (anchor: hawking_cf_bridge.py) *)
CCTCFofS[s_] := Max[0, (s - 2)/2];

(* --- native-WL Abramsky-Brandenburger LP for CF (independent reproduction of
   the CF anchors; mirrors hawking_cf_bridge.py's ncf_lp/cf_of exactly) --- *)
CCTChshSections = {{0, 0}, {0, 1}, {1, 0}, {1, 1}};
CCTChshCtx = Flatten[Table[{x, y}, {x, 0, 1}, {y, 0, 1}], 1];
CCTChshGlob = Tuples[{0, 1}, 4];         (* (a0,a1,b0,b1) *)
CCTChshM = Module[{M = Table[0, {16}, {16}]},
  Do[Module[{x = CCTChshCtx[[c, 1]], y = CCTChshCtx[[c, 2]]},
    Do[Module[{a = CCTChshSections[[s, 1]], b = CCTChshSections[[s, 2]]},
      Do[Module[{t = CCTChshGlob[[g]], ax, by},
        ax = t[[x + 1]]; by = t[[2 + y + 1]];
        If[{ax, by} == {a, b}, M[[4 (c - 1) + s, g]] = 1]], {g, 16}]], {s, 4}]], {c, 4}];
  M];
CCTChshIsoTable[s_] := Module[{c = s/4, e = Table[0, {16}]},
  Do[Module[{x = CCTChshCtx[[k, 1]], y = CCTChshCtx[[k, 2]], corr},
    corr = If[{x, y} == {1, 1}, -c, c];
    e[[4 (k - 1) + 1 ;; 4 (k - 1) + 4]] =
       {(1 + corr)/4, (1 - corr)/4, (1 - corr)/4, (1 + corr)/4}], {k, 4}];
  e];
CCTCFofSLP[s_] := Module[{e = N[CCTChshIsoTable[s]], sol},
  sol = LinearProgramming[-ConstantArray[1., 16], -CCTChshM, -e,
     ConstantArray[0., 16], Method -> "Simplex"];
  1. - Total[sol]];

(* ---------------------------------------------------------------------------
   SECTION H6.  Two-qubit depolarizing noise / temperature model (stage 5).

   Channel  rho -> (1-p) rho + p (I/4)  realized (Pauli-twirl, decl [D]) as:
   with prob (1-p) do nothing; with prob p apply a uniformly random 2-qubit
   Pauli (independent random single-qubit Pauli on partner and Hawking).  Each
   realization stays a stabilizer state; its EXACT correlation matrix is read
   out and ensemble-averaged over `K` seeded realizations, giving the noisy
   T(p), whence CHSH(p)=Horodecki(T(p)) and CF(p).  Exact closed form for the
   isotropic ideal pair: T(p) = (1-p) T_ideal so CHSH(p) = (1-p) 2 sqrt2.
   --------------------------------------------------------------------------- *)
CCTHawkRandPauli[tab_Symbol, q_Integer] := Module[{r = RandomInteger[{0, 3}]},
  Switch[r, 0, Null, 1, ApplyX[tab, q], 2, ApplyY[tab, q], 3, ApplyZ[tab, q]]];

(* one carved pair's ensemble-averaged correlation matrix at depolarizing p.
   Rebuilds the carved pair (Forced->0 canonical) per realization, applies the
   twirl, reads the exact T.  reps small (local pair) => cheap. *)
CCTHawkNoisyCorr[reps_Integer, pair_, p_, K_Integer] := Module[
  {acc = Table[0., {3}, {3}], a = pair["partner"], b = pair["hawking"]},
  Do[Module[{bundle = CCTHawkingBuildCarved[reps, {pair}, "Forced" -> 0], tab},
     tab = bundle["tab"];
     If[RandomReal[] < p,
       CCTHawkRandPauli[tab, a]; CCTHawkRandPauli[tab, b]];
     acc += N[CCTPairCorrMatrix[tab, a, b]];
     FreeTableau[tab]], {K}];
  acc/K];

(* Noise curve evaluates CHSH at the FIXED ideal-optimal angles (linear,
   unbiased under averaging).  Exact closed form for the isotropic depolarized
   ideal pair: T(p)=(1-p)T_ideal => CHSH(p)=(1-p) 2 sqrt2, CF(p)=max(0,(CHSH-2)/2). *)
CCTHawkNoiseCurve[reps_Integer, pair_, ps_List, K_Integer] :=
  Table[Module[{T = CCTHawkNoisyCorr[reps, pair, p, K], s},
     s = CCTCHSHExplicit[T];
     <|"p" -> p, "CHSH" -> s, "CF" -> CCTCFofS[s],
       "CHSHexact" -> (1 - p) 2 Sqrt[2.], "CFexact" -> CCTCFofS[(1 - p) 2 Sqrt[2.]]|>],
   {p, ps}];

(* exact depolarizing crossings from CHSH(p)=(1-p) 2 sqrt2 *)
CCTHawkPForCHSH[target_] := 1 - target/(2 Sqrt[2]);   (* p where CHSH(p)=target *)

(* ---------------------------------------------------------------------------
   SECTION H9.  Guarded self-check (fast).  Full-scale stack: the tests file.
   --------------------------------------------------------------------------- *)
If[!TrueQ[CCTHawkingCertLoadOnly],
  Module[{reps, pairs, bundle, tab, a, b, rdmExact, rdmSV, svOK, T, sOpt, sExp,
     cfTs, cfLocal, cf225, cfLPTs, cfLPLocal, cfLP225, nd, tomo, recRDM,
     tomoDev, tomoPass, noise, pDeath, p225, headPairs, headOK},
    Print["=== cct_mbqc_hawking_certification.wl self-check ==="];
    Print["    pre-registered budget: alpha=", N[CCTHawkAlpha], " over ",
      CCTHawkNTests, " tests -> per-test delta=", CCTHawkDelta];

    (* --- stage 1: carve a pair @ reps=1, verify vs StateVectorFromTableau --- *)
    Print["--- stage 1: Bell-pair carve == 2-vertex graph state (exact, reps=1) ---"];
    reps = 1; pairs = CCTHawkingSelectPairs[reps, 1];
    a = pairs[[1]]["partner"]; b = pairs[[1]]["hawking"];
    bundle = CCTHawkingBuildCarved[reps, pairs, "Forced" -> 0]; tab = bundle["tab"];
    rdmExact = CCTExactRDM[tab, a, b];
    Module[{v = StateVectorFromTableau[tab], nn = CCTMeshN[reps], T2, other},
      T2 = ArrayReshape[v, ConstantArray[2, nn]];
      other = Complement[Range[nn], {a, b}];
      T2 = Transpose[T2, Ordering[Join[{a, b}, other]]];
      T2 = ArrayReshape[T2, {4, 2^(nn - 2)}];
      rdmSV = T2 . ConjugateTranspose[T2]; rdmSV = rdmSV/Tr[rdmSV]];
    svOK = (Simplify[rdmExact - rdmSV] === Table[0, {4}, {4}]);
    Print["    exact-RDM == StateVectorFromTableau partial trace? ", svOK];
    Print["    RDM = (I + XZ + ZX + YY)/4 (2-vertex graph state = Bell up to local H)"];
    FreeTableau[tab];

    (* --- stage 4 core: exact CHSH + CF gates (fast, uses the exact RDM) --- *)
    Print["--- stage 4: exact CHSH + CF gates ---"];
    reps = 3; pairs = CCTHawkingSelectPairs[reps, 1];
    a = pairs[[1]]["partner"]; b = pairs[[1]]["hawking"];
    bundle = CCTHawkingBuildCarved[reps, pairs, "Forced" -> 0]; tab = bundle["tab"];
    T = CCTPairCorrMatrix[tab, a, b];
    sOpt = CCTCHSHOptimal[T]; sExp = CCTCHSHExplicit[T];
    FreeTableau[tab];
    Print["    correlation matrix T (rows a=X,Y,Z; cols b=X,Y,Z) = ", T];
    Print["    CHSH_opt (Horodecki) = ", sOpt, "  (2 sqrt2 = ", N[2 Sqrt[2]], ")"];
    Print["    CHSH_explicit angles = ", N[sExp]];
    cfTs = CCTCFofS[2 Sqrt[2]]; cfLocal = CCTCFofS[2]; cf225 = CCTCFofS[2.25];
    cfLPTs = CCTCFofSLP[2 Sqrt[2]]; cfLPLocal = CCTCFofSLP[2]; cfLP225 = CCTCFofSLP[2.25];
    Print["    GATE CF(2 sqrt2): closed=", N[cfTs], " LP=", cfLPTs,
      " target sqrt2-1=", N[Sqrt[2] - 1]];
    Print["    GATE CF(2):       closed=", N[cfLocal], " LP=", cfLPLocal, " target 0"];
    Print["    CF(2.25):         closed=", N[cf225], " LP=", cfLP225, " target 0.125"];

    (* --- stage 2: no-disturbance (small sample in self-check) --- *)
    Print["--- stage 2: no-disturbance n_H == n_P (self-check sample) ---"];
    reps = 30; pairs = CCTHawkingSelectPairs[reps, 20];
    SeedRandom[20260713];
    nd = CCTHawkingNoDisturbance[reps, pairs, 30];   (* 20*30=600 shots *)
    Print["    nShots=", nd["nShots"], " n_H=", nd["nBarHawking"],
      " n_P=", nd["nBarPartner"], " eps=", nd["eps"], " pass=", nd["pass"]];

    (* --- stage 3: tomography (small sample in self-check) --- *)
    Print["--- stage 3: Pauli tomography vs exact RDM (self-check sample) ---"];
    bundle = CCTHawkingBuildCarved[reps, pairs, "Forced" -> 0];
    rdmExact = CCTExactRDM[bundle["tab"], pairs[[1]]["partner"], pairs[[1]]["hawking"]];
    FreeTableau[bundle["tab"]];
    SeedRandom[20260714];
    tomo = CCTHawkingTomography[reps, pairs, 20];    (* 20*20=400 shots/setting *)
    recRDM = CCTReconstructRDM[tomo["est"]];
    tomoDev = Max[Table[Abs[Lookup[tomo["est"], Key[pl], 0] -
        Re[Tr[ConjugateTranspose[KroneckerProduct[CCTHawkPauliMat[pl[[1]]], CCTHawkPauliMat[pl[[2]]]]] . rdmExact]]],
       {pl, CCTHawk15}]];
    tomoPass = (tomoDev <= tomo["eps"]);
    Print["    nShots/setting=", tomo["nShots"], " max|est-exact|=", tomoDev,
      " eps=", tomo["eps"], " pass=", tomoPass];
    Print["    reconstructed RDM ~ exact RDM (Frobenius) = ",
      Sqrt[Total[Abs[Flatten[recRDM - rdmExact]]^2]]];

    (* --- stage 5: noise curve (small K in self-check) --- *)
    Print["--- stage 5: depolarizing CHSH(p)/CF(p) curve ---"];
    reps = 3; pairs = CCTHawkingSelectPairs[reps, 1];
    SeedRandom[20260715];
    noise = CCTHawkNoiseCurve[reps, pairs[[1]], {0, 0.1, 0.2, 0.25, 0.3}, 400];
    Do[Print["    p=", nr["p"], " CHSH=", nr["CHSH"], " (exact ", nr["CHSHexact"],
       ") CF=", nr["CF"]], {nr, noise}];
    pDeath = 1 - 1/Sqrt[2]; p225 = 1 - 2.25/(2 Sqrt[2]);
    Print["    exact violation-death p (CHSH=2)   = ", N[pDeath]];
    Print["    exact p for CHSH=2.25 (CF=0.125)   = ", N[p225]];

    (* --- stage 1 scale: M disjoint pairs, all exact Bell (reps=100) --- *)
    Print["--- stage 1 scale: M disjoint Hawking pairs, all exact 2 sqrt2 ---"];
    reps = 100; headPairs = CCTHawkingSelectPairs[reps, 100];
    bundle = CCTHawkingBuildCarved[reps, headPairs, "Forced" -> 0]; tab = bundle["tab"];
    headOK = AllTrue[headPairs, Function[p,
       CCTCHSHOptimal[CCTPairCorrMatrix[tab, p["partner"], p["hawking"]]] > 2.8]];
    FreeTableau[tab];
    Print["    M=", Length[headPairs], " pairs @ reps=", reps,
      "; every pair CHSH>2.8 (== 2 sqrt2)? ", headOK];

    Print[];
    Print["CCTHawkingCertSelfCheck: ", <|
      "Stage1_BellExact" -> svOK, "Stage2_NoDisturb" -> nd["pass"],
      "Stage3_Tomography" -> tomoPass,
      "Stage4_CHSH2sqrt2" -> (Abs[sOpt - 2 Sqrt[2]] < 10^-9),
      "Stage4_CFgates" -> (Abs[cfLPTs - (Sqrt[2] - 1)] < 10^-6 && Abs[cfLPLocal] < 10^-7),
      "Stage5_NoiseExact" -> (Abs[noise[[1]]["CHSH"] - 2 Sqrt[2]] < 0.05),
      "Stage1_Mpairs" -> headOK,
      "AllPass" -> (svOK && nd["pass"] && tomoPass && headOK)|>];
  ]
]
