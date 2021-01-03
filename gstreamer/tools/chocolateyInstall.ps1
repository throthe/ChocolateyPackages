$ErrorActionPreference = 'Stop';

# Strip package YYYYMMDD postfix if present
$versionSplit   = ${ENV:ChocolateyPackageVersion}.Split('.')
$major          = ${versionSplit}[0]
$minor          = ${versionSplit}[1]
$revision       = ${versionSplit}[2]
$version        = "${major}.${minor}.${revision}"

$packageName    = "${ENV:ChocolateyPackageName}"
$packageTitle   = "${ENV:ChocolateyPackageTitle}"
$url            = "https://gstreamer.freedesktop.org/data/pkg/windows/${version}/msvc/gstreamer-1.0-msvc-x86-${version}.msi"
$url64          = "https://gstreamer.freedesktop.org/data/pkg/windows/${version}/msvc/gstreamer-1.0-msvc-x86_64-${version}.msi"
$silentArgs     = "ADDLOCAL=ALL /qn /norestart /l*v `"$(${ENV:TEMP})\$(${packageName}).$(${version}).MsiInstall.log`""

$packageArgs = @{
  packageName     = "${packageName}"
  softwareName    = "${packageTitle}"
  url             = "${url}"
  url64           = "${url64}"
  fileType        = "msi"
  silentArgs      = "${silentArgs}"
  validExitCodes  = @(0)
  checksum        = "9f25a585703e990070ad2850dea2c4bfa76d3dbf3564173c0f16c0496f18b5ba"
  checksumType    = "sha256"
  checksum64      = "ca044a05b2ecb1cb7ed5628450d615d6f335ce7c5a4c39749336f891c4775cfa"
  checksumType64  = "sha256"
}

Install-ChocolateyPackage @packageArgs

Write-Output ""

# Must install to User path since we need to expand a User environment variable
if (${ENV:OS_IS64BIT} -And -Not ${ENV:ChocolateyForceX86}) {
  Install-ChocolateyPath -PathToInstall "%GSTREAMER_1_0_ROOT_MSVC_X86_64%\bin" -PathType "User"
} else {
  Install-ChocolateyPath -PathToInstall "%GSTREAMER_1_0_ROOT_MSVC_X86%\bin" -PathType "User"
}