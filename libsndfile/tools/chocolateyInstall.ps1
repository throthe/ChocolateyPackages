$ErrorActionPreference = 'Stop';

# Strip package YYYYMMDD postfix if present
$versionSplit   = ${ENV:ChocolateyPackageVersion}.Split('.')
$major          = ${versionSplit}[0]
$minor          = ${versionSplit}[1]
$revision       = ${versionSplit}[2]
$version        = "${major}.${minor}.${revision}"

$packageName    = "${ENV:ChocolateyPackageName}"
$url            = "https://github.com/libsndfile/libsndfile/releases/download/${version}/libsndfile-${version}-win32.zip"
$url64          = "https://github.com/libsndfile/libsndfile/releases/download/${version}/libsndfile-${version}-win64.zip"

# Choose between Program Files, Program Files (x86), and Local App Data
if (Test-ProcessAdminRights) {
  $parentFolder = "${ENV:PROGRAMFILES}"
  if (${ENV:OS_IS64BIT} -And ${ENV:ChocolateyForceX86}) {
    $parentFolder = "${ENV:PROGRAMFILES(x86)}"
  }
}
else {
  $parentFolder = "${ENV:LOCALAPPDATA}"
}

# Create temp directory to extract the Zip to
# Create a unique directory name using a GUID and check it doesn't already
# exist, if it does loop again with new GUID
do {
    $tempPath = Join-Path -Path "${env:TEMP}" -ChildPath ([GUID]::NewGuid()).ToString()
}
while (Test-Path ${tempPath})
New-Item -Path ${tempPath} -ItemType Directory | Out-Null

$installLocation = Join-Path "${parentFolder}" ${packageName}
Write-Output "Installing to ${installLocation}..."

if (-Not (Test-Path "${installLocation}")) {
  New-Item -ItemType directory -Path "${installLocation}" | Out-Null
}

$packageArgs = @{
  packageName     = "${packageName}"
  unzipLocation   = "${tempPath}"
  url             = "${url}"
  url64           = "${url64}"
  checksum        = "94780DD14BD27AFD90FF81B3A7412237ACABB77255CAACB25D48ACA14D9B3FAC"
  checksumType    = "sha256"
  checksum64      = "704CB34148D61CB4EE6B5D9E32AE8CC56D8F9BE95D7DD164FB3866EF597F0228"
  checksumType64  = "sha256"
}

Install-ChocolateyZipPackage @packageArgs

# Zip should have an inner folder
if (-Not (Test-Path "${tempPath}\bin")) {
  $folder = Get-ChildItem "${tempPath}" -Directory
  Get-ChildItem -Path ${folder}.FullName | Move-Item -Destination "${installLocation}"
  Remove-Item ${tempPath} -Recurse -Force
}

Write-Output ""

Install-ChocolateyPath -PathToInstall "${installLocation}\bin" -PathType Machine
