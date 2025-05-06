$ErrorActionPreference = 'Stop';

# Strip package YYYYMMDD postfix if present
$versionSplit   = ${ENV:ChocolateyPackageVersion}.Split('.')
$major          = ${versionSplit}[0]
$minor          = ${versionSplit}[1]
$revision       = ${versionSplit}[2]
$version        = "${major}.${minor}.${revision}"

$packageName    = "${ENV:ChocolateyPackageName}"
$packageTitle   = "${ENV:ChocolateyPackageTitle}"
$url64          = "https://github.com/ModelioOpenSource/Modelio/releases/download/v${version}/Modelio-Open-Source-${version}_64.exe"
$silentArgs     = "/S /v /qn /norestart /l*v `"$(${ENV:TEMP})\$(${packageName}).$(${version}).Install.log`""

$packageArgs = @{
  packageName     = "${packageName}"
  softwareName    = "${packageTitle}"
  url64           = "${url64}"
  fileType        = "exe"
  silentArgs      = "${silentArgs}"
  validExitCodes  = @(0)
  checksum64      = "1B1679EF75C968AB22CA4B06C04110C01883A48EEB1C0034041C0B974BA80216"
  checksumType64  = "sha256"
}

Install-ChocolateyPackage @packageArgs
