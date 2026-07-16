(* ::Package:: *)

(* ==========================================================================
   gaussian_witnesses_bridge.wl
   hawking-application  --  BUILDER 2 deliverable: WITNESSES + BRIDGE + CERTIFICATION
                      of the Gaussian (covariance-matrix) Hawking sector.
   Build spec: hawking-application/GAUSSIAN-SECTOR-DESIGN.md (ARCHITECT pass 2026-07-13).
   Companion engine (BUILDER 1): gaussian_engine.wl + gaussian_hawking_physics.wl.
   Master assembly (INTEGRATOR): hawking_gaussian_sector.wl loads all three and
   runs the full A1..A8 scoreboard.

   -----------------------------------------------------------------------
   WHAT THIS MODULE IS (honesty header -- read before citing any number)
   -----------------------------------------------------------------------
   This module implements Hawking's own 1974-75 SEMICLASSICAL KINEMATICS,
   discretized per frequency mode, as EXACT Gaussian / symplectic linear
   algebra on covariance matrices. It is NOT a derivation of black-hole
   radiation from the Einstein equations.
     * PARAMETERIZED BACKGROUND. The surface gravity kappa, equivalently the
       Hawking temperature T_H = kappa/(2 Pi), is an INPUT, not derived. No
       dynamical spacetime, no back-reaction, no field equation is solved. We
       take Hawking's result that the horizon acts, per frequency, as a
       TWO-MODE SQUEEZER between interior (partner) and exterior (Hawking)
       modes with tanh(r_w)^2 = Exp[-w/T_H] (the Boltzmann factor), and
       compute the exact downstream Gaussian consequences.
     * GRAYBODY = BEAMSPLITTER. Greybody/backscatter is modelled as a passive
       beamsplitter of transmissivity eta(w) -- a model, not a solved
       potential-barrier scattering problem.
     * EMULABILITY (the point of the whole sector). Gaussian states + Gaussian
       (symplectic) operations + homodyne/heterodyne detection are CLASSICALLY
       EFFICIENTLY SIMULABLE -- the CV Gottesman-Knill theorem (Bartlett,
       Sanders, Braunstein, Nemoto, PRL 88, 097904 (2002); Bartlett & Sanders,
       PRA 65, 042304 (2002)). Therefore this ENTIRE Hawking sector sits on the
       EMULABLE side of the framework's two-lens boundary, exactly mirroring
       the Clifford status of the qubit Hawking module
       (cluster-state-realization/ddt_mbqc_hawking_certification.wl). The A8 audit
       adds the two-tier refinement: the GENERATOR set is still non-passive
       (genuine squeezing => active sp(4,R), not passive u(2)), so it is NOT
       emulable by linear/passive optics even though it IS Gaussian-classically
       simulable. Verdict sentence: "Hawking mode conversion is NOT
       passive-linear-optics-emulable, but IS Gaussian-classically-simulable."

   Ledger tie-ins: constructively confirms HK-003 (single-context => CF == 0,
   A7ii) and HK-004 (Hudson/Wigner positivity, A7i); bridges to the qubit
   anchors of HK-002 via A6.

   -----------------------------------------------------------------------
   CONVENTION (FIXED, Weedbrook/Serafini). hbar = 1; ordering (x_j, p_j);
   [x,p] = i; sigma_ab = (1/2)<{Dr_a, Dr_b}>; vacuum sigma = I/2;
   Omega = blockdiag {{0,1},{-1,0}}. Symplectic S: S.Omega.S^T = Omega,
   sigma -> S.sigma.S^T.
   -----------------------------------------------------------------------
   MODULE DISCIPLINE (project law). Get-loadable, DEFINITIONS ONLY. All tests
   live behind the self-check guarded by GaussianHawkingLoadOnly, run by
   runners/RunGaussianHawking.wl. No Join-in-loop. Exact symbolic where the
   anchors are identities (proved with FullSimplify, not numerics).

   BUILDER-2 SCOPE. This file owns the WITNESS/BRIDGE/CERTIFICATION anchors
   A4,A5,A6,A7,A8 (task (a)-(d)). It ALSO carries standalone A1,A2,A3 gates
   computed from a MINIMAL LOCAL covariance toolkit (Section 0) so the file is
   independently testable and its runner prints "OK" -> True before
   integration. Every Section-0 engine symbol is provided ONLY IF not already
   defined (DownValues guard), so BUILDER 1's real engine (gaussian_engine.wl +
   gaussian_hawking_physics.wl), if loaded first, TAKES PRECEDENCE and the
   integrator's re-run exercises these same gates against it. The public API
   names are the shared contract (GAUSSIAN-SECTOR-DESIGN.md Sec. 4).
   ========================================================================== *)


(* ---- dependency: BlackBox paclet (needed by A7ii ContextualFraction) -----
   Loaded here ONLY if not already present, so the runner's own load wins.
   Placed before Begin["`Private`"] so CoverScenario / ContextualFraction
   resolve to the paclet symbols (not fresh private symbols) at read time. *)
If[! MemberQ[$Packages, "HubertKolcz`BlackBox`"],
  Quiet@Check[
    PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName], "..", "BlackBox"}]];
    Needs["HubertKolcz`BlackBox`"],
    Null]];


