(* ::Package:: *)

(* Simulation of "Experimental non-classicality of an indivisible quantum system"
   R. Lapkiewicz et al., Nature 474, 490 (2011) -- the KCBS test on a single qutrit.

   Model: a single photon in 3 optical modes = a qutrit. Each KCBS direction l_i
   defines A_i = 2|l_i><l_i| - 1. Neighbouring directions are orthogonal, so each
   context (A_i, A_{i+1}) is one 3-output interferometer: a projective measurement
   in the basis {l_i, l_{i+1}, l_i x l_{i+1}}.

   KCBS (correlation form):  S = Sum <A_i A_{i+1}>  >= -3  (NCHV),
   quantum minimum 5 - 4 Sqrt[5] = -3.944...
   As in the experiment, the last context uses a sixth observable A1'
   (exactly orthogonal to l5, possibly misaligned from l1) and the corrected
   bound S >= -3 - eps with eps = 2 P(A1 != A1'), estimated sequentially.

   Run:  wolframscript -file kcbs_simulation.wl                                  *)

SeedRandom[20260709];

(* ---------------- geometry: exact symbolic pentagon ---------------- *)
c2 = Cos[Pi/5]/(1 + Cos[Pi/5]);   (* cos^2 of the cone half-angle *)
vecs = Table[{Sqrt[1 - c2] Cos[4 Pi i/5],
              Sqrt[1 - c2] Sin[4 Pi i/5],
              Sqrt[c2]}, {i, 0, 4}];
psi = {0, 0, 1};                  (* state maximally violating KCBS *)

orthos   = FullSimplify @ Table[vecs[[i]] . vecs[[Mod[i, 5] + 1]], {i, 5}];
projSum  = FullSimplify @ Total[(vecs . psi)^2];
sQMexact = FullSimplify @
  Sum[1 - 2 ((vecs[[i]] . psi)^2 + (vecs[[Mod[i, 5] + 1]] . psi)^2), {i, 5}];

(* ---------------- NCHV bounds by brute force over all 32 assignments ------- *)
assignments = Tuples[{-1, 1}, 5];
nchvCorr = Min[Total[# RotateLeft[#]] & /@ assignments];
nchvProj = Max[Count[#, 1] & /@
   Select[assignments, Max[# + RotateLeft[#]] < 2 &]];   (* exclusivity: no adjacent 1,1 *)

(* ---------------- one context = one interferometer ---------------- *)
(* noise model: rho = V |psi><psi| + (1-V) I/3 ; Poissonian source *)
measureContext[a_, b_, v_, n0_] := Module[{basis, probs, n, counts, corr},
  basis = {a, b, Normalize @ Cross[a, b]};
  probs = N[v (basis . psi)^2 + (1 - v)/3];
  probs = probs/Total[probs];
  n = RandomVariate @ PoissonDistribution[n0];
  counts = RandomVariate @ MultinomialDistribution[n, probs];
  (* detector 1 -> (+1,-1), 2 -> (-1,+1), 3 -> (-1,-1) *)
  corr = N[(-counts[[1]] - counts[[2]] + counts[[3]])/n];
  {corr, Sqrt[(1 - corr^2)/n]}];

(* ---------------- eps: measure A1 then A1' in sequence ---------------- *)
seqDisagree[l1_, l1p_, v_, n0_] := Module[{p1, qpp, perp, qmp, pdiff, n, k},
  p1   = N[v (l1 . psi)^2 + (1 - v)/3];
  qpp  = N[(l1p . l1)^2];                       (* P(A1'=+1 | A1=+1) *)
  perp = psi - (l1 . psi) l1;
  qmp  = N[v (l1p . Normalize[perp])^2 + (1 - v)/2];
  pdiff = p1 (1 - qpp) + (1 - p1) qmp;
  n = RandomVariate @ PoissonDistribution[n0];
  k = RandomVariate @ BinomialDistribution[n, pdiff];
  {2. k/n, 2 Sqrt[pdiff (1 - pdiff)/n]}];

(* ---------------- full experimental run ---------------- *)
runExperiment[n0_, v_, misDeg_] := Module[{u, d, l1p, pairs, res, s, ds, eps, deps},
  u = Normalize @ Cross[vecs[[5]], vecs[[1]]];
  d = misDeg Degree;
  l1p = Cos[d] vecs[[1]] + Sin[d] u;            (* exactly _|_ l5, tilted from l1 *)
  pairs = {{vecs[[1]], vecs[[2]]}, {vecs[[2]], vecs[[3]]}, {vecs[[3]], vecs[[4]]},
           {vecs[[4]], vecs[[5]]}, {vecs[[5]], l1p}};
  res = measureContext[#[[1]], #[[2]], v, n0] & /@ pairs;
  s = Total @ res[[All, 1]];  ds = Sqrt @ Total[res[[All, 2]]^2];
  {eps, deps} = seqDisagree[vecs[[1]], l1p, v, n0];
  <|"S" -> s, "dS" -> ds, "corrs" -> res[[All, 1]], "eps" -> eps, "deps" -> deps|>];

(* ---------------- report ---------------- *)
line[s_] := Print[s];
line["==== KCBS geometry (exact) ===="];
line["consecutive dot products l_i.l_{i+1}: " <> ToString[orthos]];
line["sum <P_i> = " <> ToString[projSum] <> " = " <> ToString @ N[projSum, 8] <>
     "   (NCHV bound: " <> ToString[nchvProj] <> ")"];
line["S_QM = " <> ToString[sQMexact] <> " = " <> ToString @ N[sQMexact, 8] <>
     "   (NCHV bound: " <> ToString[nchvCorr] <> ")"];

line["\n==== ideal run: V=1, perfect alignment, 10^6 photons/context ===="];
r = runExperiment[10^6, 1., 0.];
line["correlations: " <> ToString @ NumberForm[r["corrs"], {5, 4}]];
line["S = " <> ToString @ NumberForm[r["S"], {6, 4}] <> " +/- " <>
     ToString @ NumberForm[r["dS"], {5, 4}] <> ",  eps = " <>
     ToString @ NumberForm[r["eps"], {5, 4}]];
line["violation of (-3 - eps): " <>
     ToString @ Round[(-3 - r["eps"] - r["S"])/r["dS"]] <> " sigma"];

line["\n==== realistic run: V=0.977, A1' misaligned 1 deg (Nature 2011 regime) ===="];
r = runExperiment[10^6, 0.977, 1.];
line["correlations: " <> ToString @ NumberForm[r["corrs"], {5, 4}]];
line["S = " <> ToString @ NumberForm[r["S"], {6, 4}] <> " +/- " <>
     ToString @ NumberForm[r["dS"], {5, 4}]];
line["eps = " <> ToString @ NumberForm[r["eps"], {5, 4}] <>
     "  ->  corrected NCHV bound " <> ToString @ NumberForm[-3 - r["eps"], {6, 4}]];
line["paper reported: S = -3.893 +/- 0.006"];
line["violation of corrected bound: " <>
     ToString @ Round[(-3 - r["eps"] - r["S"])/Sqrt[r["dS"]^2 + r["deps"]^2]] <> " sigma"];

line["\n==== noise robustness ===="];
vCrit = FullSimplify[(-3 + 5/3)/(5 - 4 Sqrt[5] + 5/3)];
line["S(V) = V(5-4Sqrt[5]) + (1-V)(-5/3) < -3  requires  V > " <>
     ToString[vCrit] <> " = " <> ToString @ N[vCrit, 6]];
Do[
  r = runExperiment[10^5, v, 0.];
  line["V = " <> ToString @ NumberForm[v, {4, 3}] <> ":  S = " <>
       ToString @ NumberForm[r["S"], {6, 4}] <> " +/- " <>
       ToString @ NumberForm[r["dS"], {5, 4}] <>
       If[r["S"] + 2 r["dS"] < -3, "   VIOLATES", ""]],
  {v, {1., 0.977, 0.9, 0.7, 0.6, 0.55}}];
