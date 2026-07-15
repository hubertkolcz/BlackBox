(* ::Package:: *)

(* =====================================================================
   gaussian_engine.wl  --  exact covariance-matrix (Gaussian / symplectic)
   engine for the Hawking Gaussian sector (module 08-HK-hawking).

   WHAT THIS FILE IS (honesty header):
   -----------------------------------
   A convention-fixed library of EXACT Gaussian linear algebra on
   covariance matrices: states, symplectic operations, Williamson
   (symplectic) eigenvalues, von Neumann entropy, logarithmic negativity,
   photon-number moments (Wick / Isserlis), and physicality (Hudson /
   Wigner-positivity) tests.  It is the emulable-side arithmetic engine:
   Gaussian states + Gaussian ops + homodyne are classically efficiently
   simulable (CV Gottesman-Knill: Bartlett-Sanders-Braunstein-Nemoto,
   PRL 88, 097904 (2002)).  No physics choices are made here; the Hawking
   map lives in gaussian_hawking_physics.wl.

   CONVENTION (FIXED, never deviate):
     hbar = 1.  Per mode ordering (x_j, p_j); global r=(x_1,p_1,...,x_n,p_n).
     [x_j, p_k] = i delta_jk.  Vacuum covariance sigma_vac = (1/2) I.
     sigma_ab = (1/2) < { Dr_a, Dr_b } >, Dr = r - <r>.  A state is
     {sigma, mean}.  Symplectic form Omega = blockdiag {{0,1},{-1,0}}.
     A symplectic S obeys S.Omega.S^T = Omega; action sigma -> S.sigma.S^T,
     mean -> S.mean.  Physicality: sigma + (i/2) Omega >= 0  (PSD),
     equivalently every symplectic eigenvalue nu_k >= 1/2.

   Get-loadable: DEFINITIONS ONLY.  The self-check at the bottom runs only
   when GaussianHawkingLoadOnly is not True.  No Join-in-loop.  Exact
   symbolic throughout.

   Public API (top-level symbols; contract shared with builders):
     GaussianOmega, VacuumState, ThermalState, TwoModeSqueezer,
     SingleModeSqueezer, Beamsplitter, PhaseRot, EmbedSymplectic,
     ApplySymplectic, PartialTrace, TensorState, SymplecticEigenvalues,
     GaussianG, VonNeumannEntropy, LogNegativity, MeanN, TwoPointLadder,
     WickMoment, PhysicalStateQ, HudsonPositiveQ.
   ===================================================================== *)

(* ---- symplectic form ------------------------------------------------ *)
GaussianOmega[n_Integer] := Normal @ SparseArray[
  Flatten[Table[{{2 j - 1, 2 j} -> 1, {2 j, 2 j - 1} -> -1}, {j, n}], 1],
  {2 n, 2 n}];

(* ---- states --------------------------------------------------------- *)
VacuumState[n_Integer] := {(1/2) IdentityMatrix[2 n], ConstantArray[0, 2 n]};
ThermalState[nbar_]    := {(nbar + 1/2) IdentityMatrix[2], {0, 0}};

(* ---- symplectic operators (exact, symbolic entries) ----------------- *)
TwoModeSqueezer[r_] := With[{c = Cosh[r], s = Sinh[r], zx = DiagonalMatrix[{1, -1}]},
  ArrayFlatten[{{c IdentityMatrix[2], s zx}, {s zx, c IdentityMatrix[2]}}]];
SingleModeSqueezer[q_] := DiagonalMatrix[{Exp[-q], Exp[q]}];
Beamsplitter[theta_] := With[{ct = Cos[theta], st = Sin[theta], i2 = IdentityMatrix[2]},
  ArrayFlatten[{{ct i2, st i2}, {-st i2, ct i2}}]];
PhaseRot[phi_] := {{Cos[phi], Sin[phi]}, {-Sin[phi], Cos[phi]}};

