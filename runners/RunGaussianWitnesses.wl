(* ==========================================================================
   RunGaussianWitnesses.wl -- headless acceptance runner for the WITNESSES /
   BRIDGE / CERTIFICATION half of the Gaussian Hawking sector (08-HK-hawking,
   BUILDER 2: gaussian_witnesses_bridge.wl). Prints the
   GaussianHawkingVerification association; "OK -> True" is the single
   acceptance criterion (RunAll.ps1 greps for it).

   Run:  wolframscript -file runners/RunGaussianWitnesses.wl -print all

   Load order (real engine wins over the witnesses file's guarded fallback):
     1. BlackBox paclet                (A7ii ContextualFraction).
     2. gaussian_engine.wl             -- BUILDER 1 engine, IF present.
     3. gaussian_hawking_physics.wl    -- BUILDER 1 Hawking map, IF present.
     4. gaussian_witnesses_bridge.wl   -- BUILDER 2 (this deliverable).
   Then WitnessBridgeRunAll[] drives every gate A1..A8 (A4,A5,A6,A7,A8 are the
   BUILDER-2 witness/bridge/certification anchors; A1,A2,A3 are carried here so
   the file is independently acceptance-testable). Because the engine symbols
   are provided by the witnesses file ONLY IF undefined, loading BUILDER 1's
   engine first makes these same gates exercise the REAL engine.
   ========================================================================== *)

$repoRoot = FileNameJoin[{DirectoryName[$InputFileName], ".."}];

(* 1. BlackBox paclet *)
PacletDirectoryLoad[FileNameJoin[{$repoRoot, "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"];

(* defs-only: suppress each module's on-load self-check *)
GaussianHawkingLoadOnly = True;

(* 2-3. BUILDER 1 engine + Hawking map, if they have landed (real engine wins) *)
loadIfPresent[rel_] := With[{f = FileNameJoin[{$repoRoot, "08-HK-hawking", rel}]},
  If[FileExistsQ[f], Print["[RunGaussianWitnesses] loading ", rel]; Get[f], Null]];
loadIfPresent["gaussian_engine.wl"];
loadIfPresent["gaussian_hawking_physics.wl"];

(* 4. BUILDER 2 witnesses / bridge / certification *)
Get[FileNameJoin[{$repoRoot, "08-HK-hawking", "gaussian_witnesses_bridge.wl"}]];

(* run every gate, print the verification association + literal gate values *)
GaussianHawkingVerification = WitnessBridgeRunAll[];

lit[k_] := Print["  ", k, " -> ", Lookup[GaussianHawkingVerification[k], "ok",
   GaussianHawkingVerification[k]]];
Print["=================================================================="];
Print["Gaussian Hawking sector -- witnesses / bridge / certification gates"];
Print["=================================================================="];
Print["  A1 Planck spectrum + T_H fit      : ",
  GaussianHawkingVerification["A1_Planck"]["symbolic"] && GaussianHawkingVerification["A1_Planck"]["numeric"]];
Print["  A2 entanglement = thermality      : ", GaussianHawkingVerification["A2_EntEqThermal"]["allEqual"]];
Print["  A3 log-negativity 2r/Log2         : ", GaussianHawkingVerification["A3_LogNeg"]["ok"]];
Print["  A4 Cauchy-Schwarz theta=1+1/(2n)  : ", GaussianHawkingVerification["A4_CauchySchwarz"]["ok"]];
Print["  A5 Busch-Parentani + T-death      : ", GaussianHawkingVerification["A5_BuschParentani"]["ok"]];
Print["  A6 CHSH(r) bridge -> 2 Sqrt[2]     : ", GaussianHawkingVerification["A6_CHSHbridge"]["ok"]];
Print["  A7i Hudson / Wigner positivity     : ", GaussianHawkingVerification["A7i_Hudson"]["ok"]];
Print["  A7ii single-context CF == 0        : ", GaussianHawkingVerification["A7ii_CFzero"]["ok"]];
Print["  A8 CV-DLA ACTIVE (sp(4,R), dim 10) : ", GaussianHawkingVerification["A8_DLAactive"]["ok"]];
Print["------------------------------------------------------------------"];
Print["  r_eff (CHSH = 2.25)  = ", GaussianHawkingVerification["A6_CHSHbridge"]["rEff225"]];
Print["  A8 verdict           = ", GaussianHawkingVerification["A8_DLAactive"]["verdict"]];
Print["=================================================================="];
Print["GaussianHawkingVerification = ", GaussianHawkingVerification];
Print["OK -> ", GaussianHawkingVerification["OK"]];
