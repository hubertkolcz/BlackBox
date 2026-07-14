# One-command verification of the whole repository (Windows PowerShell).
#   powershell -File RunAll.ps1
# Test battery runs plain -file from its own directory (it Prints its markers);
# each note runner uses -print all (its value is the verification Column).
$ws = "C:\Program Files\Wolfram Research\WolframScript\wolframscript.exe"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $root
$all = $true
Push-Location (Join-Path $repoRoot "BlackBox\Tests")
$out = & $ws -file BlackBoxTests.wl 2>&1 | Out-String
Pop-Location
$ok = ($out -match "ALL PASS: True") -and ($out -match "DEDUP PASS: True") -and ($out -match "UNIFY PASS: True")
if (-not $ok) { $all = $false }
Write-Output ("{0,-34} {1}" -f "BlackBox\Tests\BlackBoxTests.wl", $(if ($ok) { "OK" } else { "FAILED" }))
foreach ($f in @("RunBlackboxProtocol.wl", "RunEssay.wl", "RunCaseStudies.wl", "RunHeptagonCatalysis.wl",
    "RunBiphotonSimulator.wl", "RunWignerFlow.wl", "RunLedger.wl", "RunEpilogue.wl",
    "RunSupportCohomology.wl", "RunSignedNegativity.wl", "RunD1GECopiesSweep.wl",
    "RunD1K3Activation.wl", "RunSignalingTaxonomy.wl", "RunOpticalCompiler.wl",
    "RunGaussianHawking.wl", "RunGaussianWitnesses.wl",
    "RunSectionsFourToSix.wl", "RunEssaySectionsC.wl", "RunBlackBoxFrameworkEssay.wl")) {
  Push-Location $root
  $out = & $ws -file $f -print all 2>&1 | Out-String
  Pop-Location
  if ($f -eq "RunBlackboxProtocol.wl") {
    # Prints a validation report, not OK -> True; surface its Summary line (mirrors RunAll.sh).
    $summary = ($out -split "`r?`n" | Where-Object { $_ -match "Summary" } | Select-Object -First 1)
    $ok = [bool]$summary
    if (-not $ok) { $all = $false }
    Write-Output ("{0,-34} {1}" -f $f, $(if ($ok) { $summary } else { "NO SUMMARY LINE (inspect output)" }))
  } else {
    $ok = $out -match "OK -> True"
    if (-not $ok) { $all = $false }
    Write-Output ("{0,-34} {1}" -f $f, $(if ($ok) { "OK" } else { "FAILED" }))
  }
}
Write-Output ("REPOSITORY OK: {0}" -f $all)
if (-not $all) { exit 1 }
