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
  $pathType = "Machine"
  if (${ENV:OS_IS64BIT} -And ${ENV:ChocolateyForceX86}) {
    $parentFolder = "${ENV:PROGRAMFILES(x86)}"
  }
}
else {
  $parentFolder = "${ENV:LOCALAPPDATA}"
  $pathType = "User"
}

$installLocation = Join-Path "${parentFolder}" ${packageName}

# Create temp directory to extract the Zip to
# Create a unique directory name using a GUID and check it doesn't already
# exist, if it does loop again with new GUID
do {
    $tempPath = Join-Path -Path "${ENV:TEMP}" -ChildPath ([GUID]::NewGuid()).ToString()
}
while (Test-Path ${tempPath})
New-Item -Path ${tempPath} -ItemType Directory | Out-Null

$packageArgs = @{
  packageName     = "${packageName}"
  unzipLocation   = "${tempPath}"
  url             = "${url}"
  url64           = "${url64}"
  checksum        = "F8846AA0923BE05A3DBFFF2AABD2F76DCC3A4249579FBD16CC2BD12C0F88F5D6"
  checksumType    = "sha256"
  checksum64      = "B9DC71A36CE2A7F5816C0A30E7CFDAFC4B221F772153011B10C780230BDB95FB"
  checksumType64  = "sha256"
}

Install-ChocolateyZipPackage @packageArgs

Write-Output "Installing to ${installLocation}..."

# Zip should have an inner folder but tolerate that changing
$from = $null
if (-Not (Test-Path "${tempPath}\bin")) {
  $from = (Get-ChildItem "${tempPath}" -Directory).FullName
} else {
  $from = "${tempPath}"
}

# Remove old install
if (Test-Path "${installLocation}") {
  Remove-Item "${installLocation}" -Recurse -Force
}

Move-Item -Path "${from}" -Destination "${installLocation}"

# Cleanup
if (Test-Path "${tempPath}") {
  Remove-Item "${tempPath}" -Recurse -Force
}

Write-Output ""

Install-ChocolateyPath -PathToInstall "${installLocation}\bin" -PathType "${pathType}"