(* ---- symplectic utilities ------------------------------------------- *)
EmbedSymplectic[s_, modes_List, n_Integer] := Module[{big = IdentityMatrix[2 n], idx},
  idx = Flatten[{2 # - 1, 2 #} & /@ modes];
  big[[idx, idx]] = s;
  big];
ApplySymplectic[s_, {sigma_, mean_}] := {s . sigma . Transpose[s], s . mean};
PartialTrace[{sigma_, mean_}, keep_List] := Module[{idx = Flatten[{2 # - 1, 2 #} & /@ keep]},
  {sigma[[idx, idx]], mean[[idx]]}];
TensorState[{s1_, m1_}, {s2_, m2_}] := {ArrayFlatten[{{s1, 0}, {0, s2}}], Join[m1, m2]};

(* ---- Williamson / symplectic eigenvalues ---------------------------- *)
(* nu_k^2 are the (doubled) eigenvalues of -(Omega.sigma)^2; the spectrum of
   i Omega.sigma is {+- nu_k}.  Take one representative per +- pair.       *)
SymplecticEigenvalues[sigma_] := Module[{n = Length[sigma]/2, om, m2, ev},
  om = GaussianOmega[n];
  m2 = -(om . sigma) . (om . sigma);
  ev = Eigenvalues[m2];
  Sqrt[ Sort[ev, Greater][[1 ;; ;; 2]] ]];

(* ---- entropy / negativity (bosonic g-function, natural log = nats) --- *)
(* x Log[x] with the removable-singularity value 0 at x==0, so a PURE symplectic
   eigenvalue nu==1/2 gives GaussianG[1/2]==0 (not 0*Log[0]==Indeterminate).
   For symbolic x the If falls through to x Log[x], preserving exact proofs. *)
GaussianXLogX[x_] := If[TrueQ[Chop[x] == 0], 0, x Log[x]];
GaussianG[nu_] := GaussianXLogX[nu + 1/2] - GaussianXLogX[nu - 1/2];
VonNeumannEntropy[sigma_] := Total[GaussianG /@ SymplecticEigenvalues[sigma]];
(* Log-negativity (bits, Log2) for a TWO-mode state; PT on mode 2. *)
LogNegativity[sigma_] := Module[{p = DiagonalMatrix[{1, 1, 1, -1}], spt, numin},
  spt = p . sigma . p;
  numin = 2 Min[SymplecticEigenvalues[spt]];
  Max[0, -Log2[numin]]];

(* ---- mean photon number of mode j ----------------------------------- *)
MeanN[sigma_, j_Integer] := (sigma[[2 j - 1, 2 j - 1]] + sigma[[2 j, 2 j]])/2 - 1/2;

(* ---- photon-number moments via Wick / Isserlis ---------------------- *)
(* Ladder coefficient vector: a_mode = (x+ i p)/Sqrt2, a^dag = (x - i p)/Sqrt2.
   spec = {mode, dag} with dag = True for creation. *)
GaussianLadderVec[n_, mode_, dag_] := Module[{v = ConstantArray[0, 2 n]},
  v[[2 mode - 1]] = 1/Sqrt[2];
  v[[2 mode]] = If[TrueQ[dag], -I, I]/Sqrt[2];
  v];
(* < A B > = u.(sigma + (i/2)Omega).v, using <r_a r_b> = sigma_ab + (i/2)Omega_ab. *)
TwoPointLadder[sigma_, s1_List, s2_List] := Module[{n = Length[sigma]/2, u, v},
  u = GaussianLadderVec[n, s1[[1]], s1[[2]]];
  v = GaussianLadderVec[n, s2[[1]], s2[[2]]];
  u . (sigma + (I/2) GaussianOmega[n]) . v];
(* perfect matchings of a list, first element paired with each later one *)
GaussianMatchings[{}] := {{}};
GaussianMatchings[l_List] := Module[{f = First[l], rest = Rest[l]},
  Flatten[Table[Map[Prepend[#, {f, rest[[k]]}] &, GaussianMatchings[Delete[rest, k]]],
    {k, Length[rest]}], 1]];
(* < prod of ladder ops >  (zero-mean Gaussian => Wick over pair expectations). *)
WickMoment[sigma_, specs_List] := If[OddQ[Length[specs]], 0,
  Total[(Times @@ (TwoPointLadder[sigma, specs[[#[[1]]]], specs[[#[[2]]]]] & /@ #)) & /@
    GaussianMatchings[Range[Length[specs]]]]];

(* ---- physicality (Hudson / Wigner positivity) ----------------------- *)
(* A Gaussian state's Wigner function is Gaussian (>= 0) iff sigma is a valid
   covariance, i.e. sigma + (i/2)Omega is PSD (every nu_k >= 1/2). *)
HudsonPositiveQ[sigma_] := PositiveSemidefiniteMatrixQ[
  N[sigma + (I/2) GaussianOmega[Length[sigma]/2]]];
PhysicalStateQ[sigma_] := HudsonPositiveQ[sigma];

(* ---- load-guarded self-check --------------------------------------- *)
If[! TrueQ[GaussianHawkingLoadOnly],
  Module[{rr, cov, target},
    cov = ApplySymplectic[TwoModeSqueezer[rr], VacuumState[2]][[1]];
    target = (1/2) {{Cosh[2 rr], 0, Sinh[2 rr], 0}, {0, Cosh[2 rr], 0, -Sinh[2 rr]},
       {Sinh[2 rr], 0, Cosh[2 rr], 0}, {0, -Sinh[2 rr], 0, Cosh[2 rr]}};
    Print["[gaussian_engine self-check] TMSV covariance exact : ",
      TrueQ[FullSimplify[cov == target]]];
    Print["[gaussian_engine self-check] symplectic form OK    : ",
      TrueQ[TwoModeSqueezer[rr] . GaussianOmega[2] . Transpose[TwoModeSqueezer[rr]] ==
         GaussianOmega[2] // FullSimplify]];
  ]];
