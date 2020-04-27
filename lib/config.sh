config_loadfile() {
	if [[ ! $# -eq 1 ]]; then
		(>&2 echo "Requires at least one argument")
		return 1
	fi
	local conf_file="$1"
# Check if the file is a json file
	if [[ $(basename "${conf_file}") == *.json ]]; then
		if [[ ! -x $(command -v jq) ]]; then
			(>&2 echo "jq is required to read json files")
			return 1
		fi
		export TARGET_ARCH=$(cat "${conf_file}" | jq "if .target.arch == null then \"$(uname -m)\" else .target.arch end")
		export TARGET_PLATFORM=$(cat "${conf_file}" | jq "if .target.platform != null then .target.platform end")
		export TARGET_DEVICE=$(cat "${conf_file}" | jq "if .target.device != null then .target.device end")
		export OS_VARIANT=$(cat "${conf_file}" | jq "if .os_variant != null then .os_variant end")
		export DEBUG=$(cat "${conf_file}" | jq "if .target.debug == false then \"n\" else \"y\" end")
		export HOST_DIR=$(cat "${conf_file}" | jq "if .paths.host then .paths.host end")
		export BUILD_DIR=$(cat "${conf_file}" | jq "if .paths.build then .paths.build end")
	else
# This is an environment file so load it
		source "${conf_file}"
	fi
}

config_savefile() {
	if [[ ! $# -eq 1 ]]; then
		(>&2 echo "Requires at least one argument")
		return 1
	fi
	local conf_file="$1"
# Check if the file is a json file
	if [[ $(basename "${conf_file}") == *.json ]]; then
		cat << EOF > "${conf_file}"
{
	"paths": {
		"host": "${HOST_DIR}",
		"build": "${BUILD_DIR}"
	},
	"target": {
		"arch": ${TARGET_ARCH}",
		"platform": "${TARGET_PLATFORM}",
		"device": "${TARGET_DEVICE}",
		"debug": $([[ "${DEBUG}" == "y" ]] && echo true || echo false)
	},
	"os_variant": "${OS_VARIANT}"
}
EOF
else
# This is an environment file so load it
cat << EOF > "${conf_file}"
TARGET_ARCH="${TARGET_ARCH}"
TARGET_PLATFORM="${TARGET_PLATFORM}"
TARGET_DEVICE="${TARGET_DEVICE}"
OS_VARIANT="${OS_VARIANT}"
DEBUG="${DEBUG}"
HOST_DIR="${HOST_DIR}"
BUILD_DIR="${BUILD_DIR}"
EOF
	fi
}
