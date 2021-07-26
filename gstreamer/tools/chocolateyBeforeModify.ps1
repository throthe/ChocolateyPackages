$ErrorActionPreference = 'Stop';

$packageName = "${ENV:ChocolateyPackageName}"
$nameSplit = ${packageName}.Split('-')
$toolchain = "msvc"

if (${packageName}.Contains("devel")) {
    Write-Output "No PATH changes required for devel package. Exiting..."
    Exit
}

# gstreamer, gstreamer-devel, gstreamer-mingw, or gstreamer-mingw-devel
if (${nameSplit}.Length -gt 1 -and ${nameSplit}[1] -ne "devel") {
    $toolchain = ${nameSplit}[1]
}

# ENV:ChocolateyForceX86 appears to never be set for uninstall
# No --x86 flag exists on the command
if (${ENV:OS_IS64BIT} -And -Not ${ENV:ChocolateyForceX86}) {
    $pathForUninstall = "%GSTREAMER_1_0_ROOT_$(${toolchain}.ToUpper())_X86_64%\bin"
} else {
    $pathForUninstall = "%GSTREAMER_1_0_ROOT_$(${toolchain}.ToUpper())_X86%\bin"
}

if (-not (Get-Command 'Uninstall-ChocolateyPath' -errorAction SilentlyContinue)) {
    Write-Output "Using Uninstall-ChocolateyPath-GH1663 function";

    $toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
    $modulePath = Join-Path "${toolsDir}" 'Uninstall-ChocolateyPath-GH1663.ps1'
    Import-Module "${modulePath}"

    Uninstall-ChocolateyPath-GH1663 "${pathForUninstall}" "User"
}
else {
    Write-Debug "Using native Uninstall-ChocolateyPath function";

    Uninstall-ChocolateyPath "${pathForUninstall}" "User"
}
