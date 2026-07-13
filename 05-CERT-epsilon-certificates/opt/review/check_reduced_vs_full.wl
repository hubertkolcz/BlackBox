(* reviewer probe: does the lever-3 reduced solve's optimum equal the original
   fully-coupled joint optimum on the SAME (converged) strategy?
   Loads all definitions from the opt generator source, truncated just before
   the Stage-1 driver (RunFromSeed) so no solves run at load time.
   Usage: wolframscript -file check_reduced_vs_full.wl <K> <certfile> *)
SetDirectory[DirectoryName[$InputFileName]];
kArg = ToExpression[$ScriptCommandLine[[2]]];
certFile = $ScriptCommandLine[[3]];

src = Import["GenerateEpsilonCertificate_opt.wl", "Text"];
cut = StringPosition[src, "RunFromSeed[strategy0_, label_] :="][[1, 1]];
src = StringTake[src, cut - 1];
(* neutralize the command-line/cert-loading preamble: force K, no warm, no gt *)
src = StringReplace[src, {
    "K = 11;" -> "K = " <> ToString[kArg] <> ";",
    "args = Rest[$ScriptCommandLine];" -> "args = {};"}];
Export["tmp_defs.wl", src, "Text"];
Get["tmp_defs.wl"];
Print["definitions loaded for K = ", K];

certSymbolNames2 = {"EpsilonCertificate9", "EpsilonCertificate8",
   "EpsilonCertificate7", "EpsilonCertificate"};
Clear /@ certSymbolNames2;
Get[certFile];
cert = None;
Do[Module[{v = ToExpression[nm]},
   If[AssociationQ[v] && KeyExistsQ[v, "k"] && KeyExistsQ[v, "Strategy"], cert = v]],
  {nm, certSymbolNames2}];
If[cert === None || cert["k"] =!= K, Print["cert load failed"]; Exit[1]];

strat = Association[Table[
    {s, e} -> cert["Strategy"][ToString[s - 1] <> "|" <> e[[1]] <> ">" <> e[[2]]],
    {e, edges}, {s, 1, 3}]];

{tF, solF} = AbsoluteTiming[SolveJointFull[strat]];
gF = gammaVar /. solF;
{tR, solR} = AbsoluteTiming[SolveJointReduced[strat]];
gR = gammaVar /. solR;
Print["K=", K, "  full Gamma = ", N[gF, 15], "  [", N[Round[tF, 0.01]], " s]"];
Print["K=", K, "  reduced Gamma = ", N[gR, 15], "  [", N[Round[tR, 0.01]], " s]"];
Print["K=", K, "  |full - reduced| = ", N[Abs[gF - gR], 5],
  "  within 1e-9: ", Abs[gF - gR] < 10^-9];
(* also: reconstruct eliminated vars from the reduced solution and confirm the
   original equalities hold to float precision (what exact-repair receives) *)
fullSolRec = Join[solR, Thread[elimVars -> (elimRHS /. Dispatch[solR])]];
eqResid = Max[Abs[(#[[1]] - #[[2]]) & /@ Join[nodeCons, edgeCons] /. Dispatch[fullSolRec]]];
Print["K=", K, "  max |equality residual| of reconstructed reduced solution = ",
  N[eqResid, 5]];
minEigQ = Min[Table[Min[Eigenvalues[Qs[w] /. Dispatch[fullSolRec] // N]], {w, nodes}]];
minEigR = Min[Table[Min[Eigenvalues[Rs[w] /. Dispatch[fullSolRec] // N]], {w, nodes}]];
Print["K=", K, "  min eigenvalue over reconstructed Q blocks = ", N[minEigQ, 5],
  ", R blocks = ", N[minEigR, 5], " (PSDMARGIN = ", N[PSDMARGIN], ")"];
