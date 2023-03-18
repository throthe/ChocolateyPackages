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
new_version_without_date="${new_version%.$(date +%Y)*}" # Ex: 1.1.1.20210725 -> 1.1.1

packages=("gstreamer" "gstreamer-devel" "gstreamer-mingw" "gstreamer-mingw-devel")

for package in ${packages[@]}; do

    bump-nuspec-version "${package}" "${new_version}"

    download_url=$(sed -nr 's|\$url[ ]+=[ ]+"([^"]*)"|\1|p' tools/chocolateyInstall.ps1)
    download_url_64=$(sed -nr 's|\$url64[ ]+=[ ]+"([^"]*)"|\1|p' tools/chocolateyInstall.ps1)

    # This is pretty disgusting since it repeats chocolateyInstall.ps1, but it works for now
    toolchain="msvc"
    devel=""
    first=$(echo "${package}" | awk '{split($0, a, "-"); print a[2]}')
    second=$(echo "${package}" | awk '{split($0, a, "-"); print a[3]}')

    [ "${first}" != "devel" ] && [ ! -z "${first}" ] && toolchain="${first}"
    [ "${first}" == "devel" ] && devel="devel-"
    [ "${second}" == "devel" ] && devel="devel-"

    download_url=$(version="${new_version_without_date}" eval "echo ${download_url}")
    download_url_64=$(version="${new_version_without_date}" eval "echo ${download_url_64}")

    echo "x86 Download URL: ${download_url}"
    echo "x64 Download URL: ${download_url_64}"
    echo

    echo "Fetching checksums..."
    checksum=$(curl --fail --silent --show-error "${download_url}.sha256sum" | cut -d ' ' -f 1)
    checksum_64=$(curl --fail --silent --show-error "${download_url_64}.sha256sum" | cut -d ' ' -f 1)

    replace-checksums "${checksum}" "${checksum_64}"

    package-and-test "${package}" "${new_version}"

    choco-push "${package}" "${new_version}"
done

replace-checksums "<insert package checksum>" "<insert package checksum>"
commit-and-push "gstreamer" "${new_version}"
