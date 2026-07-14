(* Headless runner for essay Sections 4-6 (docs/essay-src/essay_sections_4_6.wl).
   Get[] (not -file) so the loader cell runs before paclet symbols are parsed,
   avoiding the Global`-shadowing pitfall. Run from anywhere:
       wolframscript -file RunSectionsFourToSix.wl -print all
   The value printed is SectionsFourToSixVerification; it must show OK -> True. *)
SetDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{"..", "docs", "essay-src", "essay_sections_4_6.wl"}]];
Print["SectionsFourToSixVerification:"];
Print[SectionsFourToSixVerification];
Print["OK -> ", SectionsFourToSixVerification["OK"]];
