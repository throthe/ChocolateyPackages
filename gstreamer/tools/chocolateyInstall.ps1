$ErrorActionPreference = 'Stop';

$packageName    = "${ENV:ChocolateyPackageName}"
$packageTitle   = "${ENV:ChocolateyPackageTitle}"
$url64          = "https://gstreamer.freedesktop.org/data/pkg/windows/${ENV:ChocolateyPackageVersion}/gstreamer-1.0-msvc-x86_64-${ENV:ChocolateyPackageVersion}.msi"
$silentArgs     = "/qn /norestart /l*v `"$(${ENV:TEMP})\$(${packageName}).$(${ENV:chocolateyPackageVersion}).MsiInstall.log`""

$packageArgs = @{
  packageName     = "${packageName}"
  softwareName    = "${packageTitle}"
  url64           = "${url64}"
  fileType        = "msi"
  silentArgs      = "${silentArgs}"
  validExitCodes  = @(0)
  checksum64      = "F33FFF17A558A433B9C4CF7BD9A338A3D0867FA2D5EE1EE33D249B6A55E8A297"
  checksumType64  = "sha256"
}

Install-ChocolateyPackage @packageArgs

Write-Output ""

# Must install to User path since we need to expand a User environment variable
if (${ENV:OS_IS64BIT} -And -Not ${ENV:ChocolateyForceX86}) {
  Install-ChocolateyPath -PathToInstall "%GSTREAMER_1_0_ROOT_X86_64%\bin" -PathType "User"
} else {
  Install-ChocolateyPath -PathToInstall "%GSTREAMER_1_0_ROOT_X86%\bin" -PathType "User"
}