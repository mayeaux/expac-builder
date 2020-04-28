expac_pkg_getvar() {
	if [[ $# -lt 2 ]]; then
		(>&2 echo "Missing package name and variable name arguments")
		return 1
	fi

	local pkgname=$(expac_pkgname2prefix "$1")
	local varname="${pkgname}_${2}"
	shift 2
	local varval="${!varname}"

	if [[ -z "${varval}" ]]; then
		if [[ $# -gt 0 ]]; then
			echo "$@"
		else
			(>&2 echo "No variable default exists")
			return 1
		fi
	else
		echo "${varval}"
	fi
}

expac_pkgname2prefix() {
	if [[ ! $# -eq 1 ]]; then
		(>&2 echo "Missing package name")
		return 1
	fi

	local pkgname="$1"

	for (( i=0; i<"${#EXPAC_PACKAGES[@]}"; i++ )); do
		local pkg="${EXPAC_PACKAGES[$i]}"
		local name="${pkg#:*}"
		local prefix="${pkg#*:}"
		if [[ "${name}" == "${pkgname}" ]]; then
			echo "${prefix}"
			return 0
		fi
	done

	(>&2 echo "Invalid package name ${pkgname}")
	return 1
}

expac_pkgprefix2name() {
	if [[ ! $# -eq 1 ]]; then
		(>&2 echo "Missing package prefix")
		return 1
	fi

	local pkgprefix="$1"

	for (( i=0; i<"${#EXPAC_PACKAGES[@]}"; i++ )); do
		local pkg="${EXPAC_PACKAGES[$i]}"
		local name="${pkg#:*}"
		local prefix="${pkg#*:}"
		if [[ "${prefix}" == "${pkgprefix}" ]]; then
			echo "${name}"
			return 0
		fi
	done

	(>&2 echo "Invalid package prefix ${pkgprefix}")
	return 1
}

expac_addpkg() {
	if [[ ! $# -eq 2 ]]; then
		(>&2 echo "Missing package name and package variable prefix")
		return 1
	fi

	local pkgname="$1"
	local pkgprefix="$2"
	export EXPAC_PACKAGES+=("${pkgname}:${pkgprefix}")
	
	local pkgbuilder=$(expac_pkg_getvar "${pkgname}" BUILDER "custom")
	local pkgver=$(expac_pkg_getvar "${pkgname}" VERSION)
	local pkgrel=$(expac_pkg_getvar "${pkgname}" REL 1)
	local pkgepoch=$(expac_pkg_getvar "${pkgname}" EPOCH 0)

	if [[ ! "${EXPAC_BUILDERS[@]}" =~ "${pkgbuilder}" ]]; then
		(>&2 echo "Invalid package builder ${pkgbuilder}")
		return 1
	fi

	if [[ "${pkgepoch}" -gt 0 ]]; then
		local fullver="${pkgepoch}:"
	fi
	local fullver="${fullver}${pkgver}-${pkgrel}"

	export "${pkgprefix}_WORKSPACE_DIR"="${BUILD_DIR}/pkg-work/${pkgname}-${fullver}"
	export "${pkgprefix}_INSTALL_DIR"="${BUILD_DIR}/pkg-install/${pkgname}-${fullver}"
	export "${pkgprefix}_SOURCE_DIR"="${SOURCE_DIR}/${pkgname}"
}

expac_pkgbuild() {
	if [[ ! $# -eq 1 ]]; then
		(>&2 echo "Missing package name")
		return 1
	fi

	export PACKAGE_NAME="$1"
	local steps=($(expac_pkg_getvar "${PACKAGE_NAME}" STEPS "configure build install staging-install"))
	local pkgbuilder=$(expac_pkg_getvar "${PACKAGE_NAME}" BUILDER "custom")

# TODO: get dependencies and build those
# TODO: check steps

	if [[ "${steps[@]}" =~ "configure" ]]; then
		echo ">> Configuring package ${PACKAGE_NAME}"
		"${pkgbuilder}"_configure "${PACKAGE_NAME}"
	fi

	if [[ "${steps[@]}" =~ "build" ]]; then
		echo ">> Building package ${PACKAGE_NAME}"
		"${pkgbuilder}"_build "${PACKAGE_NAME}"
	fi

	if [[ "${steps[@]}" =~ "install" ]]; then
		echo ">> Installing package ${PACKAGE_NAME}"
		"${pkgbuilder}"_install "${PACKAGE_NAME}"
	fi

	if [[ "${steps[@]}" =~ "staging-install" ]]; then
		echo ">> Installing package ${PACKAGE_NAME} to staging directory"
		"${pkgbuilder}"_staging_install "${PACKAGE_NAME}"
	fi

# TODO: build subpackages
# TODO: pack the package

	unset PACKAGE_NAME
}
