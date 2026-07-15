(* Headless acceptance runner for the Hawking Gaussian sector MASTER assembly
   (hawking-application/hawking_gaussian_sector.wl), which loads the engine +
   Hawking physics + witnesses/bridge and runs the unified A1..A8 scoreboard:
   Planck spectrum + T_H extraction (A1), entanglement = thermality (A2),
   logarithmic negativity E_N = 2r/Log2 (A3), Cauchy-Schwarz cross-anchor (A4),
   Busch-Parentani nonseparability + finite-temperature death (A5), CHSH(r)
   bridge to the qubit module (A6, grounded against the truncated TMSV, with the
   binning caveat), Hudson/Wigner positivity (A7i), single-context CF == 0
   (A7ii), and the CV dynamical-Lie-algebra ACTIVE verdict (A8).

   Run:
     wolframscript -file runners/RunGaussianHawking.wl -print all
   The printed value must show OK -> True.  Shared anchors A1..A5,A7i are
   cross-confirmed against BOTH builders' gate suites.  The BlackBox paclet is
   loaded first for the A7ii ContextualFraction check.  All local; no cloud. *)

$repoRoot = FileNameJoin[{DirectoryName[$InputFileName], ".."}];

(* BlackBox paclet (needed by A7ii ContextualFraction) *)
PacletDirectoryLoad[FileNameJoin[{$repoRoot, "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"];

(* defs-only load: suppress the master's auto-run so we drive it explicitly *)
GaussianHawkingLoadOnly = True;
Get[FileNameJoin[{$repoRoot, "hawking-application", "hawking_gaussian_sector.wl"}]];

GaussianHawkingSectorRunAll[];
GaussianHawkingSectorReport[GaussianHawkingVerification];
Print["GaussianHawkingVerification = ", GaussianHawkingVerification];
Print["OK -> ", GaussianHawkingVerification["OK"]]
