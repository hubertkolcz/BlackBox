# Related work — curated additions (literature pass of 2026-07-13)

Product of a targeted three-axis search run for `REVIEW-2026-07-13.md`. This file lists works **not yet tracked** in the repo/PaperKB (plus a few anchors restated for completeness), each with its bearing on this project. **MUST-CITE** = a paper on this project could not honestly omit it. Works the project already cites (Cabello 1210.2988, CSW 1010.2163, Ulrey 2001.09756, AB 1102.0264, Camillo–Cervantes 2305.16574, Lapkiewicz Nature 474, Markiewicz npj QI 5,5, Zhang Sci.Rep. 7, Budroni et al. RMP 94, arXiv:2305.19247, Quad-C₅ 2605.12828, Hofmann 2507.22323, etc.) are not repeated here.

## Axis 1 — Lie-algebraic classical simulability (bears on O2 / LP-001..003)

- **MUST-CITE** Somma, Barnum, Ortiz, Knill, PRL 97, 190501 (2006), quant-ph/0601030 — origin of "poly-dim Lie algebra ⇒ poly-time classical simulation" for algebra-supported states/gates/observables. Foundational anchor for the DLA lens.
- **MUST-CITE** Goh, Larocca, Cincio, Cerezo, Sauvage, arXiv:2308.01432 ("g-sim") — the modern algorithmic form and its caveats (efficiency only for DLA-supported observables). The LP-001 hook's feasibility condition is literally this.
- **MUST-CITE** Ragone et al., Nat. Commun. 15, 7172 (2024), arXiv:2309.09342 — loss variance ∝ 1/dim(DLA); DLA dimension as *the* resource parameter. (Twin: Fontana et al., Nat. Commun. 15, 7171, arXiv:2309.07902.)
- **MUST-CITE** Cerezo et al., arXiv:2312.09121 — provable BP-absence ⇒ classical simulability *given an initial quantum data phase*. The sharpest statement + caveat of the arrow O2 leans on.
- **MUST-CITE** Aaronson–Arkhipov, Theory Comput. 9, 143 (2013), arXiv:1011.3245 — passive linear optics has tiny DLA (u(m)) yet Fock sampling is hard. Forces the scoping: DLA prices expectation values, not sampling.
- **MUST-CITE** Rodari et al., arXiv:2505.03001 (+ theory 2409.12223) — Lie-algebraic invariants as experimental benchmarks for quantum linear optics. Closest existing "DLA as certification lens"; no contextuality component — cite and differentiate.
- Wiersema, Kökcü, Kemper, Bakalov, npj QI 10 (2024), arXiv:2309.05690 (+ arXiv:2409.19797) — DLA classification tables; lookup tool for assigning a device's generator cascade to a class.
- Kökcü et al., PRL 129, 070501 (2022), arXiv:2104.00728 — Cartan fast-forwarding: constructive emulation recipe for small-DLA cascades.
- Anschuetz, Bauer, Kiani, Lloyd, Quantum 7, 1189 (2023), arXiv:2211.16998 — poly-size commutant suffices for simulability without small DLA; a *competing* algebraic criterion to distinguish from ours.
- Bärligea, Kottmann et al., arXiv:2604.16701 (2026) — g-sim is representation-sensitive; poly DLA is a structural promise realized only in an efficient basis. Qualifies the "DLA dim ⇒ emulable" arrow.
- Diaz et al., arXiv:2310.11505 — BP theory beyond the DLA; DLA is not the whole story. Present DLA as sufficient-for-emulation, not a dichotomy.
- Bartlett, Sanders, Braunstein, Nemoto, PRL 88, 097904 (2002) — CV Gottesman–Knill; the null hypothesis "classically-optically-emulable" formalized. (Shared anchor with Axis 4.)

## Axis 2 — Contextuality as classical-simulation cost (the incumbent metric to position against)

