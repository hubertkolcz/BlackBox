(* Confirm CoefficientArrays[eqs, vars] return order and check Transpose-of-vector
   behavior, to verify the hypothesis that GenerateEpsilonCertificate_testK4.wl's
   Stage 2 has {Amat, bvec} = CoefficientArrays[...] SWAPPED (CoefficientArrays
   returns {constants, coeffMatrix}, i.e. {c0, c1}, not {c1, c0}). *)

vars = {x, y, z};
eqs = {2 x + 3 y - 1, x - z + 5};
{c0, c1} = CoefficientArrays[eqs, vars];
Print["c0 (expect constants {-1,5}): ", Normal[c0]];
Print["c1 (expect matrix {{2,3,0},{1,0,-1}}): ", Normal[c1]];
Print["Dimensions[Normal[c0]]: ", Dimensions[Normal[c0]]];
Print["Dimensions[Normal[c1]]: ", Dimensions[Normal[c1]]];

(* Now reproduce the actual bug pattern: swapped assignment *)
{AmatBUG, bvecBUG} = CoefficientArrays[eqs, vars];
AmatBUG = Normal[AmatBUG]; bvecBUG = -Normal[bvecBUG];
Print["AmatBUG (should be the WRONG, vector, thing): ", AmatBUG, "  -- MatrixQ: ", MatrixQ[AmatBUG]];
Print["bvecBUG (should be the WRONG, matrix, thing): ", bvecBUG, "  -- MatrixQ: ", MatrixQ[bvecBUG]];

x0 = {1, 1, 1};
residualBUG = Quiet[Check[AmatBUG.x0 - bvecBUG, "DOT_FAILED"]];
Print["residualBUG = AmatBUG.x0 - bvecBUG: ", residualBUG];
Print["Transpose[AmatBUG] (vector transpose): ", Quiet[Check[Transpose[AmatBUG], "TRANSPOSE_FAILED"]]];
prodBUG = Quiet[Check[AmatBUG.Transpose[AmatBUG], "PROD_FAILED"]];
Print["AmatBUG.Transpose[AmatBUG]: ", prodBUG, "  -- is this a bare number? ", NumberQ[prodBUG]];

(* CORRECT version *)
{bvecOK, AmatOK} = CoefficientArrays[eqs, vars];
AmatOK = Normal[AmatOK]; bvecOK = -Normal[bvecOK];
Print["AmatOK (should be the coeff matrix): ", AmatOK, "  -- MatrixQ: ", MatrixQ[AmatOK]];
Print["bvecOK (should be the constants vector): ", bvecOK, "  -- MatrixQ: ", MatrixQ[bvecOK]];
residualOK = AmatOK.x0 - bvecOK;
Print["residualOK: ", residualOK];
Print["AmatOK.Transpose[AmatOK]: ", AmatOK.Transpose[AmatOK], "  -- MatrixQ: ", MatrixQ[AmatOK.Transpose[AmatOK]]];
