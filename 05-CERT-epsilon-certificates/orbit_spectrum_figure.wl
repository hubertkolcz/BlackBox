(* ::Package:: *)
(* orbit_spectrum_figure.wl -- essay figure for CONVERGENCE-ANALYSIS-2026-07-13.md.
   Visualizes the finding that the "spurious" strategy-iteration seed values are
   periodic-orbit densities: observed value + 1 = theta-density of a gluing orbit.
   Panel A: the density spectrum from trans tau-star to cis 3/2, orbits marked.
   Panel B: seed value vs orbit density -- spurious orbits lie on value=density-1
   (alpha-correction OFF); the true optimum cct drops to value=density-4/3 (real gap).
   Run: wolframscript -file orbit_spectrum_figure.wl  ->  orbit_spectrum.png / .pdf *)

tau   = N[Root[49 #^3 - 128 #^2 - 75 # + 218 &, 2], 30];   (* trans density *)
cct   = 1.4032308692389975;                                 (* cct density *)
aBar  = 4/3;                                                (* cct alpha-density *)
gapCct = cct - aBar;                                        (* 0.0698975 *)

(* {density, label, observedSeedValue} for the orbits the random seeds revealed *)
orbits = {
  {tau,  "trans  \[Tau]*", 0.376723},
  {16/11, "16/11", 0.4545496},
  {19/13, "19/13", 0.4615426},
  {25/17, "25/17", 0.470592},
  {3/2,  "cis  3/2", 0.500004}
};

(* --- palette --- *)
cExtreme = RGBColor[0.22, 0.35, 0.62];   (* trans / cis: structural extremes *)
cMixed   = RGBColor[0.45, 0.48, 0.55];   (* mixed orbits *)
cOpt     = RGBColor[0.85, 0.58, 0.13];   (* cct: the true optimum *)
cLine    = RGBColor[0.65, 0.67, 0.72];
ink      = GrayLevel[0.15];

lo = 1.355; hi = 1.512;

(* ============ PANEL A : density spectrum ============ *)
axisY = 0;
tickH = 0.05;
labSlot[i_] := {0.34, 0.60, 0.34, 0.60, 0.34}[[i]];  (* stagger mixed labels *)

panelA = Graphics[{
   (* axis *)
   {ink, Thickness[0.004], Line[{{lo, axisY}, {hi, axisY}}]},
   {ink, Thickness[0.004], Line[{{hi, axisY}, {hi - 0.006, axisY + 0.012}}],
     Line[{{hi, axisY}, {hi - 0.006, axisY - 0.012}}]},
   (* axis ticks with density values *)
   Table[{GrayLevel[0.55], Line[{{d, axisY - 0.02}, {d, axisY + 0.02}}],
     Text[Style[NumberForm[N[d], {4, 3}], 8, GrayLevel[0.5]], {d, axisY - 0.09}]},
     {d, {1.38, 1.40, 1.42, 1.44, 1.46, 1.48, 1.50}}],
   (* the "crowding zone" brace *)
   {cLine, Thickness[0.002],
     Line[{{16/11, 0.16}, {16/11, 0.13}, {25/17, 0.13}, {25/17, 0.16}}]},
   Text[Style["crowding zone (\[CapitalDelta]<0.016)", 8, cLine, Italic], {19/13, 0.19}],
   (* orbit markers + staggered labels *)
   Table[With[{d = orbits[[i, 1]], lab = orbits[[i, 2]],
       col = If[MemberQ[{1, 5}, i], cExtreme, cMixed], sl = labSlot[i]},
     {{col, PointSize[0.014], Point[{d, axisY}]},
      {col, Thickness[0.0015], Line[{{d, axisY + 0.03}, {d, sl - 0.03}}]},
      Text[Style[lab, 10, col, Bold], {d, sl}]}],
     {i, Length[orbits]}],
   (* cct : the true optimum, highlighted *)
   {cOpt, PointSize[0.02], Point[{cct, axisY}]},
   {cOpt, Thickness[0.002], Line[{{cct, axisY - 0.03}, {cct, -0.14}}]},
   Text[Style["cct  \[LongDash] true optimum", 10, cOpt, Bold], {cct, -0.20}],
   Text[Style["(found by the deterministic seeds)", 8, cOpt], {cct, -0.26}]
   },
  PlotRange -> {{lo, hi}, {-0.30, 0.72}}, AspectRatio -> 0.32, ImageSize -> 760,
  PlotLabel -> Style["A.  Orbit-density spectrum explored by strategy iteration", 12, ink, Bold],
  ImagePadding -> {{10, 10}, {6, 24}}];

(* ============ PANEL B : seed value vs density ============ *)
dRange = {1.355, 1.512};
lineSpur = Line[{{#, # - 1}, {#2, #2 - 1}}] & @@ dRange;   (* value = density - 1 *)
lineGap  = Line[{{#, # - aBar}, {#2, #2 - aBar}}] & @@ dRange; (* value = density - 4/3 *)

panelB = Graphics[{
   (* the two regime lines *)
   {cMixed, Thickness[0.003], lineSpur},
   Text[Style["value = density \[Minus] 1", 9, cMixed], {1.358, 0.508}, {-1, 0}],
   Text[Style["(spurious \[LongDash] \[Alpha]-correction off)", 8, cMixed], {1.358, 0.482}, {-1, 0}],
   {cOpt, Dashing[{0.012, 0.010}], Thickness[0.003], lineGap},
   Text[Style["value = density \[Minus] 4/3  (true gap)", 9, cOpt], {1.508, 0.108}, {1, 0}],
   (* spurious orbit points on the density-1 line *)
   Table[With[{d = N[orbits[[i, 1]]], v = orbits[[i, 3]],
       col = If[MemberQ[{1, 5}, i], cExtreme, cMixed]},
     {{col, PointSize[0.013], Point[{d, v}]},
      Text[Style[orbits[[i, 2]], 8, col], {d, v + 0.028}]}],
     {i, Length[orbits]}],
   (* cct on the real-gap line + the drop arrow *)
   {cOpt, PointSize[0.02], Point[{cct, gapCct}]},
   Text[Style["cct", 9, cOpt, Bold], {cct + 0.006, gapCct + 0.028}],
   {GrayLevel[0.6], Dashing[{0.006, 0.006}], Arrowheads[0.02],
     Arrow[{{cct, cct - 1}, {cct, gapCct + 0.01}}]},
   Text[Style["\[Alpha]-cocycle\ndevelops", 8, GrayLevel[0.45], Italic],
     {cct - 0.028, (cct - 1 + gapCct)/2}]
   },
  PlotRange -> {dRange, {-0.02, 0.56}}, AspectRatio -> 0.5, ImageSize -> 760,
  Frame -> {{True, False}, {True, False}}, FrameStyle -> GrayLevel[0.55],
  FrameLabel -> {Style["orbit \[Theta]-density", 10, ink],
     Style["reported seed value", 10, ink]},
  FrameTicks -> {{Automatic, None}, {Automatic, None}},
  PlotLabel -> Style["B.  Why the optimum is special: the \[Alpha]-correction drops cct off the density\[Minus]1 line", 12, ink, Bold],
  ImagePadding -> {{55, 12}, {40, 24}}];

fig = Column[{panelA, panelB}, Spacings -> 1.2, Alignment -> Center];

Export["orbit_spectrum.png", fig, ImageResolution -> 150];
Export["orbit_spectrum.pdf", fig];
Print["WROTE orbit_spectrum.png (", FileByteCount["orbit_spectrum.png"], " bytes) and .pdf"];
Print["tau* = ", tau, "  |  cct = ", cct, "  |  gap(cct) = ", gapCct];
Print["check: 16/11-1=", N[16/11 - 1], " vs obs 0.4545496 ; 25/17-1=", N[25/17 - 1], " vs obs 0.470592"];
