(* ::Package:: *)

(* bridge_debruijn_cosheaf.wl --- ESSAY-005 BRIDGE, Formalizer D.

   Packages the windowed transfer-SDP epsilon-certificate as a CELLULAR (co)sheaf
   on the de Bruijn-k digraph with coefficients in the (max,+) tropical semiring
   T = R_max = (R U {-Inf}, max, +), and VALIDATES the sub-action = 0-cochain claim:

     X = de Bruijn-k digraph. 0-cells V = length-k words over {c,t} (|V|=2^k);
     1-cells E = transitions w->x with overlap k-1 (|E|=2^(k+1)); strongly connected.
     Stalks all T. C^0(X)=T^V is the potential field Psi; C^1(X)=T^E the edge field.
     Coboundary (delta Psi)(e) = Psi(head) - Psi(tail) (tropical division = subtraction).
     Edge weight  c(e) = d(x) - r(e),  d(x) = Q[x][5,5]+R[x][4,4] (SDP theta-density
     head payoff), r(e) = min_s (T_ell[s,sigma(s,e)] + Phi[sigma-1,x] - Phi[s-1,w]) the
     inner (min,+) alpha value. Transfer operator (L Psi)(w) = max_{x:w->x}(c+Psi(x)),
     matrix M[w,x]=c(w->x), -Inf off-edges.

   CLAIM (D). Gamma_k = the unique (max,+) eigenvalue of L = max cycle mean of c over
   de Bruijn-k = min_Psi max_e (c(e)+Psi(x)-Psi(w)). The certificate inequality
   sigma(e) = d(x)-r(e)+Psi(x)-Psi(w) <= Gamma_k for all e is exactly L Psi <= Gamma_k (x) Psi,
   i.e. the certificate's Psi is a Gamma_k-super-eigenvector / calibrated Bousch sub-action
   (a 0-cochain), and it attains the dual min (max_e sigma = Gamma_k exactly).

   GATES per window k: (i) sub-action bound sigma(e) <= Gamma_k for ALL e (exact rational);
   (ii) dual attainment max_e sigma(e) = Gamma_k EXACTLY; (iii) an INDEPENDENT Karp
   max-cycle-mean of c equals Gamma_k up to the rationalization sliver: 0 <= Gamma_k - mcm
   < 10^-7 (the project's posCheck tolerance); (iv) an independently-built tropical
   eigenvector Psi* (bias vector) satisfies L Psi* = mcm (x) Psi* on the critical class.

   NO SDP is solved here: this reads already-materialized certificate files and does exact
   rational tropical linear algebra only (local, license-cheap, no cloud). dpTransfer is
   copied verbatim from GenerateEpsilonCertificate9.wl / CaseStudies.wl.

   Run:  wolframscript -file bridge_debruijn_cosheaf.wl
*)

$HistoryLength = 0;
$RecursionLimit = 100000;
$IterationLimit = Infinity;
scriptDir = DirectoryName[ExpandFileName[$InputFileName]];
certDir = FileNameJoin[{scriptDir, "..", "05-CERT-epsilon-certificates"}];
Print["bridge_debruijn_cosheaf.wl start ", DateString[]];

(* ---- interface-DP transfer matrix, verbatim from the generator ---- *)
dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
   Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
        ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
      out = If[letter === "c", {s1, s2}, {s2, s1}];
      j = Position[dpStates, out][[1, 1]];
      T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
     {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
   T];

(* ---- de Bruijn-k graph and the certificate cochains ---- *)
deBruijnNodes[k_] := StringJoin /@ Tuples[{"c", "t"}, k];
deBruijnEdges[nodes_] := Select[Tuples[nodes, 2],
   StringDrop[#[[1]], 1] === StringDrop[#[[2]], -1] &];

ip = 5; jp = 4;

(* d(x): SDP theta-density head payoff at window x *)
dHead[CE_][x_] := CE["Q"][x][[ip, ip]] + CE["R"][x][[jp, jp]];

(* r(e): inner (min,+) alpha value under the certificate strategy *)
rInner[CE_][e_] := Module[{w = e[[1]], x = e[[2]], T},
   T = dpTransfer[StringTake[w, {-1}]];
   Min[Table[Module[{sig = CE["Strategy"][ToString[s - 1] <> "|" <> w <> ">" <> x]},
       T[[s, sig]] + CE["Phi"][ToString[sig - 1] <> "|" <> x]
        - CE["Phi"][ToString[s - 1] <> "|" <> w]], {s, 3}]]];

cWeight[CE_][e_] := dHead[CE][e[[2]]] - rInner[CE][e];               (* c(e) = d(x)-r(e) *)
sigmaSlack[CE_][e_] := cWeight[CE][e] + CE["Psi"][e[[2]]] - CE["Psi"][e[[1]]]; (* sigma(e) *)

(* ---- exact Karp max-cycle-mean = (max,+) tropical eigenvalue of L ----
   F[j][v] = max total c-weight over walks of length exactly j from source s to v
   (tropical -Inf if none). Karp: lambda = max_v min_{0<=j<=n-1} (F[n][v]-F[j][v])/(n-j).
   Strongly connected => every v reachable => F[n][v] finite for all v. Exact rational. *)
(* inEdgesTable: vertex-index vi -> list of {source-index ui, c(u->v)} *)
inEdgesTable[nodes_, edges_, cAssoc_] := Module[{idx = AssociationThread[nodes -> Range[Length[nodes]]], tab},
   tab = Association[Table[v -> {}, {v, Range[Length[nodes]]}]];
   Do[AppendTo[tab[idx[e[[2]]]], {idx[e[[1]]], cAssoc[e]}], {e, edges}];
   tab];

(* returns {lambda = max cycle mean, vStar = a node on a maximum-mean cycle} *)
karpMaxCycleMean[nodes_, edges_, cAssoc_] := Module[
   {n = Length[nodes], inEdges, F, s, best, vStar, v, j, mins, val},
   inEdges = inEdgesTable[nodes, edges, cAssoc];
   s = 1;
   F = ConstantArray[-Infinity, {n + 1, n}];
   F[[1, s]] = 0;
   Do[
     Do[
       If[inEdges[v] =!= {},
         F[[j + 1, v]] = Max[Table[F[[j, u[[1]]]] + u[[2]], {u, inEdges[v]}]]],
       {v, n}],
     {j, 1, n}];
   best = -Infinity; vStar = s;
   Do[
     If[F[[n + 1, v]] =!= -Infinity && NumericQ[F[[n + 1, v]]],
       mins = Infinity;
       Do[
         If[F[[j + 1, v]] =!= -Infinity && NumericQ[F[[j + 1, v]]],
           val = (F[[n + 1, v]] - F[[j + 1, v]])/(n - j);
           mins = Min[mins, val]],
         {j, 0, n - 1}];
       If[mins > best, best = mins; vStar = v]],
     {v, n}];
   {best, vStar}];

(* ---- independent tropical eigenvector (bias vector) via longest-path from the
   normalized operator L - lambda: with lambda the eigenvalue, the graph c-lambda has
   no positive cycle, so PsiStar(v) = max total (c-lambda)-weight of any walk ENDING at v
   from a critical vertex is finite and satisfies L.PsiStar(w) = lambda + PsiStar(w) on the
   recurrent (critical) class. We compute it by tropical power iteration of L-lambda to a
   fixed point and verify L.PsiStar = lambda (x) PsiStar on the argmax edges (critical cycle). *)
(* Independently reconstructed calibrated sub-action (tropical super-eigenvector) for
   eigenvalue lambda = mcm, WITHOUT using the certificate's Psi. Longest-path fixed point
   of B = c - lambda seeded 0 at every node (empty-walk = 0). Since mcm(B)=0 there is no
   positive cycle, so u(v) = max(0, longest B-walk ending at v) is finite and satisfies
   the calibrated Bousch sub-action inequality (L u)(v) <= lambda (x) u(v) for all v, with
   EQUALITY attained on the critical (max-mean) cycle. This is the exact dynamic analogue
   of the certificate's Psi: a 0-cochain that is a Gamma-super-eigenvector attaining the
   dual optimum -- here for the true eigenvalue mcm. *)
biasVector[nodes_, edges_, cAssoc_, lambda_] := Module[
   {n = Length[nodes], inEdges, u, uNew, iters},
   inEdges = inEdgesTable[nodes, edges, cAssoc];
   u = ConstantArray[0, n];
   Do[
     uNew = Table[
        If[inEdges[v] =!= {},
          Max[u[[v]], Max[Table[u[[uu[[1]]]] + (uu[[2]] - lambda), {uu, inEdges[v]}]]],
          u[[v]]],
        {v, n}];
     If[uNew === u, Break[]];
     u = uNew,
     {iters, 2 n + 2}];
   u];

(* ---- per-window validation ---- *)
validateWindow[CE_, label_] := Module[
   {k, nodes, edges, cA, sig, gamMax, gam, subOK, attainOK, mcm, vStar, sliver, mcmOK,
    bias, inEdges, eigResid, eigOK, res},
   k = CE["k"]; gam = CE["Gamma"];
   nodes = CE["Nodes"]; edges = deBruijnEdges[nodes];
   cA = Association[Table[e -> cWeight[CE][e], {e, edges}]];
   sig = Association[Table[e -> sigmaSlack[CE][e], {e, edges}]];
   gamMax = Max[Values[sig]];
   subOK = AllTrue[Values[sig], # <= gam &];                    (* (i)  sub-action bound *)
   attainOK = (gamMax === gam);                                 (* (ii) exact dual attainment *)
   {mcm, vStar} = karpMaxCycleMean[nodes, edges, cA];           (* (iii) independent eigenvalue *)
   sliver = gam - mcm;
   mcmOK = (sliver >= 0) && (N[sliver] < 10^-7);
   bias = biasVector[nodes, edges, cA, mcm];                    (* (iv) reconstructed sub-action *)
   inEdges = inEdgesTable[nodes, edges, cA];
   (* residual of L bias - mcm (x) bias; <= 0 everywhere (super-eigvec), = 0 attained on
      the critical cycle => calibrated sub-action for the true eigenvalue mcm *)
   eigResid = Select[Table[
      If[inEdges[v] =!= {},
        Max[Table[bias[[u[[1]]]] + u[[2]], {u, inEdges[v]}]] - (mcm + bias[[v]]),
        -Infinity], {v, Length[nodes]}], NumericQ];
   eigOK = (Max[eigResid] === 0) && AllTrue[eigResid, # <= 0 &];  (* calibrated: <=0, sup=0 *)
   res = <|
     "label" -> label, "k" -> k, "nodes" -> Length[nodes], "edges" -> Length[edges],
     "Gamma" -> gam, "GammaN" -> N[gam, 10],
     "maxSigma" -> gamMax, "subActionBoundOK" -> subOK, "dualAttainedExact" -> attainOK,
     "maxCycleMean" -> mcm, "mcmN" -> N[mcm, 10],
     "sliver" -> sliver, "sliverN" -> N[sliver], "mcmSliverOK" -> mcmOK,
     "eigenvectorEqualityOnCriticalCycle" -> eigOK,
     "allOK" -> (subOK && attainOK && mcmOK && eigOK)|>;
   Print["--- window k=", k, "  (", label, ") ---"];
   Print["  |V|=", Length[nodes], " |E|=", Length[edges],
     "   Gamma_", k, " = ", gam, " = ", N[gam, 10]];
   Print["  (i)   sub-action bound  sigma(e) <= Gamma  for all edges : ", subOK];
   Print["  (ii)  dual attained  max_e sigma(e) == Gamma  (exact)     : ", attainOK,
     "   (max_e sigma = ", N[gamMax, 10], ")"];
   Print["  (iii) Karp max-cycle-mean = tropical eigenvalue           : ", N[mcm, 10]];
   Print["        sliver Gamma - mcm = ", N[sliver], "  in [0,1e-7) : ", mcmOK];
   Print["  (iv)  reconstructed sub-action: L u <= mcm (x) u, sup slack=0 : ", eigOK];
   Print["  ==> window k=", k, " allOK = ", res["allOK"]];
   res];

(* ---- load every materialized certificate; each file assigns a distinct symbol ---- *)
certFiles = {
   {"EpsilonCertificate_testK3_output.wl", "EpsilonCertificate9"},
   {"EpsilonCertificate_testK4_output.wl", "EpsilonCertificate9"},
   {"EpsilonCertificate_testK5_output.wl", "EpsilonCertificate9"},
   {"EpsilonCertificate.wl",               "EpsilonCertificate"},
   {"EpsilonCertificate8.wl",              "EpsilonCertificate8"}};
(* if a locally-generated k=6 certificate exists, validate it too (fills the 0.0824 anchor) *)
If[FileExistsQ[FileNameJoin[{certDir, "EpsilonCertificate6.wl"}]],
   AppendTo[certFiles, {"EpsilonCertificate6.wl", "EpsilonCertificate6"}]];

results = {};
Do[
  Module[{path = FileNameJoin[{certDir, cf[[1]]}], symName = cf[[2]], CE},
    If[! FileExistsQ[path], Print["MISSING: ", path]; Continue[]];
    Print["loading ", cf[[1]], " ..."];
    ClearAll[EpsilonCertificate, EpsilonCertificate6, EpsilonCertificate8, EpsilonCertificate9];
    Get[path];
    CE = Symbol[symName];
    Print["  loaded; k=", CE["k"], " nodes=", Length[CE["Nodes"]], "; validating ..."];
    AppendTo[results, validateWindow[CE, cf[[1]]]]],
  {cf, certFiles}];

Print["\n================ SUMMARY (window indexing k = word length) ================"];
Print["  k :  Gamma_k(N)     maxSig==Gam  sub-bound  Gamma-mcm   eigvec  allOK"];
Do[Print["  ", r["k"], " :  ", N[r["Gamma"], 10], "   ",
    r["dualAttainedExact"], "       ", r["subActionBoundOK"], "     ",
    N[r["sliverN"]], "   ", r["eigenvectorEqualityOnCriticalCycle"],
    "   ", r["allOK"]],
  {r, results}];
Print["\nAnchor note (brief vs window indexing): the task brief labels these as ",
  "Gamma_(k-1); i.e. brief Gamma_3=0.1020 is window k=4, brief Gamma_5=0.0824 is ",
  "window k=6. Window indexing (word length) is authoritative -- see the file header."];
Print["ALL windows OK -> ", AllTrue[results, #["allOK"] &]];
Print["bridge_debruijn_cosheaf.wl done ", DateString[]];
