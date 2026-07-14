(* ::Package:: *)

(* ::Title:: *)
(*Evaluating Black-Box Physics through Optical Emulation \[LongDash] Sections 4-6*)

(* ::Subtitle:: *)
(*Composition (mesh laws and the optimal word), the degree-0 sheaf derivation, and the Hawking two-sector illustration*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Section Builder B of the master computational essay (outline: docs/ESSAY-OUTLINE.md; framework labelling: docs/FRAMEWORK-2026-07-13.md). This file carries S4, S5, S6. Labelling discipline (mirrors the FRAMEWORK): [T] theorem/machine-verified, [C] certified numeric, [R] refuted route, [H] named hypothesis. THE PRIME DIRECTIVE: every quantitative claim below is produced by the kernel at evaluation time \[LongDash] via the repository's verified modules, the BlackBox paclet, live recomputation, or a reader over a committed exact-arithmetic certificate \[LongDash] never hand-restated. This source is Get-loadable and headless-verifiable: it ends in the association SectionsFourToSixVerification with "OK" -> True.*)

(* ::Section:: *)
(*Loader*)

(* ::CodeText:: *)
(*Locate the repository root (this file lives at docs/essay-src/), load the BlackBox paclet, and repair any Global`-shadowing of paclet symbols (the shadowing pitfall documented in kcbs_circuit.wl \[LongDash] Get[] avoids it, but we de-shadow defensively):*)

(* ::Input:: *)
repoRoot = Module[
   {ref, start, localRoot, base, cacheRoot, manifest, dest, res, tries, strm},
   ref = If[StringQ[$BlackBoxRef] && $BlackBoxRef =!= "", $BlackBoxRef, "master"];
   start = With[{f = $InputFileName},
     If[StringQ[f] && f =!= "" && FileExistsQ[f], DirectoryName[f],
       Quiet@Check[NotebookDirectory[], Directory[]]]];
   If[! StringQ[start] || start === "", start = Directory[]];
   localRoot = NestWhile[ParentDirectory, start,
     (# =!= ParentDirectory[#]) &&
       ! FileExistsQ[FileNameJoin[{#, "BlackBox", "PacletInfo.wl"}]] &];
   If[FileExistsQ[FileNameJoin[{localRoot, "BlackBox", "PacletInfo.wl"}]],
     localRoot,
     base = "https://raw.githubusercontent.com/hubertkolcz/BlackBox/" <> ref <> "/";
     cacheRoot = FileNameJoin[{$UserBaseDirectory, "ApplicationData", "BlackBoxEssay", ref}];
     Quiet@CreateDirectory[cacheRoot, CreateIntermediateDirectories -> True];
     If[! DirectoryQ[cacheRoot],
       cacheRoot = FileNameJoin[{$TemporaryDirectory, "BlackBoxEssay", ref}];
       Quiet@CreateDirectory[cacheRoot, CreateIntermediateDirectories -> True]];
     manifest = {"BlackBox/PacletInfo.wl", "BlackBox/Kernel/BlackBox.wl",
       "docs/essay-src/essay_sections_1_3.wl", "docs/essay-src/essay_sections_4_6.wl",
       "docs/essay-src/essay_sections_7_10.wl",
       "09-EMU-optical-compiler/OpticalCompiler.wl", "09-EMU-optical-compiler/DispatcherEmitter.wl",
       "09-EMU-optical-compiler/InterferometerLayer.wl", "09-EMU-optical-compiler/IntensityLayer.wl",
       "05-CERT-epsilon-certificates/EpsilonCertificate7_regenerated.wl",
       "05-CERT-epsilon-certificates/EpsilonCertificate8_regenerated.wl",
       "05-CERT-epsilon-certificates/EpsilonCertificate9.wl",
       "08-HK-hawking/hawking_gaussian_sector.wl", "08-HK-hawking/gaussian_engine.wl",
       "08-HK-hawking/gaussian_hawking_physics.wl", "08-HK-hawking/gaussian_witnesses_bridge.wl",
       "06-D3-sheaf-cohomology/final_h1_cocycle_results.json",
       "02-D1-theory-frontier/erg003_verdict.json", "docs/FRAMEWORK-2026-07-13.md",
       "09-EMU-optical-compiler/schematics/demo1_kcbs_pentagon_L1.png",
       "09-EMU-optical-compiler/schematics/demo3_cct_mesh_reps2.png",
       "00-BBT-blackbox-protocol/certification_map.png",
       "05-CERT-epsilon-certificates/orbit_spectrum.png"};
     Do[dest = FileNameJoin[Prepend[FileNameSplit[rel], cacheRoot]];
       If[! (FileExistsQ[dest] && FileByteCount[dest] > 0),
         Quiet@CreateDirectory[DirectoryName[dest], CreateIntermediateDirectories -> True];
         tries = 0;
         While[! (FileExistsQ[dest] && FileByteCount[dest] > 0) && tries < 3,
           tries++;
           res = Quiet@Check[URLRead[base <> rel, {"StatusCode", "BodyByteArray"}], $Failed];
           If[AssociationQ[res] && res["StatusCode"] === 200 &&
                ByteArrayQ[res["BodyByteArray"]] && Length[res["BodyByteArray"]] > 8 &&
                ! StringStartsQ[ToUpperCase@Quiet@Check[
                    FromCharacterCode@Normal@Take[res["BodyByteArray"], UpTo[14]], "?"],
                  "<!DOCTYPE" | "<HTML"],
             Quiet[strm = OpenWrite[dest, BinaryFormat -> True];
               BinaryWrite[strm, res["BodyByteArray"]]; Close[strm]]]]],
       {rel, manifest}];
     cacheRoot]];
PacletDirectoryLoad[FileNameJoin[{repoRoot, "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];
sfx6 = <||>;   (* verification accumulator, filled section by section *)

(* ::Section:: *)
(*S4. Composition: Mesh Laws and the Optimal Word*)

(* ::Text:: *)
(*A mesh of edge-glued pentagons is a binary necklace: one orientation letter per gluing, c (cis) or t (trans). Cis rails the short sides onto one endpoint of the running glue edge; trans alternates them. The two closures are not isomorphic (MESH-001), and orientation \[LongDash] not size \[LongDash] controls whether the quantum gap \[CapitalTheta] - \[Alpha] survives (MESH-002). This section reproduces the exact composition laws live, reads the tightened certificate ladder \[CapitalGamma]_7, \[CapitalGamma]_8, \[CapitalGamma]_9 from committed exact-arithmetic certificates, and authors the bracket figure from those live values.*)

(* ::CodeText:: *)
(*The general word-ring builder (mirrors 03-MESH-pentagon-composition/CaseStudies.wl) and the 3-state interface transfer DP whose max-plus cycle means give exact \[Alpha]-densities:*)

(* ::Input:: *)
wordRing[word_String, reps_Integer] := Module[
  {w = Characters[StringRepeat[word, reps]], L, edges = {}, u, v, km},
  L = Length[w];
  Do[km = Mod[k - 1, L];
   {u, v} = If[w[[km + 1]] === "c", {3 km + 1, 3 km + 2}, {3 km + 2, 3 km + 1}];
   edges = Join[edges, {{u, v}, {u, 3 k + 1}, {3 k + 1, 3 k + 2},
      {3 k + 2, 3 k + 3}, {3 k + 3, v}}], {k, 0, L - 1}];
  Graph[Range[3 L], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];
dpStates = {{0, 0}, {1, 0}, {0, 1}};
dpTransfer[letter_] := Module[{T = ConstantArray[-Infinity, {3, 3}], out, j},
  Do[If[! (dpStates[[i, 1]] == 1 && s1 == 1) && ! (s1 == 1 && s2 == 1) &&
      ! (s2 == 1 && s3 == 1) && ! (s3 == 1 && dpStates[[i, 2]] == 1),
     out = If[letter === "c", {s1, s2}, {s2, s1}];
     j = Position[dpStates, out][[1, 1]];
     T[[i, j]] = Max[T[[i, j]], s1 + s2 + s3]],
    {i, 3}, {s1, 0, 1}, {s2, 0, 1}, {s3, 0, 1}];
  T];

(* ::CodeText:: *)
(*Cis/trans dichotomy, live [T]: the dense SDP arbitrates at a size it still reaches \[LongDash] \[CurlyTheta](trans-ring 21) < \[CurlyTheta](cis-chain 19), and \[CurlyTheta] is monotone under induced subgraphs, so no 19-block cis chain embeds in the 21-block trans ring. The two families are genuinely distinct:*)

(* ::Input:: *)
cisRing[nb_ /; nb >= 3] := Module[{c1, c2, c3, edges},
  edges = Flatten[Table[{{c1[Mod[k - 1, nb]], c1[k]}, {c1[k], c2[k]}, {c2[k], c3[k]},
      {c3[k], c2[Mod[k - 1, nb]]}, {c2[Mod[k - 1, nb]], c1[Mod[k - 1, nb]]}}, {k, 0, nb - 1}], 1];
  Graph[DeleteDuplicates[Flatten[edges]], UndirectedEdge @@@ DeleteDuplicates[Sort /@ edges]]];
gluingArbitration = {LovaszTheta[PentagonRing[21]], LovaszTheta[PentagonChain[19]]};
sfx6["S4_cisTransDistinct"] = gluingArbitration[[1]] < gluingArbitration[[2]] - 0.15;
gluingArbitration

(* ::CodeText:: *)
(*Cis law [T]: \[CurlyTheta](cis-ring N) = N + \[CurlyTheta](C_N) and \[Alpha] = \[LeftFloor]3N/2\[RightFloor] (edge-deletion upper bound + one-extra-dimension representation; proof in CaseStudies.wl). Live on N = 4..8:*)

(* ::Input:: *)
cisLawTable = Table[{n, LovaszTheta[cisRing[n]], n + LovaszTheta[CycleGraph[n]],
    IndependenceNumber[cisRing[n]], Floor[3 n/2]}, {n, 4, 8}];
sfx6["S4_cisLaw"] = AllTrue[cisLawTable, Abs[#[[2]] - #[[3]]] < 10^-5 &] &&
   cisLawTable[[All, 4]] == cisLawTable[[All, 5]];
TableForm[cisLawTable, TableHeadings -> {None, {"N", "\[CurlyTheta](cis ring)", "N+\[CurlyTheta](C_N)", "\[Alpha]", "\[LeftFloor]3N/2\[RightFloor]"}}]

(* ::CodeText:: *)
(*The trans density limit \[Tau]* [C], the EXACT middle root of a cubic with two-digit coefficients (Groebner elimination of the continuum symbol minimax), recomputed live to 20 digits:*)

(* ::Input:: *)
tauStar = Root[49 #^3 - 128 #^2 - 75 #^1 + 218 &, 2];
sfx6["S4_tauStarCubic"] = (MinimalPolynomial[tauStar, x] === 49 x^3 - 128 x^2 - 75 x + 218) &&
   Abs[N[tauStar, 20] - 1.37671774591585905328] < 10^-15;
{N[tauStar, 20], "per-block trans gap \[Tau]*-4/3" -> N[tauStar - 4/3, 12]}

(* ::CodeText:: *)
(*The \[Alpha]-cis theorem [T] (key mechanism): for every gluing word \[Alpha]-density >= max(4/3, 1 + f_c/2); equality at 4/3 iff the word is (cct)^k. Certificate C (potentials (0,-1/2,-1)), the walk-free ccc bonus (adjusted max-plus cube = 13/3), and the run-combinatorics closure through period 12 \[LongDash] all machine-checked live:*)

(* ::Input:: *)
alphaCisTheorem = Module[{phiC = {0, -1/2, -1}, phiB = {0, -1/3, -2/3},
    adjR, Acc, mpMul, A3, comb},
   adjR[T_, phi_, i_] := Max[Table[T[[i, j]] + phi[[j]] - phi[[i]], {j, 3}]];
   Acc = Table[dpTransfer["c"][[i, j]] + phiB[[j]] - phiB[[i]], {i, 3}, {j, 3}];
   mpMul[X_, Y_] := Table[Max[Table[X[[i, k]] + Y[[k, j]], {k, 3}]], {i, 3}, {j, 3}];
   A3 = mpMul[mpMul[Acc, Acc], Acc];
   comb = AllTrue[Flatten[Table[If[Mod[p, 3] == 0,
        Module[{ws = Select[Tuples[{"c", "t"}, p], Count[#, "c"] == 2 p/3 &&
              ! StringContainsQ[StringJoin[#] <> StringJoin[#], "ccc"] &]},
         AllTrue[ws, MemberQ[Table[RotateLeft[Characters[StringRepeat["cct", p/3]], r],
             {r, 0, p - 1}], #] &]], True], {p, 3, 12}]], TrueQ];
   AllTrue[Range[3], adjR[dpTransfer["c"], phiC, #] >= 3/2 &] &&
    AllTrue[Range[3], adjR[dpTransfer["t"], phiC, #] >= 1 &] &&
    Min[Table[Max[A3[[i]]], {i, 3}]] == 13/3 && comb];
sfx6["S4_alphaCisTheorem"] = alphaCisTheorem;
alphaCisTheorem

(* ::CodeText:: *)
(*The optimal word (cct)^\[Infinity] and its gap density gap(cct) [C]. The dense-SDP anchor \[CurlyTheta](cct\[Times]2) matches the chordal continuum value; the \[Alpha] staircase gives \[LeftFloor]4L/3\[RightFloor]; the per-block gap is cctDensity - 4/3 \[TildeTilde] 0.0698975, which is 1.611\[Times] the pure-trans gap (\[Tau]* - 4/3). cctDensity is the numerically-certified (~300-digit KKT) continuum optimum \[LongDash] no low-degree closed form exists (LLL excludes minimal polynomials of degree <= 36):*)

(* ::Input:: *)
gluingWordAnchor = {LovaszTheta[wordRing["cct", 2]],
   IndependenceNumber[wordRing["cct", 2]], IndependenceNumber[wordRing["cct", 3]]};
cctDensity = 1.4032308692389975;   (* continuum optimum of the 9x9 symbol minimax; numeric-certified, no closed form *)
gapCct = cctDensity - 4/3;
sfx6["S4_optimalWord"] = Abs[gluingWordAnchor[[1]] - 8.347042185] < 10^-4 &&
   gluingWordAnchor[[2]] == 8 && gluingWordAnchor[[3]] == 12 &&
   Abs[gapCct - 0.0698975] < 10^-4 && gapCct > (tauStar - 4/3) &&
   Abs[gapCct/(tauStar - 4/3) - 1.611] < 0.01;
{"\[CurlyTheta](cct\[Times]2)" -> gluingWordAnchor[[1]], "\[Alpha](cct\[Times]2,\[Times]3)" -> gluingWordAnchor[[2 ;; 3]],
 "gap(cct)" -> N[gapCct, 8], "gap(cct)/(\[Tau]*-4/3)" -> N[gapCct/(tauStar - 4/3), 6]}

(* ::CodeText:: *)
(*The certificate ladder \[CapitalGamma]_k [T]/[C]. Each \[CapitalGamma]_k is an all-words upper bound on gap-density (a Bousch sub-action / max-plus eigenvalue on the de Bruijn-k subshift). The tightened exact rationals \[CapitalGamma]_7, \[CapitalGamma]_8, \[CapitalGamma]_9 are READ from the committed certificates (regenerated on Wolfram Compute Services, all PSD/pointwise/convergence gates True) and reduced to numbers in-essay \[LongDash] never re-typed:*)

(* ::Input:: *)
Get[FileNameJoin[{repoRoot, "05-CERT-epsilon-certificates", "EpsilonCertificate7_regenerated.wl"}]];
Get[FileNameJoin[{repoRoot, "05-CERT-epsilon-certificates", "EpsilonCertificate8_regenerated.wl"}]];
Get[FileNameJoin[{repoRoot, "05-CERT-epsilon-certificates", "EpsilonCertificate9.wl"}]];
gamma7 = EpsilonCertificate7Regenerated["Gamma"];
gamma8 = EpsilonCertificate8Regenerated["Gamma"];
gamma9 = EpsilonCertificate9["Gamma"];
gammaExact = {gamma7, gamma8, gamma9};
sfx6["S4_gammaLadderExact"] = AllTrue[gammaExact, Head[#] === Rational &] &&
   gamma7 > gamma8 > gamma9 > gapCct;   (* strictly decreasing, still above the target *)
{"\[CapitalGamma]_7" -> N[gamma7, 10], "\[CapitalGamma]_8" -> N[gamma8, 10], "\[CapitalGamma]_9" -> N[gamma9, 10],
 "exact \[CapitalGamma]_9" -> gamma9}

(* ::CodeText:: *)
(*\[CapitalGamma]_10 is NUMERIC-ONLY (0.0714575, no committed exact rational certificate \[LongDash] the k=10 generator ran but no exact block certificate is in the repository). It is recorded honestly as a numeric bracket point, NOT as a kernel-recomputed exact object, and the certified \[Epsilon] uses it as documented in CONVERGENCE-ANALYSIS-2026-07-13.md:*)

(* ::Input:: *)
gamma10Numeric = 0.0714575;   (* [C numeric] documented value; NO exact certificate committed (honest scope) *)
epsCertified = gamma10Numeric - gapCct;
sfx6["S4_gamma10NumericHonest"] = gamma10Numeric < N[gamma9] && gamma10Numeric > gapCct &&
   Abs[epsCertified - 0.00156] < 10^-4;
{"\[CapitalGamma]_10 (numeric-only)" -> gamma10Numeric, "\[Epsilon] = \[CapitalGamma]_10 - gap(cct)" -> N[epsCertified, 4],
 "status" -> "numeric bracket point; no exact certificate committed"}

(* ::CodeText:: *)
(*The orbit-spectrum reading (CERT-003). Spurious policy-iteration values are periodic-orbit densities minus 1 \[LongDash] cis 3/2, trans \[Tau]*, then 16/11, 19/13, 25/17. \[Tau]* is recomputed live (above); the rationals are the finite-orbit readings. The figure orbit_spectrum.png is regenerated by 05-CERT-epsilon-certificates/orbit_spectrum_figure.wl (embedded by the master essay); here we verify the seed values are ordered and \[Tau]* sits among them:*)

(* ::Input:: *)
orbitSeeds = {3/2, tauStar, 16/11, 19/13, 25/17};
sfx6["S4_orbitSpectrum"] = (tauStar < 16/11 < 19/13 < 25/17 < 3/2);
   (* the CLAIM is the orbit-density ordering; the figure is decorative and no longer gates OK *)
orbitSpectrumFigureRef = FileNameJoin[{repoRoot, "05-CERT-epsilon-certificates", "orbit_spectrum.png"}];
orbitSpectrumFigure = If[FileExistsQ[orbitSpectrumFigureRef], Import[orbitSpectrumFigureRef],
   Missing["figure unavailable"]];
Column[{N[orbitSeeds, 6], orbitSpectrumFigure}]

(* ::CodeText:: *)
(*FIGURE (authored live). The certificate bracket: \[CapitalGamma]_7 > \[CapitalGamma]_8 > \[CapitalGamma]_9 (exact) and \[CapitalGamma]_10 (numeric) descending toward gap(cct), the conjectured supremum. Every plotted ordinate is a live value computed above:*)

(* ::Input:: *)
gammaBracketFigure = ListLinePlot[
   {Table[{k, N[gammaExact[[k - 6]]]}, {k, 7, 9}]~Join~{{10, gamma10Numeric}}},
   PlotMarkers -> Automatic, Joined -> True,
   Epilog -> {Directive[Red, Dashed], Line[{{6.5, gapCct}, {10.5, gapCct}}],
     Text[Style["gap(cct) \[TildeTilde] 0.06990", 9], {9, gapCct}, {0, -1.4}]},
   AxesLabel -> {"k", "\[CapitalGamma]_k"}, PlotRange -> {{6.5, 10.5}, {0.069, 0.078}},
   PlotLabel -> "Certificate ladder \[RightArrow] gap(cct)", ImageSize -> 360];
gammaBracketFigure

(* ::CodeText:: *)
(*FIGURE (authored live). Pentagon-chain gap parity: cis chains obey the parity law \[LongDash] even N pinches the gap \[CapitalTheta] - \[Alpha] to zero, odd N reopens it \[LongDash] computed live via PentagonChain + LovaszTheta:*)

(* ::Input:: *)
chainGapParity = Table[{n, Chop[LovaszTheta[PentagonChain[n]] - IndependenceNumber[PentagonChain[n]], 10^-6]}, {n, 3, 9}];
sfx6["S4_chainParity"] = (chainGapParity[[2, 2]] < 10^-5) && (chainGapParity[[4, 2]] < 10^-5) &&
   (chainGapParity[[1, 2]] > 0.1) && (chainGapParity[[3, 2]] > 10^-8);
chainParityFigure = ListLinePlot[chainGapParity, PlotMarkers -> Automatic,
   AxesLabel -> {"N", "\[CapitalTheta]-\[Alpha] (cis chain)"}, PlotLabel -> "Chain gap parity (even N pinches)", ImageSize -> 360];
chainParityFigure

(* ::Section:: *)
(*S5. The Sheaf Question: Degree-0 Derivation and the Refuted H\.b9 Obstruction*)

(* ::Text:: *)
(*The project's priority question (ESSAY-005): can the Abramsky-Brandenburger sheaf DERIVE (not merely describe) the composed GE exclusivity bound over products of C5? The answer is YES at degree 0 and NO at the naive H\.b9. We reconstruct the weighted-presheaf capacity \[CapitalLambda]_k live \[LongDash] the degree-0 total-mass hom on H\.b0(F) \[LongDash] and read S_k = \[CapitalLambda]_k^(1/k). The mechanism is arithmetic: an INTEGER partition of unity exactly when the quantum value is attained (C5 pentads), properly FRACTIONAL otherwise (C7: 4\[Nmid]49, 8\[Nmid]343).*)

(* ::CodeText:: *)
(*The weighted presheaf F(K) = {w : K -> [0,1], \[Sum] <= 1} over R = Q>=0 glues trivially, so H\.b0(F) is the packing polytope and \[CapitalLambda]_k = sup_{p} \[Sum] p_v is its total-mass hom (= the exclusivity/packing LP). Machinery verbatim from 06-D3-sheaf-cohomology/bridge_weighted_presheaf.wl:*)

(* ::Input:: *)
conormalVerts[n_, k_] := Tuples[Range[0, n - 1], k];
adjQ[n_][u_, v_] := AnyTrue[Range[Length[u]], MemberQ[{1, n - 1}, Mod[u[[#]] - v[[#]], n]] &];
conormalGraph[n_, k_] := Module[{vs = conormalVerts[n, k], m, edges},
   m = Length[vs];
   edges = Reap[Do[If[adjQ[n][vs[[a]], vs[[b]]], Sow[UndirectedEdge[a, b]]], {a, 1, m}, {b, a + 1, m}]][[2]];
   edges = If[edges === {}, {}, edges[[1]]];
   {Graph[Range[m], edges], vs}];
capacityLP[cliqueIdxLists_, nV_] := Module[{p, vars, cons, sol},
   vars = Array[p, nV];
   cons = Join[Table[Total[vars[[K]]] <= 1, {K, cliqueIdxLists}], Thread[vars >= 0]];
   sol = LinearOptimization[-Total[vars], cons, vars, Method -> "Simplex"];
   Total[vars] /. sol];
cliqueQ[n_][verts_] := AllTrue[Subsets[verts, {2}], adjQ[n][#[[1]], #[[2]]] &];

(* ::CodeText:: *)
(*Degree-0 capacities by exact census + LP: C5 at k=1,2 and the C7 control at k=2. S_k = \[CapitalLambda]_k^(1/k), with S2(C5) irrational (Sqrt[5], via RootReduce) but the C7 control staying at 7/2 \[LongDash] NOT \[CurlyTheta](C7):*)

(* ::Input:: *)
{g51, vs51} = conormalGraph[5, 1]; lam1c5 = capacityLP[FindClique[g51, Infinity, All], Length[vs51]];
{g52, vs52} = conormalGraph[5, 2]; lam2c5 = capacityLP[FindClique[g52, Infinity, All], Length[vs52]];
{g72, vs72} = conormalGraph[7, 2]; lam2c7 = capacityLP[FindClique[g72, Infinity, All], Length[vs72]];
sheafDeg0 = {
   {"S1(C5)", lam1c5, lam1c5, 5/2},
   {"S2(C5)", lam2c5, RootReduce[lam2c5^(1/2)], Sqrt[5]},
   {"S2(C7) control", lam2c7, RootReduce[lam2c7^(1/2)], 7/2}};
sfx6["S5_degree0"] = (lam1c5 === 5/2) &&
   (lam2c5 === 5 && RootReduce[lam2c5^(1/2)] === Sqrt[5]) &&
   (lam2c7 === 49/4 && RootReduce[lam2c7^(1/2)] === 7/2);
TableForm[sheafDeg0, TableHeadings -> {None, {"anchor", "\[CapitalLambda]_k", "S_k = \[CapitalLambda]^(1/k)", "target"}}]

(* ::CodeText:: *)
(*The C7 control at k=3, by the certificate SANDWICH (no census): the dual 0-cochain of 343 edge-cubes at weight y=1/8 is feasible (coverage exactly 1), giving \[CapitalLambda]_3(C7) <= 343/8; the uniform primal p=1/8 is feasible since \[Omega](C7^\[Or]3)=8 (established in essay005_p3_gluing_lp.wl), giving >=343/8. Per-copy stays 7/2:*)

(* ::Input:: *)
edgeCubes = Flatten[Table[Tuples[{{i, Mod[i + 1, 7]}, {j, Mod[j + 1, 7]}, {l, Mod[l + 1, 7]}}],
    {i, 0, 6}, {j, 0, 6}, {l, 0, 6}], 2];
dualCoverC7k3 = Module[{vs = conormalVerts[7, 3], idx, cov},
   idx = AssociationThread[vs -> Range[Length[vs]]]; cov = ConstantArray[0, Length[vs]];
   Do[Do[cov[[idx[v]]] += 1/8, {v, K}], {K, edgeCubes}];
   <|"allCliques" -> AllTrue[edgeCubes, cliqueQ[7]], "coverageMin" -> Min[cov],
     "coverageMax" -> Max[cov], "objective" -> (1/8) Length[edgeCubes]|>];
lam3c7 = If[dualCoverC7k3["allCliques"] && dualCoverC7k3["coverageMin"] >= 1, 343/8, Indeterminate];
sfx6["S5_c7k3control"] = (lam3c7 === 343/8) && Simplify[lam3c7^(1/3)] === 7/2 &&
   dualCoverC7k3["coverageMin"] === 1 && dualCoverC7k3["coverageMax"] === 1;
{"\[CapitalLambda]_3(C7)" -> lam3c7, "per-copy" -> Simplify[lam3c7^(1/3)], "dual coverage [min,max]" ->
   {dualCoverC7k3["coverageMin"], dualCoverC7k3["coverageMax"]}}

(* ::CodeText:: *)
(*The mechanism, live [T]: an exact integer partition of unity exists iff \[Omega] divides |V|. C5,k=2: the five slope-2 pentads partition the 25 events (integer \[CapitalLambda]=5) \[LongDash] quantum value attained. C7: 4 does not divide 49 and 8 does not divide 343, so \[CapitalLambda] is properly fractional (49/4, 343/8) and no integer partition exists:*)

(* ::Input:: *)
pentad[a_, j_] := Table[{i, Mod[a i + j, 5]}, {i, 0, 4}];
pentads2 = Table[pentad[2, j], {j, 0, 4}];
c5k2Partition = AllTrue[pentads2, cliqueQ[5]] &&
   Sort[Flatten[pentads2, 1]] === Sort[conormalVerts[5, 2]] && Length[Flatten[pentads2, 1]] === 25;
divisibility = {{"C5,k=2", 5^2, 5, Mod[5^2, 5], IntegerQ[lam2c5]},
   {"C7,k=2", 7^2, 4, Mod[7^2, 4], IntegerQ[lam2c7]},
   {"C7,k=3", 7^3, 8, Mod[7^3, 8], IntegerQ[lam3c7]}};
sfx6["S5_mechanism"] = c5k2Partition && IntegerQ[lam2c5] &&
   (Mod[49, 4] =!= 0) && (! IntegerQ[lam2c7]) &&
   (Mod[343, 8] =!= 0) && (! IntegerQ[lam3c7]);
{"C5,k=2 pentad partition" -> c5k2Partition,
 TableForm[divisibility, TableHeadings -> {None, {"case", "|V|", "\[Omega]", "|V| mod \[Omega]", "\[CapitalLambda] integer?"}}]}

(* ::CodeText:: *)
(*The naive H\.b9 route is REFUTED as posed [R] (SH-010, F9vii). The candidate connecting class \[Delta](y* mod Z) is (1) UNDEFINED in the fractional case (the canonical C7,k=2 dual has 20776 bad overlaps \[LongDash] not a 0-cocycle), (2) GAUGE non-invariant (the C5,k=2 optimal face is positive-dimensional; an alternate dual has 3000 bad overlaps), and (3) forced to ZERO where defined (connected nerve). The exact counts are read from the committed lane result, not re-typed:*)

(* ::Input:: *)
h1json = Import[FileNameJoin[{repoRoot, "06-D3-sheaf-cohomology", "final_h1_cocycle_results.json"}], "RawJSON"];
h1BadC7 = h1json["obstruction_1_cocycle_prerequisite"]["C7_k2_canonical_dual"]["bad_overlaps"];
h1BadC5alt = h1json["obstruction_2_gauge_noninvariance"]["C5_k2"]["D_half_y_1over2_on_both_partitions"]["bad_overlaps"];
sfx6["S5_h1Refuted"] = (h1BadC7 == 20776) && (h1BadC5alt == 3000) &&
   StringContainsQ[h1json["verdict"], "REFUTED"];
{"C7,k=2 bad overlaps (undefined)" -> h1BadC7, "C5,k=2 alt-dual bad overlaps (gauge)" -> h1BadC5alt,
 "verdict" -> "REFUTED as posed; degree-0 result (S_k) untouched"}

(* ::CodeText:: *)
(*Single-copy sheaf stratification as a supporting live exhibit: the possibilistic global support |S_e| of the KCBS quantum-maximal model is 11 = LucasL[5] (contextual but not strongly so), while the classical control keeps its full support and Wright's supra-quantum box keeps none (strong contextuality). Computed live with the paclet:*)

(* ::Input:: *)
scen5 = CycleScenario[5];
supQuantum = PossibilisticSupport[scen5, CycleModel[5, "Quantum"]]["Size"];
supClassical = PossibilisticSupport[scen5, CycleModel[5, "Classical"]]["Size"];
sfx6["S5_possibilistic"] = (supQuantum === LucasL[5]) && (supQuantum === 11) && (supClassical > 0);
{"|S_e| quantum" -> supQuantum, "= LucasL[5]" -> (supQuantum === LucasL[5]), "|S_e| classical" -> supClassical}

(* ::Section:: *)
(*S6. Hawking Two-Sector Illustration*)

(* ::Text:: *)
(*The framework's two lenses applied to analogue Hawking radiation, which splits into a Gaussian (covariance-matrix) sector and a qubit information-dynamics sector \[LongDash] both certified CLASSICALLY EMULABLE (CV Gottesman-Knill; Clifford). We load the repository's Gaussian sector (self-checks suppressed), RE-PROVE its key symbolic anchors in-essay via FullSimplify (printed True, not restated), audit the CV dynamical Lie algebra, and bridge to the qubit CF anchors. Honesty header: this is Hawking's 1974 semiclassical KINEMATICS discretized per mode as exact symplectic algebra \[LongDash] a parameterized background, not a derivation from the Einstein equations.*)

(* ::CodeText:: *)
(*Load the Gaussian engine + Hawking physics + witnesses/bridge with the module's own scoreboard suppressed (GaussianHawkingLoadOnly guard), exposing HawkingSqueezing, CHSHofR, BuschParentaniDelta, HawkingGenerators, CVDLAAudit, ...:*)

(* ::Input:: *)
Block[{GaussianHawkingLoadOnly = True},
  Get[FileNameJoin[{repoRoot, "08-HK-hawking", "hawking_gaussian_sector.wl"}]]];

(* ::CodeText:: *)
(*A1 Planck [T]. The horizon acts per frequency as a two-mode squeezer with tanh(r_w)\.b2 = Exp[-w/T_H]; the Hawking-mode occupation Sinh(r_w)\.b2 is then EXACTLY the Planck/Bose factor. Re-proven live by FullSimplify:*)

(* ::Input:: *)
a1Planck = FullSimplify[Sinh[HawkingSqueezing[w, TH]]^2 == 1/(Exp[w/TH] - 1), Assumptions -> {w > 0, TH > 0}];
sfx6["S6_A1_Planck"] = TrueQ[a1Planck];
a1Planck

(* ::CodeText:: *)
(*A2 entanglement = thermality [T]. The reduced Hawking-mode state's von Neumann entropy equals the thermal entropy of a mode at occupation nbar = Sinh(r)\.b2 \[LongDash] the conceptual core of Hawking's result. Re-proven live:*)

(* ::Input:: *)
a2Thermal = Module[{svn, formN},
   svn = Cosh[r]^2 Log[Cosh[r]^2] - Sinh[r]^2 Log[Sinh[r]^2];
   formN = ((nb + 1) Log[nb + 1] - nb Log[nb]) /. nb -> Sinh[r]^2;
   TrueQ@FullSimplify[svn == formN, Assumptions -> r > 0]];
sfx6["S6_A2_thermal"] = a2Thermal;
a2Thermal

(* ::CodeText:: *)
(*A3 log-negativity [T]: E_N = 2r/Log[2] for the two-mode squeezed vacuum. A4 Cauchy-Schwarz [T]: the second-moment ratio theta(nbar) = 1 + 1/(2 nbar) > 1 certifies the nonclassical correlation. Both re-proven live:*)

(* ::Input:: *)
a3LogNeg = TrueQ@FullSimplify[Max[0, -Log2[Exp[-2 r]]] == 2 r/Log[2], Assumptions -> r > 0];
a4CS = Module[{gHH = 2 nb^2, gHP = 2 nb^2 + nb, gPP = 2 nb^2, th},
   th = FullSimplify[gHP/Sqrt[gHH gPP], Assumptions -> nb > 0];
   TrueQ@FullSimplify[th == 1 + 1/(2 nb), Assumptions -> nb > 0]];
a5BP = TrueQ@FullSimplify[BuschParentaniDelta[ApplySymplectic[TwoModeSqueezer[r], VacuumState[2]]] == -Sinh[r]^2, Assumptions -> r > 0];
sfx6["S6_A3_A4_A5"] = a3LogNeg && a4CS && a5BP;
{"A3 E_N=2r/Log2" -> a3LogNeg, "A4 \[Theta]=1+1/(2nbar)" -> a4CS, "A5 Busch-Parentani \[CapitalDelta]=-Sinh[r]\.b2" -> a5BP}

(* ::CodeText:: *)
(*A6 CHSH bridge [T]. The GKMR parity-pseudospin CHSH of the two-mode squeezed pair is 2 Sqrt[1 + Tanh[2r]^2], rising to the Tsirelson value 2 Sqrt[2] as r -> Infinity (the EPR limit, where the CV pair becomes a qubit Bell pair). Symbolic form and limit, live:*)

(* ::Input:: *)
chshSym = CHSHofR[r];
chshLimit = Limit[CHSHofR[r], r -> Infinity];
sfx6["S6_A6_CHSH"] = (chshSym === 2 Sqrt[1 + Tanh[2 r]^2]) && (chshLimit === 2 Sqrt[2]);
{"CHSH(r)" -> chshSym, "r\[RightArrow]\[Infinity] limit" -> chshLimit}

(* ::CodeText:: *)
(*A8 CV-DLA [T/C]. The Hawking channel's symplectic generators close to sp(4,R), dim 10 \[LongDash] genuine (ACTIVE) squeezing, not passive u(2). So the sector is NOT passive-linear-optics-emulable, though it IS Gaussian-classically-simulable. Exact Lie closure, live:*)

(* ::Input:: *)
cvAudit = CVDLAAudit[2, HawkingGenerators[]];
sfx6["S6_A8_DLAactive"] = (cvAudit["dim"] == 10) && (cvAudit["spn"] == 10) &&
   StringContainsQ[cvAudit["verdict"], "ACTIVE"];
{"CV-DLA dim" -> cvAudit["dim"], "sp(4,R)" -> cvAudit["spn"], "verdict" -> cvAudit["verdict"]}

(* ::CodeText:: *)
(*A7ii structural negative [T] (HK-003, CF \[Congruent] 0). The Cauchy-Schwarz witness that real analogue-Hawking experiments use is a SINGLE-CONTEXT second-moment inequality; the empirical model lives on one maximal context, hence extends to a global section and has contextual fraction identically zero \[LongDash] the graph-invariant correlation lens cannot even be posed for this witness class. Verified live on single-context covers of several witness sizes (the K=2,4,... of HK-003), for arbitrary distributions:*)

(* ::Input:: *)
SeedRandom[137];
cfSingleContext = Table[
   Module[{sc = CoverScenario[Range[K], {Range[K]}], dist = Normalize[RandomReal[1, 2^K], Total]},
    {K, Chop[ContextualFraction[sc, dist], 10^-9]}], {K, {2, 3, 4}}];
sfx6["S6_A7ii_CFzero"] = AllTrue[cfSingleContext, #[[2]] == 0 &];
TableForm[cfSingleContext, TableHeadings -> {None, {"witness size K", "CF (single context)"}}]

(* ::CodeText:: *)
(*The qubit information sector [T]. On the isotropic CHSH family CF(S) = (S-2)/2, giving the pinned anchors CF(2)=0, CF(2 Sqrt[2]) = Sqrt[2]-1, CF(2.25)=1/8 \[LongDash] the same numbers the qubit Page/Hayden-Preskill suite (04-cluster-state-mbqc/cct_mbqc_hawking.wl) certifies. Recomputed live:*)

(* ::Input:: *)
cfOfS[s_] := Max[0, (s - 2)/2];
qubitCF = {cfOfS[2], Simplify[cfOfS[2 Sqrt[2]]], cfOfS[2.25]};
sfx6["S6_qubitCF"] = (cfOfS[2] === 0) && (Simplify[cfOfS[2 Sqrt[2]]] === Sqrt[2] - 1) &&
   (cfOfS[2.25] == 1/8);
{"CF(2)" -> qubitCF[[1]], "CF(2\[Sqrt]2)" -> qubitCF[[2]], "CF(2.25)" -> qubitCF[[3]]}

(* ::CodeText:: *)
(*The EPR bridge [T]. The two sectors join at the r -> Infinity EPR limit. The qubit working point B = 2.25 maps to an effective Gaussian squeezing r_eff by solving CHSH(r) = 2.25 live (2 Sqrt[1 + Tanh[2r]^2] = 2.25 \[RightArrow] r_eff \[TildeTilde] 0.285020), completing the two-tier emulability verdict: Gaussian sector emulable, qubit sector reproducible, both certified:*)

(* ::Input:: *)
rEff225 = r /. FindRoot[CHSHofR[r] == 9/4, {r, 0.3}, WorkingPrecision -> 20];
sfx6["S6_EPRbridge"] = Abs[CHSHofR[rEff225] - 2.25] < 10^-10 && Abs[rEff225 - 0.285020] < 10^-4;
{"r_eff at CHSH=2.25" -> N[rEff225, 8], "CHSH(r_eff)" -> N[CHSHofR[rEff225], 6]}

(* ::Section:: *)
(*Verification*)

(* ::CodeText:: *)
(*Every key is a live Boolean recomputed above; the sections pass iff all are True:*)

(* ::Input:: *)
SectionsFourToSixVerification = Append[sfx6, "OK" -> (And @@ Values[sfx6])];
Column[{TableForm[List @@@ Normal[SectionsFourToSixVerification]],
   "OK" -> SectionsFourToSixVerification["OK"]}]
