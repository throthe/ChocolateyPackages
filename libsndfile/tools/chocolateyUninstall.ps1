$ErrorActionPreference = 'Stop'

$packageName = "${ENV:ChocolateyPackageName}"

$searchPaths = "${ENV:PROGRAMFILES}", "${ENV:PROGRAMFILES(x86)}", "${ENV:LOCALAPPDATA}"

$count = 0
$foundPath = $false

ForEach ($searchPath in $searchPaths) {
  $testPath = Join-Path "${searchPath}" "${packageName}"

  if (Test-Path "${testPath}") {
    if ($count -eq 0) {
      $foundPath = "${testPath}"
    }
    elseif ($count -eq 1) {
      Write-Warning "More than one match found!"
      Write-Warning "To prevent accidental data loss, no programs will be uninstalled."
      Write-Warning "Please alert the package maintainer that the following paths matched:"
      Write-Warning "${foundPath}"
      Write-Warning "${testPath}"
    }
    elseif ($count -gt 1) {
      Write-Warning "${testPath}"
    }

    $count += 1
  }
}

if ($count -eq 1) {
  Write-Output "Removing ${foundPath}..."
  Remove-Item -Recurse "${foundPath}"
  Write-Output "Removed"
}
else {
  exit 1
}