- **MUST-CITE** Kleinmann, Gühne, Portillo, Larsson, Cabello, NJP 13, 113011 (2011), arXiv:1007.3650 — memory cost of simulating sequential contextuality; the original correlation⇒classical-resource bridge and direct ancestor of the two-lens idea.
- **MUST-CITE** Karanjai, Wallman, Bartlett, arXiv:1802.07744 — contextuality lower-bounds classical memory of *any* simulation of a sub-theory. The closest quantitative "correlation certificate ⇒ simulation cost" result; the DLA lens must be contrasted with this memory lens.
- Trandafir, Kelleher, Cabello, arXiv:2506.06869 (2025) — memory cost with Pauli observables; the program is active in Cabello's own group.
- arXiv:2606.23577 (2026) — KS contextuality as classical *coordination* cost (KCBS covered); third live variant of contextuality-as-overhead.

## Axis 3 — Self-testing / black-box certification of contextuality (bears on O3 / BBT)

- **MUST-CITE** Bharti, Ray, Varvitsiotis, Warsi, Cabello, Kwek, PRL 122, 250403 (2019), arXiv:1812.07265 — robust self-testing from KCBS-type inequalities (single unentangled system, CSW-based). Defines which assumptions the intensity-emulator adversary attacks. (Follow-ups: Quantum 4, 302 (2020) SOS robustness; arXiv:1911.09448 high-dimensional programmable devices.)
- **MUST-CITE** Hu et al., npj QI 9, 103 (2023), arXiv:2203.09003 — first experimental single-system self-test (trapped ion, KCBS). Assumes quantum measurements — i.e., does **not** exclude our intensity emulator; that is our differentiator.
- **MUST-CITE** Šupić–Bowles, Quantum 4, 337 (2020) — self-testing review; framing reference for "strongest black-box certification."
- **MUST-CITE** Eisert et al., Nat. Rev. Phys. 2, 382 (2020) — certification taxonomy by trust level; locates our protocol on the trust axis.
- **MUST-CITE** Giordani et al., Sci. Adv. 9, eadj4249 (2023), arXiv:2311.03266 — certification of contextuality/coherence/dimension on a programmable photonic processor; nearest experimental neighbour to BBT — position against it.
- **MUST-CITE** Gühne, Budroni, Cabello, Kleinmann, Larsson, PRA 89, 062107 (2014) — dimension bounds from contextuality (KCBS as dimension witness). (Also Ray et al., NJP 23, 033006 (2021), graph-theoretic dimension witnessing.)
- **MUST-CITE** Wang et al., Sci. Adv. 8, eabk1660 (2022) — loophole-free KS test (two ion species); mirror its loophole taxonomy in the BBT adversary analysis.
- Metger–Vidick, Quantum 5, 544 (2021) — single-device self-testing under computational (LWE) assumptions; the main competing route — contrast assumption bases.
- Um et al., Sci. Rep. 3, 1627 (2013); Jerger et al., Nat. Commun. 7, 12930 (2016) — KCBS-class tests on ions/superconductors: platform-independence of the pentagon test; classical-light emulation is a photonics-specific threat.
- Singh, Foreman, Bharti, Cabello, arXiv:2409.20082 (2024); Genzini et al., arXiv:2601.08392 (2026) — KCBS self-tests carry cryptographic weight (randomness expansion; on-chip SDI QRNG). Downstream users of exactly the assumptions BBT probes.
- Liu et al., arXiv:2605.18112 (2026) — sequential linear-optical KCBS with on-off detectors; the newest photonic methodology at precisely BBT's interface.
- Anders–Browne, PRL 102, 050502 (2009); Raussendorf, PRA 88, 022322 (2013) (+ review arXiv:2208.06624); Frembs, Roberts, Bartlett, NJP 20, 103011 (2018) — MBQC-contextuality foundations for the cluster-state leg (qudit case included).
- Li, Zhu, Hayashi, npj QI 9 (2023), arXiv:2305.10742; Meyer, Šupić, Grosshans, Markham, Quantum 10, 1961 (2026), arXiv:2404.03496 — adversarial graph-state verification / self-testing; state what BBT adds (the classical-optics adversary class).

## Axis 4 — Classical optical emulation of quantum statistics (the adversary, published)

