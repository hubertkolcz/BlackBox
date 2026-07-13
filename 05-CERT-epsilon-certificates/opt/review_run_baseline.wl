(* review_run_baseline.wl -- ADVERSARIAL-REVIEW copy of run_original_baseline.wl.
   Identical mechanism: copies the READ-ONLY original GenerateEpsilonCertificate9.wl,
   substitutes only the K parameter line and the Export target, evaluates the copy.
   Output filenames are review_-prefixed so no builder file is overwritten.
   Usage: wolframscript -file review_run_baseline.wl <K> <tag> *)

SetDirectory[DirectoryName[$InputFileName]];
kk = ToExpression[$ScriptCommandLine[[-2]]];
tag = $ScriptCommandLine[[-1]];
If[! (IntegerQ[kk] && kk >= 2), Print["bad K"]; Exit[1]];

src = Import["../GenerateEpsilonCertificate9.wl", "Text"];
If[StringCount[src, "K = 9;"] =!= 1, Print["ABORT: K-parameter line not unique"]; Exit[1]];
src = StringReplace[src, {
    "K = 9;" -> "K = " <> ToString[kk] <> ";",
    "Export[\"EpsilonCertificate9.wl\"" ->
      "Export[\"review_baseline_cert_K" <> ToString[kk] <> "_" <> tag <> ".wl\""}];
tmpFile = "review_baseline_src_K" <> ToString[kk] <> "_" <> tag <> ".wl";
Export[tmpFile, src, "Text"];

Print["[REVIEW-BASELINE] ORIGINAL generator (verbatim, all 4 seeds) K = ", kk, " tag = ", tag];
t0 = AbsoluteTime[];
Get[tmpFile];
Print["[REVIEW-BASELINE] K=", kk, " tag=", tag, " total wall = ",
  N[Round[AbsoluteTime[] - t0, 0.01]],
  " s, kernelMaxMemoryUsedMB = ", N[Round[MaxMemoryUsed[]/2.^20, 0.1]]];
