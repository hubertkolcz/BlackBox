(* ::Package:: *)

(* ::Title:: *)
(*Certifying Quantumness from Event Statistics: The KCBS Pentagon as a Black-Box Test*)

(* ::Subtitle:: *)
(*A computational essay on graph, sheaf, and Lie-algebra certificates of contextuality*)

(* ::Text:: *)
(*Hubert Ko\[LSlash]cz \[LongDash] July 2026. Built on the BlackBox paclet (HubertKolcz`BlackBox`, this repository); every algorithm it exports was kernel-verified twice before packaging. Native Wolfram functionality (SemidefiniteOptimization, LinearOptimization, FindClique, GraphData, MatrixLog) does all heavy lifting; the paclet only names the constructions.*)

(* ::Abstract:: *)
(*A device emits one detector click per run. Can its click statistics alone certify that no classical mechanism produced them? For the Klyachko-Can-Binicio\[GBreve]lu-Shumovsky (KCBS) pentagon the answer is a chain of three sharp numbers \[LongDash] classical 2 < quantum Sqrt[5] < exclusivity-only 5/2 \[LongDash] each computable from the exclusivity graph with no Hilbert space assumed. This essay derives all three, explains the quantum value by composing two copies of the experiment, prices the resource exactly (contextual fraction 2 Sqrt[5] - 4, in exact arithmetic), separates the three behaviours sheaf-theoretically, exhibits the Lie-algebraic step where quantumness enters, and shows why these certificates, unlike state vectors, scale to meshes.*)

(* ::Section:: *)
(*Summary of Results*)

