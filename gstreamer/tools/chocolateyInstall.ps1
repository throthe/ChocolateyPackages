$ErrorActionPreference = 'Stop';

# Strip package YYYYMMDD postfix if present
$versionSplit   = ${ENV:ChocolateyPackageVersion}.Split('.')
$major          = ${versionSplit}[0]
$minor          = ${versionSplit}[1]
$revision       = ${versionSplit}[2]
$version        = "${major}.${minor}.${revision}"

$packageName    = "${ENV:ChocolateyPackageName}"
$packageTitle   = "${ENV:ChocolateyPackageTitle}"

$nameSplit      = ${packageName}.Split('-')
$toolchain      = "msvc"
$devel          = ""

# gstreamer, gstreamer-devel, gstreamer-mingw, or gstreamer-mingw-devel
if (${packageName}.Contains("devel")) {
  $devel = "devel-"
}
if (${nameSplit}.Length -gt 1 -and ${nameSplit}[1] -ne "devel") {
  $toolchain = ${nameSplit}[1]
}

$url            = "https://gstreamer.freedesktop.org/data/pkg/windows/${version}/${toolchain}/gstreamer-1.0-${devel}${toolchain}-x86-${version}.msi"
$url64          = "https://gstreamer.freedesktop.org/data/pkg/windows/${version}/${toolchain}/gstreamer-1.0-${devel}${toolchain}-x86_64-${version}.msi"
$silentArgs     = "ADDLOCAL=ALL /qn /norestart /l*v `"$(${ENV:TEMP})\$(${packageName}).$(${version}).MsiInstall.log`""

$packageArgs = @{
  packageName     = "${packageName}"
  softwareName    = "${packageTitle}"
  url             = "${url}"
  url64           = "${url64}"
  fileType        = "msi"
  silentArgs      = "${silentArgs}"
  validExitCodes  = @(0)
  checksum        = "<insert package checksum>"
  checksumType    = "sha256"
  checksum64      = "<insert package checksum>"
  checksumType64  = "sha256"
}

Install-ChocolateyPackage @packageArgs

Write-Output ""

# Must install to User path since we need to expand a User environment variable
if (${ENV:OS_IS64BIT} -And -Not ${ENV:ChocolateyForceX86}) {
  Install-ChocolateyPath -PathToInstall "%GSTREAMER_1_0_ROOT_$(${toolchain}.ToUpper())_X86_64%\bin" -PathType "User"
} else {
  Install-ChocolateyPath -PathToInstall "%GSTREAMER_1_0_ROOT_$(${toolchain}.ToUpper())_X86%\bin" -PathType "User"
}
