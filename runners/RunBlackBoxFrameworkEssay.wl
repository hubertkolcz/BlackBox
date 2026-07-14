(* Headless runner for the master computational essay TheBlackBoxFramework.wl (repo root).
   Get[] (not -file) so the essay's loader cell and each Get-loaded section fragment run
   their Global`-deshadow before any paclet symbol is tokenised -- the shadowing pitfall
   documented in RunEssay.wl / CertifyingQuantumness.wl. Run from anywhere:
       wolframscript -file RunBlackBoxFrameworkEssay.wl -print all
   The final value printed is EssayVerification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{"..", "TheBlackBoxFramework.wl"}]];
Print["EssayVerification:"];
Print[EssayVerification];
Print["liveNumberCount -> ", EssayVerification["liveNumberCount"]];
Print["OK -> ", EssayVerification["OK"]];