(* ::Item:: *)
(*Three bounds of the pentagon: \[Alpha] = 2 (classical), \[CurlyTheta] = Sqrt[5] \[TildeTilde] 2.236 (quantum, SDP), \[Alpha]* = 5/2 (exclusivity-only) \[LongDash] reproduced by the library and confirmed exactly by Wolfram's curated GraphData.*)

(* ::Item:: *)
(*Two copies explain the quantum bound: the quantum assignment saturates all ten 5-cliques of the doubled experiment at exactly 1, while the supra-quantum Wright box violates every one of them at exactly 5/4 \[LongDash] and the heptagon box survives untouched (zero margin, no activation).*)

(* ::Item:: *)
(*The contextual fraction of the quantum-maximal model is exactly 2 Sqrt[5] - 4 \[TildeTilde] 0.472 (linear programming in exact arithmetic); the classical control carries 0, Wright's box the maximum 1.*)

(* ::Item:: *)
(*Sheaf stratification: the classical model extends globally; the quantum model does not, yet keeps |S_e| = 11 = LucasL[5] possibilistic global assignments; Wright's box keeps none \[LongDash] strong contextuality at one copy. The sheaf Laplacian's harmonic residual vanishes on all three: a pre-registered negative result.*)

(* ::Item:: *)
(*The KCBS cascade generators span a 2-plane of so(3); one commutator closes the full algebra \[LongDash] the quantum resource sits at commutator depth one.*)

(* ::Item:: *)
(*On chains of N glued pentagons the certificate stays a polynomial-size SDP while any state-vector treatment grows as 2^(5N); even-N chains pinch the quantum gap shut, odd-N chains reopen it.*)

(* ::Section:: *)
(*Introduction*)

(* ::Text:: *)
(*The KCBS construction (Klyachko, Can, Binicio\[GBreve]lu, Shumovsky, PRL 101, 020403 (2008)) tests a single three-level system with five dichotomic measurements arranged in a cycle: neighbours are compatible and exclusive, so the experiment has five contexts and each observable appears in two of them. Everything a hidden-variable sceptic needs to know is the exclusivity graph of the five events \[LongDash] the pentagon. Cabello, Severini and Winter (arXiv:1010.2163) turned this into a dictionary: the classical, quantum, and exclusivity-only reaches of ANY such experiment are three invariants of its graph. The BlackBox library packages those certificates; this essay runs them.*)

(* ::CodeText:: *)
(*Load the library (sits next to this notebook), repair any Global`-shadowing, and list its full interface:*)

(* ::Input:: *)
PacletDirectoryLoad[FileNameJoin[{Quiet@Check[NotebookDirectory[], Directory[]], "..", "BlackBox"}]];
Needs["HubertKolcz`BlackBox`"]; Quiet[Remove /@ Select["Global`" <> # & /@ Names["HubertKolcz`BlackBox`*"], NameQ]];
Names["HubertKolcz`BlackBox`*"]

(* ::Section:: *)
(*One Graph, Three Theories, Three Numbers*)

(* ::CodeText:: *)
(*The exclusivity graph of the KCBS experiment is the 5-cycle:*)

(* ::Input:: *)
pentagon = CycleGraph[5, VertexLabels -> "Name", VertexSize -> .15, ImageSize -> 200]

(* ::Text:: *)
(*A deterministic hidden-variable theory can make at most an independent set of events true at once; quantum mechanics reaches the Lov\[AAcute]sz number by semidefinite programming; a theory constrained only by exclusivity reaches the fractional packing number. Three theories, three graph invariants:*)

(* ::CodeText:: *)
(*Classical \[Alpha], quantum \[CurlyTheta] (SDP), exclusivity-only \[Alpha]* \[LongDash] the strict hierarchy 2 < Sqrt[5] < 5/2:*)

(* ::Input:: *)
{IndependenceNumber[pentagon], LovaszTheta[pentagon], FractionalPackingNumber[pentagon]}

(* ::CodeText:: *)
(*Wolfram's curated graph data supplies the same three values exactly \[LongDash] a free oracle for the library:*)

(* ::Input:: *)
GraphData[{"Cycle", 5}, #] & /@ {"IndependenceNumber", "LovaszNumber", "FractionalChromaticNumber"}

(* ::CodeText:: *)
(*The quantum value is physical: five exact pentagram directions, cyclically orthogonal, sum to Sqrt[5] on the cone axis:*)

(* ::Input:: *)
dirs = KCBSDirections[];
Simplify[{dirs[[1]] . dirs[[2]], Total[(# . {0, 0, 1})^2 & /@ dirs]}]

(* ::Section:: *)
(*Why Sqrt[5]: Compose Two Copies*)

(* ::Text:: *)
(*Where does the quantum number come from, if not from Hilbert space? Cabello's answer (PRL 110, 060402 (2013)): run two independent copies. Events of the doubled experiment are exclusive if they are exclusive in either copy (the OR product of graphs, native to Wolfram as GraphProduct's "Conormal"), and probabilities multiply. Consistent Exclusivity demands every clique of the doubled graph carry total probability at most 1. The BlackBox filter checks all of them.*)

(* ::CodeText:: *)
(*The quantum assignment (1/Sqrt[5] per event) passes all 535 maximal cliques of two copies \[LongDash] saturating the ten 5-cliques at exactly 1:*)

(* ::Input:: *)
CEFilter[pentagon, ConstantArray[1/Sqrt[5], 5] // N]

(* ::CodeText:: *)
(*Wright's exclusivity-extremal box (1/2 per event, the \[Alpha]* point) is expelled: every 5-clique overflows at exactly 5/4:*)

(* ::Input:: *)
CEFilter[pentagon, ConstantArray[1/2, 5]]

(* ::CodeText:: *)
(*The mechanism has zero margin: the heptagon box survives two copies exactly at the boundary (\[Omega] = 4, load 1) \[LongDash] no activation, reproducing arXiv:2411.09773:*)

(* ::Input:: *)
CEFilter[CycleGraph[7], ConstantArray[1/2, 7]]

(* ::Section:: *)
(*The Exact Price of Classicality*)

(* ::Text:: *)
(*How much of a behaviour can a noncontextual model carry? The contextual fraction (Abramsky, Barbosa, Mansfield, PRL 119, 050504 (2017)) decomposes an empirical model e = NCF \[CenterDot] e_noncontextual + CF \[CenterDot] e' and maximizes the noncontextual weight by linear programming over the deterministic global assignments. Wolfram's LinearOptimization supports exact arithmetic, so the certificate below is an algebraic identity, not a float.*)

(* ::CodeText:: *)
(*The 5-cycle scenario; its incidence matrix has rank 1 + 5 + 5 = 11 (Abramsky-Brandenburger Prop. 5.7):*)

(* ::Input:: *)
scenario = CycleScenario[5];
MatrixRank[scenario["Incidence"]]

(* ::CodeText:: *)
(*Contextual fractions of the three canonical models, in exact arithmetic \[LongDash] classical 0, quantum exactly 2 Sqrt[5] - 4, Wright maximal:*)

(* ::Input:: *)
FullSimplify[ContextualFraction[scenario, CycleModel[5, #], WorkingPrecision -> Infinity] & /@
  {"Classical", "Quantum", "Wright"}]

(* ::Section:: *)
(*Local Truths, Global Lies: the Sheaf View*)

(* ::Text:: *)
(*Abramsky and Brandenburger (NJP 13, 113036 (2011)) read contextuality as a local-to-global failure: each context's distribution is a local section of a presheaf, and contextuality is the obstruction to gluing them into one global distribution. The three models stratify cleanly.*)

(* ::CodeText:: *)
(*Only the classical model extends to a global probability distribution:*)

(* ::Input:: *)
GlobalSectionQ[scenario, N@CycleModel[5, #]] & /@ {"Classical", "Quantum", "Wright"}

(* ::CodeText:: *)
(*Possibilistically the quantum model keeps exactly 11 global assignments \[LongDash] the Lucas number LucasL[5] \[LongDash] while Wright's box keeps none (strong contextuality):*)

(* ::Input:: *)
{PossibilisticSupport[scenario, N@CycleModel[5, "Quantum"]],
 PossibilisticSupport[scenario, N@CycleModel[5, "Wright"]], LucasL[5]}

(* ::Text:: *)
(*A pre-registered negative result, kept for honesty: the cellular-sheaf Laplacian of the cover (Hansen-Ghrist, arXiv:1808.01513) was a candidate contextuality measure. Its kernel is the 11-dimensional space of no-disturbance models \[LongDash] and all three behaviours already live there, so the harmonic residual is blind to contextuality. It is a no-disturbance projector, nothing more.*)

(* ::CodeText:: *)
(*The harmonic residual vanishes on classical, quantum, and Wright alike \[LongDash] REJECTED as a contextuality measure:*)

(* ::Input:: *)
delta = CycleCoboundary[5];
Chop[HarmonicResidual[delta, N@CycleModel[5, #]] & /@ {"Classical", "Quantum", "Wright"}]

(* ::Section:: *)
(*The Geometry Underneath: One Commutator*)

(* ::Text:: *)
(*The canonical realization (Lapkiewicz et al., Nature 474, 490 (2011)) walks a single photon through a cascade of two-mode rotations. Each stage generator is a matrix logarithm in so(3) \[LongDash] and the four of them rotate about only two axes. The full algebra, and with it the quantum resource, appears exactly at the first commutator: locally abelian, globally non-abelian.*)

(* ::CodeText:: *)
(*The four cascade generators span only a 2-plane of so(3):*)

(* ::Input:: *)
gens = CascadeGenerators[];
MatrixRank[So3Axis /@ gens, Tolerance -> 10^-8]

(* ::CodeText:: *)
(*One commutator step closes the full three-dimensional algebra:*)

(* ::Input:: *)
DLADimension[gens]

(* ::Section:: *)
(*Why Certificates: They Scale*)

(* ::Text:: *)
(*A mesh of N single-edge-glued pentagons is a toy model of an MBQC resource. Its compiled cluster needs a state vector of dimension 2^(5N); the graph certificate is one SDP on 3N + 2 vertices. The certificate also sees structure the operator route must compute to find: even-N chains pinch the quantum gap shut (\[CurlyTheta] = \[Alpha]), odd-N chains reopen it \[LongDash] mesh parity controls quantumness.*)

(* ::CodeText:: *)
(*Chains of N glued pentagons: linear certificate growth against exponential state-vector cost:*)

(* ::Input:: *)
chainData = Table[Module[{g = PentagonChain[n]},
    {n, LovaszTheta[g], IndependenceNumber[g], 2^(5 n)}], {n, 1, 5}];
TableForm[chainData, TableHeadings -> {None, {"N", "\[CurlyTheta] (SDP)", "\[Alpha]", "state-vector dim"}}]

(* ::CodeText:: *)
(*The quantum gap \[CurlyTheta] - \[Alpha] oscillates with chain parity \[LongDash] even chains are classical, odd chains quantum:*)

(* ::Input:: *)
ListLinePlot[{#[[1]], #[[2]] - #[[3]]} & /@ chainData, PlotMarkers -> Automatic,
  AxesLabel -> {"N (pentagon blocks)", "\[CurlyTheta] - \[Alpha]"}, PlotRange -> {-.02, .28},
  PlotLabel -> "quantum gap of pentagon chains", ImageSize -> 380]

(* ::Section:: *)
(*Verification*)

(* ::Text:: *)
(*House discipline: every claim above, machine-checked in one association. This cell must print OK -> True.*)

(* ::Input:: *)
EssayVerification = <|
  "hierarchy" -> IndependenceNumber[pentagon] == 2 && FractionalPackingNumber[pentagon] == 5/2 &&
     Abs[LovaszTheta[pentagon] - Sqrt[5.]] < 10^-6,
  "oracle" -> GraphData[{"Cycle", 5}, "LovaszNumber"] === Sqrt[5],
  "geometry" -> Simplify[Total[(# . {0, 0, 1})^2 & /@ KCBSDirections[]] - Sqrt[5]] === 0,
  "twoCopies" -> CEFilter[pentagon, ConstantArray[N[1/Sqrt[5]], 5]]["Passes"] &&
     CEFilter[pentagon, ConstantArray[1/2, 5]]["Worst"] == 5/4 &&
     CEFilter[CycleGraph[7], ConstantArray[1/2, 7]]["Passes"],
  "exactCF" -> FullSimplify[ContextualFraction[scenario, CycleModel[5, "Quantum"],
       WorkingPrecision -> Infinity] - (2 Sqrt[5] - 4)] === 0,
  "sheafStrata" -> (GlobalSectionQ[scenario, N@CycleModel[5, #]] & /@ {"Classical", "Quantum", "Wright"}) ===
     {True, False, False} && PossibilisticSupport[scenario, N@CycleModel[5, "Quantum"]]["Size"] == LucasL[5],
  "laplacianRejected" -> AllTrue[HarmonicResidual[delta, N@CycleModel[5, #]] & /@
     {"Classical", "Quantum", "Wright"}, # < 10^-10 &],
  "dla" -> MatrixRank[So3Axis /@ gens, Tolerance -> 10^-8] == 2 && DLADimension[gens] == 3,
  "chains" -> And @@ Table[Abs[chainData[[n, 2]] - {2.2360680, 4., 5.1366009, 7., 8.1014704}[[n]]] < 10^-3, {n, 5}]
|>;
Column[{EssayVerification, "OK" -> And @@ Values[EssayVerification]}]

(* ::Section:: *)
(*Concluding Remarks*)

(* ::Text:: *)
(*One graph carried the whole argument. The pentagon's three invariants delimit three theories; two copies of the experiment force the quantum value; a linear program prices the resource exactly; the sheaf view says precisely which local consistencies fail to globalize; and one commutator marks where the classical description ends. Limitations, stated plainly: the SDP values are machine-precision (only the LP certificates here are exact); a classical computer reproducing these statistics has no evidential force \[LongDash] the sampler knows the context, which is exactly what hidden-variable models are forbidden; the sheaf Laplacian was rejected by its pre-registered gate test and is kept only as a no-disturbance projector; and the two-copy filter provably cannot activate n-cycles with n \[GreaterEqual] 7, so these certificates bound from above without singling out the quantum set in general \[LongDash] that is Cabello's open D1 problem, not a solved one.*)

(* ::Section:: *)
(*Future Work*)

(* ::Item:: *)
(*DONE since this essay was written: the k = 3 heptagon cell is settled by citation (Choudhary-Barbosa, arXiv:2411.09773, Thm. 12, plus a product bound) in activation.wl, and the full "does a fixed quantum pentagon activate every n-cycle box beyond n = 7" question is settled NEGATIVE by exhaustive search in HeptagonCatalysis.wl (n = 7 is the unique activated length, a theorem).*)

(* ::Item:: *)
(*DONE since this essay was written: SupportCohomology.wl replaces the rejected Laplacian with \[CapitalCCedilla]ech cohomology of the support presheaf on the CycleScenario datatype, following Abramsky-Mansfield-Barbosa, "The Cohomology of Non-Locality and Contextuality," arXiv:1111.3620 (2011/2012) - not arXiv:1502.03097, a related but different companion paper; see BlackBox.wl's CechObstruction comment for the two papers' precise division of labor.*)

(* ::Item:: *)
(*Correlate DLA growth with contextual fraction under composition on pentagon meshes \[LongDash] the FEM study design (H1-H5) built on PentagonChain.*)

(* ::Item:: *)
(*Run the two-qubit biphoton encoding of the cascade on gate hardware as a genuine platform test, using the Wolfram/QuantumFramework paclet for the circuit layer.*)

(* ::Section:: *)
(*References*)

(* ::Item:: *)
(*Klyachko, Can, Binicio\[GBreve]lu, Shumovsky, PRL 101, 020403 (2008); arXiv:0706.0126.*)

(* ::Item:: *)
(*Cabello, Severini, Winter, arXiv:1010.2163; Cabello, PRL 110, 060402 (2013).*)

(* ::Item:: *)
(*Abramsky, Brandenburger, NJP 13, 113036 (2011); Abramsky, Barbosa, Mansfield, PRL 119, 050504 (2017).*)

(* ::Item:: *)
(*Lapkiewicz et al., Nature 474, 490 (2011); Kujala, Dzhafarov, Larsson, PRL 115, 150401 (2015).*)

(* ::Item:: *)
(*Hansen, Ghrist, J. Appl. Comput. Topol. 3 (2019); arXiv:1808.01513.*)

(* ::Item:: *)
(*Choudhary, Barbosa, arXiv:2411.09773; Fritz et al., Nat. Commun. 4, 2263 (2013).*)

(* ::Item:: *)
(*Wolfram: SemidefiniteOptimization, LinearOptimization (exact LP), GraphData curated invariants, GraphProduct "Conormal"; the BlackBox paclet (this repository).*)
