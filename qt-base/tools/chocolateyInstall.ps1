$ErrorActionPreference = 'Stop';

# Strip package YYYYMMDD postfix if present
$versionSplit   = ${ENV:ChocolateyPackageVersion}.Split('.')
$major          = ${versionSplit}[0]
$minor          = ${versionSplit}[1]
$revision       = ${versionSplit}[2]
$version        = "${major}.${minor}.${revision}"

$packageName    = "${ENV:ChocolateyPackageName}"
$packageTitle   = "${ENV:ChocolateyPackageTitle}"
$toolsDir       = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url            = "http://qt.mirror.constant.com/archive/online_installers/${major}.${minor}/qt-unified-windows-x86-${version}-online.exe"
$silentArgs     = ""      # Does not work: "--platform minimal"
$installArgs    = "-v --script ${toolsDir}/qt-installer-noninteractive.qs"

$pp = Get-PackageParameters
$errorMatch = "error"
$warnMatch = "warn|${errorMatch}"
$infoMatch = "info|${warnMatch}"
$debugMatch = "debug|${infoMatch}"
$logMatch = ${warnMatch}

Write-Output ${logMatch}

# Default to C:\Qt if no installDir was given
$installDir = $pp["installDir"]
if (!$installDir) {
  $installDir = "${ENV:SYSTEMDRIVE}\Qt"
  $pp["installDir"] = "${installDir}"
}

# Check if install directory is empty
if ((Test-Path -Path "${installDir}") -And (Get-ChildItem "${installDir}" | Measure-Object).Count -gt 0) {
  throw "Install directory ${installDir} must be empty."
}

# Pass package parameters through
foreach (${arg} in @("installDir")) {
  if ($pp[${arg}]) {
    $installArgs += " ${arg}=`"" + $pp[${arg}] + "`""
  }
}

# Set log level
if ($pp["logLevel"]) {
  $level = $pp["logLevel"]

  if ("${level}" -eq "error") {
    $logMatch = $errorMatch
  } elseif ("${level}" -eq "warn") {
    $logMatch = $warnMatch
  } elseif ("${level}" -eq "info") {
    $logMatch = $infoMatch
  } elseif ("${level}" -eq "debug") {
    $logMatch = $debugMatch
  } else {
    Write-Output "Unknown log level: ${level}"
    exit 1
  }
}

Write-Output "${installArgs}"

$packageArgs = @{
  packageName     = "${packageName}"
  softwareName    = "${packageTitle}"
  url             = "${url}"
  fileType        = "exe"
  silentArgs      = "${silentArgs} ${installArgs}"
  validExitCodes  = @(0)
  checksum        = "37E3731CABC2F3CF837AA9E0A539C78B81A7F97B8E7F61DFBF594E17760E9B6C"
  checksumType    = "sha256"
}

Install-ChocolateyPackage @packageArgs # | Select-String -Pattern "choco:(${logMatch})"

# Find the uninstall key for the install we just finished
$results = Get-UninstallRegistryKey -SoftwareName 'Qt'
$regPath = $False
foreach ($result in $results) {
  if ($result.InstallLocation -eq "${installDir}") {
    $regPath = $result.PSPath
    break
  }
}

if ($regPath) {

  New-ItemProperty -Path "${regPath}" -Name InstalledWithChocoPackage -Value ${ENV:ChocolateyPackageVersion} | Out-Null

} else {
  Write-Output "Registry debug information:"
  Write-Output ""
  foreach ($result in $results) {
    Write-Output (${results} | Get-Member -MemberType Properties)
    Write-Output ""
  }

  throw "Could not find registry entry with InstallLocation equal to ${installDir}."
}

# Consider once package is laid out
#Install-ChocolateyEnvironmentVariable -variableName "SOMEVAR" -variableValue "value" [-variableType = 'Machine' #Defaults to 'User']
#Install-ChocolateyPath "$installDir"
#$env:Path = "$($env:Path);$installDir"