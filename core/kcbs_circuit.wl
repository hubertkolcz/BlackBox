(* ::Package:: *)

(* ::Title:: *)
(*The KCBS Pentagon as a Quantum Circuit*)

(* ::Subtitle:: *)
(*A computational essay: from the Lapkiewicz photonic experiment to gate-level circuits in the Wolfram Quantum Framework*)

(* ::Text:: *)
(*This essay builds, cell by cell, a circuit-model formulation of the Klyachko-Can-Binicioglu-Shumovsky (KCBS) contextuality test. Three design decisions shape everything below, and none of them is visible in the code itself, so let us state them up front.*)

(* ::Text:: *)
(*Decision 1 - the experimental template. Among the confirmed laboratory realizations of KCBS, we model the staged scheme of Lapkiewicz et al., Nature 474, 490 (2011): a single photon in three optical modes, where the five measurement contexts are obtained by switching on, one at a time, four two-mode transformations T1..T4. We choose it because its structure maps literally onto a single quantum circuit: context k is the prefix of length k of one fixed gate sequence, and the observable shared by two neighbouring contexts is carried by a part of the apparatus that the intervening transformation provably does not touch. No other published implementation collapses onto one circuit this cleanly.*)

(* ::Text:: *)
(*Decision 2 - two encodings of the qutrit. (A) A native qutrit wire (the framework supports qudits), which is the faithful emulation of the photonic black box: computational basis states are the three optical modes, and a detector click on mode i is the outcome i. (B) A two-qubit encoding in the symmetric (triplet) subspace - historically, the biphoton realization proposed in the original KCBS paper itself (arXiv:0706.0126), and practically, the version that compiles to any gate-based hardware. Its punchline: every two-mode transformation becomes a collective rotation, the same single-qubit gate applied to both qubits.*)

(* ::Text:: *)
(*Decision 3 - the picture. The framework tags every object with a "Picture" (the default is Schrodinger) and supplies both pictures natively. For the analysis of contextuality we deliberately work in the HEISENBERG picture: contextuality is a claim about observables, not states, and Section 5 shows that the three statements constituting the KCBS test become one-line operator identities there - while the Schrodinger state view is provably blind to them. Throughout, we implement as little as possible by hand: circuit diagrams, probability plots, operator composition and daggers are all built-in framework features.*)

(* ::Section:: *)
(*1. Environment*)

