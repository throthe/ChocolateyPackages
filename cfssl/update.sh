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
package="cfssl"
new_version="${1}"
new_version_without_date="${new_version%.$(date +%Y)*}" # Ex: 1.1.1.20210725 -> 1.1.1

bump-nuspec-version "${package}" "${new_version}"

targets=("cfssl" "cfssl-bundle" "cfssl-certinfo" "cfssl-newkey" "cfssl-scan" "cfssljson" "mkbundle" "multirootca")
base_url="https://github.com/cloudflare/cfssl/releases/download/v${new_version_without_date}"

for name in ${targets[@]}; do
    download_url_64="${base_url}/${name}_${new_version_without_date}_windows_amd64.exe"

    echo
    echo "Fetching and calculating checksum for ${name}..."
    echo "x64 Download URL: ${download_url_64}"
    echo
    binary="/tmp/${name}.exe"
    curl --location --fail --silent --show-error "${download_url_64}" -o "${binary}"

    checksum_64=$(calc-sha256 "${binary}")
    replace-checksum "\"${name}\"" "${checksum_64}"
done

package-and-test "${package}"

choco-push "${package}" "${new_version}"

for name in ${targets[@]}; do
    replace-checksum "\"${name}\"" "<insert checksum>"
done

commit-and-push "${package}" "${new_version}"
