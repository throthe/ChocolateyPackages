$ErrorActionPreference = 'Stop';

# Strip package YYYYMMDD postfix if present
$versionSplit   = ${ENV:ChocolateyPackageVersion}.Split('.')
$major          = ${versionSplit}[0]
$minor          = ${versionSplit}[1]
$revision       = ${versionSplit}[2]
$version        = "${major}.${minor}.${revision}"

$packageName    = "${ENV:ChocolateyPackageName}"
$packageTitle   = "${ENV:ChocolateyPackageTitle}"
$url64          = "https://github.com/ModelioOpenSource/Modelio/releases/download/v${version}/Windows.10.Modelio.Open.Source.${version}.-.64.exe"
$silentArgs     = "/S /v /qn /norestart /l*v `"$(${ENV:TEMP})\$(${packageName}).$(${version}).Install.log`""

$packageArgs = @{
  packageName     = "${packageName}"
  softwareName    = "${packageTitle}"
  url64           = "${url64}"
  fileType        = "exe"
  silentArgs      = "${silentArgs}"
  validExitCodes  = @(0)
  checksum64      = "C2B64A8A05884960568EB64F8A2EAEEB146C09B7B96FAA098B39C73EF1A7A258"
  checksumType64  = "sha256"
}

Install-ChocolateyPackage @packageArgs
