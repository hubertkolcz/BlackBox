(* ::Package:: *)

(* =====================================================================
   gaussian_hawking_physics.wl  --  Hawking's own 1974-75 semiclassical
   kinematics, discretized per frequency mode, as EXACT Gaussian /
   symplectic linear algebra on top of gaussian_engine.wl.

   WHAT THIS MODULE IS (honesty header -- read before citing anything):
   -------------------------------------------------------------------
   * PARAMETERIZED background.  The surface gravity kappa, equivalently the
     Hawking temperature T_H = kappa/(2 Pi), is an INPUT, not derived from
     the Einstein equations.  No dynamical spacetime, no back-reaction, no
     field equation is solved.  We take Hawking's result that the horizon
     acts, per frequency w, as a TWO-MODE SQUEEZER between the interior
     (partner) and exterior (Hawking) modes, with squeezing fixed by
     tanh(r_w)^2 = Exp[-w/T_H] (the Boltzmann factor), and compute the
     exact downstream Gaussian consequences.
   * Graybody = beamsplitter.  Greybody/backscatter is modelled as a
     passive beamsplitter of transmissivity eta(w) on the exterior arm -- a
     model, not a solved potential-barrier scattering problem.
   * EMULABILITY statement (the point of the whole sector).  Gaussian states
     + Gaussian (symplectic) operations + homodyne detection are classically
     efficiently simulable (CV Gottesman-Knill: Bartlett, Sanders, PRA 65,
     042304 (2002)).  So this entire Hawking sector sits on the EMULABLE
     side of the framework's two-lens boundary, mirroring the Clifford
     status of the qubit Hawking module
     (04-cluster-state-mbqc/cct_mbqc_hawking_certification.wl).  The two-tier
     CV statement (companion builder, A8): the generator set is still active
     sp(4,R), so it is NOT passive-linear-optics-emulable even though it IS
     Gaussian-classically-simulable.

   Ledger tie-ins: constructively confirms HK-004 (Hudson positivity, A7i);
   the CS/Delta witnesses it computes are single-context data (HK-003).

   This Builder-1 file supplies the ENGINE PHYSICS gates A1, A2, A3, A4, A5
   and A7i.  The pseudospin/CHSH bridge (A6), the CV-DLA audit (A8) and the
   contextual-fraction-zero demonstration (A7ii) are the companion builder's
   symbols; GaussianHawkingRunGates returns the A1..A5/A7i block whose
   "OK" -> True is the Builder-1 acceptance criterion.

   Get-loadable: DEFINITIONS ONLY.  Loads gaussian_engine.wl by relative
   path.  The gate run at the bottom fires only when GaussianHawkingLoadOnly
   is not True.  Exact symbolic where marked; the anchors are IDENTITIES
   proved with FullSimplify, not numerics.

   Public API added here: HawkingSqueezing, HawkingPair, HawkingSpectrum,
   BuschParentaniDelta, BuschParentaniThreshold, GraybodyExteriorArm,
   GaussianHawkingRunGates, GaussianHawkingVerification.
   ===================================================================== *)

If[! ValueQ[GaussianOmega[1]],
  Get[FileNameJoin[{DirectoryName[$InputFileName], "gaussian_engine.wl"}]]];

(* ---- the per-frequency Hawking map --------------------------------- *)
(* tanh(r_w)^2 == Exp[-w/T_H]  =>  r_w = ArcTanh[Sqrt[Exp[-w/T_H]]]. *)
HawkingSqueezing[w_, TH_] := ArcTanh[Sqrt[Exp[-w/TH]]];

(* interior/exterior TMSV pair; mode 1 = exterior (Hawking), mode 2 = interior. *)
HawkingPair[w_, TH_] := ApplySymplectic[TwoModeSqueezer[HawkingSqueezing[w, TH]], VacuumState[2]];

(* Planck spectrum read straight from the engine covariance (exterior arm). *)
HawkingSpectrum[ws_List, TH_] := Table[{w, MeanN[HawkingPair[w, TH][[1]], 1]}, {w, ws}];

(* Graybody: exterior arm through a beamsplitter with a vacuum (or thermal)
   ancilla, transmissivity eta = Cos[theta]^2, then trace the ancilla. *)
GraybodyExteriorArm[state_, theta_, nEnv_: 0] := Module[{full, bs},
  full = TensorState[state, ThermalState[nEnv]];  (* modes: 1,2 signal ; 3 env *)
  bs = EmbedSymplectic[Beamsplitter[theta], {1, 3}, 3];
  PartialTrace[ApplySymplectic[bs, full], {1, 2}]];

