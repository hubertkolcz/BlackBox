(* ::Package:: *)
(* orbit_spectrum_figure.wl -- essay figure for CONVERGENCE-ANALYSIS-2026-07-13.md.
   Visualizes the finding that the "spurious" strategy-iteration seed values are
   periodic-orbit densities: observed value + 1 = theta-density of a gluing orbit.
   Panel A: the density spectrum from twisted tau-star to direct 3/2, orbits marked.
   Panel B: seed value vs orbit density -- spurious orbits lie on value=density-1
   (alpha-correction OFF); the true optimum ddt drops to value=density-4/3 (real gap).
   Run: wolframscript -file orbit_spectrum_figure.wl  ->  orbit_spectrum.png / .pdf *)

tau   = N[Root[49 #^3 - 128 #^2 - 75 # + 218 &, 2], 30];   (* twisted density *)
ddt   = 1.4032308692389975;                                 (* ddt density *)
aBar  = 4/3;                                                (* ddt alpha-density *)
gapCct = ddt - aBar;                                        (* 0.0698975 *)

(* {density, label, observedSeedValue} for the orbits the random seeds revealed *)
orbits = {
  {tau,  "twisted  \[Tau]*", 0.376723},
  {16/11, "16/11", 0.4545496},
  {19/13, "19/13", 0.4615426},
  {25/17, "25/17", 0.470592},
  {3/2,  "direct  3/2", 0.500004}
};

(* --- palette (2026-07-14 visual pass: softer tones, round line caps/joins) --- *)
cExtreme = RGBColor[0.20, 0.34, 0.64];   (* twisted / direct: structural extremes *)
cMixed   = RGBColor[0.46, 0.49, 0.56];   (* mixed orbits *)
cOpt     = RGBColor[0.87, 0.58, 0.11];   (* ddt: the true optimum *)
cLine    = RGBColor[0.68, 0.70, 0.75];
ink      = GrayLevel[0.14];

lo = 1.355; hi = 1.512;

(* ============ PANEL A : density spectrum ============ *)
axisY = 0;
tickH = 0.05;
labSlot[i_] := {0.34, 0.60, 0.34, 0.60, 0.34}[[i]];  (* stagger mixed labels *)

panelA = Graphics[{
   (* axis *)
   {ink, CapForm["Round"], JoinForm["Round"], Thickness[0.0042], Line[{{lo, axisY}, {hi, axisY}}]},
   {ink, CapForm["Round"], JoinForm["Round"], Thickness[0.0042], Line[{{hi, axisY}, {hi - 0.006, axisY + 0.012}}],
     Line[{{hi, axisY}, {hi - 0.006, axisY - 0.012}}]},
   (* axis ticks with density values *)
   Table[{GrayLevel[0.58], CapForm["Round"], Line[{{d, axisY - 0.02}, {d, axisY + 0.02}}],
     Text[Style[NumberForm[N[d], {4, 3}], 8, GrayLevel[0.5]], {d, axisY - 0.09}]},
     {d, {1.38, 1.40, 1.42, 1.44, 1.46, 1.48, 1.50}}],
   (* the "crowding zone" brace *)
   {cLine, CapForm["Round"], JoinForm["Round"], Thickness[0.0022],
     Line[{{16/11, 0.16}, {16/11, 0.13}, {25/17, 0.13}, {25/17, 0.16}}]},
   Text[Style["crowding zone (\[CapitalDelta]<0.016)", 8, cLine, Italic], {19/13, 0.19}],
   (* orbit markers + staggered labels *)
   Table[With[{d = orbits[[i, 1]], lab = orbits[[i, 2]],
       col = If[MemberQ[{1, 5}, i], cExtreme, cMixed], sl = labSlot[i]},
     {{col, PointSize[0.015], Point[{d, axisY}]},
      {col, CapForm["Round"], Thickness[0.002], Line[{{d, axisY + 0.03}, {d, sl - 0.03}}]},
      Text[Style[lab, 10, col, Bold], {d, sl}]}],
     {i, Length[orbits]}],
   (* ddt : the true optimum, highlighted *)
   {cOpt, PointSize[0.022], Point[{ddt, axisY}]},
   {cOpt, CapForm["Round"], Thickness[0.0026], Line[{{ddt, axisY - 0.03}, {ddt, -0.14}}]},
   Text[Style["ddt  \[LongDash] true optimum", 10, cOpt, Bold], {ddt, -0.20}],
   Text[Style["(found by the deterministic seeds)", 8, cOpt], {ddt, -0.26}]
   },
  PlotRange -> {{lo, hi}, {-0.30, 0.72}}, AspectRatio -> 0.32, ImageSize -> 760,
  PlotLabel -> Style["A.  Orbit-density spectrum explored by strategy iteration", 12, ink, Bold],
  ImagePadding -> {{10, 10}, {6, 24}}, Background -> White];

(* ============ PANEL B : seed value vs density ============ *)
dRange = {1.355, 1.512};
lineSpur = Line[{{#, # - 1}, {#2, #2 - 1}}] & @@ dRange;   (* value = density - 1 *)
lineGap  = Line[{{#, # - aBar}, {#2, #2 - aBar}}] & @@ dRange; (* value = density - 4/3 *)

panelB = Graphics[{
   (* the two regime lines *)
   {cMixed, CapForm["Round"], JoinForm["Round"], Thickness[0.0036], lineSpur},
   Text[Style["value = density \[Minus] 1", 9, cMixed], {1.358, 0.508}, {-1, 0}],
   Text[Style["(spurious \[LongDash] \[Alpha]-correction off)", 8, cMixed], {1.358, 0.482}, {-1, 0}],
   {cOpt, CapForm["Round"], Dashing[{0.012, 0.010}], Thickness[0.0036], lineGap},
   Text[Style["value = density \[Minus] 4/3  (true gap)", 9, cOpt], {1.508, 0.108}, {1, 0}],
   (* spurious orbit points on the density-1 line *)
   Table[With[{d = N[orbits[[i, 1]]], v = orbits[[i, 3]],
       col = If[MemberQ[{1, 5}, i], cExtreme, cMixed]},
     {{col, PointSize[0.014], Point[{d, v}]},
      Text[Style[orbits[[i, 2]], 8, col], {d, v + 0.028}]}],
     {i, Length[orbits]}],
   (* ddt on the real-gap line + the drop arrow *)
   {cOpt, PointSize[0.022], Point[{ddt, gapCct}]},
   Text[Style["ddt", 9, cOpt, Bold], {ddt + 0.006, gapCct + 0.028}],
   {GrayLevel[0.6], CapForm["Round"], Dashing[{0.006, 0.006}], Arrowheads[0.02],
     Arrow[{{ddt, ddt - 1}, {ddt, gapCct + 0.01}}]},
   Text[Style["\[Alpha]-cocycle\ndevelops", 8, GrayLevel[0.45], Italic],
     {ddt - 0.028, (ddt - 1 + gapCct)/2}]
   },
  PlotRange -> {dRange, {-0.02, 0.56}}, AspectRatio -> 0.5, ImageSize -> 760,
  Frame -> {{True, False}, {True, False}}, FrameStyle -> GrayLevel[0.55],
  FrameLabel -> {Style["orbit \[Theta]-density", 10, ink],
     Style["reported seed value", 10, ink]},
  FrameTicks -> {{Automatic, None}, {Automatic, None}},
  PlotLabel -> Style["B.  Why the optimum is special: the \[Alpha]-correction drops ddt off the density\[Minus]1 line", 12, ink, Bold],
  ImagePadding -> {{55, 12}, {40, 24}}, Background -> White];

fig = Column[{panelA, panelB}, Spacings -> 1.2, Alignment -> Center];

Export["orbit_spectrum.png", fig, ImageResolution -> 200];
Export["orbit_spectrum.pdf", fig];
Print["WROTE orbit_spectrum.png (", FileByteCount["orbit_spectrum.png"], " bytes) and .pdf"];
Print["tau* = ", tau, "  |  ddt = ", ddt, "  |  gap(ddt) = ", gapCct];
Print["check: 16/11-1=", N[16/11 - 1], " vs obs 0.4545496 ; 25/17-1=", N[25/17 - 1], " vs obs 0.470592"];