- **MUST-CITE** Frustaglia, Baltanás, et al., Cabello, PRL 116, 250404 (2016), arXiv:1511.08144 — classical microwave circuits reproduce KCBS/CHSH statistics up to the *quantum* bounds (√5 included). The central competing result the certificate must defeat; companion to Zhang et al. (2017).
- **MUST-CITE** Spreeuw, Found. Phys. 28, 361 (1998) — founding "classical entanglement" paper; the adversary class's origin.
- **MUST-CITE** Qian, Little, Howell, Eberly, Optica 2, 611 (2015) — CHSH ≈ 2.54 with statistically classical fields.
- **MUST-CITE** Shen–Rosales-Guzmán, Laser Photon. Rev. 16, 2100533 (2022) — definitive review of classically-entangled structured light (the adversary's capability envelope).
- **MUST-CITE** Korolkova, Sánchez-Soto, Leuchs, Phil. Trans. R. Soc. A 382, 20230342 (2024), arXiv:2405.15692 — operational criterion separating entanglement from classical non-separability; express the BBT test in these terms.
- **MUST-CITE** Kovtoniuk, Bohmann, Semenov, arXiv:2601.13869 (2026) — any click statistics from a single unmodified on-off detector is coherent-state-forgeable; attenuation settings restore discrimination. The detector-level formalization of `BBT-002`'s blind spot + the standard fix. (Anchor: Sperling, Vogel, Agarwal, PRL 109, 093601 (2012), sub-binomial light.)
- **MUST-CITE** Hance, Krnic, Larsson, arXiv:2601.13109 (2026) — interferometry phenomenology is noncontextually modelable; KS-contextuality marks the genuinely nonclassical. Independent confirmation of the project's thesis. (Conceptual basis: Catani, Leifer, Schmid, Spekkens, Quantum 7, 1119 (2023).)
- Aiello et al., NJP 17, 043024 (2015); McLaren, Konrad, Forbes, PRA 92, 023833 (2015) — what intra-beam nonseparability can/cannot emulate; measurement side.
- Dutra, Baldijão, Terra Cunha, arXiv:2604.24735 (2026) — how KCBS/PM contextuality dies under decoherence; useful for the CF certificate's noise-robustness section.

## Axis 5 — Exclusivity-principle status (bears on D1)

- **MUST-CITE** Navascués, Guryanova, Hoban, Acín, Nat. Commun. 6, 6288 (2015), arXiv:1403.4621 — almost-quantum satisfies one-copy exclusivity (Local Orthogonality); finite-copy principles don't pin down Q. The boundary D1 lives on. (Also Sainz et al., Quantum 2, 87 (2018): almost-quantum violates Specker's principle.)
- **MUST-CITE** Cabello, PRA 100, 032120 (2019), arXiv:1801.06347 — quantum set derived exactly from GE + statistically independent realizations; the strongest "GE singles out ϑ" statement — D1's theoretical backbone.
- **MUST-CITE** Choudhary–Barbosa, arXiv:2411.09773 (2024/25) — Ramsey-theoretic proofs: no E-principle activation for n≥6-cycle PR boxes at 2–3 copies. Overlaps and partially subsumes `GE-002`'s C7/C9 numerics — engage explicitly in `02-D1-theory-frontier/`.
- Yan, PRL 110, 260406 (2013), arXiv:1303.4357 — E-principle with the complement scenario yields ϑ exactly for self-complementary vertex-transitive graphs (KCBS: √5).
- Nogueira, Vieira, Terra Cunha, PRA 111, 052418 (2025), arXiv:2411.09036 — within CSW: if all quantum behaviors occur in Nature, GE excludes all post-quantum behaviors. Recent support for the GE certificate.
- Amaral, Phil. Trans. R. Soc. A 377, 20190010 (2019), arXiv:1904.04182 — resource theory of contextuality; treat our certificates as monotones.

## Axis 6 — Analogue Hawking radiation (bears on O4 / HK)

