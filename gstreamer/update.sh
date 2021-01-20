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

bump-nuspec-version "${package}" "${new_version}"

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

replace-checksums "${checksum}" "${checksum_64}"

package-and-test "${package}"

commit-and-push "${package}" "${new_version}"
