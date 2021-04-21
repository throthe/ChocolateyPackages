
# Set the nuspec version field for PACKAGE_NAME to VERSION
function bump-nuspec-version() {
    package="${1}"
    new_version="${2}"
    new_maj_min="${new_version%.*}"

    if [ -z "${package}" ] || [ -z "${new_version}" ]; then
        echo "Usage: ${FUNCNAME[0]} PACKAGE_NAME VERSION"
        return 1
    fi

    current_version=$(sed -nr 's|<version>(.+)</version>|\1|p' "${package}.nuspec" | xargs)
    current_maj_min="${current_version%.*}"

    echo "Current version: ${current_version}"
    echo "Major minor: ${current_maj_min}"
    echo
    echo "New version: ${new_version}"
    echo "Major minor: ${new_maj_min}"
    echo

    # Make sure we actually stripped a segment
    # And that we didn't strip too much
    if [ "${current_maj_min}" == "${current_version}" ] ||
    [ "${current_maj_min}" == "${current_maj_min%.*}" ]; then
        echo "Issues parsing current version"
        echo
        return 1
    fi

    # Replace the full version
    # Replace the major.minor version
    sed -r -i "s|${current_version}|${new_version}|g" "${package}.nuspec"
    sed -r -i "s|${current_maj_min}|${new_maj_min}|g" "${package}.nuspec"
}

function replace-checksums() {
    checksum="${1}"
    checksum_64="${2}"

    if [ -z "${checksum}" ] || [ -z "${checksum_64}" ]; then
        echo "Usage: ${FUNCNAME[0]} CHECKSUM CHECKSUM_64"
    fi

    echo "x86 Checksum: ${checksum}"
    echo "x64 Checksum: ${checksum_64}"
    echo

    sed -r -i "s|(checksum[ ]+=[ ]+)\"[^\"]*\"|\1\"${checksum}\"|" tools/chocolateyInstall.ps1
    sed -r -i "s|(checksum64[ ]+=[ ]+)\"[^\"]*\"|\1\"${checksum_64}\"|" tools/chocolateyInstall.ps1
}

function package-and-test() {
    package="${1}"

    if [ -z "${package}" ]; then
        echo "Usage: ${FUNCNAME[0]} PACKAGE_NAME"
        return 1
    fi

    windows_dir=$(powershell.exe -c 'echo "${PWD}"')
    echo "Windows Directory: ${windows_dir}"
    echo

    # Assume choco is on WSL path as well
    choco.exe pack "${package}.nuspec"

    script="
    choco install -y '${package}' --source . --x86 ;
    pause ;
    choco uninstall -y --removedependencies '${package}' ;
    pause ;
    choco install -y '${package}' --source . ;
    pause ;
    choco uninstall -y --removedependencies '${package}' ;
    pause ;
    "
    echo "Testing x86 install, x86 uninstall, x64 install, x64 uninstall..."

    # Start an admin PowerShell to take care of the install
    powershell.exe -c "Start-Process powershell.exe -ArgumentList \"
    echo ${windows_dir} ;
    cd ${windows_dir} ;
    ${script}
    \" -Verb RunAs"

    read -p "Waiting for any key..."
}

function choco-push() {
    package="${1}"
    version="${2}"

    if [ -z "${package}" ] || [ -z "${version}" ]; then
        echo "Usage: ${FUNCNAME[0]} PACKAGE_NAME VERSION"
        return 1
    fi

    choco.exe push -source https://push.chocolatey.org/ "${package}.${version}.nupkg"
}

function commit-and-push() {
    package="${1}"
    version="${2}"

    if [ -z "${package}" ] || [ -z "${version}" ]; then
        echo "Usage: ${FUNCNAME[0]} PACKAGE_NAME VERSION"
        return 1
    fi

    git add .
    git diff --cached

    echo
    read -p "Waiting for confirmation..."
    echo

    git commit -m "Release ${package} ${version}"
    git push origin main
}

function calc-sha256() {
    binary="${1}"

    if [ -z "${binary}" ]; then
        echo "Usage: ${FUNCNAME[0]} PATH_TO_BINARY"
        return 1
    fi

    sha256sum -b "${binary}" | cut -d ' ' -f 1
}
