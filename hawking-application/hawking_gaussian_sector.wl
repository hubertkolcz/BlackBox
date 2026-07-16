(* ::Package:: *)

(* =====================================================================
   hawking_gaussian_sector.wl  --  MASTER ASSEMBLY of the Gaussian
   (covariance-matrix) Hawking sector, module hawking-application.  INTEGRATOR
   deliverable: loads the engine + Hawking physics + witnesses/bridge and
   runs the unified A1..A8 scoreboard, ending in the association
   GaussianHawkingVerification with "OK" -> True.

   WHAT THIS MODULE IS (honesty header -- read before citing any number)
   --------------------------------------------------------------------
   Hawking's own 1974-75 SEMICLASSICAL KINEMATICS, discretized per
   frequency mode, as EXACT Gaussian / symplectic linear algebra on
   covariance matrices.  It is NOT a derivation of black-hole radiation
   from the Einstein equations.

     * PARAMETERIZED BACKGROUND.  The surface gravity kappa, equivalently
       the Hawking temperature T_H = kappa/(2 Pi), is an INPUT, not
       derived.  No dynamical spacetime, no back-reaction, no field
       equation is solved.  We take Hawking's result that the horizon
       acts, per frequency w, as a TWO-MODE SQUEEZER between the interior
       (partner) and exterior (Hawking) modes with tanh(r_w)^2 =
       Exp[-w/T_H] (the Boltzmann factor), and compute the exact
       downstream Gaussian consequences.  There is NO GRAVITY here, only
       the horizon Bogoliubov kinematics on a fixed background.
     * GRAYBODY = BEAMSPLITTER.  Greybody/backscatter is a passive
       beamsplitter model, not a solved potential-barrier problem.
     * GKMR PSEUDOSPIN = ONE BINNING (A6).  The CHSH bridge to the qubit
       module uses the GKMR parity pseudospin -- ONE particular
       dichotomization of the CV pair (even/odd number-parity blocks).
       It is not the CV state's intrinsic nonlocality: other binnings
       (on/off detection, quadrature-sign / Gisin-Peres) give DIFFERENT
       CHSH(r) and generally weaker violation.  The 2 Sqrt[2] ceiling as
       r -> Infinity is specific to THIS binning at the EPR limit; it is
       the natural bridge because parity is exactly the pseudospin the
       qubit Bell pair carries.
     * EMULABILITY (the point of the sector).  Gaussian states + Gaussian
       (symplectic) operations + homodyne/heterodyne detection are
       CLASSICALLY EFFICIENTLY SIMULABLE -- the CV Gottesman-Knill theorem
       (Bartlett, Sanders, Braunstein, Nemoto, PRL 88, 097904 (2002);
       Bartlett & Sanders, PRA 65, 042304 (2002)).  So this ENTIRE Hawking
       sector sits on the EMULABLE side of the framework's two-lens
       boundary, mirroring the Clifford status of the qubit Hawking module
       (cluster-state-realization/ddt_mbqc_hawking_certification.wl).  The A8
       audit adds the two-tier refinement: the generator set is still
       ACTIVE sp(4,R) (genuine squeezing, not passive u(2)), so it is NOT
       passive-linear-optics-emulable even though it IS Gaussian-
       classically-simulable.

   Ledger tie-ins: constructively confirms HK-003 (single-context => CF ==
   0, A7ii) and HK-004 (Hudson/Wigner positivity, A7i); bridges to the
   qubit anchors of HK-002 via A6.

   MODULE DISCIPLINE (project law).  Get-loadable; loads the three sub-
   modules with their own self-checks SUPPRESSED (Block on
   GaussianHawkingLoadOnly), then defines the driver.  The scoreboard runs
   at the bottom ONLY when GaussianHawkingLoadOnly is not True; the runner
   runners/RunGaussianHawking.wl leaves it False.  No Join-in-loop.  The
   underlying anchors are exact identities proved with FullSimplify inside
   the sub-modules; A6's closed forms are additionally GROUNDED against the
   truncated TMSV state (non-circular).

   Sub-modules assembled (loaded in this order; real engine wins over the
   witnesses file's guarded fallback symbols):
     1. gaussian_engine.wl            -- exact covariance / symplectic engine
     2. gaussian_hawking_physics.wl   -- Hawking map + gates A1..A5, A7i
     3. gaussian_witnesses_bridge.wl  -- witnesses/bridge/cert gates A1..A8

   Public API added here:
     GaussianHawkingSectorRunAll, GaussianHawkingVerification.
   ===================================================================== *)

(* ---- load the three sub-modules, self-checks suppressed ------------- *)
Block[{GaussianHawkingLoadOnly = True},
  Get[FileNameJoin[{DirectoryName[$InputFileName], "gaussian_engine.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "gaussian_hawking_physics.wl"}]];
  Get[FileNameJoin[{DirectoryName[$InputFileName], "gaussian_witnesses_bridge.wl"}]];
];

GaussianHawkingSectorRunAll::usage =
  "GaussianHawkingSectorRunAll[] runs BOTH builders' gate suites (the engine-" <>
  "physics gates A1..A5,A7i and the witness/bridge/certification gates A1..A8) " <>
  "against the real covariance engine, cross-confirms the shared anchors, and " <>
  "returns the unified GaussianHawkingVerification association with \"OK\" -> True.";

(* ---- unified scoreboard -------------------------------------------- *)
GaussianHawkingSectorRunAll[] :=
  Module[{b1, b2, b2ok, a1, a2, a3, a4, a5, a6, a7i, a7ii, a8, cross, ok},
    (* Builder 1: engine + Hawking physics (A1..A5, A7i), plain booleans *)
    b1 = GaussianHawkingRunGates["Verbose" -> False];
    (* Builder 2: witnesses / bridge / certification (A1..A8), nested assocs *)
    b2 = WitnessBridgeRunAll[];
    b2ok = <|
      "A1" -> (b2["A1_Planck"]["symbolic"] && b2["A1_Planck"]["numeric"]),
      "A2" -> b2["A2_EntEqThermal"]["allEqual"],
      "A3" -> b2["A3_LogNeg"]["ok"],
      "A4" -> b2["A4_CauchySchwarz"]["ok"],
      "A5" -> b2["A5_BuschParentani"]["ok"],
      "A6" -> b2["A6_CHSHbridge"]["ok"],
      "A7i" -> b2["A7i_Hudson"]["ok"],
      "A7ii" -> b2["A7ii_CFzero"]["ok"],
      "A8" -> b2["A8_DLAactive"]["ok"]|>;
    (* shared anchors A1..A5, A7i: require BOTH builders to pass (cross-engine) *)
    a1  = TrueQ[b1["A1_Planck"]] && TrueQ[b2ok["A1"]];
    a2  = TrueQ[b1["A2_EntEqThermal"]] && TrueQ[b2ok["A2"]];
    a3  = TrueQ[b1["A3_LogNeg"]] && TrueQ[b2ok["A3"]];
    a4  = TrueQ[b1["A4_CauchySchwarz"]] && TrueQ[b2ok["A4"]];
    a5  = TrueQ[b1["A5_BuschParentani"]] && TrueQ[b2ok["A5"]];
    a7i = TrueQ[b1["A7i_Hudson"]] && TrueQ[b2ok["A7i"]];
    (* bridge / certification anchors A6, A7ii, A8: Builder 2 only *)
    a6   = TrueQ[b2ok["A6"]];
    a7ii = TrueQ[b2ok["A7ii"]];
    a8   = TrueQ[b2ok["A8"]];
    cross = a1 && a2 && a3 && a4 && a5 && a7i;
    ok = cross && a6 && a7ii && a8;
    GaussianHawkingVerification = <|
      "A1_Planck"        -> a1,
      "A2_EntEqThermal"  -> a2,
      "A3_LogNeg"        -> a3,
      "A4_CauchySchwarz" -> a4,
      "A5_BuschParentani"-> a5,
      "A6_CHSHbridge"    -> a6,
      "A7i_Hudson"       -> a7i,
      "A7ii_CFzero"      -> a7ii,
      "A8_DLAactive"     -> a8,
      "sharedCrossConfirmed" -> cross,
      "rEff_CHSH225"     -> b2["A6_CHSHbridge"]["rEff225"],
      "A8_verdict"       -> b2["A8_DLAactive"]["verdict"],
      "A6_binningCaveat" -> b2["A6_CHSHbridge"]["binningCaveat"],
      "bridge" ->
        "r->Inf EPR limit: GKMR-pseudospin TMSV -> qubit Bell pair (CHSH -> 2Sqrt2, CF -> Sqrt2-1). Gaussian (Hawking math) and qubit (Page/HP) sectors BOTH classically emulable.",
      "builder1" -> b1,
      "builder2" -> b2,
      "OK" -> ok|>;
    GaussianHawkingVerification];

(* ---- pretty scoreboard printer ------------------------------------- *)
GaussianHawkingSectorReport[v_Association] :=
  Module[{row},
    row[k_, label_] := Print["  ", label, " : ", v[k]];
    Print["==================================================================="];
    Print[" HAWKING GAUSSIAN SECTOR -- unified A1..A8 scoreboard (master)"];
    Print[" exact covariance/symplectic engine; parameterized background;"];
    Print[" GKMR pseudospin = one binning; no gravity; Gaussian-emulable."];
    Print["==================================================================="];
    row["A1_Planck",         "A1  Planck spectrum + T_H fit       "];
    row["A2_EntEqThermal",   "A2  entanglement = thermality       "];
    row["A3_LogNeg",         "A3  log-negativity E_N = 2r/Log2     "];
    row["A4_CauchySchwarz",  "A4  Cauchy-Schwarz theta=1+1/(2n)    "];
    row["A5_BuschParentani", "A5  Busch-Parentani + T-death        "];
    row["A6_CHSHbridge",     "A6  CHSH(r) bridge -> 2 Sqrt[2]      "];
    row["A7i_Hudson",        "A7i Hudson / Wigner positivity       "];
    row["A7ii_CFzero",       "A7ii single-context CF == 0          "];
    row["A8_DLAactive",      "A8  CV-DLA ACTIVE (sp(4,R), dim 10)  "];
    Print["-------------------------------------------------------------------"];
    Print["  shared A1..A5,A7i cross-confirmed (both builders): ", v["sharedCrossConfirmed"]];
    Print["  r_eff (CHSH = 2.25)  = ", v["rEff_CHSH225"]];
    Print["  A8 verdict           = ", v["A8_verdict"]];
    Print["  bridge               = ", v["bridge"]];
    Print["==================================================================="];
    Print["  OK -> ", v["OK"]];
  ];

(* ---- load-guarded scoreboard run ----------------------------------- *)
If[! TrueQ[GaussianHawkingLoadOnly],
  GaussianHawkingSectorRunAll[];
  GaussianHawkingSectorReport[GaussianHawkingVerification];
];