(* ::Text:: *)
(*The quantum functionality lives in the Wolfram/QuantumFramework paclet. One operational subtlety motivates the first cell: if this material is evaluated as a single block (or after a previously failed run), symbols like QuantumState can get created in the Global` context before the paclet's context is on the path, and they then shadow the real ones - every subsequent call silently fails. Evaluating cell by cell avoids the problem; the cleanup cell repairs a kernel polluted by an earlier attempt. If anything ever looks undefined, quit the kernel and evaluate the essay from the top.*)

(* ::Input:: *)
Quiet[If[# =!= {}, Remove @@ #] & @ Names["Global`Quantum*"]];

(* ::Input:: *)
Quiet[PacletInstall["Wolfram/QuantumFramework"]];
Needs["Wolfram`QuantumFramework`"];

(* ::Text:: *)
(*Sanity check: a qutrit state (dimension 3) with all amplitude on level 2 should report probabilities {0, 0, 1}.*)

(* ::Input:: *)
QuantumState[{0, 0, 1}, 3]["Probabilities"]

(* ::Section:: *)
(*2. Geometry: the pentagram*)

(* ::Text:: *)
(*KCBS needs five unit vectors l1..l5 in R^3 with each consecutive pair orthogonal (indices mod 5). Such a closed chain cannot lie in a plane; the standard construction puts the five vectors on a cone around the z axis, at azimuths spaced by 4 Pi/5 - the pentagram ordering, chosen precisely so that neighbours in the KCBS cycle are 144 degrees apart in azimuth, which combined with the cone half-angle below makes them orthogonal. The half-angle is fixed by that orthogonality condition: cos^2(theta) = cos(Pi/5)/(1 + cos(Pi/5)).*)

(* ::Text:: *)
(*The state we will feed into every context is the cone axis itself, psi = (0,0,1). This is the spin-0-along-the-symmetry-axis state, and it maximizes the violation: each projector onto l_i then has expectation exactly 1/Sqrt[5], and the KCBS correlation sum reaches its quantum minimum 5 - 4 Sqrt[5] ~ -3.944, against the noncontextual bound -3.*)

(* ::Input:: *)
c2 = Cos[Pi/5]/(1 + Cos[Pi/5]);
vecs = N @ Table[{Sqrt[1 - c2] Cos[4 Pi i/5], Sqrt[1 - c2] Sin[4 Pi i/5], Sqrt[c2]},
                 {i, 0, 4}];
psi = {0., 0., 1.};

(* ::Text:: *)
(*Verification: consecutive dot products must vanish, and each squared overlap with psi must equal 1/Sqrt[5].*)

(* ::Input:: *)
{Chop @ Table[vecs[[k]] . vecs[[Mod[k, 5] + 1]], {k, 5}],
 (vecs . psi)^2, N[1/Sqrt[5]]}

(* ::Section:: *)
(*3. Stage frames and the detector alternation*)

(* ::Text:: *)
(*Here is the part of the experiment that the code alone would not explain. At stage k, two detectors monitor two of the three modes; asking "did detector X click" realizes the dichotomic observable A = 1 - 2|l><l| for the direction l assigned to that detector (click -> -1). Crucially, Lapkiewicz et al. alternate which detector carries the observable shared with the previous stage: stage 1 measures (A1 up, A2 down); stage 2 keeps A2 physically untouched on the lower detector and replaces the upper one with A3; stage 3 keeps A3 up and brings A4 down; and so on. This alternation is what lets them claim that the shared observable is the identical physical measurement in both of its contexts - the noncontextuality assumption is enforced by construction, not postulated.*)

(* ::Text:: *)
(*We encode each stage as an orthonormal frame: row 1 = direction on the upper detector, row 2 = lower detector, row 3 = the remaining mode (their cross product, which also fixes right-handedness so that every frame is a proper rotation). The transformation between consecutive stages is then T_k = V_{k+1} . Transpose[V_k], and the alternation guarantees T_k is a two-level (Givens) rotation: it acts on exactly two modes and leaves the shared detector's mode strictly alone. Physically T_k is a beam splitter / wave-plate pair; in circuit language, a two-level unitary.*)

(* ::Input:: *)
frame[a_, b_] := {a, b, Cross[a, b]};
stageFrames = {frame[vecs[[1]], vecs[[2]]],   (* ctx1: A1 up, A2 down *)
               frame[vecs[[3]], vecs[[2]]],   (* ctx2: A3 up, A2 down *)
               frame[vecs[[3]], vecs[[4]]],   (* ctx3: A3 up, A4 down *)
               frame[vecs[[5]], vecs[[4]]],   (* ctx4: A5 up, A4 down *)
               frame[vecs[[5]], vecs[[1]]]};  (* ctx5: A5 up, A1 down *)
Ts = Table[stageFrames[[k + 1]] . Transpose[stageFrames[[k]]], {k, 4}];

(* ::Text:: *)
(*The two-level claim is falsifiable, so we check it: for each T_k, the row and the column of the shared detector must equal the corresponding identity row and column to machine precision. sharedDetector lists which detector (1 = upper, 2 = lower) is the untouched one at each step - it alternates 2,1,2,1 by the construction above.*)

(* ::Input:: *)
sharedDetector = {2, 1, 2, 1};
twoLevelDeviation = Max @ Table[Max[
   Abs[Ts[[k, sharedDetector[[k]]]]      - UnitVector[3, sharedDetector[[k]]]],
   Abs[Ts[[k, All, sharedDetector[[k]]]] - UnitVector[3, sharedDetector[[k]]]]],
  {k, 4}]

(* ::Section:: *)
(*4. Encoding A: the native qutrit circuit*)

(* ::Text:: *)
(*The circuit starts from |0>, so we need a preparation gate P whose first column is the input state expressed in the stage-1 frame, i.e. V1 . psi. Any unitary completion works because only the first column is ever used; we complete it by Gram-Schmidt against the identity and drop the vector that collapses to zero. The whole experiment is then ONE circuit, [P, T1, T2, T3, T4], and context k is its prefix of length k followed by a computational-basis measurement:*)

(* ::Text:: *)
(*|0> --[P]--*--[T1]--*--[T2]--*--[T3]--*--[T4]--*   (taps: ctx1 (A1,A2), ctx2 (A2,A3), ctx3 (A3,A4), ctx4 (A4,A5), ctx5 (A5,A1))*)

(* ::Input:: *)
prepCol = stageFrames[[1]] . psi;
P = Transpose @ Select[Orthogonalize[Join[{prepCol}, IdentityMatrix[3]]],
                       Norm[#] > .5 &];

(* ::Text:: *)
(*We attach labels to the gates (a native QuantumOperator option) so that the built-in circuit diagram is readable, and we prebuild the five prefix circuits since both pictures below will reuse them.*)

(* ::Input:: *)
qutritGates = MapThread[QuantumOperator[N @ #1, "Label" -> #2] &,
  {Join[{P}, Ts], {"P", "T1", "T2", "T3", "T4"}}];
kcbsQutritCircuit = QuantumCircuitOperator[qutritGates];
prefixes = Table[QuantumCircuitOperator[Take[qutritGates, k]], {k, 5}];

(* ::Text:: *)
(*The framework draws the circuit itself - no hand-made graphics. This single cascade on one qutrit wire IS the whole pentagon.*)

(* ::Input:: *)
kcbsQutritCircuit["Diagram"]

(* ::Text:: *)
(*Now run each prefix on |0> and read the three outcome probabilities. Expected pattern in every context: (1/Sqrt[5], 1/Sqrt[5], 1 - 2/Sqrt[5]) ~ (0.4472, 0.4472, 0.1056). The correlator follows the click convention - a click on detector 1 or 2 means the pair's product is -1; no click on either means both took +1 - hence <A_a A_b> = p3 - p1 - p2, and the five correlators must sum to the quantum minimum 5 - 4 Sqrt[5].*)

(* ::Input:: *)
contextProbs = Table[
  Values @ prefixes[[k]][QuantumState[{1, 0, 0}, 3]]["Probabilities"], {k, 5}]

(* ::Input:: *)
corrQutrit = (#[[3]] - #[[1]] - #[[2]]) & /@ contextProbs;
{SQutrit = Total[corrQutrit], N[5 - 4 Sqrt[5]]}

(* ::Section:: *)
(*5. Which picture? Heisenberg, and why*)

(* ::Text:: *)
(*Every framework object carries a native "Picture" tag - our circuit reports the default:*)

(* ::Input:: *)
kcbsQutritCircuit["Picture"]

(* ::Text:: *)
(*So the Schrodinger picture is what we have used so far: the state evolves down the cascade, the detectors stay fixed. It is the right picture for computing outcome statistics, but notice what it CANNOT show. By the pentagram symmetry, the evolved state looks the same at every tap - the same (0.447, 0.447, 0.106) bar chart five times (see the closing cell of this section). The state view is blind to the one thing the KCBS argument is about: which observable is being measured, and whether it is the same observable when it reappears in the next context. Contextuality is a statement about observables; the natural home of observables is the Heisenberg picture.*)

(* ::Text:: *)
(*In the Heisenberg picture the input state |0> never moves; instead each fixed detector projector D_d = |d><d| is pulled back through the circuit prefix, Pi = C_k^dagger . D_d . C_k. The framework composes this natively - Dagger and operator application, no hand-rolled conjugation:*)

(* ::Input:: *)
detector[d_] := QuantumOperator[DiagonalMatrix[N @ UnitVector[3, d]],
                                "Label" -> Row[{"D", d}]];
heis[k_, d_] := Chop[
  (prefixes[[k]]["Dagger"] @ detector[d] @ prefixes[[k]])["MatrixRepresentation"]];

(* ::Text:: *)
(*The five physical observables of the pentagon are now concrete operators: A1 is the upper detector of stage 1, A2 the lower detector of stage 1, A3 the upper of stage 2, A4 the lower of stage 3, A5 the upper of stage 4.*)

(* ::Input:: *)
observables = <|1 -> heis[1, 1], 2 -> heis[1, 2], 3 -> heis[2, 1],
                4 -> heis[3, 2], 5 -> heis[4, 1]|>;

(* ::Text:: *)
(*Three statements that constitute the KCBS test now become computable operator identities.*)

(* ::Text:: *)
(*(i) Noncontextuality by construction: the shared observable, pulled back from its two different contexts, is the SAME operator - A2 seen from stage 1 equals A2 seen from stage 2, and so on around the cycle. This is the Heisenberg-picture form of the claim that Lapkiewicz et al. defended against their critics.*)

(* ::Input:: *)
sharedIdentity = Max[{Max @ Abs[heis[1, 2] - heis[2, 2]],
                      Max @ Abs[heis[2, 1] - heis[3, 1]],
                      Max @ Abs[heis[3, 2] - heis[4, 2]],
                      Max @ Abs[heis[4, 1] - heis[5, 1]]}]

(* ::Text:: *)
(*(ii) Closure of the pentagram: the lower detector of stage 5, pulled back through the FULL cascade, is exactly the A1 we started from. This is the identity the experiment could not realize physically - their fifth-stage measurement was a different apparatus, hence the sixth observable A1' and the epsilon = 0.081 correction to the bound. In the ideal circuit the pentagon closes to machine precision; the deviation below is the circuit-model analogue of their epsilon.*)

(* ::Input:: *)
pentagramClosure = Max @ Abs[heis[5, 2] - heis[1, 1]]

(* ::Text:: *)
(*(iii) The KCBS structure itself, stated frame-independently: neighbouring observables are orthogonal (Tr[Pi_i . Pi_(i+1)] = 0, which is why they are co-measurable), and every observable has expectation 1/Sqrt[5] in the input state (the [[1,1]] matrix element, since the Heisenberg state is |0>). From these Heisenberg data alone the KCBS sum follows, with no reference to any evolved state: <A_i A_(i+1)> = 1 - 2(p_i + p_(i+1)) because the cross term vanishes by orthogonality.*)

(* ::Input:: *)
cyclicOrthogonality = Max @ Table[
  Abs @ Tr[observables[i] . observables[Mod[i, 5] + 1]], {i, 5}]

(* ::Input:: *)
heisExpectations = Table[observables[i][[1, 1]], {i, 5}]

(* ::Input:: *)
SHeis = Sum[1 - 2 (heisExpectations[[i]] + heisExpectations[[Mod[i, 5] + 1]]), {i, 5}]

(* ::Text:: *)
(*A visual summary of the five pulled-back observables (MatrixPlot is core Wolfram Language). Each is a real rank-1 projector; the reader can literally see the pentagon as five 3x3 matrices.*)

(* ::Input:: *)
Grid[{Table[MatrixPlot[observables[i], PlotLabel -> Row[{"A", i}],
            FrameTicks -> None], {i, 5}]}]

(* ::Text:: *)
(*And the promised Schrodinger complement - the native ProbabilityPlot of the evolved state at the five taps. All five are identical, which is exactly the point: the state view shows the symmetry, the Heisenberg view shows the physics.*)

(* ::Input:: *)
Grid[{Table[prefixes[[k]][QuantumState[{1, 0, 0}, 3]]["ProbabilityPlot"], {k, 5}]}]

(* ::Section:: *)
(*6. Where the pentagon actually lives: the event graph (Cabello's Figs. 1 and 2)*)

(* ::Text:: *)
(*A natural objection at this point: the circuit diagram of Section 4 is a single wire - a chain of boxes - so where did the pentagon go? The answer is that a circuit diagram and the pentagon are diagrams of two DIFFERENT things. A circuit diagram is a time diagram: wires are subsystems, boxes are dynamics. This experiment has exactly one indivisible qutrit, so one wire is not a limitation - it is the headline claim of the Nature paper's title ("an indivisible quantum system": no parts, no entanglement, nothing to draw a second wire for). CHSH needs two wires because it is a two-party test; KCBS deliberately does not. The pentagon lives elsewhere: in the logical structure of measurement EVENTS - which outcomes exclude which. That structure has its own canonical picture, the exclusivity graph of Cabello's "Simple Explanation of the Quantum Violation of a Fundamental Inequality", PRL 110, 060402 (2013): its Fig. 1 is the pentagon of events, and its Fig. 2 is the two-copy construction that explains WHY the quantum value stops at Sqrt[5]. This section implements both.*)

(* ::Text:: *)
(*The events are e_i = "the detector carrying A_i clicks" (each has probability 1/Sqrt[5] on our input state). Two events are exclusive when a single joint measurement can distinguish them - for sharp measurements, when their projectors are orthogonal. Crucially, we do not postulate the graph: we DERIVE it from the circuit, drawing an edge exactly where the Heisenberg observables of Section 5 satisfy Tr[Pi_i . Pi_j] = 0. The result must be - and is - the pentagon C5.*)

(* ::Input:: *)
exclusivityEdges = Select[Subsets[Range[5], {2}],
  Abs @ Tr[observables[#[[1]]] . observables[#[[2]]]] < 10^-12 &];
eventGraph = Graph[Range[5], UndirectedEdge @@@ exclusivityEdges,
  VertexCoordinates -> CirclePoints[5],
  VertexLabels -> Table[i -> Placed[Row[{"e", i}], Center], {i, 5}],
  VertexSize -> .25];
{exclusivityEdges, IsomorphicGraphQ[eventGraph, CycleGraph[5]]}

(* ::Text:: *)
(*This is the analogue of Cabello's Fig. 1 - drawn from measured operator identities, not from an assumption:*)

(* ::Input:: *)
eventGraph

(* ::Text:: *)
(*Now the three theories the reader knows from the KCBS literature - classical, quantum, and "exclusivity-only" - become three graph invariants of this one picture, all computed with built-in functions. A noncontextual (classical) model assigns 0/1 to the events with no two adjacent ones true, so its maximum for the sum of the five probabilities is the independence number alpha(C5) = 2. Quantum mechanics reaches the Lovasz number theta(C5) = Sqrt[5]. A theory constrained ONLY by exclusivity (every clique of pairwise exclusive events has total probability at most 1 - Specker's principle applied to one copy) can reach the fractional packing number alpha*(C5) = 5/2. The hierarchy 2 < Sqrt[5] < 5/2 is the whole story of the KCBS inequality in three numbers. Two side remarks the code cannot make: Specker's triangle (three pairwise exclusive events) is not available as a test in quantum mechanics, because for sharp measurements pairwise compatibility implies joint compatibility - which is exactly why the pentagon is the SMALLEST usable cycle; and CHSH is the same graph formalism with a different graph (8 events, alpha = 3, theta = 2 + Sqrt[2]).*)

(* ::Input:: *)
fractionalPacking = Total @ Values @ LinearOptimization[-Total[Array[w, 5]],
   Join[Table[w[i] + w[Mod[i, 5] + 1] <= 1, {i, 5}], Table[w[i] >= 0, {i, 5}]],
   Array[w, 5]];
bounds = <|"classical: independence number" -> GraphData[{"Cycle", 5}, "IndependenceNumber"],
           "quantum: Lovasz number"         -> GraphData[{"Cycle", 5}, "LovaszNumber"],
           "exclusivity-only: fractional packing" -> fractionalPacking|>

(* ::Text:: *)
(*Our circuit does not merely respect the quantum bound - it sits exactly on it: the five Heisenberg expectations sum to the Lovasz number.*)

(* ::Input:: *)
{quantumEventSum = Total[heisExpectations], N @ Sqrt[5]}

(* ::Text:: *)
(*Cabello's Fig. 2: why Sqrt[5] and not more? Apply the exclusivity principle to TWO INDEPENDENT COPIES of the experiment - and here, at last, a second wire appears in the circuit for a genuine physical reason. Each event e_i is located at a stage and a detector of the cascade; a product event (e_i on copy A, e_j on copy B) is read from a two-qutrit circuit running the two prefixes in parallel. The framework's MatrixRepresentation property collapses each prefix to a single labelled gate, and placing 3x3 matrices on wires {1} and {2} gives a two-qudit circuit for free.*)

(* ::Input:: *)
stageOf = {1, 1, 2, 3, 4}; detectorOf = {1, 2, 1, 2, 1};
copyOp[k_, wire_] := QuantumOperator[prefixes[[k]]["MatrixRepresentation"], {wire},
                                     "Label" -> Row[{"C", k}]];
doubleCircuit[k_, m_] := QuantumCircuitOperator[{copyOp[k, 1], copyOp[m, 2]}];
in2 = QuantumState[Normal @ SparseArray[{1 -> 1.}, 9], {3, 3}];

(* ::Text:: *)
(*The native diagram of one such double experiment - the "missing second dimension", which is not a second mode of the qutrit but a second copy of the whole black box:*)

(* ::Input:: *)
doubleCircuit[1, 2]["Diagram"]

(* ::Text:: *)
(*All 25 joint event probabilities are (1/Sqrt[5])^2 = 1/5, read off by running the appropriate prefix pair and picking the joint outcome of the two detectors:*)

(* ::Input:: *)
jointEventProb = Table[
  Values[doubleCircuit[stageOf[[i]], stageOf[[j]]][in2]["Probabilities"]][[
    3 (detectorOf[[i]] - 1) + detectorOf[[j]]]], {i, 5}, {j, 5}];
MinMax[jointEventProb]

(* ::Text:: *)
(*The 25 product events partition into 5 "pentads" {(i, 2i+j)}: within each pentad any two members are exclusive, because two distinct events either sit on adjacent vertices in the first copy, or - if they are non-adjacent there (difference of 2) - their second coordinates differ by 4, i.e. by 1 modulo 5, making them adjacent in the second copy. The exclusivity principle therefore caps every pentad's total probability at 1. Quantum mechanics SATURATES all five caps exactly - and that is the explanation: 5 pentads x 1 = 5 for two copies forces at most Sqrt[5] per copy.*)

(* ::Input:: *)
pentads = Table[Table[{i, Mod[2 i + j, 5]} + 1, {i, 0, 4}], {j, 0, 4}];
pentadSums = Table[Total[jointEventProb[[#[[1]], #[[2]]]] & /@ s], {s, pentads}]

(* ::Input:: *)
adjQ[{i_, j_}, {ip_, jp_}] := Or[Mod[i - ip, 5] == 1, Mod[ip - i, 5] == 1,
                                 Mod[j - jp, 5] == 1, Mod[jp - j, 5] == 1];
{pentadsExclusive = AllTrue[pentads, Function[s, AllTrue[Subsets[s, {2}], adjQ @@ # &]]],
 pentadsPartition = Sort[Flatten[pentads, 1]] === Sort[Tuples[Range[5], 2]]}

(* ::Text:: *)
(*The exclusivity graph of the product events is the conormal (OR) graph product of two pentagons - a built-in - and highlighting the five pentads gives the analogue of Cabello's Fig. 2: 25 events, 5 colour classes, each class a clique that quantum mechanics fills to exactly probability 1.*)

(* ::Input:: *)
gg = GraphProduct[CycleGraph[5], CycleGraph[5], "Conormal"];
HighlightGraph[gg, MapThread[Style[#1, #2] &, {pentads, ColorData[97] /@ Range[5]}],
  GraphLayout -> "CircularEmbedding", VertexSize -> .5]

(* ::Section:: *)
(*7. The KCBS game: three parties, and what beating 2 means*)

(* ::Text:: *)
(*The graph invariants of Section 6 have an operational, game-like reading, and it makes the "difference from classical" tangible. The game has three parties. A REFEREE draws one of the five edges (i, i+1) uniformly at random. ALICE receives the edge - the context - and must output a bit for each of its two vertices, subject to the exclusivity rule: never both 1 (one bit per vertex, 1 = "my event fired"). BOB receives only ONE endpoint of that edge, chosen at random, and must output its bit WITHOUT knowing which edge was drawn. The round is won if (a) Bob agrees with Alice on the shared vertex, and (b) Alice's two bits differ. Bob is the noncontextuality police: since he does not know the context, his answers define a context-free assignment of bits to vertices, and consistency forces Alice to play that same global assignment. Requirement (b) then asks the assignment to alternate 0,1 around the cycle - and an odd cycle cannot be 2-coloured. Classically at least one edge must fail.*)

(* ::Text:: *)
(*Enumerating all deterministic strategies makes the classical values exact: on the pentagon the best global assignment (e.g. 0,1,0,1,0 - the alternating chain "node 1, node 2: 0,1; node 2, node 3: 1,0; ..." that breaks only on the closing edge) wins 4 rounds in 5, and its event-sum is the independence number 2. On the triangle C3 the same logic gives 2/3 - and, remarkably, quantum mechanics CANNOT beat 2/3 there (Specker's triangle again: theta(C3) = 1, no quantum advantage on the smallest cycle). Probabilistic mixtures of assignments - weights like 1*0.3 + 0*0.7 on a node - change nothing, because both the win rate and the event-sum are linear in the strategy, and a convex mixture cannot exceed the best vertex of the polytope.*)

(* ::Input:: *)
assignments = Tuples[{0, 1}, 5];
winRate[a_, n_] := Count[Table[a[[i]] != a[[Mod[i, n] + 1]], {i, n}], True]/n;
{classicalWinC5 = Max[winRate[#, 5] & /@ assignments],
 classicalWinC3 = Max[winRate[#, 3] & /@ Tuples[{0, 1}, 3]],
 classicalMaxSum = Max[Total /@ Select[assignments,
    AllTrue[Table[#[[i]] #[[Mod[i, 5] + 1]] == 0, {i, 5}], TrueQ] &]]}

(* ::Text:: *)
(*Now the "classical circuit" that seems to beat the bound: a box that, whenever an edge is asked, flips a fair coin and answers (0,1) or (1,0). It wins EVERY round of the anticorrelation part, and each node, conditioned on being asked, answers 1 half of the time - so the sum of node expectations drifts to 5 x 1/2 = 5/2, visibly past the classical 2 and even past the quantum Sqrt[5]. The Monte Carlo cell below measures exactly these distributions for three strategies: the best deterministic assignment, the 0.3/0.7 weighted mixture, and the coin box.*)

(* ::Input:: *)
SeedRandom[20260709];
edges = Table[{k, Mod[k, 5] + 1}, {k, 5}];
playRound[strategy_] := Module[{e = RandomChoice[edges], v},
  v = strategy[e];
  {e, v, v[[1]] != v[[2]]}];
detStrategy = With[{a = {0, 1, 0, 1, 0}}, Function[e, a[[e]]]];
mixStrategy = Function[e, RandomChoice[{.3, .7} -> {{0, 1, 0, 1, 0}, {1, 0, 1, 0, 0}}][[e]]];
coinBox = Function[e, RandomChoice[{{1, 0}, {0, 1}}]];
gameStats[strategy_, trials_ : 20000] := Module[{rounds, hits, ones},
  rounds = Table[playRound[strategy], {trials}];
  hits = Association @ Table[i -> 0, {i, 5}]; ones = Association @ Table[i -> 0, {i, 5}];
  Do[MapThread[(hits[#1]++; ones[#1] += #2) &, {r[[1]], r[[2]]}], {r, rounds}];
  <|"winRate" -> N @ Mean[Boole @ rounds[[All, 3]]],
    "nodeMarginals" -> N[Values[ones]/Values[hits]],
    "sumOfNodeExpectations" -> N @ Total[Values[ones]/Values[hits]]|>];
<|"deterministic" -> gameStats[detStrategy], "weighted 0.3/0.7" -> gameStats[mixStrategy],
  "coin box (0,1)/(1,0)" -> gameStats[coinBox]|>

(* ::Text:: *)
(*So where is the swindle? The coin box does not get caught by node marginals (each is a clean 1/2) - it gets caught by BOB. Its answers are created only when the edge is known, so no context-free assignment reproduces them round by round; in the three-party game its consistency with any Bob drops, and the exclusivity-only value of the game, 1, is exactly the fractional-packing bound 5/2 in disguise. The dictionary is one line: for context-independent marginals, P(win) = 2/5 x (sum of node expectations). It maps the three Section 6 bounds onto three winning probabilities - classical 2 -> 4/5, quantum Sqrt[5] -> 2/Sqrt[5] ~ 0.894, exclusivity-only 5/2 -> 1.*)

(* ::Input:: *)
{quantumWin = Mean[(#[[1]] + #[[2]]) & /@ contextProbs], N[2/Sqrt[5]],
 winFromBound /@ <|"classical" -> 2, "quantum" -> Sqrt[5.], "exclusivity-only" -> 5/2|> /.
   winFromBound -> Function[b, 2 b/5]}

(* ::Text:: *)
(*The quantum strategy realizing 0.894 is our circuit itself: Alice runs the prefix of the drawn context and reports which detector clicked; Bob, thanks to the compatibility verified in Section 5 (and demonstrated dynamically in Section 10), measures his single observable sequentially on the same carrier and agrees with Alice with certainty. Quantum mechanics thus wins strictly more than any classical team - 0.894 versus 0.8 - while remaining strictly below the logically conceivable 1: contextual, but only as contextual as exclusivity allows.*)

(* ::Section:: *)
(*8. Generalizing beyond the pentagon: semidefinite programming*)

(* ::Text:: *)
(*Section 6 read the quantum value of C5 off GraphData. That works for catalogued graphs only. The generalization tool is the Lovasz number itself, which is a semidefinite program - maximize the total of a positive-semidefinite, unit-trace matrix that vanishes on the edges - and SemidefiniteOptimization solves it for ANY exclusivity graph. This is the machine that turns an arbitrary contextuality scenario into a number: draw the exclusivity graph of your events, feed it in, and out comes the maximal quantum value of the sum of event probabilities.*)

(* ::Input:: *)
lovaszTheta[g_Graph] := Module[{h = IndexGraph[g], n, x, X, vars, cons, sol},
  n = VertexCount[h];
  X = Table[If[i <= j, x[i, j], x[j, i]], {i, n}, {j, n}];
  vars = Flatten[Table[x[i, j], {i, n}, {j, i, n}]];
  cons = Join[{Tr[X] == 1, VectorGreaterEqual[{X, 0}, {"SemidefiniteCone", n}]},
    (x[#[[1]], #[[2]]] == 0) & /@ (Sort /@ (List @@@ EdgeList[h]))];
  sol = SemidefiniteOptimization[-Total[X, 2], cons, vars];
  Total[X, 2] /. sol];

(* ::Text:: *)
(*Four checks, from the known to the new. The pentagon reproduces Sqrt[5]. The 7-cycle gives the next member of the odd-cycle family, matching the analytic formula n cos(Pi/n)/(1+cos(Pi/n)) - these are the KCBS generalizations tested in higher-dimensional experiments. The 8-vertex circulant graph Ci(8;1,4) is the exclusivity graph of CHSH, and the SDP returns the Tsirelson bound in disguise, 2 + Sqrt[2] - one algorithm covering both contextuality and nonlocality. And the 25-vertex conormal product of two pentagons returns 5 = Sqrt[5]^2, which is Lovasz's multiplicativity theorem confirming numerically the Fig. 2 saturation of Section 6.*)

(* ::Input:: *)
<|"C5" -> {lovaszTheta[CycleGraph[5]], Sqrt[5.]},
  "C7" -> {lovaszTheta[CycleGraph[7]], N[7 Cos[Pi/7]/(1 + Cos[Pi/7])]},
  "CHSH: Ci(8;1,4)" -> {lovaszTheta[CirculantGraph[8, {1, 4}]], N[2 + Sqrt[2]]},
  "C5 conormal C5" -> {lovaszTheta[GraphProduct[CycleGraph[5], CycleGraph[5], "Conormal"]], 5.}|>

(* ::Text:: *)
(*Two cheaper routes to the same quantum maximum deserve a cell, because they answer "what factor do we get" from the operator side rather than the graph side. The sum of the five circuit-derived projectors is a concrete 3x3 matrix, and the largest value of psi.M.psi over unit states is its top eigenvalue - obtainable exactly with Eigenvalues, or numerically with NMaximize as a sanity check that needs no graph theory at all. Both give Sqrt[5] again: three independent computations (graph SDP, operator norm, direct optimization) triangulating one number.*)

(* ::Input:: *)
MM = Total[Table[observables[i], {i, 5}]];
{Max[Eigenvalues[MM]],
 Quiet @ First @ NMaximize[{{a, b, c} . MM . {a, b, c}, a^2 + b^2 + c^2 == 1}, {a, b, c}],
 Sqrt[5.]}

(* ::Section:: *)
(*9. Encoding B: the two-qubit biphoton version*)

(* ::Text:: *)
(*Why a second encoding? Because gate hardware speaks qubits, and because this encoding is not an artifice: it is the original KCBS proposal. Two indistinguishable photons in one spatial mode must be polarization-symmetric, and the symmetric subspace of two qubits is exactly 3-dimensional - a qutrit carrying the spin-1 representation literally. On a quantum computer we substitute two qubits for the two photons. The three-dimensional physics happens in the triplet; the fourth state, the singlet, is decoupled and serves as a built-in error flag - ideal evolution never populates it.*)

(* ::Text:: *)
(*The dictionary: the Cartesian direction states are |x> = (|11> - |00>)/Sqrt[2], |y> = -I(|00> + |11>)/Sqrt[2], |z> = (|01> + |10>)/Sqrt[2] (the phases make rotations act on x,y,z exactly as SO(3) matrices - a convention, verified by the final numbers). A rotation R in SO(3) lifts to the collective gate u(x)u with u in SU(2) from the double cover; the global sign ambiguity of u is harmless precisely because u enters twice. We extract u from R via ZYZ Euler angles because EulerAngles is a Wolfram built-in and the ZYZ product of two-level rotations is numerically stable.*)

(* ::Input:: *)
xState = {-1, 0, 0, 1}/Sqrt[2.];  yState = -I {1, 0, 0, 1}/Sqrt[2.];
zState = {0, 1, 1, 0}/Sqrt[2.];   sState = {0, 1, -1, 0}/Sqrt[2.];
Ddis = Conjugate /@ {xState, yState, zState, sState};

(* ::Text:: *)
(*Ddis is the "disentangler": the fixed 4x4 basis change sending |x>,|y>,|z>,|singlet> to |00>,|01>,|10>,|11>, so that a plain computational measurement of both qubits reads out the three modes - outcome 00 = click on l_k, 01 = click on l_(k+1), 10 = third mode, 11 = singlet leakage (must never fire).*)

(* ::Input:: *)
uz[t_] := DiagonalMatrix[{Exp[-I t/2], Exp[I t/2]}];
uy[t_] := {{Cos[t/2], -Sin[t/2]}, {Sin[t/2], Cos[t/2]}};
uFromSO3[R_] := Module[{ea = EulerAngles[R]}, uz[ea[[1]]] . uy[ea[[2]]] . uz[ea[[3]]]];

(* ::Text:: *)
(*One parametrized circuit covers the whole pentagon; the five contexts differ only in the setting of the collective rotation. Preparation is three elementary gates: X on qubit 2, H on qubit 1, CNOT - this builds (|01> + |10>)/Sqrt[2], which is |z>, i.e. exactly the cone-axis state psi of Section 2 in the two-qubit dictionary. The context rotation is stageFrames[[k]] itself: the SO(3) matrix whose rows send l_k to x, l_(k+1) to y, and the leftover mode to z.*)

(* ::Input:: *)
contextCircuit2q[R_] := Module[{u = uFromSO3[R]},
  QuantumCircuitOperator[{
    QuantumOperator["X", {2}], QuantumOperator["H", {1}],
    QuantumOperator["CNOT", {1, 2}],                      (* prep |z> *)
    QuantumOperator[u, {1}, "Label" -> "u"],              (* collective *)
    QuantumOperator[u, {2}, "Label" -> "u"],              (*   u (x) u  *)
    QuantumOperator[Ddis, {1, 2}, "Label" -> "D"]}]];     (* disentangler *)

(* ::Text:: *)
(*The native diagram of one context; note the visual signature of the encoding - the identical gate u on both wires, which is the circuit-level meaning of "collective spin-1 rotation".*)

(* ::Input:: *)
contextCircuit2q[stageFrames[[1]]]["Diagram"]

(* ::Input:: *)
probs2q = Table[
  Values @ contextCircuit2q[stageFrames[[k]]][
             QuantumState["Register", 2]]["Probabilities"], {k, 5}]

(* ::Input:: *)
corr2q = (#[[3]] - #[[1]] - #[[2]]) & /@ probs2q;
{S2q = Total[corr2q], singletLeakage = Max[probs2q[[All, 4]]]}

(* ::Section:: *)
(*10. Time-like scenarios: repeated measurements inside the circuit*)

(* ::Text:: *)
(*Everything so far measured once, at the end. But the gate model allows what destructive photodetection forbade: a nondemolition measurement in the MIDDLE of the circuit, with the carrier surviving into further gates and further measurements - time-like sequences of measurement, gate, measurement. One subtlety decides whether this is done honestly: measuring the full 3-outcome basis mid-circuit would collapse MORE than the observable A_i (it would also resolve the other two modes) and thereby disturb the compatible partner. The sharp test requires the BINARY measurement of A_i alone - the projector versus its complement - which the framework provides by passing a two-element projector list to QuantumMeasurementOperator.*)

(* ::Input:: *)
binMeas[proj_, order_] := QuantumMeasurementOperator[
  {proj, IdentityMatrix[3] - proj}, order];

(* ::Text:: *)
(*First demonstration: the sequential correlator. Measure A2 (binary), then apply the transformation T1, then measure A3 (binary) - measurement, gate, measurement on one carrier. Because A2 and A3 are compatible and the measurements are sharp, the intermediate collapse must not change the statistics: the sequential correlator has to equal the joint-measurement value 1 - 4/Sqrt[5] of Section 4. It does, to machine precision - this is the circuit-level content of "co-measurable" and precisely the property that the trapped-ion KCBS tests certify and that the critics of the photonic test demanded. Outcome bookkeeping: effect 1 is the projector ("click", value -1), effect 2 its complement (value +1).*)

(* ::Input:: *)
seqProbs = QuantumCircuitOperator[{qutritGates[[1]],
    binMeas[DiagonalMatrix[{0., 1., 0.}], {1}],
    qutritGates[[2]],
    binMeas[DiagonalMatrix[{1., 0., 0.}], {1}]}][
  QuantumState[{1, 0, 0}, 3]]["Probabilities"];
seqOutcomes = Keys[seqProbs][[All, 1]] /. Subscript[_, k_] :> k;
seqCorrelator = Total[MapThread[
  (If[#1[[1]] == 1, -1, 1] If[#1[[2]] == 1, -1, 1]) #2 &,
  {seqOutcomes, Values[seqProbs]}]];
{seqCorrelator, corrQutrit[[2]]}

(* ::Text:: *)
(*Second demonstration: repeatability, the operational definition of a sharp measurement. Measuring A2 twice in a row must give the same outcome with certainty; and in the A-B-A pattern - A2, then the compatible A3 (expressed in the stage-1 frame by the Heisenberg pullback through T1), then A2 again - the two A2 outcomes must still agree, proving the intermediate B did not disturb A. Both disagreement probabilities come out exactly 0. This is the certification that the ion experiments perform and that Lapkiewicz et al. could only argue by construction; in the circuit model it is two cells.*)

(* ::Input:: *)
abaProbs = QuantumCircuitOperator[{qutritGates[[1]],
    binMeas[DiagonalMatrix[{0., 1., 0.}], {1}],
    binMeas[N[Transpose[Ts[[1]]] . DiagonalMatrix[{1., 0., 0.}] . Ts[[1]]], {1}],
    binMeas[DiagonalMatrix[{0., 1., 0.}], {1}]}][
  QuantumState[{1, 0, 0}, 3]]["Probabilities"];
abaDisagreement = Chop @ Total[MapThread[
  If[#1[[1]] != #1[[3]], #2, 0] &,
  {Keys[abaProbs][[All, 1]] /. Subscript[_, k_] :> k, Values[abaProbs]}]];
repProbs = QuantumCircuitOperator[{qutritGates[[1]],
    binMeas[DiagonalMatrix[{0., 1., 0.}], {1}],
    binMeas[DiagonalMatrix[{0., 1., 0.}], {1}]}][
  QuantumState[{1, 0, 0}, 3]]["Probabilities"];
repeatDisagreement = Chop @ Total[MapThread[
  If[#1[[1]] != #1[[2]], #2, 0] &,
  {Keys[repProbs][[All, 1]] /. Subscript[_, k_] :> k, Values[repProbs]}]];
{repeatDisagreement, abaDisagreement}

(* ::Section:: *)
(*11. The other face of non-classicality: Wigner negativity*)

(* ::Text:: *)
(*The framework ships a second, independent language for non-classicality, showcased by one of its developers in the Wolfram Community post "On quantum amplitudes, correlations and negativity" (N. Murzin, https://community.wolfram.com/groups/-/m/t/3026423): quasi-probability representations. QuantumWignerTransform rewrites a state as a discrete Wigner function - a quasi-probability distribution over a 3x3 phase space - with QuantumWeylTransform, QuantumPhaseSpaceTransform and QuantumWignerMICTransform as siblings. A distribution, except that it may go NEGATIVE, and negativity is a non-classicality certificate in its own right: for odd dimensions, a pure state has a non-negative discrete Wigner function exactly when it is a stabilizer state (Gross's theorem). One cell suffices to see both sides. The circuit's input |0> is a stabilizer state: its Wigner function is non-negative, concentrated on a single phase-space line. The prepared KCBS state - one gate later - already carries two negative points: the preparation P is precisely the non-stabilizer step of the circuit.*)

(* ::Input:: *)
wignerInput = Quiet @ Chop[Re @ Values @ QuantumWignerTransform[
    QuantumState[{1, 0, 0}, 3]]["Amplitudes"]];
wignerKCBS = Chop[Re @ Values @ QuantumWignerTransform[
    prefixes[[1]][QuantumState[{1, 0, 0}, 3]]]["Amplitudes"]];
Grid[{{MatrixPlot[Partition[wignerInput, 3], PlotLabel -> "input |0>", FrameTicks -> None],
       MatrixPlot[Partition[wignerKCBS, 3], PlotLabel -> "KCBS state", FrameTicks -> None]}}]

(* ::Input:: *)
{wignerMinKCBS = Min[wignerKCBS],
 wignerNegativity = -Total[Select[wignerKCBS, Negative]],
 Total[wignerKCBS]}

(* ::Text:: *)
(*A closing conceptual point, and it is the deepest one in this essay. Wigner negativity and contextuality are two DIFFERENT certificates of non-classicality, and their relation is subtle: for many qudits probed by stabilizer (Pauli) measurements they are provably equivalent (Delfosse, Okay, Bermejo-Vega, Browne, Raussendorf, New J. Phys. 19, 123024 (2017)) - but for a SINGLE qutrit they come apart: there exist Wigner-negative single-qutrit states whose Pauli-measurement statistics still admit a noncontextual hidden-variable model. Our state wears both badges at once, each relative to its own measurement set: negative Wigner function with respect to the stabilizer structure of the mode basis (this section), and KCBS contextuality with respect to the pentagon projectors - which are NOT Pauli measurements (the rest of this essay). Neither certificate implies the other here. Non-classicality is never a property of a state alone; it is a property of a state together with the measurements one is allowed to ask about - which is, in the end, the same lesson the event graph of Section 6 taught for contextuality itself.*)

(* ::Section:: *)
(*12. Verification summary*)

(* ::Text:: *)
(*A single machine-checkable verdict, covering both pictures and the event-graph layer: the Schrodinger-side sums of both encodings must reproduce 5 - 4 Sqrt[5], the Heisenberg sum must agree, the cascade gates must be strictly two-level, the shared observables must be context-independent, the pentagram must close (the ideal A1' = A1), neighbours must be orthogonal, the singlet must stay empty, the derived event graph must be the pentagon, the quantum event sum must hit the Lovasz number, and all five pentads of the two-copy construction must saturate at 1.*)

(* ::Input:: *)
KCBSVerification = <|
  "S_qutrit" -> SQutrit, "S_2qubit" -> S2q, "S_Heisenberg" -> SHeis,
  "exact" -> N[5 - 4 Sqrt[5], 10],
  "twoLevelDeviation" -> twoLevelDeviation,
  "sharedObservableIdentity" -> sharedIdentity,
  "pentagramClosure" -> pentagramClosure,
  "cyclicOrthogonality" -> cyclicOrthogonality,
  "singletLeakage" -> singletLeakage,
  "eventGraphIsPentagon" -> IsomorphicGraphQ[eventGraph, CycleGraph[5]],
  "graphBounds" -> bounds,
  "quantumEventSum" -> quantumEventSum,
  "pentadSaturation" -> Max @ Abs[pentadSums - 1],
  "classicalGame" -> {classicalWinC3, classicalWinC5, classicalMaxSum},
  "quantumWin" -> quantumWin,
  "thetaSDP_C5" -> lovaszTheta[CycleGraph[5]],
  "seqCorrelator" -> seqCorrelator,
  "repeatDisagreement" -> repeatDisagreement,
  "abaDisagreement" -> abaDisagreement,
  "wignerMinKCBS" -> wignerMinKCBS,
  "wignerNegativity" -> wignerNegativity,
  "OK" -> And[Abs[SQutrit - (5 - 4 Sqrt[5.])] < 10^-10,
              Abs[S2q - (5 - 4 Sqrt[5.])] < 10^-10,
              Abs[SHeis - (5 - 4 Sqrt[5.])] < 10^-10,
              twoLevelDeviation < 10^-12, sharedIdentity < 10^-12,
              pentagramClosure < 10^-12, cyclicOrthogonality < 10^-12,
              singletLeakage < 10^-12,
              IsomorphicGraphQ[eventGraph, CycleGraph[5]],
              Abs[quantumEventSum - Sqrt[5.]] < 10^-10,
              Max @ Abs[pentadSums - 1] < 10^-10,
              classicalWinC3 == 2/3, classicalWinC5 == 4/5, classicalMaxSum == 2,
              Abs[quantumWin - 2/Sqrt[5.]] < 10^-10,
              Abs[lovaszTheta[CycleGraph[5]] - Sqrt[5.]] < 10^-5,
              Abs[seqCorrelator - corrQutrit[[2]]] < 10^-10,
              repeatDisagreement < 10^-12, abaDisagreement < 10^-12,
              Min[wignerInput] >= 0, wignerMinKCBS < -0.1,
              Abs[Total[wignerKCBS] - 1] < 10^-10]|>

(* ::Section:: *)
(*13. Remarks: what the circuit model adds, and what it cannot claim*)

(* ::Text:: *)
(*Two closing observations that are decisions about meaning, not code. First, Section 10 delivered what destructive photodetection could not: nondemolition measurements inside the circuit, sequential contexts on one carrier, and A-B-A repeatability certifying sharpness - the very feature whose absence forced Lapkiewicz et al. to introduce the sixth observable A1' and the epsilon-corrected bound, the feature their critics demanded (Ahrens et al., Sci. Rep. 3, 2170 (2013)), and the feature trapped-ion qutrit tests deliver in the laboratory. In this essay the pentagram closure of Section 5 and the zero disagreement probabilities of Section 10 are the ideal-circuit versions of exactly those certificates.*)

(* ::Text:: *)
(*Second, an honest boundary: evaluated in a simulator, these circuits emulate the statistics of the photonic black box - the simulator itself is a classical machine that knows the context before it draws an outcome, which is precisely what noncontextual hidden-variable models are forbidden to do. Run on real gate hardware, however, the same circuits constitute a genuine contextuality test of that platform, in the lineage of the published ion and superconducting KCBS experiments.*)

(* ::Text:: *)
(*Further reading in the Wolfram ecosystem: the Wolfram Community post "On quantum amplitudes, correlations and negativity" by Nikolay Murzin (https://community.wolfram.com/groups/-/m/t/3026423) is the source of the quasi-probability toolchain that Section 11 put to work on the KCBS state; its remaining machinery (QuantumWeylTransform, QuantumWignerMICTransform, phase-space views of channels and correlations) is the natural next instrument if one wants to track how negativity flows through the cascade gate by gate. That tracking is now done in the companion note kcbs_wigner_flow.wl: negativity is created once, by P - exactly 2/Sqrt[5] - 2/3 - and conserved by every T_k at the same two phase-space cells, parked on the one mode the detectors never monitor.*)
