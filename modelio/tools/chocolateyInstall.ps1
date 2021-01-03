$ErrorActionPreference = 'Stop';

# Strip package YYYYMMDD postfix if present
$versionSplit   = ${ENV:ChocolateyPackageVersion}.Split('.')
$major          = ${versionSplit}[0]
$minor          = ${versionSplit}[1]
$revision       = ${versionSplit}[2]
$version        = "${major}.${minor}.${revision}"

$packageName    = "${ENV:ChocolateyPackageName}"
$packageTitle   = "${ENV:ChocolateyPackageTitle}"
$url64          = "https://downloads.sourceforge.net/project/modeliouml/${version}/Modelio%20Open%20Source%20${version}%20-%2064.exe"
$silentArgs     = "/S /v /qn /norestart /l*v `"$(${ENV:TEMP})\$(${packageName}).$(${version}).Install.log`""

$packageArgs = @{
  packageName     = "${packageName}"
  softwareName    = "${packageTitle}"
  url64           = "${url64}"
  fileType        = "exe"
  silentArgs      = "${silentArgs}"
  validExitCodes  = @(0)
  checksum64      = "45A6C867DDC677074685161F43D07297D7473EB2B27AFD5B50E4D5991CDD2163"
  checksumType64  = "sha256"
}

Install-ChocolateyPackage @packageArgs
