(* ddt-optimality PILOT, STAGE B (window realism / decisive decomposition).

   Loads the EXISTING untilted k=7 and k=8 epsilon-certificates and, on each
   candidate bottleneck word, decomposes the certified per-block gap bound
       posCycleMean(word) = d-density(word) - r-density(word)
   into its theta side (d) and alpha side (r), then compares
       r-density   vs   EXACT alpha-density (alpha_density_word)
       d-density   vs   EXACT theta-density (word_density_transfer_sdp)
   The proposed method (i) tilts ONLY the alpha side. It can change the limit
   ONLY IF the current r-density is strictly below exact alpha on the bottleneck
   word (affine-floor under-credit). If r-density already equals exact alpha
   there, the residual slack is entirely theta-side and the tilt is inert. *)

SetDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{Directory[], "..", "composition-optimality", "EpsilonCertificate.wl"}]];
Get[FileNameJoin[{Directory[], "..", "composition-optimality", "EpsilonCertificate8.wl"}]];

dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
        ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "d", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];

(* d(x) = theta payoff at node x ; r(e) = alpha credit at edge e *)
dNode[CE_][x_] := CE["Q"][x][[5, 5]] + CE["R"][x][[4, 4]];
rEdge[CE_][e_] := Module[{w = e[[1]], x = e[[2]], T},
   T = dpTransfer[StringTake[w, {-1}]];
   Min[Table[Module[{sig = CE["Strategy"][ToString[s - 1] <> "|" <> w <> ">" <> x]},
       T[[s, sig]] + CE["Phi"][ToString[sig - 1] <> "|" <> x] -
        CE["Phi"][ToString[s - 1] <> "|" <> w]], {s, 3}]]];

cycleNodesEdges[word_, k_] := Module[{p = StringLength[word], wl, nodes},
   wl = Characters[StringRepeat[word, Ceiling[(k + 2)/p] + 2]];
   nodes = Table[StringJoin[wl[[j ;; j + k - 1]]], {j, 1, p}];
   {nodes, Table[{nodes[[i]], nodes[[Mod[i, p] + 1]]}, {i, p}]}];

dDensity[CE_][word_, k_] := Module[{ne = cycleNodesEdges[word, k]},
   Mean[dNode[CE] /@ ne[[1]]]];
rDensity[CE_][word_, k_] := Module[{ne = cycleNodesEdges[word, k]},
   Mean[rEdge[CE] /@ ne[[2]]]];

(* exact alpha density: max-plus cycle mean of the 3x3 period product *)
mpMul[A_, B_] := Table[Max[Table[A[[i, kk]] + B[[kk, j]], {kk, 3}]], {i, 3}, {j, 3}];
alphaDensity[word_] := Module[{P = None, M, Q, best = -Infinity},
   Do[M = dpTransfer[StringTake[word, {c, c}]];
      P = If[P === None, M, mpMul[P, M]], {c, StringLength[word]}];
   Q = P;
   Do[Do[best = Max[best, Q[[i, i]]/ell], {i, 3}]; Q = mpMul[Q, P], {ell, 1, 3}];
   best/StringLength[word]];

words = {"ddt", "dtt", "dttt", "ddtt", "ddttt", "t"};
Print["word |  alpha_exact  d-dens(k) r-dens(k) | r-alpha | gap_cert=d-r | gap_true=theta-alpha"];

report[CE_, k_, tag_] := (
  Print["=== ", tag, "  (Gamma=", N[CE["Gamma"], 8], ") ==="];
  Do[Module[{a = alphaDensity[w], dd = dDensity[CE][w, k], rr = rDensity[CE][w, k]},
     Print[StringPadRight[w, 6], " | ",
       N[a, 7], "  ", N[dd, 7], "  ", N[rr, 7], " | ",
       "r-alpha=", N[rr - a, 5], " | gap_cert=", N[dd - rr, 6]]],
    {w, words}]);

report[EpsilonCertificate, 7, "k=7 (EpsilonCertificate, bottleneck dttt)"];
report[EpsilonCertificate8, 8, "k=8 (EpsilonCertificate8, bottleneck dtt)"];
