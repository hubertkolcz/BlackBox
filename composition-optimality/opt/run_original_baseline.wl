(* run_original_baseline.wl -- runs the READ-ONLY original generator
   GenerateEpsilonCertificate9.wl at a chosen K, WITHOUT touching any original
   file: the original source is copied, only the "K = 9;" parameter line and
   the Export target filename are substituted, the copy is written into opt/
   and evaluated. Everything else (all four seeds, full per-round joint SDP
   solves, Stage 2/3/4) runs verbatim. Provides the ground-truth certificate
   and the baseline wall-clock/memory numbers for the optimized-vs-original
   comparison.
   Usage: wolframscript -file run_original_baseline.wl <K>
   Output: baseline_cert_K<K>.wl (+ baseline_src_K<K>.wl, the evaluated copy) *)

SetDirectory[DirectoryName[$InputFileName]];
kk = ToExpression[$ScriptCommandLine[[-1]]];
If[! (IntegerQ[kk] && kk >= 2), Print["bad K"]; Exit[1]];

src = Import["../GenerateEpsilonCertificate9.wl", "Text"];
If[StringCount[src, "K = 9;"] =!= 1, Print["ABORT: K-parameter line not unique"]; Exit[1]];
src = StringReplace[src, {
    "K = 9;" -> "K = " <> ToString[kk] <> ";",
    "Export[\"EpsilonCertificate9.wl\"" ->
      "Export[\"baseline_cert_K" <> ToString[kk] <> ".wl\""}];
tmpFile = "baseline_src_K" <> ToString[kk] <> ".wl";
Export[tmpFile, src, "Text"];

Print["[BASELINE] running ORIGINAL generator (verbatim, all 4 seeds) at K = ", kk];
t0 = AbsoluteTime[];
Get[tmpFile];
Print["[BASELINE] K=", kk, " total wall = ", N[Round[AbsoluteTime[] - t0, 0.01]],
  " s, kernelMaxMemoryUsedMB = ", N[Round[MaxMemoryUsed[]/2.^20, 0.1]]];
