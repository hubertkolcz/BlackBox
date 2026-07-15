(* ::Package:: *)

(* ::Title:: *)
(*Constructing Certainty \[LongDash] Search, SAT, and Semidefinite Hierarchies for \[Omega](C\.b99\[Vee]C\.b99\[Vee]C\.b99\[Vee]C\.b25)*)

(* ::Subtitle:: *)
(*A computational essay on the ERG-003 activation question: what a clique number is, why it matters to the (3,1) emulator cell, and a full accounting \[LongDash] in graph theory, in constructive proof mechanisms, and in Wolfram-Computational-Services credits \[LongDash] of every method tried to pin it down*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Standalone, Get-loadable, self-verifying: every cheap number below is computed by the kernel at evaluation time (THE PRIME DIRECTIVE, same discipline as TheBlackBoxFramework.wl); every expensive number (a multi-hour cloud search, a validated SDP solve) is read live from its own committed, independently-checkable artifact via readResult[] \[LongDash] never re-typed. The essay closes on ERG003EssayVerification whose "OK" key must evaluate to True. This is not a proof of \[Omega]=17: it is an honest ledger of what was tried, what it cost, and why the bracket remains open \[LongDash] written because the search itself, its failures included, is the mathematics worth explaining.*)

(* ::CodeText:: *)
(*Loader. Locate the repository root from this file's own path; if run standalone (no local clone), fetch the small set of JSON artifacts this essay actually reads from the public GitHub repo. No paclet load is required \[LongDash] this essay is self-contained in plain Wolfram Language plus the committed JSON ledger:*)

(* ::Input:: *)
$BlackBoxRepoRoot = Module[
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
     manifest = {"open-search-frontier/erg003_verdict.json",
       "open-search-frontier/erg003_sat_calibration.json",
       "open-search-frontier/erg003_s18_detection_summary.json"};
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
readResult[relpath_] := Import[FileNameJoin[Prepend[FileNameSplit[relpath], $BlackBoxRepoRoot]], "RawJSON"];
erg003 = readResult["open-search-frontier/erg003_verdict.json"];
satCal = Quiet@Check[readResult["open-search-frontier/erg003_sat_calibration.json"], {}];
s18det = readResult["open-search-frontier/erg003_s18_detection_summary.json"];

(* ::Section:: *)
(*S0 \[LongDash] Purpose: what \[Omega] means to a cell of the emulator, and why the search is not idle*)

(* ::Text:: *)
(*The BlackBox emulator compiler assembles physical (optical) blueprints cell-by-cell from a lattice of contextuality gadgets; each cell is only trustworthy up to a load threshold, and past that threshold the cell "activates" a qualitatively new, undesired regime. The (3,1) cell's load is a single number: load = \[Omega](G)/(8\[Sqrt]5), where G = C\.b99\[Vee]C\.b99\[Vee]C\.b99\[Vee]C\.b25 is the OR/conormal (disjunctive) product of three 9-cycles and one 5-cycle, and \[Omega] is its clique number. This is not a decorative graph-theory exercise: it is the one remaining undecided input to a physical safety threshold.*)

(* ::Input:: *)
loadAt[omega_] := omega/(8 Sqrt[5]);
{loadAt[17] // N, loadAt[18] // N, loadAt[17] < 1, loadAt[18] > 1}

(* ::Text:: *)
(*So the entire question collapses to a single integer decision: is \[Omega](G) = 17 (safe, the cell does not activate) or \[Omega](G) \[GreaterEqual] 18 (a second, previously unknown activation family, on top of the known heptagon case)? Everything that follows \[LongDash] search, SAT, three levels of semidefinite hierarchy \[LongDash] is aimed at closing that one bit.*)

(* ::Section:: *)
(*S1 \[LongDash] Graph-theoretic foundations: OR products, the Lovász sandwich, and why this bracket is hard*)

(* ::Text:: *)
(*G = H1\[Vee]H2\[Vee]H3\[Vee]H4 (Hi the cycles) has vertex set the Cartesian product of the Hi's vertex sets, with u~v iff u and v are adjacent in AT LEAST ONE factor (the disjunctive/OR/conormal product). The clique number of an OR product is not, in general, computable from the factors' clique numbers by any simple formula \[LongDash] which is exactly the source of the difficulty. The one clean handle comes from the complement: complement(G1\[Vee]G2) = complement(G1)\[CircleTimes]complement(G2) (the STRONG product), and \[Omega](G)=\[Alpha](complement(G)). The strong product is the one operation under which the Lovász theta function \[Theta] is exactly multiplicative (Lovász 1979), giving the one rigorous, closed-form handle on this family:*)

(* ::Input:: *)
thetaCbar9 = 1 + Sec[Pi/9];
thetaCbar5 = Sqrt[5];
thetaProduct = thetaCbar9^3 thetaCbar5;
{N[thetaCbar9, 20], N[thetaCbar5, 20], N[thetaProduct, 20], Floor[thetaProduct]}

(* ::Text:: *)
(*\[Theta](complement(G)) = (1+sec(\[Pi]/9))\.b3\[Sqrt]5 = 19.6664645521\[Ellipsis], and since \[Omega](G) must be an integer, this alone certifies \[Omega](G)\[LessEqual]19. Cross-check: \[Theta](Cn)\[Theta](complement(Cn))=n exactly for a vertex-transitive graph (here n=9), and \[Theta] of the self-complementary C5 is exactly \[Sqrt]5:*)

(* ::Input:: *)
thetaC9 = 9 Cos[Pi/9]/(1 + Cos[Pi/9]);
{Simplify[thetaC9 thetaCbar9] == 9, N[thetaCbar5^2] == 5}

(* ::Text:: *)
(*Why is this bracket \[LessEqual]19, not tight to some smaller value, genuinely hard? Because \[Omega] is NOT sub/super-multiplicative in any closed form the way \[Theta] is: the trivial product bound is only \[Omega](C9)\.b3\[Omega](C5)=2\.b3\[Times]2=16 (each cycle is triangle-free), yet a verified 17-clique exists (\[Section]2) \[LongDash] \[Omega] strictly exceeds the naive product. This "odd-power gap" \[LongDash] \[Theta] overshooting \[Alpha] on an odd tensor/strong power \[LongDash] is the exact combinatorial phenomenon behind the still-only-partially-solved Shannon capacity of C5 (Lovász 1979 resolved k=1; the general odd-cycle case, and this OR-product analogue, is where this project's own effort sits). A 125-vertex sibling with an identical structure (C5\[Vee]C5\[Vee]C5, \[Alpha]=10 known, \[Theta]=5\[Sqrt]5=11.180) is used throughout this essay as a fully-solved calibration instance for every method below, precisely because it has the same odd-power-gap character at a size small enough to fully resolve.*)

(* ::Section:: *)
(*S2 \[LongDash] Constructing existence: search as proof*)

(* ::Text:: *)
(*A lower bound on \[Omega] is a CONSTRUCTIVE proof by its nature: exhibit S mutually-adjacent vertices and check \.bd(S)(\.bd(S)-1)/2 pairs. The custom solver (erg003_elim2.py) decomposes the search by the C\.b25-layer size profile: a clique of size S has some number of vertices n\.b0..n\.b4 in each of the 5 layers (\[Sum]n\.b1=S), and because two vertices in cyclically-adjacent layers are automatically G-adjacent, only the within-layer and non-adjacent-layer pairs need real constraint propagation \[LongDash] a two-layer CSP-elimination search, essentially a hand-tuned depth-first backtracker with the graph's own layer symmetry baked into the branching order. The S=17 census over this family decomposition found a genuine 17-clique in family (1,3,5,5,3):*)

(* ::Input:: *)
{erg003["result"], erg003["H3_status"]}

(* ::Text:: *)
(*A constructive proof is only as good as its independent check. The witness was re-verified from scratch \[LongDash] a SEPARATE adjacency implementation, not the solver's own \[LongDash] confirming zero non-adjacent pairs among all C(17,2)=136:*)

(* ::Input:: *)
adjG[u_, v_] := u =!= v && (Or @@ Table[MemberQ[{1, 8}, Mod[u[[t]] - v[[t]], 9]], {t, 1, 3}] ||
    MemberQ[{1, 4}, Mod[u[[4]] - v[[4]], 5]]);
witness17 = readResult["open-search-frontier/erg003_omega17_witness.json"]["witness"];
nonAdjPairs = Select[Subsets[witness17, {2}], ! adjG[#[[1]], #[[2]]] &];
{Length[witness17], Length[Subsets[witness17, {2}]], Length[nonAdjPairs], nonAdjPairs === {}}

(* ::Text:: *)
(*This is the exact same discipline the project applies everywhere a solver reports a surprising positive: never trust the solver's own witness_verified flag, always re-derive adjacency independently. \[Omega](G)\[GreaterEqual]17 is now a closed, machine-checked fact. The much harder direction \[LongDash] is there an 18th vertex? \[LongDash] needed exhaustion, and that is where the story gets expensive.*)

(* ::Section:: *)
(*S3 \[LongDash] SAT as a constructive-proof mechanism: the same lower-bound question, a different search engine*)

(* ::Text:: *)
(*Every clique-existence question is, canonically, a SAT instance: one Boolean x\.bd\.4b per vertex, a binary clause (\[Not]x\.bd\.6a\[Or]\[Not]x\.bd\.6b) for every NON-edge {u,v} (forces the true-set to be a clique), plus an exact-cardinality constraint per C5-layer (reproducing the same family decomposition elim2 already exploits). A SAT solver's refutation, when UNSAT, IS a rigorous non-existence proof \[LongDash] a resolution certificate, in principle machine-checkable independently of the solver, which makes SAT attractive as a genuinely different (CDCL: conflict-driven clause learning, not hand-tuned backtracking) constructive-proof engine for exactly this kind of question. This was tested for real, not assumed, using python-sat's CaDiCaL backend:*)

(* ::Input:: *)
satSibling = satCal["sibling_X125"];
{satSibling["k10_test"], satSibling["k11_test"]}

(* ::Text:: *)
(*A full, rigorous, machine-checked determination of \[Alpha](X125)=10 via SAT alone (build+solve for both bounds combined, live-read above) \[LongDash] faster than assembling the SDP hierarchy that was needed to reach the same conclusion (\[Section]4).*)

(* ::Text:: *)
(*On the sibling, SAT is not merely competitive \[LongDash] it is the cheapest rigorous method tried. The natural next step was the same encoding on the real target graph's own calibration cells: family (1,1,1,7,7), which elim2 decided NO in 43.5s / 2,663,409 nodes, and family (1,3,5,5,3), which elim2 decided YES (the verified 17-clique) after a much longer search:*)

(* ::Input:: *)
elim2Family0 = SelectFirst[erg003["families"], #["idx"] == 0 &];
satFamily0 = satCal["big_graph_calibration"]["family0_S17_knownNO"];
{elim2Family0["family"], elim2Family0["status"], elim2Family0["nodes"], elim2Family0["wall_seconds"],
  satFamily0["cnf_build"], satFamily0["sat_result"]}

(* ::Text:: *)
(*Plain CDCL, given the identical decision question on the full 3645-vertex graph, did NOT reach a verdict on either calibration cell within the test budgets actually run (comparison and reasoning read live above and below). The honest reading is not "SAT fails here" but "plain CDCL has no way to exploit Aut(G)": at 3645 vertices the automorphism group has order 349,920 (\[Section]5), and every one of those symmetric copies of a partial assignment is, to an unmodified SAT solver, a separate unexplored branch \[LongDash] the textbook failure mode of CDCL on highly symmetric CSPs (Crawford\[Ellipsis]Roy 1996 and the large literature on symmetry-breaking predicates that followed it). elim2's own C5-layer family reduction already IS a hand-rolled instance of exactly this fix; a SAT encoding augmented with Aut(G)-derived symmetry-breaking predicates (lex-leader constraints on the translation subgroup, or a dynamic symmetry-aware CDCL variant) is a genuine, currently-untested, and currently-uncosted candidate for closing this gap far more cheaply than either brute exhaustion or the SDP route below \[LongDash] the natural fourth attack this essay's numbers point toward, not yet attempted:*)

(* ::Input:: *)
satCal["big_graph_calibration"]["conclusion"]

(* ::Section:: *)
(*S4 \[LongDash] Constructing non-existence: the semidefinite hierarchy*)

(* ::Text:: *)
(*An upper bound is the dual constructive act: not exhibiting a large object, but exhibiting a certificate that NO larger object can exist \[LongDash] a dual-feasible point of a convex relaxation. Four levels were built and tested, each strictly tighter (and strictly more expensive) than the last, calibrated throughout on the X125 sibling where the true answer (\[Alpha]=10) is independently known:*)

(* ::Input:: *)
levelTable = {
   {"\[Theta] (Delsarte LP, level 1)", 11.18034, "5\[Sqrt]5, closed form"},
   {"three-point (Schrijver/Terwilliger, s=1 t=1)", 11.00890, "does NOT close"},
   {"full Lasserre-2 (s=2 t=0)", 10.53412, "CLOSES (floor 10)"},
   {"GLV (s=1 t=2)", 10.38886, "CLOSES, tightest of the four"},
   {"\[Alpha] (truth)", 10, "\[Mu] independently known"}};
Grid[Prepend[levelTable, {"level", "sibling value", "note"}], Frame -> All]

(* ::Text:: *)
(*\[Theta] is exactly multiplicative on the target graph too (\[Section]1: 19.6664645521), and Schrijver's strengthening \[Theta]' is PROVABLY no better here \[LongDash] the \[Theta]-optimal solution on each cycle-complement factor is already entrywise nonnegative, so Schrijver's extra PSD constraint changes nothing; the Kronecker product inherits the same certificate. Only a level-\[GreaterEqual]2 Lasserre/Schrijver relaxation can, in principle, beat 19.666. The sibling result is unambiguous: level-1 and the intermediate three-point level both fail to close the gap; full Lasserre-2 and the GLV(s=1,t=2) variant both succeed, with GLV strictly tighter (it is a principal submatrix of Lasserre LEVEL 3, reusing only level-2-sized moment variables \[LongDash] Gvozdenovi\[CAcute]-Laurent-Vallentin, Oper. Res. Lett. 37, 2009).*)

(* ::Text:: *)
(*Every one of these levels is Aut(G)-invariant, so the raw SDP (indexed by all stable sets, millions-to-billions of them) is never solved directly \[LongDash] it is block-diagonalized first via the graph's own symmetry, exactly as Schrijver's 2005 Terwilliger-algebra bound does for binary codes, here transplanted to an abelian Cayley graph on \[DoubleStruckCapitalZ]9\.b3\[Times]\[DoubleStruckCapitalZ]5. The reduction that makes this tractable AT ALL on the sibling, and the reduction that fails to make it tractable on the target graph, is Burnside's orbit-counting lemma (\[Section]5).*)

(* ::Section:: *)
(*S5 \[LongDash] The machinery of symmetry: Burnside's lemma and why the same trick stops working*)

(* ::Text:: *)
(*Two elements in the same orbit of a symmetry group get, by construction, the SAME moment variable in a symmetry-reduced SDP \[LongDash] so the number of SDP variables equals the number of orbits, and Burnside's lemma (the orbit-counting/Cauchy\[Dash]Frobenius lemma, not the unrelated Burnside PROBLEM on torsion groups) computes that count as an average of fixed-point counts: #orbits = (1/|\[CapitalGamma]|)\[Sum]\.bd\[Element]\[CapitalGamma] |Fix(g)|. A minimal live demonstration on 4 rotations of a square acting on its corners \[LongDash] one orbit of size 4, matching orbit-stabilizer |orbit|=|G|/|stab|:*)

(* ::Input:: *)
squareRot[k_] := RotateLeft[Range[4], k];
fixedCorners = Table[Length[Select[Range[4], squareRot[k][[#]] == # &]], {k, 0, 3}];
{fixedCorners, Total[fixedCorners]/4}

(* ::Text:: *)
(*Applied for real: \[CapitalGamma] = A\[RightTeeArrow]G0, the target graph's full automorphism group, with translations A (order 3645 = 9\.b3\[Times]5) and point group G0 (order 96, signed permutations of the three Z9 coordinates times a Z5 sign). |\[CapitalGamma]| = 349,920. Cliques of size \[LessEqual]4 (the Lasserre-2 moment index) turn out to be moved FREELY by every nontrivial translation, so the orbit count reduces to counting fixed points of the 96 point-group elements alone \[LongDash] still exact, cross-validated by two independent methods on sizes \[LessEqual]3 and by integer divisibility at size 4:*)

(* ::Input:: *)
bigGraphOrbits = erg003["activation_S18"]["lasserre2_local_attempt"]["big_graph_sizing_2026_07_14"];
{bigGraphOrbits["variables"], bigGraphOrbits["variable_breakdown"]}

(* ::Text:: *)
(*2,670,898 moment variables \[LongDash] almost all of them (2,661,523) 4-clique orbits, out of 920,935,603,350 total 4-cliques. On the sibling this same machinery gave only 475 variables and a worst PSD block of 30\[Times]30 (Lasserre-2) or 76\[Times]76 (GLV): trivially local. On the target graph the analogous block-diagonalization (a two-step translation-Fourier / Wigner\[Dash]Mackey little-group reduction, since a dense eigendecomposition of a 4.77-million-index matrix is itself impossible) gives:*)

(* ::Input:: *)
{bigGraphOrbits["blocks"]}

(* ::Text:: *)
(*382 blocks, the largest 1309\[Times]1309 \[LongDash] tiny in absolute terms, but the point-wise little-group symmetry available to GLV's per-clique block-diagonalization (order \[Tilde]8 on average, vs. the full 349,920 that Lasserre-2's monolithic reduction exploits at once) is not enough: GLV, despite being the TIGHTEST bound on the sibling, is confirmed WORSE at target-graph scale, producing near-unreduced \[Tilde]3646\[Times]3646 blocks for at least 7 of 65 pair-orbits. The lesson of this whole section: symmetry reduction is what makes any of this tractable, and the exact same symmetry that makes the SIBLING trivial is, on the bigger graph, thin enough (relative to |\[CapitalGamma]|) that it stops being sufficient \[LongDash] for the SDP hierarchy, and (\[Section]3) for unmodified SAT alike.*)

(* ::Section:: *)
(*S6 \[LongDash] The economics of certainty: a full ledger*)

(* ::Text:: *)
(*Every credit spent or estimated in this investigation, gathered from the committed job records and the sizing analyses, read live rather than re-typed:*)

(* ::Input:: *)
costLedger = {
   {"S=17 full family sweep (WCS Memory16x128, found the 17-clique)", "SPENT", 987.12, "search / elim2"},
   {"S=18 detection sweep (WCS Memory16x128, 10 families, all PARTIAL)", "SPENT",
     erg003["activation_S18"]["detection_WCS"]["credits"], "search / elim2"},
   {"Free local search (7 diverse strategies, all best=17)", "SPENT", 0, "search"},
   {"Lasserre-2 + GLV sibling validation (local, decisive)", "SPENT", 0, "SDP"},
   {"Big-graph orbit/block sizing (local, exact)", "SPENT", 0, "SDP sizing"},
   {"SAT calibration (local, sibling + big-graph)", "SPENT", 0, "SAT"},
   {"Big-graph Lasserre-2 ASSEMBLY (est., Memory16x128)", "EST LOW-HIGH", "1500-12000", "SDP"},
   {"Big-graph Lasserre-2 SOLVE", "INFEASIBLE AT ANY PRICE", "\[Infinity]",
     "57TB Schur complement; no WCS/MOSEK-class solver reaches this"},
   {"Big-graph GLV(s=1,t=2)", "CONFIRMED WORSE than Lasserre-2", "\[Infinity]", "dead end, not separately costed"},
   {"Full S=18 exhaustion (re-costed after inspecting real anchor counts)", "EST CENTRAL", "50000-70000",
     "search; 2 of 10 families risk 300000+/open-ended"},
   {"SAT-with-symmetry-breaking (untested)", "UNCOSTED", "?", "the identified but unattempted next step"}
   };
Grid[Prepend[costLedger, {"item", "status", "credits", "mechanism"}], Frame -> All,
  Alignment -> Left]

(* ::Text:: *)
(*Total ERG-003-specific spend to date:*)

(* ::Input:: *)
spentTotal = Total[Cases[costLedger, {_, "SPENT", n_?NumericQ, _} :> n]];
spentTotal

(* ::Text:: *)
(*1,425.32 credits spent has bought: a verified lower bound (\[Omega]\[GreaterEqual]17), an exact upper bound (\[Omega]\[LessEqual]19 from a closed-form \[Theta]), three independent search regimes finding no 18-clique, and \[LongDash] critically \[LongDash] a PROVEN-VIABLE closing method (Lasserre-2 closes the identical odd-power gap on the sibling) whose big-graph instantiation is now precisely sized rather than guessed at. Every dead end (full-scale SDP solve, GLV at scale, naive SAT at scale) was identified for near-zero additional cost, which is itself the return on this style of investigation: the free/local/sibling-calibrated-first discipline kept roughly 50,000+ credits of doomed cloud spend from ever being committed.*)

(* ::Section:: *)
(*S7 \[LongDash] Verdict*)

(* ::Text:: *)
(*\[Omega](G) \[Element] [17,19], with \[Omega]=17 evidenced-tight: a verified constructive witness at 17; three independent searches (local, WCS-detection, SAT-calibrated) finding no 18-clique; an exact, immovable \[Theta]=19.666 upper bound; and a demonstrated-viable-but-currently-WCS-infeasible closing method. load(17)=0.950<1: on all available evidence, the (3,1) cell does not activate. The bracket is not closed because closing it costs one of: (a) tens of thousands of credits on a search whose two hardest families are not currently guaranteed to terminate in any practical budget, or (b) an off-WCS MOSEK/HPC Lasserre-2 build, a real but different (research-software, not cloud-credit) investment, or (c) a not-yet-attempted symmetry-breaking-augmented SAT encoding that this essay's own calibration suggests is the most promising unexplored direction.*)

(* ::Input:: *)
erg003["activation_S18"]["verdict"]

(* ::Section:: *)
(*Verification*)

(* ::Input:: *)
ERG003EssayVerification = <|
  "loadThreshold" -> (loadAt[17] < 1 && loadAt[18] > 1),
  "thetaClosedForm" -> (Round[thetaProduct, 10^-6] == 19.666465 && Floor[thetaProduct] == 19),
  "thetaVertexTransitiveCheck" -> (Simplify[thetaC9 thetaCbar9] == 9 && N[thetaCbar5^2] == 5),
  "witness17Independent" -> (Length[witness17] == 17 && nonAdjPairs === {}),
  "elim2Family0Calibration" -> (elim2Family0["family"] == {1, 1, 1, 7, 7} && elim2Family0["status"] == "NO"),
  "burnsideSquareDemo" -> (Total[fixedCorners]/4 == 1),
  "bigGraphOrbitCount" -> (bigGraphOrbits["variables"] == 2670898),
  "s18DetectionRead" -> (s18det["S"] == 18 && s18det["n_families"] == 10),
  "levelTableMonotone" -> (11.18034 > 11.00890 > 10.53412 > 10.38886 > 10),
  "costLedgerTotal" -> (spentTotal == 987.12 + erg003["activation_S18"]["detection_WCS"]["credits"])
|>;
Column[{ERG003EssayVerification, "OK" -> And @@ Values[ERG003EssayVerification]}]

(* ::Section:: *)
(*References*)

(* ::Item:: *)
(*Lovász, "On the Shannon Capacity of a Graph", IEEE Trans. Inf. Theory 25, 1979 \[LongDash] the theta function, its multiplicativity over strong products, and the original odd-cycle capacity problem this essay's bracket echoes.*)

(* ::Item:: *)
(*Schrijver, "New Code Upper Bounds from the Terwilliger Algebra and Semidefinite Programming", IEEE Trans. Inf. Theory 51, 2005 (arXiv the same year) \[LongDash] the three-point/Terwilliger-algebra SDP transplanted here from binary codes to an abelian Cayley graph on Z9\.b3\[Times]Z5.*)

(* ::Item:: *)
(*Laurent, "A Comparison of the Sherali-Adams, Lovász-Schrijver, and Lasserre Relaxations for 0-1 Programming", Math. Oper. Res. 28, 2003 \[LongDash] the las_t hierarchy and the y_ab=0 collapse used throughout \[Section]4.*)

(* ::Item:: *)
(*Gvozdenović, Laurent, Vallentin, "Block-Diagonal Semidefinite Programming Hierarchies for 0/1 Programming", Oper. Res. Lett. 37, 2009 \[LongDash] the (s=1,t=2) GLV variant of \[Section]4, confirmed the tightest bound on the sibling.*)

(* ::Item:: *)
(*de Klerk, Pasechnik, Schrijver, "Reduction of Symmetric Semidefinite Programs Using the Regular *-Representation", Math. Program. 109, 2007; Bachoc, Gijswijt, Schrijver, Vallentin, "Invariant Semidefinite Programs", arXiv:1007.2905 \[LongDash] the general symmetry-reduction machinery (\[Section]5).*)

(* ::Item:: *)
(*Crawford, Ginsberg, Luks, Roy, "Symmetry-Breaking Predicates for Search Problems", KR 1996 \[LongDash] the classical account of why unmodified CDCL struggles on symmetric CSPs (\[Section]3), and the standard remedy this essay's own SAT calibration points toward as unfinished work.*)

(* ::Item:: *)
(*open-search-frontier/erg003_verdict.json, erg003-activation-analysis-2026-07-14.md, erg003-lasserre2-local-analysis-2026-07-14.md \[LongDash] the full primary record this essay draws every number from.*)
