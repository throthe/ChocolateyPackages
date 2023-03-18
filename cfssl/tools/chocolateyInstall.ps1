$ErrorActionPreference = "Stop"

# Strip package YYYYMMDD postfix if present
$versionSplit   = ${ENV:ChocolateyPackageVersion}.Split(".")
$major          = ${versionSplit}[0]
$minor          = ${versionSplit}[1]
$revision       = ${versionSplit}[2]
$version        = "${major}.${minor}.${revision}"

$packageName    = "${ENV:ChocolateyPackageName}"
$baseUrl64      = "https://github.com/cloudflare/cfssl/releases/download/v${version}"

$targets = [Ordered]@{
    "cfssl" = "<insert checksum>"
    "cfssl-bundle" = "<insert checksum>"
    "cfssl-certinfo" = "<insert checksum>"
    "cfssl-newkey" = "<insert checksum>"
    "cfssl-scan" = "<insert checksum>"
    "cfssljson" = "<insert checksum>"
    "mkbundle" = "<insert checksum>"
    "multirootca" = "<insert checksum>"
}

# Choose between Program Files, Program Files (x86), and Local App Data
if (Test-ProcessAdminRights) {
  $parentFolder = "${ENV:PROGRAMFILES}"
  $pathType = "Machine"
  if (${ENV:OS_IS64BIT} -Eq $true -And -Not (${ENV:ChocolateyForceX86} -Eq $true)) {
    $parentFolder = "${ENV:PROGRAMFILES(x86)}"
  }
}
else {
  $parentFolder = "${ENV:LOCALAPPDATA}"
  $pathType = "User"
}

$installLocation = Join-Path $(Join-Path "${parentFolder}" "CloudFlare") "${packageName}"

Write-Output "Installing to ${installLocation}..."

ForEach ($name in $targets.Keys) {
    $checksum = $targets[$name]
    Write-Output ""

    # https://github.com/cloudflare/cfssl/releases/download/v1.6.3/cfssl-bundle_1.6.3_darwin_amd64
    $url64 = "${baseUrl64}/${name}_${version}_windows_amd64.exe"
    $fileFullPath = Join-Path "${installLocation}" "${name}.exe"

    $packageArgs = @{
      packageName     = "${packageName}"
      fileFullPath    = "${fileFullPath}"
      url64           = "${url64}"
      checksum64      = "${checksum}"
      checksumType64  = "sha256"
      forceDownload   = $true
    }

    Get-ChocolateyWebFile @packageArgs
}

Write-Output ""

Install-ChocolateyPath -PathToInstall "${installLocation}" -PathType "${pathType}"
