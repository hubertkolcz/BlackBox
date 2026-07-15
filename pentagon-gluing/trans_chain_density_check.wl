(* In-Wolfram verification of the trans-chain bulk density conjecture, at m
   values far beyond the existing Python evidence (m=50..800, with ~0.01
   boundary-transient noise at small m). Reuses transChainWL[m] and
   LovaszThetaSparse VERBATIM from CaseStudies.wl / the BlackBox paclet --
   no new construction, just running the existing machinery at larger scale.
   Target: transDensityLimit = tauStar = 1.376717745915859 (exact algebraic
   root, CaseStudies.wl:249). Success = per-block increment
   (theta(chain m2)-theta(chain m1))/(m2-m1) converging to tauStar to
   ~1e-5/1e-6, well inside the documented small-m noise floor. *)

SetDirectory[DirectoryName[$InputFileName]];
PacletDirectoryLoad[FileNameJoin[{Directory[], "..", "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"];
Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];

transChainWL[m_Integer] := Module[{edges = {}, u = 1, v = 2},
  Do[Module[{a = 3 k + 3, b = 3 k + 4, x = 3 k + 5},
    edges = Join[edges, {{u, v}, {u, a}, {a, b}, {b, x}, {x, v}}];
    {u, v} = {b, a}], {k, 0, m - 1}];
  Graph[Range[3 m + 2], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];

tauStar = Root[49 #^3 - 128 #^2 - 75 # + 218 &, 2];
Print["Target density tauStar = ", N[tauStar, 16]];

mValues = {50, 200, 1000, 5000};
results = {};
Do[
  Module[{t, theta},
    {t, theta} = AbsoluteTiming[LovaszThetaSparse[transChainWL[m]]];
    AppendTo[results, {m, theta, t}];
    Print["m = ", m, ": theta = ", N[theta, 10], ", time = ", t, "s"]],
  {m, mValues}];

Print["=== Per-block increments vs tauStar ==="];
Do[
  Module[{m1, m2, th1, th2, incr},
    {m1, th1, _} = results[[i - 1]]; {m2, th2, _} = results[[i]];
    incr = (th2 - th1)/(m2 - m1);
    Print["  (theta(", m2, ")-theta(", m1, "))/(", m2, "-", m1, ") = ", N[incr, 10],
      ", |incr - tauStar| = ", N[Abs[incr - tauStar], 6]]],
  {i, 2, Length[results]}];
