
# Set the nuspec version field for PACKAGE_NAME to VERSION
function bump-nuspec() {
    package="${1}"
    new_version="${2}"
    new_maj_min="${new_version%.*}"

    if [ -z "${package}" ] || [ -z "${new_version}" ]; then
        echo "bump-nuspec PACKAGE_NAME VERSION"
        exit 1
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
        exit 1
    fi

    # Replace the full version
    # Replace the major.minor version
    sed -r -i "s|${current_version}|${new_version}|g" "${package}.nuspec"
    sed -r -i "s|${current_maj_min}|${new_maj_min}|g" "${package}.nuspec"
}
