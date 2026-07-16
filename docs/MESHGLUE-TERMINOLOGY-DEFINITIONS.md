# Terminology Definitions — “Evaluating Black-Box Physics Through Optical Emulation” (MeshGlue essay)

These definitions appear in the published notebook
([wolframcloud.com/obj/hubertkolcz/MeshGlue-PentagonGluing](https://www.wolframcloud.com/obj/hubertkolcz/MeshGlue-PentagonGluing))
as collapsed cells placed directly beneath the paragraph where each term first appears —
click a cell's opener triangle there to expand it. This file is the canonical list, and it is
the **single place where the definitions' sources are recorded**; the notebook's own References
section deliberately lists only the works the essay itself builds on.

Every definition is written in the author's own words and anchored to one respected source —
a Stanford Encyclopedia of Philosophy entry, a standard monograph, or the original defining
paper (never a wiki) — verified against both the source and the essay's own constructions.

## Quantum Contextuality

### no-signalling (post-quantum theories)
*In-essay notation / aliases:* no signaling, no faster-than-light communication, no-signalling ceiling, exclusivity-only theories, post-quantum contextuality, PR boxes

A theory is no-signalling when one party's choice of measurement never alters another party's local statistics: for correlations p(a,b|x,y), the marginal Σ_b p(a,b|x,y) is independent of the distant setting y, and symmetrically for x. Popescu and Rohrlich showed this axiom alone does not recover quantum mechanics — no-signalling "PR boxes" reach the CHSH value S = 4, beyond the quantum bound 2√2. In contextuality the analogous minimal demand — exclusive events never both fire, nothing more — defines the post-quantum rung: on the KCBS pentagon, probability 1/2 on every event is allowed, giving the ceiling α*(C5) = 5/2, strictly above the quantum ϑ(C5) = √5.

**Source:** Popescu, S., & Rohrlich, D. (1994). Quantum nonlocality as an axiom. Foundations of Physics, 24(3), 379–385. https://doi.org/10.1007/BF02058098 — <https://doi.org/10.1007/BF02058098>

### noncontextuality / contextuality
*In-essay notation / aliases:* context-independence of outcomes, noncontextual hidden-variable model, noncontextual assignment of pre-existing ±1 values, α bound

Noncontextuality is the hypothesis that each measurement outcome reveals a pre-existing value that is independent of its context — the set of compatible measurements performed alongside it. Formally, a noncontextual hidden-variable model assigns every observable a definite value (±1 for the KCBS observables A_k = 1 − 2|v_k⟩⟨v_k|) by deterministic, context-independent assignments, together with arbitrary convex mixtures over such assignments. Every model in this class — mixtures included, which is why the bound covers all noncontextual models, not just deterministic ones — obeys Σ⟨A_k A_(k+1)⟩ ≥ −3 on the pentagon, equivalently Σp ≤ α(C5) = 2 on the event ruler. Contextuality is the violation of such bounds; the qutrit reaches 5 − 4√5 ≈ −3.944.

**Source:** Held, C. (2022). The Kochen-Specker theorem. In E. N. Zalta (Ed.), The Stanford Encyclopedia of Philosophy (Fall 2022 ed.). Stanford University. — <https://plato.stanford.edu/entries/kochen-specker/>

### entanglement
*In-essay notation / aliases:* entangled state, entangled pair, non-separable state, QuantumEntangledQ check

A joint state of two systems A and B is a product state when it factorizes as |ψ⟩ = |φA⟩ ⊗ |φB⟩ — system A in some state and system B in some state, separately. A pure state is entangled exactly when no such factorization exists; a mixed state is entangled when it is not even a probabilistic mixture of product states (not separable). The Bell pair (|00⟩+|11⟩)/√2, prepared here by H then CNOT, is entangled in this sense — the property QuantumEntangledQ certifies — and is the resource lifting the CHSH game from the classical ceiling 3/4 to cos²(π/8) ≈ 0.854, without permitting signaling: neither party's local statistics change.

**Source:** Bub, J. (2023). Quantum entanglement and information. In E. N. Zalta & U. Nodelman (Eds.), The Stanford Encyclopedia of Philosophy (Summer 2023 ed.). Metaphysics Research Lab, Stanford University. https://plato.stanford.edu/archives/sum2023/entries/qt-entangle/ — <https://plato.stanford.edu/archives/sum2023/entries/qt-entangle/>

### local hidden-variable theory
*In-essay notation / aliases:* hidden variable, shared randomness, pre-agreed joint strategy, local realistic theory

A model in which measurement statistics arise from a variable λ shared in advance from a common source (the essay's "pre-agreed, shared randomness"), with no signal exchanged between parties once measurements begin. Formally, the joint outcome probabilities must factorize: p(a, b | x, y, λ) = p(a | x, λ) · p(b | y, λ), where x, y are the local settings and a, b the outcomes; observed statistics are averages of these products over a distribution of λ independent of the setting choices. Determinism is not required — factorizability suffices. Bell showed every such model obeys inequalities, such as the CHSH bound |S| ≤ 2, that entangled quantum states violate; the single-system, noncontextual analogue is the KCBS bound Σp ≤ α(C5) = 2.

**Source:** Myrvold, W., Genovese, M., & Shimony, A. (2024). Bell's theorem. In E. N. Zalta & U. Nodelman (Eds.), The Stanford Encyclopedia of Philosophy (Spring 2024 ed.). Metaphysics Research Lab, Stanford University. https://plato.stanford.edu/archives/spr2024/entries/bell-theorem/ — <https://plato.stanford.edu/archives/spr2024/entries/bell-theorem/>

### EPR argument
*In-essay notation / aliases:* Einstein–Podolsky–Rosen (1935), EPR experiment, element of reality, completeness of quantum mechanics

The Einstein–Podolsky–Rosen (1935) argument that quantum mechanics is incomplete. EPR consider two entangled systems whose correlations let a measurement on one predict, with certainty and without disturbance, the outcome of either of two incompatible quantities on the other. By their criterion of reality — if, without disturbing a system, one can predict a quantity's value with certainty, an "element of reality" corresponds to it — both quantities are real; since no quantum state assigns both definite values simultaneously, either quantum mechanics is incomplete or distant measurements disturb one another. EPR conclude a deeper local, realistic completion should exist — the claim Bell (1964) later made experimentally testable.

**Source:** Fine, A. (2017). The Einstein-Podolsky-Rosen argument in quantum theory. In E. N. Zalta (Ed.), The Stanford Encyclopedia of Philosophy (Winter 2017 substantive revision). — <https://plato.stanford.edu/entries/qt-epr/>

### CHSH inequality
*In-essay notation / aliases:* S = E(a0,b0)+E(a0,b1)+E(a1,b0)−E(a1,b1), |S| ≤ 2, Clauser–Horne–Shimony–Holt (1969)

A Bell inequality due to Clauser, Horne, Shimony and Holt (1969) for a two-party experiment in which Alice and Bob each choose between two measurement settings (a0, a1 and b0, b1) and record ±1 outcomes. Writing E(a,b) for the expectation of the product of outcomes, form S = E(a0,b0) + E(a0,b1) + E(a1,b0) − E(a1,b1). In any local hidden-variable theory the outcomes at each setting are fixed values ±1, and for such numbers the combination can never exceed 2 in magnitude, so |S| ≤ 2. Quantum mechanics violates this: an entangled pair with optimally rotated settings gives S = 2√2 ≈ 2.828, Tsirelson's bound.

**Source:** Myrvold, W., Genovese, M., & Shimony, A. (2024). Bell's theorem. In E. N. Zalta & U. Nodelman (Eds.), The Stanford Encyclopedia of Philosophy (Spring 2024 ed.). Metaphysics Research Lab, Stanford University. — <https://plato.stanford.edu/entries/bell-theorem/>

### correlator / expectation value E(a,b)
*In-essay notation / aliases:* E(a0,b0)…E(a1,b1), 〈A_k A_(k+1)〉, correlation sum Σ, four correlators

The correlator E(a,b) is the expectation value of the product of the two ±1 measurement outcomes when the stations choose settings a and b: statistically, the average of that product over many repeated runs, so E(a,b) lies between −1 (perfect anticorrelation) and +1 (perfect correlation). Quantum mechanics computes it as ⟨ψ|A⊗B|ψ⟩ for the observables at those settings — the essay's bell.KroneckerProduct[a,b].bell. Bell-type quantities are sums of correlators: CHSH uses S = E(a0,b0) + E(a0,b1) + E(a1,b0) − E(a1,b1), with |S| ≤ 2 for local hidden variables, while the Bell state gives three correlators +1/√2 and one −1/√2, so S = 2√2; KCBS analogously sums ⟨A_k A_(k+1)⟩ around the pentagon.

**Source:** Myrvold, W., Genovese, M., & Shimony, A. (2024). Bell's theorem. In E. N. Zalta & U. Nodelman (Eds.), The Stanford Encyclopedia of Philosophy (Winter 2024 ed.). Metaphysics Research Lab, Stanford University. — <https://plato.stanford.edu/archives/win2024/entries/bell-theorem/>

### Bell's theorem
*In-essay notation / aliases:* Bell (1964), Bell inequality, local hidden-variable inequality

Bell's theorem (Bell, 1964) states that no local hidden-variable theory can reproduce all predictions of quantum mechanics: if measurement outcomes are determined by shared variables fixed at the source, and each party's outcome is independent of the other's distant setting choice, the resulting correlations must satisfy an inequality that suitable entangled quantum states violate. Its most-tested special case is the CHSH inequality (Clauser, Horne, Shimony and Holt, 1969): with two settings and ±1 outcomes per party, S = E(a0,b0) + E(a0,b1) + E(a1,b0) − E(a1,b1) obeys |S| ≤ 2 in every local hidden-variable theory, while quantum mechanics reaches S = 2√2 (Tsirelson's bound). The theorem is the general no-go result; CHSH is one derived inequality.

**Source:** Myrvold, W., Genovese, M., & Shimony, A. (2024). Bell's theorem. In E. N. Zalta & U. Nodelman (Eds.), The Stanford Encyclopedia of Philosophy (Spring 2024 ed.). Stanford University. https://plato.stanford.edu/entries/bell-theorem/ — <https://plato.stanford.edu/entries/bell-theorem/>

### Tsirelson bound
*In-essay notation / aliases:* 2√2 ≈ 2.828, Tsirelson (1980), Cirel'son bound

The maximum value quantum mechanics itself allows for the CHSH combination S = E(a0,b0) + E(a0,b1) + E(a1,b0) − E(a1,b1): whereas local hidden-variable theories obey |S| ≤ 2, every quantum state and choice of ±1-valued measurements satisfies |S| ≤ 2√2 ≈ 2.828, and a maximally entangled qubit pair with suitably rotated settings attains this ceiling exactly (Tsirelson, 1980). The bound thus marks quantum theory's own limit, strictly between the classical bound 2 and the algebraic maximum 4 — the two-party analogue of the Lovász number ϑ sitting between α and α* in the essay's α ≤ ϑ ≤ α* hierarchy for the KCBS pentagon.

**Source:** Myrvold, W., Genovese, M., & Shimony, A. (2024). Bell's theorem. In E. N. Zalta & U. Nodelman (Eds.), The Stanford Encyclopedia of Philosophy (Spring 2024 ed.). Stanford University. — <https://plato.stanford.edu/entries/bell-theorem/>

### quantum circuit (Hadamard and CNOT gates)
*In-essay notation / aliases:* QuantumCircuitOperator diagram, gate chain, H, controlled-NOT, 51-gate circuit, gate cascade

A quantum circuit is a sequence of unitary gates applied to wires, one per qubit (or qudit); the whole circuit is the matrix product of its gates, taken in reverse order of application, with identities filling the untouched wires. The Hadamard gate H = (1/√2)·[[1, 1], [1, −1]] sends |0⟩ to (|0⟩ + |1⟩)/√2, an equal superposition. The controlled-NOT (CNOT) acts on two qubits, flipping the target exactly when the control is |1⟩: |c, t⟩ → |c, t ⊕ c⟩. Applied to |00⟩, H on the control qubit followed by CNOT yields the entangled Bell state (|00⟩ + |11⟩)/√2 — the essay's Bell-pair preparation — and the same circuit model carries its qutrit gate cascades, up to the 51-gate necklace circuit.

**Source:** Nielsen, M. A., & Chuang, I. L. (2010). Quantum computation and quantum information (10th anniversary ed.). Cambridge University Press. — <https://www.cambridge.org/highereducation/books/quantum-computation-and-quantum-information/01E10196D0A682A6AEFFEA52D53BE9AE>

### tensor (Kronecker) product
*In-essay notation / aliases:* KroneckerProduct, QuantumTensorProduct, joint observable, P_i ⊗ P_j, composite observable

The composition rule for quantum subsystems: two systems with state spaces H₁ (dimension m) and H₂ (dimension n) combine into the mn-dimensional space H₁ ⊗ H₂, and operators A on H₁ and B on H₂ combine into A ⊗ B, defined by (A ⊗ B)(u ⊗ v) = Au ⊗ Bv. In matrix form this is the Kronecker product: the block matrix whose (i,j) block is a_ij·B. A joint observable such as P_i ⊗ P_j then measures P_i on the first subsystem and P_j on the second simultaneously; on a product state its expectation factorizes, ⟨u ⊗ v|A ⊗ B|u ⊗ v⟩ = ⟨u|A|u⟩⟨v|B|v⟩. In the essay this is KroneckerProduct/QuantumTensorProduct — the "independent products" route that gluing is contrasted with.

**Source:** Nielsen, M. A., & Chuang, I. L. (2010). Quantum computation and quantum information (10th anniversary ed.), §2.1.7. Cambridge University Press. https://doi.org/10.1017/CBO9780511976667 — <https://doi.org/10.1017/CBO9780511976667>

### Kochen–Specker theorem
*In-essay notation / aliases:* Kochen and Specker (1967), state-independent contextuality

The theorem of Kochen and Specker (1967): on a Hilbert space of dimension ≥ 3, no assignment of definite values {0, 1} to all projection operators can satisfy the exclusivity-and-completeness rule that, in every set of mutually orthogonal projectors summing to the identity, exactly one receives the value 1 — provided each projector's value is noncontextual, i.e. independent of which compatible projectors it is measured alongside. The original proof exhibits a finite set of 117 directions in three dimensions admitting no such coloring. Unlike Bell/CHSH, the result is state-independent and needs no entanglement or spatial separation: a single qutrit suffices. KCBS is its state-dependent, experimentally testable descendant.

**Source:** Held, C. (2022). The Kochen-Specker theorem. In E. N. Zalta & U. Nodelman (Eds.), The Stanford Encyclopedia of Philosophy (Fall 2022 ed.). Metaphysics Research Lab, Stanford University. — <https://plato.stanford.edu/archives/fall2022/entries/kochen-specker/>

### measurement context / joint measurability (compatibility)
*In-essay notation / aliases:* context, compatible measurements, jointly measurable, commuting projectors, one context per pentagon edge, pairwise-compatible sharp measurements

Two quantum measurements are compatible (jointly measurable) when a single experimental arrangement can yield both outcomes at once; for sharp observables this holds exactly when they commute, [A, B] = AB − BA = 0. A measurement context is a set of mutually compatible observables measured together in one run — and for sharp measurements pairwise commutativity already guarantees that the whole set is jointly measurable. Noncontextuality demands that an outcome's value be independent of which context it is measured in. In the KCBS pentagon C5, adjacent directions are orthogonal, so each pair (A_k, A_(k+1)) commutes and forms one context per pentagon edge — five contexts, each sharing one observable with each neighbor.

**Source:** Held, C. (2022). The Kochen–Specker theorem. In E. N. Zalta & U. Nodelman (Eds.), The Stanford Encyclopedia of Philosophy (Fall 2022 ed.). Metaphysics Research Lab, Stanford University. https://plato.stanford.edu/archives/fall2022/entries/kochen-specker/ — <https://plato.stanford.edu/archives/fall2022/entries/kochen-specker/>

### quantum nonlocality
*In-essay notation / aliases:* nonlocality, spatially-separated case of contextuality

Quantum nonlocality is the failure of correlations between spatially separated systems to admit any local hidden-variable model — a distribution over hidden states λ in which each party's outcome depends only on λ and its own local setting, so joint probabilities factorize. Bell's theorem shows entangled states violate bounds every such model obeys; in the CHSH form, S = E(a0,b0) + E(a0,b1) + E(a1,b0) − E(a1,b1) satisfies |S| ≤ 2 for local models, while quantum mechanics reaches 2√2. Nonlocality nonetheless respects no-signaling: neither party's local statistics depend on the other's setting. In this essay it is the special spatially separated case of contextuality.

**Source:** Berkovitz, J. (2016). Action at a distance in quantum mechanics. In E. N. Zalta (Ed.), The Stanford Encyclopedia of Philosophy (Spring 2016 ed.). Metaphysics Research Lab, Stanford University. — <https://plato.stanford.edu/archives/spr2016/entries/qm-action-distance/>

## The Atom: The KCBS Pentagon

### KCBS inequality
*In-essay notation / aliases:* pentagram inequality, Σ〈A_i A_(i+1)〉 ≥ −3, quantum value 5−4√5, Klyachko–Can–Binicioğlu–Shumovsky (2008)

The KCBS inequality (Klyachko, Can, Binicioğlu, Shumovsky, 2008), originally the "pentagram inequality", is the minimal test of quantum contextuality. Five unit vectors v_0…v_4 in a qutrit's state space, each orthogonal to its two cyclic neighbors, define dichotomic observables A_i = 1 − 2|v_i⟩⟨v_i|; adjacent pairs commute and are jointly measurable — the edges of the pentagon exclusivity graph C5. Every noncontextual assignment of preexisting ±1 values obeys Σ⟨A_i A_(i+1)⟩ ≥ −3 (indices mod 5), whereas the qutrit's cone-axis state gives each context ⟨A_i A_(i+1)⟩ = 1 − 4/√5, summing to 5 − 4√5 ≈ −3.944. On the event ruler, Σ⟨A_i A_(i+1)⟩ = 5 − 4Σp, so the bounds read Σp ≤ 2 versus √5 = ϑ(C5).

**Source:** Klyachko, A. A., Can, M. A., Binicioğlu, S., & Shumovsky, A. S. (2008). Simple test for hidden variables in spin-1 systems. Physical Review Letters, 101(2), 020403. https://doi.org/10.1103/PhysRevLett.101.020403 — <https://doi.org/10.1103/PhysRevLett.101.020403>

### Born rule (measurement postulate)
*In-essay notation / aliases:* |〈handle|v_k〉|², cos² click probability, probability = |amplitude|², expectation 〈ψ|A|ψ〉, 'Mean' as expectation value

The postulate fixing how quantum states yield statistics: measuring an observable with projectors {P_k} on state |ψ⟩ gives outcome k with probability p(k) = ⟨ψ|P_k|ψ⟩; for a rank-one projector P_k = |v_k⟩⟨v_k| this is the squared overlap |⟨v_k|ψ⟩|², and the expectation value of any observable A is ⟨A⟩ = ⟨ψ|A|ψ⟩. After outcome k, the state updates to P_k|ψ⟩/√p(k). Every probability in this essay is a Born-rule value — each KCBS projector clicks on the handle state with |⟨handle|v_k⟩|² = 1/√5, QuantumMeasurementOperator's "Mean" returns ⟨ψ|P|ψ⟩, and the 25 composite projectors P_i ⊗ P_j click with probability exactly 1/5.

**Source:** Nielsen, M. A., & Chuang, I. L. (2010). Quantum computation and quantum information (10th anniversary ed.), §2.2.3. Cambridge University Press. https://doi.org/10.1017/CBO9780511976667 — <https://www.cambridge.org/core/product/identifier/9780511976667/type/book>

### Lovász number ϑ(G)
*In-essay notation / aliases:* ϑ(C5) = √5, ϑ(G_W), ϑ-bar(W), Lovász theta SDP, quantum bound, Lovász (1979)

The Lovász number ϑ(G) of a graph G is a semidefinite-programming invariant sandwiched between the independence number and the fractional packing number: α(G) ≤ ϑ(G) ≤ α*(G). It equals the maximum of the sum of all entries of a real symmetric positive-semidefinite matrix X with Tr X = 1 and X_ij = 0 for every edge ij; equivalently, the maximum of Σᵢ ⟨c, uᵢ⟩² over a unit "handle" vector c and unit vectors uᵢ assigned to vertices with uᵢ ⊥ uⱼ on every edge. For an exclusivity graph it is the quantum-mechanical maximum of the event sum Σp, and it is multiplicative under the co-normal (OR) product that combines independent copies. Lovász (1979) introduced it with the pentagon, computing ϑ(C5) = √5 and thereby settling the Shannon capacity Θ(C5) = √5.

**Source:** Lovász, L. (1979). On the Shannon capacity of a graph. IEEE Transactions on Information Theory, 25(1), 1–7. https://doi.org/10.1109/TIT.1979.1055985 — <https://doi.org/10.1109/TIT.1979.1055985>

### exclusivity graph
*In-essay notation / aliases:* C5 exclusivity graph, G_W, exclusive events, exclusivity structure

The exclusivity graph of a measurement scenario has one vertex per measurement event and an edge joining each pair of mutually exclusive events — events jointly testable in a single run yet never both occurring (quantumly, orthogonal projectors). Its graph invariants bound the event sum Σp attainable in each physical theory: noncontextual hidden-variable models reach at most the independence number α(G), quantum mechanics at most the Lovász number ϑ(G), and any no-signalling theory at most the fractional packing number α*(G), with α(G) ≤ ϑ(G) ≤ α*(G). For the KCBS pentagon C5 these read 2 < √5 < 5/2 — the smallest strict separation — and the essay's glued composites G_W are exclusivity graphs built by identifying shared detectors.

**Source:** Cabello, A., Severini, S., & Winter, A. (2014). Graph-theoretic approach to quantum correlations. Physical Review Letters, 112(4), 040401. https://doi.org/10.1103/PhysRevLett.112.040401 — <https://arxiv.org/abs/1401.7081>

### fractional packing number α*(G) (and fractional edge cover)
*In-essay notation / aliases:* α*(C5) = 5/2, fractional-packing polytope, no-signalling ceiling, weight-1/2 edge cover of value 3/2 per block, LP duality squeeze

The fractional packing number α*(G) of an exclusivity graph G is the value of a linear program: maximize Σ x_i over vertex weights x_i ≥ 0 with Σ_{i∈C} x_i ≤ 1 on every clique C. It caps the event sum Σp in any no-signalling theory obeying only exclusivity, so α(G) ≤ ϑ(G) ≤ α*(G). On triangle-free graphs such as C5 the cliques are just edges, so the constraint reads x_i + x_j ≤ 1, and weight 1/2 everywhere gives α*(C5) = 5/2. This edge-form LP has as its dual the fractional edge cover: minimize Σ y_e over edge weights y_e ≥ 0 summing to at least 1 at every vertex. Weak duality puts every packing ≤ every cover, so matching values (3/2 per block) certify the value exactly.

**Source:** Cabello, A., Severini, S., & Winter, A. (2014). Graph-theoretic approach to quantum correlations. Physical Review Letters, 112(4), 040401. https://doi.org/10.1103/PhysRevLett.112.040401 — <https://arxiv.org/abs/1401.7081>

### independence number α(G)
*In-essay notation / aliases:* α(C5) = 2, α(G_W), α-bar(W) (density per block), classical bound, FindIndependentVertexSet

An independent set in a graph G is a set of vertices no two of which are joined by an edge; the independence number α(G) is the size of a largest such set. In an exclusivity graph, whose vertices are measurement events and whose edges join mutually exclusive pairs, α(G) counts the most events a deterministic 0/1 assignment can mark 1 with no two adjacent 1s, so every noncontextual hidden-variable model obeys Σp ≤ α(G). For the KCBS pentagon, α(C5) = 2. The essay also uses the per-block density α-bar(W), the independence number divided by the number of glued pentagons.

**Source:** Diestel, R. (2017). Graph theory (5th ed., Graduate Texts in Mathematics, Vol. 173). Springer. — <https://diestel-graph-theory.com/>

### projector (projection operator)
*In-essay notation / aliases:* |v_k〉〈v_k|, Outer[Times,v,v], rank-1 projection, tensor-product projectors P_i ⊗ P_j

A projector is a Hermitian, idempotent operator: P† = P and P² = P. The essay uses rank-1 projectors P_k = |v_k⟩⟨v_k| (in code, Outer[Times, v, v]), each projecting onto the ray spanned by a unit vector v_k. Measuring P_k is a yes/no test: on state |ψ⟩ it "clicks" with probability ⟨ψ|P_k|ψ⟩ = |⟨v_k|ψ⟩|², its eigenvalues being 1 (yes) and 0 (no). Orthogonal directions give commuting projectors with P_i P_j = 0, i.e. mutually exclusive events — the pentagon's edges. Every object here is built from projectors: the dichotomic observables A_k = 1 − 2|v_k⟩⟨v_k|, and the 25 joint tests P_i ⊗ P_j on two independent pentagon copies.

**Source:** Nielsen, M. A., & Chuang, I. L. (2010). Quantum computation and quantum information (10th anniversary ed., §2.1.6). Cambridge University Press. — <https://www.cambridge.org/highereducation/books/quantum-computation-and-quantum-information/01E10196D0A682A6AEFFEA52D53BE9AE>

### orthonormal representation with handle
*In-essay notation / aliases:* handle state, cone-axis state, vector representation, representation witness, rail representation

An orthonormal representation of an exclusivity graph assigns each vertex i a unit vector uᵢ so that adjacent (mutually exclusive) vertices are orthogonal: ⟨uᵢ, uⱼ⟩ = 0 whenever i ~ j — the complement of Lovász's original convention, which orthogonalizes non-adjacent pairs. A handle (Grötschel–Lovász–Schrijver's term) is one further unit vector h; the representation's value is Σᵢ ⟨h, uᵢ⟩², and the Lovász number ϑ is the maximum value over all representations and handles, so any explicit construction certifies a lower bound on ϑ. Each uᵢ defines a rank-one projector and h a quantum state, making ⟨h, uᵢ⟩² the click probability of event i; for the KCBS pentagon C5, Lovász's symmetric umbrella of five vectors about h gives ⟨h, uᵢ⟩² = 1/√5 each, attaining Σp = √5 = ϑ(C5).

**Source:** Lovász, L. (1979). On the Shannon capacity of a graph. IEEE Transactions on Information Theory, 25(1), 1–7. https://doi.org/10.1109/TIT.1979.1055985 — <https://doi.org/10.1109/TIT.1979.1055985>

### heralded single photon
*In-essay notation / aliases:* single heralded photon, heralding, single-photon source

A photon whose presence is announced, rather than assumed, by its twin. A nonlinear source — typically spontaneous parametric down-conversion — creates photons in pairs; detecting one member of a pair (the herald, or idler) signals that a partner photon now occupies the signal path. Conditioning on herald clicks suppresses the vacuum component and, at low pump power, multi-photon contamination, though the source remains probabilistic rather than on-demand. In the Lapkiewicz experiment this matters directly: the qutrit is one heralded photon spread over three optical modes, so heralding certifies that the KCBS statistics arise from indivisible single-particle events rather than from classical light or accidental multi-photon coincidences.

**Source:** Eisaman, M. D., Fan, J., Migdall, A., & Polyakov, S. V. (2011). Invited review article: Single-photon sources and detectors. Review of Scientific Instruments, 82(7), 071101. https://doi.org/10.1063/1.3610677 — <https://www.nist.gov/publications/single-photon-sources-and-detectors>

### unitary operator / unitarity
*In-essay notation / aliases:* UnitaryQ, 'confirmed unitary', norm-preserving evolution, reversibility

A unitary operator U on a Hilbert space is a linear operator whose conjugate transpose is its inverse: U†U = UU† = I. Unitarity is exactly the condition that U preserves inner products, hence norms — so quantum state vectors stay normalized and outcome probabilities always sum to 1 — and that the evolution is reversible, since U† undoes U. Quantum mechanics postulates that every closed-system evolution, and thus every quantum gate and circuit, is unitary. In this essay, UnitaryQ → True is the machine check that a constructed gate satisfies U†U = I; both direct (det +1) and twisted (det −1) gluing gates pass it, since unitarity fixes only |det U| = 1.

**Source:** Nielsen, M. A., & Chuang, I. L. (2010). Quantum computation and quantum information (10th anniversary ed.). Cambridge University Press. — <https://www.cambridge.org/highereducation/books/quantum-computation-and-quantum-information/01E10196D0A682A6AEFFEA52D53BE9AE>

### co-normal (OR) graph product
*In-essay notation / aliases:* OR product, disjunctive product, independent-copies composition, ϑ-multiplicativity under the OR product

The co-normal (OR) product G∨H of two graphs has vertex set V(G)×V(H), with (u₁,u₂) adjacent to (v₁,v₂) exactly when u₁~v₁ in G or u₂~v₂ in H. For exclusivity graphs this is the natural composition of independent experiments: a pair of joint events is exclusive as soon as either component pair is. The Lovász number is multiplicative under this product, ϑ(G∨H) = ϑ(G)·ϑ(H) — the complement-form of Lovász's strong-product identity, proved in the same 1979 paper. Applied to two independent KCBS pentagons, the 25-event graph C₅∨C₅ has quantum value ϑ = 5, and multiplicativity forces the single-pentagon bound ϑ(C₅) = √5 — the essay's second derivation of the KCBS quantum maximum.

**Source:** Lovász, L. (1979). On the Shannon capacity of a graph. IEEE Transactions on Information Theory, 25(1), 1–7. https://doi.org/10.1109/TIT.1979.1055985 — <https://ieeexplore.ieee.org/document/1055985>

## Composition by Gluing: Direct and Twisted

### orthogonal group O(3): isometries, rotations vs reflections (det = ±1)
*In-essay notation / aliases:* rigid attachment, isometry of real three-dimensional space, orientation-preserving/reversing, R_twisted = diag(1,1,-1).R_direct, (-1)^#twisted, determinant multiplicativity

The orthogonal group O(3) is the group of all linear maps R of real three-dimensional space that preserve lengths and angles — equivalently, all 3×3 real matrices satisfying RᵀR = I. These are exactly the origin-fixing isometries of R³, so every rigid attachment of one pentagon frame to another is an element of O(3). Taking determinants of RᵀR = I gives det R = ±1, splitting O(3) into its two connected components: the rotations (det = +1, the gluing letter d) and the orientation-reversing maps (det = −1) — reflections and rotoreflections — among them the letter t's reflection, with R_twisted = diag(1,1,−1)·R_direct exhibiting the sign flip. Since det(R₁R₂) = det R₁ · det R₂, any composed gluing word carries the well-defined parity (−1)^#twisted.

**Source:** Artin, M. (2011). Algebra (2nd ed.). Pearson. (Ch. 5, orthogonal matrices, rotations and reflections; reissued as Classic Version, 2017.) — <https://www.pearson.com/en-us/subject-catalog/p/Artin-Algebra-Classic-Version-2nd-Edition/P200000006078/9780134689609>

### perfect graph
*In-essay notation / aliases:* 'even cycles are perfect', sandwich theorem α ≤ ϑ ≤ χ̄

A graph G is perfect when, for every induced subgraph H of G (G included), the chromatic number equals the clique number, χ(H) = ω(H); equivalently, by complementation, the independence number of every induced subgraph equals its clique-cover number, α(H) = χ̄(H). Perfection matters here through the sandwich theorem α(G) ≤ ϑ(G) ≤ χ̄(G): the Lovász number is squeezed between two NP-hard quantities, and on a perfect graph the sandwich collapses to equality. The strong perfect graph theorem characterizes perfection: G is perfect exactly when neither G nor its complement contains an induced odd cycle of length ≥ 5. An even cycle C_2N has no such odd hole or antihole, so it is perfect and ϑ(C_2N) = α(C_2N) = N — the step the essay's direct-ring upper bound uses.

**Source:** Knuth, D. E. (1994). The sandwich theorem. The Electronic Journal of Combinatorics, 1, Article A1. https://doi.org/10.37236/1193 — <https://www.combinatorics.org/ojs/index.php/eljc/article/view/v1i1a1>

### Gröbner basis
*In-essay notation / aliases:* Gröbner-basis elimination, collapsing the KKT system to a single cubic

Fix a monomial order on a polynomial ring. A Gröbner basis of an ideal I is a finite set G = {g₁, …, gₛ} ⊂ I whose leading terms generate the ideal of all leading terms: ⟨LT(g₁), …, LT(gₛ)⟩ = ⟨LT(I)⟩. Division by G then yields a unique remainder, zero exactly when a polynomial lies in I, and under an elimination (e.g. lexicographic) order the basis systematically eliminates variables from a polynomial system. The essay uses this elimination to collapse the twisted ring's KKT stationarity equations to one cubic, 49x³ − 128x² − 75x + 218 = 0, whose middle root is the exact constant τ*.

**Source:** Cox, D. A., Little, J., & O'Shea, D. (2015). Ideals, varieties, and algorithms: An introduction to computational algebraic geometry and commutative algebra (4th ed.). Springer. — <https://doi.org/10.1007/978-3-319-16721-3>

### KKT conditions (and global optimality in convex programs)
*In-essay notation / aliases:* KKT stationarity, KKT multipliers positive, Karush–Kuhn–Tucker, max-eigenvalue minimax hence convex

For a problem "minimize f(x) subject to gᵢ(x) ≤ 0" with differentiable data, the Karush–Kuhn–Tucker (KKT) conditions ask for a point x* and multipliers λᵢ ≥ 0 satisfying stationarity, ∇f(x*) + Σᵢ λᵢ ∇gᵢ(x*) = 0, primal feasibility gᵢ(x*) ≤ 0, and complementary slackness λᵢ gᵢ(x*) = 0. At an optimum they hold whenever a constraint qualification such as Slater's condition is met; conversely, when f and every gᵢ are convex, any KKT point is a global minimum. The largest eigenvalue of a symmetric matrix is a convex function of its entries, so the essay's max-eigenvalue symbol minimax is a convex program: exhibiting a KKT witness with positive multipliers certifies τ* as the exact optimum, not merely a stationary point or a numerical fit.

**Source:** Boyd, S., & Vandenberghe, L. (2004). Convex optimization. Cambridge University Press. (KKT conditions: §5.5.3; convexity of the maximum eigenvalue: §3.2.3, Example 3.10) — <https://web.stanford.edu/~boyd/cvxbook/>

### algebraic number / exact closed form (the cubic field Q(τ*))
*In-essay notation / aliases:* exact algebraic closed form, middle root of 49x³−128x²−75x+218, RootReduce verification, number-field arithmetic

An algebraic number is a root of a nonzero polynomial with integer coefficients, specified exactly by that polynomial plus a root index — here τ* is the middle real root of 49x³ − 128x² − 75x + 218. Such a root is an exact closed form: all arithmetic can be done symbolically in the number field Q(τ*), whose elements are expressions a + bτ* + cτ*² with rational a, b, c, reduced modulo the cubic. An identity in Q(τ*) is verified when it simplifies to exactly zero (the essay's RootReduce check on the dual witness), so the twisted-ring growth rate is proven by exact number-field arithmetic, not fit by a numerical solver.

**Source:** Basu, S., Pollack, R., & Roy, M.-F. (2006). Algorithms in real algebraic geometry (2nd ed.). Springer. — <https://link.springer.com/book/10.1007/3-540-33099-2>

### convex duality / dual witness / certificate
*In-essay notation / aliases:* dual variables (βbx, γax, βab, γba), explicit dual witness (g, h, cos θ*), certificate ladder Γ_k, provable ceiling, certified to within ϵ

Every optimization problem admits a Lagrangian dual, and weak duality holds unconditionally: for a maximization problem with optimum p*, every dual feasible point yields a dual objective value that upper-bounds p*. A dual feasible point is therefore a certificate — a finite, checkable object whose defining identities can be verified directly, as with the dual witness (g, h, cos θ*) whose KKT identities are checked exactly in the cubic field ℚ(τ*) — proving the bound without re-running any search. Convexity adds sufficiency: a KKT point of a convex problem is globally, not merely locally, optimal. The ladder Γ_k is a sequence of such certified ceilings on the gap density of every gluing word, each sitting only slightly above gap(ddt).

**Source:** Boyd, S., & Vandenberghe, L. (2004). Convex optimization. Cambridge University Press. (Ch. 5, Duality; §5.5, Optimality conditions, incl. §5.5.1, Certificate of suboptimality) — <https://web.stanford.edu/~boyd/cvxbook/>

### semidefinite programming (SDP)
*In-essay notation / aliases:* ϑ-SDP, positive-semidefinite cone, one semidefinite program over all vertices jointly, per-node PSD blocks

Semidefinite programming is convex optimization over the cone of positive-semidefinite matrices: minimize a linear objective c⊤x subject to the affine matrix constraint F(x) = F₀ + x₁F₁ + … + xₘFₘ being positive semidefinite (no negative eigenvalues). It generalizes linear programming — recovered when all Fᵢ are diagonal — while keeping strong duality (under strict feasibility) and polynomial-time interior-point solvability. In this essay every quantum quantity is an SDP value: the Lovász number ϑ of a glued exclusivity graph must be paid for with one semidefinite program over all vertices jointly, whereas α composes letter-by-letter; feasible dual points supply the rigorous Γ_k certificates for gap(ddt).

**Source:** Vandenberghe, L., & Boyd, S. (1996). Semidefinite programming. SIAM Review, 38(1), 49–95. — <https://web.stanford.edu/~boyd/papers/sdp.html>

### max-plus (tropical) transfer-matrix method
*In-essay notation / aliases:* 3-state max-plus transfer dynamic program, transfer matrices T_d, T_t, trace(T_d T_d T_t ...), letter-local factorization, tropical semiring (ℝ∪{−∞}, max, +)

A dynamic program carried out in the tropical semiring (ℝ∪{−∞}, max, +), where addition is max and multiplication is +. Each gluing letter gets a matrix over a small set of local boundary states — here 3×3 matrices T_d and T_t whose (i, j) entry is the largest number of independent vertices a pentagon block can contribute while its interface moves from state i to state j (−∞ if impossible). Because matrix products in this semiring compose letter by letter, the tropical trace — the maximum diagonal entry — of the word's matrix product equals the global optimum for the closed necklace: trace(T_d T_d T_t T_d T_d T_t) = α(G_W) = 8. This is exactly why α is exact and letter-local while ϑ needs one global SDP.

**Source:** Baccelli, F., Cohen, G., Olsder, G. J., & Quadrat, J.-P. (1992). Synchronization and linearity: An algebra for discrete event systems. Wiley. — <https://www.rocq.inria.fr/metalau/cohen/documents/BCOQ-book.pdf>

## Searching for the Optimal Word: ddt

### first Stiefel–Whitney class w1 (orientability; cylinder vs Möbius)
*In-essay notation / aliases:* w_1 ∈ H^1(ring; Z2), 'the complete topological invariant of the gluing pattern', (-1)^#twisted as a cohomology class, trivial vs nontrivial class, Möbius band's single boundary loop

The first Stiefel–Whitney class w1 of a real vector bundle is a cohomology class in H^1(base; Z2) that measures the obstruction to orienting the bundle: w1 = 0 exactly when a consistent orientation of the fibers exists. Concretely, it records whether the transition maps between local trivializations preserve or reverse orientation, so around any loop it evaluates to the sign of the holonomy determinant — here (−1)^#twisted, the parity of t-joints in the gluing word. Line (interval) bundles over the circle are classified completely by w1: the trivial class gives the cylinder (two boundary loops), the nontrivial class the Möbius band (one boundary loop) — the essay's cylinder/Möbius dichotomy for glued pentagon rings.

**Source:** Milnor, J. W., & Stasheff, J. D. (1974). Characteristic classes (Annals of Mathematics Studies 76). Princeton University Press. — <https://press.princeton.edu/books/paperback/9780691081229/characteristic-classes>

### cohomology H^1(ring; Z2) and coboundaries
*In-essay notation / aliases:* H^1(C6; Z2), cohomology count, coboundary flips at every block, two gauge classes among 64 parity words, H^1 = Z^1/B^1

On the ring graph C_L (blocks as vertices, joints as edges), a Z2-valued 1-cochain assigns each edge a parity label: 0 for direct, 1 for twisted. A 0-cochain assigns a bit to each vertex; its coboundary δs flips the labels of the two edges meeting every vertex where s = 1 — exactly the re-orientation of one block's frame. With no 2-cells, every 1-cochain is a cocycle, so H^1(C_L; Z2) = Z^1/B^1 ≅ Z2: the 2^L parity words collapse under coboundary flips into exactly two classes, distinguished by the total parity Σw mod 2, i.e. the holonomy sign (−1)^#twisted. Cell 145 verifies this by direct count for L = 6: 64 words, two classes.

**Source:** Hatcher, A. (2002). Algebraic topology. Cambridge University Press. (See §3.1: cochain complexes, coboundary maps, and cohomology groups.) — <https://pi.math.cornell.edu/~hatcher/AT/ATpage.html>

### flat O(3)-bundle (gluing data / transition functions)
*In-essay notation / aliases:* flat bundle over the ring, descent formalism, charts, local trivializations, 'a gauge field from local trivializations'

A fibre bundle over a base covered by charts Uᵢ is presented by its gluing data: transition functions gᵢⱼ on overlaps Uᵢ∩Uⱼ, valued in the structure group G and satisfying the cocycle condition gᵢₖ = gᵢⱼ·gⱼₖ on triple overlaps, which glue the local trivializations Uᵢ×F into one total space. The bundle is flat when the gᵢⱼ can be chosen locally constant; flat G-bundles are then classified, up to gauge equivalence, by holonomy homomorphisms π₁(base) → G, taken up to conjugation in G. In the essay each joint's R_direct or R_twisted matrix is exactly such a transition function for a flat O(3)-bundle over the ring, whose holonomy homomorphism Z → O(3) sends 1 to the gluing word's ordered product.

**Source:** Steenrod, N. (1951). The Topology of Fibre Bundles (Princeton Mathematical Series 14). Princeton University Press. (See Part I, §2–3, coordinate transformations and the cocycle condition.) — <https://press.princeton.edu/books/paperback/9780691005485/the-topology-of-fibre-bundles>

### gauge transformation / Z2 lattice gauge field
*In-essay notation / aliases:* gauge moves, gauge equivalence classes, re-orienting one block's local frame, parity word as link variables, Ising gauge model

A Z2 lattice gauge field assigns to each link ℓ of a graph a variable σℓ ∈ {+1, −1}; in the essay the gluing word's parity labels (d ↦ +1, t ↦ −1) play this role on the ring of pentagon blocks. A gauge transformation chooses a sign gv = ±1 at each vertex and replaces σuv by gu σuv gv — concretely, re-orienting one block's local frame flips the parity label at its two adjacent joints. Products of link variables around closed loops (Wilson loops) are gauge-invariant, and on a single ring the loop parity (−1)^#t is the only invariant: all 2^L parity words of length L collapse into exactly two gauge equivalence classes.

**Source:** Kogut, J. B. (1979). An introduction to lattice gauge theory and spin systems. Reviews of Modern Physics, 51(4), 659–713. https://doi.org/10.1103/RevModPhys.51.659 — <https://doi.org/10.1103/RevModPhys.51.659>

### holonomy (Wilson loop)
*In-essay notation / aliases:* the accumulated matrix around the ring, the 51-fold product, holonomy parity, ordered product of link matrices around a closed loop

Holonomy is the net transformation produced by parallel transport around a closed loop: for a bundle or lattice gauge field given by link matrices g_1, …, g_L along the loop's edges, it is the ordered product g_L ⋯ g_2 g_1 — in this essay, the 51-fold product of R_direct and R_twisted around the necklace. Changing the local frame at a site (a gauge move) only conjugates this product, so its conjugation-invariant content is what is physically meaningful; Wilson's loop observable, the trace of the ordered product of link variables around a closed lattice path, is the basic gauge-invariant quantity built from it. Here that invariant is the determinant sign (−1)^#twisted, the parity separating cylinder from Möbius gluings.

**Source:** Wilson, K. G. (1974). Confinement of quarks. Physical Review D, 10(8), 2445–2459. https://doi.org/10.1103/PhysRevD.10.2445 — <https://doi.org/10.1103/PhysRevD.10.2445>

### voltage (gain) graph
*In-essay notation / aliases:* group-labeled graph, Z2-labeled ring, gluing data as edge labels

A voltage (gain) graph is a graph each of whose oriented edges carries an element of a group G; traversing an edge against its orientation contributes the inverse element, so every walk acquires a net group value — the ordered product of its edge labels — and every closed loop acquires a holonomy. Equivalently, it is the gluing data of a flat G-bundle over the graph, from which a covering (derived) graph can be constructed. The essay labels each joint of the base ring with the matrix R_direct or R_twisted — a voltage in O(3) — so the 51-fold product around the necklace is the loop holonomy; its determinant sign (−1)^#twisted is the gauge-invariant Z2 parity (the class w_1): even gives the cylinder, odd the Möbius band.

**Source:** Gross, J. L. (1974). Voltage graphs. Discrete Mathematics, 9(3), 239–246. Elsevier. — <https://doi.org/10.1016/0012-365X(74)90006-5>

## Why This Resists Proof: De Bruijn Graphs and Ergodic Optimization

### ergodic optimization (mean-payoff over shift spaces)
*In-essay notation / aliases:* ergodic-optimization problem, mean-payoff problem, shift space of {d,t}-sequences, maximizing time-averages over invariant measures

Given a continuous map T: X → X of a compact metric space and a continuous payoff f: X → ℝ, ergodic optimization studies the maximum ergodic average β(f) = sup ∫f dμ, the supremum over all T-invariant Borel probability measures μ; this supremum is attained, and any measure attaining it is a maximizing measure. Equivalently, β(f) is the best achievable long-run time average supₓ lim supₙ (1/n)·Σₖ₌₀ⁿ⁻¹ f(Tᵏx) — the mean payoff per step. In the essay X is the shift space of {d,t}-sequences, T the left shift, and the payoff encodes the gap density ϑ/L − α/L per pentagon block — a whole-word quantity, not letter-local; periodic words correspond to de Bruijn-graph cycles, and the optimizer may be a non-periodic (Sturmian) sequence — the stated obstruction to certifying (ddt)∞ as globally optimal.

**Source:** Jenkinson, O. (2006). Ergodic optimization. Discrete and Continuous Dynamical Systems, 15(1), 197–224. https://doi.org/10.3934/dcds.2006.15.197 — <https://www.aimsciences.org/article/doi/10.3934/dcds.2006.15.197>

### de Bruijn graph
*In-essay notation / aliases:* de Bruijn-k graph over {d,t}, de Bruijn-3, window graph, cycle = periodic word correspondence, de Bruijn machinery

The de Bruijn graph of order k over an alphabet — here the gluing alphabet {d, t} — has one node for each length-k word and a directed edge from w to w′ exactly when w′ is obtained from w by deleting its first letter and appending one new letter, so following edges reads out a sequence one letter at a time. Infinite {d, t}-sequences correspond to infinite walks, and periodic gluing words correspond precisely to directed cycles: (ddt)∞ is the 3-cycle ddt → dtd → tdd → ddt in the de Bruijn-3 graph. Attaching one certificate block to each node is what lets the ladder Γ_k bound the gap density of every gluing word, periodic or not.

**Source:** Lind, D., & Marcus, B. (1995). An Introduction to Symbolic Dynamics and Coding. Cambridge University Press. https://doi.org/10.1017/CBO9780511626302 — <https://doi.org/10.1017/CBO9780511626302>

### joint spectral radius
*In-essay notation / aliases:* JSR, joint-spectral-radius problem, maximal growth rate of matrix products

The joint spectral radius (JSR) of a finite set of matrices Σ = {A₁, …, A_m} is the maximal exponential growth rate achievable by long products drawn from the set: ρ(Σ) = lim_{k→∞} max ‖A_{i₁}A_{i₂}⋯A_{i_k}‖^(1/k), the maximum ranging over all length-k choices of factors (the limit is independent of the norm). For a single matrix it reduces to the ordinary spectral radius. Σ has the "finiteness property" when some periodic product attains ρ(Σ); Bousch and Mairesse showed this can fail, the best sequence being aperiodic (Sturmian). This is exactly the obstruction the essay imports: certifying (ddt)∞ as the optimal gluing word over {d,t}-sequences is a JSR-type ergodic-optimization problem, so periodic search alone cannot close it.

**Source:** Jungers, R. (2009). The joint spectral radius: Theory and applications (Lecture Notes in Control and Information Sciences, Vol. 385). Springer Berlin, Heidelberg. — <https://link.springer.com/book/10.1007/978-3-540-95980-9>

### Schur complement
*In-essay notation / aliases:* Schur-complement argument, edge-by-edge PSD assembly

For a block matrix M = [[A, B], [B*, C]] with A invertible, the Schur complement of A in M is M/A = C − B*A⁻¹B. Its key property: when A is positive definite, M is positive semidefinite if and only if C − B*A⁻¹B is positive semidefinite. This turns a global positivity condition on a large matrix into a chain of small local checks — exactly how the essay's Γ_k certificates work: one rational positive-semidefinite block per de Bruijn-k node is assembled edge-by-edge around a ring, each join justified by a Schur-complement step, yielding a provable per-block ceiling on the Lovász number ϑ — and hence on the gap density ϑ/L − α/L — for every gluing word of window size k.

**Source:** Zhang, F. (Ed.). (2005). The Schur complement and its applications (Numerical Methods and Algorithms, Vol. 4). Springer. — <https://link.springer.com/book/10.1007/b105056>

### Sturmian sequence
*In-essay notation / aliases:* non-periodic (Sturmian) sequence, Sturmian maximizer, aperiodic competitor

An infinite sequence over a two-letter alphabet (here d, t) that is aperiodic yet has the lowest factor complexity aperiodicity allows: for every n it contains exactly n+1 distinct blocks of length n — the minimum possible, since by the Morse–Hedlund theorem any sequence with at most n blocks of some length n is eventually periodic. Equivalently, it is the itinerary of an irrational rotation: the n-th letter records whether ⟨nθ + ρ⟩ falls in an interval of length θ on the circle, for irrational θ. Sturmian sequences are the known shape of aperiodic maximizers in ergodic optimization: when the finiteness property fails, the best gluing word can be Sturmian, so no search over periodic words, however long, will find it.

**Source:** Morse, M., & Hedlund, G. A. (1940). Symbolic dynamics II. Sturmian trajectories. American Journal of Mathematics, 62(1), 1–42. — <https://doi.org/10.2307/2371431>

### finiteness property
*In-essay notation / aliases:* finiteness conjecture, optimum attained by a periodic word / finite matrix product

A finite set of matrices {A₁, …, Aₘ} has the finiteness property if its joint spectral radius ρ = lim_{k→∞} max over length-k words of ‖A_{i₁}···A_{i_k}‖^{1/k} is attained exactly by some finite product: ρ = ρ(A_{i₁}···A_{i_k})^{1/k} for a word of some finite length k, so that repeating that word periodically is globally optimal. The finiteness conjecture asserted this always holds; Bousch and Mairesse disproved it, exhibiting systems whose optimum is achieved only by non-periodic (Sturmian) sequences. Where the property fails — as it can for the essay's ergodic optimization over {d, t} gluing words — no enumeration of periodic words, however long, can certify a global optimum.

**Source:** Bousch, T., & Mairesse, J. (2002). Asymptotic height optimization for topical IFS, Tetris heaps, and the finiteness conjecture. Journal of the American Mathematical Society, 15(1), 77–111. https://doi.org/10.1090/S0894-0347-01-00378-2 — <https://doi.org/10.1090/S0894-0347-01-00378-2>

## From Gluing Words to Black-Box Certification

### Black-box / device-independent certification
*In-essay notation / aliases:* black-box certification instrument, certification instrument, black-box test, certifiable advantage per interrogation round, sealed box, black-box physics

Certifying a quantum property of a device from its observed input-output statistics alone, treating its interior as a sealed box whose workings are neither trusted nor modelled. The certificate is a correlation that exceeds a bound provably obeyed by every noncontextual classical account: here the noncontextual limit α, which the quantum value ϑ beats, so a click table with Σp above α could not have come from any noncontextual hidden-variable device. The gap ϑ − α is the certifiable advantage per interrogation round; self-testing, inferring the state and measurements themselves, is its strongest form. Statistics alone cannot, however, unmask a classical intensity forger — excluding that impostor is what the essay's dynamics audit adds.

**Source:** Šupić, I., & Bowles, J. (2020). Self-testing of quantum systems: A review. Quantum, 4, 337. https://doi.org/10.22331/q-2020-09-30-337 — <https://quantum-journal.org/papers/q-2020-09-30-337/>

### Statistical power / test statistic
*In-essay notation / aliases:* statistical power, statistical power per pentagon, statistical power of a black-box test per unit of hardware, margin of impossibility, certifiable advantage per round

In hypothesis testing, a test statistic is the single number computed from the data on which the accept/reject decision rests, and the statistical power of a test is the probability it correctly rejects the null hypothesis when a specified alternative holds — 1 minus the Type II (false-negative) error rate. Here the test statistic is the observed event-sum Σp; the null hypothesis is the classical noncontextual (hidden-variable) account, capped at α, and the alternative is the genuinely quantum device reaching ϑ. The margin ϑ − α is what lets finite click data reject the classical account; dividing by chain length L, the gap density ϑ/L − α/L measures the certifying power each glued pentagon contributes, so optimizing gap density optimizes statistical power per unit of hardware.

**Source:** Lehmann, E. L., & Romano, J. P. (2005). Testing statistical hypotheses (3rd ed.). Springer. https://doi.org/10.1007/0-387-27605-X — <https://doi.org/10.1007/0-387-27605-X>

### Critical visibility
*In-essay notation / aliases:* critical visibility, the signal fraction below which the quantum advantage disappears, ~88.5% visibility target, 0.5854, 1/(3(tau*-1)) approx 0.8848

Critical visibility is the threshold mixing fraction v at which a contextuality test loses its quantum advantage under isotropic noise. Modeling the noisy qutrit as ρ_v = v·ρ + (1−v)·I/3, the event-sum witness Σp interpolates between its ideal quantum value and the fully mixed value of 1/3 per event; v_crit is the v at which Σp drops to the classical noncontextual bound α, so for v ≤ v_crit a noncontextual model exists and the advantage disappears. A single pentagon gives v_crit = (2 − 5/3)/(√5 − 5/3) ≈ 0.5854, rising to 1/(3(τ*−1)) ≈ 0.8848 in the long-chain limit.

**Source:** Budroni, C., Cabello, A., Gühne, O., Kleinmann, M., & Larsson, J.-Å. (2022). Kochen-Specker contextuality. Reviews of Modern Physics, 94(4), 045007. https://doi.org/10.1103/RevModPhys.94.045007 — <https://doi.org/10.1103/RevModPhys.94.045007>

### Isotropic (white / depolarizing) noise
*In-essay notation / aliases:* isotropic noise, white noise, depolarizing noise

A one-parameter noise model in which an ideal d-dimensional state ρ is blended with the maximally mixed (identity) state I/d: ρ_v = v·ρ + (1−v)·I/d. This is the action of the depolarizing channel, which with probability 1−v discards the input and replaces it by the featureless I/d, leaving the direction of ρ untouched while shrinking every deviation from I/d uniformly. The visibility v ∈ [0,1] is the surviving signal fraction. The critical visibility is the smallest v at which the state still beats the noncontextual bound; below it, isotropic mixing has washed the contextual advantage away.

**Source:** Nielsen, M. A., & Chuang, I. L. (2010). Quantum computation and quantum information (10th anniversary ed.). Cambridge University Press. — <https://www.cambridge.org/core/books/quantum-computation-and-quantum-information/01E10196D0A682A6AEFFEA52D53BE9AE>

### Passive linear optics (beamsplitters and phase shifters)
*In-essay notation / aliases:* passive linear optics, beamsplitters and phase shifters, passive two-mode interferometer, passive interferometer, intensity forger's toolkit, phase[n,j], bsRe/bsIm

Passive linear optics is the class of optical transformations built solely from beamsplitters and phase shifters — devices that redistribute and rephase light among n modes without amplifying it, conserving total photon number. In the essay's quadrature representation each declared generator (phase[n,j], bsRe, bsIm) is real antisymmetric, and iterated commutators of such generators close inside the compact unitary algebra u(n), the n×n anti-Hermitian matrices of dimension at most n². Reck, Zeilinger, Bernstein and Bertani showed every n-mode unitary factors into beamsplitters and phase shifters, so u(n) is exactly an intensity forger's reach; escaping it into the symplectic algebra sp(2n,R) requires squeezing.

**Source:** Reck, M., Zeilinger, A., Bernstein, H. J., & Bertani, P. (1994). Experimental realization of any discrete unitary operator. Physical Review Letters, 73(1), 58–61. https://doi.org/10.1103/PhysRevLett.73.58 — <https://doi.org/10.1103/PhysRevLett.73.58>

### Squeezing / single- and two-mode squeezers
*In-essay notation / aliases:* squeezing, single squeezed mode, single-mode squeezer (sq1), two-mode squeezer (sq2Re/sq2Im), pair production at the horizon as a two-mode squeezer, active optics

Squeezing is the optical operation generated by Hamiltonians quadratic in the mode creation and annihilation operators — a single-mode squeezer (sq1) by terms in a² and a†², a two-mode squeezer (sq2Re/sq2Im) by a†b† and ab — which redistribute quadrature noise, pushing one quadrature's variance below the vacuum level at its conjugate's expense. Unlike passive phase shifters and beamsplitters, which conserve total photon number and close inside the compact algebra u(n), these number-nonconserving generators escape into the full symplectic algebra sp(2n,R). A design requiring them is active, not passive, optics; in the analogue-Hawking channel, pair production at the horizon acts as a two-mode squeezer.

**Source:** Barnett, S. M., & Radmore, P. M. (1997). Methods in theoretical quantum optics. Oxford University Press. https://doi.org/10.1093/acprof:oso/9780198563617.001.0001 — <https://doi.org/10.1093/acprof:oso/9780198563617.001.0001>

### Unitary Lie algebra u(n) / unitary group (compact algebra)
*In-essay notation / aliases:* compact algebra u(n), u(n), u(2), dimension at most n^2, compact algebra

The unitary group U(n) is the group of n×n complex matrices U satisfying U†U = I (columns orthonormal); it is compact, and its Lie algebra u(n) consists of the n×n anti-Hermitian matrices (X† = −X), a real vector space of dimension n². These are the generators of energy- and photon-number-conserving evolutions — passive linear optics (beamsplitters and phase shifters) on n modes. The essay's audit closes declared generators under commutators in the quadrature representation; if every element stays antisymmetric and the rank stays ≤ n² — i.e. inside u(n) — the design is passive-emulable, while squeezing generators grow the closure out to the larger symplectic algebra sp(2n,R), of dimension n(2n+1).

**Source:** Hall, B. C. (2015). Lie groups, Lie algebras, and representations: An elementary introduction (2nd ed., Graduate Texts in Mathematics, Vol. 222). Springer. https://doi.org/10.1007/978-3-319-13467-3 — <https://doi.org/10.1007/978-3-319-13467-3>

### Real symplectic Lie algebra sp(2n,R) / symplectic group
*In-essay notation / aliases:* symplectic algebra sp(2n,R), sp(2n,R), sp(4,R), sp(2,R), full symplectic algebra, dimension n(2n+1)

The real symplectic group Sp(2n,R) is the group of real 2n×2n matrices M preserving the symplectic form Ω, MᵀΩM = Ω; on n bosonic modes it generates the linear (Gaussian) quadrature dynamics. Its Lie algebra sp(2n,R) consists of the real 2n×2n matrices A satisfying AᵀΩ + ΩA = 0, and has dimension n(2n+1). It is noncompact, and contains the compact u(n) of passive beamsplitter-and-phase optics as a subalgebra (dimension n²); the extra generators are squeezers. In the audit here, a passive two-mode interferometer stays inside u(2) (dimension 4), adding the two-mode squeezer closes all of sp(4,R) (dimension 10), and a single squeezed mode already fills sp(2,R) (dimension 3).

**Source:** Arvind, Dutta, B., Mukunda, N., & Simon, R. (1995). The real symplectic groups in quantum mechanics and optics. Pramana, 45(6), 471-497. — <https://arxiv.org/abs/quant-ph/9509002>

### Dynamical Lie algebra (DLA) / iterated-commutator (Lie) closure
*In-essay notation / aliases:* Lie closure, iterated-commutator closure, closure, closure dimension, dynamical Lie algebra, qubit-side Lie closure grows as 4^n - 1

The dynamical Lie algebra of a set of generators — here the declared optical generators (phases, beamsplitters, squeezers), written in the 2n×2n real quadrature representation — is the smallest Lie algebra containing them and closed under commutation [A,B] = AB − BA. The audit computes it by repeatedly appending commutators until the spanned dimension stops growing (its FixedPoint closure), reading off that dimension by exact rank. It then asks whether the closure stays inside the compact algebra u(n) — realized here as antisymmetric matrices, dimension at most n² — or reaches the full real symplectic algebra sp(2n,R), the matrices M with MᵀΩ + ΩM = 0 for the symplectic form Ω, dimension n(2n+1). The DLA fixes which dynamics the generators can reach; the passive verdict requires every closure element antisymmetric and closure dimension at most n².

**Source:** D'Alessandro, D. (2007). Introduction to quantum control and dynamics. Chapman & Hall/CRC. https://doi.org/10.1201/9781584888833 — <https://doi.org/10.1201/9781584888833>

### Antisymmetric-matrix (compact-algebra) characterization
*In-essay notation / aliases:* every element antisymmetric, Transpose[#] === -#, skew-symmetric generators, compact-algebra characterization, staying inside u(n) means antisymmetric

In the real quadrature representation on n optical modes, the audit writes each declared generator as a 2n×2n matrix acting on position–momentum coordinates; every such matrix lies in the symplectic algebra sp(2n,R) = {M : MᵀΩ + ΩM = 0} for the symplectic form Ω, dimension n(2n+1). The compact-algebra characterization pins down its maximal compact subalgebra u(n) — the passive beamsplitter-and-phase generators, dimension n² — via the criterion that a symplectic generator lies in u(n) exactly when its quadrature matrix is antisymmetric, Transpose[M] === −M. The verdict tests the full commutator closure: every element antisymmetric and closure rank at most n² means the design is passive-linear-optics reproducible; any element escaping antisymmetry signals genuine squeezing into the full sp(2n,R).

**Source:** Arvind, Dutta, B., Mukunda, N., & Simon, R. (1995). The real symplectic groups in quantum mechanics and optics. Pramana, 45(6), 471–497. https://doi.org/10.1007/BF02848172 — <https://arxiv.org/abs/quant-ph/9509002>

### Classical intensity emulator (intensity forger)
*In-essay notation / aliases:* classical intensity emulators, intensity forger, classical light beam split and redistributed with tuned intensities, classical fake, impostor

A classical intensity emulator (intensity forger) is an adversarial device that imitates a quantum black box using only a classical light beam split and redistributed across modes with tuned intensities. Because such a beam can reproduce any consistent table of click frequencies — the quantum-optimal one included — statistics alone cannot certify a genuinely quantum interior, which is why the essay adds a dynamics audit. The forger is confined to passive linear optics (phase shifters and beamsplitters), whose generators close inside the compact algebra u(n) of n×n anti-Hermitian matrices, dimension n²; genuine squeezing would instead escape into sp(2n,R), dimension n(2n+1). Against exactly this impostor class the certification battery is provably complete — a conditional theorem resting on one stated detector-physics premise.

**Source:** Spreeuw, R. J. C. (1998). A classical analogy of entanglement. Foundations of Physics, 28(3), 361–374. https://doi.org/10.1023/A:1018703709245 — <https://doi.org/10.1023/A:1018703709245>

### Quadrature representation / quadrature operators
*In-essay notation / aliases:* quadrature representation, quadratures, symplectic form omega[n], the 2n x 2n real generator matrices, quadratic-form generators qf

In the continuous-variable picture used here, each optical mode j carries two Hermitian quadrature operators — a position-like x̂_j and a momentum-like p̂_j, obeying the canonical commutator [x̂_j, p̂_k] = i δ_jk. The 2n quadratures of n modes stack into one real vector whose commutation structure is packaged by the symplectic form Ω (the code's omega[n], n block-diagonal copies of [[0,1],[-1,0]]). Any Hamiltonian quadratic in these quadratures generates a linear, Ω-preserving flow, so its generator is a real 2n×2n matrix Ω·qf acting on the quadrature vector — which is why the audit's generators are real 2n×2n matrices, passive optics closing in u(n) and squeezing reaching sp(2n,R).

**Source:** Weedbrook, C., Pirandola, S., García-Patrón, R., Cerf, N. J., Ralph, T. C., Shapiro, J. H., & Lloyd, S. (2012). Gaussian quantum information. Reviews of Modern Physics, 84(2), 621–669. https://doi.org/10.1103/RevModPhys.84.621 — <https://doi.org/10.1103/RevModPhys.84.621>

### Analogue Hawking radiation / analogue gravity
*In-essay notation / aliases:* analogue-Hawking channel, analogue-Hawking dynamics, horizon, pair production at the horizon, two-mode squeezer that models a horizon, free phase evolution + graybody backscatter + pair production

Analogue gravity is a research programme that reproduces features of curved-spacetime physics — event horizons above all — inside laboratory systems such as flowing fluids or nonlinear optical media, where small perturbations propagate along an effective metric instead of in real gravity. Analogue Hawking radiation is the thermal pair-creation such a mimicked horizon emits, the tabletop counterpart of a black hole's Hawking radiation. In this essay's audit the analogue-Hawking channel is modeled on two optical modes as free phase evolution, a graybody-backscatter beamsplitter, and horizon pair production as a two-mode squeezer; that squeezer lifts the dynamical Lie algebra from u(2) to the full sp(4,R), producing the "beyond passive optics" verdict.

**Source:** Barceló, C., Liberati, S., & Visser, M. (2005). Analogue gravity. Living Reviews in Relativity, 8, 12. https://doi.org/10.12942/lrr-2005-12 — <https://arxiv.org/abs/gr-qc/0505065>

### Graybody factor
*In-essay notation / aliases:* graybody beamsplitter, graybody backscatter, greybody factor

In black-hole physics, Hawking emission is not a perfect blackbody: quanta escaping the horizon backscatter off the surrounding curvature potential barrier, and the graybody factor Γ(ω) is the frequency-dependent transmission probability, 0 ≤ Γ(ω) ≤ 1, that multiplies the ideal Planck spectrum to give the actual emitted flux — the measure of how far the spectrum departs from a blackbody. In the essay's analogue-Hawking audit this horizon transmission is represented as a passive beamsplitter — the graybody beamsplitter generator (bsRe/bsIm) — mixing the two optical modes between free phase evolution and the two-mode squeezer that models pair production.

**Source:** Page, D. N. (1976). Particle emission rates from a black hole: Massless particles from an uncharged, nonrotating hole. Physical Review D, 13(2), 198–206. https://doi.org/10.1103/PhysRevD.13.198 — <https://doi.org/10.1103/PhysRevD.13.198>

### Gaussian states and operations (efficiently classically simulable)
*In-essay notation / aliases:* Gaussian, being Gaussian remain efficiently classically simulable, Gaussian correlations

A Gaussian state of continuous-variable (bosonic) modes is one whose Wigner quasiprobability is a Gaussian, so it is fixed entirely by its first moments (mean quadratures) and its quadrature covariance matrix; Gaussian operations — quadrature-linear maps such as phase shifts, beamsplitters, single- and two-mode squeezing, and homodyne measurement — send Gaussian states to Gaussian states. Bartlett, Sanders, Braunstein and Nemoto (2002) proved that any process built solely from Gaussian preparations, operations, and measurements can be simulated on a classical computer in polynomial resources. Hence squeezing, though beyond passive optics dynamically, keeps the channel's correlations efficiently classically simulable.

**Source:** Bartlett, S. D., Sanders, B. C., Braunstein, S. L., & Nemoto, K. (2002). Efficient classical simulation of continuous variable quantum information processes. Physical Review Letters, 88(9), 097904. https://doi.org/10.1103/PhysRevLett.88.097904 — <https://arxiv.org/abs/quant-ph/0109047>
