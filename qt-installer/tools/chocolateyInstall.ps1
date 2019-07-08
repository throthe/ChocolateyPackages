$ErrorActionPreference = 'Stop';

$v              = ${ENV:ChocolateyPackageVersion}.Split('.')
$maj            = ${v}[0]
$min            = ${v}[1]
$packageName    = "${ENV:ChocolateyPackageName}"
$packageTitle   = "${ENV:ChocolateyPackageTitle}"
$toolsDir       = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url            = "http://qt.mirror.constant.com/archive/online_installers/${maj}.${min}/qt-unified-windows-x86-${ENV:ChocolateyPackageVersion}-online.exe"
$silentArgs     = "--platform minimal"
$installArgs    = "-v --script ${toolsDir}/qt-installer-noninteractive.qs"

$pp = Get-PackageParameters
$logPattern = "'choco:warn|choco:error'"

# Pass the component list through
if ($pp["components"]) {
  $installArgs += "$pp['components']"
  echo "$pp['components']"
}

echo "Was verbose: ${ENV:ChocolateyEnvironmentVerbose}"
if (${ENV:ChocolateyEnvironmentVerbose}) {
  echo "Verbose enabled."
  $logPattern = "'choco:info|choco:warn|choco:error'"
}

echo "Was debug: ${ENV:ChocolateyEnvironmentDebug}"
if (${ENV:ChocolateyEnvironmentDebug}) {
  echo "Debug enabled."
  $logPattern = "'choco:debug|choco:info|choco:warn|choco:error'"
}

echo "${installArgs}"
echo "${ENV:ChocolateyPackageTitle}"

$packageArgs = @{
  packageName     = "${packageName}"
  softwareName    = "${packageTitle}"
  url             = "${url}"
  fileType        = "exe"
  silentArgs      = "${installArgs}" # -platform minimal
  validExitCodes  = @(0)
  checksum        = "37E3731CABC2F3CF837AA9E0A539C78B81A7F97B8E7F61DFBF594E17760E9B6C"
  checksumType    = "sha256"
}

Install-ChocolateyPackage @packageArgs | Tee-Object -FilePath ./full-log.txt | Select-String -Pattern choco -SimpleMatch

# Consider once package is laid out
#Install-ChocolateyEnvironmentVariable -variableName "SOMEVAR" -variableValue "value" [-variableType = 'Machine' #Defaults to 'User']
#Install-ChocolateyPath "$installDir"
#$env:Path = "$($env:Path);$installDir"