- **MUST-CITE** Steinhauer, Nat. Phys. 12, 959 (2016), arXiv:1510.00621 — the entanglement claim via the CS witness; the chapter's experimental target. With: Leonhardt, Ann. Phys. 530, 1700114 (2018), arXiv:1609.03803 (critique) and Steinhauer's reply arXiv:1609.09017.
- **MUST-CITE** Busch–Parentani, PRD 89, 105024 (2014), arXiv:1403.3262 — the second-moment nonseparability criterion: one fixed commuting set ⇒ single context by construction. The witness HK-003 targets.
- **MUST-CITE** de Nova, Sols, Zapata, PRA 89, 043808 (2014) + NJP 17, 105003 (2015) — CS violation as the "unequivocal signature"; explicitly concedes restriction to quadratic witnesses — direct textual support for HK-003.
- **MUST-CITE** Isoard–Pavloff, PRL 124, 060401 (2020), arXiv:1909.02509 — state-of-the-art Bogoliubov theory of the measured correlator; all second moments of a Gaussian theory.
- **MUST-CITE** Kolobov, Golubkov, Muñoz de Nova, Steinhauer, Nat. Phys. 17, 362 (2021), arXiv:1910.09363 — stationarity/thermality case for spontaneity; no entanglement witness — the quantumness case rests on Gaussian-narrative plausibility.
- **MUST-CITE** Agullo, Brady, Kranas, PRL 128, 091301 (2022) + PRD 107, 085009 (2023) — Gaussian-QI treatment; entanglement extinguished at ambient T ~ T_H; the certification program lives inside covariance-matrix territory.
- **MUST-CITE** Ciliberto, Emig, Pavloff, Isoard, PRA 109, 063325 (2024), arXiv:2404.16497 — Bell violations for the BEC analogue via non-Gaussian (parity/pseudospin) measurements; the only beyond-second-moment escalation — nonlocality, *not* contextuality. Nearest neighbour to HK; cite and differentiate.
- **MUST-CITE** Hudson, Rep. Math. Phys. 6, 249 (1974) (+ Soto–Claverie 1983); Bartlett, Sanders, Braunstein, Nemoto, PRL 88, 097904 (2002) — Wigner-positivity of Gaussians; CV Gottesman–Knill. The anchors of HK-004. (Brady, arXiv:2512.24344 (2025): lecture notes casting analogue gravity natively in this Gaussian framework.)
- Michel–Coupechoux–Parentani, PRD 94, 084027 (2016); Wang, Jacobson, Edwards, Clark, PRA 96, 023616 (2017) — classical/stimulated mechanisms reproducing the correlation signature; the emulation loophole made concrete.
- Weinfurtner et al., PRL 106, 021302 (2011); Euvé et al., PRL 117, 121301 (2016); Drori et al., PRL 122, 010404 (2019); Procopio et al., Nature (2026), arXiv:2607.01118 — classical-platform and stimulated observations across water/fibre; kinematics is classically emulatable, so certification must come from elsewhere.
- Jacquet et al., PRL 130, 111501 (2023); Falque et al., PRL 135, 023401 (2025) + arXiv:2512.17807 — polariton frontier; still two-point observables. Shi et al., Nat. Commun. 14, 3263 (2023) — superconducting-chip simulator, programmed dynamics. Chandran–Fischer, arXiv:2604.02075 (2026) — negativity volume-law proposal; entanglement monotone on a Gaussian state, contextuality-free.

## Synthesis (what the searches established)

1. **No prior work combines correlation-level contextuality certificates with a DLA/Lie-algebraic emulatability criterion.** The incumbent "classical overhead" metric is memory cost (Kleinmann; Karanjai–Wallman–Bartlett; Trandafir); the only DLA-based verification work (Rodari) has no contextuality. The two-lens protocol is a genuine gap — provided the DLA lens is scoped to algebra-supported observable sectors (Aaronson–Arkhipov contrast) and the quantum-data caveat (Cerezo) is acknowledged.
2. **No published black-box test excludes a classical-optics intensity-emulator adversary.** Self-testing assumes quantum measurements (Hu et al.); classical fields provably reach the quantum bounds at the statistics level (Frustaglia; Qian; Zhang); the detector-level forgeability theorem (Kovtoniuk) and the operational boundary (Korolkova) supply the formal frame `BBT-002` needs. Nearest neighbours to position against: Giordani et al. (2023) and Hu et al. (2023).
3. **No work applies contextuality to analogue-Hawking certification.** The field is Gaussian second-moment machinery end-to-end; the one escalation is Bell-type (Ciliberto et al. 2024). `HK-003`/`HK-004` occupy unclaimed ground.
4. **D1's question is open with named obstructions on both sides** (almost-quantum passes one-copy GE; no activation for n≥6 cycles at low copies per Choudhary–Barbosa) — engage both.
