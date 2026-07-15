(* LEVER 4 probe: does the EXACT optimal certificate data at K=3/4/5 exhibit
   word-reversal / c<->t-swap / reversal+swap symmetry?
   Read-only on the testK outputs; writes nothing outside stdout. *)

SetDirectory[DirectoryName[$InputFileName]];
base = ParentDirectory[Directory[]];

(* transfer matrices, verbatim from GenerateEpsilonCertificate9.wl *)
dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
        ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "c", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];
Tc = dpTransfer["c"]; Tt = dpTransfer["t"];
Print["Tc = ", Tc];
Print["Tt = ", Tt];
Print["Tc -Inf cells: ", Position[Tc, -Infinity]];
Print["Tt -Inf cells: ", Position[Tt, -Infinity]];

rev[w_String] := StringReverse[w];
sw[w_String]  := StringReplace[w, {"c" -> "t", "t" -> "c"}];
rs[w_String]  := sw[rev[w]];

edgeLetter[e_] := StringTake[e[[1]], -1];

probeOne[file_, kExpected_] := Module[
  {cert, nodes, edges, Q, R, Psi, Phi, Strat, d, sigma, maps, mapEdge,
   report, piQswap, piRswap},
  Print["=================================================================="];
  Print["Loading ", file];
  Clear[EpsilonCertificate9];
  Get[FileNameJoin[{base, file}]];
  cert = EpsilonCertificate9;
  Print["k = ", cert["k"], "  Gamma = ", N[cert["Gamma"], 12]];
  nodes = cert["Nodes"]; Q = cert["Q"]; R = cert["R"];
  Psi = cert["Psi"]; Phi = cert["Phi"]; Strat = cert["Strategy"];
  edges = Select[Tuples[nodes, 2],
    StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];
  d = Association[Table[w -> Q[w][[5, 5]] + R[w][[4, 4]], {w, nodes}]];

  sigma[e_] := Module[{w = e[[1]], x = e[[2]], T, r},
    T = If[edgeLetter[e] === "c", Tc, Tt];
    r = Min[Table[
       Module[{sig = Strat[ToString[s - 1] <> "|" <> w <> ">" <> x]},
        T[[s, sig]] + Phi[ToString[sig - 1] <> "|" <> x] -
         Phi[ToString[s - 1] <> "|" <> w]], {s, 3}]];
    d[x] - r + Psi[x] - Psi[w]];
  sigAll = Association[Table[e -> sigma[e], {e, edges}]];

  (* --- node-map tests on d --- *)
  Do[Module[{m = mp[[1]], name = mp[[2]], exact, maxdiff},
     exact = Count[nodes, w_ /; d[w] === d[m[w]]];
     maxdiff = Max[Table[Abs[N[d[w] - d[m[w]], 20]], {w, nodes}]];
     Print["d-invariance under ", name, ": exact-equal ", exact, "/",
       Length[nodes], ", max |diff| = ", ScientificForm[maxdiff, 3]]],
    {mp, {{rev, "reverse"}, {sw, "swap"}, {rs, "rev+swap"}}}];

  (* --- edge-map tests on sigma --- *)
  (* reversal maps edge (w,x) -> (rev x, rev w); swap maps (w,x)->(sw w,sw x) *)
  Do[Module[{name = mp[[1]], f = mp[[2]], exact, maxdiff, msEqual},
     exact = Count[edges, e_ /; sigAll[e] === sigAll[f[e]]];
     maxdiff = Max[Table[Abs[N[sigAll[e] - sigAll[f[e]], 20]], {e, edges}]];
     msEqual = Sort[N[Values[sigAll], 20]] ===
       Sort[N[Table[sigAll[f[e]], {e, edges}], 20]];
     Print["sigma-invariance under ", name, ": exact-equal ", exact, "/",
       Length[edges], ", max |diff| = ", ScientificForm[maxdiff, 3],
       ", multiset-equal(20 digits) = ", msEqual]],
    {mp, {
      {"reverse (e->(rev x,rev w))", Function[e, {rev[e[[2]]], rev[e[[1]]]}]},
      {"swap (e->(sw w,sw x))",      Function[e, {sw[e[[1]]], sw[e[[2]]]}]},
      {"rev+swap (e->(rs x,rs w))",  Function[e, {rs[e[[2]]], rs[e[[1]]]}]}}}];

  (* --- multiset test on d --- *)
  Print["d multiset self-check (trivially true): ",
    Sort[N[Values[d], 20]] === Sort[N[Values[d], 20]]];

  (* --- Q/R block tests under the two admissible index transports ---
     nodeCons force piQ in {id, (13)(24) i.e. u<->a,v<->b}, piR in {id,(12) v<->b} *)
  piQswap = {3, 4, 1, 2, 5}; piRswap = {2, 1, 3, 4};
  Do[Module[{m = mp[[1]], name = mp[[2]], dQid, dQsw, dRid, dRsw, aQid, aQsw},
     dQid = Max[Table[Abs[N[Q[m[w]][[i, j]] - Q[w][[i, j]], 20]],
        {w, nodes}, {i, 5}, {j, 5}]];
     dQsw = Max[Table[
        Abs[N[Q[m[w]][[piQswap[[i]], piQswap[[j]]]] - Q[w][[i, j]], 20]],
        {w, nodes}, {i, 5}, {j, 5}]];
     aQid = Max[Table[Abs[N[Abs[Q[m[w]][[i, j]]] - Abs[Q[w][[i, j]]], 20]],
        {w, nodes}, {i, 5}, {j, 5}]];
     aQsw = Max[Table[
        Abs[N[Abs[Q[m[w]][[piQswap[[i]], piQswap[[j]]]]] - Abs[Q[w][[i, j]]], 20]],
        {w, nodes}, {i, 5}, {j, 5}]];
     dRid = Max[Table[Abs[N[R[m[w]][[i, j]] - R[w][[i, j]], 20]],
        {w, nodes}, {i, 4}, {j, 4}]];
     dRsw = Max[Table[
        Abs[N[R[m[w]][[piRswap[[i]], piRswap[[j]]]] - R[w][[i, j]], 20]],
        {w, nodes}, {i, 4}, {j, 4}]];
     Print["Q/R-invariance under ", name,
       ": Q(id) ", ScientificForm[dQid, 3],
       ", Q(u<->a,v<->b) ", ScientificForm[dQsw, 3],
       ", |Q|(id) ", ScientificForm[aQid, 3],
       ", |Q|(swap) ", ScientificForm[aQsw, 3],
       ", R(id) ", ScientificForm[dRid, 3],
       ", R(v<->b) ", ScientificForm[dRsw, 3]]],
    {mp, {{rev, "reverse"}, {sw, "swap"}, {rs, "rev+swap"}}}];

  (* --- Psi affine-involution fixed-point tests --- *)
  Module[{cRev, cSwap, cRs},
    cRev = Table[N[Psi[w] + Psi[rev[w]] + d[w], 20], {w, nodes}];
    cSwap = Table[N[Psi[sw[w]] - Psi[w], 20], {w, nodes}];
    cRs = Table[N[Psi[w] + Psi[rs[w]] + d[w], 20], {w, nodes}];
    Print["Psi rev-affine (psi(w)+psi(rev w)+d(w)) spread: ",
      ScientificForm[Max[cRev] - Min[cRev], 3]];
    Print["Psi swap (psi(sw w)-psi(w)) spread: ",
      ScientificForm[Max[cSwap] - Min[cSwap], 3]];
    Print["Psi rev+swap affine spread: ",
      ScientificForm[Max[cRs] - Min[cRs], 3]];
    ];
  ];

probeOne["EpsilonCertificate_testK3_output.wl", 3];
probeOne["EpsilonCertificate_testK4_output.wl", 4];
probeOne["EpsilonCertificate_testK5_output.wl", 5];
Print["DONE"];