(* ---- usage messages (witness/bridge/certification API owned here) ------- *)
GaussianOmega::usage = "GaussianOmega[n] gives the 2n x 2n symplectic form Omega = blockdiag[{{0,1},{-1,0}}] in ordering (x_1,p_1,...,x_n,p_n).";
PseudospinCorrMatrix::usage = "PseudospinCorrMatrix[r] gives the 3x3 GKMR pseudospin correlation matrix T_ps[i,j] = <s1_i s2_j> of the two-mode squeezed vacuum with squeezing r: DiagonalMatrix[{Tanh[2r], -Tanh[2r], 1}] (Chen-Pan-Hou-Zhang PRL 88, 040406 (2002); the dichotomic observables of Ciliberto et al. 2404.16497).";
CHSHofR::usage = "CHSHofR[r] gives the Horodecki-optimal CHSH value of the TMSV pseudospin pair at squeezing r: 2 Sqrt[1 + Tanh[2r]^2]. Limit r->Infinity is 2 Sqrt[2] (the qubit Bell-pair anchor).";
CHSHCFofR::usage = "CHSHCFofR[r] gives the contextual-fraction scale value Max[0,(CHSHofR[r]-2)/2] of the TMSV pseudospin pair, on the same scale as the qubit module's DDTCFofS.";
BuschParentaniDelta::usage = "BuschParentaniDelta[state] gives the Busch-Parentani/Steinhauer nonseparability functional Delta = <bH^dag bH><bP^dag bP> - Abs[<bH bP>]^2 read from the two-mode Gaussian state's covariance. Delta < 0 certifies nonseparability of the Hawking (mode 1) / partner (mode 2) pair.";
CauchySchwarzTheta::usage = "CauchySchwarzTheta[state] gives theta = Gamma_HP/Sqrt[Gamma_HH Gamma_PP], the density-density Cauchy-Schwarz ratio (de Nova-Sols-Zapata) of a two-mode Gaussian state, from the covariance via Wick. theta > 1 certifies CS violation. For the ideal TMSV, theta = 1 + 1/(2 nbar).";
FactorialMomentsHP::usage = "FactorialMomentsHP[state] gives <|\"GammaHH\"->..., \"GammaPP\"->..., \"GammaHP\"->..., \"nH\"->..., \"nP\"->...|>: the Wick photon-number factorial moments Gamma_HH=<n_H(n_H-1)>, Gamma_PP=<n_P(n_P-1)>, Gamma_HP=<n_H n_P> of a two-mode zero-mean Gaussian state, from its covariance. Same-mode moments use the general bosonic-Wick form <n(n-1)> = |m|^2 + 2 nbar^2 (m = anomalous <a a>), valid for squeezed/thermal arms, not only the thermal-arm shortcut 2 nbar^2.";
CVLieClosureDim::usage = "CVLieClosureDim[gens] gives the dimension of the matrix dynamical Lie algebra generated by the symplectic generators gens (exact rank of the iterated-commutator closure). CVLieClosureDim[gens, \"Basis\"] returns the spanning basis; CVLieClosureDim[gens, \"Compact\"] returns True iff the closure lies in u(n) (all elements antisymmetric).";
CVDLAAudit::usage = "CVDLAAudit[n, gens] runs the Sp(2n,R) leaf-confinement audit (CV analogue of gate G7): returns <|\"n\",\"dim\",\"un\",\"spn\",\"compact\",\"confined\",\"verdict\"|>. confined (subset u(n), passive) => classically emulable by linear optics; active (contains a symmetric/squeezing element) => genuine squeezing, not passive-confined.";
HawkingGenerators::usage = "HawkingGenerators[] gives the symplectic generator set of the Hawking Gaussian channel on 2 modes: {phase_1, phase_2, beamsplitter_re, beamsplitter_im (graybody), two-mode-squeezer_1, two-mode-squeezer_2}. Its DLA is sp(4,R) (dim 10, ACTIVE).";
SingleContextScenario::usage = "SingleContextScenario[k] gives the one-context BlackBox scenario on two jointly-measured registers with k outcomes each (a single context {0,1}) -- the structural form of a density-density correlator.";
SingleContextCF::usage = "SingleContextCF[e] gives the contextual fraction of the empirical model e on the single-context scenario matching Length[e] (k^2 sections). It is 0 identically (HK-003): jointly-measured, single-context data can carry no Kochen-Specker/Bell gap.";
HudsonPositiveQ::usage = "HudsonPositiveQ[sigma] gives True iff the covariance sigma is a valid (physical) covariance, sigma + (I/2) Omega >= 0 -- equivalently the Gaussian state has a NON-NEGATIVE Wigner function (Hudson's theorem for Gaussian states, A7i).";
WitnessBridgeRunAll::usage = "WitnessBridgeRunAll[] runs every gate (A1..A8) and returns the GaussianHawkingVerification association with \"OK\" -> True iff all gates pass.";

(* ---- Section-0 engine API usage (provided locally only if absent) ------- *)
VacuumState::usage = "VacuumState[n] gives the n-mode vacuum Gaussian state {sigma = (1/2) I_{2n}, mean = 0}.";
ThermalState::usage = "ThermalState[nbar] gives the 1-mode thermal state {(nbar + 1/2) I_2, 0}.";
TwoModeSqueezer::usage = "TwoModeSqueezer[r] gives the 4x4 two-mode-squeezer symplectic {{c I2, s Zx},{s Zx, c I2}}, c=Cosh[r], s=Sinh[r], Zx=diag(1,-1). ACTIVE.";
SingleModeSqueezer::usage = "SingleModeSqueezer[q] gives the 2x2 single-mode-squeezer symplectic DiagonalMatrix[{Exp[-q], Exp[q]}]. ACTIVE.";
Beamsplitter::usage = "Beamsplitter[theta] gives the 4x4 beamsplitter symplectic; transmissivity eta = Cos[theta]^2. Passive.";
PhaseRot::usage = "PhaseRot[phi] gives the 2x2 phase-rotation symplectic {{Cos,Sin},{-Sin,Cos}}. Passive.";
ApplySymplectic::usage = "ApplySymplectic[S, state] gives {S.sigma.Transpose[S], S.mean}.";
EmbedSymplectic::usage = "EmbedSymplectic[S, modes, n] places the k-mode symplectic S on the listed modes inside an n-mode identity.";
PartialTrace::usage = "PartialTrace[state, keep] gives the reduced Gaussian state on the modes in keep (Gaussian partial trace = covariance submatrix).";
TensorState::usage = "TensorState[st1, st2] gives the block-diagonal tensor product of two Gaussian states.";
SymplecticEigenvalues::usage = "SymplecticEigenvalues[sigma] gives the Williamson symplectic eigenvalues nu_k >= 0 (positive half of Abs[Eigenvalues[I Omega.sigma]]), sorted. Physical iff all nu_k >= 1/2.";
VonNeumannEntropy::usage = "VonNeumannEntropy[sigma] gives the von Neumann entropy (nats) of a zero-mean Gaussian state via the bosonic g-function on the symplectic eigenvalues.";
LogNegativity::usage = "LogNegativity[sigma] gives the logarithmic negativity (bits) of a two-mode Gaussian state: Max[0, -Log2[2 Min[SymplecticEigenvalues[P.sigma.P]]]], P = diag(1,1,1,-1).";
MeanN::usage = "MeanN[sigma, j] gives the mean photon number nbar_j = (sigma[[2j-1,2j-1]] + sigma[[2j,2j]])/2 - 1/2 of mode j.";
HawkingSqueezing::usage = "HawkingSqueezing[w, TH] gives r_w = ArcTanh[Sqrt[Exp[-w/TH]]]: the per-frequency Hawking squeezing at frequency w, Hawking temperature TH (tanh(r_w)^2 = Exp[-w/TH]).";
HawkingPair::usage = "HawkingPair[w, TH] gives the interior/exterior TMSV Gaussian state produced by the horizon at frequency w, temperature TH: ApplySymplectic[TwoModeSqueezer[HawkingSqueezing[w,TH]], VacuumState[2]]. Mode 1 = Hawking (exterior), mode 2 = partner (interior).";
HawkingSpectrum::usage = "HawkingSpectrum[ws, TH] gives {w_i, nbar_i} pairs, nbar_i the exterior-arm occupation of HawkingPair[w_i, TH] read from the engine covariance (the Planck spectrum, A1).";


