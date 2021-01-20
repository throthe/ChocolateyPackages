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
  checksum        = "909f41b7ea8bdc1a0b7f105e7731bca364b409320007fe7581be0ce20a18fc56"
  checksumType    = "sha256"
  checksum64      = "c5ddf9f64ecb4b509f24f3351c08e8ba48e0cbd1ea409018f86917b90ee79e91"
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