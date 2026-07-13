(* bridge_tropical_limit.wl -- Formalizer C's tropical-limit / Maslov-dequantization bridge.
   Companion to ESSAY-005-BRIDGE-formalC-tropical-limit.md.

   OBJECT.  On the de Bruijn-K graph the certificate supplies the additive edge cocycle
       sigma(e) = d(x) - r(e) + Psi(x) - Psi(w)          (posSigma, verbatim from CaseStudies.wl)
   whose max cycle mean = tropical (max,+) eigenvalue = Gamma_K [proj/lit].
   A^(K)_{w->x} := sigma(w->x)  for legal de Bruijn edges,  -Infinity otherwise.
   (Using sigma rather than the bare g=d(x)-r(e) is harmless: the coboundary Psi(x)-Psi(w)
    is exp(beta Psi) diagonal similarity in the (+,x) world, so exp(beta sigma) and exp(beta g)
    are SIMILAR matrices with identical Perron spectrum at EVERY beta -- same F_K(beta).)

   MASLOV QUANTIZATION at inverse temperature beta:
       T_beta = exp(beta A^(K))  (exp(-Inf)=0),  a nonneg irreducible (+,x) Ruelle operator.
       F_K(beta) = (1/beta) log rho(T_beta),  rho = Perron spectral radius.
   CLAIM C-lim:  F_K(beta) decreasing,  lim_{beta->inf} F_K(beta) = Gamma_K.
   Anchors (de Bruijn window K):  Gamma_3 = 1/8 = 0.125 exactly;
       Gamma_4 = 0.10196412702492699;  Gamma_5 = 0.0952971530959493.

   All local; numeric eigenvalues only; log-sum-exp stabilized. No cloud, no SDP. *)

$certDir = "C:/Users/cp/Desktop/black-box/05-CERT-epsilon-certificates";

(* interface-DP transfer matrix, verbatim from CaseStudies.wl / the generator *)
dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
        ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "c", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];

posEdges[CE_] := Select[Tuples[CE["Nodes"], 2], StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];

(* the certified cocycle sigma(e), verbatim (posSigma, CaseStudies.wl line ~419) *)
posSigma[CE_][e_] := Module[{w = e[[1]], x = e[[2]], T, r, ip = 5, jp = 4},
   T = dpTransfer[StringTake[w, {-1}]];
   r = Min[Table[Module[{sig = CE["Strategy"][ToString[s - 1] <> "|" <> w <> ">" <> x]},
        T[[s, sig]] + CE["Phi"][ToString[sig - 1] <> "|" <> x] - CE["Phi"][ToString[s - 1] <> "|" <> w]], {s, 3}]];
   (CE["Q"][x][[ip, ip]] + CE["R"][x][[jp, jp]]) - r + CE["Psi"][x] - CE["Psi"][w]];

(* ---- max cycle mean (tropical eigenvalue) via max-plus powers, Karp-style ---- *)
mpMatMul[A_, B_] := Table[Max[A[[i, All]] + B[[All, j]]], {i, Length[A]}, {j, Length[B[[1]]]}];
maxCycleMean[A_] := Module[{n = Length[A], P = A, best = -Infinity, k},
   Do[best = Max[best, Max[Table[P[[i, i]], {i, n}]/k]];
      If[k < n, P = mpMatMul[P, A]], {k, 1, n}];
   best];