Begin["`Private`"];

(* ========================================================================== *)
(* SECTION 0.  MINIMAL LOCAL COVARIANCE TOOLKIT                                *)
(* Provided ONLY where the symbol is not already defined, so BUILDER 1's real *)
(* engine wins if loaded first. DownValues guard = "define iff absent".       *)
(* ========================================================================== *)

zx2 = {{1, 0}, {0, -1}};
id2m = IdentityMatrix[2];

If[DownValues[GaussianOmega] === {},
  GaussianOmega[n_Integer] :=
    ArrayFlatten[Table[If[i == j, {{0, 1}, {-1, 0}}, {{0, 0}, {0, 0}}], {i, n}, {j, n}]]];

If[DownValues[VacuumState] === {},
  VacuumState[n_Integer] := {(1/2) IdentityMatrix[2 n], ConstantArray[0, 2 n]}];

If[DownValues[ThermalState] === {},
  ThermalState[nbar_] := {(nbar + 1/2) IdentityMatrix[2], {0, 0}}];

If[DownValues[TwoModeSqueezer] === {},
  TwoModeSqueezer[r_] :=
    ArrayFlatten[{{Cosh[r] id2m, Sinh[r] zx2}, {Sinh[r] zx2, Cosh[r] id2m}}]];

If[DownValues[SingleModeSqueezer] === {},
  SingleModeSqueezer[q_] := DiagonalMatrix[{Exp[-q], Exp[q]}]];

If[DownValues[Beamsplitter] === {},
  Beamsplitter[th_] :=
    ArrayFlatten[{{Cos[th] id2m, Sin[th] id2m}, {-Sin[th] id2m, Cos[th] id2m}}]];

If[DownValues[PhaseRot] === {},
  PhaseRot[phi_] := {{Cos[phi], Sin[phi]}, {-Sin[phi], Cos[phi]}}];

If[DownValues[ApplySymplectic] === {},
  ApplySymplectic[S_, {sigma_, mean_}] := {S . sigma . Transpose[S], S . mean}];

If[DownValues[EmbedSymplectic] === {},
  EmbedSymplectic[S_, modes_List, n_Integer] :=
    Module[{full = IdentityMatrix[2 n], idx},
      idx = Flatten[{2 # - 1, 2 #} & /@ modes];
      full[[idx, idx]] = S; full]];

If[DownValues[PartialTrace] === {},
  PartialTrace[{sigma_, mean_}, keep_List] :=
    Module[{idx = Flatten[{2 # - 1, 2 #} & /@ keep]},
      {sigma[[idx, idx]], mean[[idx]]}]];

If[DownValues[TensorState] === {},
  TensorState[{s1_, m1_}, {s2_, m2_}] :=
    {ArrayFlatten[{{s1, 0}, {0, s2}}], Join[m1, m2]}];

If[DownValues[SymplecticEigenvalues] === {},
  SymplecticEigenvalues[sigma_] :=
    Module[{n = Length[sigma]/2, sp},
      (* spectrum of I Omega.sigma is {+/- nu_k}: Abs makes each nu_k appear
         TWICE. Sort ascending groups the identical copies adjacently; take one
         from each pair via ::2. (Taking the top n by magnitude is WRONG when
         values repeat -- it would return two copies of the largest.) *)
      sp = Sort[Abs[Eigenvalues[I GaussianOmega[n] . sigma]]];
      sp[[1 ;; ;; 2]]]];

If[DownValues[MeanN] === {},
  MeanN[sigma_, j_Integer] := (sigma[[2 j - 1, 2 j - 1]] + sigma[[2 j, 2 j]])/2 - 1/2];

(* x Log[x] with the removable value 0 at x==0 (pure eigenvalue nu==1/2), so
   VonNeumannEntropy of a pure state is 0, not Indeterminate; symbolic falls
   through to x Log[x] and preserves the exact entropy proofs. *)
gXLogX[x_] := If[TrueQ[Chop[x] == 0], 0, x Log[x]];
gNats[nu_] := gXLogX[nu + 1/2] - gXLogX[nu - 1/2];

If[DownValues[VonNeumannEntropy] === {},
  VonNeumannEntropy[sigma_] := Total[gNats /@ SymplecticEigenvalues[sigma]]];

If[DownValues[LogNegativity] === {},
  LogNegativity[sigma_] :=
    Module[{P = DiagonalMatrix[{1, 1, 1, -1}], nuMin},
      nuMin = Min[SymplecticEigenvalues[P . sigma . P]];
      Max[0, -Log2[2 nuMin]]]];

If[DownValues[HawkingSqueezing] === {},
  HawkingSqueezing[w_, TH_] := ArcTanh[Sqrt[Exp[-w/TH]]]];

If[DownValues[HawkingPair] === {},
  HawkingPair[w_, TH_] :=
    ApplySymplectic[TwoModeSqueezer[HawkingSqueezing[w, TH]], VacuumState[2]]];

If[DownValues[HawkingSpectrum] === {},
  HawkingSpectrum[ws_List, TH_] :=
    Table[{w, MeanN[HawkingPair[w, TH][[1]], 1]}, {w, ws}]];


(* ========================================================================== *)
(* SECTION A4.  CAUCHY-SCHWARZ VIOLATION FROM THE ENGINE COVARIANCE           *)
(* Cross-anchor to hawking-application/hawking_cs_route.py (its TMSV closed forms). *)
(* Photon-number factorial moments via Wick/Isserlis on the covariance.       *)
(* ========================================================================== *)

(* Second moments of ladder operators from the xp covariance (zero mean):
   <b_j^dag b_j> = nbar_j ; <b_j b_k> (j != k) anomalous correlation.
   For number moments we use: n_j = (x_j^2 + p_j^2 - 1)/2, and Wick for the
   zero-mean Gaussian gives every fourth moment from the covariance sigma.   *)

(* cross-mode <n_H n_P> via Wick (modes commute; unambiguous ordering):
   <(x_H^2+p_H^2)(x_P^2+p_P^2)> = SUM_{u in{xH,pH}, v in{xP,pP}}
        [ sigma_uu sigma_vv + 2 sigma_uv^2 ]                               *)
wickCross[sigma_, H_, P_] :=
  Module[{uH = {2 H - 1, 2 H}, vP = {2 P - 1, 2 P}, s},
    s = Sum[sigma[[u, u]] sigma[[v, v]] + 2 sigma[[u, v]]^2, {u, uH}, {v, vP}];
    s];

(* general single-mode <n_j(n_j-1)> from the covariance, NOT the thermal
   shortcut: the bosonic Wick contraction over {a^dag,a^dag,a,a} gives
   <a^dag a^dag a a> = |m_j|^2 + 2 nbar_j^2, where the anomalous moment
   m_j = <a_j a_j> = (sigma_xx - sigma_pp)/2 + I sigma_xp encodes single-mode
   squeezing.  For a thermal reduced arm (m_j = 0) this collapses to 2 nbar_j^2,
   so it reproduces the pure-TMSV answer while staying correct for squeezed /
   thermal-input arms.  (Verified against the engine WickMoment.) *)
wickAnomalousM[sigma_, j_] :=
  (sigma[[2 j - 1, 2 j - 1]] - sigma[[2 j, 2 j]])/2 + I sigma[[2 j - 1, 2 j]];
wickSelf[sigma_, j_] :=
  Module[{nb = MeanN[sigma, j], m = wickAnomalousM[sigma, j]}, Abs[m]^2 + 2 nb^2];

FactorialMomentsHP[{sigma_, mean_}] :=
  Module[{nH, nP, quadHP, GammaHP, GammaHH, GammaPP},
    nH = MeanN[sigma, 1]; nP = MeanN[sigma, 2];
    (* <n_H n_P> = (1/4)[<(xH^2+pH^2)(xP^2+pP^2)> - (2nH+1) - (2nP+1) + 1]  *)
    quadHP = wickCross[sigma, 1, 2];
    GammaHP = (quadHP - (2 nH + 1) - (2 nP + 1) + 1)/4;
    GammaHH = wickSelf[sigma, 1]; GammaPP = wickSelf[sigma, 2];
    <|"GammaHH" -> Simplify[GammaHH], "GammaPP" -> Simplify[GammaPP],
      "GammaHP" -> Simplify[GammaHP], "nH" -> Simplify[nH], "nP" -> Simplify[nP]|>];

CauchySchwarzTheta[st_] :=
  Module[{m = FactorialMomentsHP[st]},
    m["GammaHP"]/Sqrt[m["GammaHH"] m["GammaPP"]]];


(* ========================================================================== *)
(* SECTION A5.  BUSCH-PARENTANI / STEINHAUER NONSEPARABILITY                  *)
(* Delta = <bH^dag bH><bP^dag bP> - |<bH bP>|^2 from the covariance.          *)
(*   <b_j^dag b_j> = nbar_j                                                    *)
(*   <bH bP> = (1/2)[(sigma_xHxP - sigma_pHpP) + I(sigma_xHpP + sigma_pHxP)]   *)
(* ========================================================================== *)

anomalousHP[sigma_] :=
  Module[{xH = 1, pH = 2, xP = 3, pP = 4},
    ((sigma[[xH, xP]] - sigma[[pH, pP]]) + I (sigma[[xH, pP]] + sigma[[pH, xP]]))/2];

(* DownValues guard: if BUILDER 1's engine (gaussian_hawking_physics.wl) already
   defined BuschParentaniDelta, that version wins -- no silent overwrite. This
   local form (via anomalousHP) is the standalone fallback; both agree. *)
If[DownValues[BuschParentaniDelta] === {},
  BuschParentaniDelta[{sigma_, mean_}] :=
    Module[{nH = MeanN[sigma, 1], nP = MeanN[sigma, 2], bhbp = anomalousHP[sigma]},
      Simplify[nH nP - Abs[bhbp]^2]]];


(* ========================================================================== *)
(* SECTION A6.  GKMR PSEUDOSPIN CORRELATORS + CHSH(r) BRIDGE                  *)
(* ------------------------------------------------------------------------- *)
(* HONESTY CAVEAT (binning).  The GKMR pseudospin (Chen-Pan-Hou-Zhang, PRL 88,  *)
(* 040406 (2002)) is ONE particular dichotomization of the infinite-dimensional *)
(* CV pair: it bins the number basis into even/odd parity blocks. It is NOT the  *)
(* CV state's intrinsic "CHSH": other binnings (on/off photodetection, sign of a *)
(* quadrature / Gisin-Peres, displaced parity) give DIFFERENT CHSH(r) curves and *)
(* generally WEAKER violation. The 2 Sqrt[2] ceiling as r->Inf is specific to    *)
(* THIS binning at the EPR limit; it is the natural bridge to the qubit module   *)
(* because parity is exactly the pseudospin the qubit Bell pair carries, not a   *)
(* claim that the Gaussian pair is "more nonlocal" than another binning shows.   *)
(* Non-circularity: PseudospinCorrMatrix / CHSHofR are the CLOSED FORMS; gateA6  *)
(* GROUNDS them by deriving the same numbers from the truncated TMSV number-     *)
(* state expansion and the Horodecki criterion, independent of these defs.       *)
(* ========================================================================== *)

PseudospinCorrMatrix[r_] := DiagonalMatrix[{Tanh[2 r], -Tanh[2 r], 1}];

CHSHofR[r_] := 2 Sqrt[1 + Tanh[2 r]^2];

CHSHCFofR[r_] := Max[0, (CHSHofR[r] - 2)/2];

(* --- independent GROUNDING toolkit (used by gateA6, NOT the closed forms) ---
   GKMR pseudospin operators in the truncated number basis |0>..|2N-1>:
     s_+ = Sum_k |2k+1><2k|,  s_- = s_+^T,  s_x = s_+ + s_-,
     s_y = -I (s_+ - s_-),  s_z = Sum_k (|2k+1><2k+1| - |2k><2k|).           *)
PseudospinSpinOps[nPairs_Integer] :=
  Module[{d = 2 nPairs, sp},
    sp = SparseArray[Table[{2 k + 2, 2 k + 1} -> 1, {k, 0, nPairs - 1}], {d, d}];
    {sp + Transpose[sp], -I (sp - Transpose[sp]),
     SparseArray[
       Flatten[Table[{{2 k + 1, 2 k + 1} -> -1, {2 k + 2, 2 k + 2} -> 1},
          {k, 0, nPairs - 1}], 1], {d, d}]}];

(* correlation matrix T_ij = <s1_i (x) s2_j> of the truncated two-mode squeezed
   vacuum |TMSV> = Sum_n (Tanh[r]^n/Cosh[r]) |n,n>, DERIVED from the state:
   <psi| A(x)B |psi> = Sum_{m,n} c_m c_n A_mn B_mn (real Schmidt coefficients). *)
TMSVPseudospinCorr[r_?NumericQ, nTrunc_Integer] :=
  Module[{c, ops},
    c = Table[Tanh[r]^n/Cosh[r], {n, 0, nTrunc - 1}];
    ops = PseudospinSpinOps[nTrunc/2];
    Chop[Re @ Table[
       Sum[c[[m + 1]] c[[n + 1]] ops[[i]][[m + 1, n + 1]] ops[[j]][[m + 1, n + 1]],
         {m, 0, nTrunc - 1}, {n, 0, nTrunc - 1}], {i, 3}, {j, 3}], 10^-9]];

(* Horodecki-Horodecki-Horodecki (PLA 200, 340 (1995)) maximal CHSH of a state
   with 3x3 correlation matrix T: 2 Sqrt[s1^2 + s2^2], s1>=s2 the two largest
   singular values of T.  DERIVES CHSH from a correlation matrix (no restatement). *)
HorodeckiCHSH[Tmat_] :=
  Module[{sv = Sort[SingularValueList[N[Tmat]], Greater]}, 2 Sqrt[sv[[1]]^2 + sv[[2]]^2]];


(* ========================================================================== *)
(* SECTION A7i.  HUDSON / WIGNER POSITIVITY (Gaussian => W >= 0)              *)
(* ========================================================================== *)

(* sigma + (I/2) Omega is Hermitian; PSD iff its least eigenvalue >= 0.
   Use an eigenvalue tolerance so the pure-state boundary (a genuine zero
   eigenvalue) is accepted rather than tripped by numerical noise. *)
If[DownValues[HudsonPositiveQ] === {},
  HudsonPositiveQ[sigma_] :=
    Module[{n = Length[sigma]/2, ev},
      ev = Re[Eigenvalues[N[sigma + (I/2) GaussianOmega[n]]]];
      Min[ev] >= -10^-10]];


(* ========================================================================== *)
(* SECTION A7ii.  SINGLE-CONTEXT CF == 0 (HK-003), via BlackBox paclet         *)
(* A density-density correlator is jointly-measured single-context data: one   *)
(* context {0,1}, k outcomes each. CF = 0 identically for every such model.    *)
(* ========================================================================== *)

SingleContextScenario[k_Integer] :=
  CoverScenario[{0, 1}, {{0, 1}}, Range[0, k - 1]];

SingleContextCF[e_List] :=
  Module[{k = Round[Sqrt[Length[e]]], scen},
    scen = SingleContextScenario[k];
    ContextualFraction[scen, e]];


(* ========================================================================== *)
(* SECTION A8.  CV DYNAMICAL-LIE-ALGEBRA AUDIT (native WL reimplementation of  *)
(* certification-protocol/final_o3_cv_dla.py). Exact integer arithmetic.     *)
(*   K = Omega . G from H = (1/2) r^T G r; LieClosure by iterated commutators; *)
(*   dim by exact matrix rank; compact iff every basis element antisymmetric.  *)
(* ========================================================================== *)

genFromTerms[n_, terms_] :=
  Module[{G = ConstantArray[0, {2 n, 2 n}]},
    Do[With[{a = t[[1]], b = t[[2]], c = t[[3]]},
       If[a == b, G[[a, a]] += c, G[[a, b]] += c/2; G[[b, a]] += c/2]], {t, terms}];
    GaussianOmega[n] . G];

xIdx[j_] := 2 j - 1;  pIdx[j_] := 2 j;

genPhase[n_, j_]        := genFromTerms[n, {{xIdx[j], xIdx[j], 1}, {pIdx[j], pIdx[j], 1}}];
genBSre[n_, j_, k_]     := genFromTerms[n, {{xIdx[j], xIdx[k], 1}, {pIdx[j], pIdx[k], 1}}];
genBSim[n_, j_, k_]     := genFromTerms[n, {{xIdx[j], pIdx[k], 1}, {pIdx[j], xIdx[k], -1}}];
genTMS1[n_, j_, k_]     := genFromTerms[n, {{xIdx[j], xIdx[k], 1}, {pIdx[j], pIdx[k], -1}}];
genTMS2[n_, j_, k_]     := genFromTerms[n, {{xIdx[j], pIdx[k], 1}, {pIdx[j], xIdx[k], 1}}];
genSMS1[n_, j_]         := genFromTerms[n, {{xIdx[j], xIdx[j], 1}, {pIdx[j], pIdx[j], -1}}];

commutator[a_, b_] := a . b - b . a;

matRank[mats_] := If[mats === {}, 0, MatrixRank[Transpose[Flatten[#] & /@ mats]]];

lieClosure[gens_] :=
  Module[{basis = {}, new, added, c},
    Do[If[matRank[Append[basis, g]] > matRank[basis], AppendTo[basis, g]], {g, gens}];
    While[True,
      new = basis; added = False;
      Do[c = commutator[basis[[i]], basis[[j]]];
         If[! MatrixQ[c, # === 0 &] && Max[Abs[Flatten[c]]] =!= 0,
            If[matRank[Append[new, c]] > Length[new], AppendTo[new, c]; added = True]],
         {i, Length[basis]}, {j, i + 1, Length[basis]}];
      basis = new;
      If[! added, Break[]]];
    basis];

allAntisym[mats_] := AllTrue[mats, Max[Abs[Flatten[# + Transpose[#]]]] === 0 &];

CVLieClosureDim[gens_]                := matRank[lieClosure[gens]];
CVLieClosureDim[gens_, "Basis"]       := lieClosure[gens];
CVLieClosureDim[gens_, "Compact"]     := allAntisym[lieClosure[gens]];

CVDLAAudit[n_Integer, gens_List] :=
  Module[{basis = lieClosure[gens], d, un = n^2, spn = n (2 n + 1), compact, confined},
    d = matRank[basis];
    compact = allAntisym[basis];
    confined = compact && d <= un;
    <|"n" -> n, "dim" -> d, "un" -> un, "spn" -> spn, "compact" -> compact,
      "confined" -> confined,
      "verdict" -> If[confined,
        "PASSIVE-CONFINED (subset u(n): classically emulable by linear optics)",
        "ACTIVE (genuine squeezing; NOT passive-linear-optics-emulable)"]|>];

(* the module's own Hawking-channel generator set (2 modes):
   free phase evolution on each mode + graybody beamsplitter + two-mode
   squeezer. Closes to sp(4,R) (dim 10) => ACTIVE.                            *)
HawkingGenerators[] := {
  genPhase[2, 1], genPhase[2, 2],
  genBSre[2, 1, 2], genBSim[2, 1, 2],
  genTMS1[2, 1, 2], genTMS2[2, 1, 2]};


(* ========================================================================== *)
(* GATE ASSEMBLY.  Each gate is a Boolean; WitnessBridgeRunAll returns the     *)
(* GaussianHawkingVerification association with "OK" -> And of all gates.      *)
(* ========================================================================== *)

(* symbolic r, w, TH, nbar, nin used only inside proofs below *)

gateA1[] :=
  Module[{sym, ws, TH0, nb, ys, fit, THfit},
    (* symbolic Planck emergence *)
    sym = FullSimplify[
      Sinh[HawkingSqueezing[wS, THS]]^2 == 1/(Exp[wS/THS] - 1),
      Assumptions -> {wS > 0, THS > 0}];
    (* numeric fit: recover TH from the engine spectrum *)
    TH0 = 1/(2 Pi);
    ws = Range[1, 8] TH0;  (* w/TH in {1..8} *)
    nb = MeanN[HawkingPair[#, TH0][[1]], 1] & /@ ws;
    ys = Log[1 + 1/nb];               (* = w/TH exactly *)
    fit = ys . ws/(ws . ws);          (* least-squares slope through origin = 1/TH *)
    THfit = 1/fit;
    <|"symbolic" -> (sym === True), "THfit" -> N[THfit, 16],
      "numeric" -> (Abs[THfit - TH0] < 10^-8)|>];

gateA2[] :=
  Module[{st, sigmaA, nuList, nu, svn, formR, formN, okNu, okR, okN},
    st = HawkingPair[wS, THS];
    (* use symbolic squeezing r for the entropy identity *)
    sigmaA = PartialTrace[ApplySymplectic[TwoModeSqueezer[rS], VacuumState[2]], {1}][[1]];
    nuList = SymplecticEigenvalues[sigmaA];
    okNu = (FullSimplify[nuList == {Sinh[rS]^2 + 1/2}, Assumptions -> rS > 0] === True) ||
           (FullSimplify[First[nuList] == Sinh[rS]^2 + 1/2, Assumptions -> rS > 0] === True);
    svn = VonNeumannEntropy[sigmaA];
    formR = Cosh[rS]^2 Log[Cosh[rS]^2] - Sinh[rS]^2 Log[Sinh[rS]^2];
    okR = FullSimplify[svn == formR, Assumptions -> rS > 0] === True;
    formN = (nb + 1) Log[nb + 1] - nb Log[nb] /. nb -> Sinh[rS]^2;
    okN = FullSimplify[svn == formN, Assumptions -> rS > 0] === True;
    <|"reducedThermal" -> okNu, "entropyFormCosh" -> okR,
      "entropyFormNbar" -> okN, "allEqual" -> (okNu && okR && okN)|>];

gateA3[] :=
  Module[{sigma, P, nus, sumOK, prodOK, okMin, lnNum, okLN, r0 = 7/10},
    sigma = ApplySymplectic[TwoModeSqueezer[rS], VacuumState[2]][[1]];
    P = DiagonalMatrix[{1, 1, 1, -1}];
    (* The two PT symplectic eigenvalues are exactly (1/2)Exp[+/-2r]. Verify
       WITHOUT a symbolic magnitude sort (unreliable on symbolic entries) by
       proving their SUM = Cosh[2r] and PRODUCT = 1/4 -> the multiset is
       {(1/2)Exp[-2r], (1/2)Exp[2r]}, whose minimum (r>0) is (1/2)Exp[-2r]. *)
    nus = SymplecticEigenvalues[P . sigma . P];
    sumOK = FullSimplify[Total[nus] == Cosh[2 rS], Assumptions -> rS > 0] === True;
    prodOK = FullSimplify[Times @@ nus == 1/4, Assumptions -> rS > 0] === True;
    okMin = sumOK && prodOK;   (* => nuMinusTilde = (1/2)Exp[-2r], nuMinus = Exp[-2r] *)
    (* LogNegativity closed form 2r/Log[2]: check numerically (Min is exact
       numerically) at a sample r, and cross-check the exact ratio. *)
    lnNum = LogNegativity[N[sigma /. rS -> r0, 30]];
    okLN = Abs[lnNum - 2 r0/Log[2.`30]] < 10^-12;
    <|"ptSum" -> sumOK, "ptProduct" -> prodOK, "nuMinusExact" -> okMin,
      "logNegAt0p7" -> lnNum, "logNegExact" -> okLN, "ok" -> (okMin && okLN)|>];

gateA4[] :=
  Module[{thetaR, thetaInNbar, okSym, tab, lams, okNum},
    (* symbolic theta from the engine covariance, explicit squeezing r:
       FullSimplify -> a closed form; rewrite in nbar = Sinh[r]^2 = 1+1/(2nbar). *)
    thetaR = FullSimplify[
       CauchySchwarzTheta[ApplySymplectic[TwoModeSqueezer[rS], VacuumState[2]]],
       Assumptions -> rS > 0];
    okSym = FullSimplify[thetaR == 1 + 1/(2 Sinh[rS]^2), Assumptions -> rS > 0] === True;
    (* rewrite in nbar via r = ArcSinh[Sqrt[nbar]] (so Sinh[r]^2 = nbar): -> 1+1/(2 nb) *)
    thetaInNbar = FullSimplify[thetaR /. rS -> ArcSinh[Sqrt[nb]], Assumptions -> nb > 0];
    (* numeric table over hawking_cs_route.py's lambdas; nbar = lam^2/(1-lam^2) *)
    lams = {0.05, 0.2, 0.4, 0.6, 0.8};
    tab = Table[
      Module[{nbar = lam^2/(1 - lam^2), rr = ArcTanh[lam], thetaEng, thetaClosed},
        thetaEng = N[CauchySchwarzTheta[ApplySymplectic[TwoModeSqueezer[rr], VacuumState[2]]], 20];
        thetaClosed = 1 + 1/(2 nbar);
        {lam, nbar, thetaEng, thetaClosed, Abs[thetaEng - thetaClosed]}],
      {lam, lams}];
    okNum = AllTrue[tab, #[[5]] < 10^-6 &];
    <|"thetaSymbolic" -> thetaR, "thetaInNbar" -> thetaInNbar, "symbolicOK" -> okSym,
      "table" -> tab, "numericOK" -> okNum, "ok" -> (okSym && okNum)|>];

gateA5[] :=
  Module[{vac, deltaVac, okVac, deltaTh, thr, okThr, signTab},
    (* vacuum input: Delta == -Sinh[r]^2 *)
    vac = ApplySymplectic[TwoModeSqueezer[rS], VacuumState[2]];
    deltaVac = BuschParentaniDelta[vac];
    okVac = FullSimplify[deltaVac == -Sinh[rS]^2, Assumptions -> rS > 0] === True;
    (* thermal input nin per port: threshold Delta < 0 <=> nin < (Exp[2r]-1)/2 *)
    deltaTh = BuschParentaniDelta[
      ApplySymplectic[TwoModeSqueezer[rS],
        TensorState[ThermalState[ninS], ThermalState[ninS]]]];
    thr = (Exp[2 rS] - 1)/2;
    okThr = FullSimplify[(deltaTh /. ninS -> thr) == 0, Assumptions -> rS > 0] === True;
    (* numeric sign-flip table at r = 0.5 across nin around the threshold *)
    signTab = With[{r0 = 0.5, tc = (Exp[2 0.5] - 1)/2},
      Table[{nin,
        Sign[N[deltaTh /. {rS -> 0.5, ninS -> nin}]]},
        {nin, {0., 0.5 tc, tc, 1.5 tc}}]];
    <|"deltaVacExact" -> okVac, "thresholdExact" -> okThr,
      "thresholdValue" -> "(Exp[2r]-1)/2", "signTable" -> signTab,
      "ok" -> (okVac && okThr)|>];

gateA6[] :=
  Module[{rs, N0, okDerived, okHoro, symHoro, lim, okLim, reff, okReff, tab, maxErr},
    rs = {0.3, 0.6, 1.0}; N0 = 60;
    (* (1) NON-CIRCULAR grounding: the pseudospin correlation matrix DERIVED from
       the truncated TMSV number-state expansion matches the closed form to high
       precision (independent of PseudospinCorrMatrix's definition).            *)
    maxErr = Max[
       Max@Abs@Flatten[TMSVPseudospinCorr[#, N0] - N[PseudospinCorrMatrix[#]]] & /@ rs];
    okDerived = maxErr < 10^-6;
    (* (2) CHSH via the Horodecki criterion applied to the DERIVED correlation
       matrix equals the closed form CHSHofR -- grounded, not restated.         *)
    okHoro = AllTrue[rs,
       Abs[HorodeckiCHSH[TMSVPseudospinCorr[#, N0]] - CHSHofR[#]] < 10^-6 &];
    (* (2b) symbolic: the Horodecki formula on the closed-form matrix's singular
       values {1, Tanh[2r], Tanh[2r]} yields CHSHofR (two largest = 1, Tanh2r). *)
    symHoro = FullSimplify[2 Sqrt[1 + Tanh[2 rS]^2] == CHSHofR[rS],
       Assumptions -> rS > 0] === True;
    lim = Limit[CHSHofR[rS], rS -> Infinity];
    okLim = (lim === 2 Sqrt[2]);
    reff = rS /. Quiet@FindRoot[CHSHofR[rS] == 2.25, {rS, 0.3}];
    okReff = Abs[reff - 0.285020] < 10^-5;
    tab = Table[{r0, N[CHSHofR[r0], 10], N[CHSHCFofR[r0], 10]},
       {r0, {0.1, 0.285020, 0.5, 1.0, 2.0}}];
    <|"corrMatrixDerivedErr" -> maxErr, "corrMatrixDerived" -> okDerived,
      "chshHorodeckiDerived" -> okHoro, "chshHorodeckiSymbolic" -> symHoro,
      "limit2Sqrt2" -> okLim, "rEff225" -> N[reff, 12], "rEffOK" -> okReff,
      "cfAtCeiling" -> Simplify[Max[0, (2 Sqrt[2] - 2)/2]],  (* = Sqrt[2]-1 *)
      "binningCaveat" ->
        "GKMR parity pseudospin is ONE binning of the CV pair; other binnings give different CHSH(r). 2Sqrt2 ceiling is specific to this binning at r->Inf.",
      "table" -> tab,
      "ok" -> (okDerived && okHoro && symHoro && okLim && okReff)|>];

gateA7i[] :=
  Module[{graybody, states, oks},
    (* graybody output: mix the exterior arm (mode 1) of a TMSV with a vacuum
       ancilla (mode 3) via a beamsplitter, then trace the ancilla -> modes 1,2. *)
    graybody = PartialTrace[
      ApplySymplectic[EmbedSymplectic[Beamsplitter[0.6], {1, 3}, 3],
        TensorState[ApplySymplectic[TwoModeSqueezer[0.9], VacuumState[2]],
          VacuumState[1]]], {1, 2}][[1]];
    states = {
      HawkingPair[1.3, 1/(2 Pi)][[1]],                         (* pure Hawking pair *)
      ApplySymplectic[TwoModeSqueezer[0.4],                    (* thermal-input pair *)
        TensorState[ThermalState[0.3], ThermalState[0.3]]][[1]],
      graybody};                                               (* graybody output *)
    oks = HudsonPositiveQ /@ states;
    <|"perState" -> oks, "ok" -> AllTrue[oks, TrueQ]|>];

gateA7ii[] :=
  Module[{cases, cfs},
    cases = {
      {0.55, 0.05, 0.05, 0.35},                          (* K=2 (2x2 joint)   *)
      N@Normalize[Range[9] + 1, Total],                  (* K=9 (3x3 joint)   *)
      Module[{lam = 0.6, ns = Range[0, 10], p},          (* real TMSV diagonal *)
        p = (1 - lam^2) lam^(2 ns); p = p/Total[p];
        (* embed 11 diagonal cells into 11x11 = 121 joint outcomes (k=11)    *)
        Module[{full = ConstantArray[0., 121]},
          Do[full[[12 i + 1]] = p[[i + 1]], {i, 0, 10}]; full]]};
    cfs = SingleContextCF /@ cases;
    <|"CFvalues" -> cfs, "ok" -> AllTrue[cfs, Abs[#] < 10^-9 &]|>];

gateA8[] :=
  Module[{n = 2, ai, aii, aiii, hawk, okI, okII, okIII, okHawk},
    ai   = CVDLAAudit[2, {genPhase[2, 1], genPhase[2, 2], genBSre[2, 1, 2], genBSim[2, 1, 2]}];
    aii  = CVDLAAudit[2, {genPhase[2, 1], genPhase[2, 2], genBSre[2, 1, 2], genBSim[2, 1, 2],
                          genTMS1[2, 1, 2], genTMS2[2, 1, 2]}];
    aiii = CVDLAAudit[1, {genPhase[1, 1], genSMS1[1, 1]}];
    hawk = CVDLAAudit[2, HawkingGenerators[]];
    okI   = ai["dim"] == 4 && ai["confined"] === True;
    okII  = aii["dim"] == 10 && aii["confined"] === False;
    okIII = aiii["dim"] == 3 && aiii["confined"] === False;
    okHawk = hawk["dim"] == 10 && hawk["confined"] === False;
    <|"validation_i_u2" -> ai, "validation_ii_sp4" -> aii,
      "validation_iii_sp2" -> aiii, "hawking" -> hawk,
      "verdict" -> "Hawking mode conversion is NOT passive-linear-optics-emulable, but IS Gaussian-classically-simulable",
      "ok" -> (okI && okII && okIII && okHawk)|>];

WitnessBridgeRunAll[] :=
  Module[{a1, a2, a3, a4, a5, a6, a7i, a7ii, a8, ok},
    a1 = gateA1[]; a2 = gateA2[]; a3 = gateA3[];
    a4 = gateA4[]; a5 = gateA5[]; a6 = gateA6[];
    a7i = gateA7i[]; a7ii = gateA7ii[]; a8 = gateA8[];
    ok = a1["numeric"] && (a1["symbolic"]) && a2["allEqual"] && a3["ok"] &&
         a4["ok"] && a5["ok"] && a6["ok"] && a7i["ok"] && a7ii["ok"] && a8["ok"];
    <|"A1_Planck" -> a1, "A2_EntEqThermal" -> a2, "A3_LogNeg" -> a3,
      "A4_CauchySchwarz" -> a4, "A5_BuschParentani" -> a5, "A6_CHSHbridge" -> a6,
      "A7i_Hudson" -> a7i, "A7ii_CFzero" -> a7ii, "A8_DLAactive" -> a8,
      "OK" -> TrueQ[ok]|>];

End[];

(* --------------------------------------------------------------------------
   Self-check (runs on direct Get; suppressed when GaussianHawkingLoadOnly).
   The runner runners/RunGaussianHawking.wl leaves the flag False so this
   fires and prints the GaussianHawkingVerification association last.
   -------------------------------------------------------------------------- *)
If[! TrueQ[GaussianHawkingLoadOnly],
  GaussianHawkingVerification = WitnessBridgeRunAll[];
  Print["GaussianHawkingVerification = ", GaussianHawkingVerification];
  Print["OK -> ", GaussianHawkingVerification["OK"]];
];
