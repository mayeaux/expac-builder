## Autotools

# Configures autotools package
configure_autotools() {
	if [[ $(package_getvar REGEN n) == "y" ]]; then
		autoconf -fiv
	fi
	local build_dir=$(package_getvar BUILD_DIR)
	if [[ $(package_getvar USE_SUBBUILD n) == "y" ]]; then
		package_setvar BUILD_DIR "${build_dir}/build"
		build_dir+="/build"
	fi
	local debug_flag=""
	if [[ "${DEBUG}" == "y" ]]; then
		debug_flag="--enable-debug"
	fi
	mkdir -p "$build_dir"
	"$build_dir/configure" --prefix=/usr --sysconfdir=/etc --exe-prefix=/usr --libdir=/usr/lib --libexecdir=/usr/lib --localstatedir=/var \
		--program-prefix="" --with-bugurl="https://github.com/ExpidusOS" --disable-gtk-doc --disable-gtk-doc-html --disable-doc \
		--disable-docs --disable-documentation --with-selinux=no --enable-static --quiet "${debug_flag}" \
		$(package_getvar CONF_FLAGS)
}

# Builds autotools package
build_autotools() {
	cd "$(package_getvar BUILD_DIR)" && make
}

# Install autotools package
install_autotools() {
	cd "$(package_getvar BUILD_DIR)" && make install DESTDIR="$(package_getvar INSTALL_DIR)"
}

staging_install_autotools() {
	cd "$(package_getvar BUILD_DIR)" && make install DESTDIR="${STAGING_INSTALL_DIR}"
}

# Clean up autotools package
clean_autotools() {
	cd "$(package_getvar BUILD_DIR)" && make distclean
}

EXPAC_BUILDER_BUILDERS+=("autotools")
