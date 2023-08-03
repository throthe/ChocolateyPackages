$ErrorActionPreference = 'Stop';

# Strip package YYYYMMDD postfix if present
$versionSplit   = ${ENV:ChocolateyPackageVersion}.Split('.')
$major          = ${versionSplit}[0]
$minor          = ${versionSplit}[1]
$revision       = ${versionSplit}[2]
$version        = "${major}.${minor}.${revision}"

$packageName    = "${ENV:ChocolateyPackageName}"
$packageTitle   = "${ENV:ChocolateyPackageTitle}"
$url64          = "https://github.com/ModelioOpenSource/Modelio/releases/download/v${version}/Modelio.Open.Source.${version}.-.64.exe"
$silentArgs     = "/S /v /qn /norestart /l*v `"$(${ENV:TEMP})\$(${packageName}).$(${version}).Install.log`""

$packageArgs = @{
  packageName     = "${packageName}"
  softwareName    = "${packageTitle}"
  url64           = "${url64}"
  fileType        = "exe"
  silentArgs      = "${silentArgs}"
  validExitCodes  = @(0)
  checksum64      = "A0DFE06F07619003D3F3189801A8DF165FD51AFE9F06C5BE0E3887D8CAFE0B9E"
  checksumType64  = "sha256"
}

Install-ChocolateyPackage @packageArgs
