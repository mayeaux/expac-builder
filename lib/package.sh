# Get a variable of a package
package_getvar() {
	if [[ ! $# -eq 1 ]]; then
		(>&2 echo "Requires at least one argument")
		return 1
	fi

# Check if PACKAGE_NAME is set
	if [[ -z "${PACKAGE_NAME}" ]]; then
		local PACKAGE_NAME="$1"
		shift 1
	fi

# Check if our package has the variable
	local var_name="${PACKAGE_NAME}_${1}"
	if [[ -z "${!var_name}" ]]; then
# Check if variable default exists
		if [[ $# -eq 1 ]]; then
			echo "${2}"
		else
			echo "${var_name}"
		fi
	else
		(>&2 echo "Variable ${1} does not exist for package ${PACKAGE_NAME}")
		return 1
	fi
}

# Sets a package variable
package_setvar() {
	if [[ ! $# -eq 1 ]]; then
		(>&2 echo "Requires at least one argument")
		return 1
	fi

# Check if PACKAGE_NAME is set
	if [[ -z "${PACKAGE_NAME}" ]]; then
		local PACKAGE_NAME="$1"
		shift 1
	fi

	local var_name="$1"
	shift 1
	export "${PACKAGE_NAME}_${var_name}"="$@"
}

# Internal function to setup a package's variables
package_setup() {
# Check if PACKAGE_NAME is set
	if [[ -z "${PACKAGE_NAME}" ]]; then
		local PACKAGE_NAME="$1"
		shift 1
	fi

# Set the variables
	export "${PACKAGE_NAME}_BUILD_DIR"="${BUILD_DIR}/pkg/${PACKAGE_NAME}"
	export "${PACKAGE_NAME}_INSTALL_DIR"="${BUILD_DIR}/pkg/${PACKAGE_NAME}/install"
}

# Downloads a package's files
package_download() {
# Check if PACKAGE_NAME is set
	if [[ -z "${PACKAGE_NAME}" ]]; then
		local PACKAGE_NAME="$1"
		shift 1
	fi

# Check if the checksums length match up with the source length
	local sources=$(package_getvar SOURCES)
	if [[ ! $(package_getvar CHECKSUMS >/dev/null) ]]; then
		local checksums=$(package_getvar CHECKSUMS)
		if [[ ! "${#checksums[@]}" -eq "${#sources[@]}" ]]; then
			(>&2 echo "Package ${PACKAGE_NAME} has an invalid checksum array")
			return 1
		fi
	fi

# Begin downloading
	local builddir=$(package_getvar BUILD_DIR)
	for (( i=0; i<"${#sources[@]}"; i++ )); do
		local src="${sources[$i]}"
		local checksum="${checksums[$i]}"
		if [[ ! -f "${builddir}"/$(basename "$src") ]]; then
			if [[ "${src}" =~ '(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]' ]]; then
				curl -L "$src" --silent -o "${builddir}"/$(basename "$src")
				if [[ ! $(${CHECKSUM_PROG}sum "${builddir}"/$(basename "$src")) == "${checksum}" ]]; then
					(>&2 echo "Package ${PACKAGE_NAME} soruce #$i has an invalid source checksum")
					return 1
				fi
				local fname=$(basename "$src")
				pushd "${builddir}" >/dev/null
				if [[ "${fname}" == *.tar.* ]]; then
					tar -xf "${builddir}/${fname}"
				elif [[ "${fname}" == *.zip ]]; then
					unzip "${builddir}/${fname}"
				fi
				popd >/dev/null
			elif [[ "${src}" == git+* ]]; then
				git clone -q --recursive "$src" "${builddir}"/$(basename "$src")
				pushd "${builddir}"/$(basename "$src") >/dev/null
				if [[ ! $(git rev-parse HEAD) == "${checksum}" ]]; then
					popd >/dev/null
					(>&2 echo "Package ${PACKAGE_NAME} soruce #$i has an invalid source checksum")
					return 1
				fi
			else
				(>&2 echo "Package ${PACKAGE_NAME} source #$i is an invalid source")
				return 1
			fi
		fi
	done
}

# Loads a package into the system
package_load() {
# Check if PACKAGE_NAME is set
	if [[ -z "${PACKAGE_NAME}" ]]; then
		export PACKAGE_NAME="$1"
		shift 1
	fi

# Check if WORKSPACE_DIR is set
	if [[ -z "${WORKSPACE_DIR}" ]]; then
		export WORKSPACE_DIR="$1"
		shift 1
	fi

# Load the package
	source "${WORKSPACE_DIR}/packages/${PACKAGE_NAME}/expac-build.sh"
	EXPAC_PACKAGES+=("${PACKAGE_NAME}")
	export EXPAC_PACKAGES

# Clean up
	unset PACKAGE_NAME WORKSPACE_DIR
}

# Prints a list of all the packages
packages_discover() {
# Check if PACKAGE_NAME is set
	if [[ -z "${PACKAGE_NAME}" ]]; then
		export PACKAGE_NAME="$1"
		shift 1
	fi

# Check if WORKSPACE_DIR is set
	if [[ -z "${WORKSPACE_DIR}" ]]; then
		export WORKSPACE_DIR="$1"
		shift 1
	fi

	find "${WORKSPACE_DIR}/packages/" -mindepth 1 -maxdepth 1 -type d | xargs -0 basename 
}