(* ---- Busch-Parentani / Steinhauer nonseparability ------------------- *)
(* Delta = <bH^dag bH><bP^dag bP> - |<bH bP>|^2 from the engine 2nd moments;
   modes 1 = H (exterior), 2 = P (interior).  Delta < 0 == nonseparable. *)
BuschParentaniDelta[{sigma_, mean_}] := Module[{nH, nP, cHP},
  nH  = TwoPointLadder[sigma, {1, True}, {1, False}];
  nP  = TwoPointLadder[sigma, {2, True}, {2, False}];
  cHP = TwoPointLadder[sigma, {1, False}, {2, False}];
  nH nP - cHP Conjugate[cHP]];
(* thermal-input death threshold: positive root of Delta == 0 in n_in. *)
BuschParentaniThreshold[r_] := (Exp[2 r] - 1)/2;

(* =====================================================================
   GATES (each Prints its literal outputs and returns a Boolean).
   ===================================================================== *)

Options[GaussianHawkingRunGates] = {"Verbose" -> True};

GaussianHawkingGateA1[] := Module[
  {w, TH, symId, engId, TH0, ws, dat, slope, THfit, numOK},
  Clear[w, TH];
  (* symbolic: Planck spectrum emerges from the engine *)
  symId = TrueQ@FullSimplify[
    Sinh[HawkingSqueezing[w, TH]]^2 == 1/(Exp[w/TH] - 1), w > 0 && TH > 0];
  engId = TrueQ@FullSimplify[
    MeanN[HawkingPair[w, TH][[1]], 1] == 1/(Exp[w/TH] - 1), w > 0 && TH > 0];
  (* numeric: extract T_H by fitting the engine spectrum on a frequency grid *)
  TH0 = 2/5;
  ws = {2/5, 4/5, 6/5, 8/5, 2, 12/5};
  dat = {#, Log[1 + 1/MeanN[HawkingPair[#, TH0][[1]], 1]]} & /@ ws;   (* y = w/T_H *)
  slope = Last@CoefficientList[Fit[N[dat, 40], {1, x}, x], x];
  THfit = 1/slope;
  numOK = Abs[THfit - TH0] < 10^-8;
  Print["  [A1] Planck spectrum from the covariance engine (the Boltzmann factor)"];
  Print["       symbolic  Sinh[r_w]^2 == 1/(Exp[w/T_H]-1)         : ", symId];
  Print["       engine    MeanN[exterior] == 1/(Exp[w/T_H]-1)      : ", engId];
  Print["       numeric   T_H fit ", N[THfit, 12], " vs input ",
    N[TH0], "  (|diff| ", N[Abs[THfit - TH0]], ")"];
  symId && engId && numOK];

GaussianHawkingGateA2[] := Module[{rr, st, sigA, nuOK, Svn, f1, f2},
  Clear[rr];
  st = ApplySymplectic[TwoModeSqueezer[rr], VacuumState[2]];
  sigA = PartialTrace[st, {1}][[1]];
  nuOK = TrueQ@FullSimplify[
    CharacteristicPolynomial[-(GaussianOmega[1] . sigA) . (GaussianOmega[1] . sigA), y]
      == (y - (Cosh[2 rr]/2)^2)^2, rr > 0];
  Svn = VonNeumannEntropy[sigA];
  f1 = TrueQ@FullSimplify[
    Svn == Cosh[rr]^2 Log[Cosh[rr]^2] - Sinh[rr]^2 Log[Sinh[rr]^2], rr > 0];
  f2 = TrueQ@FullSimplify[
    Svn == (Sinh[rr]^2 + 1) Log[Sinh[rr]^2 + 1] - Sinh[rr]^2 Log[Sinh[rr]^2], rr > 0];
  Print["  [A2] entanglement = thermality (the conceptual core of Hawking's result)"];
  Print["       reduced-arm symplectic eig  nu == nbar + 1/2         : ", nuOK];
  Print["       S_vN == Cosh^2 Log Cosh^2 - Sinh^2 Log Sinh^2        : ", f1];
  Print["       S_vN == (nbar+1)Log(nbar+1) - nbar Log nbar          : ", f2];
  nuOK && f1 && f2];

GaussianHawkingGateA3[] := Module[{rr, st, sig, p4, spt, m2, cpOK, idOK, engOK, r0},
  Clear[rr];
  st = ApplySymplectic[TwoModeSqueezer[rr], VacuumState[2]];
  sig = st[[1]];
  p4 = DiagonalMatrix[{1, 1, 1, -1}];
  spt = p4 . sig . p4;
  m2 = -(GaussianOmega[2] . spt) . (GaussianOmega[2] . spt);
  cpOK = TrueQ@FullSimplify[
    CharacteristicPolynomial[m2, y] == (y - Exp[4 rr]/4)^2 (y - Exp[-4 rr]/4)^2, rr > 0];
  idOK = TrueQ@FullSimplify[Max[0, -Log2[Exp[-2 rr]]] == 2 rr/Log[2], rr > 0];
  r0 = 7/10;
  engOK = Abs[LogNegativity[sig /. rr -> N[r0, 40]] - 2 r0/Log[2]] < 10^-9;
  Print["  [A3] logarithmic negativity of the Hawking TMSV pair (exact)"];
  Print["       PT symplectic eig nu_- == Exp[-2r]  (charpoly)        : ", cpOK];
  Print["       E_N == Max[0,-Log2[Exp[-2r]]] == 2 r/Log2             : ", idOK];
  Print["       engine E_N(r=0.7) ", N[LogNegativity[sig /. rr -> 0.7]],
    " vs 2r/Log2 ", N[2 r0/Log[2]]];
  cpOK && idOK && engOK];

GaussianHawkingGateA4[] := Module[
  {rr, st, sig, nb, gHH, gPP, gHP, hhOK, hpOK, thExpr, thOK, tbl, numOK},
  Clear[rr];
  st = ApplySymplectic[TwoModeSqueezer[rr], VacuumState[2]];
  sig = st[[1]];
  nb = Sinh[rr]^2;
  gHH = WickMoment[sig, {{1, True}, {1, True}, {1, False}, {1, False}}];  (* <n(n-1)> *)
  gPP = WickMoment[sig, {{2, True}, {2, True}, {2, False}, {2, False}}];
  gHP = WickMoment[sig, {{1, True}, {1, False}, {2, True}, {2, False}}];  (* <n_H n_P> *)
  hhOK = TrueQ@FullSimplify[gHH == 2 nb^2, rr > 0];
  hpOK = TrueQ@FullSimplify[gHP == 2 nb^2 + nb, rr > 0];
  thExpr = FullSimplify[gHP/Sqrt[gHH gPP], rr > 0];
  thOK = TrueQ@FullSimplify[thExpr == 1 + 1/(2 nb), rr > 0];
  (* numeric table vs the committed hawking_cs_route.py values (same lam grid) *)
  tbl = Table[Module[{r = ArcTanh[lam], s, gh, gp, nbn, thn},
      s = ApplySymplectic[TwoModeSqueezer[r], VacuumState[2]][[1]];
      gh = Re@WickMoment[s, {{1, True}, {1, True}, {1, False}, {1, False}}];
      gp = Re@WickMoment[s, {{1, True}, {1, False}, {2, True}, {2, False}}];
      nbn = MeanN[s, 1];
      thn = gp/Sqrt[gh gh];
      N@{lam, nbn, gh, gp, thn, 1 + 1/(2 nbn)}],
    {lam, {5/100, 2/10, 4/10, 6/10, 8/10}}];
  numOK = And @@ (Abs[#[[5]] - #[[6]]] < 10^-6 &) /@ tbl;
  Print["  [A4] Cauchy-Schwarz cross-anchor to hawking_cs_route.py (Wick from engine)"];
  Print["       <n(n-1)> == 2 nbar^2  (engine Wick)                   : ", hhOK];
  Print["       <n_H n_P> == 2 nbar^2 + nbar                          : ", hpOK];
  Print["       theta == 1 + 1/(2 nbar) > 1  (CS violation)           : ", thOK];
  Print["       {lam, nbar, <n(n-1)>, <nH nP>, theta_engine, 1+1/2nbar}:"];
  (Print["         ", #] & /@ tbl);
  hhOK && hpOK && thOK && numOK];

GaussianHawkingGateA5[] := Module[
  {rr, nin, stV, d0, vacOK, stT, dT, formOK, rootP, rootM, asm, r0, thr, tbl, signOK},
  Clear[rr, nin];
  asm = rr > 0 && nin > 0;
  stV = ApplySymplectic[TwoModeSqueezer[rr], VacuumState[2]];
  d0 = FullSimplify[BuschParentaniDelta[stV], rr > 0];
  vacOK = TrueQ@FullSimplify[d0 == -Sinh[rr]^2, rr > 0];
  stT = ApplySymplectic[TwoModeSqueezer[rr], TensorState[ThermalState[nin], ThermalState[nin]]];
  dT = FullSimplify[BuschParentaniDelta[stT], asm];
  formOK = TrueQ@FullSimplify[dT == (nin + 1/2)^2 - (nin + 1/2) Cosh[2 rr] + 1/4, asm];
  rootP = TrueQ@FullSimplify[(dT /. nin -> (Exp[2 rr] - 1)/2) == 0, rr > 0];
  rootM = TrueQ@FullSimplify[(dT /. nin -> (Exp[-2 rr] - 1)/2) == 0, rr > 0];
  (* numeric sign-flip across the analytic threshold at fixed r *)
  r0 = 1/2;
  thr = N@BuschParentaniThreshold[r0];   (* = (Exp[1]-1)/2 ~ 0.859 *)
  tbl = Table[Module[{dv},
      dv = Re@N@BuschParentaniDelta[
        ApplySymplectic[TwoModeSqueezer[r0], TensorState[ThermalState[ni], ThermalState[ni]]]];
      {N@ni, Chop[dv], ni < BuschParentaniThreshold[r0], Sign[dv]}],
    {ni, {1/10, 1/2, 8/10, 9/10, 12/10}}];
  signOK = And @@ ((#[[4]] == If[#[[3]], -1, 1]) & /@ tbl);
  Print["  [A5] Busch-Parentani nonseparability + finite-temperature death"];
  Print["       vacuum input  Delta == -Sinh[r]^2 < 0 for all r>0     : ", vacOK];
  Print["       thermal input Delta == (n+1/2)^2-(n+1/2)Cosh2r+1/4    : ", formOK];
  Print["       death threshold n_in = (Exp[2r]-1)/2  is a root       : ", rootP && rootM];
  Print["       r=1/2 threshold n_in* = ", thr,
    " ; sign-flip table {n_in, Delta, expect<0, sign}:"];
  (Print["         ", Most[#], " sign=", Last[#]] & /@ tbl);
  vacOK && formOK && rootP && rootM && signOK];

GaussianHawkingGateA7i[] := Module[{states, res},
  states = {
    "HawkingPair(w=1,T=0.4)" -> HawkingPair[1, 2/5][[1]],
    "thermal-input squeezed" ->
      ApplySymplectic[TwoModeSqueezer[7/10], TensorState[ThermalState[1/2], ThermalState[1/2]]][[1]],
    "graybody exterior arm"  ->
      GraybodyExteriorArm[HawkingPair[1, 2/5], Pi/5, 0][[1]]};
  res = (Rule[First[#], HudsonPositiveQ[Last[#]]]) & /@ states;
  Print["  [A7i] Hudson / Wigner positivity (Gaussian => W >= 0; confirms HK-004)"];
  (Print["       ", First[#], " : sigma + (i/2)Omega PSD -> ", Last[#]] & /@ res);
  And @@ (Last /@ res)];

GaussianHawkingRunGates[OptionsPattern[]] := Module[{a1, a2, a3, a4, a5, a7, ok},
  If[OptionValue["Verbose"],
    Print["==================================================================="];
    Print[" Gaussian Hawking sector -- Builder 1 (engine + Hawking physics)"];
    Print[" exact symbolic gates A1..A5, A7i on the covariance engine"];
    Print["==================================================================="]];
  a1 = GaussianHawkingGateA1[];
  a2 = GaussianHawkingGateA2[];
  a3 = GaussianHawkingGateA3[];
  a4 = GaussianHawkingGateA4[];
  a5 = GaussianHawkingGateA5[];
  a7 = GaussianHawkingGateA7i[];
  ok = a1 && a2 && a3 && a4 && a5 && a7;
  GaussianHawkingVerification = <|
    "A1_Planck" -> a1, "A2_EntEqThermal" -> a2, "A3_LogNeg" -> a3,
    "A4_CauchySchwarz" -> a4, "A5_BuschParentani" -> a5, "A7i_Hudson" -> a7,
    "note" -> "A6 (CHSH bridge), A7ii (CF=0), A8 (CV-DLA) are the companion builder's gates",
    "OK" -> ok|>;
  GaussianHawkingVerification];

(* ---- load-guarded gate run ----------------------------------------- *)
If[! TrueQ[GaussianHawkingLoadOnly], Print[GaussianHawkingRunGates[]]];
