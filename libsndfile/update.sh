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
package="libsndfile"
new_version="${1}"
new_version_without_date="${new_version%.$(date +%Y)*}" # Ex: 1.1.1.20210725 -> 1.1.1

bump-nuspec-version "${package}" "${new_version}"

base_url="https://github.com/libsndfile/libsndfile/releases/download/${new_version_without_date}/libsndfile-${new_version_without_date}"
download_url="${base_url}-win32.zip"
download_url_64="${base_url}-win64.zip"

echo
echo "Fetching and calculating checksum for ${package}..."
echo "x86 Download URL: ${download_url}"
echo "x64 Download URL: ${download_url_64}"
echo
download="/tmp/$(basename ${download_url})"
download_64="/tmp/$(basename ${download_url_64})"
curl --location --fail --silent --show-error "${download_url}" -o "${download}"
curl --location --fail --silent --show-error "${download_url_64}" -o "${download_64}"

checksum=$(calc-sha256 "${download}")
checksum_64=$(calc-sha256 "${download_64}")
replace-checksum "checksum" "${checksum}"
replace-checksum "checksum64" "${checksum_64}"

package-and-test "${package}" "${new_version}"

choco-push "${package}" "${new_version}"

replace-checksum "checksum" "<insert checksum>"
replace-checksum "checksum64" "<insert checksum>"

commit-and-push "${package}" "${new_version}"
