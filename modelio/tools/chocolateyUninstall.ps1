$ErrorActionPreference = 'Stop'

$packageName    = "${ENV:ChocolateyPackageName}"
$silentArgs     = "/S /v /qn /norestart /l*v `"$(${ENV:TEMP})\$(${packageName}).$(${version}).Uninstall.log`""

$packageArgs = @{
  packageName     = "${packageName}"
  softwareName    = "Modelio Open Source*"
  fileType        = "exe"
  silentArgs      = "${silentArgs}"
  validExitCodes  = @(0)
}

[array]$key = Get-UninstallRegistryKey @packageArgs

if ($key.Count -eq 0) {
  Write-Warning "$packageName has already been uninstalled by other means."
}
elseif ($key.Count -eq 1) {
  $key | ForEach-Object {
    $packageArgs['file'] = $_.UninstallString

    Uninstall-ChocolateyPackage @packageArgs
  }
}
else {
  Write-Warning "$($key.Count) matches found!"
  Write-Warning "To prevent accidental data loss, no programs will be uninstalled."
  Write-Warning "Please alert the package maintainer that the following keys were matched:"
  $key | ForEach-Object { Write-Warning "- $($_.DisplayName)" }
}
