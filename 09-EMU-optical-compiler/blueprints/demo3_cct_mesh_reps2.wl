<|"TargetSpec" -> <|"Word" -> "cct", "Reps" -> 2|>, "ModeCount" -> 18, 
 "Layer" -> "Mesh", "Stages" -> {<|"Type" -> "Block", "Index" -> 0, 
    "Modes" -> {1, 2, 3}, "Letter" -> "c", "Label" -> "P1"|>, 
   <|"Type" -> "Block", "Index" -> 1, "Modes" -> {4, 5, 6}, "Letter" -> "c", 
    "Label" -> "P2"|>, <|"Type" -> "Block", "Index" -> 2, 
    "Modes" -> {7, 8, 9}, "Letter" -> "t", "Label" -> "P3"|>, 
   <|"Type" -> "Block", "Index" -> 3, "Modes" -> {10, 11, 12}, 
    "Letter" -> "c", "Label" -> "P4"|>, <|"Type" -> "Block", "Index" -> 4, 
    "Modes" -> {13, 14, 15}, "Letter" -> "c", "Label" -> "P5"|>, 
   <|"Type" -> "Block", "Index" -> 5, "Modes" -> {16, 17, 18}, 
    "Letter" -> "t", "Label" -> "P6"|>}, 
 "Routing" -> {<|"From" -> 0, "To" -> 1, "SharedModes" -> {1, 2}, 
    "Orientation" -> "cis"|>, <|"From" -> 1, "To" -> 2, 
    "SharedModes" -> {4, 5}, "Orientation" -> "cis"|>, 
   <|"From" -> 2, "To" -> 3, "SharedModes" -> {7, 8}, 
    "Orientation" -> "trans"|>, <|"From" -> 3, "To" -> 4, 
    "SharedModes" -> {10, 11}, "Orientation" -> "cis"|>, 
   <|"From" -> 4, "To" -> 5, "SharedModes" -> {13, 14}, 
    "Orientation" -> "cis"|>}, "IntensitySchedule" -> Missing[], 
 "Unitary" -> Missing[], "MeshEdgeList" -> {{16, 17}, {1, 17}, {1, 2}, {2, 
  3}, {3, 16}, {1, 4}, {4, 5}, {5, 6}, {2, 6}, {4, 7}, {7, 8}, {8, 9}, {5, 
  9}, {8, 10}, {10, 11}, {11, 12}, {7, 12}, {10, 13}, {13, 14}, {14, 15}, 
  {11, 15}, {13, 16}, {17, 18}, {14, 18}}, "CertificationVerdict" -> 
  <|"Mesh" -> <|"Name" -> "pentagon-mesh", "Span" -> 2, "DLADimension" -> 3, 
     "LeafConfined" -> False, "Verdict" -> "genuine", "Layer" -> "Mesh", 
     "Blocks" -> {<|"Block" -> 0, "Modes" -> {1, 2, 3}, "Letter" -> "c", 
        "CycleVerified" -> True, "InBlueprintEdgeList" -> True, "Span" -> 2, 
        "DLADimension" -> 3, "LeafConfined" -> False, 
        "Verdict" -> "genuine"|>, <|"Block" -> 1, "Modes" -> {4, 5, 6}, 
        "Letter" -> "c", "CycleVerified" -> True, "InBlueprintEdgeList" -> 
         True, "Span" -> 2, "DLADimension" -> 3, "LeafConfined" -> False, 
        "Verdict" -> "genuine"|>, <|"Block" -> 2, "Modes" -> {7, 8, 9}, 
        "Letter" -> "t", "CycleVerified" -> True, "InBlueprintEdgeList" -> 
         True, "Span" -> 2, "DLADimension" -> 3, "LeafConfined" -> False, 
        "Verdict" -> "genuine"|>, <|"Block" -> 3, "Modes" -> {10, 11, 12}, 
        "Letter" -> "c", "CycleVerified" -> True, "InBlueprintEdgeList" -> 
         True, "Span" -> 2, "DLADimension" -> 3, "LeafConfined" -> False, 
        "Verdict" -> "genuine"|>, <|"Block" -> 4, "Modes" -> {13, 14, 15}, 
        "Letter" -> "c", "CycleVerified" -> True, "InBlueprintEdgeList" -> 
         True, "Span" -> 2, "DLADimension" -> 3, "LeafConfined" -> False, 
        "Verdict" -> "genuine"|>, <|"Block" -> 5, "Modes" -> {16, 17, 18}, 
        "Letter" -> "t", "CycleVerified" -> True, "InBlueprintEdgeList" -> 
         True, "Span" -> 2, "DLADimension" -> 3, "LeafConfined" -> False, 
        "Verdict" -> "genuine"|>}, "AllBlocksVerified" -> True, 
     "Method" -> "Per-block structural C5-isomorphism check against the \
blueprint's own stored edge list, then the existing so(3) \
CascadeGenerators/DLADimension audit reused per verified block (same \
n-independent-cascade precedent already used for Cn scenarios).", 
     "JointEntanglementAudited" -> False, "ScopeNote" -> "Per-block LOCAL \
genuineness only (block-local, per the compiler's honest scope). Makes no \
claim about joint/global entanglement across the mesh's su(2^n) qubits -- \
that route remains computationally infeasible past ~14 qubits \
(cct_cluster_dla.wl) and is a separate, open item."|>|>, 
 "Provenance" -> <|"Targets" -> <|"Word" -> "cct", "Reps" -> 2|>, 
   "Anchors" -> {"A1", "A2", "A3", "A4", "A5"}, "Date" -> "2026-07-13", 
   "Citations" -> {"BBT-002", "BBT-003", "MESH-004", "MESH-008", 
     "Frustaglia PRL116 250404", "Lapkiewicz Nature474 490"}|>, 
 "SelfCertification" -> <|"StatisticsMatch" -> True, "MaxDeviation" -> 0, 
   "TargetReproduced" -> True, "DLAVerdictConsistent" -> True, 
   "OK" -> True|>, "Schematic" -> "(exported separately)"|>