(* which cycle attains it: the argmax simple cycle word (small graphs only) *)
bestCycleNode[A_, nodes_] := Module[{n = Length[A], P = A, rec = {}, k, diag, m},
   Do[diag = Table[P[[i, i]], {i, n}]/k; m = Max[diag];
      AppendTo[rec, {k, m, First@Ordering[-diag, 1]}];
      If[k < n, P = mpMatMul[P, A]], {k, 1, n}];
   rec = Select[rec, NumberQ[#[[2]]] &];
   First@MaximalBy[rec, #[[2]] &]];

(* Gibbs / Perron data at inverse temperature beta, log-sum-exp stabilized *)
freeEnergy[A_, beta_] := Module[{n = Length[A], maxA, Texp, ev, rho},
   maxA = Max[Select[Flatten[A], NumberQ]];
   Texp = Table[If[NumberQ[A[[i, j]]], Exp[N[beta*(A[[i, j]] - maxA), 40]], 0], {i, n}, {j, n}];
   ev = Eigenvalues[Texp];
   rho = Max[Re[Select[ev, Abs[Im[#]] < 10^-8 &]]];
   maxA + Log[rho]/beta];

(* stationary (Gibbs) mass on nodes = left*right Perron eigvec, to test selection *)
gibbsMass[A_, beta_] := Module[{n = Length[A], maxA, Texp, vr, vl},
   maxA = Max[Select[Flatten[A], NumberQ]];
   Texp = Table[If[NumberQ[A[[i, j]]], Exp[N[beta*(A[[i, j]] - maxA), 40]], 0], {i, n}, {j, n}];
   vr = Abs@Last[Eigenvectors[Texp]];        (* right Perron (smallest-index? use max) *)
   vr = Abs@First[Eigenvectors[Texp][[Ordering[-Re[Eigenvalues[Texp]], 1]]]];
   vl = Abs@First[Eigenvectors[Transpose[Texp]][[Ordering[-Re[Eigenvalues[Transpose[Texp]]], 1]]]];
   Normalize[vr*vl, Total]];

runK[Kval_, certFile_, docGamma_, cctNodesFn_] := Module[
  {CE, nodes, n, idx, edges, A, mcm, betas, tab, bc, best, mass, top, cctNodes},
  Clear[EpsilonCertificate9];
  Get[FileNameJoin[{$certDir, certFile}]];
  CE = EpsilonCertificate9;
  nodes = CE["Nodes"]; n = Length[nodes];
  idx = Association[Table[nodes[[i]] -> i, {i, n}]];
  edges = posEdges[CE];
  A = ConstantArray[-Infinity, {n, n}];
  Do[A[[idx[e[[1]]], idx[e[[2]]]]] = N[posSigma[CE][e], 30], {e, edges}];
  mcm = maxCycleMean[A];
  Print["==================== K = ", Kval, " (", n, " nodes) ===================="];
  Print["  certificate Gamma_", Kval, "  = ", N[CE["Gamma"], 16]];
  Print["  documented Gamma_", Kval, "  = ", docGamma];
  Print["  max cycle mean of A^(K) = ", N[mcm, 16], "   (GATE: matches Gamma_", Kval, ")"];
  betas = {5, 10, 20, 40, 80, 160, 320, 640};
  tab = Table[{b, freeEnergy[A, b], freeEnergy[A, b] - mcm}, {b, betas}];
  Print["  beta        F_K(beta)              F_K(beta) - Gamma_K"];
  Do[Print["  ", PaddedForm[row[[1]], 5], "   ", NumberForm[N[row[[2]], 12], {14, 12}],
      "   ", ScientificForm[N[row[[3]], 4]]], {row, tab}];
  Print["  monotone decreasing in beta: ", OrderedQ[Reverse[tab[[All, 2]]]]];
  (* selection: which cycle does T->0 pick, is it cct? *)
  bc = bestCycleNode[A, nodes];
  cctNodes = cctNodesFn[];
  mass = gibbsMass[A, 640];
  top = Take[SortBy[Table[nodes[[i]] -> mass[[i]], {i, n}], -Last[#] &], Min[4, n]];
  Print["  argmax-cycle-mean bottleneck node (period start): ", nodes[[bc[[3]]]],
     "  (cycle length ", bc[[1]], ")"];
  Print["  cct-orbit de Bruijn-", Kval, " nodes: ", cctNodes];
  Print["  Gibbs mass (beta=640) top nodes: ", top];
  Print["  T->0 mass concentrated on cct-orbit? ",
     Total[mass[[idx /@ cctNodes]]] > 0.9,
     "   (cct-orbit mass = ", N[Total[mass[[idx /@ cctNodes]]], 4], ")"];
  {Kval, N[CE["Gamma"], 16], N[mcm, 16], tab, nodes[[bc[[3]]]], cctNodes,
   N[Total[mass[[idx /@ cctNodes]]], 4]}
];

(* cct = (cct)^inf ; its length-K de Bruijn windows are the K cyclic rotations *)
cctWindows[Kval_] := Module[{s = StringRepeat["cct", Ceiling[(Kval + 3)/3] + 1]},
   DeleteDuplicates[Table[StringTake[s, {j, j + Kval - 1}], {j, 1, 3}]]];

res3 = runK[3, "EpsilonCertificate_testK3_output.wl", 0.125, cctWindows[3] &];
res4 = runK[4, "EpsilonCertificate_testK4_output.wl", 0.10196412702492699, cctWindows[4] &];
res5 = runK[5, "EpsilonCertificate_testK5_output.wl", 0.0952971530959493, cctWindows[5] &];

Print["\n==================== SUMMARY ===================="];
Print["K | Gamma_K(cert) | maxCycleMean(A) | F_K(640) | bottleneck word | cct-orbit T->0 mass"];
Do[Print[r[[1]], " | ", r[[2]], " | ", r[[3]], " | ", N[Last[r[[4]]][[2]], 12],
     " | ", r[[5]], " | ", r[[7]]], {r, {res3, res4, res5}}];
