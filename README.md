# ChocolateyPackages #
Packages for the Chocolatey package manager.

## Quickstart ##

```powershell
# ADMINISTRATOR PowerShell

$PACKAGE_NAME=""
$API_KEY=""

cd "${PACKAGE_NAME}"
choco pack

choco install "${PACKAGE_NAME}" --source . --x86
choco uninstall "${PACKAGE_NAME}"

choco install "${PACKAGE_NAME}" --source .
# OR
# choco upgrade "${PACKAGE_NAME}" --source .
choco uninstall "${PACKAGE_NAME}"

choco apikey -k "${API_KEY}" -source https://push.chocolatey.org/
choco push -source https://push.chocolatey.org/
```

More: https://chocolatey.org/docs/CreatePackagesQuickStart