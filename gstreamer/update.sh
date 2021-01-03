#!/bin/bash

set -e
set -o pipefail
echo

source ../common.sh

function usage() {
    echo
    echo "update.sh VERSION"
    echo
}

if [ -z "${1}" ]; then
    usage
    exit 1
fi

old_dir="${PWD}"
package="gstreamer"
new_version="${1}"

bump-nuspec "${package}" "${new_version}"

download_url=$(sed -nr 's|\$url[ ]+=[ ]+"([^"]*)"|\1|p' tools/chocolateyInstall.ps1)
download_url_64=$(sed -nr 's|\$url64[ ]+=[ ]+"([^"]*)"|\1|p' tools/chocolateyInstall.ps1)

download_url=$(version="${new_version}" eval "echo ${download_url}")
download_url_64=$(version="${new_version}" eval "echo ${download_url_64}")

echo "x86 Download URL: ${download_url}"
echo "x64 Download URL: ${download_url_64}"
echo

echo "Fetching checksums..."
checksum=$(curl --fail --silent --show-error "${download_url}.sha256sum" | cut -d ' ' -f 1)
checksum_64=$(curl --fail --silent --show-error "${download_url_64}.sha256sum" | cut -d ' ' -f 1)

echo "x86 Checksum: ${checksum}"
echo "x64 Checksum: ${checksum_64}"
echo

sed -r -i "s|(checksum[ ]+=[ ]+)\"[^\"]*\"|\1\"${checksum}\"|" tools/chocolateyInstall.ps1
sed -r -i "s|(checksum64[ ]+=[ ]+)\"[^\"]*\"|\1\"${checksum_64}\"|" tools/chocolateyInstall.ps1

windows_dir=$(powershell.exe -c 'echo "${PWD}"')
echo "Windows Directory: ${windows_dir}"
echo

# Assume choco is on WSL path as well
choco.exe pack

if choco.exe list --local-only | grep "${package}"; then
    script="
    choco install -y '${package}' --source . ;
    "
    echo "Existing install found. Testing upgrade..."
else
    script="
    choco install -y '${package}' --source . --x86 ;
    choco uninstall -y '${package}' ;
    choco install -y '${package}' --source . ;
    choco uninstall -y '${package}' ;
    "
    echo "Testing x86 install, x86 uninstall, x64 install, x64 uninstall..."
fi

# Start an admin PowerShell to take care of the install
powershell.exe -c "Start-Process powershell.exe -ArgumentList \"
echo ${windows_dir} ;
cd ${windows_dir} ;
${script}
pause ;
\" -Verb RunAs"

git add .
git diff --cached

echo
read -p "Waiting for confirmation..."
echo

git commit -m "Release ${package} ${new_version}"

choco.exe push -source https://push.chocolatey.org/ "${package}.${new_version}.nupkg"
